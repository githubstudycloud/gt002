# 开发环境搭建指南

## 前置要求

### 必需软件
1. **Java 21** (OpenJDK or Oracle JDK)
   ```bash
   java -version
   # 应显示: openjdk version "21.x.x"
   ```

2. **Maven 3.9+**
   ```bash
   mvn -version
   ```

3. **Docker Desktop** (或 Docker Engine + Docker Compose)
   ```bash
   docker --version
   docker-compose --version
   ```

4. **Git**
   ```bash
   git --version
   ```

### 推荐工具
- **IntelliJ IDEA Ultimate** (带 Spring Boot 支持)
- **VS Code** + Java Extension Pack
- **Postman** 或 **Insomnia** (API 测试)
- **DBeaver** 或 **DataGrip** (数据库管理)
- **K9s** (Kubernetes 集群管理)

## 项目克隆与构建

### 1. 克隆项目
```bash
git clone https://github.com/your-org/springboot4-enterprise.git
cd springboot4-enterprise
```

### 2. 构建项目
```bash
# 完整构建（包括所有模块）
mvn clean install

# 跳过测试的快速构建
mvn clean install -DskipTests

# 只构建特定模块
cd modules/user-service
mvn clean install
```

## 本地开发环境

### 启动依赖服务

项目提供了 Docker Compose 配置来启动所有依赖服务：

```bash
cd deployment/docker
docker-compose up -d
```

这将启动以下服务：
- PostgreSQL (端口 5432)
- Redis (端口 6379)
- MongoDB (端口 27017)
- Elasticsearch (端口 9200)
- Kafka + Zookeeper (端口 9092)
- Prometheus (端口 9090)
- Grafana (端口 3000)
- Loki (端口 3100)
- Tempo (端口 3200, 4317, 4318)
- Jaeger (端口 16686)
- Nacos (端口 8848)

### 验证服务状态

```bash
# 查看所有容器状态
docker-compose ps

# 查看服务日志
docker-compose logs -f postgres
docker-compose logs -f redis

# 健康检查
curl http://localhost:9090/-/healthy  # Prometheus
curl http://localhost:8848/nacos/     # Nacos
```

### 访问管理界面

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger UI**: http://localhost:16686
- **Kafka UI**: http://localhost:8090
- **Nacos Console**: http://localhost:8848/nacos (nacos/nacos)

## 启动微服务

### 方式1：使用 Maven (开发模式)

在不同的终端窗口中启动各个服务：

```bash
# Terminal 1 - Gateway Service
cd infrastructure/gateway-service
mvn spring-boot:run

# Terminal 2 - User Service
cd modules/user-service
mvn spring-boot:run

# Terminal 3 - Order Service
cd modules/order-service
mvn spring-boot:run

# Terminal 4 - Product Service
cd modules/product-service
mvn spring-boot:run
```

### 方式2：使用 IDE

在 IntelliJ IDEA 中：
1. 打开项目
2. 等待 Maven 索引完成
3. 找到各服务的主类（`*Application.java`）
4. 右键点击 -> Run 或 Debug

### 方式3：使用 JAR 文件

```bash
# 先构建
mvn clean package -DskipTests

# 运行各个服务
java -jar infrastructure/gateway-service/target/gateway-service-1.0.0-SNAPSHOT.jar
java -jar modules/user-service/target/user-service-1.0.0-SNAPSHOT.jar
```

## 环境配置

### 应用配置文件

每个服务都有多个环境的配置文件：

```
src/main/resources/
├── application.yml           # 通用配置
├── application-dev.yml       # 开发环境
├── application-staging.yml   # 预生产环境
└── application-prod.yml      # 生产环境
```

### 切换环境

```bash
# 方式1：使用环境变量
export SPRING_PROFILES_ACTIVE=dev
mvn spring-boot:run

# 方式2：Maven 命令行参数
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 方式3：JAR 启动参数
java -jar app.jar --spring.profiles.active=dev
```

### 常用配置覆盖

```bash
# 更改端口
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8085"

# 更改数据库连接
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.datasource.url=jdbc:postgresql://localhost:5432/mydb"
```

## 数据库初始化

### 自动初始化（Flyway）

项目使用 Flyway 进行数据库版本管理，启动时会自动执行迁移脚本：

```
src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__create_orders_table.sql
└── V3__create_products_table.sql
```

### 手动初始化

```bash
# 连接到 PostgreSQL
docker exec -it postgres psql -U enterprise -d enterprise_db

# 执行 SQL
\i /path/to/init.sql

# 查看表
\dt

# 退出
\q
```

## 开发工具配置

### IntelliJ IDEA 插件推荐

1. **Lombok** - 简化 Java 代码
2. **Spring Boot Assistant** - Spring Boot 开发辅助
3. **SonarLint** - 代码质量检查
4. **Docker** - Docker 支持
5. **Database Navigator** - 数据库工具
6. **Rainbow Brackets** - 代码可读性
7. **GitToolBox** - Git 增强

### Lombok 配置

在 IntelliJ IDEA 中启用注解处理：
1. Settings -> Build, Execution, Deployment -> Compiler -> Annotation Processors
2. 勾选 "Enable annotation processing"

### Code Style

项目根目录包含 `.editorconfig` 文件，确保 IDE 配置一致。

## 热重载开发

### Spring Boot DevTools

在 `pom.xml` 中已包含：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

### IntelliJ IDEA 配置

1. Settings -> Build, Execution, Deployment -> Compiler
2. 勾选 "Build project automatically"
3. Settings -> Advanced Settings
4. 勾选 "Allow auto-make to start even if developed application is currently running"

## 测试

### 单元测试

```bash
# 运行所有单元测试
mvn test

# 运行特定测试类
mvn test -Dtest=UserServiceTest

# 运行特定测试方法
mvn test -Dtest=UserServiceTest#testCreateUser
```

### 集成测试

```bash
# 运行集成测试（使用 Testcontainers）
mvn verify -P integration-tests
```

### API 测试

使用 Postman Collection：
1. 导入 `postman/Enterprise-API.postman_collection.json`
2. 配置环境变量（localhost:8080）
3. 运行测试套件

## 常见问题排查

### 端口冲突

```bash
# 查看端口占用 (Windows)
netstat -ano | findstr :8080

# 查看端口占用 (Linux/Mac)
lsof -i :8080

# 杀死进程
kill -9 <PID>
```

### 依赖下载失败

```bash
# 清理 Maven 缓存
mvn dependency:purge-local-repository

# 强制更新
mvn clean install -U
```

### Docker 容器无法启动

```bash
# 查看容器日志
docker-compose logs -f <service-name>

# 重启服务
docker-compose restart <service-name>

# 完全重建
docker-compose down -v
docker-compose up -d --build
```

### 数据库连接失败

1. 检查 PostgreSQL 容器是否运行：`docker ps | grep postgres`
2. 检查连接配置：`application-dev.yml`
3. 测试连接：`docker exec -it postgres psql -U enterprise -d enterprise_db`

## 下一步

- 阅读 [微服务开发指南](microservice-guide.md)
- 了解 [API 文档](api-documentation.md)
- 查看 [部署运维手册](deployment-guide.md)
