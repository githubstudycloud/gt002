# 项目目录结构

```
springboot2-enterprise/
│
├── pom.xml                                    # 父 POM 配置
├── README.md                                  # 项目说明文档
├── QUICK_START.md                            # 快速启动指南
├── ARCHITECTURE.md                           # 系统架构设计文档
├── PROJECT_STRUCTURE.md                      # 本文件
├── .gitignore                                # Git 忽略文件配置
├── .gitlab-ci.yml                            # GitLab CI/CD 配置
├── Makefile                                  # Make 命令配置
├── docker-compose.yml                        # Docker Compose 编排文件
│
├── enterprise-common/                        # 公共模块
│   ├── pom.xml
│   └── src/main/java/com/enterprise/common/
│       ├── result/                          # 统一响应结果封装
│       │   ├── Result.java                  # 统一响应实体
│       │   └── ResultCode.java              # 响应状态码枚举
│       ├── exception/                       # 全局异常处理
│       │   ├── BusinessException.java       # 业务异常
│       │   └── GlobalExceptionHandler.java  # 全局异常处理器
│       ├── constant/                        # 常量定义
│       ├── enums/                          # 枚举类型
│       └── utils/                          # 工具类
│
├── enterprise-core/                         # 核心模块
│   ├── pom.xml
│   └── src/main/java/com/enterprise/core/
│       ├── config/                         # 配置类
│       │   ├── DruidConfig.java           # Druid 数据源配置
│       │   ├── RedisConfig.java           # Redis 配置
│       │   ├── MyBatisPlusConfig.java     # MyBatis Plus 配置
│       │   └── WebMvcConfig.java          # Web MVC 配置
│       ├── interceptor/                    # 拦截器
│       │   ├── AuthInterceptor.java       # 认证拦截器
│       │   └── LogInterceptor.java        # 日志拦截器
│       ├── aspect/                         # AOP 切面
│       │   ├── LogAspect.java             # 日志切面
│       │   └── CacheAspect.java           # 缓存切面
│       └── base/                           # 基础类
│           ├── BaseEntity.java            # 基础实体类
│           ├── BaseController.java        # 基础控制器
│           └── BaseService.java           # 基础服务类
│
├── enterprise-service-user/                 # 用户服务
│   ├── pom.xml
│   ├── Dockerfile                          # Docker 镜像构建文件
│   └── src/
│       ├── main/
│       │   ├── java/com/enterprise/user/
│       │   │   ├── UserServiceApplication.java  # 启动类
│       │   │   ├── controller/            # 控制器层
│       │   │   │   └── UserController.java
│       │   │   ├── service/               # 服务层
│       │   │   │   ├── UserService.java
│       │   │   │   └── impl/
│       │   │   │       └── UserServiceImpl.java
│       │   │   ├── mapper/                # 数据访问层
│       │   │   │   └── UserMapper.java
│       │   │   ├── entity/                # 实体类
│       │   │   │   └── User.java
│       │   │   ├── dto/                   # 数据传输对象
│       │   │   │   ├── UserDTO.java
│       │   │   │   └── UserQueryDTO.java
│       │   │   └── vo/                    # 视图对象
│       │   │       └── UserVO.java
│       │   └── resources/
│       │       ├── application.yml         # 应用配置
│       │       ├── application-dev.yml     # 开发环境配置
│       │       ├── application-test.yml    # 测试环境配置
│       │       ├── application-prod.yml    # 生产环境配置
│       │       ├── mapper/                # MyBatis XML
│       │       │   └── UserMapper.xml
│       │       └── logback-spring.xml     # 日志配置
│       └── test/                          # 测试代码
│           └── java/com/enterprise/user/
│               └── UserServiceTest.java
│
├── enterprise-service-order/                # 订单服务（结构同 user-service）
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/...
│
├── enterprise-service-product/              # 商品服务（结构同 user-service）
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/...
│
├── enterprise-gateway/                      # API 网关
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/
│       └── main/
│           ├── java/com/enterprise/gateway/
│           │   ├── GatewayApplication.java
│           │   ├── filter/               # 网关过滤器
│           │   │   ├── AuthGatewayFilter.java
│           │   │   └── LogGatewayFilter.java
│           │   └── config/
│           │       └── GatewayConfig.java
│           └── resources/
│               └── application.yml
│
├── enterprise-admin/                        # 管理后台
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/...
│
├── enterprise-monitor/                      # 监控服务
│   ├── pom.xml
│   ├── Dockerfile
│   └── src/...
│
├── k8s/                                    # Kubernetes 部署配置
│   ├── namespace.yaml                      # 命名空间配置
│   ├── configmap.yaml                     # 配置映射
│   ├── ingress.yaml                       # Ingress 路由配置
│   │
│   ├── user-service/                      # 用户服务 K8s 配置
│   │   ├── deployment.yaml               # Deployment 配置
│   │   ├── service.yaml                  # Service 配置
│   │   └── hpa.yaml                      # 水平自动扩缩容配置
│   │
│   ├── order-service/                     # 订单服务 K8s 配置
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   │
│   ├── product-service/                   # 商品服务 K8s 配置
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   │
│   ├── gateway/                           # 网关 K8s 配置
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   │
│   └── infrastructure/                    # 基础设施 K8s 配置
│       ├── mysql/
│       │   ├── statefulset.yaml
│       │   ├── service.yaml
│       │   └── pvc.yaml
│       ├── redis/
│       │   ├── statefulset.yaml
│       │   ├── service.yaml
│       │   └── pvc.yaml
│       ├── nacos/
│       │   ├── statefulset.yaml
│       │   ├── service.yaml
│       │   └── pvc.yaml
│       ├── prometheus/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── configmap.yaml
│       ├── grafana/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   └── configmap.yaml
│       └── elk/
│           ├── elasticsearch-statefulset.yaml
│           ├── logstash-deployment.yaml
│           └── kibana-deployment.yaml
│
├── deploy/                                 # 部署配置文件
│   ├── prometheus/
│   │   ├── prometheus.yml                # Prometheus 配置
│   │   └── rules/                        # 告警规则
│   │       ├── app-rules.yml
│   │       └── infra-rules.yml
│   │
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── datasources/             # 数据源配置
│   │   │   │   └── datasource.yml
│   │   │   └── dashboards/              # Dashboard 配置
│   │   │       └── dashboard.yml
│   │   └── dashboards/                   # Dashboard JSON
│   │       ├── jvm-dashboard.json
│   │       ├── spring-boot-dashboard.json
│   │       └── mysql-dashboard.json
│   │
│   ├── logstash/
│   │   ├── logstash.conf                # Logstash 配置
│   │   └── patterns/                    # 日志解析模式
│   │
│   ├── mysql/
│   │   └── init/                        # MySQL 初始化脚本
│   │       ├── 01-create-database.sql
│   │       ├── 02-create-tables.sql
│   │       └── 03-init-data.sql
│   │
│   ├── rocketmq/
│   │   └── broker.conf                  # RocketMQ Broker 配置
│   │
│   └── scripts/                          # 部署脚本
│       ├── start-all.sh                 # 启动所有服务
│       ├── stop-all.sh                  # 停止所有服务
│       ├── backup-db.sh                 # 数据库备份
│       └── deploy-k8s.sh                # K8s 部署脚本
│
├── docs/                                   # 文档目录
│   ├── api/                              # API 文档
│   │   ├── user-api.md
│   │   ├── order-api.md
│   │   └── product-api.md
│   ├── design/                           # 设计文档
│   │   ├── database-design.md
│   │   ├── architecture-design.md
│   │   └── security-design.md
│   └── operation/                        # 运维文档
│       ├── deployment.md
│       ├── monitoring.md
│       └── troubleshooting.md
│
└── scripts/                               # 脚本工具
    ├── build.sh                          # 构建脚本
    ├── test.sh                           # 测试脚本
    ├── docker-build.sh                   # Docker 构建脚本
    └── k8s-deploy.sh                     # K8s 部署脚本
```

## 模块说明

### 公共模块（enterprise-common）
提供项目中所有服务共用的基础功能：
- 统一响应结果封装
- 全局异常处理
- 常量定义
- 工具类

### 核心模块（enterprise-core）
提供核心基础设施配置：
- 数据库配置（Druid、MyBatis Plus）
- 缓存配置（Redis、Redisson）
- 消息队列配置
- AOP 切面
- 拦截器

### 业务服务模块
- **enterprise-service-user**: 用户服务
- **enterprise-service-order**: 订单服务
- **enterprise-service-product**: 商品服务

每个服务模块遵循标准的三层架构：
- Controller 层：接口定义
- Service 层：业务逻辑
- Mapper 层：数据访问

### 基础设施模块
- **enterprise-gateway**: API 网关（路由、鉴权、限流）
- **enterprise-admin**: 管理后台
- **enterprise-monitor**: 监控服务

### 配置目录
- **k8s/**: Kubernetes 部署配置
- **deploy/**: 各种中间件和工具的配置文件
- **docs/**: 项目文档
- **scripts/**: 自动化脚本

## 配置文件说明

### 应用配置
- `application.yml`: 主配置文件
- `application-dev.yml`: 开发环境配置
- `application-test.yml`: 测试环境配置
- `application-prod.yml`: 生产环境配置

### 中间件配置
- `docker-compose.yml`: 本地开发环境一键启动
- `prometheus.yml`: 监控指标采集配置
- `logstash.conf`: 日志处理配置

### 部署配置
- `Dockerfile`: 服务镜像构建配置
- `k8s/*.yaml`: Kubernetes 资源定义
- `.gitlab-ci.yml`: CI/CD 流水线配置

## 命名规范

### Java 类命名
- **Controller**: `XxxController.java`
- **Service**: `XxxService.java` / `XxxServiceImpl.java`
- **Mapper**: `XxxMapper.java`
- **Entity**: `Xxx.java`
- **DTO**: `XxxDTO.java`
- **VO**: `XxxVO.java`

### 配置文件命名
- **K8s 资源**: `xxx-deployment.yaml`, `xxx-service.yaml`
- **配置文件**: `xxx-config.yml`, `xxx.conf`
- **脚本文件**: `xxx.sh`, `xxx-deploy.sh`

## 扩展指南

### 添加新服务
1. 创建新的 Maven 模块
2. 添加必要的依赖（common、core）
3. 编写业务代码（Controller、Service、Mapper）
4. 创建 Dockerfile
5. 创建 K8s 配置文件
6. 更新 docker-compose.yml
7. 更新父 POM

### 添加新的基础设施
1. 在 docker-compose.yml 中添加服务定义
2. 在 k8s/infrastructure/ 中创建 K8s 配置
3. 更新监控配置（如需要）
4. 更新文档

## 最佳实践

1. **代码组织**: 遵循分层架构，保持清晰的依赖关系
2. **配置管理**: 敏感信息使用环境变量或 Secret
3. **日志规范**: 使用统一的日志格式和级别
4. **异常处理**: 使用全局异常处理器
5. **API 设计**: 遵循 RESTful 规范
6. **版本控制**: Git Flow 工作流
7. **代码审查**: 提交前进行 Code Review
8. **自动化测试**: 编写单元测试和集成测试
