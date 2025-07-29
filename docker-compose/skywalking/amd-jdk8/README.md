## java agent 安装，代理 java 服务进行采集

在宿主机下载 agent 文件
```bash
wget https://archive.apache.org/dist/skywalking/8.3.0/apache-skywalking-apm-es7-8.3.0.tar.gz
tar -zxvf apache-skywalking-apm-es7-8.3.0.tar.gz
```

各服务启动容器挂载 agent 到容器
```bash
  -v /data/apache-skywalking-apm-bin-es7/agent:/skywalking/agent \
  -e JAVA_TOOL_OPTIONS=-javaagent:/skywalking/agent/skywalking-agent.jar \
  -e SW_AGENT_NAME=$app_name-anhui \
  -e SW_COLLECTOR_BACKEND_SERVICES=172.33.128.23:11800 \
```