# AI API Gateway API规范文档

## 一、API概述

AI API Gateway提供RESTful API接口，兼容OpenAI API格式，同时支持多种AI厂商的原生格式。

### 基础信息
- **Base URL**: `http://localhost:8080` (本地部署) 或 `https://your-domain.com`
- **API版本**: v1
- **认证方式**: API Key (Bearer Token)
- **内容类型**: `application/json`
- **字符编码**: UTF-8

### 认证
所有API请求需要在Header中携带API Key:
```
Authorization: Bearer <your-api-key>
```

## 二、核心API端点

### 2.1 Chat Completions (聊天补全)

#### OpenAI格式 (推荐)

**端点**: `POST /v1/chat/completions`

**请求示例**:
```json
{
  "model": "gpt-4",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "Hello, who are you?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1000,
  "stream": false,
  "provider": "openai"
}
```

**请求参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| model | string | 是 | 模型名称 |
| messages | array | 是 | 消息列表 |
| temperature | float | 否 | 温度参数 (0-2) |
| max_tokens | integer | 否 | 最大token数 |
| stream | boolean | 否 | 是否流式响应 |
| provider | string | 否 | 指定provider,不指定则自动选择 |
| top_p | float | 否 | 核采样参数 |
| n | integer | 否 | 生成的响应数量 |
| stop | string/array | 否 | 停止序列 |
| presence_penalty | float | 否 | 存在惩罚 |
| frequency_penalty | float | 否 | 频率惩罚 |

**响应示例**:
```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "gpt-4",
  "provider": "openai",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I am an AI assistant created by OpenAI..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 20,
    "completion_tokens": 50,
    "total_tokens": 70
  },
  "cost": 0.0014
}
```

**流式响应示例** (stream=true):
```
data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"I"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{"content":" am"},"finish_reason":null}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","created":1677652288,"model":"gpt-4","choices":[{"index":0,"delta":{"content":" an"},"finish_reason":null}]}

...

data: [DONE]
```

#### Claude原生格式

**端点**: `POST /v1/providers/claude/messages`

**请求示例**:
```json
{
  "model": "claude-3-opus-20240229",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "Hello, Claude"
    }
  ],
  "system": "You are a helpful assistant."
}
```

#### Gemini原生格式

**端点**: `POST /v1/providers/gemini/generateContent`

**请求示例**:
```json
{
  "model": "gemini-pro",
  "contents": [
    {
      "role": "user",
      "parts": [
        {"text": "Hello, Gemini"}
      ]
    }
  ],
  "generationConfig": {
    "temperature": 0.9,
    "maxOutputTokens": 2048
  }
}
```

### 2.2 Models (模型列表)

**端点**: `GET /v1/models`

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| provider | string | 否 | 过滤特定provider |

**响应示例**:
```json
{
  "object": "list",
  "data": [
    {
      "id": "gpt-4",
      "object": "model",
      "created": 1687882411,
      "owned_by": "openai",
      "provider": "openai",
      "pricing": {
        "prompt": 0.00003,
        "completion": 0.00006
      }
    },
    {
      "id": "claude-3-opus-20240229",
      "object": "model",
      "created": 1709255940,
      "owned_by": "anthropic",
      "provider": "claude",
      "pricing": {
        "prompt": 0.000015,
        "completion": 0.000075
      }
    }
  ]
}
```

**获取单个模型**:
`GET /v1/models/{model_id}`

### 2.3 Embeddings (向量化)

**端点**: `POST /v1/embeddings`

**请求示例**:
```json
{
  "model": "text-embedding-ada-002",
  "input": "The quick brown fox jumps over the lazy dog",
  "provider": "openai"
}
```

**响应示例**:
```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": [0.0023064255, -0.009327292, ...],
      "index": 0
    }
  ],
  "model": "text-embedding-ada-002",
  "usage": {
    "prompt_tokens": 10,
    "total_tokens": 10
  }
}
```

### 2.4 Image Generation (图像生成)

**端点**: `POST /v1/images/generations`

**请求示例**:
```json
{
  "prompt": "A cute baby sea otter",
  "model": "dall-e-3",
  "n": 1,
  "size": "1024x1024",
  "quality": "standard",
  "provider": "openai"
}
```

## 三、管理API

### 3.1 Provider Accounts (Provider账户管理)

#### 创建Provider账户
**端点**: `POST /v1/admin/provider-accounts`

**请求示例**:
```json
{
  "provider": "openai",
  "account_name": "My OpenAI Account",
  "api_key": "sk-...",
  "config": {
    "organization_id": "org-..."
  }
}
```

#### 列出Provider账户
**端点**: `GET /v1/admin/provider-accounts`

**响应示例**:
```json
{
  "accounts": [
    {
      "id": 1,
      "provider": "openai",
      "account_name": "My OpenAI Account",
      "created_at": "2025-11-14T10:00:00Z",
      "is_active": true,
      "status": "healthy"
    }
  ]
}
```

#### 更新Provider账户
**端点**: `PUT /v1/admin/provider-accounts/{account_id}`

#### 删除Provider账户
**端点**: `DELETE /v1/admin/provider-accounts/{account_id}`

#### 测试Provider账户
**端点**: `POST /v1/admin/provider-accounts/{account_id}/test`

### 3.2 Quota Policies (配额策略)

#### 创建配额策略
**端点**: `POST /v1/admin/quota-policies`

**请求示例**:
```json
{
  "provider": "openai",
  "daily_token_limit": 1000000,
  "monthly_budget": 100.00,
  "rate_limit": {
    "requests_per_minute": 60,
    "tokens_per_minute": 90000
  }
}
```

#### 获取配额策略
**端点**: `GET /v1/admin/quota-policies`

#### 更新配额策略
**端点**: `PUT /v1/admin/quota-policies/{policy_id}`

### 3.3 Model Mappings (模型映射)

#### 创建模型映射
**端点**: `POST /v1/admin/model-mappings`

**请求示例**:
```json
{
  "source_model": "gpt-4",
  "target_provider": "claude",
  "target_model": "claude-3-opus-20240229",
  "config": {
    "temperature_adjustment": 0.0,
    "max_tokens_multiplier": 1.0
  }
}
```

**说明**: 当请求`gpt-4`且指定或自动选择`claude` provider时,自动映射到`claude-3-opus`

#### 列出模型映射
**端点**: `GET /v1/admin/model-mappings`

### 3.4 Usage Statistics (使用统计)

#### 获取使用统计
**端点**: `GET /v1/admin/usage`

**查询参数**:
| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| start_date | string | 否 | 开始日期 (YYYY-MM-DD) |
| end_date | string | 否 | 结束日期 (YYYY-MM-DD) |
| provider | string | 否 | 过滤provider |
| group_by | string | 否 | 分组方式 (day/hour/provider/model) |

**响应示例**:
```json
{
  "period": {
    "start": "2025-11-01",
    "end": "2025-11-14"
  },
  "summary": {
    "total_requests": 15234,
    "total_tokens": 12345678,
    "total_cost": 234.56,
    "providers": {
      "openai": {
        "requests": 10000,
        "tokens": 8000000,
        "cost": 150.00
      },
      "claude": {
        "requests": 5234,
        "tokens": 4345678,
        "cost": 84.56
      }
    }
  },
  "daily_breakdown": [
    {
      "date": "2025-11-14",
      "requests": 1234,
      "tokens": 987654,
      "cost": 18.76
    }
  ]
}
```

#### 导出使用日志
**端点**: `GET /v1/admin/usage/export`

**格式**: CSV或JSON
**查询参数**: 同上

### 3.5 API Keys (API密钥管理)

#### 创建API Key
**端点**: `POST /v1/admin/api-keys`

**请求示例**:
```json
{
  "name": "Production Key",
  "scopes": ["chat", "embeddings"],
  "rate_limit": {
    "requests_per_minute": 100
  },
  "expires_at": "2026-11-14T00:00:00Z"
}
```

**响应示例**:
```json
{
  "id": 1,
  "name": "Production Key",
  "api_key": "sk-gateway-abc123...",
  "created_at": "2025-11-14T10:00:00Z",
  "expires_at": "2026-11-14T00:00:00Z"
}
```

#### 列出API Keys
**端点**: `GET /v1/admin/api-keys`

#### 撤销API Key
**端点**: `DELETE /v1/admin/api-keys/{key_id}`

## 四、高级特性API

### 4.1 Request Routing (请求路由)

#### 负载均衡路由
在请求中指定多个provider,系统自动负载均衡:

```json
{
  "model": "gpt-4",
  "messages": [...],
  "providers": ["openai", "azure-openai"],
  "routing_strategy": "load_balance"
}
```

**routing_strategy选项**:
- `load_balance`: 负载均衡
- `fallback`: 故障转移
- `least_cost`: 最低成本
- `least_latency`: 最低延迟

#### 智能路由
```json
{
  "model": "gpt-4",
  "messages": [...],
  "routing": {
    "strategy": "smart",
    "preferences": {
      "cost_weight": 0.3,
      "latency_weight": 0.5,
      "reliability_weight": 0.2
    }
  }
}
```

### 4.2 Request Caching (请求缓存)

启用请求缓存以节省成本:

```json
{
  "model": "gpt-4",
  "messages": [...],
  "cache": {
    "enabled": true,
    "ttl": 3600
  }
}
```

### 4.3 Webhooks (事件通知)

#### 注册Webhook
**端点**: `POST /v1/admin/webhooks`

**请求示例**:
```json
{
  "url": "https://your-domain.com/webhook",
  "events": ["quota.warning", "quota.exceeded", "provider.error"],
  "secret": "your-webhook-secret"
}
```

**事件类型**:
- `quota.warning`: 配额预警(达到80%)
- `quota.exceeded`: 配额超限
- `provider.error`: Provider错误
- `high_latency`: 高延迟告警
- `cost.threshold`: 成本阈值

**Webhook Payload示例**:
```json
{
  "event": "quota.warning",
  "timestamp": "2025-11-14T10:00:00Z",
  "data": {
    "provider": "openai",
    "current_usage": 800000,
    "limit": 1000000,
    "percentage": 80
  }
}
```

### 4.4 Batch Requests (批量请求)

**端点**: `POST /v1/batch`

**请求示例**:
```json
{
  "requests": [
    {
      "id": "req-1",
      "endpoint": "/v1/chat/completions",
      "body": {
        "model": "gpt-4",
        "messages": [...]
      }
    },
    {
      "id": "req-2",
      "endpoint": "/v1/embeddings",
      "body": {
        "model": "text-embedding-ada-002",
        "input": "..."
      }
    }
  ]
}
```

**响应示例**:
```json
{
  "responses": [
    {
      "id": "req-1",
      "status": 200,
      "body": {...}
    },
    {
      "id": "req-2",
      "status": 200,
      "body": {...}
    }
  ]
}
```

## 五、健康检查与监控

### 5.1 Health Check
**端点**: `GET /health`

**响应示例**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 86400,
  "providers": {
    "openai": "healthy",
    "claude": "healthy",
    "gemini": "degraded"
  }
}
```

### 5.2 Metrics
**端点**: `GET /metrics`

返回Prometheus格式的metrics

### 5.3 Provider Status
**端点**: `GET /v1/providers/status`

**响应示例**:
```json
{
  "providers": [
    {
      "name": "openai",
      "status": "healthy",
      "latency_p95": 234,
      "error_rate": 0.001,
      "last_check": "2025-11-14T10:00:00Z"
    }
  ]
}
```

## 六、错误处理

### 错误响应格式
```json
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Please retry after 60 seconds.",
    "type": "rate_limit_error",
    "param": null,
    "details": {
      "limit": 60,
      "remaining": 0,
      "reset_at": "2025-11-14T10:01:00Z"
    }
  }
}
```

### 错误码列表

| HTTP状态码 | 错误代码 | 说明 |
|-----------|---------|------|
| 400 | invalid_request | 请求参数无效 |
| 401 | invalid_api_key | API Key无效 |
| 403 | insufficient_quota | 配额不足 |
| 404 | not_found | 资源不存在 |
| 429 | rate_limit_exceeded | 速率限制超限 |
| 500 | internal_error | 内部错误 |
| 502 | provider_error | Provider服务错误 |
| 503 | service_unavailable | 服务不可用 |
| 504 | timeout | 请求超时 |

### Rate Limit Headers
所有响应包含以下headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1699964400
```

## 七、SDK示例

### Python SDK
```python
from ai_gateway import Gateway

client = Gateway(
    api_key="your-api-key",
    base_url="http://localhost:8080"
)

# Chat completion
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Hello!"}
    ],
    provider="openai"  # 可选
)

print(response.choices[0].message.content)

# Stream
for chunk in client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True
):
    print(chunk.choices[0].delta.content, end="")
```

### JavaScript/TypeScript SDK
```typescript
import { Gateway } from '@ai-gateway/sdk';

const client = new Gateway({
  apiKey: 'your-api-key',
  baseURL: 'http://localhost:8080'
});

// Chat completion
const response = await client.chat.completions.create({
  model: 'gpt-4',
  messages: [
    { role: 'user', content: 'Hello!' }
  ],
  provider: 'openai' // optional
});

console.log(response.choices[0].message.content);

// Stream
const stream = await client.chat.completions.create({
  model: 'gpt-4',
  messages: [{ role: 'user', content: 'Tell me a story' }],
  stream: true
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content || '');
}
```

### CLI工具
```bash
# 安装CLI
npm install -g @ai-gateway/cli

# 配置
ai-gateway config set api_key your-api-key
ai-gateway config set base_url http://localhost:8080

# 聊天
ai-gateway chat "Hello, who are you?" --model gpt-4 --provider openai

# 流式聊天
ai-gateway chat "Tell me a story" --stream

# 查看使用统计
ai-gateway usage --last 7d

# 管理Provider账户
ai-gateway providers add openai --api-key sk-...
ai-gateway providers list
```

---

**文档版本**: v1.0
**更新日期**: 2025-11-14
