# 当脚本中的任一命令返回非零退出状态时立即终止执行。
set -e
# 在执行命令前打印命令及其参数，方便调试。
set -x

# 从.env文件中读取环境变量,只能在shell脚本中使用，不会自动传递到 docker build
source .env

echo " 下载 arm64v8/fluentd:v1.16-debian-1 镜像..."
# docker pull arm64v8/fluentd:v1.16-debian-1


echo " 开始登录私有镜像仓库..."
echo "$REPOSITORY_PASSWORD" | docker login --username="$REPOSITORY_USERNAME" "$REPOSITORY_URL" --password-stdin


echo " 开始构建 fluentd-with-loki 客户端镜像..."
docker build -t "$IMAGE_NAME":"$IMAGE_VERSION" -f fluentd-with-loki.Dockerfile .


echo " 推送镜像到私有仓库..."
docker tag "$IMAGE_NAME":"$IMAGE_VERSION" "$REPOSITORY_URL"/"$REPOSITORY_NAMESPACE"/"$IMAGE_NAME":"$IMAGE_VERSION"
docker push "$REPOSITORY_URL"/"$REPOSITORY_NAMESPACE"/"$IMAGE_NAME":"$IMAGE_VERSION"

echo " 镜像构建并推送完成！"