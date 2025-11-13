# Codex 和 Claude Code 本地模型映射配置指南

> **更新日期**: 2025-11-13
> **版本**: v1.0.0
> **配置方式**: 网页配置（无需重新构建镜像）

---

## 📋 目录

- [概述](#概述)
- [配置方式说明](#配置方式说明)
- [前置准备](#前置准备)
- [Claude Code 配置](#claude-code-配置)
- [Codex 配置](#codex-配置)
- [Web 界面操作步骤](#web-界面操作步骤)
- [配置示例](#配置示例)
- [验证测试](#验证测试)
- [故障排除](#故障排除)
- [高级配置](#高级配置)

---

## 概述

本文档介绍如何将本地部署的开源大模型（如 Qwen、GLM 等）通过 Claude Relay Service 映射为 Codex 和 Claude Code 客户端可识别的模型名称。

### 支持的客户端

- ✅ **Claude Code CLI**: Anthropic 官方命令行工具
- ✅ **Codex CLI**: OpenAI Codex 命令行工具
- ✅ **Continue**: VSCode/JetBrains AI 代码助手插件
- ✅ **Cursor**: AI 驱动的代码编辑器
- ✅ 其他 OpenAI/Claude 兼容客户端

### 支持的模型服务器

- ✅ **vLLM**: 高性能推理引擎（推荐）
- ✅ **FastChat**: OpenAI 兼容 API 服务器
- ✅ **Text Generation Inference (TGI)**: Hugging Face 推理服务器
- ✅ **Ollama**: 本地模型运行工具
- ✅ **LM Studio**: 桌面版本地模型工具
- ✅ **llama.cpp server**: C++ 推理引擎

---

## 配置方式说明

### 🌐 **网页配置（推荐）**

**特点**:
- ✅ 无需重新构建 Docker 镜像
- ✅ 实时生效，无需重启服务
- ✅ 支持动态添加/删除/修改账户
- ✅ 通过 Web 管理界面操作
- ✅ 配置保存在数据库中

**适用场景**:
- 日常添加新模型账户
- 修改现有模型配置
- 测试不同模型映射
- 多团队协作管理

### 🔨 构建前导入（不推荐）

**特点**:
- ⚠️ 需要重新构建 Docker 镜像
- ⚠️ 需要重启服务才能生效
- ⚠️ 配置固化在镜像中，不够灵活
- ⚠️ 适合完全离线环境

**适用场景**:
- 完全离线部署（无法访问 Web 界面）
- 需要预配置大量账户

**本文档重点**: 我们推荐并详细介绍 **网页配置** 方式。

---

## 前置准备

### 1. 确认模型服务器运行正常

确保您的本地模型服务器（如 vLLM）已启动并可访问：

```bash
# 测试模型服务器是否可访问
curl http://192.168.1.100:8000/v1/models

# 预期输出（vLLM 示例）:
{
  "object": "list",
  "data": [
    {
      "id": "qwen3-vl-235b-a22b-instruct-fp8",
      "object": "model",
      "created": 1731456789,
      "owned_by": "vllm"
    }
  ]
}
```

### 2. 记录模型信息

准备以下信息：

| 信息项 | 说明 | 示例 |
|-------|------|------|
| **模型服务器地址** | 包含完整协议和端口 | `http://192.168.1.100:8000/v1` |
| **模型部署名称** | 服务器中的实际模型 ID | `qwen3-vl-235b-a22b-instruct-fp8` |
| **API Key** | 模型服务器的密钥（可选） | `sk-dummy` 或 `EMPTY` |
| **目标客户端** | Codex 或 Claude Code | 选择一个或两个 |

### 3. 确认 Relay Service 运行正常

```bash
# 检查服务状态
cd claude-relay-service-v2
./deploy.sh status

# 访问 Web 界面
# 浏览器打开: http://your-server-ip:3000
```

---

## Claude Code 配置

### 支持的模型名称

Claude Code 客户端识别以下模型名称：

| 模型 ID | 说明 | 推荐用途 |
|--------|------|---------|
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | **最推荐**，最新最强 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 高质量任务 |
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 平衡性能 |
| `claude-3-5-sonnet-20241022` | Claude 3.5 Sonnet | 广泛使用 |
| `claude-3-5-haiku-20241022` | Claude 3.5 Haiku | 快速响应 |
| `claude-3-opus-20240229` | Claude 3 Opus | 经典版本 |
| `claude-3-sonnet-20240229` | Claude 3 Sonnet | 经典版本 |
| `claude-3-haiku-20240307` | Claude 3 Haiku | 轻量级 |

### 配置步骤（Web 界面）

#### 1. 登录 Web 管理界面

```
URL: http://your-server-ip:3000
默认账号: admin
默认密码: 查看部署时设置的环境变量
```

#### 2. 添加 Azure OpenAI 账户

1. 点击左侧菜单 **"账户管理"** → **"Azure OpenAI 账户"**
2. 点击右上角 **"添加账户"** 按钮
3. 填写表单：

| 字段 | 值 | 说明 |
|-----|-----|------|
| **账户名称** | `Qwen3-VL-235B-Claude` | 自定义，便于识别 |
| **Azure Endpoint** | `http://192.168.1.100:8000/v1` | 模型服务器地址 |
| **Deployment Name** | `qwen3-vl-235b-a22b-instruct-fp8` | 实际模型名 |
| **API Key** | `sk-dummy` | 任意值即可 |
| **Supported Models** | 选择或输入 Claude 模型 | 见下方详细说明 |

#### 3. 配置 Supported Models

**方式 A: 通过下拉多选框**（推荐）

在 "Supported Models" 字段，勾选以下模型：
- ☑️ `claude-sonnet-4-5-20250929`
- ☑️ `claude-opus-4-1-20250805`
- ☑️ `claude-3-5-sonnet-20241022`

**方式 B: 手动输入 JSON**

如果界面只有文本框，输入：
```json
["claude-sonnet-4-5-20250929", "claude-opus-4-1-20250805", "claude-3-5-sonnet-20241022"]
```

#### 4. 保存配置

点击 **"保存"** 按钮，系统会：
- ✅ 自动加密存储 API Key
- ✅ 验证配置格式
- ✅ 立即生效（无需重启）

---

## Codex 配置

### 支持的模型名称

Codex 客户端通常使用 OpenAI GPT 模型名称：

| 模型 ID | 说明 | 推荐用途 |
|--------|------|---------|
| `gpt-4o` | GPT-4 Omni | **最推荐**，多模态任务 |
| `gpt-4o-mini` | GPT-4 Omni Mini | 轻量快速 |
| `gpt-4-turbo` | GPT-4 Turbo | 高速 GPT-4 |
| `gpt-4` | GPT-4 标准版 | 经典 GPT-4 |
| `gpt-3.5-turbo` | GPT-3.5 Turbo | 快速轻量 |
| `gpt-3.5-turbo-16k` | GPT-3.5 Turbo 16K | 长上下文 |

### 配置步骤（Web 界面）

#### 1. 添加 Azure OpenAI 账户

与 Claude Code 配置类似，但选择 GPT 模型：

| 字段 | 值 | 说明 |
|-----|-----|------|
| **账户名称** | `Qwen3-32B-Codex` | 自定义名称 |
| **Azure Endpoint** | `http://192.168.1.101:8000/v1` | 模型服务器地址 |
| **Deployment Name** | `qwen3-32b` | 实际模型名 |
| **API Key** | `sk-codex` | 任意值 |
| **Supported Models** | 选择 GPT 模型 | 见下方 |

#### 2. 配置 Supported Models

**下拉选择**：
- ☑️ `gpt-4o`
- ☑️ `gpt-4-turbo`
- ☑️ `gpt-3.5-turbo`

**或手动输入**：
```json
["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"]
```

---

## Web 界面操作步骤

### 完整操作流程（截图说明）

#### Step 1: 访问管理界面

```
浏览器打开: http://your-server-ip:3000
```

#### Step 2: 导航到账户管理

```
左侧菜单 → 账户管理 → Azure OpenAI 账户
```

#### Step 3: 添加新账户

```
点击右上角 "添加账户" 按钮
```

#### Step 4: 填写表单

**示例：为 Claude Code 配置 Qwen3-VL-235B**

```
账户名称: Qwen3-VL-235B-Claude
Azure Endpoint: http://192.168.1.100:8000/v1
Deployment Name: qwen3-vl-235b-a22b-instruct-fp8
API Key: sk-dummy
Supported Models:
  - claude-sonnet-4-5-20250929
  - claude-opus-4-1-20250805
  - claude-3-5-sonnet-20241022
备注: Qwen3-VL-235B FP8 量化模型，用于 Claude Code
```

#### Step 5: 保存并验证

```
点击 "保存" → 查看账户列表 → 确认状态为 "启用"
```

#### Step 6: 查看账户详情

```
点击账户行的 "详情" 按钮 → 查看配置是否正确
```

---

## 配置示例

### 示例 1: Claude Code 使用 Qwen3-VL-235B

**场景**: 使用本地部署的 Qwen3-VL-235B-A22B-Instruct-FP8 模型作为 Claude Sonnet 4.5

**模型服务器**:
```bash
# vLLM 启动命令
vllm serve Qwen/Qwen3-VL-235B-A22B-Instruct-FP8 \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name qwen3-vl-235b-a22b-instruct-fp8
```

**Web 配置**:
```
账户名称: Qwen3-VL-235B-Claude
Azure Endpoint: http://192.168.1.100:8000/v1
Deployment Name: qwen3-vl-235b-a22b-instruct-fp8
API Key: sk-dummy
Supported Models: ["claude-sonnet-4-5-20250929"]
```

**客户端使用**:
```bash
# Claude Code CLI
claude-cli --model claude-sonnet-4-5-20250929 "分析这段代码"

# 实际转发到:
# POST http://192.168.1.100:8000/v1/chat/completions
# Body: {"model": "qwen3-vl-235b-a22b-instruct-fp8", ...}
```

### 示例 2: Codex 使用 Qwen3-32B

**场景**: 使用 Qwen3-32B 作为 GPT-4o

**模型服务器**:
```bash
# vLLM 启动命令
vllm serve Qwen/Qwen3-32B \
  --host 0.0.0.0 \
  --port 8001 \
  --served-model-name qwen3-32b
```

**Web 配置**:
```
账户名称: Qwen3-32B-Codex
Azure Endpoint: http://192.168.1.101:8001/v1
Deployment Name: qwen3-32b
API Key: sk-codex
Supported Models: ["gpt-4o", "gpt-4-turbo"]
```

**客户端使用**:
```bash
# Codex CLI（假设）
codex-cli --model gpt-4o "Generate a function"

# 或 curl 直接调用
curl -X POST http://your-relay-server:3000/v1/chat/completions \
  -H "Authorization: Bearer your-relay-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### 示例 3: 混合配置（同时支持 Claude Code 和 Codex）

**场景**: 一个账户同时支持 Claude 和 GPT 模型名称

**Web 配置**:
```
账户名称: Multi-Model-Universal
Azure Endpoint: http://192.168.1.150:8000/v1
Deployment Name: qwen3-235b-a22b
API Key: sk-multi
Supported Models: [
  "claude-sonnet-4-5-20250929",
  "claude-3-5-sonnet-20241022",
  "gpt-4o",
  "gpt-4-turbo"
]
```

**用途**:
- Claude Code 请求 `claude-sonnet-4-5-20250929` → 转发到 Qwen3-235B
- Codex 请求 `gpt-4o` → 转发到 Qwen3-235B
- Continue 插件请求 `gpt-4-turbo` → 转发到 Qwen3-235B

### 示例 4: 多模型负载均衡

**场景**: 配置多个相同模型的账户，自动轮询分配请求

**账户 1**:
```
账户名称: Qwen3-235B-Server1
Azure Endpoint: http://192.168.1.100:8000/v1
Deployment Name: qwen3-235b-a22b
Supported Models: ["claude-sonnet-4-5-20250929"]
优先级: 100
```

**账户 2**:
```
账户名称: Qwen3-235B-Server2
Azure Endpoint: http://192.168.1.101:8000/v1
Deployment Name: qwen3-235b-a22b
Supported Models: ["claude-sonnet-4-5-20250929"]
优先级: 100
```

**结果**: Claude Code 请求会在两个服务器间轮询分配，实现负载均衡。

---

## 验证测试

### 1. 通过 Web 界面验证

```
账户管理 → 找到您的账户 → 点击 "测试连接" 按钮
```

预期结果: ✅ 连接成功

### 2. 通过 API 验证

**测试 Claude 模型**:
```bash
curl -X POST http://your-relay-server:3000/v1/messages \
  -H "Authorization: Bearer your-relay-api-key" \
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

**测试 GPT 模型**:
```bash
curl -X POST http://your-relay-server:3000/v1/chat/completions \
  -H "Authorization: Bearer your-relay-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Hello, test connection"}
    ]
  }'
```

### 3. 通过客户端验证

**Claude Code CLI**:
```bash
# 配置 API Key 和 Endpoint
export ANTHROPIC_API_KEY="your-relay-api-key"
export ANTHROPIC_BASE_URL="http://your-relay-server:3000"

# 测试命令
claude-cli --model claude-sonnet-4-5-20250929 "分析这段 Python 代码：print('hello')"
```

**Continue 插件**:
```json
// settings.json
{
  "continue.apiKey": "your-relay-api-key",
  "continue.apiBase": "http://your-relay-server:3000/v1",
  "continue.model": "gpt-4o"
}
```

### 4. 查看日志验证

```bash
# 查看 Relay Service 日志
cd claude-relay-service-v2
./deploy.sh logs

# 搜索模型请求日志
./deploy.sh logs | grep "claude-sonnet-4-5"
./deploy.sh logs | grep "gpt-4o"
```

预期输出示例:
```
[2025-11-13 10:30:45] INFO: Request model: claude-sonnet-4-5-20250929
[2025-11-13 10:30:45] INFO: Mapped to account: Qwen3-VL-235B-Claude
[2025-11-13 10:30:45] INFO: Forwarding to: http://192.168.1.100:8000/v1
[2025-11-13 10:30:45] INFO: Deployment name: qwen3-vl-235b-a22b-instruct-fp8
[2025-11-13 10:30:46] INFO: Response status: 200 OK
```

---

## 故障排除

### 问题 1: 客户端报错 "Model not supported"

**现象**:
```
Error: The model 'claude-sonnet-4-5-20250929' is not supported
```

**原因**:
- 账户的 `Supported Models` 未包含该模型
- 账户被禁用
- API Key 不正确

**解决方案**:
```bash
# 1. 登录 Web 界面
# 2. 检查账户的 "Supported Models" 配置
# 3. 确认账户状态为 "启用"
# 4. 点击 "测试连接" 按钮验证
```

### 问题 2: 连接超时

**现象**:
```
Error: Request timeout after 30000ms
```

**原因**:
- 模型服务器未启动
- 网络不通
- 端口错误

**解决方案**:
```bash
# 1. 测试模型服务器是否可访问
curl http://192.168.1.100:8000/v1/models

# 2. 检查防火墙规则
sudo ufw status

# 3. 检查服务器日志
./deploy.sh logs | tail -50
```

### 问题 3: API Key 保存失败

**现象**: Web 界面提示 "Failed to save API key"

**原因**:
- 数据库连接问题
- 加密密钥未配置

**解决方案**:
```bash
# 1. 检查环境变量
cat .env | grep ENCRYPTION_KEY

# 2. 如果未设置，添加加密密钥
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env

# 3. 重启服务
./deploy.sh restart
```

### 问题 4: Claude Code 验证失败

**现象**: 日志显示 "Claude Code validation failed"

**原因**:
- User-Agent 不匹配
- 缺少必需的头部
- 系统提示词不匹配

**解决方案**:
```bash
# 1. 查看详细日志
./deploy.sh logs | grep "Claude Code validation"

# 2. 确认 Claude Code 版本
claude-cli --version

# 3. 检查配置文件
cat src/validators/clients/claudeCodeValidator.js
```

### 问题 5: 模型响应异常

**现象**: 客户端收到错误响应或乱码

**原因**:
- 模型服务器配置错误
- Deployment Name 不匹配
- 模型服务器内部错误

**解决方案**:
```bash
# 1. 直接测试模型服务器
curl -X POST http://192.168.1.100:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-vl-235b-a22b-instruct-fp8",
    "messages": [{"role": "user", "content": "测试"}]
  }'

# 2. 检查模型服务器日志
# (取决于您使用的服务器类型，如 vLLM、FastChat 等)
```

---

## 高级配置

### 1. 配置代理

如果模型服务器需要通过代理访问：

**Web 界面** → **账户详情** → **高级配置**:
```json
{
  "proxy": "http://proxy-server:8080",
  "timeout": 60000
}
```

### 2. 设置优先级

配置多个账户时，可设置优先级（1-100）：

```
优先级: 100  (最高优先级，优先使用)
优先级: 50   (中等优先级)
优先级: 10   (最低优先级，备用)
```

### 3. 账户限流配置

限制每个账户的并发请求数：

```json
{
  "maxConcurrency": 50,
  "rateLimitPerMinute": 100
}
```

### 4. 自定义请求头

为特定模型服务器添加自定义请求头：

```json
{
  "customHeaders": {
    "X-Custom-Auth": "Bearer custom-token",
    "X-Request-ID": "custom-request-id"
  }
}
```

### 5. 批量导入配置

如果需要添加大量账户，可使用 API 批量导入：

**创建配置文件** `accounts.json`:
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
    "supportedModels": ["gpt-4o", "gpt-4-turbo"]
  }
]
```

**导入命令**:
```bash
# 使用 API 批量导入
for account in $(cat accounts.json | jq -c '.[]'); do
  curl -X POST http://your-relay-server:3000/api/admin/azure-openai/accounts \
    -H "Authorization: Bearer admin-api-key" \
    -H "Content-Type: application/json" \
    -d "$account"
done
```

---

## 相关文档

- [主文档 - README.md](README.md)
- [自定义模型增强说明 - CUSTOM-MODEL-ENHANCEMENT.md](CUSTOM-MODEL-ENHANCEMENT.md)
- [快速开始 - QUICKSTART.md](QUICKSTART.md)
- [离线部署验证 - OFFLINE-DEPLOYMENT-VERIFIED.md](OFFLINE-DEPLOYMENT-VERIFIED.md)
- [部署成功说明 - DEPLOYMENT-SUCCESS.md](DEPLOYMENT-SUCCESS.md)

---

## 总结

### 配置方式对比

| 特性 | 网页配置 | 构建前导入 |
|-----|---------|-----------|
| 实时生效 | ✅ 是 | ❌ 需重启 |
| 操作难度 | ✅ 简单 | ⚠️ 复杂 |
| 灵活性 | ✅ 高 | ❌ 低 |
| 离线支持 | ⚠️ 需访问 Web | ✅ 完全离线 |
| 推荐度 | ⭐⭐⭐⭐⭐ | ⭐⭐ |

### 关键要点

1. ✅ **推荐网页配置**: 实时生效，无需重新构建镜像
2. ✅ **账户类型**: 使用 "Azure OpenAI 账户" 类型
3. ✅ **模型映射**: Claude Code 用 Claude 模型名，Codex 用 GPT 模型名
4. ✅ **一账户多模型**: 可同时支持 Claude 和 GPT 模型名称
5. ✅ **多账户负载**: 配置多个相同模型账户实现负载均衡

### 快速检查清单

- [ ] 模型服务器已启动并可访问
- [ ] Relay Service 运行正常
- [ ] 已登录 Web 管理界面
- [ ] 已添加 Azure OpenAI 账户
- [ ] 已配置 Supported Models
- [ ] 已保存并启用账户
- [ ] 已通过 API 测试验证
- [ ] 客户端配置正确
- [ ] 日志显示转发成功

---

**版本**: v1.0.0
**更新时间**: 2025-11-13
**维护者**: Claude Relay Service Team

如有问题，请参考[故障排除](#故障排除)章节或查看[相关文档](#相关文档)。
