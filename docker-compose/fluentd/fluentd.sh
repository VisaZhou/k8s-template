# 运行自己 build 的 fluentd-with-loki 采集镜像
docker run -d \
  --name fluentd \
  --restart=always \
  -p 24224:24224 \
  -v "$(pwd)"/fluent.conf:/fluentd/etc/fluent.conf \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-arm64/fluentd-with-loki:latest

# 各服务容器运行时加载插件
docker run -itd \
  --net=host \
  --name phis-message \
  --restart=always \
  --log-driver=fluentd \
  --log-opt fluentd-address=127.0.0.1:24224 \
  --log-opt tag="phis-message.log" \
  -v /data/app-logs/phis-message:/logs \
  -v /etc/localtime:/etc/localtime \
  phis-message