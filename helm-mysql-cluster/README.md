## Helm-mysql-cluster 与 Helm-mysql 的区别

### 副本数量
```yml
  replicas: 2
```

### 初始化容器
集群的每个 Pod 的 server_id 不能重复而且非0，否则会导致 MySQL 主从复制失败。

这里把pod的名称作为 server_id 的基础，去除非数字部分，取出数字部分并加1，确保每个 Pod 的 server_id 唯一。

它将把创建的 my.cnf 文件挂载到共享卷中，这样 containers 下的容器可以访问到这个配置文件。
```yml
      initContainers:
        - name: {{ .Values.name.initContainer}}  # 初始化容器的名称
          image: {{ .Values.image.initContainer}}  # 初始化容器的镜像
          env:
            - name: MYSQL_SERVER_ID
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name # 使用 Pod 名称作为 MySQL 的 server_id，确保在集群中唯一，由于必须是数字，所以在钩子中提取数字部分，并且写入 my.cnf
          volumeMounts:
            - name: {{ .Values.name.volume}}  # 挂载的共享卷名称
              mountPath: /etc/mysql
          command:
            - "/bin/sh"
            - "-c"
            - |
              ID=$(echo $MYSQL_SERVER_ID | sed 's/[^0-9]//g')
              ID=$((ID + 1))
              echo "[mysqld]" > /etc/mysql/my.cnf
              echo "server-id = $ID" >> /etc/mysql/my.cnf
```

这里的 initContainer 主要是将共享卷中的 my.cnf 挂载到容器的 /etc/mysql/my.cnf 路径下。

emptyDir: { } 共享卷，会在 Pod 删除时候自动清除。

```yml
      containers:
          volumeMounts:
            - name: {{ .Values.name.volume}} # 将共享卷 emptyDir 中的特定文件 my.cnf，精确地挂载到容器的 /etc/mysql/my.cnf 配置路径。
              mountPath: /etc/mysql/my.cnf
              subPath: my.cnf
      volumes:
        - name: {{ .Values.name.volume}} # 创建一个临时的空目录（empty dir）作为 volume。每次 Pod 启动时，这个目录都是空的。生命周期 跟随 Pod —— 也就是说 Pod 一旦被删除，这个目录里的数据就没有了。
          emptyDir: { }
```

### 创建钩子脚本
实现主从复制的脚本
values.yaml
```yml
# 自定义配置
env:
  user: root # MySQL root 用户名
  password: zxj201328  # MySQL root 用户的密码
  replicationUser: repl # 主从复制用户，为了更好的安全性，不建议使用root账号
  replicationPassword: repl_zxj201328 # 主从复制用户密码
```

statefulset.yml
```yml
          lifecycle:
            # 如果是主库，则判断repl的账号是否存在，如果不存在则创建一个名为 repl 的复制账号，并授权它拥有主从同步权限。
            # 如果是从库，则连接主库，获取主库的 binlog 文件名和位置，并配置为从库，一旦配置完成，MySQL 会自动同步主库的所有写入操作到从库，实时或接近实时。
            # mysqladmin ping：这是一个 MySQL 管理工具，用来检查 MySQL 服务是否正在运行。
            # MASTER_STATUS=$(...)：这段命令将 SHOW MASTER STATUS 命令的结果（主节点的二进制日志文件和位置）赋值给 MASTER_STATUS 变量，稍后用于配置从节点的复制。
            # LOG_FILE=$(...)：将 awk 提取出来的日志文件名赋值给 LOG_FILE 变量。这样，LOG_FILE 就保存了主节点的二进制日志文件的名称。
            # LOG_POS=$(...)：将 awk 提取出来的日志位置赋值给 LOG_POS 变量。这样，LOG_POS 就保存了主节点的二进制日志的当前位置。
            # CHANGE MASTER TO ...：主从复制配置的关键部分。它告诉从节点如何连接到主节点，并配置复制所需的参数。
            # START SLAVE：启动从节点的复制进程。它告诉 MySQL 从节点开始从主节点读取二进制日志，并实时应用主节点上的变更。
            postStart:
              exec:
                command:
                  - "/bin/sh"
                  - "-c"
                  - |
                    echo "Waiting for mysqld to be ready..."
                    until mysqladmin ping -u{{ .Values.env.user}} -p{{ .Values.env.password}} --silent; do sleep 2; done
                    mysql -u{{ .Values.env.user }} -p{{ .Values.env.password }} -e "ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '{{ .Values.env.password }}'; FLUSH PRIVILEGES;"

                    if [ $(cat /etc/hostname) = "{{ .Values.name.cluster }}-0" ]; then
                      echo "Initializing master..."
                      USER_EXISTS=$(mysql -u{{ .Values.env.user}} -p{{ .Values.env.password}} -e "SELECT COUNT(*) FROM mysql.user WHERE user = '{{ .Values.env.replicationUser}}';" | tail -n 1)
                      if [ "$USER_EXISTS" -eq 0 ]; then
                      mysql -u{{ .Values.env.user}} -p{{ .Values.env.password}} -e "CREATE USER '{{ .Values.env.replicationUser}}'@'%' IDENTIFIED WITH mysql_native_password BY '{{ .Values.env.replicationPassword}}'; GRANT REPLICATION SLAVE ON *.* TO '{{ .Values.env.replicationUser}}'@'%'; FLUSH PRIVILEGES;"
                      else
                      echo "Replication user '{{ .Values.env.replicationUser}}' already exists, skipping creation."
                      fi
                    else
                      echo "Initializing slave..."
                      until mysqladmin ping -h {{ .Values.name.cluster }}-0.{{ .Values.name.service }}.default.svc.cluster.local -u{{ .Values.env.user}} -p{{ .Values.env.password}} --silent; do sleep 2; done
                      MASTER_STATUS=$(mysql -h {{ .Values.name.cluster }}-0.{{ .Values.name.service }}.default.svc.cluster.local -u{{ .Values.env.user}} -p{{ .Values.env.password}} -e 'SHOW MASTER STATUS\G')
                      LOG_FILE=$(echo "$MASTER_STATUS" | grep File | awk '{print $2}')
                      LOG_POS=$(echo "$MASTER_STATUS" | grep Position | awk '{print $2}')
                      mysql -u{{ .Values.env.user}} -p{{ .Values.env.password}} -e "STOP SLAVE;"
                      mysql -u{{ .Values.env.user}} -p{{ .Values.env.password}} -e "CHANGE MASTER TO MASTER_HOST='{{ .Values.name.cluster }}-0.{{ .Values.name.service }}.default.svc.cluster.local', MASTER_USER='{{ .Values.env.replicationUser}}', MASTER_PASSWORD='{{ .Values.env.replicationPassword}}', MASTER_LOG_FILE='$LOG_FILE', MASTER_LOG_POS=$LOG_POS; START SLAVE;"
                    fi
```
## 注意
volumeClaimTemplates 不需要修改，但是在从单机转为集群时需要删除旧的pvc。

主从复制设置好后，如果从机复制有报错，将会自动调用STOP SLAVE命令停止复制，需要手动解决掉错误部分，然后执行START SLAVE命令重新开始复制。

主从复制设置好后，读写分离依靠ShardingSphere来实现。

