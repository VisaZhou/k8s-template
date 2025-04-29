## 支持
目前的 cluster 模式支持master之间的集群。 slave只用于备份主节点数据，当主节点宕机时，slave会自动升级为主节点来提供服务。 客户端会被redirect到新的主节点。

该 helm 配置为自动分配主从，自动分配槽位，不适用于持久化 Redis 数据的场景。 因为重启所有节点会重新分配槽位和主从，而从 pvc 中恢复数据时，槽位和主从关系会不一致。 而且 k8s 中的 IP 地址是动态分配的，重启后 IP 地址会发生变化，node.conf 中的 IP 地址也会发生变化，因此会导致集群无法正常工作。

因此需要去除掉 pvc 的挂载。如果需要持久化数据，使用单机版 Redis 模式。
## 架构

Redis Cluster 至少需要 3 个 master + 每个 master 至少一个 replica，也就是说：最少需要 6 个节点（3主3从），否则会报错。
```bash
*** ERROR: Invalid configuration for cluster creation.
*** Redis Cluster requires at least 3 master nodes.
*** This is not possible with 4 nodes and 1 replicas per node.
*** At least 6 nodes are required.
```

三主三从架构，16384 个 slot，被平均分配给 2 个主节点，每个主节点挂 1 个从节点，如果 master 宕机，对应的 slave 会晋升为 master（自动故障转移）

master 1：管理的哈希槽为 0 - 5460 ，slave 1 备份 master 1

master 2：管理的哈希槽为 5461 - 10922 ，slave 2 备份 master 2

master 3：管理的哈希槽为 10923 - 16383 ，slave 3 备份 master 3

Cluster 总线：节点间通过 cluster bus 端口（一般是普通端口+10000）进行心跳和元数据交换

## 修改内容
### 1. redis-statefulset.yaml
副本数量
```yml
replicas: 6
```

端口配置：服务端口 + cluster bus 端口（这个端口不会对客户端暴露，只是集群内部节点通讯用的）

在 Redis cluster 模式里，Cluster bus 端口固定等于 port + 10000
```yml
ports:
    - containerPort: {{ .Values.service.port}}  # 容器内部 Redis 服务的端口
    - containerPort: {{ add .Values.service.port 10000 }} #  容器内部 Redis 集群节点间通信的端口：16379
```

去除掉 pvc 的挂载，去除以下内容：
```yml

    volumeMounts:
      - mountPath: {{ .Values.pvc.path}}
        name: {{ .Values.name.pvc}}  
    
  volumeClaimTemplates:
    - metadata:
        name: {{ .Values.name.pvc}}  
      spec:
        accessModes:
          - {{ .Values.pvc.accessModes}} 
        resources:
          requests:
            storage: {{ .Values.pvc.storage}}
        storageClassName: {{ .Values.name.storageClass}}
```

### 2. redis-service.yaml
同 statefulset，新增 cluster bus 端口，并且service有多端口时必须指定端口名称
```yml
  ports:
    - name: redis
      protocol: TCP
      # Service 在 Kubernetes 集群内部暴露的端口
      port: {{ .Values.service.port }}
      # pod 内部 Redis 进程监听的端口
      targetPort: {{ .Values.service.port }}

    - name: clusterbus
      protocol: TCP
      # Redis Cluster 节点之间通信的端口，通常是主端口 + 10000
      port: {{ add .Values.service.port 10000 }}
      targetPort: {{ add .Values.service.port 10000 }}
```

### 3. redis-configmap.yaml
1. cluster-enabled 启用集群模式。

2. cluster-config-file 设置集群配置文件的名称,文件由 Redis 自己生成、维护,这个文件会保存在 dir 目录下。

3. cluster-node-timeout 设置集群节点超时时间（单位：毫秒）。

4. masterauth 主从复制密码。
```txt
cluster-enabled "yes"
cluster-config-file nodes.conf
cluster-node-timeout 5000
masterauth zxj201328
```

## 集群创建
以下是集群创建命令：cluster-replicas 1 表示每个 master 会 分配 1 个 slave，redis-cli 在收到这 4 个节点之后，会：

1.	先选出 N/(1+1)（也就是一半）个节点做 master

2.	剩下的节点，随机或者按顺序分配给 master 当 slave
```bash
redis-cli --cluster create \
redis-cluster-0.redis-service.default.svc.cluster.local:6379 \
redis-cluster-1.redis-service.default.svc.cluster.local:6379 \
redis-cluster-2.redis-service.default.svc.cluster.local:6379 \
redis-cluster-3.redis-service.default.svc.cluster.local:6379 \
redis-cluster-4.redis-service.default.svc.cluster.local:6379 \
redis-cluster-5.redis-service.default.svc.cluster.local:6379 \
--cluster-replicas 1 -a zxj201328 --cluster-yes
```

把集群创建命令放在job中，Job 是独立于 StatefulSet 的，等 StatefulSet 完全就绪后再手动或自动执行，Job 执行一次性 cluster create 命令，执行完自动退出

该Job需要等待所有的 redis-cluster-x 节点都处于 Ready 状态后再执行创建集群命令，因此需要用到 kubectl 命令来检查节点状态。

使用 kubectl 命令需要构建一个包含 kubectl 和 redis-cli 的镜像(已构建k8s-redis-client)，还需要使用  ServiceAccount + Role + RoleBinding 来赋予容器内访问 Kubernetes API 的权限。

### redis-role.yml
```yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: redis-cluster-job-sa
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: redis-cluster-job-role
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: redis-cluster-job-rb
  namespace: default
subjects:
  - kind: ServiceAccount
    name: redis-cluster-job-sa
    namespace: default
roleRef:
  kind: Role
  name: redis-cluster-job-role
  apiGroup: rbac.authorization.k8s.io
```

### redis-job.yml
```yml
apiVersion: batch/v1
kind: Job
metadata:
  name: redis-init
spec:
  backoffLimit: 0 # 设置 restartPolicy: Never 后，k8s 不会重启当前容器，但是 Job 会创建新的容器执行完当前任务，可使用 backoffLimit 设置重试次数
  template:
    spec:
      serviceAccountName: redis-cluster-job-sa   #  绑定 ServiceAccount
      containers:
        - name: redis-job
          image: crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-arm64/k8s-redis-client:1.0
          imagePullPolicy: IfNotPresent  # 如果本地已有镜像则不再拉取
          command: ["/bin/sh", "-c"]
          # 等待所有 redis-cluster-x 节点 Running后执行创建集群命令
          args:
            - |
              while true; do
                READY_COUNT=$(kubectl get pods | grep 'redis-cluster-' | grep 'Running' | wc -l)
                if [ "$READY_COUNT" -ge 6 ]; then
                  echo "所有节点已就绪，开始创建集群"
                  break
                fi
                echo "等待 Redis 节点就绪..."
                sleep 5
              done

              redis-cli --cluster create \
              redis-cluster-0.redis-service.default.svc.cluster.local:6379 \
              redis-cluster-1.redis-service.default.svc.cluster.local:6379 \
              redis-cluster-2.redis-service.default.svc.cluster.local:6379 \
              redis-cluster-3.redis-service.default.svc.cluster.local:6379 \
              redis-cluster-4.redis-service.default.svc.cluster.local:6379 \
              redis-cluster-5.redis-service.default.svc.cluster.local:6379 \
              --cluster-replicas 1 -a zxj201328 --cluster-yes
      restartPolicy: Never # 脚本跑完或失败后，k8s 不再重启当前容器
      imagePullSecrets:
        - name: my-registry-secret # 如果需要从私有镜像仓库拉取镜像，指定镜像仓库的 Secret
```

### java 客户端连接集群
开发环境

转发所有端口到本地进行连接会失败，因为 Redis Cluster 节点间的跳转依靠的是 nodes.conf 中的内网 IP 地址。

所以本地连接改为使用 Jedis + 自构建的 helm-redis-proxy 取代 lettuce,使用 proxy 连接集群，proxy 会自动处理集群的路由问题。

注意：关闭 redis 健康检查，因为 redis-cluster-proxy 不支持 info 命令，所以开发环境下需要关闭 redis 健康检查。
```xml
        <dependency>
            <groupId>redis.clients</groupId>
            <artifactId>jedis</artifactId>
            <scope>runtime</scope>
            <optional>true</optional>
        </dependency>
```
```yml
  # 由于开发环境端口策略问题，需要使用 redis-cluster-proxy 代理来实现 redis 连接。
  data:
    redis: # 由于 redis-cluster-proxy 中设置了密码，所以不需要在这里设置密码，集群模式下也不需要设置database
      host: localhost
      port: 7777
      timeout: 3000
      client-type: jedis  # 明确使用 Jedis 客户端，支持redis-cluster-proxy
      jedis:
        pool:
          max-active: 8         # 最大连接数
          max-wait: -1ms        # 最大等待时间（-1 表示无限等待）
          min-idle: 0           # 最小空闲连接数
          max-idle: 8           # 最大空闲连接数

management:
  health:
    redis:
      enabled: false # 由于 redis-cluster-proxy 不支持 info 命令，所以开发环境下需要关闭 redis 健康检查
```

k8s内网环境

可以直接使用 lettuce 进行连接。
```yml
  data:
    redis:
      # 这里配置 Redis 集群的节点，Lettuce 会自动进行集群管理
      cluster:
        nodes:
          - redis-cluster-0.redis-service.default.svc.cluster.local:6379
          - redis-cluster-1.redis-service.default.svc.cluster.local:6379
          - redis-cluster-2.redis-service.default.svc.cluster.local:6379
          - redis-cluster-3.redis-service.default.svc.cluster.local:6379
          - redis-cluster-4.redis-service.default.svc.cluster.local:6379
          - redis-cluster-5.redis-service.default.svc.cluster.local:6379
        max-redirects: 5   # Redis 集群中重定向的最大次数，类似于使用 -c 参数的效果
      password: zxj201328
      timeout: 3000
      lettuce:
        pool:
          max-active: 8  # 连接池最大连接数
          max-wait: -1ms  # 连接池最大阻塞等待时间（使用负值表示没有限制）
          min-idle: 0  # 连接池中的最小空闲连接
          max-idle: 8  # 连接池中的最大空闲连接
```


## 命令
### 集群连接

Redis Cluster 使用 分片机制，把 16384 个槽（slot）平均分给所有 master 节点。每个 key 根据 CRC16 算法被映射到某个 slot。

使用普通连接命令，并设置key时，它会把 key 映射到某个 slot，然后去访问对应的 master 节点，如果这个节点不是你连接的节点，就会报错。
```bash
redis-cli -a zxj201328 
set test1 value1

# (error) MOVED 4768 10.244.0.221:6379
```
使用集群连接命令，并设置key时，它会把 key 映射到某个 slot，然后去访问对应的 master 节点，如果这个节点不是你连接的节点，它会自动重定向到正确的节点。
```bash
redis-cli -c -a zxj201328
set test1 value1

# -> Redirected to slot [4768] located at 10.244.0.221:6379
#OK
```

### 主从关系对应查看
10.244.0.221 是 master（redis-cluster-0） , 对应的 slave 是 10.244.0.226 (redis-cluster-4)

10.244.0.223 是 master (redis-cluster-1) , 对应的 slave-1 是 10.244.0.227 (redis-cluster-5)

10.244.0.224 是 master (redis-cluster-2) , 对应的 slave-2 是 10.244.0.225 (redis-cluster-3)
```bash
redis-cli -c -a zxj201328
cluster nodes

# ca19cd965ae9d7ef5b5939471c1136a9005235fc 10.244.0.221:6379@16379 master - 0 1745409941000 1 connected 0-5460
# c2b888d5a325f43451d16bb57e0b0a9cf1f49fbb 10.244.0.223:6379@16379 master - 0 1745409941800 2 connected 5461-10922
# 9c2a2fba4290efb89f8db4701179f2388e197884 10.244.0.224:6379@16379 master - 0 1745409941000 3 connected 10923-16383
# c2fb5c9e081a1ecf6912705d2455ab4f5399954a 10.244.0.227:6379@16379 slave c2b888d5a325f43451d16bb57e0b0a9cf1f49fbb 0 1745409941800 2 connected
# 4d867f43b89a1bbd26e66ffdcebfe219c89e695a 10.244.0.225:6379@16379 slave 9c2a2fba4290efb89f8db4701179f2388e197884 0 1745409940287 3 connected
# 3372f9385e39f3ae44e8eb375c5e3aa936c63d26 10.244.0.226:6379@16379 myself,slave ca19cd965ae9d7ef5b5939471c1136a9005235fc 0 0 1 connected
```
```bash
kubectl get pods -o wide

# redis-cluster-0                    1/1     Running     0            77m   10.244.0.221   minikube   <none>           <none>
# redis-cluster-1                    1/1     Running     0            77m   10.244.0.223   minikube   <none>           <none>
# redis-cluster-2                    1/1     Running     0            77m   10.244.0.224   minikube   <none>           <none>
# redis-cluster-3                    1/1     Running     0            77m   10.244.0.225   minikube   <none>           <none>
# redis-cluster-4                    1/1     Running     0            77m   10.244.0.226   minikube   <none>           <none>
# redis-cluster-5                    1/1     Running     0            77m   10.244.0.227   minikube   <none>           <none>
```

### 主从复制测试
从以下命令可以看出，使用普通登录 redis-cluster-0 设置值。

使用普通登录 redis-cluster-4 也能获取到这个值。

但是使用普通登录 redis-cluster-5 却获取不到这个值，因为它是 redis-cluster-1 的从节点。
```bash
kubectl exec -it redis-cluster-0 -- redis-cli -a zxj201328
set test0 value0
# OK
exit

kubectl exec -it redis-cluster-4 -- redis-cli -a zxj201328
readonly
get test0
# "value0"
exit

kubectl exec -it redis-cluster-5 -- redis-cli -a zxj201328
readonly
get text0
# (error) MOVED 641 10.244.0.243:6379
exit
```

## 哨兵模式
Redis 是 Cluster 模式的话，已经支持主从复制、自动故障转移和分布式路由，不需要再使用 Sentinel 了。

它们分别是两套高可用机制，不可以混用。