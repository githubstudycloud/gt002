# 监控与可观测性指南

## 目录
- [监控架构](#监控架构)
- [指标监控 (Metrics)](#指标监控-metrics)
- [日志管理 (Logging)](#日志管理-logging)
- [链路追踪 (Tracing)](#链路追踪-tracing)
- [告警配置 (Alerting)](#告警配置-alerting)
- [性能调优](#性能调优)

## 监控架构

### 三大支柱

我们的可观测性系统基于三大支柱构建：

```
┌─────────────────────────────────────────────────────────┐
│                    应用程序层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ Gateway  │  │   Auth   │  │   User   │  │  Order   │ │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘ │
└────────┼─────────────┼─────────────┼─────────────┼──────┘
         │             │             │             │
    ┌────┼─────────────┼─────────────┼─────────────┼────┐
    │    │             │             │             │    │
    │ ┌──▼──┐       ┌──▼──┐       ┌──▼──┐              │
    │ │Metric│      │ Log │       │Trace│              │
    │ └──┬──┘       └──┬──┘       └──┬──┘              │
    │    │             │             │                  │
    │ ┌──▼─────┐   ┌──▼────┐    ┌───▼────┐             │
    │ │Promethe│   │  ELK  │    │ Jaeger │             │
    │ │  us    │   │ Stack │    │        │             │
    │ └──┬─────┘   └───────┘    └────────┘             │
    │    │                                              │
    │ ┌──▼──────┐                                       │
    │ │ Grafana │  ◄─── 统一可视化平台                   │
    │ └─────────┘                                       │
    └──────────────────────────────────────────────────┘
```

## 指标监控 (Metrics)

### Spring Boot Actuator 配置

在 `application.yml` 中配置：

```yaml
management:
  endpoints:
    web:
      exposure:
        include: '*'
      base-path: /actuator
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
    metrics:
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
      slo:
        http.server.requests: 50ms,100ms,200ms,500ms,1s,2s
  # 健康检查配置
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
```

### Micrometer 自定义指标

```java
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Component;

@Component
public class MetricsService {

    private final Counter orderCounter;
    private final Timer orderProcessTimer;
    private final MeterRegistry registry;

    public MetricsService(MeterRegistry registry) {
        this.registry = registry;

        // 计数器
        this.orderCounter = Counter.builder("orders.created")
            .description("订单创建总数")
            .tag("type", "business")
            .register(registry);

        // 计时器
        this.orderProcessTimer = Timer.builder("orders.process.time")
            .description("订单处理时间")
            .tag("type", "performance")
            .register(registry);
    }

    public void recordOrderCreated() {
        orderCounter.increment();
    }

    public void recordOrderProcessTime(Runnable task) {
        orderProcessTimer.record(task);
    }

    // Gauge 示例 - 动态值
    public void registerQueueSizeGauge(Queue<?> queue) {
        registry.gauge("queue.size",
            Tags.of("queue", "order-queue"),
            queue,
            Queue::size);
    }
}
```

### 关键指标定义

#### 1. 系统指标
- **JVM 内存**: `jvm.memory.used`, `jvm.memory.max`
- **GC**: `jvm.gc.pause`, `jvm.gc.memory.allocated`
- **线程**: `jvm.threads.live`, `jvm.threads.peak`
- **CPU**: `system.cpu.usage`, `process.cpu.usage`

#### 2. 应用指标
- **HTTP 请求**: `http.server.requests` (count, duration)
- **数据库连接池**: `hikaricp.connections.active`, `hikaricp.connections.idle`
- **缓存**: `cache.gets`, `cache.puts`, `cache.evictions`
- **消息队列**: `kafka.consumer.records.consumed.total`

#### 3. 业务指标
- **订单量**: `orders.created`, `orders.completed`
- **用户活跃**: `users.active`, `users.registered`
- **交易额**: `transactions.amount`
- **错误率**: `errors.count`, `errors.rate`

### Prometheus 查询示例

```promql
# QPS (每秒请求数)
rate(http_server_requests_seconds_count{job="gateway"}[1m])

# 平均响应时间
rate(http_server_requests_seconds_sum{job="gateway"}[5m])
/
rate(http_server_requests_seconds_count{job="gateway"}[5m])

# P95 响应时间
histogram_quantile(0.95,
  rate(http_server_requests_seconds_bucket{job="gateway"}[5m])
)

# 错误率
rate(http_server_requests_seconds_count{status=~"5.."}[5m])
/
rate(http_server_requests_seconds_count[5m])

# CPU 使用率
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 内存使用率
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# JVM 堆内存使用率
(jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) * 100

# 数据库连接池使用率
(hikaricp_connections_active / hikaricp_connections_max) * 100
```

### Grafana 仪表板

#### 推荐仪表板

1. **Spring Boot 仪表板** (ID: 12900)
   - JVM 指标
   - HTTP 请求统计
   - 数据库连接池
   - 缓存统计

2. **JVM Micrometer** (ID: 4701)
   - 堆内存详情
   - GC 统计
   - 线程状态
   - 类加载

3. **Kubernetes 集群监控** (ID: 7249)
   - 节点资源
   - Pod 状态
   - 网络流量
   - 存储使用

#### 自定义面板

```json
{
  "dashboard": {
    "title": "业务监控面板",
    "panels": [
      {
        "title": "订单创建趋势",
        "targets": [
          {
            "expr": "rate(orders_created_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "实时 QPS",
        "targets": [
          {
            "expr": "sum(rate(http_server_requests_seconds_count[1m]))"
          }
        ],
        "type": "singlestat"
      },
      {
        "title": "错误率",
        "targets": [
          {
            "expr": "rate(http_server_requests_seconds_count{status=~\"5..\"}[5m])"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

## 日志管理 (Logging)

### Logback 配置

```xml
<!-- logback-spring.xml -->
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>

    <!-- 控制台输出 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <customFields>{"app":"${spring.application.name}"}</customFields>
            <fieldNames>
                <timestamp>@timestamp</timestamp>
                <message>message</message>
                <logger>logger_name</logger>
                <level>log_level</level>
                <thread>thread_name</thread>
            </fieldNames>
        </encoder>
    </appender>

    <!-- 文件输出 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>/var/log/app/${spring.application.name}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>/var/log/app/${spring.application.name}-%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
            <maxHistory>30</maxHistory>
            <timeBasedFileNamingAndTriggeringPolicy
                class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>100MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <encoder class="net.logstash.logback.encoder.LogstashEncoder"/>
    </appender>

    <!-- 异步日志 -->
    <appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
        <queueSize>512</queueSize>
        <appender-ref ref="FILE"/>
    </appender>

    <!-- 根日志级别 -->
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="ASYNC"/>
    </root>

    <!-- 包级别日志 -->
    <logger name="com.enterprise" level="DEBUG"/>
    <logger name="org.springframework" level="INFO"/>
    <logger name="com.zaxxer.hikari" level="INFO"/>
</configuration>
```

### 结构化日志

```java
import net.logstash.logback.argument.StructuredArguments;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class OrderService {

    private static final Logger logger = LoggerFactory.getLogger(OrderService.class);

    public Order createOrder(OrderRequest request) {
        // 结构化日志
        logger.info("Creating order",
            StructuredArguments.keyValue("userId", request.getUserId()),
            StructuredArguments.keyValue("amount", request.getAmount()),
            StructuredArguments.keyValue("productCount", request.getProducts().size())
        );

        try {
            Order order = processOrder(request);

            logger.info("Order created successfully",
                StructuredArguments.keyValue("orderId", order.getId()),
                StructuredArguments.keyValue("status", order.getStatus()),
                StructuredArguments.keyValue("duration", getDuration())
            );

            return order;
        } catch (Exception e) {
            logger.error("Failed to create order",
                StructuredArguments.keyValue("userId", request.getUserId()),
                StructuredArguments.keyValue("error", e.getMessage()),
                e
            );
            throw e;
        }
    }
}
```

### ELK Stack 配置

#### Filebeat 配置

```yaml
# filebeat.yml
filebeat.inputs:
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    processors:
      - add_kubernetes_metadata:
          host: ${NODE_NAME}
          matchers:
          - logs_path:
              logs_path: "/var/lib/docker/containers/"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "springboot3-logs-%{+yyyy.MM.dd}"

setup.template.name: "springboot3-logs"
setup.template.pattern: "springboot3-logs-*"
setup.ilm.enabled: false
```

#### Kibana 查询示例

```
# 错误日志
log_level:ERROR AND app:gateway

# 慢查询
message:"Slow query" AND duration:>1000

# 特定用户操作
userId:"12345" AND (message:"login" OR message:"logout")

# 时间范围内的 5xx 错误
log_level:ERROR AND status:[500 TO 599] AND @timestamp:[now-1h TO now]
```

## 链路追踪 (Tracing)

### Micrometer Tracing 配置

```yaml
# application.yml
management:
  tracing:
    sampling:
      probability: 1.0  # 采样率 100%（生产环境建议 0.1）
  zipkin:
    tracing:
      endpoint: http://jaeger:9411/api/v2/spans
  otlp:
    tracing:
      endpoint: http://jaeger:4318/v1/traces
```

### 自定义 Span

```java
import io.micrometer.tracing.Span;
import io.micrometer.tracing.Tracer;
import org.springframework.stereotype.Service;

@Service
public class PaymentService {

    private final Tracer tracer;

    public PaymentService(Tracer tracer) {
        this.tracer = tracer;
    }

    public PaymentResult processPayment(PaymentRequest request) {
        // 创建自定义 Span
        Span span = tracer.nextSpan().name("payment.process").start();

        try (Tracer.SpanInScope ws = tracer.withSpan(span)) {
            // 添加标签
            span.tag("payment.method", request.getMethod());
            span.tag("payment.amount", String.valueOf(request.getAmount()));

            // 业务逻辑
            PaymentResult result = doPayment(request);

            // 添加事件
            span.event("payment.completed");
            span.tag("payment.id", result.getPaymentId());

            return result;
        } catch (Exception e) {
            span.error(e);
            throw e;
        } finally {
            span.end();
        }
    }

    // 使用注解自动创建 Span
    @NewSpan("database.query")
    public List<Order> queryOrders(@SpanTag("userId") String userId) {
        return orderRepository.findByUserId(userId);
    }
}
```

### 跨服务追踪

```java
@Configuration
public class TracingConfig {

    @Bean
    public RestTemplateCustomizer restTemplateCustomizer(Tracer tracer) {
        return restTemplate -> {
            // 自动传播追踪上下文
            restTemplate.getInterceptors().add((request, body, execution) -> {
                Span currentSpan = tracer.currentSpan();
                if (currentSpan != null) {
                    // 注入追踪头
                    request.getHeaders().add("X-B3-TraceId", currentSpan.context().traceId());
                    request.getHeaders().add("X-B3-SpanId", currentSpan.context().spanId());
                }
                return execution.execute(request, body);
            });
        };
    }
}
```

### Jaeger UI 使用

访问 Jaeger UI: http://localhost:16686

1. **搜索 Trace**
   - 按服务名称搜索
   - 按操作名称搜索
   - 按标签搜索
   - 按持续时间过滤

2. **分析 Trace**
   - 查看完整调用链
   - 识别瓶颈
   - 分析错误
   - 比较 Trace

3. **依赖关系图**
   - 服务拓扑
   - 调用关系
   - 依赖深度

## 告警配置 (Alerting)

### Prometheus 告警规则

```yaml
# prometheus-rules.yml
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # 服务不可用告警
      - alert: ServiceDown
        expr: up{job=~"gateway|auth-service|user-service"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "服务 {{ $labels.job }} 不可用"
          description: "{{ $labels.instance }} 已经下线超过 1 分钟"

      # 高错误率告警
      - alert: HighErrorRate
        expr: |
          rate(http_server_requests_seconds_count{status=~"5.."}[5m])
          /
          rate(http_server_requests_seconds_count[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.job }} 错误率过高"
          description: "错误率: {{ $value | humanizePercentage }}"

      # 响应时间过长告警
      - alert: HighResponseTime
        expr: |
          histogram_quantile(0.95,
            rate(http_server_requests_seconds_bucket[5m])
          ) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.job }} P95 响应时间过长"
          description: "P95 响应时间: {{ $value | humanizeDuration }}"

      # CPU 使用率告警
      - alert: HighCPUUsage
        expr: |
          100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.instance }} CPU 使用率过高"
          description: "CPU 使用率: {{ $value | humanize }}%"

      # 内存使用率告警
      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.instance }} 内存使用率过高"
          description: "内存使用率: {{ $value | humanize }}%"

      # JVM 堆内存告警
      - alert: HighJVMHeapUsage
        expr: |
          (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.job }} JVM 堆内存使用率过高"
          description: "堆内存使用率: {{ $value | humanize }}%"

      # 数据库连接池告警
      - alert: HighDBConnectionPoolUsage
        expr: |
          (hikaricp_connections_active / hikaricp_connections_max) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.job }} 数据库连接池使用率过高"
          description: "连接池使用率: {{ $value | humanize }}%"

      # Pod 重启告警
      - alert: PodRestartingTooOften
        expr: rate(kube_pod_container_status_restarts_total[1h]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} 频繁重启"
          description: "最近 1 小时重启 {{ $value }} 次"
```

### AlertManager 配置

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m

# 路由配置
route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

  routes:
    # 严重告警立即发送
    - match:
        severity: critical
      receiver: 'critical-alerts'
      group_wait: 0s
      repeat_interval: 5m

    # 警告类告警
    - match:
        severity: warning
      receiver: 'warning-alerts'
      repeat_interval: 1h

# 接收器配置
receivers:
  # 默认接收器
  - name: 'default'
    webhook_configs:
      - url: 'http://alertmanager-webhook:8080/alert'

  # 严重告警 - 钉钉 + 短信
  - name: 'critical-alerts'
    webhook_configs:
      - url: 'http://dingtalk-webhook:8060/dingtalk/webhook/send'
        send_resolved: true
    # 邮件配置
    email_configs:
      - to: 'ops@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: 'password'

  # 警告告警 - 钉钉
  - name: 'warning-alerts'
    webhook_configs:
      - url: 'http://dingtalk-webhook:8060/dingtalk/webhook/send'
        send_resolved: true

# 抑制规则
inhibit_rules:
  # 如果服务下线，抑制该服务的其他告警
  - source_match:
      alertname: 'ServiceDown'
    target_match_re:
      alertname: '.*'
    equal: ['job', 'instance']
```

### 钉钉告警集成

```java
@Service
public class DingTalkAlertService {

    private final RestTemplate restTemplate;

    @Value("${dingtalk.webhook.url}")
    private String webhookUrl;

    public void sendAlert(AlertMessage alert) {
        Map<String, Object> message = new HashMap<>();
        message.put("msgtype", "markdown");

        Map<String, String> markdown = new HashMap<>();
        markdown.put("title", alert.getTitle());
        markdown.put("text", buildMarkdownText(alert));
        message.put("markdown", markdown);

        // 严重告警 @所有人
        if ("critical".equals(alert.getSeverity())) {
            Map<String, Object> at = new HashMap<>();
            at.put("isAtAll", true);
            message.put("at", at);
        }

        restTemplate.postForEntity(webhookUrl, message, String.class);
    }

    private String buildMarkdownText(AlertMessage alert) {
        return String.format(
            "### %s\n\n" +
            "- **告警等级**: %s\n" +
            "- **告警时间**: %s\n" +
            "- **告警详情**: %s\n" +
            "- **影响范围**: %s\n",
            alert.getTitle(),
            alert.getSeverity(),
            alert.getTimestamp(),
            alert.getDescription(),
            alert.getAffectedServices()
        );
    }
}
```

## 性能调优

### JVM 参数优化

```bash
# 生产环境推荐 JVM 参数
JAVA_OPTS="
  # 堆内存设置
  -Xms2g -Xmx2g

  # 使用 G1 GC
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:G1HeapRegionSize=16m

  # GC 日志
  -Xlog:gc*:file=/var/log/gc.log:time,uptime:filecount=5,filesize=100m

  # OOM 时生成 Heap Dump
  -XX:+HeapDumpOnOutOfMemoryError
  -XX:HeapDumpPath=/var/log/heapdump.hprof

  # 优化参数
  -XX:+UseStringDeduplication
  -XX:+ParallelRefProcEnabled

  # 远程调试（开发环境）
  # -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005
"
```

### 应用性能优化清单

1. **数据库优化**
   - 使用索引
   - 批量操作
   - 连接池配置
   - 慢查询优化

2. **缓存策略**
   - Redis 缓存热点数据
   - 本地缓存 (Caffeine)
   - 缓存预热
   - 缓存穿透/击穿/雪崩防护

3. **异步处理**
   - 异步方法 (@Async)
   - 消息队列解耦
   - 事件驱动架构

4. **限流降级**
   - Resilience4j 限流
   - 熔断器
   - 降级策略
   - 服务隔离

## 总结

完整的监控体系包括：

1. **指标监控**: Prometheus + Grafana
2. **日志管理**: ELK Stack / Loki
3. **链路追踪**: Jaeger / Zipkin
4. **告警通知**: AlertManager + 钉钉/邮件
5. **性能分析**: APM 工具

关键要点：
- 建立完整的监控指标体系
- 配置合理的告警规则
- 使用结构化日志
- 实施分布式追踪
- 持续性能优化
