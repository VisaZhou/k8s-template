# 创建 Loki 存储目录
mkdir -p loki/{wal,chunks,cache,index,compactor,rules}
# 设置 Loki 存储目录的权限
sudo chown -R 10001:10001 ./loki

# 创建 Grafana 配置目录
mkdir -p grafana/provisioning/{datasources,dashboards}
# 设置 Grafana 配置目录的权限
sudo chown -R 472:472 ./grafana

# 在各个采集端服务器上安装 Loki 插件采集日志
# loki-docker-driver 是通过 Docker 自带日志驱动机制，直接将 stdout/stderr 数据以 label + log 格式实时推送到 Loki，不依赖日志文件，也不需要 Promtail。
# --alias loki-driver 是为了给插件起一个别名，方便在 Docker 容器中使用。
# --grant-all-permissions 是为了授予插件所有权限，确保插件可以正常工作。
docker plugin install grafana/loki-docker-driver:latest --alias loki-driver --grant-all-permissions

# 测试：被采集容器挂载 Loki 插件采集日志
docker run -d \
  --name nginx \
  --log-driver=loki-driver \
  --log-opt loki-url="http://192.168.78.102:3100/loki/api/v1/push" \
  --log-opt loki-external-labels=job=my-nginx \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/nginx:latest

