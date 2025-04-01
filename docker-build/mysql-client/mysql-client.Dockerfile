FROM crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/alpine:latest

# 安装 MySQL 客户端（实际上是 MariaDB Client，它兼容 MySQL）
RUN apk add --no-cache mysql-client