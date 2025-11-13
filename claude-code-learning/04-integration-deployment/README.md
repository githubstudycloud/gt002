# Claude Code 集成与部署

本目录介绍如何将 Claude Code 集成到各种 CI/CD 流程和云平台。

---

## 1. GitHub Actions 集成

### 1.1 基本设置
```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Claude Code Review
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          command: "审查这个 PR 的代码质量"
```

### 1.2 自动化测试
```yaml
name: Auto Fix Tests

on:
  push:
    branches: [main, develop]

jobs:
  fix-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run tests and fix failures
        run: |
          claude headless "运行测试并修复所有失败的测试"
```

### 1.3 自动化文档
```yaml
name: Update Documentation

on:
  push:
    paths:
      - 'src/**'

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - name: Generate docs
        run: |
          claude headless "更新 API 文档以反映最新代码变更"
```

📖 **官方文档**: [GitHub Actions](https://code.claude.com/docs/en/github-actions.md)

---

## 2. GitLab CI/CD 集成

### 2.1 基本配置
```yaml
# .gitlab-ci.yml
stages:
  - review
  - test
  - deploy

code_review:
  stage: review
  script:
    - claude headless "审查 MR !${CI_MERGE_REQUEST_IID}"
  only:
    - merge_requests

auto_fix:
  stage: test
  script:
    - claude headless "运行测试并修复问题"
  when: on_failure
```

### 2.2 自动创建 MR
```yaml
create_mr:
  stage: deploy
  script:
    - claude headless "创建合并请求用于版本 ${CI_COMMIT_TAG}"
  only:
    - tags
```

📖 **官方文档**: [GitLab CI/CD](https://code.claude.com/docs/en/gitlab-ci-cd.md)

---

## 3. MCP (Model Context Protocol)

### 3.1 什么是 MCP？
MCP 允许 Claude Code 连接到外部服务和数据源。

### 3.2 可用的 MCP Servers
- **GitHub**: 仓库、issues、PRs
- **PostgreSQL**: 数据库查询
- **MongoDB**: 数据库操作
- **Sentry**: 错误跟踪
- **Slack**: 消息通知
- 自定义服务器

### 3.3 配置 GitHub MCP
```json
// settings.json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_..."
      }
    }
  }
}
```

### 3.4 使用 MCP
```
连接到 GitHub 并获取所有 open issues
查询数据库中的用户表
从 Sentry 获取最近的错误
```

### 3.5 创建自定义 MCP Server
```typescript
// custom-mcp-server.ts
import { MCPServer } from '@modelcontextprotocol/sdk';

const server = new MCPServer({
  name: 'my-service',
  version: '1.0.0'
});

server.addTool({
  name: 'query_api',
  description: '查询内部 API',
  parameters: {
    endpoint: 'string'
  },
  handler: async (params) => {
    // 实现逻辑
  }
});

server.listen();
```

📖 **官方文档**: [MCP](https://code.claude.com/docs/en/mcp.md)

---

## 4. Headless 模式

### 4.1 什么是 Headless 模式？
非交互式命令行 API，用于自动化和脚本。

### 4.2 基本用法
```bash
# 单次命令
claude headless "分析代码库并生成报告"

# 保存输出
claude headless "运行测试" > test-results.txt

# 使用管道
echo "修复 lint 错误" | claude headless
```

### 4.3 多轮对话
```bash
# 使用会话 ID
SESSION_ID=$(claude headless --new-session "开始新功能")
claude headless --session $SESSION_ID "实现用户认证"
claude headless --session $SESSION_ID "添加测试"
```

### 4.4 脚本集成
```bash
#!/bin/bash
# auto-deploy.sh

# 运行测试
if claude headless "运行所有测试"; then
  echo "测试通过"

  # 构建
  claude headless "构建生产版本"

  # 部署
  claude headless "部署到生产环境"
else
  echo "测试失败，取消部署"
  exit 1
fi
```

### 4.5 Node.js 集成
```javascript
const { exec } = require('child_process');

async function runClaude(command) {
  return new Promise((resolve, reject) => {
    exec(`claude headless "${command}"`, (error, stdout, stderr) => {
      if (error) reject(error);
      else resolve(stdout);
    });
  });
}

// 使用
const result = await runClaude('分析代码质量');
console.log(result);
```

📖 **官方文档**: [Headless](https://code.claude.com/docs/en/headless.md)

---

## 5. AWS Bedrock 部署

### 5.1 配置
```json
// settings.json
{
  "provider": "bedrock",
  "bedrock": {
    "region": "us-east-1",
    "model": "anthropic.claude-3-sonnet-20240229-v1:0"
  }
}
```

### 5.2 IAM 配置
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream"
    ],
    "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
  }]
}
```

### 5.3 环境变量
```bash
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

📖 **官方文档**: [AWS Bedrock](https://code.claude.com/docs/en/amazon-bedrock.md)

---

## 6. Google Vertex AI 部署

### 6.1 配置
```json
// settings.json
{
  "provider": "vertex",
  "vertex": {
    "projectId": "my-project",
    "location": "us-central1",
    "model": "claude-3-sonnet@20240229"
  }
}
```

### 6.2 认证
```bash
gcloud auth application-default login
gcloud config set project my-project
```

### 6.3 IAM 角色
```bash
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:my-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

📖 **官方文档**: [Google Vertex AI](https://code.claude.com/docs/en/google-vertex-ai.md)

---

## 7. Dev Containers

### 7.1 配置文件
```json
// .devcontainer/devcontainer.json
{
  "name": "Claude Code Dev Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/anthropic/features/claude-code:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code"
      ]
    }
  }
}
```

### 7.2 团队共享
- 提交 .devcontainer 到版本控制
- 团队成员自动获得相同环境
- 确保一致的配置

### 7.3 安全隔离
- 容器化执行
- 网络隔离
- 资源限制

📖 **官方文档**: [Dev Containers](https://code.claude.com/docs/en/devcontainer.md)

---

## 8. Docker 集成

### 8.1 Dockerfile
```dockerfile
FROM node:18

# 安装 Claude Code
RUN npm install -g @anthropic/claude-code

# 配置
COPY .claude /root/.claude

WORKDIR /app
COPY . .

CMD ["claude", "headless", "运行任务"]
```

### 8.2 Docker Compose
```yaml
version: '3.8'

services:
  claude-worker:
    build: .
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    volumes:
      - ./src:/app/src
    command: claude headless "监听任务队列"
```

---

## 9. Jenkins 集成

### 9.1 Pipeline
```groovy
pipeline {
  agent any

  stages {
    stage('Code Review') {
      steps {
        sh 'claude headless "审查最新提交"'
      }
    }

    stage('Fix Tests') {
      when {
        expression {
          return currentBuild.result == 'FAILURE'
        }
      }
      steps {
        sh 'claude headless "修复失败的测试"'
      }
    }
  }
}
```

---

## 10. Kubernetes 部署

### 10.1 Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: claude-worker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: claude-worker
  template:
    metadata:
      labels:
        app: claude-worker
    spec:
      containers:
      - name: claude
        image: my-claude-image:latest
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: anthropic-secret
              key: api-key
```

---

## 11. 持续集成最佳实践

### 11.1 代码审查
```yaml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    - 检查代码质量
    - 验证测试覆盖
    - 检查安全问题
    - 评估性能
```

### 11.2 自动修复
```yaml
on:
  push:
    branches: [develop]

jobs:
  auto-fix:
    - 运行 linter
    - 修复格式问题
    - 更新类型定义
    - 提交修复
```

### 11.3 文档同步
```yaml
on:
  push:
    paths:
      - 'src/**/*.ts'

jobs:
  docs:
    - 生成 API 文档
    - 更新 README
    - 提交文档更新
```

---

## 12. 部署策略

### 12.1 蓝绿部署
使用 Claude Code 自动化：
- 部署新版本
- 运行冒烟测试
- 切换流量
- 监控指标

### 12.2 金丝雀发布
- 部署到小部分用户
- 监控错误率
- 逐步扩大范围
- 自动回滚

### 12.3 A/B 测试
- 部署多个版本
- 收集性能数据
- 分析结果
- 选择最佳版本

---

## 13. 监控和日志

### 13.1 集成 Sentry
```javascript
// 通过 MCP 连接 Sentry
const errors = await claude.mcp.sentry.getRecentErrors();
console.log('最近的错误:', errors);
```

### 13.2 日志分析
```bash
# 分析日志文件
claude headless "分析 logs/app.log 并识别问题"
```

### 13.3 性能监控
```bash
# 生成性能报告
claude headless "分析性能指标并生成优化建议"
```

---

## 14. 安全考虑

### 14.1 密钥管理
- 使用环境变量
- 使用密钥管理服务（AWS Secrets Manager, HashiCorp Vault）
- 不要硬编码密钥

### 14.2 网络安全
- 使用 HTTPS
- 配置防火墙
- 启用 VPN

### 14.3 访问控制
- IAM 角色和策略
- 最小权限原则
- 审计日志

---

## 15. 故障排查

### 15.1 常见问题
- API 密钥错误
- 网络连接问题
- 权限不足
- 配置错误

### 15.2 调试技巧
```bash
# 启用详细日志
claude --verbose headless "任务"

# 检查配置
claude config list

# 测试连接
claude headless "echo test"
```

---

## 下一步

学习 [安全与管理](../05-security-admin/) 的最佳实践！
