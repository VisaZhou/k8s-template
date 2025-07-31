FROM crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/fluentd:v1.16-debian

USER root

# 安装构建插件所需依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ruby-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Fluentd Loki 插件
RUN fluent-gem install fluent-plugin-grafana-loki

# 切回 fluent 用户（以符合 upstream 安全建议）
USER fluent

# 设置默认启动命令
CMD ["fluentd", "-c", "/fluentd/etc/fluent.conf", "-v"]