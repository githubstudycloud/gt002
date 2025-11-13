# 技术栈详解

## 1. 后端技术栈

### 1.1 核心框架

#### Spring Boot 3.2.x
**用途:** 应用开发框架
**特性:**
- 快速开发: 自动配置,开箱即用
- 约定优于配置: 减少配置工作量
- 独立运行: 内嵌Tomcat,无需外部容器
- 生产就绪: Actuator健康检查和监控

**最佳实践:**
```java
@SpringBootApplication
@EnableAsync
@EnableScheduling
@EnableCaching
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

#### Spring Cloud 2023.0.x
**组件清单:**

1. **Spring Cloud Gateway - API网关**
   - 动态路由
   - 请求过滤
   - 限流降级
   - 负载均衡

2. **Spring Cloud OpenFeign - 声明式HTTP客户端**
   - 接口化调用
   - 负载均衡
   - 熔断降级
   - 请求重试

3. **Spring Cloud LoadBalancer - 负载均衡**
   - 客户端负载均衡
   - 多种策略支持
   - 健康检查

#### Spring Cloud Alibaba 2023.0.1.0
**组件清单:**

1. **Nacos - 服务注册与配置中心**
   ```yaml
   spring:
     cloud:
       nacos:
         discovery:
           server-addr: localhost:8848
         config:
           server-addr: localhost:8848
           file-extension: yaml
   ```

2. **Sentinel - 流量控制**
   ```java
   @SentinelResource(value = "getUserById",
                     blockHandler = "handleBlock",
                     fallback = "handleFallback")
   public User getUserById(Long id) {
       return userService.getById(id);
   }
   ```

3. **Seata - 分布式事务**
   ```java
   @GlobalTransactional
   public void createOrder(Order order) {
       // 创建订单
       orderService.create(order);
       // 扣减库存
       productService.decreaseStock(order.getProductId());
       // 扣减余额
       accountService.decrease(order.getUserId());
   }
   ```

### 1.2 数据访问层

#### MyBatis-Plus 3.5.6
**特性:**
- 单表CRUD无需编写SQL
- 条件构造器
- 分页插件
- 代码生成器

**示例代码:**
```java
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User>
    implements UserService {

    @Override
    public List<User> getActiveUsers() {
        return lambdaQuery()
            .eq(User::getStatus, 1)
            .orderByDesc(User::getCreateTime)
            .list();
    }
}
```

#### Druid 1.2.23
**特性:**
- 监控统计
- SQL防火墙
- 连接池管理
- 慢SQL记录

**配置示例:**
```yaml
spring:
  datasource:
    druid:
      initial-size: 10
      max-active: 50
      min-idle: 10
      max-wait: 60000
      stat-view-servlet:
        enabled: true
        url-pattern: /druid/*
      filter:
        stat:
          enabled: true
          slow-sql-millis: 2000
```

#### Flyway 10.13.0
**用途:** 数据库版本管理

**目录结构:**
```
src/main/resources/db/migration/
├── V1__init_schema.sql
├── V2__add_user_table.sql
└── V3__add_order_table.sql
```

#### ShardingSphere 5.4.1
**用途:** 分库分表中间件

**配置示例:**
```yaml
spring:
  shardingsphere:
    rules:
      sharding:
        tables:
          t_order:
            actual-data-nodes: ds$->{0..1}.t_order_$->{0..3}
            table-strategy:
              standard:
                sharding-column: user_id
                sharding-algorithm-name: order-inline
```

### 1.3 缓存技术

#### Redis 7.x + Redisson 3.30.0
**使用场景:**
- 分布式缓存
- 分布式锁
- 限流控制
- 消息队列
- 会话存储

**代码示例:**
```java
@Service
public class CacheService {

    @Autowired
    private RedissonClient redissonClient;

    // 分布式锁
    public void updateWithLock(String key) {
        RLock lock = redissonClient.getLock("lock:" + key);
        try {
            lock.lock(30, TimeUnit.SECONDS);
            // 业务逻辑
        } finally {
            lock.unlock();
        }
    }

    // 限流
    public boolean tryAcquire(String key) {
        RRateLimiter limiter = redissonClient.getRateLimiter(key);
        limiter.trySetRate(RateType.OVERALL, 100, 1, RateIntervalUnit.SECONDS);
        return limiter.tryAcquire();
    }
}
```

#### Caffeine
**用途:** 本地缓存

**配置:**
```java
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .initialCapacity(100)
            .maximumSize(1000)
            .expireAfterWrite(10, TimeUnit.MINUTES));
        return cacheManager;
    }
}
```

### 1.4 消息队列

#### RabbitMQ
**使用场景:**
- 异步处理
- 应用解耦
- 流量削峰
- 消息通知

**配置示例:**
```java
@Configuration
public class RabbitConfig {

    @Bean
    public Queue orderQueue() {
        return new Queue("order.queue", true);
    }

    @Bean
    public DirectExchange orderExchange() {
        return new DirectExchange("order.exchange");
    }

    @Bean
    public Binding orderBinding() {
        return BindingBuilder
            .bind(orderQueue())
            .to(orderExchange())
            .with("order.create");
    }
}

// 生产者
@Service
public class OrderProducer {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    public void sendOrder(Order order) {
        rabbitTemplate.convertAndSend(
            "order.exchange",
            "order.create",
            order
        );
    }
}

// 消费者
@Component
public class OrderConsumer {

    @RabbitListener(queues = "order.queue")
    public void handleOrder(Order order) {
        // 处理订单
    }
}
```

#### Apache Kafka (可选)
**使用场景:**
- 大数据流处理
- 日志收集
- 实时数据管道

### 1.5 安全认证

#### Spring Security + JWT
**实现流程:**
1. 用户登录 → 生成JWT Token
2. 请求携带Token → Gateway验证
3. Token解析 → 获取用户信息
4. 权限校验 → 放行/拒绝

**代码示例:**
```java
@Service
public class JwtTokenService {

    private static final String SECRET = "your-secret-key";

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("username", userDetails.getUsername());
        claims.put("authorities", userDetails.getAuthorities());

        return Jwts.builder()
            .setClaims(claims)
            .setSubject(userDetails.getUsername())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + 86400000))
            .signWith(SignatureAlgorithm.HS512, SECRET)
            .compact();
    }

    public Claims parseToken(String token) {
        return Jwts.parser()
            .setSigningKey(SECRET)
            .parseClaimsJws(token)
            .getBody();
    }
}
```

### 1.6 搜索引擎

#### Elasticsearch 8.x
**使用场景:**
- 全文搜索
- 日志分析
- 数据聚合
- 实时分析

**集成示例:**
```java
@Service
public class ProductSearchService {

    @Autowired
    private ElasticsearchRestTemplate elasticsearchTemplate;

    public List<Product> search(String keyword) {
        NativeSearchQuery query = new NativeSearchQueryBuilder()
            .withQuery(QueryBuilders.multiMatchQuery(keyword, "name", "description"))
            .withPageable(PageRequest.of(0, 10))
            .build();

        SearchHits<Product> searchHits = elasticsearchTemplate.search(query, Product.class);
        return searchHits.stream()
            .map(SearchHit::getContent)
            .collect(Collectors.toList());
    }
}
```

### 1.7 任务调度

#### XXL-Job 2.4.1
**特性:**
- 分布式调度
- 动态配置
- 执行日志
- 失败重试

**使用示例:**
```java
@Component
public class SampleXxlJob {

    @XxlJob("demoJobHandler")
    public void demoJobHandler() throws Exception {
        XxlJobHelper.log("XXL-JOB, Hello World.");
        // 执行任务逻辑
    }
}
```

### 1.8 工具类库

#### Hutool 5.8.27
**常用工具:**
- 字符串工具: StrUtil
- 集合工具: CollUtil
- 日期工具: DateUtil
- 加密工具: SecureUtil
- HTTP工具: HttpUtil

#### Lombok 1.18.32
**常用注解:**
- @Data: 生成getter/setter/toString/equals/hashCode
- @Builder: 建造者模式
- @Slf4j: 日志
- @NoArgsConstructor/@AllArgsConstructor: 构造函数

#### MapStruct 1.5.5
**对象映射:**
```java
@Mapper(componentModel = "spring")
public interface UserConverter {

    UserDTO toDTO(User user);

    User toEntity(UserDTO dto);

    List<UserDTO> toDTOList(List<User> users);
}
```

## 2. 容器化与编排

### 2.1 Docker
**最佳实践:**
- 多阶段构建减小镜像体积
- 使用非root用户运行
- 健康检查配置
- 资源限制

### 2.2 Kubernetes
**核心概念:**
- Pod: 最小部署单元
- Deployment: 无状态应用
- StatefulSet: 有状态应用
- Service: 服务发现与负载均衡
- Ingress: 外部访问入口
- ConfigMap: 配置管理
- Secret: 敏感信息管理
- PVC: 持久化存储

**生产级配置:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - springboot-app
              topologyKey: kubernetes.io/hostname
```

## 3. 监控与日志

### 3.1 Prometheus + Grafana
**监控指标:**
- JVM指标: 内存、GC、线程
- 应用指标: HTTP请求、数据库连接池
- 业务指标: 订单量、用户活跃度
- 基础设施: CPU、内存、磁盘、网络

**Grafana Dashboard ID:**
- 4701: JVM Micrometer
- 11074: Spring Boot Statistics
- 13770: Spring Boot APM Dashboard

### 3.2 Skywalking
**功能:**
- 分布式链路追踪
- 服务拓扑图
- 性能分析
- 告警通知

**集成方式:**
```bash
java -javaagent:/path/to/skywalking-agent.jar \
     -Dskywalking.agent.service_name=user-service \
     -Dskywalking.collector.backend_service=localhost:11800 \
     -jar app.jar
```

### 3.3 ELK Stack
**组件:**
- Elasticsearch: 存储日志
- Logstash: 收集和转换日志
- Kibana: 可视化分析

**Logback配置:**
```xml
<appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>logstash:5000</destination>
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>{"app":"springboot1","env":"prod"}</customFields>
    </encoder>
</appender>
```

## 4. CI/CD工具链

### 4.1 代码管理
- Git: 版本控制
- GitFlow: 分支管理策略

### 4.2 构建工具
- Maven: Java项目构建
- Docker Buildx: 多架构镜像构建

### 4.3 CI/CD平台
- Jenkins: 持续集成
- GitLab CI: 代码托管+CI/CD
- GitHub Actions: 自动化工作流
- ArgoCD: GitOps部署

### 4.4 制品管理
- Harbor: Docker镜像仓库
- Nexus: Maven私服

### 4.5 代码质量
- SonarQube: 代码质量分析
- Checkstyle: 代码规范检查
- SpotBugs: Bug检测

## 5. 测试框架

### 5.1 单元测试
**JUnit 5 + Mockito**
```java
@SpringBootTest
class UserServiceTest {

    @MockBean
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Test
    void testGetUser() {
        User user = new User();
        user.setId(1L);
        user.setUsername("test");

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        User result = userService.getById(1L);
        assertEquals("test", result.getUsername());
    }
}
```

### 5.2 集成测试
**TestContainers**
```java
@Testcontainers
@SpringBootTest
class IntegrationTest {

    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7")
        .withExposedPorts(6379);

    @Test
    void testDatabase() {
        // 测试逻辑
    }
}
```

### 5.3 性能测试
- JMeter: HTTP性能测试
- Gatling: 代码化性能测试

## 6. 文档工具

### 6.1 API文档
**Knife4j (Swagger3)**
```java
@Configuration
@EnableOpenApi
public class Knife4jConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("SpringBoot1 API")
                .version("1.0")
                .description("企业级微服务API文档"));
    }
}
```

访问地址: http://localhost:8080/doc.html

## 7. 技术选型原则

1. **成熟稳定**: 选择经过生产验证的技术
2. **社区活跃**: 有良好的社区支持
3. **性能优秀**: 满足性能要求
4. **易于维护**: 降低维护成本
5. **团队熟悉**: 团队有相关经验
6. **可扩展性**: 支持业务扩展
7. **成本可控**: 总体成本在预算内

## 8. 技术演进路线

**短期 (3-6个月):**
- 优化现有架构
- 提升性能指标
- 完善监控告警

**中期 (6-12个月):**
- 引入服务网格 (Istio)
- 升级到最新LTS版本
- 容量规划与扩展

**长期 (1-2年):**
- 云原生架构改造
- Serverless探索
- AI/ML能力集成
