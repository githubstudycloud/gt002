# 自定义开源模型接入指南

本指南说明如何将自部署的开源大模型配置到Claude Relay Service中作为代理服务端。

## 🎯 适用场景

您已经部署了以下开源模型并希望通过Claude Relay Service统一管理:
- Qwen3-VL-235B-A22B-Instruct-FP8
- Qwen3-32B
- Qwen3-235B-A22B
- GLM-4.6-FP8
- Qwen3-Coder-480B-A35B

## 📋 前提条件

### 1. 模型服务端要求

您的开源模型需要通过以下方式之一提供OpenAI兼容的API接口:

**推荐方案:**
- **vLLM** - 高性能推理引擎,原生支持OpenAI API格式
- **FastChat** - 支持多种模型的API服务器
- **Text-Generation-Inference** (TGI) - Hugging Face的推理服务器
- **Ollama** - 本地模型运行工具

### 2. API端点格式

确保您的模型服务提供以下OpenAI兼容端点:
```
POST http://your-server:port/v1/chat/completions
```

## 🚀 方法一: 使用Azure OpenAI账户类型(推荐)

Claude Relay Service的Azure OpenAI账户类型支持自定义endpoint,可以用来接入任何OpenAI兼容的API。

### 步骤 1: 准备模型API端点

假设您使用vLLM部署了Qwen3-32B模型:

```bash
# 启动vLLM服务 (示例)
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen3-32B \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name qwen3-32b
```

API端点: `http://your-server-ip:8000`

### 步骤 2: 修改Azure endpoint格式验证

由于Claude Relay Service默认验证Azure endpoint格式为 `https://*.openai.azure.com`,我们需要修改验证逻辑以支持自定义域名。

**修改文件:** `src/routes/admin.js` (第8010-8017行)

**原代码:**
```javascript
// 验证 Azure endpoint 格式
if (!azureEndpoint.match(/^https:\/\/[\w-]+\.openai\.azure\.com$/)) {
  return res.status(400).json({
    success: false,
    message:
      'Invalid Azure OpenAI endpoint format. Expected: https://your-resource.openai.azure.com'
  })
}
```

**修改为:**
```javascript
// 验证 Azure endpoint 格式 - 支持自定义域名
if (!azureEndpoint.match(/^https?:\/\/.+/) && !azureEndpoint.match(/^http:\/\/[\d.]+:\d+$/)) {
  return res.status(400).json({
    success: false,
    message:
      'Invalid endpoint format. Expected: http://ip:port or https://domain'
  })
}
```

### 步骤 3: 通过Web界面添加账户

1. 访问Claude Relay Service管理界面: `http://localhost:3000/admin-next`

2. 登录后,进入 **账户管理** > **Azure OpenAI 账户**

3. 点击 **添加账户**,填写以下信息:

```json
{
  "name": "Qwen3-32B",
  "description": "自部署的Qwen3-32B模型",
  "accountType": "shared",
  "azureEndpoint": "http://192.168.1.100:8000",
  "apiVersion": "2024-02-01",
  "deploymentName": "qwen3-32b",
  "apiKey": "sk-dummy-key-not-required",
  "supportedModels": ["qwen3-32b", "claude-3-opus-20240229"],
  "priority": 50,
  "isActive": true,
  "schedulable": true
}
```

**字段说明:**
- `azureEndpoint`: 您的模型服务地址
- `deploymentName`: vLLM的 `--served-model-name` 参数值
- `apiKey`: 如果您的服务不需要认证,填写任意值
- `supportedModels`: 映射到Claude模型名称,客户端请求时使用

### 步骤 4: 测试连接

添加账户后,系统会自动测试连接。您也可以手动测试:

```bash
curl -X POST http://localhost:3000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-relay-api-key" \
  -d '{
    "model": "claude-3-opus-20240229",
    "messages": [
      {"role": "user", "content": "你好"}
    ],
    "max_tokens": 1024
  }'
```

## 🔧 方法二: 使用OpenAI账户类型

如果您的模型服务完全兼容OpenAI API格式,可以直接使用OpenAI账户类型。

### 步骤 1: 修改OpenAI账户服务

**文件:** `src/services/openaiAccountService.js`

在文件中找到API调用部分,添加自定义base URL支持:

```javascript
// 添加配置选项
const CUSTOM_OPENAI_ENDPOINTS = {
  'qwen3-32b': 'http://192.168.1.100:8000/v1',
  'qwen3-235b': 'http://192.168.1.101:8000/v1',
  'glm-4.6': 'http://192.168.1.102:8000/v1'
}

// 在makeOpenAIRequest函数中使用自定义endpoint
function getOpenAIEndpoint(model) {
  return CUSTOM_OPENAI_ENDPOINTS[model] || 'https://api.openai.com/v1'
}
```

### 步骤 2: 通过Web界面添加OpenAI账户

```json
{
  "name": "Qwen3-235B Local",
  "description": "本地部署的Qwen3-235B",
  "accountType": "shared",
  "apiKey": "sk-custom-key",
  "supportedModels": ["qwen3-235b", "claude-3-opus-20240229"],
  "priority": 60,
  "isActive": true
}
```

## 📝 多模型配置示例

### 配置文件: `custom-models-config.json`

```json
{
  "models": [
    {
      "name": "Qwen3-VL-235B",
      "endpoint": "http://192.168.1.100:8000",
      "deployment": "qwen3-vl-235b",
      "type": "vision",
      "mapping": "claude-3-opus-20240229"
    },
    {
      "name": "Qwen3-32B",
      "endpoint": "http://192.168.1.101:8000",
      "deployment": "qwen3-32b",
      "type": "chat",
      "mapping": "claude-3-sonnet-20240229"
    },
    {
      "name": "GLM-4.6-FP8",
      "endpoint": "http://192.168.1.102:8000",
      "deployment": "glm-4.6-fp8",
      "type": "chat",
      "mapping": "claude-3-haiku-20240307"
    },
    {
      "name": "Qwen3-Coder-480B",
      "endpoint": "http://192.168.1.103:8000",
      "deployment": "qwen3-coder-480b",
      "type": "code",
      "mapping": "claude-3-opus-20240229"
    }
  ]
}
```

### 批量导入脚本

创建脚本 `import-custom-models.sh`:

```bash
#!/bin/bash

RELAY_ADMIN_URL="http://localhost:3000/admin"
ADMIN_TOKEN="your-admin-session-token"

# 读取配置文件
cat custom-models-config.json | jq -c '.models[]' | while read model; do
  NAME=$(echo $model | jq -r '.name')
  ENDPOINT=$(echo $model | jq -r '.endpoint')
  DEPLOYMENT=$(echo $model | jq -r '.deployment')
  MAPPING=$(echo $model | jq -r '.mapping')

  echo "Adding model: $NAME"

  curl -X POST "$RELAY_ADMIN_URL/azure-openai-accounts" \
    -H "Content-Type: application/json" \
    -H "Cookie: admin_session=$ADMIN_TOKEN" \
    -d "{
      \"name\": \"$NAME\",
      \"description\": \"Custom deployed model\",
      \"accountType\": \"shared\",
      \"azureEndpoint\": \"$ENDPOINT\",
      \"apiVersion\": \"2024-02-01\",
      \"deploymentName\": \"$DEPLOYMENT\",
      \"apiKey\": \"sk-custom\",
      \"supportedModels\": [\"$MAPPING\"],
      \"priority\": 50,
      \"isActive\": true,
      \"schedulable\": true
    }"

  echo ""
done
```

## 🔐 安全建议

### 1. 使用认证

为您的模型服务添加API Key认证:

**vLLM示例:**
```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen3-32B \
  --api-key sk-your-secure-key
```

### 2. 使用反向代理

通过Nginx添加HTTPS和访问控制:

```nginx
server {
    listen 443 ssl;
    server_name your-model-server.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location /v1/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        # API Key验证
        if ($http_authorization != "Bearer sk-your-key") {
            return 401;
        }
    }
}
```

### 3. 网络隔离

将模型服务器放在内网,只允许Claude Relay Service访问:

```bash
# iptables规则
iptables -A INPUT -p tcp --dport 8000 -s 192.168.1.10 -j ACCEPT
iptables -A INPUT -p tcp --dport 8000 -j DROP
```

## 📊 监控和日志

### 查看模型使用情况

在Claude Relay Service管理界面:
1. **Dashboard** - 查看总体使用统计
2. **API Keys** - 查看每个客户端的使用量
3. **Accounts** - 查看每个模型的调用次数

### 模型服务器日志

**vLLM日志:**
```bash
# 查看实时日志
tail -f /var/log/vllm/server.log

# 查看错误日志
grep ERROR /var/log/vllm/server.log
```

## 🚨 故障排查

### 问题 1: 连接超时

**检查项:**
- 模型服务是否正常运行: `curl http://server:port/v1/models`
- 防火墙是否开放端口: `telnet server port`
- Claude Relay Service网络连通性

### 问题 2: 模型响应格式错误

**解决方案:**
确保模型服务返回OpenAI兼容的JSON格式:

```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "qwen3-32b",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "回复内容"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

### 问题 3: 模型不被调度

**检查配置:**
- `isActive`: 必须为 `true`
- `schedulable`: 必须为 `true`
- `priority`: 数值越大优先级越高
- 确认模型映射到了正确的Claude模型名称

## 📚 客户端配置

### Claude Code配置

编辑 `~/.config/claude/config.json`:

```json
{
  "api": {
    "baseURL": "http://your-relay-server:3000",
    "apiKey": "cr_your_relay_api_key"
  }
}
```

### 其他客户端

任何支持Claude API的客户端都可以使用:

```python
import anthropic

client = anthropic.Anthropic(
    base_url="http://your-relay-server:3000",
    api_key="cr_your_relay_api_key"
)

response = client.messages.create(
    model="claude-3-opus-20240229",  # 映射到您的Qwen模型
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "你好"}
    ]
)

print(response.content[0].text)
```

## 🎉 完成

现在您可以通过Claude Relay Service统一管理和使用自部署的开源模型了!

**优势:**
- ✅ 统一的API接口
- ✅ 多模型自动调度和负载均衡
- ✅ 使用量统计和监控
- ✅ API Key管理
- ✅ 访问控制和限流

## 📞 需要帮助?

遇到问题请查看:
- [Claude Relay Service文档](README.md)
- [官方GitHub Issues](https://github.com/Wei-Shaw/claude-relay-service/issues)
- [Telegram群组](https://t.me/claude_relay_service)
