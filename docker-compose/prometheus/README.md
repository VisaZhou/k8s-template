## prometheus 服务器监控

### 部署 prometheus 服务端

首先准备一个 prometheus 的配置文件 `prometheus.yml`。prometheus 通过此配置文件主动去采集所需数据。

然后运行
```bash
docker compose -f docker-compose.yml up -d
```

### 部署 node-exporter
node-exporter 是 Prometheus 官方提供的一个 主机级别的监控数据采集器 ，它会不断暴露出该服务器的CPU、内存、磁盘、网络等硬件信息和运行状态。

根据不同的采集端服务器硬件架构选择不同的脚本运行。

```bash
sh node-exporter.sh
```

amd 的镜像通过 docker_image_pusher 的 github action 上传到阿里云镜像仓库。

arm 的通过本地 mac pull arm镜像后 手动 push 到阿里云镜像仓库。
```bash
docker pull prom/node-exporter@sha256:2e9d73002adb973441ec1c815a8e7e7c2465f5e535d859d16ee395f2ceb857c7
docker tag 94b9e099be35 crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/node-exporter:arm64-1.9.1
docker push crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/node-exporter:arm64-1.9.1
```

### 接入 Grafana
1. 登录 Grafana --> 添加新连接 --> prometheus 数据源 --> 输入 prometheus 的地址 `http://prometheus:9090` --> 保存。

2. 仪表板 --> 导入 --> 输入 1860（该仪表板就是全局的 Node Exporter 仪表板）