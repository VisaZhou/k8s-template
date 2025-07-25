# Loki + Grafana + Loki driver 日志系统

## 安装步骤

进入目录 
```bash
cd docker-compose/promtail-loki-grafana
```

执行初始化配置文件
   - 该脚本会创建 loki 和 grafana 的挂载目录。
   - 会安装 Loki 采集插件用来采集 Docker 日志（可单独提出安装在需要采集的服务器上）
```bash
sh loki-grafana.sh   
```
   
执行 compose 文件启动服务
```bash
docker-compose -f docker-compose-loki.yml up -d
```

运行服务并使用loki采集插件,参照 nginx.sh
```bash
docker run -d \
  --name nginx \
  --log-driver=loki-driver \
  --log-opt loki-url="http://192.168.1.9:3100/loki/api/v1/push" \
  --log-opt loki-external-labels=job=my-nginx \
  crpi-iay62pbhw1a58p10.cn-hangzhou.personal.cr.aliyuncs.com/visage-namespace/nginx:latest
```

验证是否成功：浏览器访问如下地址并查看日志是否正确输出
```bash
http://192.168.1.9:3100/loki/api/v1/query?query={job="my-nginx"}
```

如果未正确输出则进入 nginx 容器查看 loki 是否已初始化完成
```bash
 docker exec -it nginx /bin/sh
 curl http://192.168.1.9:3100/ready
 
 # 初始化未完成，等待其完成：Ingester not ready: waiting for 15s after being ready
 # 初始化完成：ready
```


## Grafana 配置
访问地址：`http://localhost:3200/`
账号密码：`phis/giga@163.com`

配置数据源
1. 在 Grafana 中，点击左侧菜单 --> 点击 Plugins and data --> 点击 Plugins --> 搜索 Loki 并安装 -->
2. 点击 Add new data source --> 选择 Loki --> 填写 URL 为 `http://192.168.1.9:3100(根据内网实际ip修改)` --> 点击 Save & Test

配置日志面板
1. 在 Grafana 中，点击左侧菜单 --> Explore --> 选择 Loki 数据源 --> 选择对应的job --> 点击 Run Query（目前是json格式的，不是标准输出）

配置标准输出
1. 可以在 Builder 面板中修改,但是为临时缓存，不是持久化：新增 label filters --> + Operations（json）--> + Operations (Line format) --> + Expression ({{.log}})
2. 可以在 code 面板中修改,但是为临时缓存，不是持久化：`{job="anhui-gateway"} | json | line_format "{{.log}}"`
3. 配置仪表板，永久有效
   - 在 Grafana 中，点击左侧菜单 --> Dashboard --> New dashboard --> Add new panel-->右侧面板选择logs，可把 time 和 Wrip lines 开放--> code输入`{job="$job"} | json | line_format "{{.log}}"`--> save 保存
   - 编辑仪表板 --> 打开仪表板设置 --> 新增变量 job(Select variable type选择 Query， datasource 选择 Loki，Refresh 选择 on dashboard load, Query 选择 Label values job) --> 保存

## `loki-docker-driver` 无法安装

放弃 `loki-docker-driver` 插件，使用 docker 自带的 `fluentd-driver` 采集日志
1. 同样需要安装 `loki` 和 `grafana`，可以参考上面的步骤。
2. Dockerfile 打包对应硬件架构的 `fluentd-with-loki` 镜像。
3. 在各个采集端服务器部署 `fluentd`，配置 `fluentd-driver` 采集日志并发送到 `loki`。