# Spring Boot 4 企业级多模块项目架构

## 项目概述

本项目展示了基于 Spring Boot 4 的大型企业级多模块应用架构，涵盖从开发到集群部署监控的完整技术栈。

## 技术栈选型

### 核心框架
- **Spring Boot 4.0.x** - 最新企业级应用框架
- **Spring Cloud 2024.x** - 微服务全家桶
- **Java 21** - LTS版本，支持虚拟线程和现代Java特性

### 数据层
- **Spring Data JPA** - ORM框架
- **PostgreSQL 16** - 主数据库
- **Redis 7.x** - 分布式缓存
- **MongoDB 7.x** - 文档数据库（日志、非结构化数据）
- **Elasticsearch 8.x** - 搜索引擎
- **Flyway** - 数据库版本管理

### 消息队列
- **Apache Kafka** - 高吞吐量消息队列
- **RabbitMQ** - 可靠性消息队列（可选）

### 服务治理与配置
- **Spring Cloud Config** - 配置中心
- **Spring Cloud Gateway** - API网关
- **Spring Cloud LoadBalancer** - 负载均衡
- **Resilience4j** - 熔断降级
- **Nacos/Consul** - 服务注册与发现

### 认证授权
- **Spring Security 6** - 安全框架
- **OAuth 2.1** - 授权协议
- **JWT** - 令牌认证
- **Keycloak** - 统一身份认证平台

### 监控与可观测性
- **Micrometer** - 指标收集
- **Prometheus** - 指标存储
- **Grafana** - 可视化监控
- **Loki** - 日志聚合
- **Tempo** - 分布式追踪
- **Spring Boot Actuator** - 应用健康检查
- **OpenTelemetry** - 统一可观测性标准

### DevOps工具链
- **Docker** - 容器化
- **Kubernetes** - 容器编排
- **Helm** - K8s包管理
- **GitLab CI / GitHub Actions** - CI/CD
- **ArgoCD** - GitOps持续部署
- **Harbor** - 镜像仓库
- **SonarQube** - 代码质量
- **Trivy** - 安全扫描

### 测试框架
- **JUnit 5** - 单元测试
- **Testcontainers** - 集成测试
- **WireMock** - API模拟
- **JMeter / Gatling** - 性能测试

### 文档与API
- **SpringDoc OpenAPI** - API文档生成
- **Swagger UI** - API交互界面

### 构建工具
- **Maven 3.9+** - 项目构建

## 项目模块结构

```
springboot4-enterprise/
├── pom.xml                           # 父POM
├── common/                           # 公共模块
│   ├── common-core/                  # 核心工具类
│   ├── common-security/              # 安全配置
│   ├── common-redis/                 # Redis配置
│   ├── common-web/                   # Web通用配置
│   └── common-logging/               # 日志配置
├── infrastructure/                   # 基础设施模块
│   ├── gateway-service/              # API网关
│   ├── config-service/               # 配置中心
│   └── registry-service/             # 服务注册中心（可选）
├── modules/                          # 业务模块
│   ├── user-service/                 # 用户服务
│   ├── order-service/                # 订单服务
│   ├── product-service/              # 商品服务
│   ├── payment-service/              # 支付服务
│   └── notification-service/         # 通知服务
├── deployment/                       # 部署配置
│   ├── docker/                       # Docker配置
│   ├── kubernetes/                   # K8s配置
│   │   ├── base/                     # 基础配置
│   │   ├── dev/                      # 开发环境
│   │   ├── staging/                  # 预生产环境
│   │   └── prod/                     # 生产环境
│   ├── helm/                         # Helm Charts
│   └── monitoring/                   # 监控配置
├── scripts/                          # 脚本工具
└── docs/                             # 文档
```

## 开发环境搭建

### 前置要求
- Java 21
- Maven 3.9+
- Docker & Docker Compose
- Kubernetes (Minikube/Kind for local)

### 本地开发环境启动

```bash
# 启动本地依赖服务（PostgreSQL, Redis, Kafka等）
cd deployment/docker
docker-compose up -d

# 构建项目
mvn clean install

# 启动各个服务
cd modules/user-service && mvn spring-boot:run
```

## 部署流程

### 1. 开发阶段
- 本地开发使用Docker Compose启动依赖服务
- 单元测试 + 集成测试（Testcontainers）
- 代码提交触发CI流程

### 2. CI/CD流程
```yaml
构建 → 测试 → 代码扫描 → 镜像构建 → 镜像扫描 → 推送镜像仓库 → 部署到K8s
```

### 3. Kubernetes集群部署
- 使用Helm管理应用部署
- 支持多环境（dev/staging/prod）
- 蓝绿部署或金丝雀发布

### 4. 监控与告警
- Prometheus采集指标
- Grafana展示监控面板
- Loki聚合日志
- Tempo追踪分布式调用链
- AlertManager处理告警

## 架构设计原则

1. **微服务拆分** - 按业务领域拆分服务
2. **DDD设计** - 领域驱动设计
3. **CQRS模式** - 读写分离（适用场景）
4. **Event Sourcing** - 事件溯源（适用场景）
5. **API网关模式** - 统一入口
6. **配置外部化** - 配置中心管理
7. **容器化部署** - 环境一致性
8. **可观测性优先** - 日志、指标、追踪三位一体

## 数据一致性方案

- **Saga模式** - 分布式事务
- **Seata** - 分布式事务框架（可选）
- **事件驱动** - 最终一致性
- **本地消息表** - 可靠消息

## 安全最佳实践

- OAuth 2.1 + JWT认证
- API限流与熔断
- 数据加密传输（TLS）
- 敏感数据加密存储
- 安全扫描集成
- RBAC权限控制

## 性能优化

- 多级缓存策略（本地缓存 + Redis）
- 数据库连接池优化
- 异步处理（虚拟线程）
- 限流降级
- CDN加速静态资源

## 快速开始

详细的开发指南请参考：
- [开发环境搭建指南](docs/dev-setup.md)
- [微服务开发指南](docs/microservice-guide.md)
- [部署运维手册](docs/deployment-guide.md)
- [监控告警配置](docs/monitoring-guide.md)

## License

MIT License
