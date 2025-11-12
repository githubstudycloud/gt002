# Claude Relay Service - 内网部署版本

> 基于 [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service) 官方项目，优化为适合内网环境部署的 Docker 方案。

## 快速开始

### Linux/macOS

```bash
# 加载镜像（如果是从 Git 获取）
./load-images.sh

# 初始化环境
./init-env.sh

# 启动服务
./deploy.sh start

# 查看管理员凭据
cat ./data/app/init.json
```

### Windows

```cmd
REM 加载镜像（如果是从 Git 获取）
load-images.sh

REM 初始化环境
init-env.bat

REM 启动服务
deploy.bat start

REM 查看管理员凭据
type .\data\app\init.json
```

访问管理界面: http://localhost:3000/web

## 文档

- [快速开始指南](QUICKSTART.md) - 5 分钟快速部署
- [完整部署文档](README-DEPLOYMENT.md) - 详细的部署说明
- [项目总结](PROJECT-SUMMARY.md) - 项目架构和技术细节

## 主要特性

- Docker 容器化部署，环境隔离
- 支持完全离线内网部署
- 镜像自动分卷，适合 Git 上传
- 一键初始化和部署脚本
- 跨平台支持（Linux/macOS/Windows）
- 数据持久化和备份友好

## 项目结构

```
claude-relay-service/
├── docker-compose.yml        # Docker 编排配置
├── Dockerfile                # 镜像构建文件
├── .env.example              # 环境变量模板
│
├── 部署脚本
│   ├── build.sh              # 构建镜像
│   ├── export-images.sh      # 导出镜像
│   ├── load-images.sh        # 加载镜像
│   ├── init-env.sh/bat       # 初始化环境
│   └── deploy.sh/bat         # 部署管理
│
├── 文档
│   ├── QUICKSTART.md         # 快速开始
│   ├── README-DEPLOYMENT.md  # 部署文档
│   └── PROJECT-SUMMARY.md    # 项目总结
│
└── 数据目录（运行时生成）
    ├── data/logs/            # 应用日志
    ├── data/app/             # 应用数据
    └── data/redis/           # Redis 数据
```

## 部署方案

### 方案 A: 外网构建 + 内网部署（推荐）

**构建机器（有外网）:**

```bash
./build.sh              # 构建镜像
./export-images.sh      # 导出并分卷
git add images/ && git commit -m "Add images"
```

**内网服务器:**

```bash
git clone <repo>
cd claude-relay-service
./load-images.sh        # 加载镜像
./init-env.sh           # 初始化
./deploy.sh start       # 启动
```

### 方案 B: 内网直接构建

```bash
./init-env.sh           # 初始化环境
./deploy.sh start       # 构建并启动
```

## 常用命令

```bash
./deploy.sh start       # 启动服务
./deploy.sh stop        # 停止服务
./deploy.sh restart     # 重启服务
./deploy.sh status      # 查看状态
./deploy.sh logs        # 查看日志
./deploy.sh clean       # 清理并重启
```

## 配置说明

主要配置在 `.env` 文件中：

```bash
# 服务端口
PORT=3000

# 绑定地址
BIND_HOST=0.0.0.0

# 必填：JWT 密钥（由 init-env.sh 自动生成）
JWT_SECRET=your-jwt-secret

# 必填：加密密钥（由 init-env.sh 自动生成）
ENCRYPTION_KEY=your-encryption-key

# 可选：管理员账户（留空则自动生成）
ADMIN_USERNAME=
ADMIN_PASSWORD=
```

## 系统要求

- **CPU**: 1 核心+
- **内存**: 512MB+（推荐 1GB）
- **磁盘**: 10GB+
- **Docker**: 20.10+
- **Docker Compose**: 1.29+

## 访问服务

启动成功后：

- **管理界面**: http://localhost:3000/web
- **API 端点**: http://localhost:3000/api
- **健康检查**: http://localhost:3000/health

## 故障排查

### 服务无法启动

```bash
# 查看日志
./deploy.sh logs

# 检查 Docker
docker ps
docker info
```

### 无法访问管理界面

```bash
# 检查端口
netstat -tulpn | grep 3000

# 检查防火墙
sudo ufw allow 3000
```

### 镜像加载失败

```bash
# 验证文件完整性
cd images && sha256sum -c checksums.txt

# 手动加载
docker load < images/claude-relay-service.tar.gz
```

## 数据备份

```bash
# 备份数据
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data
./deploy.sh start

# 恢复数据
./deploy.sh stop
tar -xzf backup-20240101.tar.gz
./deploy.sh start
```

## 安全建议

1. 修改默认管理员密码
2. 使用强随机密钥（脚本自动生成）
3. 配置防火墙限制访问
4. 定期备份数据
5. 不要将 `.env` 文件提交到 Git

## 许可和免责

- 本项目基于官方 Claude Relay Service 进行部署优化
- 仅供学习和研究使用
- 使用本服务可能违反 Anthropic 的服务条款
- 用户需自行承担使用风险

## 相关链接

- 官方项目: https://github.com/Wei-Shaw/claude-relay-service
- 官方文档: 参见 [README.md](README.md)

## 获取帮助

1. 查看 [完整部署文档](README-DEPLOYMENT.md)
2. 查看 [快速开始指南](QUICKSTART.md)
3. 查看 [项目总结](PROJECT-SUMMARY.md)
4. 查看容器日志: `./deploy.sh logs`

---

**版本**: v1.0.0
**最后更新**: 2025-01-12
