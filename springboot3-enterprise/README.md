# Spring Boot 3 大型企业级多模块项目技术栈

## 项目概述

本项目展示了使用 Spring Boot 3 构建大型企业级应用的完整技术栈和最佳实践，涵盖从开发、测试、构建、部署到生产环境的集群部署和监控。

## 技术栈选型

### 1. 核心框架
- **Spring Boot 3.2+** - 基于 Spring Framework 6，支持 Java 17+
- **Spring Cloud 2023.x (Hoxton/2023.0.0)** - 微服务治理
- **Maven/Gradle** - 多模块项目管理

### 2. 开发框架层

#### 2.1 Web 层
- **Spring WebFlux** - 响应式 Web 框架（高并发场景）
- **Spring MVC** - 传统 Servlet 栈（常规场景）
- **Spring Security 6** - 安全认证授权
- **JWT/OAuth2** - 无状态认证

#### 2.2 数据访问层
- **Spring Data JPA** - ORM 框架
- **MyBatis-Plus 3.5+** - 灵活的 SQL 操作
- **Hibernate 6** - JPA 实现
- **Redis** - 缓存与会话管理
- **Redisson** - 分布式锁和数据结构
- **Elasticsearch 8.x** - 搜索引擎

#### 2.3 数据库
- **PostgreSQL/MySQL 8** - 主数据库
- **MongoDB** - 文档数据库
- **ClickHouse** - 分析型数据库
- **Flyway/Liquibase** - 数据库版本管理

#### 2.4 消息队列
- **Apache Kafka** - 事件流平台
- **RabbitMQ** - 传统消息队列
- **Spring Cloud Stream** - 消息驱动微服务

### 3. 微服务组件

#### 3.1 服务治理
- **Spring Cloud Gateway** - API 网关
- **Spring Cloud LoadBalancer** - 客户端负载均衡
- **Resilience4j** - 熔断、限流、重试
- **Nacos/Consul** - 服务注册与配置中心

#### 3.2 配置管理
- **Spring Cloud Config** - 配置中心
- **Nacos Config** - 配置管理
- **Apollo** - 分布式配置中心

#### 3.3 分布式追踪
- **Spring Cloud Sleuth** - 分布式追踪
- **Micrometer Tracing** - 链路追踪抽象
- **OpenTelemetry** - 可观测性标准

### 4. 容器化与编排

#### 4.1 容器化
- **Docker** - 容器引擎
- **Docker Compose** - 本地多容器编排
- **Jib/Buildpacks** - 云原生镜像构建

#### 4.2 容器编排
- **Kubernetes (K8s)** - 容器编排平台
- **Helm** - K8s 包管理器
- **Kustomize** - K8s 配置管理

### 5. CI/CD 流水线

#### 5.1 版本控制
- **Git** - 版本控制
- **GitFlow/Trunk-Based** - 分支策略

#### 5.2 CI/CD 工具
- **Jenkins** - 自动化服务器
- **GitLab CI/CD** - GitLab 集成 CI/CD
- **GitHub Actions** - GitHub 原生 CI/CD
- **ArgoCD** - GitOps 持续部署

#### 5.3 制品管理
- **Nexus/Artifactory** - Maven 私服
- **Harbor** - 镜像仓库

### 6. 监控与可观测性

#### 6.1 指标监控
- **Prometheus** - 指标采集与存储
- **Grafana** - 可视化仪表板
- **Spring Boot Actuator** - 应用健康检查
- **Micrometer** - 指标门面

#### 6.2 日志管理
- **ELK Stack** (Elasticsearch + Logstash + Kibana)
- **Loki + Promtail** - 轻量级日志方案
- **Fluentd/Fluent Bit** - 日志收集器

#### 6.3 链路追踪
- **Jaeger** - 分布式追踪系统
- **Zipkin** - 链路追踪
- **SkyWalking** - APM 应用性能监控

#### 6.4 告警
- **Alertmanager** - Prometheus 告警管理
- **PagerDuty** - 告警通知平台
- **钉钉/企业微信** - 国内告警通知

### 7. 服务网格（可选）
- **Istio** - 服务网格
- **Linkerd** - 轻量级服务网格

### 8. 开发工具

#### 8.1 代码质量
- **SonarQube** - 代码质量管理
- **Checkstyle/SpotBugs** - 静态代码分析
- **JaCoCo** - 代码覆盖率

#### 8.2 API 文档
- **SpringDoc OpenAPI 3** - API 文档生成
- **Swagger UI** - API 调试工具

#### 8.3 测试
- **JUnit 5** - 单元测试
- **Mockito** - Mock 框架
- **TestContainers** - 集成测试容器
- **JMeter/Gatling** - 性能测试

## 项目模块结构

```
springboot3-enterprise/
├── pom.xml                          # 父 POM
├── common/                          # 通用模块
│   ├── common-core/                 # 核心工具类
│   ├── common-security/             # 安全模块
│   ├── common-redis/                # Redis 配置
│   └── common-log/                  # 日志配置
├── gateway/                         # API 网关
├── auth-service/                    # 认证服务
├── user-service/                    # 用户服务
├── order-service/                   # 订单服务
├── product-service/                 # 商品服务
├── infrastructure/                  # 基础设施
│   ├── docker/                      # Docker 配置
│   ├── kubernetes/                  # K8s 配置
│   ├── monitoring/                  # 监控配置
│   └── ci-cd/                       # CI/CD 配置
└── docs/                            # 文档
```

## 从开发到部署的完整流程

### 阶段 1: 本地开发
1. IDE 开发（IntelliJ IDEA）
2. 本地单元测试
3. Docker Compose 本地集成测试
4. Git 提交代码

### 阶段 2: CI 持续集成
1. 代码推送触发 CI 流水线
2. 编译构建（Maven/Gradle）
3. 单元测试 + 代码覆盖率检查
4. 代码质量扫描（SonarQube）
5. 集成测试（TestContainers）
6. 构建 Docker 镜像
7. 推送镜像到 Harbor

### 阶段 3: CD 持续部署

#### 3.1 测试环境
- ArgoCD 自动同步
- 部署到 K8s 测试集群
- 自动化端到端测试

#### 3.2 预发环境
- 手动审批
- 金丝雀发布
- 压力测试

#### 3.3 生产环境
- 蓝绿部署/滚动更新
- 健康检查
- 自动回滚机制

### 阶段 4: 运维监控
1. **指标监控**: Prometheus + Grafana
2. **日志分析**: ELK Stack
3. **链路追踪**: Jaeger
4. **告警通知**: Alertmanager
5. **自动扩缩容**: K8s HPA

## 集群部署架构

```
                           ┌─────────────┐
                           │   Ingress   │
                           │  Controller │
                           └──────┬──────┘
                                  │
                         ┌────────▼────────┐
                         │  API Gateway    │
                         │  (Spring Cloud) │
                         └────────┬────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼─────┐         ┌──────▼──────┐        ┌──────▼──────┐
    │  Service  │         │   Service   │        │   Service   │
    │  Pod 1-N  │         │   Pod 1-N   │        │   Pod 1-N   │
    └─────┬─────┘         └──────┬──────┘        └──────┬──────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
              ┌─────▼────┐  ┌───▼────┐  ┌───▼────┐
              │ Database │  │ Redis  │  │ Kafka  │
              │ Cluster  │  │Cluster │  │Cluster │
              └──────────┘  └────────┘  └────────┘
```

## 监控体系

```
Application (Spring Boot)
    │
    ├─ Metrics ──────────► Prometheus ──► Grafana
    │                                        │
    ├─ Logs ─────────────► ELK/Loki ────────┤
    │                                        │
    └─ Traces ───────────► Jaeger ──────────┤
                                             │
                                    ┌────────▼────────┐
                                    │  Alert Manager  │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │ Notification    │
                                    │ (钉钉/邮件/短信)  │
                                    └─────────────────┘
```

## 快速开始

详细的实现代码和配置请参考各子目录的 README 文档。

## 参考资源

- [Spring Boot 3 官方文档](https://spring.io/projects/spring-boot)
- [Spring Cloud 文档](https://spring.io/projects/spring-cloud)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Prometheus 文档](https://prometheus.io/docs/)

## 许可证

MIT License
