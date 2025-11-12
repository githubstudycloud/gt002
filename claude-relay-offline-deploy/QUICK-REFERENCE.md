# Claude Relay Service - 快速参考卡片

## 一分钟速查

### 快速部署（内网）

```bash
cd claude-relay-service
./load-images.sh && ./init-env.sh && ./deploy.sh start
```

### 快速部署（有外网）

```bash
cd claude-relay-service
./init-env.sh && ./deploy.sh start
```

---

## 常用命令

| 命令 | 说明 |
|------|------|
| `./deploy.sh start` | 启动服务 |
| `./deploy.sh stop` | 停止服务 |
| `./deploy.sh restart` | 重启服务 |
| `./deploy.sh status` | 查看状态 |
| `./deploy.sh logs` | 查看日志 |
| `./deploy.sh clean` | 清理重启 |

---

## 文件位置

| 文件 | 位置 |
|------|------|
| 管理员凭据 | `./data/app/init.json` |
| 环境配置 | `.env` |
| 应用日志 | `./data/logs/` |
| Redis 数据 | `./data/redis/` |

---

## 访问地址

| 服务 | URL |
|------|-----|
| 管理界面 | `http://localhost:3000/web` |
| Claude API | `http://localhost:3000/api` |
| 健康检查 | `http://localhost:3000/health` |

---

## 配置要点

```bash
# .env 文件必填项
JWT_SECRET=<自动生成>
ENCRYPTION_KEY=<自动生成>

# 可选配置
PORT=3000
BIND_HOST=0.0.0.0
```

---

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| 无法启动 | `./deploy.sh logs` 查看日志 |
| 无法访问 | 检查 `BIND_HOST` 和防火墙 |
| 镜像加载失败 | `cd images && sha256sum -c checksums.txt` |
| 忘记密码 | `cat ./data/app/init.json` |

---

## 数据备份

```bash
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data
./deploy.sh start
```

---

## 镜像管理

| 操作 | 命令 |
|------|------|
| 构建镜像 | `./build.sh` |
| 导出镜像 | `./export-images.sh` |
| 加载镜像 | `./load-images.sh` |

---

## 端口修改

```bash
# 编辑 .env 文件
nano .env
# 修改 PORT=3000 为其他端口
# 重启服务
./deploy.sh restart
```

---

## 文档导航

| 文档 | 用途 |
|------|------|
| [README-INTRANET.md](README-INTRANET.md) | 主文档 |
| [QUICKSTART.md](QUICKSTART.md) | 快速开始 |
| [README-DEPLOYMENT.md](README-DEPLOYMENT.md) | 完整指南 |
| [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) | 技术总结 |

---

## Windows 用户

将所有 `.sh` 命令替换为 `.bat`:

```cmd
deploy.bat start
deploy.bat stop
init-env.bat
```

---

## Docker 命令

| 操作 | 命令 |
|------|------|
| 查看容器 | `docker ps` |
| 查看日志 | `docker logs claude-relay-service` |
| 进入容器 | `docker exec -it claude-relay-service sh` |
| 查看镜像 | `docker images` |

---

## 环境要求

- Docker 20.10+
- Docker Compose 1.29+
- 512MB+ 内存
- 10GB+ 磁盘空间

---

**提示**: 完整文档请查看 [README-DEPLOYMENT.md](README-DEPLOYMENT.md)
