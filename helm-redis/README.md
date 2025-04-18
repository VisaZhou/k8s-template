## RDB
### 验证配置是否成功
获取rdb的触发条件，与configmap中的配置一致：

每 15 分钟内至少有 1 次写操作；

每 5 分钟内至少有 10 次写操作；

每 1 分钟内至少有 10000 次写操作。
```bash
redis-cli -p 6379 -a zxj201328
config get save

# 输出
# 1) "save"
# 2) "900 1 300 10 60 10000"
```

### 获取RDB文件
根据configmap中的dir得出rdb位置在容器内的/var/lib/redis路径下：
```bash
cd /var/lib/redis
ls

# 输出
# appendonlydir  dump.rdb
```

### 获取最后一次生成RDB文件的时间
```bash
redis-cli -p 6379 -a zxj201328
lastsave

# 输出
# 1744942299
```

### 手动触发RDB保存
```bash
redis-cli -p 6379 -a zxj201328
bgsave

# 输出
# Background saving started
```
### 恢复RDB
重启redis

启动的时候，Redis 会自动加载 RDB

它会在 dir 目录下找 dump.rdb

如果找到，就自动把里面的快照数据加载到内存里恢复出来


## AOF
### 验证配置是否成功
获取是否启用 AOF 持久化，与configmap中的配置一致：
```bash
redis-cli -p 6379 -a zxj201328
config get appendonly

# 输出
# 1) "appendonly"
# 2) "yes"
```

获取同步策略，与configmap中的配置一致：
```bash
redis-cli -p 6379 -a zxj201328
config get appendfsync

# 输出
# 1) "appendfsync"
# 2) "everysec"
```

### 获取AOF文件
根据configmap中的dir得出aof位置在容器内的/var/lib/redis路径下：

从 Redis 6.2 开始，AOF 重写不是直接写一个新的 AOF 文件了，而是先生成 base.rdb，再追加 incr.aof ，最后通过 manifest 组织起来。

appendonly.aof.1.base.rdb：AOF 重写过程中，先生成的一个 RDB 快照，记录当时所有数据。

appendonly.aof.1.incr.aof：AOF 重写过程中，增量数据的 AOF 文件，记录了在 RDB 快照之后的所有操作。

appendonly.aof.manifest：索引文件，记录了增量数据的 AOF 文件和 RDB 快照的关系。
```bash
cd /var/lib/redis/appendonlydir
ls

# 输出
# appendonly.aof.1.base.rdb  appendonly.aof.1.incr.aof  appendonly.aof.manifest
```

### 恢复AOF
和 RDB 一样，AOF 文件的恢复是 Redis 启动时自动完成的，前提是：

appendonly yes 已启用

appendfilename 配置的 AOF 文件存在（默认 appendonly.aof）

dir 路径正确