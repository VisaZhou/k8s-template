## Helm-nacos-cluster 与 Helm-nacos 的区别

### 副本数量修改
```yml
  replicas: 2
```

### 单机模式改为集群模式
```yml
# 集群模式
env: 
  - name: MODE
    value: "cluster"
  - name: CLUSTER_NODES
    value: "nacos-cluster-0.{{ .Values.name.service }}.default.svc.cluster.local:8848,nacos-cluster-1.{{ .Values.name.service }}.default.svc.cluster.local:8848"
  - name: NACOS_SERVERS
    value: "nacos-cluster-0.{{ .Values.name.service }}.default.svc.cluster.local:8848 nacos-cluster-1.{{ .Values.name.service }}.default.svc.cluster.local:8848"  
```

### 集群模式下的springboot nacos配置
本地环境需要每个端口都转发,并且注册到配置中

因为 Nacos 集群模式下，默认 启动多个节点，并且启用了 集群内部健康检查和节点注册机制。如果你 只映射了某一个 Pod 的 8848 端口你只能访问集群的一个节点。此时 Spring Boot 连接后，Nacos 会告诉客户端「集群还有别的节点」，但客户端访问那些节点会失败（因为没暴露其它节点的端口），就会导致连不上。
```shell
nohup kubectl port-forward pod/nacos-cluster-0 8848:8848 9848:9848 9849:9849 > port-forward.log 2>&1 &
nohup kubectl port-forward pod/nacos-cluster-1 8858:8848 9858:9848 9859:9849 > port-forward.log 2>&1 &
```
```yml
spring:
  cloud:
    nacos:
      discovery:
        # 服务注册地址
        server-addr: localhost:8848,localhost:8858
        username: nacos
        password: nacos
```

k8s环境配置不用修改,会自动注册到集群中。
```yml
spring:
  cloud:
    nacos:
      discovery:
        # 服务注册地址
        server-addr: nacos-service.default.svc.cluster.local:8848
        username: nacos
        password: nacos
```