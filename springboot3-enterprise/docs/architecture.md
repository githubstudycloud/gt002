# 系统架构设计

## 目录
- [整体架构](#整体架构)
- [技术架构](#技术架构)
- [微服务拆分](#微服务拆分)
- [数据架构](#数据架构)
- [安全架构](#安全架构)
- [高可用架构](#高可用架构)
- [性能优化](#性能优化)

## 整体架构

### 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端层                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ Web App │  │ Mobile  │  │  小程序  │  │ 第三方  │        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
└───────┼────────────┼────────────┼────────────┼─────────────┘
        │            │            │            │
┌───────┼────────────┼────────────┼────────────┼─────────────┐
│       │            │            │            │               │
│       └────────────┴────────────┴────────────┘               │
│                         │                                    │
│                    ┌────▼────┐                               │
│                    │ Ingress │                               │
│                    └────┬────┘                               │
│                         │                                    │
│                    ┌────▼────┐                               │
│                    │   CDN   │ (静态资源)                     │
│                    └────┬────┘                               │
│                         │                                    │
│                    ┌────▼────────┐                           │
│                    │ API Gateway │  ◄─── 接入层               │
│                    │  (路由/鉴权) │                           │
│                    └──────┬──────┘                           │
└───────────────────────────┼──────────────────────────────────┘
                            │
┌───────────────────────────┼──────────────────────────────────┐
│                      业务服务层                                │
│    ┌───────────────────────────────────────────┐             │
│    │                                           │             │
│  ┌─▼──────────┐  ┌──────────┐  ┌──────────┐  │             │
│  │ Auth       │  │  User    │  │ Product  │  │             │
│  │ Service    │  │ Service  │  │ Service  │  │             │
│  └────────────┘  └──────────┘  └──────────┘  │             │
│                                               │             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │             │
│  │  Order   │  │ Payment  │  │Inventory │   │             │
│  │ Service  │  │ Service  │  │ Service  │   │             │
│  └──────────┘  └──────────┘  └──────────┘   │             │
│                                               │             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │             │
│  │Notifica- │  │  Search  │  │Analytics │   │             │
│  │  tion    │  │ Service  │  │ Service  │   │             │
│  └──────────┘  └──────────┘  └──────────┘   │             │
│                                               │             │
└───────────────────────────┼───────────────────┴─────────────┘
                            │
┌───────────────────────────┼──────────────────────────────────┐
│                      基础设施层                                │
│                            │                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Nacos   │  │  Redis   │  │  Kafka   │  │  Jaeger  │    │
│  │(注册/配置)│  │  (缓存)  │  │ (消息)   │  │  (追踪)  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │PostgreSQL│  │  Elastic │  │Prometheus│  │ Grafana  │    │
│  │  (主库)  │  │  (搜索)  │  │  (监控)  │  │ (可视化) │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└──────────────────────────────────────────────────────────────┘
```

## 技术架构

### 核心技术栈

#### 后端框架
```
Spring Boot 3.2+
├── Spring Web / WebFlux      # Web 框架
├── Spring Security 6          # 安全框架
├── Spring Data JPA           # 数据访问
├── Spring Cloud Gateway      # API 网关
├── Spring Cloud OpenFeign    # 服务调用
└── Spring Cloud Stream       # 消息驱动
```

#### 服务治理
```
Spring Cloud 2023.x
├── Nacos Discovery          # 服务注册发现
├── Nacos Config            # 配置中心
├── Resilience4j            # 熔断限流
├── LoadBalancer            # 负载均衡
└── Sleuth + Micrometer     # 链路追踪
```

#### 数据存储
```
Data Layer
├── PostgreSQL              # 关系型数据库
├── Redis                   # 缓存 + 会话
├── Elasticsearch           # 全文搜索
├── MongoDB                 # 文档数据库
└── ClickHouse             # 分析型数据库
```

#### 消息队列
```
Messaging
├── Apache Kafka            # 事件流
├── RabbitMQ               # 任务队列
└── Spring Cloud Stream    # 消息抽象
```

### 代码结构

```
service-name/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/enterprise/service/
│   │   │       ├── ServiceApplication.java
│   │   │       ├── controller/          # 控制器层
│   │   │       │   ├── UserController.java
│   │   │       │   └── dto/             # 数据传输对象
│   │   │       ├── service/             # 服务层
│   │   │       │   ├── UserService.java
│   │   │       │   └── impl/
│   │   │       ├── repository/          # 数据访问层
│   │   │       │   └── UserRepository.java
│   │   │       ├── domain/              # 领域模型
│   │   │       │   ├── entity/          # 实体
│   │   │       │   ├── vo/              # 值对象
│   │   │       │   └── aggregate/       # 聚合根
│   │   │       ├── config/              # 配置类
│   │   │       ├── security/            # 安全配置
│   │   │       ├── exception/           # 异常处理
│   │   │       ├── util/                # 工具类
│   │   │       ├── event/               # 事件
│   │   │       │   ├── publisher/       # 事件发布
│   │   │       │   └── listener/        # 事件监听
│   │   │       └── client/              # 外部服务客户端
│   │   │           └── feign/           # Feign 客户端
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       ├── bootstrap.yml
│   │       ├── db/migration/            # Flyway 脚本
│   │       └── static/
│   └── test/
│       ├── java/
│       │   └── com/enterprise/service/
│       │       ├── controller/          # 控制器测试
│       │       ├── service/             # 服务测试
│       │       └── integration/         # 集成测试
│       └── resources/
│           └── application-test.yml
├── pom.xml
├── Dockerfile
└── README.md
```

## 微服务拆分

### 服务划分原则

1. **按业务领域拆分** (DDD)
   - 用户域: 用户管理、认证授权
   - 商品域: 商品、库存、分类
   - 订单域: 订单、购物车
   - 支付域: 支付、退款
   - 营销域: 优惠券、活动

2. **单一职责原则**
   - 每个服务只负责一个业务领域
   - 服务内部高内聚
   - 服务之间低耦合

3. **数据独立原则**
   - 每个服务独立数据库
   - 避免直接访问其他服务数据库
   - 通过 API 或事件通信

### 核心服务

#### 1. Gateway Service (网关服务)
**职责**:
- 统一入口
- 路由转发
- 限流熔断
- 认证鉴权
- 日志记录

**技术栈**:
```yaml
dependencies:
  - spring-cloud-gateway
  - spring-security
  - redis (限流)
  - resilience4j
```

#### 2. Auth Service (认证服务)
**职责**:
- 用户认证
- JWT 生成/验证
- OAuth2 授权
- SSO 单点登录
- 权限管理

**核心接口**:
```java
POST /auth/login        # 登录
POST /auth/logout       # 登出
POST /auth/refresh      # 刷新 Token
GET  /auth/validate     # 验证 Token
POST /auth/register     # 注册
```

#### 3. User Service (用户服务)
**职责**:
- 用户信息管理
- 用户画像
- 用户关系
- 积分管理

**核心接口**:
```java
GET    /users/{id}           # 获取用户
PUT    /users/{id}           # 更新用户
GET    /users/{id}/profile   # 用户画像
POST   /users/{id}/follow    # 关注用户
```

#### 4. Product Service (商品服务)
**职责**:
- 商品管理
- 分类管理
- 品牌管理
- SPU/SKU 管理

**核心接口**:
```java
GET    /products              # 商品列表
GET    /products/{id}         # 商品详情
POST   /products              # 创建商品
PUT    /products/{id}         # 更新商品
GET    /products/search       # 搜索商品
```

#### 5. Order Service (订单服务)
**职责**:
- 订单创建
- 订单状态管理
- 购物车
- 订单查询

**核心接口**:
```java
POST   /orders                # 创建订单
GET    /orders/{id}           # 订单详情
PUT    /orders/{id}/cancel    # 取消订单
GET    /orders/user/{userId}  # 用户订单列表
POST   /orders/{id}/pay       # 支付订单
```

#### 6. Payment Service (支付服务)
**职责**:
- 支付处理
- 退款处理
- 支付回调
- 支付查询

**核心接口**:
```java
POST   /payments              # 创建支付
GET    /payments/{id}         # 支付详情
POST   /payments/{id}/refund  # 退款
POST   /payments/callback     # 支付回调
```

### 服务间通信

#### 1. 同步通信 - OpenFeign

```java
@FeignClient(name = "user-service", fallback = UserServiceFallback.class)
public interface UserServiceClient {

    @GetMapping("/users/{id}")
    UserDTO getUser(@PathVariable("id") Long id);

    @GetMapping("/users/batch")
    List<UserDTO> getBatchUsers(@RequestParam("ids") List<Long> ids);
}

// 降级处理
@Component
public class UserServiceFallback implements UserServiceClient {

    @Override
    public UserDTO getUser(Long id) {
        return UserDTO.builder()
            .id(id)
            .nickname("用户" + id)
            .build();
    }

    @Override
    public List<UserDTO> getBatchUsers(List<Long> ids) {
        return Collections.emptyList();
    }
}
```

#### 2. 异步通信 - Kafka

```java
// 发送事件
@Service
public class OrderEventPublisher {

    private final StreamBridge streamBridge;

    public void publishOrderCreated(Order order) {
        OrderCreatedEvent event = OrderCreatedEvent.builder()
            .orderId(order.getId())
            .userId(order.getUserId())
            .amount(order.getAmount())
            .timestamp(Instant.now())
            .build();

        streamBridge.send("order-created", event);
    }
}

// 监听事件
@Service
public class OrderEventListener {

    @Bean
    public Consumer<OrderCreatedEvent> handleOrderCreated() {
        return event -> {
            log.info("Received order created event: {}", event);
            // 处理业务逻辑
            notificationService.sendOrderNotification(event);
            inventoryService.reduceInventory(event);
        };
    }
}
```

## 数据架构

### 数据库设计原则

1. **每个服务独立数据库**
2. **读写分离**
3. **分库分表**
4. **数据一致性**

### 数据一致性方案

#### 1. Saga 模式

```java
@Service
public class OrderSagaOrchestrator {

    public void createOrder(OrderRequest request) {
        // 1. 创建订单
        Order order = orderService.createOrder(request);

        try {
            // 2. 扣减库存
            inventoryService.reduceInventory(order);

            // 3. 创建支付
            Payment payment = paymentService.createPayment(order);

            // 4. 发送通知
            notificationService.sendNotification(order);

            // 提交
            order.setStatus(OrderStatus.SUCCESS);
            orderService.updateOrder(order);

        } catch (Exception e) {
            // 补偿操作
            compensate(order);
            throw new SagaException("Order creation failed", e);
        }
    }

    private void compensate(Order order) {
        // 回滚库存
        inventoryService.restoreInventory(order);
        // 取消订单
        orderService.cancelOrder(order.getId());
    }
}
```

#### 2. 分布式事务 - Seata

```yaml
seata:
  enabled: true
  application-id: ${spring.application.name}
  tx-service-group: ${spring.application.name}-group
  service:
    vgroup-mapping:
      ${spring.application.name}-group: default
  registry:
    type: nacos
    nacos:
      server-addr: ${nacos.server-addr}
```

```java
@Service
public class OrderService {

    @GlobalTransactional(rollbackFor = Exception.class)
    public Order createOrder(OrderRequest request) {
        // 创建订单
        Order order = orderRepository.save(new Order(request));

        // 调用库存服务扣减库存
        inventoryClient.reduceInventory(request.getProductId(), request.getQuantity());

        // 调用积分服务
        pointsClient.addPoints(request.getUserId(), order.getAmount());

        return order;
    }
}
```

### 缓存架构

```
┌─────────────────────────────────────────┐
│          应用层                          │
└────────────┬────────────────────────────┘
             │
        ┌────▼────┐
        │ L1 Cache│  (Caffeine - 本地缓存)
        └────┬────┘
             │ Miss
        ┌────▼────┐
        │ L2 Cache│  (Redis - 分布式缓存)
        └────┬────┘
             │ Miss
        ┌────▼────┐
        │Database │  (PostgreSQL)
        └─────────┘
```

```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory factory) {
        // L1: Caffeine
        CaffeineCache l1Cache = new CaffeineCache("l1",
            Caffeine.newBuilder()
                .maximumSize(1000)
                .expireAfterWrite(5, TimeUnit.MINUTES)
                .build());

        // L2: Redis
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(30))
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair
                    .fromSerializer(new GenericJackson2JsonRedisSerializer())
            );

        RedisCacheManager l2CacheManager = RedisCacheManager.builder(factory)
            .cacheDefaults(config)
            .build();

        return new CompositeCacheManager(
            new CaffeineCacheManager(),
            l2CacheManager
        );
    }
}
```

## 安全架构

### 认证授权流程

```
1. 用户登录
   Client → Gateway → Auth Service
                        ↓
                     验证用户名密码
                        ↓
                   生成 JWT Token
                        ↓
   Client ← Gateway ← Auth Service

2. 访问受保护资源
   Client (携带 Token) → Gateway
                           ↓
                     验证 Token
                           ↓
                     提取用户信息
                           ↓
                     转发到业务服务
                           ↓
   Client ← Gateway ← Business Service
```

### JWT 配置

```java
@Configuration
public class JwtConfig {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("username", userDetails.getUsername());
        claims.put("authorities", userDetails.getAuthorities());

        return Jwts.builder()
            .setClaims(claims)
            .setSubject(userDetails.getUsername())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + expiration * 1000))
            .signWith(SignatureAlgorithm.HS512, secret)
            .compact();
    }

    public Claims parseToken(String token) {
        return Jwts.parser()
            .setSigningKey(secret)
            .parseClaimsJws(token)
            .getBody();
    }
}
```

### API 权限控制

```java
@Configuration
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authorize -> authorize
                .requestMatchers("/actuator/**").permitAll()
                .requestMatchers("/auth/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll()
            )
            .csrf().disable()
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS);

        return http.build();
    }
}

// 方法级别权限
@Service
public class UserService {

    @PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
    public UserDTO getUser(Long userId) {
        // ...
    }

    @PreAuthorize("hasAuthority('USER_DELETE')")
    public void deleteUser(Long userId) {
        // ...
    }
}
```

## 高可用架构

### 1. 服务高可用

- **多实例部署**: 每个服务至少 3 个实例
- **健康检查**: Kubernetes livenessProbe + readinessProbe
- **自动重启**: 异常自动重启
- **滚动更新**: 零停机部署

### 2. 数据库高可用

```
┌─────────────────────────────────────────┐
│         应用层                           │
└────────────┬───────────────┬────────────┘
             │               │
      ┌──────▼──────┐  ┌────▼─────────┐
      │   Master    │  │   Standby    │
      │ (Primary)   │──│  (Replica)   │
      └─────────────┘  └──────────────┘
             │               │
      ┌──────▼───────────────▼──────┐
      │    PgPool / HAProxy         │
      │     (连接池 + 负载均衡)        │
      └─────────────────────────────┘
```

### 3. 缓存高可用

```yaml
# Redis Sentinel 配置
spring:
  redis:
    sentinel:
      master: mymaster
      nodes:
        - sentinel1:26379
        - sentinel2:26379
        - sentinel3:26379
```

### 4. 熔断降级

```java
@Configuration
public class Resilience4jConfig {

    @Bean
    public Customizer<Resilience4JCircuitBreakerFactory> defaultCustomizer() {
        return factory -> factory.configureDefault(id -> new Resilience4JConfigBuilder(id)
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .slidingWindowSize(10)
                .failureRateThreshold(50)
                .waitDurationInOpenState(Duration.ofSeconds(10))
                .build())
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(3))
                .build())
            .build());
    }
}

@Service
public class OrderService {

    @CircuitBreaker(name = "orderService", fallbackMethod = "fallbackGetOrder")
    @Retry(name = "orderService")
    @RateLimiter(name = "orderService")
    public Order getOrder(Long orderId) {
        return orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException(orderId));
    }

    private Order fallbackGetOrder(Long orderId, Exception e) {
        log.error("Fallback triggered for order: {}", orderId, e);
        return Order.builder()
            .id(orderId)
            .status(OrderStatus.UNKNOWN)
            .build();
    }
}
```

## 性能优化

### 1. 数据库优化
- 索引优化
- 查询优化
- 批量操作
- 分页查询

### 2. 缓存策略
- 多级缓存
- 缓存预热
- 缓存更新策略
- 防止缓存穿透/击穿/雪崩

### 3. 异步处理
- 消息队列
- 异步方法
- 事件驱动

### 4. 连接池优化
```yaml
spring:
  datasource:
    hikari:
      minimum-idle: 10
      maximum-pool-size: 50
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### 5. JVM 调优
- 合理的堆内存设置
- 选择合适的 GC
- GC 参数调优

## 总结

本架构设计遵循以下原则:

1. **微服务设计原则**: 高内聚、低耦合
2. **领域驱动设计**: 按业务领域划分服务
3. **云原生架构**: 容器化、可观测性、弹性伸缩
4. **安全优先**: 认证授权、数据加密、网络隔离
5. **高可用**: 多活部署、故障自愈、容灾备份
6. **可扩展**: 水平扩展、服务解耦、插件化
