# 自定义模型支持增强说明

> **更新日期**: 2025-11-13
> **版本**: v1.1.0
> **镜像 ID**: 新镜像已包含此更新

---

## 📝 更新摘要

本次更新增强了 Azure OpenAI 账户类型对自定义模型的支持，特别是针对 **Claude 模型**和**OpenAI 兼容API**的支持。

### 主要变化

#### 1. 扩展默认支持的模型列表

在 `azureOpenaiAccountService.js` 中，更新了默认的 `supportedModels` 列表：

**修改前**（仅支持 GPT 模型）:
```javascript
supportedModels: JSON.stringify(
  accountData.supportedModels || ['gpt-4', 'gpt-4-turbo', 'gpt-35-turbo', 'gpt-35-turbo-16k']
)
```

**修改后**（同时支持 Claude 和 GPT 模型）:
```javascript
supportedModels: JSON.stringify(
  accountData.supportedModels || [
    // Claude 模型（用于自定义模型映射）
    'claude-sonnet-4-5-20250929',
    'claude-opus-4-1-20250805',
    'claude-sonnet-4-20250514',
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
    'claude-3-opus-20240229',
    'claude-3-sonnet-20240229',
    'claude-3-haiku-20240307',
    // GPT 模型（原有支持）
    'gpt-4',
    'gpt-4-turbo',
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-35-turbo',
    'gpt-35-turbo-16k'
  ]
)
```

#### 2. 更新错误处理的 Fallback 模型

当模型配置解析失败时，使用更合理的默认模型列表：

**修改前**:
```javascript
accountData.supportedModels = ['gpt-4', 'gpt-35-turbo']
```

**修改后**:
```javascript
accountData.supportedModels = [
  'claude-3-5-sonnet-20241022',
  'claude-3-opus-20240229',
  'gpt-4',
  'gpt-35-turbo'
]
```

---

## 🎯 使用场景

### 场景 1: Claude Code 客户端支持

现在可以将自己部署的 Claude 兼容模型（如 Qwen3、GLM-4 等）映射为 Claude 模型名称，供 Claude Code 客户端使用：

```json
{
  "name": "Qwen3-235B-Custom",
  "azureEndpoint": "http://192.168.1.100:8000/v1",
  "deploymentName": "qwen3-235b-a22b",
  "apiKey": "sk-dummy",
  "supportedModels": [
    "claude-sonnet-4-5-20250929",
    "claude-3-5-sonnet-20241022"
  ]
}
```

**客户端请求**:
```bash
# Claude Code 请求 claude-sonnet-4-5-20250929
# 实际代理到 http://192.168.1.100:8000/v1/chat/completions
# 使用 qwen3-235b-a22b 模型
```

### 场景 2: OpenAI 客户端支持

同样支持 OpenAI 兼容的客户端（如 Continue、Cursor 等）：

```json
{
  "name": "Qwen3-32B-OpenAI",
  "azureEndpoint": "http://192.168.1.200:8000/v1",
  "deploymentName": "qwen3-32b",
  "apiKey": "sk-custom",
  "supportedModels": [
    "gpt-4o",
    "gpt-4-turbo"
  ]
}
```

### 场景 3: 混合模型支持

一个账户可以同时支持 Claude 和 GPT 模型名称：

```json
{
  "name": "Multi-Model-Endpoint",
  "azureEndpoint": "http://192.168.1.150:8000/v1",
  "deploymentName": "default-model",
  "apiKey": "sk-multi",
  "supportedModels": [
    "claude-3-5-sonnet-20241022",
    "claude-3-opus-20240229",
    "gpt-4o",
    "gpt-4-turbo",
    "gpt-35-turbo"
  ]
}
```

---

## 🔧 技术细节

### 修改的文件

| 文件路径 | 修改内容 | 影响范围 |
|---------|---------|---------|
| `src/services/azureOpenaiAccountService.js` | 扩展默认 supportedModels 列表<br>更新 fallback 模型列表 | 创建账户时的默认配置<br>配置解析失败时的容错处理 |

### 兼容性

- ✅ **向后兼容**: 现有配置无需修改，继续正常工作
- ✅ **新账户**: 自动获得扩展的模型支持
- ✅ **现有账户**: 可通过更新 `supportedModels` 字段启用新模型

### API 兼容性

此更新支持以下 OpenAI 兼容 API 服务器：

- ✅ vLLM (推荐)
- ✅ FastChat
- ✅ Text Generation Inference (TGI)
- ✅ Ollama
- ✅ LM Studio
- ✅ llama.cpp server
- ✅ 其他 OpenAI 兼容服务

---

## 📋 部署和使用

### 1. 重新构建镜像

已完成镜像构建，新镜像位于：
```
claude-relay-service-final/images/
├── claude-relay-service.tar.gz.part-aa (45MB)
├── claude-relay-service.tar.gz.part-ab (45MB)
├── claude-relay-service.tar.gz.part-ac (39MB)
├── redis.tar.gz (17MB)
└── checksums.txt
```

### 2. 校验文件完整性

```bash
cd claude-relay-service-final/images
sha256sum -c checksums.txt
```

**预期输出**:
```
claude-relay-service.tar.gz.part-aa: OK
claude-relay-service.tar.gz.part-ab: OK
claude-relay-service.tar.gz.part-ac: OK
redis.tar.gz: OK
```

### 3. 加载新镜像

```bash
cd claude-relay-service-final
./load-images.sh
```

### 4. 重启服务

```bash
./deploy.sh restart
```

---

## 🚀 快速配置示例

### 配置自定义 Qwen 模型

```bash
# 使用 add-custom-model.sh 快速添加
./add-custom-model.sh

# 按提示输入:
# Account Name: Qwen3-235B-Local
# Azure Endpoint: http://192.168.1.100:8000/v1
# Deployment Name: qwen3-235b-a22b
# API Key: sk-dummy
# Supported Models: claude-sonnet-4-5-20250929,claude-3-5-sonnet-20241022
```

### 批量配置

创建 `custom-models.json`:

```json
[
  {
    "name": "Qwen3-VL-235B",
    "azureEndpoint": "http://192.168.1.100:8000/v1",
    "deploymentName": "qwen3-vl-235b-a22b-instruct-fp8",
    "apiKey": "sk-qwen3vl",
    "supportedModels": ["claude-sonnet-4-5-20250929", "claude-opus-4-1-20250805"]
  },
  {
    "name": "Qwen3-32B",
    "azureEndpoint": "http://192.168.1.101:8000/v1",
    "deploymentName": "qwen3-32b",
    "apiKey": "sk-qwen32b",
    "supportedModels": ["claude-3-5-sonnet-20241022", "gpt-4o"]
  },
  {
    "name": "GLM-4.6-FP8",
    "azureEndpoint": "http://192.168.1.102:8000/v1",
    "deploymentName": "glm-4.6-fp8",
    "apiKey": "sk-glm4",
    "supportedModels": ["claude-3-opus-20240229", "gpt-4-turbo"]
  }
]
```

批量导入：
```bash
./add-custom-model.sh --batch custom-models.json
```

---

## ✅ 支持的 Claude 模型列表

| 模型 ID | 说明 | 建议用途 |
|--------|------|---------|
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 最新版本，推荐 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 高质量任务 |
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 平衡性能 |
| `claude-3-5-sonnet-20241022` | Claude 3.5 Sonnet | 广泛使用 |
| `claude-3-5-haiku-20241022` | Claude 3.5 Haiku | 快速响应 |
| `claude-3-opus-20240229` | Claude 3 Opus | 经典版本 |
| `claude-3-sonnet-20240229` | Claude 3 Sonnet | 经典版本 |
| `claude-3-haiku-20240307` | Claude 3 Haiku | 轻量级 |

## ✅ 支持的 GPT 模型列表

| 模型 ID | 说明 | 建议用途 |
|--------|------|---------|
| `gpt-4o` | GPT-4 Omni | 多模态任务 |
| `gpt-4o-mini` | GPT-4 Omni Mini | 轻量版 |
| `gpt-4-turbo` | GPT-4 Turbo | 高速 GPT-4 |
| `gpt-4` | GPT-4 标准版 | 经典 GPT-4 |
| `gpt-35-turbo` | GPT-3.5 Turbo | 快速轻量 |
| `gpt-35-turbo-16k` | GPT-3.5 Turbo 16K | 长上下文 |

---

## 🔐 安全建议

1. **API Key 管理**
   - 自定义模型的 API Key 会被加密存储
   - 使用强密钥（`ENCRYPTION_KEY` 环境变量）
   - 定期轮换 API Key

2. **网络隔离**
   - 建议自定义模型服务与 Relay 服务在同一内网
   - 使用防火墙限制访问
   - 考虑使用 VPN 或专用网络

3. **访问控制**
   - 为不同团队创建专用账户
   - 使用 API Key 的账户绑定功能
   - 定期审计使用日志

---

## 📊 性能考虑

### 延迟优化

- **内网部署**: 自定义模型服务与 Relay 服务部署在同一局域网，延迟 < 5ms
- **代理配置**: 如需通过代理访问，在账户配置中添加 `proxy` 字段
- **连接池**: 服务自动管理 HTTP 连接池，无需手动配置

### 并发处理

- **默认配置**: 支持每个账户同时处理 50 个并发请求
- **负载均衡**: 配置多个相同模型的账户，自动轮询分配
- **优先级控制**: 使用 `priority` 字段（1-100）设置账户优先级

---

## 🐛 故障排除

### 问题 1: 模型请求失败

**现象**: 客户端报错 "Model not supported"

**解决方案**:
1. 检查账户的 `supportedModels` 配置是否包含请求的模型
2. 确认自定义模型服务是否正常运行
3. 验证 `azureEndpoint` 是否可访问

```bash
# 测试自定义模型服务
curl http://192.168.1.100:8000/v1/models

# 测试代理连接
curl -X POST http://localhost:3000/v1/chat/completions \
  -H "Authorization: Bearer your-relay-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### 问题 2: 校验和验证失败

**现象**: `sha256sum -c checksums.txt` 报错

**解决方案**:
```bash
# 重新下载镜像文件
rm -rf claude-relay-service-final/images/*
cd claude-relay-service-final/images
scp -r ubuntu@server:/path/to/images/* .

# 验证
sha256sum -c checksums.txt
```

### 问题 3: Claude Code 客户端无法连接

**现象**: Claude Code 报错 "Authentication failed"

**解决方案**:
1. 检查 API Key 配置是否正确
2. 确认账户 `supportedModels` 包含 Claude 模型
3. 查看服务日志 `./deploy.sh logs`

---

## 📚 相关文档

- [主文档 - README.md](README.md)
- [自定义模型完整配置指南 - CUSTOM-MODEL-SETUP.md](CUSTOM-MODEL-SETUP.md)
- [快速开始 - QUICKSTART.md](QUICKSTART.md)
- [离线部署验证 - OFFLINE-DEPLOYMENT-VERIFIED.md](OFFLINE-DEPLOYMENT-VERIFIED.md)
- [部署成功说明 - DEPLOYMENT-SUCCESS.md](DEPLOYMENT-SUCCESS.md)

---

## 🎉 总结

本次更新解决了以下问题：

1. ✅ Azure OpenAI 账户类型现在**默认支持 Claude 模型**
2. ✅ 可以使用自定义模型服务（Qwen、GLM 等）**映射为 Claude 或 GPT 模型名称**
3. ✅ **Claude Code** 和 **OpenAI 兼容客户端**都可以正常使用
4. ✅ 向后兼容，现有配置无需修改
5. ✅ 提供完整的配置工具和文档

现在您可以完全在内网环境中，使用自己部署的开源大模型，通过 Claude Relay Service 统一管理和代理，节省 API 成本！

---

**版本**: v1.1.0
**更新时间**: 2025-11-13
**维护者**: Claude Relay Service Team
