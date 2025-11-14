# AI API Gateway 架构设计文档

## 一、系统架构概览

### 1.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │CLI Tools │  │  SDKs    │  │ Web Apps │  │  Agents  │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
└───────┼─────────────┼─────────────┼─────────────┼──────────────┘
        │             │             │             │
        └─────────────┴─────────────┴─────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │      API Gateway (Load Balancer)    │
        └──────────────────┬──────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────────────┐
│                    Core Gateway Service                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Request Router & Processor                   │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │
│  │  │  Auth    │  │ Rate     │  │  Format  │  │ Protocol │ │  │
│  │  │Middleware│  │ Limiter  │  │Converter │  │ Adapter  │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Provider Adapter Layer                       │  │
│  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │  │
│  │  │OpenAI│ │Claude│ │Gemini│ │Azure │ │Baidu │ │Custom│ │  │
│  │  │      │ │      │ │      │ │OpenAI│ │Wenxin│ │      │ │  │
│  │  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Support Services                             │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │
│  │  │  Config  │  │ Metrics  │  │  Logger  │  │  Cache   │ │  │
│  │  │ Manager  │  │Collector │  │          │  │          │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────┘
                           │
        ┌──────────────────┴──────────────────┐
        │                                      │
┌───────┴────────┐                  ┌─────────┴────────┐
│   Database     │                  │  External APIs   │
│  ┌──────────┐  │                  │  ┌────────────┐  │
│  │Accounts  │  │                  │  │OpenAI API  │  │
│  │Config    │  │                  │  │Claude API  │  │
│  │Usage     │  │                  │  │Gemini API  │  │
│  │Logs      │  │                  │  │Azure API   │  │
│  └──────────┘  │                  │  │Baidu API   │  │
└────────────────┘                  │  │...         │  │
                                    └────────────────┘
```

### 1.2 核心组件说明

#### 1. API Gateway (Load Balancer)
- 入口流量分发
- TLS/SSL终止
- 基础DDoS防护

#### 2. Request Router & Processor
- 请求路由
- 中间件链式处理
- 响应聚合

#### 3. Provider Adapter Layer
- 厂商API适配
- 格式转换
- 错误处理统一化

#### 4. Support Services
- 配置管理
- 指标收集
- 日志处理
- 缓存服务

## 二、核心模块设计

### 2.1 认证与授权模块

#### 认证方式
```go
type AuthMethod int

const (
    APIKey AuthMethod = iota    // API密钥认证
    BearerToken                 // Bearer Token认证
    OAuth2                      // OAuth2认证
    Custom                      // 自定义认证
)

type AuthConfig struct {
    Method       AuthMethod
    APIKey       string
    BearerToken  string
    OAuth2Config *OAuth2Config
}
```

#### 权限模型
- 基于角色的访问控制(RBAC)
- 细粒度的API权限管理
- 配额和速率限制绑定

### 2.2 格式转换引擎

#### 转换器接口
```go
type Converter interface {
    // 转换请求格式
    ConvertRequest(from Provider, to Provider, request interface{}) (interface{}, error)

    // 转换响应格式
    ConvertResponse(from Provider, to Provider, response interface{}) (interface{}, error)

    // 转换流式响应
    ConvertStreamChunk(from Provider, to Provider, chunk interface{}) (interface{}, error)
}
```

#### 支持的转换路径
```
OpenAI Format (中心格式)
    ↕
┌───┴───┬────────┬────────┬────────┬────────┐
│Claude │ Gemini │ Azure  │ Baidu  │ Custom │
│       │        │ OpenAI │ Wenxin │        │
└───────┴────────┴────────┴────────┴────────┘
```

**设计原则：**
- OpenAI格式作为中间标准格式
- 其他格式先转为OpenAI，再转为目标格式
- 减少N*(N-1)转换器的维护成本

### 2.3 Provider适配器

#### 适配器接口
```go
type ProviderAdapter interface {
    // 获取Provider信息
    GetInfo() ProviderInfo

    // 发送聊天请求
    ChatCompletion(ctx context.Context, req *ChatRequest) (*ChatResponse, error)

    // 流式聊天请求
    ChatCompletionStream(ctx context.Context, req *ChatRequest) (<-chan *StreamChunk, error)

    // 模型列表
    ListModels(ctx context.Context) ([]Model, error)

    // 健康检查
    HealthCheck(ctx context.Context) error
}

type ProviderInfo struct {
    Name         string
    Version      string
    SupportedAPIs []string
    RateLimit    RateLimitInfo
}
```

#### 内置适配器

1. **OpenAI Adapter**
   - 支持GPT-3.5, GPT-4, GPT-4 Turbo等
   - 完整的流式支持
   - Function calling支持

2. **Claude Adapter**
   - Claude 3 Haiku/Sonnet/Opus
   - Claude 3.5 Sonnet
   - Claude 4系列
   - System提示处理
   - 多模态支持

3. **Gemini Adapter**
   - Gemini Pro/Ultra
   - Contents结构转换
   - SafetySettings处理

4. **Azure OpenAI Adapter**
   - 部署名称映射
   - Endpoint配置
   - API版本管理

5. **Baidu Wenxin Adapter**
   - ERNIE系列模型
   - 千帆平台对接
   - 国内网络优化

6. **Custom Adapter**
   - 基于配置的通用适配器
   - 支持OpenAPI规范定义

### 2.4 协议适配层

#### MCP协议支持
```go
type MCPAdapter struct {
    Version string // "20241105" or "20250326"
}

func (m *MCPAdapter) ConvertToMCP(openAPISpec *OpenAPISpec) (*MCPSpec, error)
func (m *MCPAdapter) HandleMCPRequest(req *MCPRequest) (*MCPResponse, error)
```

#### SSE流式支持
```go
type SSEHandler struct {
    Writer http.ResponseWriter
}

func (s *SSEHandler) WriteEvent(event *SSEEvent) error
func (s *SSEHandler) Close() error
```

#### WebSocket支持
```go
type WSHandler struct {
    Conn *websocket.Conn
}

func (w *WSHandler) SendMessage(msg *WSMessage) error
func (w *WSHandler) ReceiveMessage() (*WSMessage, error)
```

### 2.5 配额管理模块

#### 配额策略
```go
type QuotaPolicy struct {
    UserID          string
    Provider        string
    DailyTokenLimit int64
    MonthlyBudget   float64
    RateLimit       RateLimitConfig
}

type RateLimitConfig struct {
    RequestsPerMinute int
    RequestsPerHour   int
    TokensPerMinute   int64
    TokensPerHour     int64
}
```

#### 配额追踪
- 实时token消耗统计
- 成本计算和预估
- 配额预警机制
- 超限处理策略

### 2.6 日志与监控模块

#### 日志结构
```go
type RequestLog struct {
    RequestID   string
    Timestamp   time.Time
    UserID      string
    Provider    string
    Model       string
    Endpoint    string
    Method      string
    RequestSize int64
    ResponseSize int64
    TokensUsed  TokenUsage
    Latency     time.Duration
    StatusCode  int
    Error       string
}

type TokenUsage struct {
    PromptTokens     int64
    CompletionTokens int64
    TotalTokens      int64
}
```

#### 监控指标
- 请求QPS/TPS
- 响应延迟(P50/P95/P99)
- 错误率
- Token消耗速率
- Provider可用性
- 成本统计

## 三、数据模型设计

### 3.1 数据库Schema

#### Users表
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);
```

#### Provider Accounts表
```sql
CREATE TABLE provider_accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    provider VARCHAR(50) NOT NULL,
    account_name VARCHAR(100),
    api_key TEXT NOT NULL,
    api_secret TEXT,
    endpoint VARCHAR(255),
    config JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, provider, account_name)
);
```

#### Quota Policies表
```sql
CREATE TABLE quota_policies (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    provider VARCHAR(50),
    daily_token_limit BIGINT,
    monthly_budget DECIMAL(10, 2),
    requests_per_minute INTEGER,
    requests_per_hour INTEGER,
    tokens_per_minute BIGINT,
    tokens_per_hour BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, provider)
);
```

#### Usage Logs表
```sql
CREATE TABLE usage_logs (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(100) UNIQUE NOT NULL,
    user_id INTEGER REFERENCES users(id),
    provider VARCHAR(50),
    model VARCHAR(100),
    endpoint VARCHAR(255),
    prompt_tokens BIGINT,
    completion_tokens BIGINT,
    total_tokens BIGINT,
    cost DECIMAL(10, 6),
    latency_ms INTEGER,
    status_code INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_usage_logs_user_created ON usage_logs(user_id, created_at);
CREATE INDEX idx_usage_logs_provider_created ON usage_logs(provider, created_at);
```

#### Model Mappings表
```sql
CREATE TABLE model_mappings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    source_model VARCHAR(100),
    target_provider VARCHAR(50),
    target_model VARCHAR(100),
    config JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, source_model, target_provider)
);
```

### 3.2 配置文件结构

#### gateway.yaml
```yaml
server:
  host: 0.0.0.0
  port: 8080
  tls:
    enabled: false
    cert_file: ""
    key_file: ""

database:
  type: postgres  # postgres, sqlite, mysql
  host: localhost
  port: 5432
  database: ai_gateway
  username: postgres
  password: ""
  ssl_mode: disable

redis:
  enabled: false
  host: localhost
  port: 6379
  password: ""
  db: 0

auth:
  default_method: api_key
  jwt_secret: ""
  token_expiry: 24h

providers:
  openai:
    enabled: true
    base_url: https://api.openai.com/v1
    timeout: 60s
    retry_attempts: 3

  claude:
    enabled: true
    base_url: https://api.anthropic.com/v1
    timeout: 60s
    retry_attempts: 3

  gemini:
    enabled: true
    base_url: https://generativelanguage.googleapis.com/v1
    timeout: 60s
    retry_attempts: 3

logging:
  level: info  # debug, info, warn, error
  format: json  # json, text
  output: stdout  # stdout, file
  file_path: logs/gateway.log

monitoring:
  prometheus:
    enabled: true
    port: 9090

  metrics:
    collect_token_usage: true
    collect_latency: true
    collect_error_rate: true

rate_limit:
  default_rpm: 60
  default_rph: 1000
  default_tpm: 90000
  default_tph: 1000000
```

## 四、关键流程设计

### 4.1 请求处理流程

```
Client Request
    ↓
[API Gateway]
    ↓
[Authentication] ─→ Reject (401)
    ↓ Pass
[Rate Limiting] ─→ Reject (429)
    ↓ Pass
[Request Validation] ─→ Reject (400)
    ↓ Pass
[Format Detection]
    ↓
[Format Conversion] (if needed)
    ↓
[Provider Selection]
    ↓
[Provider Adapter]
    ↓
[External API Call]
    ↓
[Response Conversion]
    ↓
[Usage Logging]
    ↓
[Response to Client]
```

### 4.2 流式响应处理

```
Client Connects (SSE/WebSocket)
    ↓
[Stream Handler Init]
    ↓
[Provider Stream Request]
    ↓
┌─────────────────────┐
│ For each chunk:     │
│   ↓                 │
│ [Chunk Conversion]  │
│   ↓                 │
│ [Send to Client]    │
│   ↓                 │
│ [Token Counting]    │
└─────────────────────┘
    ↓
[Stream Complete]
    ↓
[Usage Update]
    ↓
[Close Connection]
```

### 4.3 故障处理流程

```
Request Failed
    ↓
[Error Type Detection]
    ↓
Rate Limit Error? ─→ [Wait & Retry]
    ↓ No
Network Error? ─→ [Retry with Backoff]
    ↓ No
Auth Error? ─→ [Try Alternative Account]
    ↓ No
Provider Down? ─→ [Failover to Backup Provider]
    ↓ No
[Return Error to Client]
```

## 五、安全设计

### 5.1 API密钥管理
- 密钥加密存储(AES-256)
- 定期轮换机制
- 密钥权限范围限制

### 5.2 通信安全
- TLS 1.3强制加密
- 证书验证
- HTTPS重定向

### 5.3 访问控制
- IP白名单/黑名单
- 地理位置限制
- User-Agent验证

### 5.4 审计日志
- 所有请求完整记录
- 敏感操作单独审计
- 日志不可篡改性

## 六、性能优化

### 6.1 缓存策略
- 模型列表缓存(TTL: 1h)
- 账户配置缓存(TTL: 5m)
- 响应缓存(可选,相同请求)

### 6.2 连接池
- HTTP连接复用
- 连接池大小动态调整
- 空闲连接超时清理

### 6.3 并发控制
- Goroutine池化
- 请求队列限制
- 优雅降级

### 6.4 数据库优化
- 读写分离
- 索引优化
- 连接池管理
- 批量写入

## 七、部署架构

### 7.1 单机部署
```
┌─────────────────────────────┐
│      Docker Compose         │
│  ┌─────────────────────┐   │
│  │  Gateway Service    │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │  PostgreSQL         │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │  Redis (Optional)   │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 7.2 集群部署
```
         ┌─────────────┐
         │Load Balancer│
         └──────┬──────┘
                │
    ┌───────────┼───────────┐
    ↓           ↓           ↓
┌────────┐  ┌────────┐  ┌────────┐
│Gateway1│  │Gateway2│  │Gateway3│
└───┬────┘  └───┬────┘  └───┬────┘
    └───────────┼───────────┘
                │
    ┌───────────┼───────────┐
    ↓           ↓           ↓
┌─────────┐ ┌──────┐ ┌──────────┐
│PostgreSQL│ │Redis │ │Prometheus│
│  Cluster│ │Cluster│ │          │
└─────────┘ └──────┘ └──────────┘
```

## 八、扩展性设计

### 8.1 插件系统
```go
type Plugin interface {
    Name() string
    Init(config map[string]interface{}) error
    BeforeRequest(req *Request) error
    AfterResponse(resp *Response) error
}
```

### 8.2 自定义Provider
- 基于配置的Provider定义
- 支持OpenAPI规范导入
- 自定义转换规则

### 8.3 Webhook支持
- 使用事件通知
- 配额预警
- 异常告警

---

**文档版本**: v1.0
**更新日期**: 2025-11-14
