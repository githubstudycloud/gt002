# Spring Boot 2 企业级多模块项目架构

这是一个完整的 Spring Boot 2.x 企业级多模块项目，涵盖了从开发到生产集群部署及监控的完整技术栈。

## 项目概述

本项目展示了大型企业级 Spring Boot 项目的最佳实践，包括：
- 多模块项目架构设计
- 微服务架构实现
- 完整的 DevOps 工具链
- 生产级别的监控和日志方案
- Kubernetes 集群部署

## 技术栈

### 核心框架
- **Spring Boot 2.7.18**: 核心应用框架
- **Spring Cloud 2021.0.8**: 微服务治理框架
- **Spring Cloud Alibaba 2021.0.5.0**: 阿里巴巴微服务组件

### 服务治理
- **Nacos 2.2.3**: 服务注册与发现、配置中心
- **OpenFeign**: 声明式服务调用
- **Sentinel**: 流量控制、熔断降级
- **LoadBalancer**: 客户端负载均衡

### 数据持久化
- **MySQL 8.0**: 关系型数据库
- **MyBatis Plus 3.5.4**: ORM 框架
- **Druid 1.2.20**: 数据库连接池
- **Redis 7.0**: 缓存数据库
- **Redisson 3.24.3**: Redis 客户端

### 消息队列
- **RocketMQ 4.9.7**: 分布式消息中间件
- **Kafka 3.1.2**: 流式数据平台

### 安全认证
- **Sa-Token 1.37.0**: 权限认证框架
- **JWT**: Token 生成和验证

### 监控与日志
- **Prometheus**: 指标采集
- **Grafana**: 数据可视化
- **Spring Boot Actuator**: 应用监控端点
- **Micrometer**: 指标导出
- **ELK Stack**: 日志聚合分析
  - Elasticsearch 7.17.12: 日志存储与搜索
  - Logstash 7.17.12: 日志处理
  - Kibana 7.17.12: 日志可视化
- **Zipkin**: 分布式链路追踪
- **SkyWalking**: APM 监控

### 文档工具
- **Knife4j 3.0.3**: API 文档增强工具（基于 Swagger）

### 工具类库
- **Lombok**: 简化 Java 代码
- **Hutool 5.8.23**: Java 工具类库
- **FastJson2**: JSON 处理
- **Guava 32.1.3**: Google 核心库

### 容器化与编排
- **Docker**: 容器化技术
- **Docker Compose**: 本地多容器编排
- **Kubernetes**: 生产环境容器编排

## 项目结构

```
springboot2-enterprise/
├── enterprise-common/           # 公共模块
│   ├── result/                 # 统一响应结果封装
│   └── exception/              # 全局异常处理
├── enterprise-core/            # 核心模块
│   ├── config/                # 数据库、Redis、消息队列配置
│   └── interceptor/           # 拦截器
├── enterprise-service-user/    # 用户服务
├── enterprise-service-order/   # 订单服务
├── enterprise-service-product/ # 商品服务
├── enterprise-gateway/         # API 网关
├── enterprise-admin/          # 管理后台
├── enterprise-monitor/        # 监控服务
├── k8s/                       # Kubernetes 部署配置
│   ├── namespace.yaml         # 命名空间配置
│   ├── configmap.yaml        # 配置映射
│   ├── user-service/         # 用户服务部署配置
│   └── infrastructure/       # 基础设施配置
├── deploy/                    # 部署配置
│   ├── prometheus/           # Prometheus 配置
│   ├── grafana/             # Grafana 配置
│   ├── logstash/            # Logstash 配置
│   └── mysql/               # MySQL 初始化脚本
├── docker-compose.yml        # Docker Compose 编排文件
└── pom.xml                  # 父 POM 文件
```

## 快速开始

### 前置要求

- JDK 1.8+
- Maven 3.6+
- Docker 20.10+
- Docker Compose 2.0+（可选）
- Kubernetes 1.20+（生产环境）

### 本地开发环境

#### 1. 克隆项目

```bash
git clone <repository-url>
cd springboot2-enterprise
```

#### 2. 编译项目

```bash
mvn clean install -DskipTests
```

#### 3. 启动基础设施（使用 Docker Compose）

```bash
# 启动所有基础设施服务（MySQL、Redis、Nacos 等）
docker-compose up -d mysql redis nacos sentinel

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f nacos
```

#### 4. 初始化数据库

创建数据库：
```sql
CREATE DATABASE enterprise_user CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE nacos_config CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 5. 启动应用

```bash
# 方式一：直接运行
cd enterprise-service-user
mvn spring-boot:run

# 方式二：使用 Docker Compose
docker-compose up -d user-service
```

#### 6. 访问服务

- 用户服务: http://localhost:8081
- Nacos 控制台: http://localhost:8848/nacos (nacos/nacos)
- Druid 监控: http://localhost:8081/druid (admin/admin)
- API 文档: http://localhost:8081/doc.html

## Docker 部署

### 完整环境部署

启动所有服务（包括监控和日志系统）：

```bash
docker-compose up -d
```

### 服务访问地址

- **业务服务**
  - 用户服务: http://localhost:8081

- **基础设施**
  - Nacos: http://localhost:8848/nacos (nacos/nacos)
  - Sentinel: http://localhost:8858 (sentinel/sentinel)

- **监控系统**
  - Prometheus: http://localhost:9090
  - Grafana: http://localhost:3000 (admin/admin123456)
  - Zipkin: http://localhost:9411

- **日志系统**
  - Kibana: http://localhost:5601
  - Elasticsearch: http://localhost:9200

### Docker 命令

```bash
# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f [service-name]

# 停止服务
docker-compose stop

# 停止并删除容器
docker-compose down

# 停止并删除容器及数据卷
docker-compose down -v
```

## Kubernetes 部署

### 1. 创建命名空间和配置

```bash
# 创建命名空间
kubectl apply -f k8s/namespace.yaml

# 创建 ConfigMap 和 Secret
kubectl apply -f k8s/configmap.yaml
```

### 2. 部署基础设施

```bash
# 部署 MySQL
kubectl apply -f k8s/infrastructure/mysql.yaml

# 部署 Redis
kubectl apply -f k8s/infrastructure/redis.yaml

# 部署 Nacos
kubectl apply -f k8s/infrastructure/nacos.yaml
```

### 3. 部署业务服务

```bash
# 部署用户服务
kubectl apply -f k8s/user-service/deployment.yaml

# 查看部署状态
kubectl get pods -n enterprise

# 查看服务
kubectl get svc -n enterprise
```

### 4. 配置 Ingress（可选）

```bash
kubectl apply -f k8s/ingress.yaml
```

### 5. 监控部署

```bash
# 查看 HPA 状态
kubectl get hpa -n enterprise

# 查看 Pod 资源使用情况
kubectl top pods -n enterprise

# 查看 Pod 日志
kubectl logs -f <pod-name> -n enterprise
```

### Kubernetes 常用命令

```bash
# 查看所有资源
kubectl get all -n enterprise

# 进入容器
kubectl exec -it <pod-name> -n enterprise -- /bin/sh

# 查看 Pod 详情
kubectl describe pod <pod-name> -n enterprise

# 扩缩容
kubectl scale deployment user-service --replicas=5 -n enterprise

# 更新镜像
kubectl set image deployment/user-service user-service=enterprise/user-service:1.0.1 -n enterprise

# 回滚
kubectl rollout undo deployment/user-service -n enterprise

# 查看回滚历史
kubectl rollout history deployment/user-service -n enterprise
```

## 监控系统配置

### Prometheus 监控

1. 访问 Prometheus: http://localhost:9090
2. 查看 Targets: http://localhost:9090/targets
3. 常用 PromQL 查询：
   ```promql
   # JVM 内存使用率
   jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

   # HTTP 请求 QPS
   rate(http_server_requests_seconds_count[1m])

   # 接口响应时间 P99
   histogram_quantile(0.99, rate(http_server_requests_seconds_bucket[5m]))
   ```

### Grafana 可视化

1. 访问 Grafana: http://localhost:3000
2. 登录: admin / admin123456
3. 添加数据源（已自动配置）
4. 导入推荐 Dashboard:
   - JVM (Micrometer): Dashboard ID 4701
   - Spring Boot 2.1: Dashboard ID 10280
   - Node Exporter: Dashboard ID 1860

### ELK 日志系统

1. 访问 Kibana: http://localhost:5601
2. 创建索引模式: `enterprise-logs-*`
3. 查看实时日志流
4. 创建告警规则

### Zipkin 链路追踪

1. 访问 Zipkin: http://localhost:9411
2. 查看服务依赖关系
3. 分析慢请求
4. 排查服务调用问题

## 开发规范

### 代码规范

- 遵循阿里巴巴 Java 开发手册
- 使用 Lombok 简化代码
- 统一异常处理
- 统一响应结果封装

### API 规范

- RESTful API 设计
- 统一接口版本管理
- 完善的 API 文档（Knife4j）

### 数据库规范

- 使用 MyBatis Plus 代码生成器
- 逻辑删除
- 乐观锁
- 自动填充创建时间和更新时间

### Git 规范

- 分支管理：master/develop/feature/hotfix
- 提交信息规范：feat/fix/docs/style/refactor/test/chore

## 性能优化

### 应用层优化

- 使用连接池（Druid、Redis 连接池）
- 缓存策略（Redis 多级缓存）
- 异步处理（消息队列）
- 数据库优化（索引、分页）

### JVM 优化

```bash
-server
-Xms2g
-Xmx2g
-XX:+UseG1GC
-XX:MaxGCPauseMillis=100
-XX:+ParallelRefProcEnabled
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/app/logs/heapdump.hprof
```

### Kubernetes 资源优化

- 合理设置 requests 和 limits
- 配置 HPA 自动扩缩容
- 使用资源配额（ResourceQuota）
- 配置 PodDisruptionBudget

## 高可用方案

### 数据库高可用

- MySQL 主从复制
- MySQL MGR 集群
- 读写分离

### Redis 高可用

- Redis Sentinel 哨兵模式
- Redis Cluster 集群模式

### 应用高可用

- 多副本部署（K8s Deployment replicas >= 3）
- 健康检查（Liveness/Readiness Probe）
- 优雅停机
- 熔断降级（Sentinel）

## 故障排查

### 查看日志

```bash
# Docker 环境
docker-compose logs -f user-service

# Kubernetes 环境
kubectl logs -f <pod-name> -n enterprise

# 查看 ELK 日志
# 访问 Kibana: http://localhost:5601
```

### 监控告警

- 查看 Prometheus 告警规则
- 配置 Grafana 告警通知
- 接入钉钉/企业微信机器人

### 性能分析

- 使用 Arthas 进行在线诊断
- JVM 内存分析（heapdump）
- 线程栈分析（jstack）
- Zipkin 链路分析

## 安全加固

### 应用安全

- 接口鉴权（Sa-Token）
- SQL 注入防护（MyBatis）
- XSS 防护
- CSRF 防护

### 数据安全

- 敏感数据加密
- 数据库连接加密
- Redis 密码认证

### 网络安全

- K8s NetworkPolicy
- Ingress TLS
- 限流防刷（Sentinel）

## 持续集成/持续部署

### Jenkins Pipeline 示例

```groovy
pipeline {
    agent any
    stages {
        stage('编译') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('构建镜像') {
            steps {
                sh 'docker build -t enterprise/user-service:${BUILD_NUMBER} .'
            }
        }
        stage('推送镜像') {
            steps {
                sh 'docker push enterprise/user-service:${BUILD_NUMBER}'
            }
        }
        stage('部署到K8s') {
            steps {
                sh 'kubectl set image deployment/user-service user-service=enterprise/user-service:${BUILD_NUMBER} -n enterprise'
            }
        }
    }
}
```

### GitLab CI/CD 示例

参考 `.gitlab-ci.yml` 文件

## 常见问题

### Q1: Nacos 无法连接？
A: 检查网络配置，确保服务能访问 Nacos 地址。Docker 环境使用服务名，K8s 环境使用 Service DNS。

### Q2: Redis 连接失败？
A: 检查 Redis 密码配置，确保防火墙开放 6379 端口。

### Q3: 服务启动慢？
A: 增加健康检查的 initialDelaySeconds，优化 JVM 参数，使用 SSD 存储。

### Q4: Pod 频繁重启？
A: 检查 OOM、健康检查配置、应用日志，调整资源限制。

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 联系方式

- 作者: Enterprise Team
- 邮箱: enterprise@example.com
- 项目地址: https://github.com/enterprise/springboot2-enterprise
