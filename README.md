# Helm 部署指南

## 项目 Helm 组件

本项目包含以下三种 Helm Chart 组件：

1. **helm-mysql**
    - 负责部署 MySQL 数据库。
    - 副本数 (replicas): `1`

2. **helm-nacos**
    - 负责部署 Nacos 作为服务注册中心。
    - 副本数 (replicas): `1`

3. **helm-backend**
    - 主要业务后端服务。
    - 副本数 (replicas): `2`

## 部署流程

### 1️⃣ 部署 MySQL
首先部署 MySQL Helm Chart，提供数据库服务：
```sh
helm upgrade --install helm-mysql ./helm-mysql
```
等待 MySQL 启动完成，可使用以下命令检查状态：
```sh
kubectl get pods -l app=mysql
```

### 2️⃣ 部署 Nacos
接下来部署 Nacos Helm Chart，作为服务注册中心：
```sh
helm upgrade --install helm-nacos ./helm-nacos
```
检查 Nacos 状态：
```sh
kubectl get pods -l app=nacos
```
Nacos 2.5.0 版本首次部署完成后，需要手动初始化 nacos 账户密码。等待 Nacos 完全启动后，执行以下命令：
```sh
curl -X POST 'http://nacos-service.default.svc.cluster.local:8848/nacos/v1/auth/users/admin' -d 'password=nacos'
```
端口转发到本地 8847 端口，访问 http://localhost:8847/nacos 测试登录是否成功：
```sh
nohup kubectl port-forward pod/nacos-cluster-0 8847:8848 > port-forward.log 2>&1 &
```

### 3️⃣ 部署 Backend
在 `helm-backend` 启动之前，需要手动在 MySQL 中创建数据库 `backend-boot-template`。

首先，进入 MySQL Pod：
```sh
kubectl exec -it $(kubectl get pods -l app=mysql -o jsonpath="{.items[0].metadata.name}") -- mysql -u root -p
```

然后，在 MySQL 命令行中执行：
```sql
CREATE DATABASE IF NOT EXISTS `backend-boot-template`;
```
数据库创建完成后，可以部署后端服务：
```sh
helm install helm-backend ./helm-backend
```

检查 Backend 状态：
```sh
kubectl get pods -l app=backend
```

## 结束
按照以上步骤，Helm Chart 部署完成，`backend` 成功连接 `MySQL` 和 `Nacos`，系统正式运行。

