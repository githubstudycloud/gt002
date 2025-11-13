# Claude Relay Service 内网部署项目总结

## 项目概述

本项目将 [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service) 官方一键安装脚本转换为适合内网环境部署的 Docker 方案，支持镜像分卷上传到 Git。

---

## 项目结构

```
claude-relay-service/
├── docker-compose.yml              # Docker Compose 配置（内网部署版）
├── docker-compose.official.yml     # 官方原始配置（备份）
├── Dockerfile                      # Docker 镜像构建文件
├── docker-entrypoint.sh           # 容器启动脚本
├── .env.example                    # 环境变量配置模板
├── .gitignore.deployment          # Git 忽略文件配置
│
├── 构建和部署脚本 (Linux/macOS)
│   ├── build.sh                    # 镜像构建脚本
│   ├── export-images.sh            # 镜像导出和分卷脚本
│   ├── load-images.sh              # 镜像加载脚本
│   ├── init-env.sh                 # 环境初始化脚本
│   └── deploy.sh                   # 部署管理脚本
│
├── 构建和部署脚本 (Windows)
│   ├── deploy.bat                  # 部署管理脚本 (Windows)
│   └── init-env.bat                # 环境初始化脚本 (Windows)
│
├── 文档
│   ├── README-DEPLOYMENT.md        # 完整部署文档
│   ├── QUICKSTART.md              # 快速开始指南
│   ├── PROJECT-SUMMARY.md         # 项目总结（本文档）
│   ├── README.md                   # 官方原始文档
│   └── README_EN.md               # 官方英文文档
│
├── 源代码
│   ├── src/                        # 应用源代码
│   ├── web/                        # Web 前端源代码
│   ├── config/                     # 配置文件
│   ├── scripts/                    # 辅助脚本
│   └── cli/                        # 命令行工具
│
├── 数据目录 (运行时生成)
│   ├── data/logs/                  # 应用日志
│   ├── data/app/                   # 应用数据
│   └── data/redis/                 # Redis 数据
│
└── 镜像文件 (导出后生成)
    └── images/                     # Docker 镜像分卷文件
        ├── claude-relay-service.tar.gz.part-*
        ├── redis.tar.gz.part-*
        └── checksums.txt           # 文件校验和
```

---

## 核心功能

### 1. 内网部署优化

- **独立镜像**: 将服务打包为自包含的 Docker 镜像
- **无需外网**: 内网环境可直接加载预构建镜像
- **数据持久化**: 所有数据映射到主机目录，便于备份和迁移

### 2. 镜像分卷管理

- **自动分卷**: 将大镜像分割为 < 50MB 的小文件
- **Git 友好**: 适应 Git 文件大小限制
- **完整性校验**: 自动生成和验证 SHA256 校验和

### 3. 一键部署脚本

#### Linux/macOS 脚本

- `build.sh`: 构建 Docker 镜像
- `export-images.sh`: 导出并分卷镜像
- `load-images.sh`: 加载镜像到内网服务器
- `init-env.sh`: 初始化环境配置和生成密钥
- `deploy.sh`: 统一的部署管理入口

#### Windows 脚本

- `deploy.bat`: Windows 部署管理
- `init-env.bat`: Windows 环境初始化

### 4. 配置管理

- 环境变量驱动配置
- 自动密钥生成（JWT、加密密钥、Redis 密码）
- 配置文件模板（.env.example）

---

## 部署方案对比

### 方案 A: 外网构建 + 内网部署（推荐）

**适用场景**: 有一台外网机器可用于构建

**优势**:
- 构建速度快（直接从外网拉取依赖）
- 镜像质量高（使用官方源）
- 适合团队协作（镜像通过 Git 分发）

**流程**:
1. 外网机器：`build.sh` → `export-images.sh` → 提交到 Git
2. 内网机器：克隆仓库 → `load-images.sh` → `init-env.sh` → `deploy.sh`

### 方案 B: 内网直接构建

**适用场景**: 内网有 npm 和 Docker 镜像源

**优势**:
- 流程简单（无需镜像传输）
- 实时构建（可快速调试）

**流程**:
1. 配置内网镜像源
2. 运行 `init-env.sh` → `deploy.sh`

---

## 关键特性

### 安全性

- 自动生成强随机密钥
- 支持 Redis 密码保护
- 环境变量管理敏感信息
- .gitignore 防止密钥泄露

### 易用性

- 一键初始化和部署
- 交互式配置向导
- 彩色终端输出
- 详细的错误提示

### 可维护性

- 完整的日志记录
- 数据目录统一管理
- 支持备份和恢复
- 版本化配置管理

### 兼容性

- 支持 Linux/macOS/Windows
- 兼容 Docker Compose V1 和 V2
- 多种密钥生成方式（openssl、/dev/urandom、bash）

---

## 技术栈

### 容器化

- **Docker**: 应用容器化
- **Docker Compose**: 多容器编排
- **Alpine Linux**: 精简基础镜像

### 应用层

- **Node.js 18**: 运行时环境
- **Redis 7**: 数据存储
- **Vue.js**: Web 前端（admin-spa）

### 脚本

- **Bash**: Linux/macOS 自动化脚本
- **Batch**: Windows 自动化脚本
- **PowerShell**: Windows 密钥生成

---

## 与官方方案对比

| 特性 | 官方一键脚本 | 本项目 |
|------|-------------|--------|
| 部署方式 | 直接安装到主机 | Docker 容器化 |
| 外网依赖 | 运行时需要外网 | 可完全离线部署 |
| 环境隔离 | 依赖主机环境 | 完全隔离 |
| 数据管理 | 分散在多个目录 | 统一数据目录 |
| 备份迁移 | 较复杂 | 简单（复制 data 目录） |
| 多实例 | 不支持 | 支持（修改端口） |
| 镜像分发 | N/A | 支持分卷和 Git |
| Windows 支持 | 有限 | 完整支持 |

---

## 部署清单

### 构建机器（有外网）

- [ ] 安装 Docker 和 Docker Compose
- [ ] 克隆本仓库
- [ ] 运行 `build.sh` 构建镜像
- [ ] 运行 `export-images.sh` 导出镜像
- [ ] 提交 images 目录到 Git

### 内网服务器

- [ ] 安装 Docker 和 Docker Compose
- [ ] 克隆本仓库
- [ ] 运行 `load-images.sh` 加载镜像
- [ ] 运行 `init-env.sh` 初始化环境
- [ ] 运行 `deploy.sh start` 启动服务
- [ ] 访问管理界面并登录
- [ ] 添加 Claude 账户
- [ ] 创建 API Key
- [ ] 配置客户端

---

## 常见问题

### Q1: 镜像文件太大无法上传 Git？

**A**: 使用 `export-images.sh` 自动分卷，每个文件 < 45MB，适合 Git 上传限制。

### Q2: 内网无法构建怎么办？

**A**: 使用方案 A，在外网机器构建后导出镜像，通过 Git 或其他方式传输到内网。

### Q3: 如何升级服务？

**A**:
1. 备份 data 目录
2. 拉取最新代码
3. 重新构建镜像（如需要）
4. 运行 `deploy.sh restart`

### Q4: 忘记管理员密码？

**A**: 查看 `./data/app/init.json` 文件，或删除该文件后重启服务自动重新生成。

### Q5: 如何修改端口？

**A**: 编辑 `.env` 文件，修改 `PORT` 变量，然后运行 `deploy.sh restart`。

### Q6: 数据如何备份？

**A**: 停止服务后，备份整个 `data` 目录：
```bash
./deploy.sh stop
tar -czf backup-$(date +%Y%m%d).tar.gz ./data
./deploy.sh start
```

---

## 脚本功能说明

### build.sh
- 构建 Claude Relay Service 镜像
- 拉取 Redis 官方镜像
- 验证镜像构建结果

### export-images.sh
- 导出 Docker 镜像为 tar.gz
- 自动分卷（45MB/个）
- 生成 SHA256 校验文件

### load-images.sh
- 验证文件完整性
- 合并分卷文件
- 加载镜像到 Docker

### init-env.sh
- 生成安全密钥
- 创建 .env 配置文件
- 初始化数据目录

### deploy.sh
- start: 启动服务
- stop: 停止服务
- restart: 重启服务
- status: 查看状态
- logs: 查看日志
- clean: 清理并重启

---

## 最佳实践

### 1. 安全配置

- 修改默认管理员密码
- 使用强随机密钥（由脚本自动生成）
- 配置防火墙限制访问
- 定期备份数据

### 2. 性能优化

- 使用 SSD 存储 Redis 数据
- 根据负载调整容器资源限制
- 启用日志轮转（已配置）

### 3. 监控和维护

- 定期查看日志：`./deploy.sh logs`
- 监控磁盘使用：`du -sh ./data/*`
- 设置定期备份计划

### 4. 生产部署

- 使用反向代理（Nginx、Caddy）
- 配置 HTTPS 证书
- 设置 `BIND_HOST=127.0.0.1`（仅本地访问）
- 使用独立的 Redis 实例（可选）

---

## 许可和免责

本项目基于 [Claude Relay Service](https://github.com/Wei-Shaw/claude-relay-service) 进行内网部署优化。

**重要提示**:
- 本服务仅供学习和研究使用
- 使用本服务可能违反 Anthropic 的服务条款
- 用户需自行承担使用风险
- 建议使用美国地区的服务器以避免 Cloudflare 封锁

---

## 更新日志

### v1.0.0 (2025-01-12)

- 初始版本
- Docker Compose 配置
- 镜像分卷和导入导出脚本
- Linux/macOS/Windows 部署脚本
- 完整的部署文档

---

## 贡献

欢迎提交 Issue 和 Pull Request 改进本项目。

---

## 联系方式

- 官方项目: https://github.com/Wei-Shaw/claude-relay-service
- 部署问题: 查看 [README-DEPLOYMENT.md](README-DEPLOYMENT.md)

---

**最后更新**: 2025-01-12
