# 监控告警配置指南

## 可观测性三大支柱

### 1. Metrics (指标)
使用 **Prometheus** + **Grafana** 收集和展示系统指标

### 2. Logs (日志)
使用 **Loki** 进行日志聚合和查询

### 3. Traces (追踪)
使用 **Tempo** 或 **Jaeger** 进行分布式追踪

## Prometheus 配置

### Spring Boot Actuator 集成

在每个微服务的 `pom.xml` 中添加：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### application.yml 配置

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus,metrics
      base-path: /actuator
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
    prometheus:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
      environment: ${spring.profiles.active}
    distribution:
      percentiles-histogram:
        http.server.requests: true
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
```

### 自定义指标

```java
@Component
public class CustomMetrics {

    private final Counter orderCounter;
    private final Timer orderProcessingTimer;
    private final Gauge activeOrders;

    public CustomMetrics(MeterRegistry registry) {
        this.orderCounter = Counter.builder("orders.created")
            .description("Total orders created")
            .tag("type", "business")
            .register(registry);

        this.orderProcessingTimer = Timer.builder("orders.processing.time")
            .description("Order processing time")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(registry);

        this.activeOrders = Gauge.builder("orders.active", this::getActiveOrderCount)
            .description("Number of active orders")
            .register(registry);
    }

    public void recordOrderCreated() {
        orderCounter.increment();
    }

    public void recordOrderProcessing(Runnable task) {
        orderProcessingTimer.record(task);
    }

    private long getActiveOrderCount() {
        // 实现逻辑
        return 0L;
    }
}
```

## Grafana 仪表盘

### 核心指标仪表盘

#### 1. 应用健康状态

**Panel: Service Health**
```promql
# UP/DOWN 状态
up{job="spring-boot-services"}

# 实例数量
count(up{job="spring-boot-services"} == 1) by (application)
```

#### 2. 请求指标

**Panel: Request Rate (RPS)**
```promql
# 每秒请求数
sum(rate(http_server_requests_seconds_count[5m])) by (application)

# 按状态码分组
sum(rate(http_server_requests_seconds_count[5m])) by (status)
```

**Panel: Error Rate**
```promql
# 错误率
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
/
sum(rate(http_server_requests_seconds_count[5m])) * 100
```

**Panel: Response Time (Latency)**
```promql
# P50, P95, P99
histogram_quantile(0.50, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, application))
histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, application))
histogram_quantile(0.99, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, application))
```

#### 3. JVM 指标

**Panel: Heap Memory Usage**
```promql
# 堆内存使用率
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

# 堆内存使用量
jvm_memory_used_bytes{area="heap"} / 1024 / 1024
```

**Panel: GC Metrics**
```promql
# GC 次数
rate(jvm_gc_pause_seconds_count[5m])

# GC 时间
rate(jvm_gc_pause_seconds_sum[5m])

# GC 暂停时间百分比
rate(jvm_gc_pause_seconds_sum[5m]) * 100
```

**Panel: Thread Count**
```promql
jvm_threads_live_threads
jvm_threads_daemon_threads
```

#### 4. 数据库连接池

**Panel: Database Connections**
```promql
# 活跃连接数
hikaricp_connections_active

# 空闲连接数
hikaricp_connections_idle

# 等待连接的线程数
hikaricp_connections_pending

# 连接获取时间
hikaricp_connections_acquire_seconds
```

#### 5. 业务指标

**Panel: Business Metrics**
```promql
# 订单创建速率
rate(orders_created_total[5m])

# 订单处理时间
histogram_quantile(0.95, rate(orders_processing_time_seconds_bucket[5m]))
```

### Grafana 导入仪表盘

```bash
# 导入预制的 Spring Boot 仪表盘
# Dashboard ID: 4701, 6756, 10280
```

访问 Grafana -> Dashboards -> Import -> 输入 ID

## 日志聚合 (Loki)

### Logback 配置

```xml
<!-- src/main/resources/logback-spring.xml -->
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>

    <springProperty scope="context" name="applicationName" source="spring.application.name"/>

    <!-- Console Appender with JSON format -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <customFields>{"application":"${applicationName}"}</customFields>
        </encoder>
    </appender>

    <!-- Loki Appender -->
    <appender name="LOKI" class="com.github.loki4j.logback.Loki4jAppender">
        <http>
            <url>http://loki:3100/loki/api/v1/push</url>
        </http>
        <format>
            <label>
                <pattern>application=${applicationName},host=${HOSTNAME},level=%level</pattern>
            </label>
            <message>
                <pattern>
                    {
                        "timestamp": "%date{ISO8601}",
                        "level": "%level",
                        "thread": "%thread",
                        "logger": "%logger{36}",
                        "message": "%message",
                        "trace_id": "%X{traceId}",
                        "span_id": "%X{spanId}"
                    }
                </pattern>
            </message>
        </format>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="LOKI"/>
    </root>

    <logger name="com.enterprise" level="DEBUG"/>
</configuration>
```

### LogQL 查询示例

```logql
# 查询特定应用的错误日志
{application="user-service"} |= "ERROR"

# 查询包含特定关键字的日志
{application="user-service"} |~ "(?i)exception|error"

# 聚合查询 - 每分钟错误数
sum(count_over_time({application="user-service"} |= "ERROR" [1m]))

# 查询特定 Trace ID 的日志
{application=~".*"} | json | trace_id="abc123"

# 查询响应时间超过 1s 的请求
{application="gateway-service"} | json | duration > 1000
```

## 分布式追踪 (OpenTelemetry)

### Spring Boot 配置

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

### application.yml 配置

```yaml
management:
  tracing:
    sampling:
      probability: 1.0  # 生产环境建议 0.1
  otlp:
    tracing:
      endpoint: http://tempo:4318/v1/traces

spring:
  sleuth:
    enabled: false  # 使用 Micrometer Tracing
```

### 自定义 Span

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    private final Tracer tracer;

    public Order createOrder(OrderRequest request) {
        Span span = tracer.spanBuilder("create-order")
            .setAttribute("order.id", request.getId())
            .setAttribute("order.amount", request.getAmount())
            .startSpan();

        try (Scope scope = span.makeCurrent()) {
            // 业务逻辑
            Order order = processOrder(request);
            span.addEvent("Order created successfully");
            return order;
        } catch (Exception e) {
            span.recordException(e);
            span.setStatus(StatusCode.ERROR);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

## 告警配置

### Prometheus AlertManager

#### 告警规则

已在 `deployment/monitoring/prometheus-config.yaml` 中配置核心告警规则：

- 高错误率 (>5%)
- 高响应时间 (P95 > 1s)
- 服务宕机
- 高内存使用 (>90%)
- 高 CPU 使用 (>80%)
- 数据库连接池耗尽 (>90%)
- 高 GC 压力 (>10%)

#### AlertManager 配置

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@enterprise.com'
  smtp_auth_username: 'alerts@enterprise.com'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default-receiver'
  routes:
  - match:
      severity: critical
    receiver: 'critical-receiver'
    continue: true
  - match:
      severity: warning
    receiver: 'warning-receiver'

receivers:
- name: 'default-receiver'
  email_configs:
  - to: 'team@enterprise.com'

- name: 'critical-receiver'
  email_configs:
  - to: 'oncall@enterprise.com'
  pagerduty_configs:
  - service_key: '<pagerduty-key>'
  slack_configs:
  - api_url: '<slack-webhook>'
    channel: '#alerts-critical'

- name: 'warning-receiver'
  slack_configs:
  - api_url: '<slack-webhook>'
    channel: '#alerts-warning'

inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'cluster', 'service']
```

### 部署 AlertManager

```bash
kubectl apply -f deployment/monitoring/alertmanager-config.yaml

helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set alertmanager.config.global.smtp_smarthost='smtp.gmail.com:587'
```

## 健康检查

### Kubernetes Probes

已在部署文件中配置：

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8081
  initialDelaySeconds: 60
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8081
  initialDelaySeconds: 30
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /actuator/health
    port: 8081
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 30
```

### 自定义健康检查

```java
@Component
public class CustomHealthIndicator implements HealthIndicator {

    @Autowired
    private DatabaseService databaseService;

    @Autowired
    private RedisService redisService;

    @Override
    public Health health() {
        try {
            // 检查数据库连接
            databaseService.ping();

            // 检查 Redis 连接
            redisService.ping();

            return Health.up()
                .withDetail("database", "available")
                .withDetail("redis", "available")
                .build();
        } catch (Exception e) {
            return Health.down()
                .withException(e)
                .build();
        }
    }
}
```

## SLI/SLO/SLA

### 定义 SLI (Service Level Indicators)

```yaml
# 可用性
availability_sli:
  query: |
    sum(rate(http_server_requests_seconds_count{status!~"5.."}[30d]))
    /
    sum(rate(http_server_requests_seconds_count[30d]))

# 延迟
latency_sli:
  query: |
    histogram_quantile(0.95,
      sum(rate(http_server_requests_seconds_bucket[30d])) by (le)
    )

# 错误率
error_rate_sli:
  query: |
    sum(rate(http_server_requests_seconds_count{status=~"5.."}[30d]))
    /
    sum(rate(http_server_requests_seconds_count[30d]))
```

### SLO 目标

- **可用性**: 99.9% (每月允许 43 分钟停机)
- **延迟**: P95 < 500ms, P99 < 1s
- **错误率**: < 0.1%

### 错误预算

```promql
# 剩余错误预算
(1 - slo_target) - (1 - current_availability)

# 错误预算消耗率
error_budget_consumption_rate = actual_error_rate / slo_error_budget
```

## 监控最佳实践

### 1. 四个黄金信号

- **延迟 (Latency)**: 请求响应时间
- **流量 (Traffic)**: 系统处理的请求量
- **错误 (Errors)**: 失败请求的比率
- **饱和度 (Saturation)**: 资源使用程度

### 2. USE 方法 (资源监控)

- **Utilization**: 资源利用率
- **Saturation**: 资源饱和度
- **Errors**: 错误数

### 3. RED 方法 (服务监控)

- **Rate**: 请求速率
- **Errors**: 错误率
- **Duration**: 响应时间

### 4. 告警设计原则

- **可操作**: 告警必须需要人工介入
- **有意义**: 告警应该影响用户体验
- **避免噪音**: 减少误报
- **适当阈值**: 基于历史数据设置
- **分级管理**: Critical/Warning/Info

## 监控检查清单

- [ ] Prometheus 正常采集指标
- [ ] Grafana 仪表盘显示正常
- [ ] Loki 收集日志
- [ ] Tempo/Jaeger 追踪链路
- [ ] AlertManager 发送告警
- [ ] 健康检查端点正常
- [ ] 自定义业务指标已实现
- [ ] SLO 监控已配置
- [ ] 值班轮换已建立
- [ ] Runbook 文档已准备

## 故障诊断流程

1. **收到告警** → 检查 Grafana 仪表盘
2. **定位问题服务** → 查看 Loki 日志
3. **分析具体请求** → Tempo/Jaeger 追踪
4. **检查资源** → Prometheus 指标
5. **执行恢复操作** → 参考 Runbook
6. **事后分析** → 编写事故报告

## 下一步

- 配置 [Alertmanager 集成](alertmanager-integration.md)
- 设置 [On-call 轮换](oncall-setup.md)
- 编写 [Runbook 文档](runbooks.md)
