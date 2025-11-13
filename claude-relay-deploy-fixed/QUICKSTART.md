# Claude Relay Service 快速开始

## 5 分钟快速部署指南

### 前置要求

- 已安装 Docker 和 Docker Compose
- 服务器可访问 Claude API（api.anthropic.com）

---

## 方案一：有外网环境

### 构建机器（有外网）

```bash
# 1. 克隆仓库
git clone <repository-url>
cd claude-relay-service

# 2. 构建并导出镜像
chmod +x build.sh export-images.sh
./build.sh
./export-images.sh

# 3. 提交到 Git
git add images/
git commit -m "Add images"
git push
```

### 内网服务器

```bash
# 1. 克隆仓库
git clone <repository-url>
cd claude-relay-service

# 2. 加载镜像并部署
chmod +x load-images.sh init-env.sh deploy.sh
./load-images.sh
./init-env.sh
./deploy.sh start

# 3. 查看管理员凭据
cat ./data/app/init.json
```

访问: http://<服务器IP>:3000/web

---

## 方案二：内网直接构建

```bash
# 1. 克隆仓库
git clone <repository-url>
cd claude-relay-service

# 2. 初始化并启动
chmod +x init-env.sh deploy.sh
./init-env.sh
./deploy.sh start

# 3. 查看管理员凭据
cat ./data/app/init.json
```

访问: http://<服务器IP>:3000/web

---

## 快速配置

### 1. 登录管理界面

使用 `data/app/init.json` 中的凭据登录

### 2. 添加 Claude 账户

管理界面 → 账户管理 → 添加账户 → 完成 OAuth 授权

### 3. 创建 API Key

管理界面 → API Key 管理 → 创建 API Key

### 4. 配置客户端

设置环境变量：

```bash
ANTHROPIC_BASE_URL="http://<服务器IP>:3000/api/"
ANTHROPIC_AUTH_TOKEN="<your-api-key>"
```

---

## 常用命令

```bash
./deploy.sh start      # 启动服务
./deploy.sh stop       # 停止服务
./deploy.sh restart    # 重启服务
./deploy.sh status     # 查看状态
./deploy.sh logs       # 查看日志
```

---

## 故障排查

### 无法启动

```bash
# 查看日志
./deploy.sh logs

# 检查 Docker
sudo systemctl status docker
```

### 无法访问

```bash
# 检查防火墙
sudo ufw allow 3000

# 检查绑定地址（确保是 0.0.0.0）
grep BIND_HOST .env
```

### 镜像加载失败

```bash
# 验证文件完整性
cd images && sha256sum -c checksums.txt

# 手动加载
docker load < images/claude-relay-service.tar.gz
```

---

## 下一步

- 阅读完整文档: [README-DEPLOYMENT.md](README-DEPLOYMENT.md)
- 配置反向代理（生产环境推荐）
- 设置定期备份

---

**需要帮助？** 查看完整部署文档或项目 Issues。
