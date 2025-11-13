# Claude Relay Service v2.1.0 发布说明

发布日期：2025-11-13

## 📋 版本概述

v2.1.0 版本为所有账户类型添加了完整的 OpenAI API 格式支持，包括前端配置界面和后端流式响应转换功能。

## ✨ 新增功能

### 1. 全面的 OpenAI 格式支持

为以下所有账户类型添加了 OpenAI 格式配置选项：

- **CCR 账户** (自定义后端中继)
- **Claude Console 账户**
- **Responses 账户**
- **OpenAI-Responses 账户**

### 2. Web 管理界面增强

#### API 格式选择
- Claude (默认) - 使用 `/v1/messages` 端点
- OpenAI - 使用 `/v1/chat/completions` 端点

#### 响应格式选择
- Claude (默认) - 保持 Claude 原生格式
- OpenAI - 自动转换为 Claude 格式（适用于使用 OpenAI SDK 的场景）

### 3. 后端兼容性改进

- 流式响应自动转换（OpenAI SSE → Claude SSE）
- Token 使用统计兼容性（支持 OpenAI usage 格式）
- 无缝切换，无需修改客户端代码

## 🔧 技术细节

### 修改的文件

#### 前端界面
- `web/admin-spa/src/components/accounts/AccountForm.vue`
  - 添加 API 格式和响应格式下拉选择
  - 完整的表单数据模型集成
  - 创建/更新/加载逻辑完善

- `web/admin-spa/src/components/accounts/CcrAccountForm.vue`
  - CCR 账户专用配置界面

#### 后端服务
- `src/services/ccrRelayService.js`
  - 流式响应格式转换
  - Token 统计解析兼容性

- `src/utils/responseFormatConverter.js`
  - OpenAI 与 Claude 格式互转工具类

#### 文档
- `CCR-OPENAI-FORMAT-GUIDE.md`
  - 完整的配置指南
  - Web 界面使用说明
  - API 调用示例

#### 版本信息
- `package.json` - 版本号更新为 2.1.0
- `Dockerfile` - LABEL version 更新为 2.1.0

## 📦 Docker 镜像

### 镜像信息
- **镜像名称**: `claude-relay-service:2.1.0`
- **镜像别名**: `claude-relay-service:latest`
- **镜像 ID**: `c82adcaa7a10`
- **镜像大小**: 570MB (压缩后 57MB)

### 镜像文件
- **文件名**: `claude-relay-service-v2.1.0.tar.gz`
- **位置**: `images/claude-relay-service-v2.1.0.tar.gz`
- **大小**: 57MB

## 🚀 部署说明

### 在线环境部署

```bash
# 拉取最新镜像
docker pull claude-relay-service:2.1.0

# 或使用 docker-compose
docker-compose pull
docker-compose up -d
```

### 离线环境部署

```bash
# 1. 加载镜像
docker load < images/claude-relay-service-v2.1.0.tar.gz

# 2. 查看镜像
docker images | grep claude-relay-service

# 3. 启动服务
docker-compose up -d
```

### 环境变量

确保以下环境变量已配置：

```bash
JWT_SECRET=your-jwt-secret-key-at-least-32-chars
ENCRYPTION_KEY=your-32-character-encryption-key
REDIS_HOST=claude-relay-redis
REDIS_PORT=6379
NODE_ENV=production
```

## 🔄 升级指南

### 从 v1.0.0 升级到 v2.1.0

1. **备份数据**
   ```bash
   # 备份数据目录
   cp -r /opt/claude-relay-data /opt/claude-relay-data.backup
   ```

2. **停止旧服务**
   ```bash
   docker stop claude-relay-service
   docker rm claude-relay-service
   ```

3. **删除旧镜像（可选）**
   ```bash
   docker rmi claude-relay-service:latest
   ```

4. **加载新镜像**
   ```bash
   docker load < claude-relay-service-v2.1.0.tar.gz
   ```

5. **启动新服务**
   ```bash
   docker run -d --name claude-relay-service \
     --network claude-relay-network \
     -p 3000:3000 \
     -v /opt/claude-relay-data:/app/data \
     -e JWT_SECRET='your-jwt-secret' \
     -e ENCRYPTION_KEY='your-encryption-key' \
     -e REDIS_HOST='claude-relay-redis' \
     -e REDIS_PORT=6379 \
     -e NODE_ENV=production \
     --restart unless-stopped \
     claude-relay-service:2.1.0
   ```

6. **验证服务**
   ```bash
   # 检查健康状态
   curl http://localhost:3000/health

   # 查看日志
   docker logs -f claude-relay-service
   ```

## 📝 配置示例

### 创建 CCR 账户（OpenAI 格式）

通过 Web 界面：

1. 访问 `http://your-server:3000/admin-next`
2. 登录管理员账户
3. 导航到 "账户管理"
4. 点击 "新建 CCR 账户"
5. 填写基本信息
6. 在 "API 格式" 下拉框选择 "OpenAI - /v1/chat/completions"
7. 在 "响应格式" 下拉框选择 "OpenAI - 自动转换为 Claude 格式"
8. 保存

### 更新现有账户

1. 进入账户列表
2. 点击账户的 "编辑" 按钮
3. 修改 "API 格式" 和 "响应格式" 配置
4. 保存更改

## 🐛 已知问题

无

## 🔮 未来计划

- [ ] 支持更多 OpenAI 专有特性
- [ ] 添加格式转换性能监控
- [ ] 支持自定义格式转换规则

## 📄 更新日志

### v2.1.0 (2025-11-13)

#### Added
- 为所有账户类型添加 OpenAI 格式配置支持
- Web 管理界面增加 API 格式和响应格式选择
- 后端流式响应自动转换功能
- Token 使用统计兼容性支持
- 完整的 OpenAI 格式配置文档

#### Changed
- 更新 `package.json` 版本为 2.1.0
- 更新 `Dockerfile` 版本标签为 2.1.0
- 优化 `AccountForm.vue` 和 `CcrAccountForm.vue` 表单逻辑

#### Fixed
- 无

## 📞 支持

如遇到问题，请：

1. 查看文档：`CCR-OPENAI-FORMAT-GUIDE.md`
2. 查看日志：`docker logs claude-relay-service`
3. 提交 Issue

## 🙏 致谢

感谢所有贡献者和用户的支持！

---

**🤖 Generated with [Claude Code](https://claude.com/claude-code)**

**Co-Authored-By: Claude <noreply@anthropic.com>**
