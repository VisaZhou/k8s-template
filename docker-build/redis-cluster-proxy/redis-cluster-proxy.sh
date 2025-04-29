#!/bin/bash

# 遇到错误立刻退出
set -e
# 打印命令方便调试
set -x

# 读取环境变量
source .env

echo "登录阿里云镜像仓库..."
echo "$REPOSITORY_PASSWORD" | docker login --username="$REPOSITORY_USERNAME" "$REPOSITORY_URL" --password-stdin

echo "开始构建 redis-cluster-proxy 镜像..."
docker build -t "$IMAGE_NAME":"$IMAGE_VERSION" -f redis-cluster-proxy.Dockerfile .

echo "推送镜像到仓库..."
docker tag "$IMAGE_NAME":"$IMAGE_VERSION" "$REPOSITORY_URL/$REPOSITORY_NAMESPACE/$IMAGE_NAME:$IMAGE_VERSION"
docker push "$REPOSITORY_URL/$REPOSITORY_NAMESPACE/$IMAGE_NAME:$IMAGE_VERSION"

echo "构建并推送完成！"