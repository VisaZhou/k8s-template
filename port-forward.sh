# 查看所有转发进程
ps aux | grep "kubectl port-forward"

# 一键取消所有转发进程
pkill -f "kubectl port-forward"

# <本地端口>:<容器端口>

# nacos集群
nohup kubectl port-forward pod/nacos-cluster-0 8848:8848 9848:9848 9849:9849 > port-forward.log 2>&1 &
nohup kubectl port-forward pod/nacos-cluster-1 8858:8848 9858:9848 9859:9849 > port-forward.log 2>&1 &

# mysql集群
nohup kubectl port-forward pod/mysql-cluster-0 3306:3306 > port-forward.log 2>&1 &
nohup kubectl port-forward pod/mysql-cluster-1 3316:3306 > port-forward.log 2>&1 &

# redis集群代理
nohup kubectl port-forward pod/redis-proxy-0 7777:7777 > port-forward.log 2>&1 &