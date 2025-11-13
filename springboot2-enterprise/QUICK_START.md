# 快速启动指南

本指南帮助您在 5 分钟内快速启动并体验整个项目。

## 方式一：使用 Docker Compose（推荐）

### 前置要求
- Docker 20.10+
- Docker Compose 2.0+

### 启动步骤

```bash
# 1. 进入项目目录
cd springboot2-enterprise

# 2. 启动所有服务（首次启动会自动下载镜像）
docker-compose up -d

# 3. 查看服务状态（等待所有服务变为 Up 状态）
docker-compose ps

# 4. 查看日志（可选）
docker-compose logs -f
```

### 访问服务

**基础设施**
- Nacos 控制台: http://localhost:8848/nacos
  - 用户名/密码: nacos/nacos
- Sentinel 控制台: http://localhost:8858
  - 用户名/密码: sentinel/sentinel

**监控系统**
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
  - 用户名/密码: admin/admin123456
- Zipkin 链路追踪: http://localhost:9411

**日志系统**
- Kibana: http://localhost:5601
- Elasticsearch: http://localhost:9200

**业务服务**
- 用户服务: http://localhost:8081
- API 文档: http://localhost:8081/doc.html
- Druid 监控: http://localhost:8081/druid
  - 用户名/密码: admin/admin

### 停止服务

```bash
# 停止所有服务
docker-compose stop

# 停止并删除容器（保留数据）
docker-compose down

# 停止并删除容器和数据卷（清空所有数据）
docker-compose down -v
```

## 方式二：本地开发环境

### 前置要求
- JDK 1.8+
- Maven 3.6+
- MySQL 8.0+
- Redis 5.0+
- Nacos 2.2.3+

### 启动步骤

#### 1. 准备基础设施

**启动 MySQL**
```sql
-- 创建数据库
CREATE DATABASE enterprise_user CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE nacos_config CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 导入 Nacos 配置表（从 Nacos 官网下载 SQL 脚本）
-- https://github.com/alibaba/nacos/blob/master/distribution/conf/mysql-schema.sql
```

**启动 Redis**
```bash
redis-server
```

**启动 Nacos**
```bash
# 单机模式启动
sh startup.sh -m standalone  # Linux/Mac
startup.cmd -m standalone     # Windows
```

#### 2. 修改配置

编辑 `enterprise-service-user/src/main/resources/application.yml`:
```yaml
spring:
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
      config:
        server-addr: localhost:8848
  datasource:
    url: jdbc:mysql://localhost:3306/enterprise_user?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false
    username: root
    password: your_password  # 修改为你的密码
  redis:
    host: localhost
    port: 6379
    password: # 如果有密码就填写
```

#### 3. 编译并启动

```bash
# 编译项目
mvn clean install -DskipTests

# 启动用户服务
cd enterprise-service-user
mvn spring-boot:run
```

或者使用 IDE：
- IntelliJ IDEA: 找到 `UserServiceApplication.java`，右键 -> Run
- Eclipse: 找到 `UserServiceApplication.java`，右键 -> Run As -> Java Application

#### 4. 验证服务

访问 http://localhost:8081/actuator/health，如果返回 `{"status":"UP"}`，说明服务启动成功。

## 方式三：使用 Makefile（快捷命令）

如果你的系统支持 `make` 命令：

```bash
# 查看所有可用命令
make help

# 启动本地开发环境（只启动基础设施）
make dev-start

# 编译打包项目
make package

# 完整部署流程（打包+构建镜像+启动）
make deploy-full

# 停止本地开发环境
make dev-stop
```

## 快速验证

### 1. 检查服务注册

访问 Nacos 控制台 http://localhost:8848/nacos，查看服务列表中是否有 `enterprise-user-service`。

### 2. 查看 API 文档

访问 http://localhost:8081/doc.html，查看所有可用的 API 接口。

### 3. 测试接口

使用 curl 或 Postman 测试：
```bash
# 健康检查
curl http://localhost:8081/actuator/health

# 查看指标（Prometheus 格式）
curl http://localhost:8081/actuator/prometheus
```

### 4. 查看监控

1. 访问 Grafana http://localhost:3000
2. 登录后导入 Dashboard（Dashboard ID: 4701 或 10280）
3. 查看应用监控指标

### 5. 查看日志

访问 Kibana http://localhost:5601，创建索引模式 `enterprise-logs-*`，查看应用日志。

## 常见问题

### Q1: 服务启动失败，提示无法连接数据库
**A:** 检查 MySQL 是否启动，用户名密码是否正确，数据库是否已创建。

### Q2: Nacos 连接失败
**A:** 确保 Nacos 服务已启动，检查配置文件中的 Nacos 地址是否正确。

### Q3: Docker Compose 启动慢
**A:** 首次启动需要下载镜像，请耐心等待。可以使用 `docker-compose logs -f` 查看启动进度。

### Q4: 端口冲突
**A:** 检查是否有其他服务占用了相同端口，可以修改 `docker-compose.yml` 中的端口映射。

### Q5: 内存不足
**A:** Docker Compose 环境至少需要 8GB RAM。可以在 `docker-compose.yml` 中调整各服务的内存限制。

## 下一步

恭喜！您已经成功启动了项目。接下来可以：

1. 阅读 [README.md](README.md) 了解完整的技术栈和架构设计
2. 查看 [部署文档](#kubernetes-部署) 了解如何部署到生产环境
3. 学习 [开发规范](#开发规范) 开始编写业务代码
4. 配置 [监控告警](#监控系统配置) 建立完善的运维体系

## 技术支持

如有问题，请查阅：
- 项目文档: [README.md](README.md)
- 提交 Issue: https://github.com/enterprise/springboot2-enterprise/issues

祝您使用愉快！
