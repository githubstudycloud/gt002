# 高可用与性能优化完整指南

## 1. 数据库高可用架构

### 1.1 PostgreSQL高可用方案

#### 主从复制架构
```yaml
# docker-compose.yml - PostgreSQL主从复制
version: '3.8'
services:
  postgres-primary:
    image: postgres:16
    environment:
      POSTGRES_USER: replicator
      POSTGRES_PASSWORD: replicator_password
      POSTGRES_DB: myapp
    volumes:
      - pg-primary-data:/var/lib/postgresql/data
      - ./primary-setup.sh:/docker-entrypoint-initdb.d/setup.sh
    command: |
      postgres
      -c wal_level=replica
      -c hot_standby=on
      -c max_wal_senders=10
      -c max_replication_slots=10
      -c hot_standby_feedback=on
    ports:
      - "5432:5432"

  postgres-replica-1:
    image: postgres:16
    environment:
      PGUSER: replicator
      PGPASSWORD: replicator_password
    depends_on:
      - postgres-primary
    command: |
      bash -c "
      until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot_1 --host=postgres-primary --port=5432
      do
        echo 'Waiting for primary to connect...'
        sleep 1s
      done
      echo 'Backup done, starting replica...'
      postgres
      "
    volumes:
      - pg-replica-1-data:/var/lib/postgresql/data

  postgres-replica-2:
    image: postgres:16
    environment:
      PGUSER: replicator
      PGPASSWORD: replicator_password
    depends_on:
      - postgres-primary
    command: |
      bash -c "
      until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot_2 --host=postgres-primary --port=5432
      do
        echo 'Waiting for primary to connect...'
        sleep 1s
      done
      echo 'Backup done, starting replica...'
      postgres
      "
    volumes:
      - pg-replica-2-data:/var/lib/postgresql/data

volumes:
  pg-primary-data:
  pg-replica-1-data:
  pg-replica-2-data:
```

#### 读写分离配置（Spring Boot）
```java
// 数据源配置
@Configuration
public class DataSourceConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.primary")
    public DataSource primaryDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean
    @ConfigurationProperties("spring.datasource.replica")
    public DataSource replicaDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean
    public DataSource routingDataSource() {
        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put(DataSourceType.PRIMARY, primaryDataSource());
        targetDataSources.put(DataSourceType.REPLICA, replicaDataSource());

        DynamicRoutingDataSource routingDataSource = new DynamicRoutingDataSource();
        routingDataSource.setTargetDataSources(targetDataSources);
        routingDataSource.setDefaultTargetDataSource(primaryDataSource());
        return routingDataSource;
    }
}

// 动态数据源路由
public class DynamicRoutingDataSource extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        return DataSourceContextHolder.getDataSourceType();
    }
}

// 数据源切换
public class DataSourceContextHolder {
    private static final ThreadLocal<DataSourceType> contextHolder = new ThreadLocal<>();

    public static void setDataSourceType(DataSourceType type) {
        contextHolder.set(type);
    }

    public static DataSourceType getDataSourceType() {
        return contextHolder.get() != null ? contextHolder.get() : DataSourceType.PRIMARY;
    }

    public static void clearDataSourceType() {
        contextHolder.remove();
    }
}

// 注解驱动的读写分离
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ReadOnly {
}

@Aspect
@Component
public class DataSourceAspect {

    @Around("@annotation(readOnly)")
    public Object setReadDataSource(ProceedingJoinPoint pjp, ReadOnly readOnly) throws Throwable {
        try {
            DataSourceContextHolder.setDataSourceType(DataSourceType.REPLICA);
            return pjp.proceed();
        } finally {
            DataSourceContextHolder.clearDataSourceType();
        }
    }
}

// 使用示例
@Service
public class UserService {

    @Transactional
    public void createUser(User user) {
        // 自动路由到主库
        userRepository.save(user);
    }

    @ReadOnly
    @Transactional(readOnly = true)
    public User getUser(Long id) {
        // 自动路由到从库
        return userRepository.findById(id).orElse(null);
    }
}
```

---

### 1.2 MySQL分库分表（ShardingSphere）

#### ShardingSphere-JDBC配置
```yaml
# application.yml
spring:
  shardingsphere:
    datasource:
      names: ds0,ds1,ds2
      ds0:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://db0:3306/order_db
        username: root
        password: password
      ds1:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://db1:3306/order_db
        username: root
        password: password
      ds2:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://db2:3306/order_db
        username: root
        password: password

    rules:
      sharding:
        tables:
          # 订单表分库分表
          t_order:
            actual-data-nodes: ds$->{0..2}.t_order_$->{0..15}
            database-strategy:
              standard:
                sharding-column: user_id
                sharding-algorithm-name: database-inline
            table-strategy:
              standard:
                sharding-column: order_id
                sharding-algorithm-name: table-inline
            key-generate-strategy:
              column: order_id
              key-generator-name: snowflake

          # 订单项表
          t_order_item:
            actual-data-nodes: ds$->{0..2}.t_order_item_$->{0..15}
            database-strategy:
              standard:
                sharding-column: user_id
                sharding-algorithm-name: database-inline
            table-strategy:
              standard:
                sharding-column: order_id
                sharding-algorithm-name: table-inline
            key-generate-strategy:
              column: item_id
              key-generator-name: snowflake

        binding-tables:
          - t_order,t_order_item

        sharding-algorithms:
          database-inline:
            type: INLINE
            props:
              algorithm-expression: ds$->{user_id % 3}
          table-inline:
            type: INLINE
            props:
              algorithm-expression: t_order_$->{order_id % 16}

        key-generators:
          snowflake:
            type: SNOWFLAKE
            props:
              worker-id: 123

    props:
      sql-show: true
```

#### 分库分表最佳实践
```java
// 1. 使用分布式ID生成器
@Service
public class OrderService {

    @Autowired
    private SnowflakeIdGenerator idGenerator;

    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        Order order = new Order();
        // 使用雪花算法生成全局唯一ID
        order.setOrderId(idGenerator.nextId());
        order.setUserId(request.getUserId());
        // ... 其他字段

        return orderRepository.save(order);
    }
}

// 2. 跨片查询优化
@Service
public class OrderQueryService {

    // 按分片键查询 - 路由到单个分片
    public List<Order> getUserOrders(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    // 跨片查询 - 需要聚合多个分片结果
    public Page<Order> searchOrders(OrderSearchCriteria criteria, Pageable pageable) {
        // 使用ElasticSearch等搜索引擎代替跨片查询
        return orderSearchRepository.search(criteria, pageable);
    }
}

// 3. 分布式事务处理（Saga模式）
@Service
public class OrderSagaService {

    @Autowired
    private OrderService orderService;
    @Autowired
    private InventoryService inventoryService;
    @Autowired
    private PaymentService paymentService;

    public void createOrderSaga(CreateOrderRequest request) {
        // 本地事务：创建订单（pending状态）
        Order order = orderService.createOrder(request);

        try {
            // 远程调用：扣减库存
            inventoryService.reserveStock(order.getItems());

            // 远程调用：扣款
            paymentService.charge(order.getUserId(), order.getTotalAmount());

            // 成功：更新订单状态
            orderService.updateOrderStatus(order.getId(), OrderStatus.PAID);

        } catch (Exception e) {
            // 失败：补偿操作
            compensate(order);
            throw e;
        }
    }

    private void compensate(Order order) {
        try {
            inventoryService.releaseStock(order.getItems());
        } catch (Exception e) {
            // 记录补偿失败，人工介入
            log.error("Compensation failed for order: {}", order.getId(), e);
        }
    }
}
```

---

## 2. 缓存架构设计

### 2.1 多级缓存架构

```
客户端 → CDN缓存 → 网关缓存(Nginx) → 应用缓存(Caffeine) → 分布式缓存(Redis) → 数据库
```

#### 本地缓存 + 分布式缓存
```java
@Configuration
public class CacheConfig {

    @Bean
    public Caffeine<Object, Object> caffeineConfig() {
        return Caffeine.newBuilder()
            .maximumSize(10000)
            .expireAfterWrite(10, TimeUnit.MINUTES)
            .recordStats();
    }

    @Bean
    public CacheManager cacheManager(Caffeine caffeine, RedisConnectionFactory connectionFactory) {
        // 二级缓存：本地缓存 + Redis
        return new MultiLevelCacheManager(
            new CaffeineCacheManager(),
            new RedisCacheManager(RedisCacheWriter.nonLockingRedisCacheWriter(connectionFactory))
        );
    }
}

// 多级缓存管理器
public class MultiLevelCacheManager implements CacheManager {
    private final CacheManager l1CacheManager; // 本地缓存
    private final CacheManager l2CacheManager; // 分布式缓存

    @Override
    public Cache getCache(String name) {
        return new MultiLevelCache(
            l1CacheManager.getCache(name),
            l2CacheManager.getCache(name)
        );
    }
}

public class MultiLevelCache implements Cache {
    private final Cache l1Cache;
    private final Cache l2Cache;

    @Override
    public ValueWrapper get(Object key) {
        // 先查L1缓存
        ValueWrapper value = l1Cache.get(key);
        if (value != null) {
            return value;
        }

        // 再查L2缓存
        value = l2Cache.get(key);
        if (value != null) {
            // 回填L1缓存
            l1Cache.put(key, value.get());
        }

        return value;
    }

    @Override
    public void put(Object key, Object value) {
        l1Cache.put(key, value);
        l2Cache.put(key, value);
    }

    @Override
    public void evict(Object key) {
        l1Cache.evict(key);
        l2Cache.evict(key);
        // 发布缓存失效消息，通知其他节点
        publishInvalidationMessage(key);
    }
}
```

---

### 2.2 缓存一致性方案

#### Cache-Aside模式（最常用）
```java
@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private RedisTemplate<String, Product> redisTemplate;

    private static final String CACHE_KEY_PREFIX = "product:";

    // 读操作
    public Product getProduct(Long id) {
        String key = CACHE_KEY_PREFIX + id;

        // 1. 查询缓存
        Product product = redisTemplate.opsForValue().get(key);
        if (product != null) {
            return product;
        }

        // 2. 缓存未命中，查询数据库
        product = productRepository.findById(id).orElse(null);
        if (product != null) {
            // 3. 写入缓存
            redisTemplate.opsForValue().set(key, product, 30, TimeUnit.MINUTES);
        }

        return product;
    }

    // 写操作
    @Transactional
    public Product updateProduct(Long id, ProductUpdateRequest request) {
        // 1. 更新数据库
        Product product = productRepository.findById(id).orElseThrow();
        product.setName(request.getName());
        product.setPrice(request.getPrice());
        productRepository.save(product);

        // 2. 删除缓存（而不是更新缓存）
        String key = CACHE_KEY_PREFIX + id;
        redisTemplate.delete(key);

        return product;
    }
}
```

#### 延迟双删策略
```java
@Service
public class ProductService {

    @Transactional
    public Product updateProduct(Long id, ProductUpdateRequest request) {
        String key = CACHE_KEY_PREFIX + id;

        // 第一次删除缓存
        redisTemplate.delete(key);

        // 更新数据库
        Product product = productRepository.findById(id).orElseThrow();
        product.setName(request.getName());
        productRepository.save(product);

        // 延迟后再次删除缓存（防止脏读）
        CompletableFuture.runAsync(() -> {
            try {
                Thread.sleep(500); // 延迟500ms
                redisTemplate.delete(key);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });

        return product;
    }
}
```

#### Canal监听MySQL binlog同步缓存
```java
// 监听MySQL binlog变更，异步更新缓存
@Component
public class CanalClient {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @PostConstruct
    public void start() {
        CanalConnector connector = CanalConnectors.newSingleConnector(
            new InetSocketAddress("127.0.0.1", 11111),
            "example", "", ""
        );

        new Thread(() -> {
            connector.connect();
            connector.subscribe(".*\\..*");
            connector.rollback();

            while (true) {
                Message message = connector.getWithoutAck(100);
                long batchId = message.getId();

                if (batchId == -1 || message.getEntries().isEmpty()) {
                    continue;
                }

                for (CanalEntry.Entry entry : message.getEntries()) {
                    if (entry.getEntryType() == CanalEntry.EntryType.ROWDATA) {
                        processEntry(entry);
                    }
                }

                connector.ack(batchId);
            }
        }).start();
    }

    private void processEntry(CanalEntry.Entry entry) {
        String tableName = entry.getHeader().getTableName();
        CanalEntry.RowChange rowChange = CanalEntry.RowChange.parseFrom(entry.getStoreValue());

        for (CanalEntry.RowData rowData : rowChange.getRowDatasList()) {
            if (rowChange.getEventType() == CanalEntry.EventType.UPDATE ||
                rowChange.getEventType() == CanalEntry.EventType.DELETE) {
                // 删除缓存
                String id = rowData.getBeforeColumnsList().stream()
                    .filter(col -> col.getName().equals("id"))
                    .findFirst()
                    .map(CanalEntry.Column::getValue)
                    .orElse(null);

                if (id != null) {
                    redisTemplate.delete(tableName + ":" + id);
                }
            }
        }
    }
}
```

---

### 2.3 缓存雪崩/击穿/穿透防护

#### 缓存雪崩防护
```java
@Service
public class CacheService {

    // 方案1: 随机过期时间
    public void setCacheWithRandomExpiry(String key, Object value) {
        int baseExpiry = 3600; // 1小时
        int randomExpiry = ThreadLocalRandom.current().nextInt(0, 600); // 0-10分钟随机
        redisTemplate.opsForValue().set(key, value, baseExpiry + randomExpiry, TimeUnit.SECONDS);
    }

    // 方案2: 缓存预热
    @Scheduled(cron = "0 0 2 * * ?") // 每天凌晨2点
    public void warmUpCache() {
        List<Product> hotProducts = productRepository.findHotProducts();
        for (Product product : hotProducts) {
            String key = "product:" + product.getId();
            redisTemplate.opsForValue().set(key, product, 1, TimeUnit.DAYS);
        }
    }

    // 方案3: 互斥锁重建缓存
    public Product getProductWithMutex(Long id) {
        String key = "product:" + id;
        String lockKey = "lock:product:" + id;

        Product product = (Product) redisTemplate.opsForValue().get(key);
        if (product != null) {
            return product;
        }

        // 尝试获取锁
        Boolean locked = redisTemplate.opsForValue().setIfAbsent(lockKey, "1", 10, TimeUnit.SECONDS);
        if (Boolean.TRUE.equals(locked)) {
            try {
                // 双重检查
                product = (Product) redisTemplate.opsForValue().get(key);
                if (product != null) {
                    return product;
                }

                // 查询数据库
                product = productRepository.findById(id).orElse(null);
                if (product != null) {
                    redisTemplate.opsForValue().set(key, product, 30, TimeUnit.MINUTES);
                }
                return product;
            } finally {
                redisTemplate.delete(lockKey);
            }
        } else {
            // 等待锁释放后重试
            try {
                Thread.sleep(50);
                return getProductWithMutex(id);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return null;
            }
        }
    }
}
```

#### 缓存穿透防护（布隆过滤器）
```java
@Configuration
public class BloomFilterConfig {

    @Bean
    public BloomFilter<Long> productBloomFilter() {
        // 预计100万商品，误判率0.01%
        BloomFilter<Long> filter = BloomFilter.create(
            Funnels.longFunnel(),
            1000000,
            0.0001
        );

        // 初始化：加载所有商品ID
        List<Long> allProductIds = productRepository.findAllIds();
        allProductIds.forEach(filter::put);

        return filter;
    }
}

@Service
public class ProductService {

    @Autowired
    private BloomFilter<Long> productBloomFilter;

    public Product getProduct(Long id) {
        // 先用布隆过滤器判断
        if (!productBloomFilter.mightContain(id)) {
            return null; // 一定不存在
        }

        // 可能存在，查询缓存和数据库
        String key = "product:" + id;
        Product product = (Product) redisTemplate.opsForValue().get(key);
        if (product != null) {
            return product;
        }

        product = productRepository.findById(id).orElse(null);
        if (product != null) {
            redisTemplate.opsForValue().set(key, product, 30, TimeUnit.MINUTES);
        } else {
            // 缓存空对象，防止穿透
            redisTemplate.opsForValue().set(key, NULL_VALUE, 5, TimeUnit.MINUTES);
        }

        return product;
    }
}
```

---

## 3. 限流与熔断

### 3.1 限流算法实现

#### 令牌桶算法（Guava RateLimiter）
```java
@Component
public class RateLimitService {

    // 每秒允许100个请求
    private final RateLimiter rateLimiter = RateLimiter.create(100);

    public boolean tryAcquire() {
        return rateLimiter.tryAcquire(100, TimeUnit.MILLISECONDS);
    }
}

@RestController
public class ApiController {

    @Autowired
    private RateLimitService rateLimitService;

    @GetMapping("/api/data")
    public ResponseEntity<?> getData() {
        if (!rateLimitService.tryAcquire()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .body("Rate limit exceeded");
        }

        // 处理请求
        return ResponseEntity.ok(service.getData());
    }
}
```

#### 滑动窗口算法（Redis实现）
```java
@Component
public class SlidingWindowRateLimiter {

    @Autowired
    private StringRedisTemplate redisTemplate;

    public boolean isAllowed(String key, int limit, int windowSize) {
        long now = System.currentTimeMillis();
        long windowStart = now - windowSize * 1000L;

        String redisKey = "rate_limit:" + key;

        // 使用Lua脚本保证原子性
        String luaScript =
            "redis.call('zremrangebyscore', KEYS[1], 0, ARGV[1]) " +
            "local count = redis.call('zcard', KEYS[1]) " +
            "if count < tonumber(ARGV[3]) then " +
            "  redis.call('zadd', KEYS[1], ARGV[2], ARGV[2]) " +
            "  redis.call('expire', KEYS[1], ARGV[4]) " +
            "  return 1 " +
            "else " +
            "  return 0 " +
            "end";

        RedisScript<Long> script = RedisScript.of(luaScript, Long.class);
        Long result = redisTemplate.execute(
            script,
            Collections.singletonList(redisKey),
            String.valueOf(windowStart),
            String.valueOf(now),
            String.valueOf(limit),
            String.valueOf(windowSize)
        );

        return result != null && result == 1;
    }
}
```

#### 分布式限流（Redis + Lua）
```java
@Component
public class DistributedRateLimiter {

    @Autowired
    private StringRedisTemplate redisTemplate;

    // Lua脚本：令牌桶算法
    private static final String TOKEN_BUCKET_SCRIPT =
        "local key = KEYS[1] " +
        "local capacity = tonumber(ARGV[1]) " +
        "local rate = tonumber(ARGV[2]) " +
        "local requested = tonumber(ARGV[3]) " +
        "local now = tonumber(ARGV[4]) " +

        "local last_time = redis.call('hget', key, 'last_time') " +
        "local tokens = redis.call('hget', key, 'tokens') " +

        "if last_time == false then " +
        "  last_time = now " +
        "  tokens = capacity " +
        "else " +
        "  local delta = math.max(0, now - last_time) " +
        "  tokens = math.min(capacity, tokens + delta * rate) " +
        "end " +

        "if tokens >= requested then " +
        "  tokens = tokens - requested " +
        "  redis.call('hmset', key, 'last_time', now, 'tokens', tokens) " +
        "  redis.call('expire', key, 3600) " +
        "  return 1 " +
        "else " +
        "  return 0 " +
        "end";

    public boolean tryAcquire(String resource, int capacity, double rate, int requested) {
        RedisScript<Long> script = RedisScript.of(TOKEN_BUCKET_SCRIPT, Long.class);
        Long result = redisTemplate.execute(
            script,
            Collections.singletonList("rate_limit:" + resource),
            String.valueOf(capacity),
            String.valueOf(rate),
            String.valueOf(requested),
            String.valueOf(System.currentTimeMillis())
        );
        return result != null && result == 1;
    }
}
```

---

### 3.2 熔断降级（Resilience4j）

```java
@Configuration
public class Resilience4jConfig {

    @Bean
    public CircuitBreaker circuitBreaker() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
            .failureRateThreshold(50) // 失败率50%触发熔断
            .slowCallRateThreshold(50) // 慢调用率50%触发熔断
            .slowCallDurationThreshold(Duration.ofSeconds(2)) // 超过2秒算慢调用
            .waitDurationInOpenState(Duration.ofSeconds(60)) // 熔断后等待60秒
            .permittedNumberOfCallsInHalfOpenState(10) // 半开状态允许10个请求
            .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.TIME_BASED)
            .slidingWindowSize(100) // 滑动窗口100秒
            .minimumNumberOfCalls(10) // 最少10个请求才计算失败率
            .build();

        return CircuitBreaker.of("externalService", config);
    }

    @Bean
    public Bulkhead bulkhead() {
        BulkheadConfig config = BulkheadConfig.custom()
            .maxConcurrentCalls(10) // 最大并发10
            .maxWaitDuration(Duration.ofMillis(500)) // 最大等待500ms
            .build();

        return Bulkhead.of("externalService", config);
    }

    @Bean
    public Retry retry() {
        RetryConfig config = RetryConfig.custom()
            .maxAttempts(3) // 最多重试3次
            .waitDuration(Duration.ofSeconds(1)) // 重试间隔1秒
            .retryExceptions(IOException.class, TimeoutException.class)
            .ignoreExceptions(BusinessException.class)
            .build();

        return Retry.of("externalService", config);
    }
}

@Service
public class ExternalService {

    @Autowired
    private CircuitBreaker circuitBreaker;

    @Autowired
    private Bulkhead bulkhead;

    @Autowired
    private Retry retry;

    @Autowired
    private RestTemplate restTemplate;

    public String callExternalApi(String endpoint) {
        Supplier<String> supplier = () -> restTemplate.getForObject(endpoint, String.class);

        // 组合使用：重试 -> 舱壁 -> 熔断
        supplier = Retry.decorateSupplier(retry, supplier);
        supplier = Bulkhead.decorateSupplier(bulkhead, supplier);
        supplier = CircuitBreaker.decorateSupplier(circuitBreaker, supplier);

        try {
            return supplier.get();
        } catch (Exception e) {
            // 降级逻辑
            return fallback();
        }
    }

    private String fallback() {
        return "Service temporarily unavailable";
    }
}
```

---

## 4. 消息队列高可用

### 4.1 Kafka高可用配置

```yaml
# Kafka集群配置
version: '3.8'
services:
  zookeeper:
    image: bitnami/zookeeper:latest
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
    ports:
      - "2181:2181"

  kafka-1:
    image: bitnami/kafka:3.6
    environment:
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_BROKER_ID=1
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-1:9092
      - KAFKA_CFG_NUM_PARTITIONS=3
      - KAFKA_CFG_DEFAULT_REPLICATION_FACTOR=3
      - KAFKA_CFG_MIN_INSYNC_REPLICAS=2
    depends_on:
      - zookeeper

  kafka-2:
    image: bitnami/kafka:3.6
    environment:
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_BROKER_ID=2
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-2:9092
    depends_on:
      - zookeeper

  kafka-3:
    image: bitnami/kafka:3.6
    environment:
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_CFG_BROKER_ID=3
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka-3:9092
    depends_on:
      - zookeeper
```

#### Kafka生产者高可用配置
```java
@Configuration
public class KafkaProducerConfig {

    @Bean
    public ProducerFactory<String, String> producerFactory() {
        Map<String, Object> config = new HashMap<>();
        config.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka-1:9092,kafka-2:9092,kafka-3:9092");

        // 高可用配置
        config.put(ProducerConfig.ACKS_CONFIG, "all"); // 等待所有副本确认
        config.put(ProducerConfig.RETRIES_CONFIG, 3); // 重试3次
        config.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 1); // 保证顺序
        config.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true); // 幂等性

        // 性能优化
        config.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
        config.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        config.put(ProducerConfig.LINGER_MS_CONFIG, 10);
        config.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);

        return new DefaultKafkaProducerFactory<>(config);
    }

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }
}

@Service
public class OrderEventProducer {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    public void sendOrderEvent(OrderEvent event) {
        String topic = "order-events";
        String key = String.valueOf(event.getOrderId());
        String value = JSON.toJSONString(event);

        // 异步发送with回调
        ListenableFuture<SendResult<String, String>> future =
            kafkaTemplate.send(topic, key, value);

        future.addCallback(
            result -> log.info("Sent message=[{}] with offset=[{}]",
                value, result.getRecordMetadata().offset()),
            ex -> log.error("Unable to send message=[{}] due to: {}",
                value, ex.getMessage())
        );
    }
}
```

#### Kafka消费者高可用配置
```java
@Configuration
public class KafkaConsumerConfig {

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        Map<String, Object> config = new HashMap<>();
        config.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka-1:9092,kafka-2:9092,kafka-3:9092");
        config.put(ConsumerConfig.GROUP_ID_CONFIG, "order-service");

        // 高可用配置
        config.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false); // 手动提交
        config.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        config.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100); // 每次拉取100条
        config.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, 300000); // 5分钟
        config.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, 10000);
        config.put(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG, 3000);

        return new DefaultKafkaConsumerFactory<>(config);
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory =
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.setConcurrency(3); // 3个并发消费者
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL_IMMEDIATE);
        return factory;
    }
}

@Component
public class OrderEventConsumer {

    @KafkaListener(topics = "order-events", groupId = "order-service")
    public void consume(ConsumerRecord<String, String> record, Acknowledgment ack) {
        try {
            OrderEvent event = JSON.parseObject(record.value(), OrderEvent.class);
            processOrder(event);

            // 处理成功，手动提交offset
            ack.acknowledge();

        } catch (Exception e) {
            log.error("Failed to process message: {}", record.value(), e);
            // 处理失败，发送到死信队列
            sendToDeadLetterQueue(record);
        }
    }
}
```

---

## 5. 性能优化清单

### 5.1 数据库优化
- [ ] 创建合适的索引（避免全表扫描）
- [ ] 使用EXPLAIN分析查询计划
- [ ] 避免SELECT *，只查询需要的字段
- [ ] 批量操作代替单条操作
- [ ] 使用连接池（HikariCP推荐配置）
- [ ] 读写分离（主从复制）
- [ ] 分库分表（单表超过500万行考虑）
- [ ] 使用Redis缓存热点数据
- [ ] 定期归档历史数据

### 5.2 应用优化
- [ ] JVM参数调优（G1GC for Java 17+）
- [ ] 异步处理耗时操作
- [ ] 使用消息队列削峰填谷
- [ ] 启用HTTP/2
- [ ] 启用gzip压缩
- [ ] 静态资源CDN加速
- [ ] 图片使用WebP格式
- [ ] 懒加载与虚拟滚动
- [ ] 代码分割与按需加载

### 5.3 监控指标
- [ ] RED指标：Rate, Errors, Duration
- [ ] 数据库连接池使用率
- [ ] 缓存命中率
- [ ] 消息队列积压
- [ ] JVM内存与GC
- [ ] 慢查询日志

---

这份高可用与性能优化指南提供了生产级的架构方案和代码实现，涵盖了数据库、缓存、限流熔断、消息队列等核心组件的高可用设计。