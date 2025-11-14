# AI API Gateway 快速开始指南

## 前提条件

- Docker & Docker Compose
- 或 Go 1.21+ (如果从源码运行)

## 使用Docker快速启动 (推荐)

### 1. 克隆仓库
```bash
git clone https://github.com/your-org/ai-api-gateway.git
cd ai-api-gateway
```

### 2. 配置
```bash
# 复制配置文件
cp config/gateway.example.yaml config/gateway.yaml

# 编辑配置文件,设置数据库密码等
nano config/gateway.yaml
```

### 3. 启动服务
```bash
docker-compose up -d
```

### 4. 检查服务状态
```bash
# 查看所有服务
docker-compose ps

# 查看日志
docker-compose logs -f gateway

# 健康检查
curl http://localhost:8080/health
```

### 5. 创建API Key
```bash
# 进入容器
docker-compose exec gateway sh

# 运行CLI创建API Key (假设已实现CLI)
./gateway api-key create --name "My First Key"

# 或使用API创建 (需要先创建初始管理员密钥)
curl -X POST http://localhost:8080/v1/admin/api-keys \
  -H "Authorization: Bearer <admin-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My First Key",
    "scopes": ["chat", "embeddings"]
  }'
```

### 6. 配置Provider账户
```bash
# 添加OpenAI账户
curl -X POST http://localhost:8080/v1/admin/provider-accounts \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "openai",
    "account_name": "OpenAI Production",
    "api_key": "sk-..."
  }'

# 添加Claude账户
curl -X POST http://localhost:8080/v1/admin/provider-accounts \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "claude",
    "account_name": "Claude Production",
    "api_key": "sk-ant-..."
  }'
```

### 7. 测试聊天API
```bash
# 使用OpenAI格式调用
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "Hello, who are you?"}
    ],
    "provider": "openai"
  }'

# 自动路由到Claude
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-opus-20240229",
    "messages": [
      {"role": "user", "content": "Hello, Claude!"}
    ]
  }'
```

### 8. 查看使用统计
```bash
curl http://localhost:8080/v1/admin/usage?start_date=2025-11-01 \
  -H "Authorization: Bearer <your-api-key>"
```

### 9. 访问监控面板
- Prometheus: http://localhost:9091
- Grafana: http://localhost:3000 (默认用户名/密码: admin/admin)

## 从源码运行

### 1. 安装依赖
```bash
# 克隆仓库
git clone https://github.com/your-org/ai-api-gateway.git
cd ai-api-gateway

# 下载依赖
go mod download
```

### 2. 启动数据库
```bash
# 使用Docker启动PostgreSQL
docker run -d \
  --name ai-gateway-postgres \
  -e POSTGRES_DB=ai_gateway \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=gateway123 \
  -p 5432:5432 \
  postgres:15-alpine
```

### 3. 配置
```bash
cp config/gateway.example.yaml config/gateway.yaml
# 编辑配置文件
```

### 4. 运行数据库迁移
```bash
go run cmd/migrate/main.go up
```

### 5. 启动服务
```bash
go run cmd/gateway/main.go
```

## 使用CLI工具 (待开发)

### 安装CLI
```bash
# 使用go install
go install github.com/your-org/ai-api-gateway/cmd/cli@latest

# 或下载预编译二进制
# 参考 Releases 页面
```

### 配置CLI
```bash
ai-gateway config set api_key <your-api-key>
ai-gateway config set base_url http://localhost:8080
```

### 使用CLI
```bash
# 聊天
ai-gateway chat "Hello, how are you?" --model gpt-4

# 流式聊天
ai-gateway chat "Tell me a story" --stream

# 查看使用情况
ai-gateway usage --last 7d

# 管理Provider
ai-gateway providers list
ai-gateway providers add openai --api-key sk-...

# 查看模型列表
ai-gateway models list
```

## 集成到现有应用

### Python (使用OpenAI SDK)
```python
from openai import OpenAI

client = OpenAI(
    api_key="your-gateway-api-key",
    base_url="http://localhost:8080/v1"
)

# 使用OpenAI
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Hello!"}
    ],
    extra_body={"provider": "openai"}
)

# 使用Claude (通过OpenAI格式)
response = client.chat.completions.create(
    model="claude-3-opus-20240229",
    messages=[
        {"role": "user", "content": "Hello!"}
    ]
)
```

### JavaScript/TypeScript (使用OpenAI SDK)
```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'your-gateway-api-key',
  baseURL: 'http://localhost:8080/v1',
});

// 使用OpenAI
const response = await client.chat.completions.create({
  model: 'gpt-4',
  messages: [
    { role: 'user', content: 'Hello!' }
  ],
  provider: 'openai', // 自定义参数
});

// 使用Claude
const response = await client.chat.completions.create({
  model: 'claude-3-opus-20240229',
  messages: [
    { role: 'user', content: 'Hello!' }
  ],
});
```

### cURL
```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer <your-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

## 常见问题

### 如何切换不同的AI提供商?
通过在请求中指定`provider`参数,或者使用模型映射功能。

### 如何设置配额限制?
使用配额策略API创建和管理配额限制。

### 如何查看API调用日志?
通过使用统计API或直接查询数据库的`usage_logs`表。

### 支持流式响应吗?
是的,设置`stream: true`参数即可启用流式响应。

### 可以在生产环境使用吗?
目前处于早期开发阶段,建议等待v1.0稳定版本再用于生产。

## 下一步

- 阅读[完整文档](docs/README.md)
- 查看[API规范](docs/03-api-specification.md)
- 了解[架构设计](docs/02-architecture-design.md)
- 参与[贡献](CONTRIBUTING.md)

## 获取帮助

- GitHub Issues: 报告问题
- GitHub Discussions: 技术讨论
- 文档: docs/

## 许可证

MIT License - 详见 [LICENSE](LICENSE)
