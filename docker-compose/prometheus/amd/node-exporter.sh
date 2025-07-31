docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --network=host \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/node-exporter:v1.9.1