# Claude Relay Service 内网部署指南

本文档详细说明如何在内网环境中部署 Claude Relay Service。

## 目录

- [项目简介](#项目简介)
- [架构说明](#架构说明)
- [部署准备](#部署准备)
- [部署流程](#部署流程)
- [配置说明](#配置说明)
- [使用指南](#使用指南)
- [故障排查](#故障排查)
- [维护管理](#维护管理)

---

## 项目简介

Claude Relay Service (CRS) 是一个自托管的 Claude API 中继服务，提供以下功能：

- **多账户管理**: 支持添加多个 Claude 账户，自动负载均衡和故障转移
- **统一访问入口**: 为 Claude、OpenAI、Gemini 等服务提供统一的 API 接口
- **使用控制**: 支持 API Key 级别的使用限制、模型限制和客户端限制
- **Web 管理界面**: 直观的管理面板，支持账户管理、API Key 管理和使用统计
- **使用分析**: 详细的 Token 使用统计和成本监控

---

## 架构说明

### 系统架构

```
┌─────────────────────────────────────────────┐
│         Claude Relay Service                │
│  ┌────────────┐         ┌───────────┐      │
│  │  Web UI    │         │  API      │      │
│  │  :3000/web │◄───────►│  :3000/   │      │
│  └────────────┘         └───────────┘      │
│         │                     │             │
│         └─────────┬───────────┘             │
│                   ▼                         │
│         ┌──────────────────┐                │
│         │  Redis Database  │                │
│         │  (数据存储)       │                │
│         └──────────────────┘                │
└─────────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────┐
  │  Claude API     │
  │  (外网访问)      │
  └─────────────────┘
```

### 容器组成

- **claude-relay-service**: 主服务容器，提供 Web 界面和 API 服务
- **redis**: Redis 数据库容器，存储账户信息、API Key 和使用统计

### 数据持久化

所有数据通过 Docker Volume 映射到主机目录：

```
./data/
├── logs/          # 应用日志
├── app/           # 应用数据（账户、API Key 等）
└── redis/         # Redis 持久化数据
```

---

## 部署准备

### 硬件要求

- **CPU**: 1 核心及以上
- **内存**: 512MB 及以上（推荐 1GB）
- **磁盘**: 10GB 及以上可用空间
- **网络**: 需要能访问 Claude API（api.anthropic.com）

### 软件要求

- **操作系统**: Linux (推荐 Ubuntu 20.04+) 或 macOS
- **Docker**: 20.10+ 版本
- **Docker Compose**: 1.29+ 版本（或 Docker Compose V2）

### 安装 Docker

#### Ubuntu/Debian

```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 添加当前用户到 docker 组（可选）
sudo usermod -aG docker $USER
```

#### CentOS/RHEL

```bash
# 安装 Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

---

## 部署流程

### 方案 A: 有外网环境构建镜像

适用于有外网访问的构建机器，构建后将镜像导出到内网。

#### 第一步：构建机器上操作

```bash
# 1. 克隆仓库
git clone <repository-url>
cd claude-relay-service

# 2. 构建 Docker 镜像
chmod +x build.sh
./build.sh

# 3. 导出镜像（自动分卷，适合 Git）
chmod +x export-images.sh
./export-images.sh

# 4. 提交镜像到 Git（或通过其他方式传输）
git add images/
git commit -m "Add Docker images"
git push
```

#### 第二步：内网服务器上操作

```bash
# 1. 克隆仓库（从内网 Git 或复制文件）
git clone <repository-url>
cd claude-relay-service

# 2. 加载镜像
chmod +x load-images.sh
./load-images.sh

# 3. 初始化环境
chmod +x init-env.sh
./init-env.sh

# 4. 启动服务
chmod +x deploy.sh
./deploy.sh start
```

### 方案 B: 直接在内网构建（需要配置镜像源）

如果内网服务器有 npm 和 Docker 镜像源，可以直接构建：

```bash
# 1. 克隆仓库
git clone <repository-url>
cd claude-relay-service

# 2. 配置 npm 镜像源（可选）
npm config set registry https://registry.npmmirror.com

# 3. 初始化环境
chmod +x init-env.sh
./init-env.sh

# 4. 构建并启动
chmod +x deploy.sh
./deploy.sh start
```

---

## 配置说明

### 环境变量配置

主要配置文件为 `.env`，可以通过 `init-env.sh` 自动生成，或手动从 `.env.example` 复制。

#### 必填配置

```bash
# JWT 密钥（至少 32 字符）
JWT_SECRET=your-generated-jwt-secret-key

# 加密密钥（必须是 32 字符）
ENCRYPTION_KEY=your-32-character-encryption-key
```

#### 可选配置

```bash
# 服务配置
BIND_HOST=0.0.0.0          # 绑定地址
PORT=3000                   # 服务端口

# 管理员账户（留空则自动生成）
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-password

# Redis 配置
REDIS_PASSWORD=your-redis-password

# 日志级别
LOG_LEVEL=info             # error, warn, info, debug

# 时区设置（中国为 8）
TIMEZONE_OFFSET=8
```

### 生成密钥

可以使用以下命令生成安全的随机密钥：

```bash
# 生成 JWT Secret
openssl rand -base64 48

# 生成 Encryption Key（32 字符）
openssl rand -hex 16

# 生成 Redis 密码
openssl rand -base64 24
```

### 端口配置

默认端口为 `3000`，如需修改：

1. 编辑 `.env` 文件
2. 修改 `PORT` 变量
3. 重启服务：`./deploy.sh restart`

---

## 使用指南

### 启动服务

```bash
# 启动服务
./deploy.sh start

# 查看状态
./deploy.sh status

# 查看日志
./deploy.sh logs
```

### 访问管理界面

服务启动后，通过浏览器访问：

- **本地访问**: http://localhost:3000/web
- **局域网访问**: http://<服务器IP>:3000/web

### 首次登录

1. 查看自动生成的管理员凭据：

```bash
cat ./data/app/init.json
```

2. 使用凭据登录管理界面

### 添加 Claude 账户

1. 登录管理界面
2. 进入 "账户管理"
3. 点击 "添加账户"
4. 完成 OAuth 授权流程

### 创建 API Key

1. 进入 "API Key 管理"
2. 点击 "创建 API Key"
3. 配置限制选项：
   - Token 限制
   - 模型限制
   - 客户端限制
4. 保存并复制生成的 API Key

### 配置客户端

#### Claude Code

编辑环境变量或配置文件：

```bash
ANTHROPIC_BASE_URL="http://<服务器IP>:3000/api/"
ANTHROPIC_AUTH_TOKEN="<your-api-key>"
```

#### 其他客户端

根据客户端类型配置相应的 Base URL 和 API Key：

- Claude API: `http://<服务器IP>:3000/api/`
- OpenAI API: `http://<服务器IP>:3000/openai/`
- Gemini API: `http://<服务器IP>:3000/gemini/`

---

## 故障排查

### 服务无法启动

1. **检查 Docker 服务**

```bash
sudo systemctl status docker
```

2. **检查端口占用**

```bash
netstat -tulpn | grep 3000
# 或
lsof -i :3000
```

3. **查看容器日志**

```bash
./deploy.sh logs
# 或
docker logs claude-relay-service
```

### 无法访问管理界面

1. **检查防火墙**

```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 3000

# CentOS/RHEL
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

2. **检查服务状态**

```bash
./deploy.sh status
```

3. **检查绑定地址**

确保 `.env` 中的 `BIND_HOST` 设置为 `0.0.0.0`（允许外部访问）

### Redis 连接失败

1. **检查 Redis 容器**

```bash
docker ps | grep redis
docker logs claude-relay-redis
```

2. **检查 Redis 密码**

确保 `.env` 中的 `REDIS_PASSWORD` 配置正确

### 镜像加载失败

1. **检查镜像文件完整性**

```bash
cd images/
sha256sum -c checksums.txt
```

2. **检查磁盘空间**

```bash
df -h
```

3. **手动加载镜像**

```bash
docker load < images/claude-relay-service.tar.gz
docker load < images/redis.tar.gz
```

---

## 维护管理

### 常用命令

```bash
# 启动服务
./deploy.sh start

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# 查看状态
./deploy.sh status

# 查看日志
./deploy.sh logs

# 清理并重启（删除所有容器和数据）
./deploy.sh clean
```

### 备份数据

建议定期备份 `./data` 目录：

```bash
# 创建备份
tar -czf backup-$(date +%Y%m%d).tar.gz ./data

# 停止服务后备份（推荐）
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data
./deploy.sh start
```

### 恢复数据

```bash
# 停止服务
./deploy.sh stop

# 恢复数据
tar -xzf backup-20240101.tar.gz

# 启动服务
./deploy.sh start
```

### 更新服务

```bash
# 1. 备份数据
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data

# 2. 拉取最新代码
git pull

# 3. 重新构建镜像（如需要）
./build.sh

# 4. 重启服务
./deploy.sh start
```

### 查看资源使用

```bash
# 查看容器资源使用
docker stats claude-relay-service claude-relay-redis

# 查看磁盘使用
du -sh ./data/*
```

### 清理日志

```bash
# 清理旧日志（保留最近 7 天）
find ./data/logs -name "*.log" -mtime +7 -delete

# 清理 Docker 日志
sudo sh -c "truncate -s 0 /var/lib/docker/containers/*/*-json.log"
```

---

## 安全建议

1. **修改默认密码**: 首次登录后立即修改管理员密码
2. **使用强密钥**: 确保 JWT_SECRET 和 ENCRYPTION_KEY 足够复杂
3. **限制访问**: 配置防火墙，仅允许必要的 IP 访问
4. **定期备份**: 建立定期备份机制
5. **监控日志**: 定期检查日志文件，发现异常访问
6. **更新服务**: 及时更新到最新版本，修复安全漏洞

---

## 许可和免责

- 本服务仅供学习和研究使用
- 使用本服务可能违反 Anthropic 的服务条款
- 用户需自行承担使用风险
- 建议使用美国地区的服务器以避免 Cloudflare 封锁

---

## 支持

如遇到问题，请：

1. 查看本文档的故障排查章节
2. 查看项目 GitHub Issues
3. 查看容器日志：`./deploy.sh logs`

---

**最后更新**: 2025-01-12
