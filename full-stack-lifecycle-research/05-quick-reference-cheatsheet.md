# 全栈开发快速参考手册 (Cheat Sheet)

> 生产环境常用命令、配置和最佳实践速查

## 目录
- [Docker常用命令](#docker常用命令)
- [Kubernetes常用命令](#kubernetes常用命令)
- [Git工作流](#git工作流)
- [数据库优化速查](#数据库优化速查)
- [Redis常用命令](#redis常用命令)
- [Kafka常用命令](#kafka常用命令)
- [性能调优参数](#性能调优参数)
- [故障排查清单](#故障排查清单)

---

## Docker常用命令

### 镜像管理
```bash
# 构建镜像
docker build -t myapp:v1.0 .

# 多平台构建（支持ARM64）
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:v1.0 --push .

# 查看镜像
docker images

# 删除无用镜像
docker image prune -a

# 查看镜像层
docker history myapp:v1.0

# 导出/导入镜像
docker save myapp:v1.0 -o myapp.tar
docker load -i myapp.tar

# 扫描漏洞
docker scan myapp:v1.0
```

### 容器管理
```bash
# 运行容器
docker run -d --name myapp -p 8080:8080 myapp:v1.0

# 查看日志
docker logs -f --tail 100 myapp

# 进入容器
docker exec -it myapp /bin/bash

# 查看容器资源使用
docker stats myapp

# 查看容器详细信息
docker inspect myapp

# 停止并删除容器
docker stop myapp && docker rm myapp

# 清理所有停止的容器
docker container prune
```

### Docker Compose
```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f backend

# 重启服务
docker-compose restart backend

# 停止并删除
docker-compose down

# 停止并删除（包括数据卷）
docker-compose down -v

# 查看运行状态
docker-compose ps

# 扩容服务
docker-compose up -d --scale backend=3
```

---

## Kubernetes常用命令

### 资源管理
```bash
# 应用配置
kubectl apply -f deployment.yaml

# 查看资源
kubectl get pods -n production
kubectl get deployments -n production
kubectl get services -n production
kubectl get ingress -n production

# 查看详细信息
kubectl describe pod my-pod -n production

# 查看日志
kubectl logs -f my-pod -n production
kubectl logs -f my-pod -n production --tail=100
kubectl logs -f deployment/backend-api -n production

# 进入Pod
kubectl exec -it my-pod -n production -- /bin/bash

# 端口转发（本地调试）
kubectl port-forward pod/my-pod 8080:8080 -n production

# 查看资源使用
kubectl top pods -n production
kubectl top nodes
```

### 部署管理
```bash
# 更新镜像
kubectl set image deployment/backend-api backend-api=myapp:v1.1 -n production

# 查看滚动更新状态
kubectl rollout status deployment/backend-api -n production

# 查看更新历史
kubectl rollout history deployment/backend-api -n production

# 回滚到上一个版本
kubectl rollout undo deployment/backend-api -n production

# 回滚到指定版本
kubectl rollout undo deployment/backend-api --to-revision=2 -n production

# 暂停/恢复滚动更新
kubectl rollout pause deployment/backend-api -n production
kubectl rollout resume deployment/backend-api -n production

# 重启Deployment
kubectl rollout restart deployment/backend-api -n production

# 扩缩容
kubectl scale deployment/backend-api --replicas=5 -n production
```

### ConfigMap & Secret
```bash
# 创建ConfigMap
kubectl create configmap app-config --from-file=config.yaml -n production

# 创建Secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secret123 \
  -n production

# 从文件创建Secret
kubectl create secret generic tls-secret \
  --from-file=tls.crt=./cert.pem \
  --from-file=tls.key=./key.pem \
  -n production

# 查看Secret（base64编码）
kubectl get secret db-secret -o yaml -n production

# 解码Secret
kubectl get secret db-secret -o jsonpath='{.data.password}' -n production | base64 --decode
```

### 故障排查
```bash
# 查看事件
kubectl get events -n production --sort-by='.lastTimestamp'

# 查看Pod状态详情
kubectl get pods -o wide -n production

# 查看失败的Pod
kubectl get pods --field-selector=status.phase=Failed -n production

# 查看Pod的资源请求和限制
kubectl get pods -n production -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.containers[0].resources.requests.memory

# 强制删除Pod
kubectl delete pod my-pod -n production --force --grace-period=0

# 查看节点状态
kubectl describe node node-1
```

### Helm命令
```bash
# 添加仓库
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 搜索Chart
helm search repo nginx

# 安装Chart
helm install my-release bitnami/nginx -n production --create-namespace

# 使用values文件安装
helm install my-release ./my-chart -f values-prod.yaml -n production

# 升级
helm upgrade my-release ./my-chart -f values-prod.yaml -n production

# 查看已安装的Release
helm list -n production

# 查看历史
helm history my-release -n production

# 回滚
helm rollback my-release 1 -n production

# 卸载
helm uninstall my-release -n production

# 测试Chart
helm lint ./my-chart
helm template my-release ./my-chart -f values-prod.yaml
```

---

## Git工作流

### 常用命令
```bash
# 克隆仓库
git clone https://github.com/username/repo.git
cd repo

# 创建并切换分支
git checkout -b feature/new-feature

# 提交代码
git add .
git commit -m "feat: add new feature"

# 推送到远程
git push origin feature/new-feature

# 同步主分支
git checkout main
git pull origin main
git checkout feature/new-feature
git rebase main

# 合并分支
git checkout main
git merge --no-ff feature/new-feature
git push origin main

# 删除分支
git branch -d feature/new-feature
git push origin --delete feature/new-feature

# 查看提交历史
git log --oneline --graph --all

# 撤销本地修改
git checkout -- file.txt

# 撤销最后一次提交（保留修改）
git reset --soft HEAD~1

# 撤销最后一次提交（不保留修改）
git reset --hard HEAD~1

# 修改最后一次提交
git commit --amend

# 储藏当前修改
git stash
git stash list
git stash pop

# 查看差异
git diff
git diff --staged
git diff main..feature/new-feature
```

### Conventional Commits规范
```
feat: 新功能
fix: 修复bug
docs: 文档修改
style: 代码格式（不影响功能）
refactor: 重构
perf: 性能优化
test: 测试相关
chore: 构建/工具链修改

示例：
feat(auth): add OAuth2 login
fix(api): resolve null pointer exception
docs(readme): update installation guide
```

---

## 数据库优化速查

### PostgreSQL
```sql
-- 查看慢查询
SELECT pid, now() - query_start as duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - query_start > interval '5 seconds';

-- 查看表大小
SELECT
  schemaname as schema,
  tablename as table,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- 查看索引使用情况
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- 分析查询计划
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- 创建索引
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- 分析表统计信息
ANALYZE users;

-- 查看锁等待
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

### MySQL
```sql
-- 查看慢查询
SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- 查看表大小
SELECT
  table_schema as `Database`,
  table_name AS `Table`,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS `Size (MB)`
FROM information_schema.TABLES
ORDER BY (data_length + index_length) DESC
LIMIT 10;

-- 查看索引使用情况
SELECT
  object_schema,
  object_name,
  index_name,
  count_star,
  count_read
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE index_name IS NOT NULL
ORDER BY count_star DESC;

-- 分析查询计划
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- 创建索引
ALTER TABLE users ADD INDEX idx_email (email);

-- 优化表
OPTIMIZE TABLE users;

-- 查看当前连接
SHOW PROCESSLIST;

-- 杀死慢查询
KILL <process_id>;
```

### 通用优化技巧
```sql
-- ❌ 避免SELECT *
SELECT * FROM users;

-- ✅ 只查询需要的字段
SELECT id, name, email FROM users;

-- ❌ 避免在WHERE中使用函数
SELECT * FROM orders WHERE YEAR(created_at) = 2024;

-- ✅ 直接比较日期
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';

-- ❌ 避免隐式类型转换
SELECT * FROM users WHERE id = '123'; -- id是INT类型

-- ✅ 使用正确类型
SELECT * FROM users WHERE id = 123;

-- ❌ 避免OR（可能不走索引）
SELECT * FROM users WHERE name = 'John' OR email = 'john@example.com';

-- ✅ 使用UNION
SELECT * FROM users WHERE name = 'John'
UNION
SELECT * FROM users WHERE email = 'john@example.com';

-- 批量插入
INSERT INTO users (name, email) VALUES
  ('John', 'john@example.com'),
  ('Jane', 'jane@example.com'),
  ('Bob', 'bob@example.com');
```

---

## Redis常用命令

### 连接与管理
```bash
# 连接Redis
redis-cli -h localhost -p 6379 -a password

# 查看信息
INFO
INFO memory
INFO stats

# 查看配置
CONFIG GET maxmemory
CONFIG SET maxmemory 2gb

# 监控命令
MONITOR

# 查看慢查询
SLOWLOG GET 10

# 查看客户端连接
CLIENT LIST

# 查看键统计
INFO keyspace

# 查看内存使用
MEMORY USAGE mykey
```

### 键操作
```bash
# 查看所有键（生产环境慎用！）
KEYS *

# 扫描键（推荐）
SCAN 0 MATCH user:* COUNT 100

# 查看键类型
TYPE mykey

# 查看过期时间
TTL mykey

# 设置过期时间
EXPIRE mykey 3600

# 删除键
DEL mykey

# 检查键是否存在
EXISTS mykey

# 重命名键
RENAME oldkey newkey
```

### 字符串操作
```bash
# 设置值
SET mykey "Hello"

# 设置值（带过期时间）
SETEX mykey 3600 "Hello"

# 仅当键不存在时设置
SETNX mykey "Hello"

# 获取值
GET mykey

# 批量设置
MSET key1 "value1" key2 "value2"

# 批量获取
MGET key1 key2

# 自增
INCR counter
INCRBY counter 10

# 自减
DECR counter
DECRBY counter 10
```

### 哈希操作
```bash
# 设置字段
HSET user:1 name "John" age 30

# 获取字段
HGET user:1 name

# 获取所有字段
HGETALL user:1

# 删除字段
HDEL user:1 age

# 检查字段是否存在
HEXISTS user:1 name

# 字段自增
HINCRBY user:1 age 1
```

### 列表操作
```bash
# 左侧推入
LPUSH mylist "value1"

# 右侧推入
RPUSH mylist "value2"

# 左侧弹出
LPOP mylist

# 右侧弹出
RPOP mylist

# 获取范围
LRANGE mylist 0 -1

# 获取长度
LLEN mylist

# 阻塞弹出（用于消息队列）
BLPOP mylist 10
```

### 集合操作
```bash
# 添加成员
SADD myset "member1" "member2"

# 获取所有成员
SMEMBERS myset

# 检查成员是否存在
SISMEMBER myset "member1"

# 删除成员
SREM myset "member1"

# 集合运算
SINTER set1 set2   # 交集
SUNION set1 set2   # 并集
SDIFF set1 set2    # 差集
```

### 有序集合操作
```bash
# 添加成员（带分数）
ZADD leaderboard 100 "player1" 200 "player2"

# 获取排名范围
ZRANGE leaderboard 0 9 WITHSCORES

# 获取逆序排名
ZREVRANGE leaderboard 0 9 WITHSCORES

# 获取成员排名
ZRANK leaderboard "player1"

# 获取成员分数
ZSCORE leaderboard "player1"

# 增加分数
ZINCRBY leaderboard 10 "player1"

# 按分数范围查询
ZRANGEBYSCORE leaderboard 100 200
```

---

## Kafka常用命令

### Topic管理
```bash
# 创建Topic
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --partitions 3 \
  --replication-factor 3

# 查看Topic列表
kafka-topics.sh --list --bootstrap-server localhost:9092

# 查看Topic详情
kafka-topics.sh --describe --topic my-topic --bootstrap-server localhost:9092

# 增加分区数
kafka-topics.sh --alter \
  --topic my-topic \
  --partitions 6 \
  --bootstrap-server localhost:9092

# 删除Topic
kafka-topics.sh --delete --topic my-topic --bootstrap-server localhost:9092
```

### 生产者
```bash
# 命令行生产消息
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic

# 带Key的消息
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --property "parse.key=true" \
  --property "key.separator=:"

# 性能测试
kafka-producer-perf-test.sh \
  --topic my-topic \
  --num-records 1000000 \
  --record-size 1024 \
  --throughput -1 \
  --producer-props bootstrap.servers=localhost:9092
```

### 消费者
```bash
# 从头消费
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --from-beginning

# 指定消费者组
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic my-topic \
  --group my-consumer-group

# 查看消费者组列表
kafka-consumer-groups.sh --list --bootstrap-server localhost:9092

# 查看消费者组详情
kafka-consumer-groups.sh \
  --describe \
  --group my-consumer-group \
  --bootstrap-server localhost:9092

# 重置offset到最早
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group my-consumer-group \
  --topic my-topic \
  --reset-offsets \
  --to-earliest \
  --execute

# 重置offset到指定时间
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group my-consumer-group \
  --topic my-topic \
  --reset-offsets \
  --to-datetime 2024-01-01T00:00:00.000 \
  --execute
```

---

## 性能调优参数

### JVM参数（Java 17+）
```bash
# 推荐配置（8GB堆内存）
java -Xms8g -Xmx8g \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+ParallelRefProcEnabled \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1HeapRegionSize=16M \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=35 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/tmp/heapdump.hprof \
  -XX:+PrintGCDetails \
  -XX:+PrintGCDateStamps \
  -Xloggc:/var/log/gc.log \
  -jar app.jar
```

### PostgreSQL配置
```ini
# /var/lib/postgresql/data/postgresql.conf

# 连接数（根据实际需求）
max_connections = 200

# 共享内存（通常是系统RAM的25%）
shared_buffers = 2GB

# 有效缓存大小（通常是系统RAM的50%-75%）
effective_cache_size = 6GB

# 维护工作内存（用于VACUUM, CREATE INDEX）
maintenance_work_mem = 512MB

# 工作内存（每个查询）
work_mem = 16MB

# WAL缓冲区
wal_buffers = 16MB

# 检查点
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 1GB

# 查询规划
random_page_cost = 1.1  # SSD
effective_io_concurrency = 200  # SSD

# 日志
log_min_duration_statement = 1000  # 记录超过1秒的查询
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### MySQL配置
```ini
# /etc/my.cnf

[mysqld]
# 连接数
max_connections = 500

# InnoDB缓冲池（通常是系统RAM的70%-80%）
innodb_buffer_pool_size = 6G
innodb_buffer_pool_instances = 6

# 日志文件大小
innodb_log_file_size = 1G

# 刷新策略
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# 线程并发
innodb_thread_concurrency = 0
innodb_read_io_threads = 4
innodb_write_io_threads = 4

# 查询缓存（MySQL 5.7，8.0已移除）
query_cache_type = 0
query_cache_size = 0

# 慢查询日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
```

### Redis配置
```ini
# /etc/redis/redis.conf

# 最大内存（根据实际需求）
maxmemory 2gb

# 内存淘汰策略
maxmemory-policy allkeys-lru

# 持久化（AOF）
appendonly yes
appendfsync everysec

# RDB快照
save 900 1
save 300 10
save 60 10000

# 慢查询阈值（微秒）
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端输出缓冲区
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# TCP backlog
tcp-backlog 511

# 超时
timeout 0
tcp-keepalive 300
```

### Nginx配置
```nginx
# /etc/nginx/nginx.conf

user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # 基础配置
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    types_hash_max_size 2048;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    # 缓存
    open_file_cache max=10000 inactive=60s;
    open_file_cache_valid 120s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # 上传限制
    client_max_body_size 100M;
    client_body_buffer_size 128k;

    # 超时设置
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    '$request_time $upstream_response_time';

    access_log /var/log/nginx/access.log main;
}
```

---

## 故障排查清单

### 服务不可用
1. ✅ 检查服务是否运行：`systemctl status myapp` 或 `kubectl get pods`
2. ✅ 检查端口是否监听：`netstat -tlnp | grep 8080`
3. ✅ 检查防火墙：`iptables -L` 或 `ufw status`
4. ✅ 检查日志：`tail -f /var/log/myapp/app.log`
5. ✅ 检查网络连通性：`ping`, `telnet`, `curl`

### 性能问题
1. ✅ 检查CPU使用率：`top`, `htop`
2. ✅ 检查内存使用：`free -h`, `vmstat`
3. ✅ 检查磁盘IO：`iostat`, `iotop`
4. ✅ 检查网络流量：`iftop`, `nethogs`
5. ✅ 检查慢查询：数据库慢查询日志
6. ✅ 检查缓存命中率：Redis `INFO stats`
7. ✅ 检查JVM GC：`jstat -gcutil <pid> 1000`

### 数据库问题
1. ✅ 检查连接数：`SELECT count(*) FROM pg_stat_activity`
2. ✅ 检查锁等待：查询锁等待SQL
3. ✅ 检查慢查询：`SELECT * FROM pg_stat_statements`
4. ✅ 检查索引使用：`EXPLAIN ANALYZE`
5. ✅ 检查表大小：查询表大小SQL
6. ✅ 检查缓冲池命中率：`SELECT * FROM pg_stat_database`

### 内存泄漏
1. ✅ 生成堆转储：`jmap -dump:format=b,file=heap.bin <pid>`
2. ✅ 使用MAT分析：导入heap.bin到Eclipse MAT
3. ✅ 查看对象占用：查找最大对象
4. ✅ 检查缓存配置：是否缓存过大
5. ✅ 检查连接泄漏：数据库连接是否关闭

### 网络问题
1. ✅ 检查DNS解析：`nslookup domain.com`
2. ✅ 检查路由：`traceroute domain.com`
3. ✅ 检查端口连通性：`telnet host port`
4. ✅ 抓包分析：`tcpdump -i eth0 port 8080 -w capture.pcap`
5. ✅ 检查防火墙规则：`iptables -L -n -v`

---

## 生产环境最佳实践速查

### ✅ 部署前检查清单
- [ ] 所有测试通过（单元/集成/E2E）
- [ ] 代码审查完成
- [ ] 安全扫描通过（无高危漏洞）
- [ ] 性能测试达标
- [ ] 数据库迁移脚本已测试
- [ ] 回滚方案已准备
- [ ] 监控告警已配置
- [ ] 文档已更新
- [ ] 相关团队已通知

### ✅ 安全配置清单
- [ ] 使用HTTPS（TLS 1.2+）
- [ ] 敏感信息使用密钥管理（Vault）
- [ ] 最小权限原则（RBAC）
- [ ] 定期更新依赖（修复漏洞）
- [ ] 启用审计日志
- [ ] 配置防火墙规则
- [ ] 定期备份（每日全量+实时增量）
- [ ] 备份加密存储
- [ ] 定期演练恢复流程

### ✅ 性能优化清单
- [ ] 数据库索引优化
- [ ] 启用查询缓存（Redis）
- [ ] 静态资源CDN加速
- [ ] 启用Gzip压缩
- [ ] 图片使用WebP格式
- [ ] 代码分割与懒加载
- [ ] 数据库连接池配置
- [ ] JVM参数调优
- [ ] 异步处理耗时操作

---

**提示**：这份速查手册应该打印出来放在显示器旁边，或保存为浏览器书签！

💡 需要更详细的说明？请查看完整文档：
- [00-comprehensive-challenges.md](./00-comprehensive-challenges.md)
- [02-technology-selection-guide.md](./02-technology-selection-guide.md)
- [03-deployment-devops-guide.md](./03-deployment-devops-guide.md)
- [04-high-availability-performance.md](./04-high-availability-performance.md)
