nohup kubectl port-forward pod/nacos-cluster-0 8848:8848 > port-forward.log 2>&1 &
nohup kubectl port-forward pod/mysql-cluster-0 3306:3306 > port-forward.log 2>&1 &
nohup kubectl port-forward pod/redis-cluster-0 6379:6379 > port-forward.log 2>&1 &

