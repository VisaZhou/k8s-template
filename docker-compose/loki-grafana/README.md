## Loki + Grafana + Loki driver 日志系统

### 安装步骤

进入目录 
```bash
cd docker-compose/promtail-loki-grafana
```

执行初始化配置文件
   - 该脚本会创建 loki 和 grafana 的挂载目录。
   - 会安装 Loki 采集插件用来采集 Docker 日志（可单独提出安装在需要采集的服务器上）
```bash
sh loki-grafana.sh   
```
   
执行 compose 文件启动服务
```bash
docker-compose -f docker-compose-loki.yml up -d
```

运行服务并使用loki采集插件,参照 nginx.sh
```bash
docker run -d \
  --name nginx \
  --log-driver=loki-driver \
  --log-opt loki-url="http://192.168.1.9:3100/loki/api/v1/push" \
  --log-opt loki-external-labels=job=my-nginx \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/nginx:latest
```

验证是否成功：浏览器访问如下地址并查看日志是否正确输出
```bash
http://192.168.1.9:3100/loki/api/v1/query?query={job="my-nginx"}
```

如果未正确输出则进入 nginx 容器查看 loki 是否已初始化完成
```bash
 docker exec -it nginx /bin/sh
 curl http://192.168.1.9:3100/ready
 
 # 初始化未完成，等待其完成：Ingester not ready: waiting for 15s after being ready
 # 初始化完成：ready
```


### 访问 Grafana，配置 Loki 数据源
访问地址：`http://localhost:3200/`
账号密码：`phis/giga@163.com`

在 Grafana 中，点击左侧菜单 --> 点击 Plugins and data --> 点击 Plugins --> 搜索 Loki 并安装 -->
点击 Add new data source --> 选择 Loki --> 填写 URL 为 `http://192.168.1.9:3100(根据内网实际ip修改)` --> 点击 Save & Test

### Grafana 查看日志
在 Grafana 中，点击左侧菜单 --> Explore --> 选择 Loki 数据源 --> 输入查询语句 `{job="my-nginx"}` --> 点击 Run Query

### `loki-docker-driver` 由于插件托管在国外，本地挂代理可以安装，但是在服务器上没有代理,处理情况如下：

1.使用 docker:24.0-dind (带有完整 Docker 的镜像)
```bash
# 拉取 docker:24.0-dind 镜像
docker pull crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/docker:24.0-dind

# 运行 docker:24.0-dind，并进入容器的交互式 shell
docker run -it --rm \
  --name docker-image \
  --privileged \
  --network host \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/docker:24.0-dind \
  sh

# 在容器内安装 loki-docker-driver 插件,如果安装不成功但是下载成功了也没关系，可以在容器内复制插件到宿主机上
dockerd &
sleep 5 
docker plugin install grafana/loki-docker-driver:latest --alias loki-driver --grant-all-permissions
```
2.找到插件在容器内的路径
```bash
cd /var/lib/docker/plugins
ls
```

3.复制插件到宿主机
```bash
docker cp docker-image:/var/lib/docker/plugins/7a0e275e5a78062bd3898ffdc8bbc53e02f2d62fdc118af6123351f736c993a7 ./docker-compose/loki-grafana/plugin
```

4.复制插件到服务器
```bash
rsync -a -e ssh -i ./docker-compose/loki-grafana/plugin/7a0e275e5a78062bd3898ffdc8bbc53e02f2d62fdc118af6123351f736c993a7 root@1.95.48.134:/var/lib/docker/plugins/
```

5.重启服务器docker，并启动插件
```bash
systemctl restart docker
docker plugin enable loki-driver:latest
```

### 放弃 `loki-docker-driver` 插件，使用 `fluentd` 采集日志
`fluentd` 部署方式
1. 同样需要安装 `loki` 和 `grafana`，可以参考上面的步骤。
2. Dockerfile 打包对应硬件架构的 `fluentd-with-loki` 镜像。
3. 在各个采集端部署 `fluentd`，配置 `fluentd` 采集日志并发送到 `loki`。