# Docker 镜像目录

## 说明

此目录用于存放 Docker 镜像文件，用于离线部署。

## 构建镜像（有 Docker 环境）

如果您有 Docker 环境，请运行以下命令构建和导出镜像：

```bash
# 在项目根目录运行
./build.sh              # 构建镜像
./export-images.sh      # 导出并分卷镜像
```

## 镜像文件

构建完成后，此目录将包含以下文件：

- `claude-relay-service.tar.gz.part-*` - Claude Relay Service 镜像分卷文件
- `redis.tar.gz.part-*` - Redis 镜像分卷文件（或完整文件）
- `checksums.txt` - SHA256 校验和文件

## 使用镜像

在内网服务器上：

```bash
./load-images.sh        # 自动合并分卷并加载镜像
```

## 注意事项

1. 镜像文件较大（总计约 500MB），已分卷为 45MB 小文件
2. 分卷文件必须全部存在才能正确合并
3. 加载前会自动验证文件完整性
4. 如果此目录为空，说明镜像尚未构建

## 无 Docker 环境？

如果当前环境没有 Docker：

1. 在有 Docker 的机器上运行 `build.sh` 和 `export-images.sh`
2. 将 images 目录的所有文件复制到此处
3. 提交到 Git 或通过其他方式传输到内网服务器

## 文件大小限制

Git 默认单文件限制 50MB，我们的分卷策略（45MB/个）确保可以正常提交。

如果使用 Git LFS，可以不分卷直接提交完整镜像文件。
