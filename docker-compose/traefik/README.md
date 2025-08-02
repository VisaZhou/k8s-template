## Traefik
当前 Traefik 主要用来作为域名转发代理服务。

### 服务标识符
```text
<服务名>@<provider>
```

### provider：配置来源
1. internal：Traefik 内置服务
2. file：从本地静态或动态 .yml 文件加载
3. docker：自动发现 Docker 服务并配置路由
4. kubernetes / kubernetesCRD：集成 K8s 的 Ingress 或 CRD
5. consulCatalog：使用 Consul 服务注册表
6. etcd：从 etcd 配置中心读取
7. zookeeper：使用 Zookeeper 作为配置中心
8. ecs：AWS ECS 容器服务
9. marathon：Mesos 平台
10. rancher：Rancher 环境中使用
11. rest：通过 REST API 提交配置（动态）

### Traefik 内置服务
1. noop@internal： 无操作服务，通常用于测试或占位符。
2. api@internal：用于访问 Traefik 的 Dashboard 仪表盘和 API 接口。
3. dashboard@internal：仅包含 Dashboard 仪表盘的轻量级服务，不包括 API 接口。

## 注意
1. entryPoints的名称，service的名称，router的名称，middleware的名称，tag的名称，label的名称等都不能重复。
2. entryPoints的名称，service的名称，router的名称，middleware的名称，tag的名称，label的名称等都不能为纯数字。