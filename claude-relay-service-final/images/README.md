# Docker 镜像文件

本目录包含 Claude Relay Service 的 Docker 镜像文件,用于离线部署。

## 📦 镜像列表

### 1. claude-relay-service:latest (129MB)

主应用镜像,包含:
- Node.js 18 运行环境
- Claude Relay Service 应用代码
- 前端静态文件 (Vue.js)
- 所有依赖包

**文件分卷** (GitHub 文件大小限制):
- `claude-relay-service.tar.gz.part-aa` - 45MB
- `claude-relay-service.tar.gz.part-ab` - 45MB
- `claude-relay-service.tar.gz.part-ac` - 39MB

### 2. redis:7-alpine (17MB)

Redis 数据库镜像:
- Redis 7.x 版本
- Alpine Linux 基础镜像
- 轻量级构建

**单文件**:
- `redis.tar.gz` - 17MB

## 🔐 文件完整性

所有镜像文件都包含 SHA256 校验和,存储在 `checksums.txt` 中。

**校验命令**:
```bash
cd images
sha256sum -c checksums.txt
```

**预期输出**:
```
claude-relay-service.tar.gz.part-aa: OK
claude-relay-service.tar.gz.part-ab: OK
claude-relay-service.tar.gz.part-ac: OK
redis.tar.gz: OK
```

## 📊 镜像信息

| 镜像 | 大小 | 文件数 | SHA256 (首8位) |
|------|------|--------|----------------|
| claude-relay-service | 129MB | 3个分卷 | 4ebdd8c4 |
| redis | 17MB | 1个文件 | d558b45b |

**总大小**: 146MB

## 🚀 加载镜像

### 自动加载 (推荐)

使用根目录的 `load-images.sh` 脚本:
```bash
cd ..
./load-images.sh
```

脚本会自动:
1. 验证文件完整性
2. 合并分卷文件
3. 解压并加载到 Docker

### 手动加载

```bash
# 1. 合并 claude-relay-service 分卷
cat claude-relay-service.tar.gz.part-* > claude-relay-service.tar.gz

# 2. 加载镜像
gunzip -c claude-relay-service.tar.gz | docker load
gunzip -c redis.tar.gz | docker load

# 3. 验证
docker images | grep -E "claude-relay|redis"
```

## 🔄 更新日期

- **构建时间**: 2025-11-13
- **导出时间**: 2025-11-13 11:54 UTC+8
- **测试状态**: ✅ 已验证
- **测试环境**: Ubuntu 22.04 / Docker 24.x

## ⚠️ 注意事项

1. **文件分卷**: claude-relay-service 镜像因 GitHub 限制被分成3个文件,需要先合并
2. **校验和验证**: 下载后务必验证校验和,确保文件完整性
3. **Docker版本**: 建议使用 Docker 20.10+ 和 docker-compose 1.29+
4. **磁盘空间**: 确保有至少 500MB 的可用空间

## 🐛 故障排查

### 问题1: 校验和失败

**可能原因**: 下载不完整或文件损坏

**解决方案**:
```bash
# 重新下载文件
rm -f claude-relay-service.tar.gz.part-*
git pull origin master

# 重新验证
sha256sum -c checksums.txt
```

### 问题2: 镜像加载失败

**错误示例**: `Error loading image`

**解决方案**:
```bash
# 确保 Docker 正在运行
docker ps

# 手动加载并查看错误
gunzip -c claude-relay-service.tar.gz | docker load
```

### 问题3: 分卷合并失败

**错误示例**: `gzip: invalid compressed data`

**解决方案**:
```bash
# 检查所有分卷文件是否存在
ls -lh claude-relay-service.tar.gz.part-*

# 清理旧文件后重新合并
rm -f claude-relay-service.tar.gz
cat claude-relay-service.tar.gz.part-* > claude-relay-service.tar.gz
```

## 📚 相关文档

- [../README.md](../README.md) - 主文档
- [../OFFLINE-DEPLOYMENT-VERIFIED.md](../OFFLINE-DEPLOYMENT-VERIFIED.md) - 离线部署验证报告
- [../load-images.sh](../load-images.sh) - 自动加载脚本

---

**镜像来源**: https://github.com/Wei-Shaw/claude-relay-service
**本地构建**: Ubuntu 22.04 / Docker 24.x
**验证状态**: ✅ 完整性已验证,部署测试通过
