FROM crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/alpine:latest

# 安装 bash、curl、redis-cli
RUN apk add --no-cache bash curl redis

# 安装 kubectl（官方最新版本）
RUN curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# 设置默认 shell
SHELL ["/bin/bash", "-c"]

# 定义工作目录
WORKDIR /workspace

# 默认执行 bash
CMD [ "bash" ]