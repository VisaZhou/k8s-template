## 作用
在本地开发环境中，Spring Boot 项目需要连接部署在 Kubernetes 集群中的 Redis Cluster。

由于 Redis Cluster 的从节点通过集群内部的 Pod IP 进行通信，这些 IP 本地无法访问，导致当客户端被自动重定向到从节点时连接失败。

redis-cluster-proxy 部署在同一个 K8s 集群中，并作为集群的统一入口，能够在集群内部正确解析并转发请求。

只需通过本地端口转发访问该 Proxy，即可避免跨网络连接失败的问题，实现稳定的本地调试体验。