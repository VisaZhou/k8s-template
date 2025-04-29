# 阶段一：构建阶段，基于 alpine 安装 gcc 工具链并构建 C 项目
FROM crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/alpine:latest AS builder

# 安装构建所需的依赖
RUN apk add --no-cache build-base git gcc libc-dev linux-headers

# 克隆源码
WORKDIR /app
RUN git clone https://github.com/RedisLabs/redis-cluster-proxy.git .

# 编译（Makefile 会构建 src/redis-cluster-proxy）
RUN make CFLAGS="-fcommon"

# 阶段二：精简运行镜像，只复制最终可执行文件
FROM crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/alpine:latest

COPY --from=builder /app/src/redis-cluster-proxy /usr/local/bin/redis-cluster-proxy

ENTRYPOINT ["/usr/local/bin/redis-cluster-proxy"]