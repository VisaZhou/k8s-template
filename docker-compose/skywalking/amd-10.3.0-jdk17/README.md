## 指定 profile 启动 skywalking
```bash
docker compose -f docker-compose.yml --profile elasticsearch up -d
docker compose -f docker-compose.yml --profile banyandb up -d
```

## skywalking 对应的代理下载地址

```bash
https://skywalking.apache.org/downloads/?utm_source=chatgpt.com
```

## java agent 安装，代理 java 服务进行采集

在宿主机下载 agent 文件 9.4.0 版本
```bash
https://dlcdn.apache.org/skywalking/java-agent/9.4.0/apache-skywalking-java-agent-9.4.0.tgz
```

上传各个服务器后解压
```bash
rsync -avz /Users/zhouxujin/Downloads/apache-skywalking-java-agent-9.4.0.tgz root@1.95.68.241:/data/skywalking/java-agent 
tar -zxvf apache-skywalking-java-agent-9.4.0.tgz
```

各服务启动容器挂载 agent 到容器
```bash
-v /data/skywalking/java-agent/skywalking-agent:/skywalking-agent \
-e JAVA_TOOL_OPTIONS="-javaagent:/skywalking-agent/skywalking-agent.jar \
                    -Dskywalking.agent.service_name=$app_name-anhui \
                    -Dskywalking.collector.backend_service=172.33.128.23:11800" \
```

打开首页
```bash
http://1.95.48.134:10800/
```
常规服务 --> 服务（看到相关服务） --> 点击服务右侧查看相关Trace（看到相关请求以及调用链）