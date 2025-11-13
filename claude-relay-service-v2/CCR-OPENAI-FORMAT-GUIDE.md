# CCR 账户 OpenAI 格式支持配置指南

> **版本**: v2.0.0
> **更新日期**: 2025-11-13
> **新特性**: 支持 OpenAI `/v1/chat/completions` 端点和自动格式转换

---

## 📋 目录

- [功能概述](#功能概述)
- [新增字段说明](#新增字段说明)
- [配置场景](#配置场景)
- [完整配置示例](#完整配置示例)
- [格式转换说明](#格式转换说明)
- [验证测试](#验证测试)
- [故障排除](#故障排除)
- [API 参考](#api-参考)

---

## 功能概述

### ✨ 新增功能

**版本 v2.0.0** 为 CCR 账户添加了 OpenAI 格式支持，主要包括：

1. **灵活的 API 端点选择**
   - 支持 Claude 格式端点: `/v1/messages`
   - 支持 OpenAI 格式端点: `/v1/chat/completions`

2. **自动格式转换**
   - 请求格式转换: Claude Messages API → OpenAI Chat Completions API
   - 响应格式转换: OpenAI Chat Completions API → Claude Messages API

3. **完全向后兼容**
   - 现有 CCR 账户默认使用 Claude 格式，无需修改
   - 新字段为可选，默认值确保兼容性

### 使用场景

✅ **场景 1**: 本地模型服务器使用 OpenAI 兼容 API
✅ **场景 2**: 您的 API 地址是 `https://域名/test/v1/chat/completions`
✅ **场景 3**: 后端返回 OpenAI 格式响应，需要转换为 Claude 格式
✅ **场景 4**: 使用 vLLM、FastChat、TGI 等 OpenAI 兼容服务器

---

## 新增字段说明

### 1. apiFormat (API 格式)

**类型**: `string`
**可选值**: `'claude'` | `'openai'`
**默认值**: `'claude'`

**作用**: 指定后端 API 的格式和端点

| 值 | API 端点 | 请求体格式 | 适用场景 |
|----|---------|-----------|---------|
| `claude` | `/v1/messages` | Claude Messages API | Anthropic Claude API 或兼容服务 |
| `openai` | `/v1/chat/completions` | OpenAI Chat Completions API | vLLM、FastChat、TGI、Ollama 等 |

**示例**:
```json
{
  "apiFormat": "openai"
}
```

### 2. responseFormat (响应格式)

**类型**: `string`
**可选值**: `'claude'` | `'openai'`
**默认值**: `'claude'`

**作用**: 控制响应格式转换

| 值 | 行为 | 适用场景 |
|----|-----|---------|
| `claude` | 不转换，原样返回 | 后端已返回 Claude 格式 |
| `openai` | 自动转换 OpenAI → Claude | 后端返回 OpenAI 格式，需转换 |

**示例**:
```json
{
  "responseFormat": "openai"
}
```

---

## 2. 通过 Web 管理界面配置（推荐）

### 2.1 访问管理界面

1. 在浏览器中打开: `http://your-server:3006/admin-next`
2. 使用管理员账户登录
3. 导航到左侧菜单 → **CCR 账户** 页面

### 2.2 创建 OpenAI 格式 CCR 账户

点击 **"+ 创建账户"** 按钮，填写以下配置：

#### 基础信息

| 字段 | 说明 | 示例值 |
|------|------|--------|
| **账户名称** | 自定义账户名称 | `本地 Qwen3-OpenAI` |
| **描述** | 账户说明（可选） | `Qwen3-235B 通过 OpenAI API 格式` |
| **API URL** | 后端基础地址 | `https://your-domain.com/test` |
| **API Key** | 后端 API 密钥 | `sk-your-local-key` |
| **优先级** | 1-100，数值越大优先级越高 | `100` |

⚠️ **重要**: API URL 填写基础地址即可，**不需要**添加 `/v1/messages` 或 `/v1/chat/completions` 后缀。

#### API 格式配置（v2.0 新增）

| 字段 | 说明 | 选项 |
|------|------|------|
| **API 格式** | 后端 API 端点格式 | ✅ `OpenAI - /v1/chat/completions`<br>□ `Claude (默认) - /v1/messages` |
| **响应格式** | 后端响应格式 | ✅ `OpenAI - 自动转换为 Claude 格式`<br>□ `Claude (默认)` |

**选择说明**:
- 如果您的后端是 vLLM、FastChat、Ollama 等 OpenAI 兼容服务，两个下拉框都选择 `OpenAI`
- 系统会自动将 API URL 拼接为 `https://your-domain.com/test/v1/chat/completions`
- 请求会从 Claude 格式自动转换为 OpenAI 格式
- 响应会从 OpenAI 格式自动转换回 Claude 格式

#### 模型映射配置

在 **"支持的模型"** 区域配置模型映射表（JSON 格式）:

```json
{
  "claude-sonnet-4-5-20250929": "qwen3-235b-a22b",
  "claude-opus-4-1-20250805": "qwen3-vl-235b-a22b-instruct-fp8",
  "gpt-4o": "qwen3-32b"
}
```

**说明**:
- 键 (左侧): Claude Code 请求的模型名
- 值 (右侧): 后端实际的模型名

### 2.3 保存并测试

1. 点击 **"保存"** 按钮
2. 在 CCR 账户列表中找到刚创建的账户
3. 点击 **"测试连接"** 按钮验证配置

✅ **预期结果**: 显示 "连接成功" 消息

---

## 配置场景

### 场景 1: 使用 OpenAI 兼容 API（推荐）

**您的情况**:
- 本地模型服务器地址: `https://域名/test/v1/chat/completions`
- 或基础地址: `https://域名/test`
- 返回格式: OpenAI JSON

**配置方案**:

| 字段 | 值 | 说明 |
|-----|-----|------|
| **API URL** | `https://域名/test` | 基础地址，系统自动拼接 `/v1/chat/completions` |
| **API Format** | `openai` | 使用 OpenAI 端点 |
| **Response Format** | `openai` | 自动转换 OpenAI 响应为 Claude 格式 |
| **Supported Models** | 模型映射表 | 必填，见下方示例 |

**Web 界面配置**:

```
账户名称: 本地 Qwen3-OpenAI
描述: Qwen3-235B 通过 OpenAI API 格式
API URL: https://your-domain.com/test
API Key: sk-your-local-key
API Format: openai  ← 选择 "OpenAI"
Response Format: openai  ← 选择 "OpenAI"
Supported Models:
{
  "claude-sonnet-4-5-20250929": "qwen3-235b-a22b",
  "claude-opus-4-1-20250805": "qwen3-vl-235b-a22b-instruct-fp8",
  "gpt-4o": "qwen3-32b"
}
```

**请求流程**:
```
Claude Code 客户端
  ↓ 请求: claude-sonnet-4-5-20250929
Claude Relay Service
  ↓ 映射模型: qwen3-235b-a22b
  ↓ 转换请求格式: Messages API → Chat Completions API
  ↓ 发送到: https://your-domain.com/test/v1/chat/completions
本地模型服务器
  ↓ 返回: OpenAI JSON 格式
Claude Relay Service
  ↓ 转换响应格式: OpenAI → Claude
  ↓ 返回: Claude Messages API 格式
Claude Code 客户端
```

### 场景 2: Claude 原生 API（向后兼容）

**您的情况**:
- 使用 Anthropic Claude API 或完全兼容的服务
- 端点: `/v1/messages`

**配置方案**:

| 字段 | 值 | 说明 |
|-----|-----|------|
| **API URL** | `https://api.anthropic.com` | Claude API 地址 |
| **API Format** | `claude` 或留空 | 默认值 |
| **Response Format** | `claude` 或留空 | 默认值 |

**说明**: 这是默认行为，现有账户无需修改。

### 场景 3: 混合环境

**您的情况**:
- 有些模型用 OpenAI 格式 API
- 有些模型用 Claude 格式 API

**配置方案**: 创建多个 CCR 账户，分别配置不同格式

**账户 1 - OpenAI 格式模型**:
```json
{
  "name": "Qwen3-OpenAI",
  "apiUrl": "https://openai-server.com/api",
  "apiFormat": "openai",
  "responseFormat": "openai",
  "supportedModels": {
    "claude-sonnet-4-5-20250929": "qwen3-235b",
    "gpt-4o": "qwen3-32b"
  }
}
```

**账户 2 - Claude 格式模型**:
```json
{
  "name": "Claude-Direct",
  "apiUrl": "https://claude-server.com/api",
  "apiFormat": "claude",
  "responseFormat": "claude",
  "supportedModels": {
    "claude-3-5-sonnet-20241022": "claude-3-5-sonnet-20241022"
  }
}
```

---

## 完整配置示例

### 示例 1: vLLM 部署的 Qwen3-VL-235B

**环境**:
- vLLM 服务器: `http://192.168.1.100:8000`
- 模型名称: `Qwen/Qwen3-VL-235B-A22B-Instruct-FP8`
- API 格式: OpenAI 兼容

**Web 界面配置**:

```
═══════════════════════════════════════════════════════
账户名称: vLLM-Qwen3-VL-235B
描述: vLLM 部署的 Qwen3-VL-235B FP8 量化模型
API URL: http://192.168.1.100:8000
API Key: sk-dummy
优先级: 100
═══════════════════════════════════════════════════════
API Format: openai
Response Format: openai
═══════════════════════════════════════════════════════
Supported Models (JSON):
{
  "claude-sonnet-4-5-20250929": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8",
  "claude-opus-4-1-20250805": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8"
}
═══════════════════════════════════════════════════════
User Agent: claude-relay-service/2.0.0
是否启用: ✅ 是
账户类型: shared
═══════════════════════════════════════════════════════
```

**生成的完整 API 端点**:
```
http://192.168.1.100:8000/v1/chat/completions
```

**请求示例** (系统自动转换):

原始请求 (Claude Code 发送):
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ]
}
```

转换后请求 (发送到 vLLM):
```json
{
  "model": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ]
}
```

vLLM 响应 (OpenAI 格式):
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1731456789,
  "model": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! I'm doing well, thank you for asking."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 12,
    "completion_tokens": 10,
    "total_tokens": 22
  }
}
```

转换后响应 (返回给 Claude Code):
```json
{
  "id": "chatcmpl-xxx",
  "type": "message",
  "role": "assistant",
  "model": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8",
  "content": [
    {
      "type": "text",
      "text": "Hello! I'm doing well, thank you for asking."
    }
  ],
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 12,
    "output_tokens": 10
  }
}
```

### 示例 2: FastChat 部署的 GLM-4

**环境**:
- FastChat 服务器: `https://glm.example.com/api`
- 模型名称: `glm-4.6-fp8`

**配置**:

```json
{
  "name": "FastChat-GLM4",
  "description": "FastChat 部署的 GLM-4.6 FP8 模型",
  "apiUrl": "https://glm.example.com/api",
  "apiKey": "sk-glm-key",
  "apiFormat": "openai",
  "responseFormat": "openai",
  "supportedModels": {
    "claude-3-haiku-20240307": "glm-4.6-fp8",
    "gpt-4o-mini": "glm-4.6-fp8"
  },
  "priority": 80,
  "isActive": true
}
```

### 示例 3: TGI (Text Generation Inference)

**环境**:
- TGI 服务器: `http://10.0.1.50:8080`
- 模型: `meta-llama/Llama-2-70b-chat-hf`

**配置**:

```json
{
  "name": "TGI-Llama2-70B",
  "apiUrl": "http://10.0.1.50:8080",
  "apiKey": "EMPTY",
  "apiFormat": "openai",
  "responseFormat": "openai",
  "supportedModels": {
    "claude-3-opus-20240229": "meta-llama/Llama-2-70b-chat-hf"
  }
}
```

---

## 格式转换说明

### 请求格式转换 (Claude → OpenAI)

**当 `apiFormat = 'openai'` 时自动转换**

**转换规则**:

| Claude Messages API | OpenAI Chat Completions API |
|---------------------|---------------------------|
| `model` | `model` (直接映射) |
| `max_tokens` | `max_tokens` |
| `temperature` | `temperature` |
| `top_p` | `top_p` |
| `top_k` | ❌ 忽略 (OpenAI 不支持) |
| `system` (字符串) | `messages[0]` with `role: "system"` |
| `messages` | `messages` (合并系统消息) |
| `stream` | `stream` |

**示例转换**:

Claude 请求:
```json
{
  "model": "claude-sonnet-4-5-20250929",
  "max_tokens": 1024,
  "temperature": 0.7,
  "system": "You are a helpful assistant.",
  "messages": [
    {
      "role": "user",
      "content": "What is the capital of France?"
    }
  ]
}
```

转换为 OpenAI 请求:
```json
{
  "model": "qwen3-235b",
  "max_tokens": 1024,
  "temperature": 0.7,
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "What is the capital of France?"
    }
  ]
}
```

### 响应格式转换 (OpenAI → Claude)

**当 `responseFormat = 'openai'` 时自动转换**

**转换规则**:

| OpenAI Field | Claude Field | 说明 |
|--------------|--------------|------|
| `id` | `id` | 请求 ID |
| `object: "chat.completion"` | `type: "message"` | 对象类型 |
| `model` | `model` | 模型名称 |
| `choices[0].message.role` | `role` | 固定为 "assistant" |
| `choices[0].message.content` | `content[0].text` | 文本内容 |
| `choices[0].finish_reason` | `stop_reason` | 停止原因 (映射) |
| `usage.prompt_tokens` | `usage.input_tokens` | 输入 token 数 |
| `usage.completion_tokens` | `usage.output_tokens` | 输出 token 数 |

**finish_reason 映射**:

| OpenAI | Claude |
|--------|--------|
| `stop` | `end_turn` |
| `length` | `max_tokens` |
| `content_filter` | `end_turn` |
| `tool_calls` | `tool_use` |
| `function_call` | `tool_use` |

---

## 验证测试

### 1. Web 界面测试连接

```
账户管理 → CCR 账户 → 找到您的账户 → 点击 "测试连接"
```

**预期结果**: ✅ **连接成功**

### 2. 查看日志验证格式转换

```bash
cd claude-relay-service-v2
./deploy.sh logs | tail -100
```

**关键日志 (OpenAI 格式)**:
```
[INFO] 📤 Processing CCR API request for account: vLLM-Qwen3-VL-235B
[DEBUG] 🌐 Account API URL: http://192.168.1.100:8000
[DEBUG] 🔍 Account supportedModels: {"claude-sonnet-4-5-20250929":"Qwen/..."}
[DEBUG] 🔧 API Format: openai, Response Format: openai
[DEBUG] 🔄 Converting Claude request to OpenAI format
[DEBUG] 🎯 Final API endpoint: http://192.168.1.100:8000/v1/chat/completions
[INFO] 📤 Sending request to CCR API...
[DEBUG] 🔗 CCR API response: 200
[DEBUG] 🔄 Converting OpenAI response to Claude format
[INFO] ✅ Request completed successfully
```

### 3. API 测试

**测试 OpenAI 格式 CCR 账户**:

```bash
curl -X POST http://your-relay-server:3000/v1/messages \
  -H "x-api-key: your-relay-api-key" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet-4-5-20250929",
    "max_tokens": 100,
    "messages": [
      {"role": "user", "content": "测试 OpenAI 格式转换"}
    ]
  }'
```

**预期**: 收到 Claude 格式的响应 (即使后端是 OpenAI 格式)

### 4. Claude Code CLI 测试

```bash
export ANTHROPIC_API_KEY="your-relay-api-key"
export ANTHROPIC_BASE_URL="http://your-relay-server:3000"

claude-cli --model claude-sonnet-4-5-20250929 "测试本地 OpenAI 格式模型"
```

**预期**: 正常工作，无需感知后端 API 格式

---

## 故障排除

### 问题 1: 404 Not Found 错误

**现象**:
```
❌ CCR API returned error status: 404
```

**原因**: API URL 或端点配置错误

**解决方案**:

1. **检查 API URL**:
   - ✅ 正确: `https://domain.com/test`
   - ❌ 错误: `https://domain.com/test/` (末尾斜杠)
   - ❌ 错误: `https://domain.com/test/v1` (包含版本)

2. **检查 API Format**:
   - 如果您的 API 是 `/v1/chat/completions`，设置 `apiFormat: "openai"`
   - 如果您的 API 是 `/v1/messages`，设置 `apiFormat: "claude"`

3. **验证完整端点**:
   ```bash
   # 测试 OpenAI 格式端点
   curl -X POST https://your-domain.com/test/v1/chat/completions \
     -H "Authorization: Bearer your-key" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "your-model-name",
       "messages": [{"role": "user", "content": "test"}]
     }'
   ```

### 问题 2: 响应格式错误

**现象**:
```
❌ Client error: Invalid response format
```

**原因**: 响应格式配置错误

**解决方案**:

1. **确认后端返回格式**:
   ```bash
   # 直接调用后端 API，查看响应
   curl -X POST http://your-backend/v1/chat/completions \
     -H "Authorization: Bearer key" \
     -H "Content-Type: application/json" \
     -d '{"model":"test","messages":[{"role":"user","content":"hi"}]}'
   ```

2. **检查响应中的 `object` 字段**:
   - 如果是 `"object": "chat.completion"` → 设置 `responseFormat: "openai"`
   - 如果是 `"type": "message"` → 设置 `responseFormat: "claude"`

3. **查看转换日志**:
   ```bash
   ./deploy.sh logs | grep -E "Converting|response"
   ```

### 问题 3: 模型名称不匹配

**现象**:
```
❌ Model 'qwen3-235b' not found
```

**原因**: `supportedModels` 映射表中的值与后端实际模型名不一致

**解决方案**:

1. **查询后端支持的模型** (如果有 models 端点):
   ```bash
   curl http://your-backend/v1/models \
     -H "Authorization: Bearer key"
   ```

2. **更新 supportedModels 映射**:
   ```json
   {
     "claude-sonnet-4-5-20250929": "完整的后端模型名称"
   }
   ```

3. **常见模型名称格式**:
   - vLLM: `Qwen/Qwen3-VL-235B-A22B-Instruct-FP8`
   - FastChat: `glm-4.6-fp8` 或 `chatglm3-6b`
   - TGI: `meta-llama/Llama-2-70b-chat-hf`
   - Ollama: `llama2:70b` 或 `qwen:72b`

### 问题 4: 字段不支持错误

**现象**:
```
⚠️ top_k parameter is not supported in OpenAI format, ignored
```

**说明**: 这是**正常警告**，不影响功能

**原因**: Claude API 的 `top_k` 参数在 OpenAI API 中不存在，系统自动忽略

**行为**: 请求仍然正常发送，只是不包含不兼容的参数

---

## API 参考

### CCR 账户配置对象

```typescript
interface CcrAccount {
  // 基础字段
  name: string                    // 账户名称
  description?: string            // 描述
  apiUrl: string                  // API 基础地址
  apiKey: string                  // API 密钥
  priority?: number               // 优先级 (1-100，默认 50)
  isActive?: boolean              // 是否启用 (默认 true)

  // ✨ 新增字段 (v2.0.0)
  apiFormat?: 'claude' | 'openai' // API 格式 (默认 'claude')
  responseFormat?: 'claude' | 'openai' // 响应格式 (默认 'claude')

  // 模型映射
  supportedModels: Record<string, string> | {} // 模型映射表

  // 可选配置
  userAgent?: string              // User-Agent
  rateLimitDuration?: number      // 限流时间 (分钟)
  proxy?: ProxyConfig             // 代理配置
  accountType?: 'shared' | 'dedicated' // 账户类型
  dailyQuota?: number             // 每日额度 (美元)
  quotaResetTime?: string         // 额度重置时间 (HH:mm)
}
```

### API 端点构建规则

```javascript
// apiFormat = 'claude' (默认)
const endpoint = `${apiUrl}/v1/messages`

// apiFormat = 'openai'
const endpoint = `${apiUrl}/v1/chat/completions`
```

**示例**:

| apiUrl | apiFormat | 最终端点 |
|--------|-----------|---------|
| `https://api.com` | `claude` | `https://api.com/v1/messages` |
| `https://api.com` | `openai` | `https://api.com/v1/chat/completions` |
| `https://api.com/v1/messages` | `claude` | `https://api.com/v1/messages` (原样) |
| `https://api.com/v1/chat/completions` | `openai` | `https://api.com/v1/chat/completions` (原样) |

---

## 总结

### 配置清单

使用 OpenAI 格式 API 时，确保配置：

- [ ] **API URL**: 基础地址 (如 `https://domain.com/test`)
- [ ] **API Key**: 您的密钥
- [ ] **API Format**: 选择 `openai`
- [ ] **Response Format**: 选择 `openai` (如果后端返回 OpenAI 格式)
- [ ] **Supported Models**: 配置完整的模型映射表
  ```json
  {
    "claude-sonnet-4-5-20250929": "Qwen/Qwen3-VL-235B-A22B-Instruct-FP8"
  }
  ```
- [ ] **测试连接**: 通过 Web 界面测试
- [ ] **查看日志**: 确认格式转换正常工作

### 关键要点

1. ✅ **API Format** 控制端点和请求格式
2. ✅ **Response Format** 控制响应转换
3. ✅ **向后兼容**: 现有账户无需修改
4. ✅ **自动拼接**: 系统自动添加 `/v1/messages` 或 `/v1/chat/completions`
5. ✅ **透明转换**: 客户端无感知，始终使用 Claude API

### 调试技巧

1. **查看完整日志**:
   ```bash
   ./deploy.sh logs | grep -E "CCR|Converting|endpoint"
   ```

2. **测试单个请求**:
   ```bash
   curl -v http://relay:3000/v1/messages \
     -H "x-api-key: key" \
     -H "anthropic-version: 2023-06-01" \
     -H "Content-Type: application/json" \
     -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
   ```

3. **直接测试后端**:
   ```bash
   curl http://your-backend/v1/chat/completions \
     -H "Authorization: Bearer key" \
     -d '{"model":"your-model","messages":[{"role":"user","content":"test"}]}'
   ```

---

**版本**: v2.0.0
**更新时间**: 2025-11-13
**维护者**: Claude Relay Service Team

相关文档:
- [CCR 本地模型配置指南](CCR-LOCAL-MODEL-CONFIG.md)
- [Codex 和 Claude Code 配置指南](CODEX-CLAUDECODE-SETUP.md)
- [主文档 README](README.md)
