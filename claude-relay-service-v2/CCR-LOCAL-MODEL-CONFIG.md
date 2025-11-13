# CCR 账户配置本地模型服务器详细指南

> **更新日期**: 2025-11-13
> **适用场景**: 本地部署的开源模型通过 CCR 账户代理为 Claude API
> **配置方式**: Web 界面配置

---

## 📋 目录

- [问题背景](#问题背景)
- [CCR 账户工作原理](#ccr-账户工作原理)
- [配置步骤](#配置步骤)
- [模型映射配置](#模型映射配置)
- [完整配置示例](#完整配置示例)
- [验证测试](#验证测试)
- [常见问题](#常见问题)
- [API 路径说明](#api-路径说明)

---

## 问题背景

### 用户环境

- **本地模型服务器**: `https://域名/test/api`
- **API 格式**: OpenAI 兼容（无 `/v1/models` 端点）
- **返回格式**: 同 OpenAI API
- **认证方式**: API Key

### 遇到的问题

1. ❌ 在 Web 界面只配置了 `apiUrl` 和 `apiKey`
2. ❌ 没有配置 `supportedModels` 字段
3. ❌ 客户端请求 `claude-sonnet-4-5-20250929` 时报错"找不到模型"

### 问题原因

CCR 账户的 `supportedModels` 字段为 **必填项**（用于模型映射），如果不配置：
- 系统无法识别客户端请求的模型名
- 无法将 Claude 模型名映射到本地模型名

---

## CCR 账户工作原理

### 请求流程

```
客户端 (Claude Code/Codex)
    ↓
请求: claude-sonnet-4-5-20250929
    ↓
Claude Relay Service (CCR 账户)
    ↓
映射: claude-sonnet-4-5-20250929 → qwen3-235b
    ↓
本地模型服务器: https://域名/test/api/v1/messages
    ↓
请求体: {"model": "qwen3-235b", ...}
    ↓
返回: OpenAI 格式响应
    ↓
透传给客户端
```

### 模型映射逻辑

**代码位置**: [src/services/ccrAccountService.js:534-605](claude-relay-service-v2/src/services/ccrAccountService.js#L534-L605)

```javascript
// supportedModels 支持两种格式：

// 1. 空对象 {} - 支持所有模型，不做映射
supportedModels: {}

// 2. 映射表 - 客户端模型名 → 后端实际模型名
supportedModels: {
  "claude-sonnet-4-5-20250929": "qwen3-235b",
  "claude-opus-4-1-20250805": "qwen3-vl-235b",
  "gpt-4o": "qwen3-32b"
}
```

### 关键代码逻辑

**[ccrRelayService.js:40-55](claude-relay-service-v2/src/services/ccrRelayService.js#L40-L55)**:
```javascript
// 1. 解析客户端请求的模型名
const { baseModel } = parseVendorPrefixedModel(requestBody.model)
// baseModel = "claude-sonnet-4-5-20250929"

// 2. 查找映射表
let mappedModel = baseModel
if (account.supportedModels && typeof account.supportedModels === 'object') {
  const newModel = ccrAccountService.getMappedModel(account.supportedModels, baseModel)
  if (newModel !== baseModel) {
    logger.info(`🔄 Mapping model from ${baseModel} to ${newModel}`)
    mappedModel = newModel // mappedModel = "qwen3-235b"
  }
}

// 3. 发送给本地服务器
modifiedRequestBody = {
  ...requestBody,
  model: mappedModel // 使用映射后的模型名
}
```

---

## 配置步骤

### 1. 准备信息

| 信息项 | 您的值 | 说明 |
|-------|--------|------|
| **API Base URL** | `https://域名/test/api` | 本地模型服务器地址 |
| **API Key** | `您的密钥` | 模型服务器认证密钥 |
| **本地模型名称** | 如 `qwen3-235b` | 您的模型服务器识别的模型 ID |
| **客户端使用的模型名** | `claude-sonnet-4-5-20250929` | Claude Code/Codex 使用的模型名 |

### 2. 测试本地服务器

```bash
# 测试 API 是否可访问（假设有 messages 端点）
curl -X POST https://域名/test/api/v1/messages \
  -H "Authorization: Bearer 您的密钥" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-235b",
    "messages": [{"role": "user", "content": "测试"}],
    "max_tokens": 100
  }'

# 预期输出: OpenAI 格式的 JSON 响应
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1731456789,
  "model": "qwen3-235b",
  "choices": [...],
  "usage": {...}
}
```

### 3. 登录 Web 管理界面

```
URL: http://your-relay-server:3000
账号: admin
密码: 您设置的管理员密码
```

### 4. 添加 CCR 账户

**导航**: 左侧菜单 → **账户管理** → **CCR 账户** → 点击 **"添加账户"**

---

## 模型映射配置

### 方式 1: 支持所有模型（不推荐）

如果您的本地模型服务器能识别 Claude 模型名（如 `claude-sonnet-4-5-20250929`），可以使用空对象：

```json
{}
```

**缺点**:
- 客户端请求什么模型名，就原样发送到您的服务器
- 如果您的服务器不认识 Claude 模型名，会报错

### 方式 2: 精确映射（推荐）

为每个客户端模型名配置映射：

```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b-a22b",
  "claude-opus-4-1-20250805": "qwen3-vl-235b-a22b-instruct-fp8",
  "claude-3-5-sonnet-20241022": "qwen3-32b",
  "gpt-4o": "qwen3-235b-a22b",
  "gpt-4-turbo": "qwen3-coder-480b-a35b"
}
```

**说明**:
- **键（左侧）**: 客户端请求的模型名（Claude Code/Codex 使用的）
- **值（右侧）**: 您的本地模型服务器识别的实际模型 ID

### 方式 3: 多对一映射

多个客户端模型名映射到同一个本地模型：

```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b",
  "claude-opus-4-1-20250805": "qwen3-235b",
  "claude-3-5-sonnet-20241022": "qwen3-235b",
  "gpt-4o": "qwen3-235b",
  "gpt-4-turbo": "qwen3-235b"
}
```

**用途**: 您只有一个本地模型，但希望支持多种客户端模型名请求。

---

## 完整配置示例

### 示例 1: 单模型映射

**场景**: 本地部署 Qwen3-VL-235B，映射为 Claude Sonnet 4.5

**Web 表单填写**:

| 字段 | 值 |
|-----|-----|
| **账户名称** | `本地 Qwen3-VL-235B` |
| **描述** | `本地部署的 Qwen3-VL-235B FP8 量化模型` |
| **API URL** | `https://域名/test/api` |
| **API Key** | `sk-your-local-api-key` |
| **Supported Models** | 见下方 JSON |
| **User Agent** | `claude-relay-service/1.0.0` |
| **优先级** | `100` |
| **是否启用** | ✅ 是 |
| **代理设置** | （留空，除非需要） |

**Supported Models (JSON)**:
```json
{
  "claude-sonnet-4-5-20250929": "qwen3-vl-235b-a22b-instruct-fp8"
}
```

### 示例 2: 多模型映射

**场景**: 本地部署多个模型，分别映射到不同的 Claude/GPT 模型名

**Supported Models (JSON)**:
```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b-a22b",
  "claude-opus-4-1-20250805": "qwen3-vl-235b-a22b-instruct-fp8",
  "claude-3-5-sonnet-20241022": "qwen3-32b",
  "claude-3-haiku-20240307": "glm-4.6-fp8",
  "gpt-4o": "qwen3-235b-a22b",
  "gpt-4-turbo": "qwen3-coder-480b-a35b"
}
```

### 示例 3: 通用映射（一个模型服务多个客户端）

**场景**: 只有一个 Qwen3-235B 模型，但希望响应所有常见的模型名请求

**Supported Models (JSON)**:
```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b",
  "claude-opus-4-1-20250805": "qwen3-235b",
  "claude-sonnet-4-20250514": "qwen3-235b",
  "claude-3-5-sonnet-20241022": "qwen3-235b",
  "claude-3-5-haiku-20241022": "qwen3-235b",
  "claude-3-opus-20240229": "qwen3-235b",
  "gpt-4o": "qwen3-235b",
  "gpt-4-turbo": "qwen3-235b",
  "gpt-4": "qwen3-235b"
}
```

---

## 验证测试

### 1. 通过 Web 界面测试连接

```
账户管理 → CCR 账户 → 找到您的账户 → 点击 "测试连接" 按钮
```

预期结果: ✅ **连接成功**

如果失败，检查：
- API URL 是否正确
- API Key 是否有效
- 网络是否可达
- 防火墙是否开放

### 2. 通过 Relay Service API 测试

**测试 Claude 模型请求**:
```bash
curl -X POST http://your-relay-server:3000/v1/messages \
  -H "x-api-key: your-relay-api-key" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "messages": [
      {"role": "user", "content": "你好，测试连接"}
    ],
    "max_tokens": 100
  }'
```

**预期流程**:
1. Relay Service 收到请求，模型名: `claude-sonnet-4-5-20250929`
2. CCR 账户映射: `claude-sonnet-4-5-20250929` → `qwen3-235b`
3. 转发到本地服务器: `https://域名/test/api/v1/messages` + `{"model": "qwen3-235b", ...}`
4. 本地服务器返回 OpenAI 格式响应
5. Relay Service 透传给客户端

### 3. 查看日志验证

```bash
cd claude-relay-service-v2
./deploy.sh logs | tail -50
```

**关键日志**:
```
[INFO] 📤 Processing CCR API request for key: xxx, account: 本地 Qwen3-VL-235B
[DEBUG] 🌐 Account API URL: https://域名/test/api
[DEBUG] 🔍 Account supportedModels: {"claude-sonnet-4-5-20250929":"qwen3-235b"}
[DEBUG] 📝 Request model: claude-sonnet-4-5-20250929
[DEBUG] 🔄 Parsed base model: claude-sonnet-4-5-20250929
[INFO] 🔄 Mapping model from claude-sonnet-4-5-20250929 to qwen3-235b
[DEBUG] 🎯 Final API endpoint: https://域名/test/api/v1/messages
[INFO] 📤 Sending request to CCR API...
[DEBUG] 🔗 CCR API response: 200
```

### 4. 客户端测试

**Claude Code CLI**:
```bash
export ANTHROPIC_API_KEY="your-relay-api-key"
export ANTHROPIC_BASE_URL="http://your-relay-server:3000"

claude-cli --model claude-sonnet-4-5-20250929 "测试本地模型连接"
```

---

## 常见问题

### Q1: 报错 "Model not supported" 或 "找不到模型 sonnet"

**原因**: `supportedModels` 未配置或配置错误

**解决方案**:
1. 检查 CCR 账户的 `supportedModels` 字段
2. 确保包含客户端请求的模型名作为键
3. 值为本地服务器识别的模型 ID

**正确配置示例**:
```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b"
}
```

### Q2: 报错 "API URL invalid" 或连接超时

**原因**: API URL 配置错误或网络不通

**解决方案**:
1. 确认 API URL 格式正确: `https://域名/test/api`（不要加 `/v1/messages`）
2. 测试网络连通性: `curl https://域名/test/api/v1/messages`
3. 检查防火墙和证书（HTTPS）

### Q3: 本地服务器收到的模型名不对

**现象**: 日志显示映射成功，但本地服务器报错"模型不存在"

**原因**: `supportedModels` 映射的值与本地服务器实际模型 ID 不匹配

**解决方案**:
1. 检查本地服务器的模型 ID（可能需要查看服务器日志或配置）
2. 更新 `supportedModels` 映射表中的值

**示例**:
```json
// 错误: 本地模型 ID 是 "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8"
{
  "claude-sonnet-4-5-20250929": "qwen3-vl"  // ❌ 不匹配
}

// 正确
{
  "claude-sonnet-4-5-20250929": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8"  // ✅ 完整 ID
}
```

### Q4: API Key 保存失败

**原因**: 加密密钥未配置

**解决方案**:
```bash
cd claude-relay-service-v2

# 检查环境变量
cat .env | grep ENCRYPTION_KEY

# 如果没有，生成并添加
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env

# 重启服务
./deploy.sh restart
```

### Q5: 返回格式不兼容

**现象**: Relay Service 能收到响应，但客户端报错

**原因**: 本地服务器返回的格式不是标准 OpenAI/Claude 格式

**解决方案**:
1. 确认本地服务器使用 OpenAI 兼容 API（vLLM、FastChat、TGI 等）
2. 检查返回 JSON 是否包含必需字段: `id`, `object`, `model`, `choices`, `usage`
3. 查看 Relay Service 日志中的响应内容

### Q6: 没有模型列表接口怎么办？

**问题**: 本地服务器没有 `/v1/models` 端点

**答案**: **不需要！** CCR 账户不依赖模型列表接口。

**原理**:
- CCR 账户通过 `supportedModels` 映射表静态配置模型
- 不会调用 `/v1/models` 端点
- 直接使用映射后的模型名请求 `/v1/messages` 或 `/v1/chat/completions`

---

## API 路径说明

### CCR 账户如何构建完整 API 路径

**代码位置**: [ccrRelayService.js:85-96](claude-relay-service-v2/src/services/ccrRelayService.js#L85-L96)

```javascript
// 您配置的 API URL
const apiUrl = "https://域名/test/api"

// 系统处理逻辑
const cleanUrl = apiUrl.replace(/\/$/, '') // 移除末尾斜杠
// cleanUrl = "https://域名/test/api"

// 自动拼接 /v1/messages
const apiEndpoint = cleanUrl.endsWith('/v1/messages')
  ? cleanUrl
  : `${cleanUrl}/v1/messages`

// 最终请求地址
// apiEndpoint = "https://域名/test/api/v1/messages"
```

### 配置规则

| 您的配置 | 最终请求地址 | 是否正确 |
|---------|-------------|---------|
| `https://域名/test/api` | `https://域名/test/api/v1/messages` | ✅ 推荐 |
| `https://域名/test/api/` | `https://域名/test/api/v1/messages` | ✅ 自动处理 |
| `https://域名/test/api/v1` | `https://域名/test/api/v1/v1/messages` | ❌ 错误 |
| `https://域名/test/api/v1/messages` | `https://域名/test/api/v1/messages` | ✅ 直接使用 |

**建议**: 配置为 `https://域名/test/api`，让系统自动拼接 `/v1/messages`

### 如果您的 API 路径不同

**场景 1**: 您的 API 是 `/v2/messages`

修改代码 [ccrRelayService.js:95](claude-relay-service-v2/src/services/ccrRelayService.js#L95):
```javascript
// 原代码
apiEndpoint = cleanUrl.endsWith('/v1/messages') ? cleanUrl : `${cleanUrl}/v1/messages`

// 修改为
apiEndpoint = cleanUrl.endsWith('/v2/messages') ? cleanUrl : `${cleanUrl}/v2/messages`
```

**场景 2**: 您的 API 是 `/chat/completions`（OpenAI 格式）

修改代码 [ccrRelayService.js:95](claude-relay-service-v2/src/services/ccrRelayService.js#L95):
```javascript
apiEndpoint = cleanUrl.endsWith('/chat/completions') ? cleanUrl : `${cleanUrl}/v1/chat/completions`
```

---

## 总结

### 配置清单

- [ ] **API URL**: `https://域名/test/api`（不包含 `/v1/messages`）
- [ ] **API Key**: 您的本地服务器密钥
- [ ] **Supported Models**: 配置映射表（JSON 对象）
  ```json
  {
    "claude-sonnet-4-5-20250929": "本地模型ID"
  }
  ```
- [ ] **优先级**: 50-100（数值越大优先级越高）
- [ ] **启用账户**: ✅ 是

### 关键要点

1. ✅ **必须配置 `supportedModels`**: 空对象或映射表
2. ✅ **映射表格式**: `{"客户端模型名": "本地模型ID"}`
3. ✅ **API URL 不包含端点**: 系统自动拼接 `/v1/messages`
4. ✅ **无需模型列表接口**: CCR 使用静态映射
5. ✅ **本地服务器返回 OpenAI 格式**: 标准 JSON 响应

### 调试技巧

1. **查看日志**: `./deploy.sh logs | grep -E "CCR|映射|Mapping"`
2. **测试连接**: Web 界面 → 账户管理 → 测试连接
3. **手动测试**: 用 `curl` 直接请求本地服务器和 Relay Service
4. **检查映射**: 确认日志中显示"Mapping model from X to Y"

---

**版本**: v1.0.0
**更新时间**: 2025-11-13
**维护者**: Claude Relay Service Team

如有疑问，请参考 [CODEX-CLAUDECODE-SETUP.md](CODEX-CLAUDECODE-SETUP.md) 或查看源代码：
- [ccrAccountService.js](src/services/ccrAccountService.js)
- [ccrRelayService.js](src/services/ccrRelayService.js)
