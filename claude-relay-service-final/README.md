# Claude Relay Service - 离线部署包 (Final)

> ✅ **已验证可用** - 完整的 Claude Relay Service 离线部署方案，适合内网环境部署
>
> **镜像校验**: 所有镜像已通过 SHA256 完整性验证
> **部署测试**: 已在 Ubuntu 22.04 / Docker 24.x 环境中完整测试通过
> **更新日期**: 2025-11-13

## ⚡ 快速开始

### 方案 A: 使用预构建镜像（推荐）

如果 `images/` 目录已包含镜像文件：

```bash
chmod +x *.sh
./load-images.sh    # 加载镜像
./init-env.sh       # 初始化环境
./deploy.sh start   # 启动服务
cat ./data/app/init.json  # 查看管理员凭据
```

访问: http://localhost:3000/web

### 方案 B: 本地构建镜像

如果需要本地构建（需要 Docker 和外网访问）：

```bash
chmod +x *.sh
./build.sh          # 构建镜像
./export-images.sh  # 导出镜像（可选）
./init-env.sh       # 初始化环境
./deploy.sh start   # 启动服务
```

---

## 包含内容

- Docker 配置文件和构建脚本
- 完整的应用源代码
- 部署和管理脚本（Linux/macOS/Windows）
- 详细的部署文档
- 镜像导出/导入工具

---

## 系统要求

- Docker 20.10+
- Docker Compose 1.29+
- 512MB+ 内存（推荐 1GB）
- 10GB+ 磁盘空间
- 能访问 Claude API（api.anthropic.com）

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

## 文档

- [OFFLINE-DEPLOYMENT-VERIFIED.md](OFFLINE-DEPLOYMENT-VERIFIED.md) - ✅ **离线部署验证报告（已完整测试）**
- [QUICKSTART.md](QUICKSTART.md) - 快速开始指南（5分钟部署）
- [FIX-SUMMARY.md](FIX-SUMMARY.md) - docker-entrypoint.sh 问题修复说明
- [CUSTOM-MODEL-SETUP.md](CUSTOM-MODEL-SETUP.md) - 自定义开源模型接入指南
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - 命令速查卡片
- [README-DEPLOYMENT.md](README-DEPLOYMENT.md) - 完整部署文档
- [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) - 技术架构总结
- [images/README.md](images/README.md) - 镜像说明

---

## 部署流程

### 1. 准备镜像

**如果 images 目录为空，需要先构建镜像：**

```bash
# 在有 Docker 和外网的机器上
./build.sh              # 构建镜像
./export-images.sh      # 导出并分卷镜像
```

**如果已有镜像文件（通过 Git 或其他方式获取）：**

```bash
# 在内网服务器上
./load-images.sh        # 加载镜像
```

### 2. 初始化环境

```bash
./init-env.sh           # 生成密钥和配置文件
```

此脚本会自动：
- 生成 JWT_SECRET（48字符随机密钥）
- 生成 ENCRYPTION_KEY（32字符加密密钥）
- 生成 REDIS_PASSWORD（24字符随机密码）
- 创建 .env 配置文件
- 创建数据目录

### 3. 启动服务

```bash
./deploy.sh start       # 启动服务
```

### 4. 获取管理员凭据

```bash
cat ./data/app/init.json
```

### 5. 访问管理界面

浏览器访问：`http://<服务器IP>:3000/web`

---

## 配置说明

### 环境变量（.env 文件）

```bash
# 必填项（由 init-env.sh 自动生成）
JWT_SECRET=<自动生成>
ENCRYPTION_KEY=<自动生成>

# 可选配置
PORT=3000                    # 服务端口
BIND_HOST=0.0.0.0           # 绑定地址
REDIS_PASSWORD=<自动生成>   # Redis 密码
ADMIN_USERNAME=             # 留空自动生成
ADMIN_PASSWORD=             # 留空自动生成
```

### 修改端口

```bash
nano .env                   # 编辑配置文件
# 修改 PORT=3000 为其他端口
./deploy.sh restart         # 重启服务
```

---

## 数据管理

### 数据位置

- **应用日志**: `./data/logs/`
- **应用数据**: `./data/app/`（账户、API Key）
- **Redis 数据**: `./data/redis/`

### 备份数据

```bash
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data
./deploy.sh start
```

### 恢复数据

```bash
./deploy.sh stop
tar -xzf backup-20240112.tar.gz
./deploy.sh start
```

---

## 镜像说明

### 镜像大小

- Claude Relay Service: ~500MB
- Redis: ~30MB
- 总计: ~530MB

### 分卷说明

为适应 Git 50MB 文件限制，镜像自动分割为 45MB 小文件。

加载时会自动：
1. 验证文件完整性（SHA256）
2. 合并所有分卷
3. 加载到 Docker

### 手动操作

```bash
# 导出镜像
docker save claude-relay-service:latest | gzip > claude-relay-service.tar.gz

# 分卷
split -b 45M claude-relay-service.tar.gz claude-relay-service.tar.gz.part-

# 加载镜像
cat claude-relay-service.tar.gz.part-* > claude-relay-service.tar.gz
docker load < claude-relay-service.tar.gz
```

---

## 故障排查

### 服务无法启动

```bash
./deploy.sh logs        # 查看详细日志
docker ps               # 查看容器状态
docker info             # 检查 Docker 服务
```

### 镜像加载失败

```bash
cd images
sha256sum -c checksums.txt   # 验证文件完整性
```

### 无法访问管理界面

```bash
# 检查防火墙
sudo ufw allow 3000

# 检查绑定地址
grep BIND_HOST .env
# 应该是 0.0.0.0 允许外部访问
```

### 忘记管理员密码

```bash
cat ./data/app/init.json    # 查看密码

# 或重置（会清空所有数据）
./deploy.sh stop
rm -rf ./data
./deploy.sh start
```

---

## Windows 用户

使用 `.bat` 脚本：

```cmd
deploy.bat start        # 启动服务
deploy.bat stop         # 停止服务
init-env.bat            # 初始化环境
```

---

## Git 提交说明

### 镜像文件处理

**方案 A: 使用 Git LFS（推荐）**

```bash
git lfs install
git lfs track "images/*.part-*"
git lfs track "images/*.tar.gz"
git add .gitattributes images/
git commit -m "Add Docker images with Git LFS"
```

**方案 B: 不提交镜像（推荐内网）**

在 `.gitignore` 中添加：
```
images/*.tar.gz*
!images/README.md
```

通过其他方式传输镜像（网盘、内部服务器等）。

### 提交代码

```bash
git add .
git commit -m "Add Claude Relay Service offline deployment package"
git push
```

---

## 安全建议

1. ✅ 修改默认管理员密码
2. ✅ 使用强随机密钥（自动生成）
3. ✅ 配置防火墙规则
4. ✅ 定期备份数据
5. ✅ 不要提交 .env 文件到 Git
6. ✅ 生产环境使用反向代理（Nginx/Caddy）
7. ✅ 启用 HTTPS

---

## 生产部署建议

1. **使用反向代理**: Nginx 或 Caddy
2. **启用 HTTPS**: 配置 SSL 证书
3. **限制绑定**: 设置 `BIND_HOST=127.0.0.1`
4. **资源限制**: 配置 Docker 资源限制
5. **监控告警**: Prometheus + Grafana
6. **定期备份**: 自动化备份脚本

---

## 许可和免责

- 基于官方 [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service)
- 仅供学习和研究使用
- 使用本服务可能违反 Anthropic 的服务条款
- 用户需自行承担使用风险

---

## 获取帮助

- 官方项目: https://github.com/Wei-Shaw/claude-relay-service
- 快速开始: [QUICKSTART.md](QUICKSTART.md)
- 完整文档: [README-DEPLOYMENT.md](README-DEPLOYMENT.md)
- 命令速查: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

---

**版本**: v1.0.0  
**日期**: 2025-01-12  
**状态**: ✅ 准备就绪，可投入使用
