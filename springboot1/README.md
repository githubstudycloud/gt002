# Spring Boot 大型多子项目企业级架构

## 项目概述

本项目展示如何使用 Spring Boot 构建大型企业级多模块应用,涵盖从开发到集群部署监控的完整技术栈。

## 技术栈选型

### 1. 核心框架
- **Spring Boot 3.2.x** - 应用框架
- **Spring Cloud 2023.0.x** - 微服务生态
- **Spring Security 6.x** - 安全认证
- **Spring Data JPA** - 数据访问层

### 2. 数据库层
- **MySQL 8.0** - 主数据库
- **PostgreSQL 15** - 分析型数据库(可选)
- **MyBatis-Plus 3.5.x** - 持久层增强
- **Flyway/Liquibase** - 数据库版本管理
- **ShardingSphere** - 分库分表中间件

### 3. 缓存层
- **Redis 7.x** - 分布式缓存
- **Redisson** - Redis客户端增强
- **Caffeine** - 本地缓存

### 4. 消息队列
- **RabbitMQ** - 消息中间件
- **Apache Kafka** - 流处理平台
- **RocketMQ** - 阿里云消息队列(可选)

### 5. 服务治理
- **Spring Cloud Gateway** - 网关
- **Nacos** - 服务注册与配置中心
- **Sentinel** - 流量控制与熔断降级
- **Seata** - 分布式事务
- **OpenFeign** - 声明式服务调用

### 6. 搜索引擎
- **Elasticsearch 8.x** - 全文搜索
- **Logstash** - 日志收集

### 7. 任务调度
- **XXL-Job** - 分布式任务调度
- **Quartz** - 定时任务

### 8. API文档
- **Knife4j (Swagger3)** - API文档生成
- **Spring REST Docs** - 测试驱动文档

### 9. 安全认证
- **JWT** - 无状态认证
- **OAuth2** - 授权框架
- **Spring Security** - 权限控制
- **Shiro** - 轻量级安全框架(备选)

### 10. 容器化与编排
- **Docker** - 容器化
- **Docker Compose** - 本地编排
- **Kubernetes (K8s)** - 集群编排
- **Helm** - K8s包管理

### 11. CI/CD
- **Jenkins** - 持续集成
- **GitLab CI/CD** - 代码托管与CI/CD
- **GitHub Actions** - 自动化工作流
- **ArgoCD** - GitOps部署

### 12. 监控告警
- **Prometheus** - 监控指标采集
- **Grafana** - 可视化监控
- **Spring Boot Actuator** - 应用监控端点
- **Micrometer** - 监控指标门面
- **Skywalking/Zipkin** - 分布式链路追踪
- **ELK Stack** - 日志分析
  - Elasticsearch - 存储
  - Logstash - 收集
  - Kibana - 可视化
- **Loki** - 日志聚合(Grafana生态)

### 13. 开发工具
- **Lombok** - 简化代码
- **MapStruct** - 对象映射
- **Hutool** - Java工具类库
- **Guava** - Google核心库
- **FastJSON2/Jackson** - JSON处理

### 14. 测试框架
- **JUnit 5** - 单元测试
- **Mockito** - Mock框架
- **TestContainers** - 集成测试
- **JMeter/Gatling** - 性能测试

### 15. 网关与负载均衡
- **Nginx** - 反向代理
- **HAProxy** - 负载均衡
- **Traefik** - 云原生边缘路由

### 16. 存储服务
- **MinIO** - 对象存储
- **FastDFS** - 分布式文件系统
- **OSS/S3** - 云存储

### 17. 配置管理
- **Spring Cloud Config** - 配置中心
- **Nacos Config** - 动态配置
- **Apollo** - 携程配置中心

## 项目结构

```
springboot1/
├── pom.xml                          # 父POM
├── README.md                        # 项目说明
├── docs/                            # 文档目录
│   ├── architecture.md              # 架构设计
│   ├── deployment.md                # 部署指南
│   └── tech-stack.md                # 技术栈详解
├── common/                          # 公共模块
│   ├── common-core/                 # 核心工具类
│   ├── common-redis/                # Redis配置
│   ├── common-security/             # 安全认证
│   ├── common-swagger/              # API文档
│   └── common-log/                  # 日志组件
├── gateway/                         # 网关服务
├── auth/                            # 认证服务
├── system/                          # 系统服务
│   ├── system-api/                  # API接口
│   ├── system-biz/                  # 业务逻辑
│   └── system-dao/                  # 数据访问
├── user/                            # 用户服务
│   ├── user-api/
│   ├── user-biz/
│   └── user-dao/
├── order/                           # 订单服务
│   ├── order-api/
│   ├── order-biz/
│   └── order-dao/
├── product/                         # 商品服务
│   ├── product-api/
│   ├── product-biz/
│   └── product-dao/
├── docker/                          # Docker配置
│   ├── docker-compose.yml           # 本地环境编排
│   ├── Dockerfile.template          # Dockerfile模板
│   └── mysql/                       # MySQL初始化脚本
├── kubernetes/                      # K8s配置
│   ├── base/                        # 基础配置
│   ├── overlays/                    # 环境覆盖
│   │   ├── dev/
│   │   ├── test/
│   │   └── prod/
│   └── helm/                        # Helm Charts
├── scripts/                         # 脚本目录
│   ├── build.sh                     # 构建脚本
│   ├── deploy.sh                    # 部署脚本
│   └── init-db.sh                   # 数据库初始化
└── monitoring/                      # 监控配置
    ├── prometheus/                  # Prometheus配置
    ├── grafana/                     # Grafana看板
    └── skywalking/                  # 链路追踪
```

## 环境划分

- **dev** - 开发环境
- **test** - 测试环境
- **staging** - 预发布环境
- **prod** - 生产环境

## 部署架构

### 本地开发
- Docker Compose 一键启动所有依赖服务
- Spring Boot DevTools 热部署

### 测试环境
- Docker Swarm 或小规模K8s集群
- Jenkins自动化构建部署

### 生产环境
- Kubernetes集群高可用部署
- Prometheus + Grafana监控
- ELK日志分析
- Skywalking链路追踪

## 快速开始

```bash
# 1. 构建项目
mvn clean install

# 2. 启动基础服务
cd docker
docker-compose up -d

# 3. 启动应用服务
cd ../scripts
./build.sh
./deploy.sh dev

# 4. 访问服务
# Gateway: http://localhost:8080
# Swagger UI: http://localhost:8080/doc.html
# Nacos: http://localhost:8848/nacos
# Grafana: http://localhost:3000
# Kibana: http://localhost:5601
```

## 开发规范

1. **代码规范**: 遵循阿里巴巴Java开发手册
2. **Git分支**: Git Flow工作流
3. **提交规范**: Conventional Commits
4. **API设计**: RESTful风格
5. **异常处理**: 统一异常处理机制
6. **日志规范**: SLF4J + Logback

## 性能优化

1. 数据库索引优化
2. Redis缓存策略
3. 连接池调优
4. JVM参数优化
5. 异步处理
6. 读写分离
7. 分库分表

## 安全加固

1. HTTPS加密传输
2. SQL注入防护
3. XSS攻击防护
4. CSRF防护
5. 接口限流
6. 敏感数据加密
7. 审计日志

## 高可用方案

1. 服务多实例部署
2. 数据库主从复制
3. Redis哨兵/集群
4. 消息队列集群
5. 限流降级熔断
6. 灰度发布
7. 故障自愈

## 许可证

MIT License
