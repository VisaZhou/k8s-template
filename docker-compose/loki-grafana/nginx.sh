# 根据内网ip地址修改

docker run -d \
  --name nginx \
  --log-driver=loki-driver \
  --log-opt loki-url="http://192.168.78.102:3100/loki/api/v1/push" \
  --log-opt loki-external-labels=job=my-nginx \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/nginx:latest