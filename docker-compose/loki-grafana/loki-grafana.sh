# 创建 Loki 存储目录
mkdir -p loki/{wal,chunks,cache,index,compactor,rules}

# 创建 Grafana 配置目录
mkdir -p grafana/provisioning/{datasources,dashboards}

# 安装 Loki 插件采集日志
# loki-docker-driver 是通过 Docker 自带日志驱动机制，直接将 stdout/stderr 数据以 label + log 格式实时推送到 Loki，不依赖日志文件，也不需要 Promtail。
# --alias loki-driver 是为了给插件起一个别名，方便在 Docker 容器中使用。
# --grant-all-permissions 是为了授予插件所有权限，确保插件可以正常工作。
docker plugin install grafana/loki-docker-driver:latest --alias loki-driver --grant-all-permissions

