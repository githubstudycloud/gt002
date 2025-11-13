# 快速启动指南

## 5分钟快速开始

### 前置条件
- Docker Desktop 已安装并运行
- JDK 17+ 已安装
- Maven 3.8+ 已安装

### 步骤1: 克隆项目
```bash
git clone https://github.com/your-org/springboot1.git
cd springboot1
```

### 步骤2: 启动基础设施
```bash
cd docker
docker-compose up -d
```

等待2-3分钟,确保所有服务启动成功:
```bash
docker-compose ps
```

### 步骤3: 初始化数据库
数据库会通过init脚本自动初始化。访问以下地址验证:
- MySQL: `mysql -h127.0.0.1 -uroot -proot123456`
- Nacos: http://localhost:8848/nacos (nacos/nacos)

### 步骤4: 构建项目
```bash
cd ..
./scripts/build.sh
```

### 步骤5: 启动应用 (选择一种方式)

**方式A: IDE启动 (推荐开发)**
1. 用IDEA打开项目
2. 等待Maven依赖下载完成
3. 运行各模块的Application.java
4. 配置VM参数: `-Dspring.profiles.active=dev`

**方式B: 命令行启动**
```bash
# 启动网关
cd gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev &

# 启动其他服务...
```

**方式C: Docker启动**
```bash
./scripts/docker-build-all.sh
docker-compose -f docker/docker-compose-app.yml up -d
```

### 步骤6: 验证服务

访问以下地址:
- Gateway: http://localhost:8080
- Swagger API文档: http://localhost:8080/doc.html
- Nacos控制台: http://localhost:8848/nacos
- RabbitMQ管理: http://localhost:15672
- Grafana监控: http://localhost:3000

## 常用命令

### Docker管理
```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 查看日志
docker-compose logs -f [service-name]

# 重启某个服务
docker-compose restart [service-name]
```

### 构建部署
```bash
# 编译打包
./scripts/build.sh

# 部署到K8s开发环境
./scripts/deploy.sh dev

# 部署到K8s生产环境
./scripts/deploy.sh prod
```

### 数据库操作
```bash
# 连接MySQL
mysql -h127.0.0.1 -P3306 -uroot -proot123456

# 查看数据库
SHOW DATABASES;
USE springboot1;
SHOW TABLES;
```

### Redis操作
```bash
# 连接Redis
redis-cli -h 127.0.0.1 -p 6379 -a redis123456

# 查看所有key
KEYS *

# 查看key值
GET key_name
```

## 常见问题

### Q1: 端口冲突
**问题:** docker-compose启动失败,提示端口被占用
**解决:** 修改docker-compose.yml中的端口映射,或停止占用端口的程序

### Q2: 内存不足
**问题:** Docker容器启动失败
**解决:** 增加Docker Desktop的内存限制 (建议8GB+)

### Q3: Maven依赖下载慢
**问题:** 依赖下载速度慢或超时
**解决:** 配置阿里云Maven镜像 (已在pom.xml中配置)

### Q4: Nacos无法注册服务
**问题:** 服务启动成功但Nacos看不到
**解决:**
1. 检查Nacos是否正常运行
2. 检查application.yml中的nacos配置
3. 查看服务日志排查错误

### Q5: 数据库连接失败
**问题:** 应用启动报数据库连接错误
**解决:**
1. 确认MySQL容器已启动
2. 检查数据库配置是否正确
3. 等待MySQL完全启动(约30秒)

## 项目结构速览

```
springboot1/
├── common/              # 公共模块
│   ├── common-core     # 核心工具
│   ├── common-redis    # Redis配置
│   ├── common-security # 安全认证
│   └── common-swagger  # API文档
├── gateway/            # 网关服务
├── auth/               # 认证服务
├── user/               # 用户服务
├── order/              # 订单服务
├── product/            # 商品服务
├── docker/             # Docker配置
├── kubernetes/         # K8s配置
├── scripts/            # 部署脚本
├── monitoring/         # 监控配置
└── docs/               # 文档
```

## 下一步

1. 阅读 [架构设计文档](docs/architecture.md)
2. 查看 [技术栈详解](docs/tech-stack.md)
3. 学习 [部署指南](docs/deployment.md)
4. 浏览 API文档: http://localhost:8080/doc.html

## 技术支持

- 文档: [docs/](docs/)
- Issues: https://github.com/your-org/springboot1/issues
- Wiki: https://github.com/your-org/springboot1/wiki

## 贡献指南

欢迎提交Pull Request和Issue!

1. Fork项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件
