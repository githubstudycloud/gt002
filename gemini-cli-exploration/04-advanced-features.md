# Gemini CLI 高级特性

## 1. 自定义系统指令

### 1.1 使用 GEMINI_SYSTEM_MD 环境变量

自定义 Gemini CLI 的核心行为指令，而不是使用硬编码的默认值。

```bash
# 创建自定义系统指令文件
cat > ~/my-system-instructions.md << 'EOF'
# 自定义系统指令

你是一个专注于 Python 开发的 AI 助手。

## 规则
- 始终使用 Python 3.11+ 特性
- 遵循 PEP 8 风格指南
- 优先使用类型注解
- 所有函数必须有文档字符串
- 使用 pytest 进行测试

## 代码风格
- 使用 4 空格缩进
- 行长度限制 88 字符（Black 风格）
- 使用 f-string 而不是 .format()

## 测试要求
- 测试覆盖率必须 > 80%
- 使用 pytest fixtures
- 测试文件命名: test_*.py
EOF

# 使用自定义系统指令
export GEMINI_SYSTEM_MD="$HOME/my-system-instructions.md"
gemini
```

### 1.2 项目特定系统指令

```bash
# 在项目中创建
cat > .gemini/system.md << 'EOF'
# 项目特定指令

这是一个 FastAPI 微服务项目。

## 架构要求
- 使用异步函数（async/await）
- 依赖注入模式
- 分层架构（路由 -> 服务 -> 数据访问）

## 安全要求
- 所有端点需要认证
- 输入验证使用 Pydantic
- SQL 查询使用参数化
EOF

# 设置环境变量指向项目文件
export GEMINI_SYSTEM_MD="./.gemini/system.md"
```

### 1.3 多个系统指令文件

```bash
# 组合多个指令文件
cat ~/base-instructions.md ./.gemini/project-instructions.md > /tmp/combined-instructions.md
export GEMINI_SYSTEM_MD="/tmp/combined-instructions.md"
```

## 2. 动态隔离代理（Isolated Agents）

### 2.1 智能模型路由器

预览版包含智能模型路由器，自动选择最适合任务的模型。

```bash
# 启用预览版
npm install -g @google/gemini-cli@preview

# 路由器会自动:
# - 简单问题 -> gemini-2.5-flash
# - 复杂分析 -> gemini-2.5-pro
# - 代码生成 -> 最合适的模型
```

### 2.2 代码库调查代理

内置的专门代理，用于深入分析代码库。

```bash
gemini -p "使用代码库调查代理分析这个项目的架构模式"
```

**代理能力**:
- 识别架构模式
- 检测设计模式
- 分析依赖关系图
- 找出技术债务
- 评估代码质量

### 2.3 创建自定义代理

```bash
# 在 .gemini/agents/ 目录创建代理定义
mkdir -p .gemini/agents

cat > .gemini/agents/security-auditor.toml << 'EOF'
[agent]
name = "security-auditor"
description = "安全审计代理"
model = "gemini-2.5-pro"

[system_prompt]
content = """
你是一个专业的安全审计员。

重点关注:
1. SQL 注入漏洞
2. XSS 攻击向量
3. CSRF 防护
4. 敏感数据泄露
5. 不安全的依赖项
6. 认证/授权问题

对于每个发现的问题，提供:
- 严重程度（高/中/低）
- 详细描述
- 利用场景
- 修复建议
"""

[tools]
enabled = ["read_file", "search_file_content", "web_fetch"]
EOF
```

## 3. 高级上下文管理

### 3.1 层级 GEMINI.md 策略

```
project/
├── GEMINI.md                    # 全局上下文
├── frontend/
│   ├── GEMINI.md               # 前端特定
│   ├── components/
│   │   └── GEMINI.md          # 组件特定
│   └── pages/
│       └── GEMINI.md          # 页面特定
└── backend/
    ├── GEMINI.md               # 后端特定
    └── api/
        └── GEMINI.md          # API 特定
```

**示例 - 根 GEMINI.md**:
```markdown
# 项目全局上下文

## 技术栈
- 前端: React 18 + TypeScript
- 后端: Node.js + Express
- 数据库: PostgreSQL 15
- 缓存: Redis

## 通用规则
- 所有代码必须通过 ESLint
- 提交前运行测试
- 使用语义化版本

## 环境
- 开发: localhost:3000
- 测试: test.example.com
- 生产: example.com
```

**示例 - frontend/GEMINI.md**:
```markdown
# 前端特定上下文

继承根级上下文。

## 组件规则
- 使用函数组件和 Hooks
- Props 使用 TypeScript 接口定义
- 样式使用 CSS Modules

## 状态管理
- 全局状态: Redux Toolkit
- 本地状态: useState/useReducer
- 服务器状态: React Query

## 测试
- 组件测试: React Testing Library
- E2E 测试: Playwright
```

### 3.2 动态上下文注入

```bash
# 根据任务动态添加上下文
gemini -p "$(cat task.txt)

上下文:
$(cat relevant-doc.md)

代码示例:
$(cat example.js)

现在执行任务。"
```

### 3.3 上下文模板

```bash
# 创建可重用的上下文模板
cat > ~/.gemini/templates/refactor-context.md << 'EOF'
# 重构上下文模板

## 重构目标
{REFACTOR_GOAL}

## 当前问题
{CURRENT_ISSUES}

## 期望结果
{EXPECTED_OUTCOME}

## 约束条件
- 不破坏现有 API
- 保持向后兼容
- 测试必须通过
- 性能不能降低
EOF

# 使用模板
REFACTOR_GOAL="提高代码可维护性"
CURRENT_ISSUES="函数过长，职责不清"
EXPECTED_OUTCOME="清晰的模块划分"

sed -e "s/{REFACTOR_GOAL}/$REFACTOR_GOAL/" \
    -e "s/{CURRENT_ISSUES}/$CURRENT_ISSUES/" \
    -e "s/{EXPECTED_OUTCOME}/$EXPECTED_OUTCOME/" \
    ~/.gemini/templates/refactor-context.md | gemini -p "$(cat) 重构 src/utils.js"
```

## 4. 高级 MCP 集成

### 4.1 多个 MCP 服务器配置

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://localhost/mydb"
      }
    },
    "custom-api": {
      "command": "node",
      "args": ["./mcp-servers/custom-api/index.js"],
      "env": {
        "API_KEY": "${CUSTOM_API_KEY}"
      }
    }
  }
}
```

### 4.2 创建自定义 MCP 服务器（FastMCP）

```python
# my_mcp_server.py
from fastmcp import FastMCP

mcp = FastMCP("My Custom Server")

@mcp.tool()
def analyze_code_complexity(file_path: str) -> dict:
    """分析代码复杂度"""
    # 实现代码复杂度分析
    return {
        "cyclomatic_complexity": 5,
        "cognitive_complexity": 3,
        "lines_of_code": 150
    }

@mcp.tool()
def check_security_vulnerabilities(directory: str) -> list:
    """检查安全漏洞"""
    # 实现安全扫描
    return [
        {"severity": "high", "issue": "SQL injection risk"},
        {"severity": "medium", "issue": "Weak password hash"}
    ]

if __name__ == "__main__":
    mcp.run()
```

**安装和配置**:
```bash
# 安装 FastMCP
pip install fastmcp

# 安装到 Gemini CLI
fastmcp install gemini-cli

# 在 settings.json 中配置
{
  "mcpServers": {
    "custom": {
      "command": "python",
      "args": ["./my_mcp_server.py"]
    }
  }
}
```

### 4.3 MCP 服务器与 Docker

```yaml
# docker-compose.yml
version: '3.8'
services:
  mcp-gateway:
    image: mcp/gateway:latest
    ports:
      - "8080:8080"
    environment:
      - MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}
    volumes:
      - ./mcp-config:/config

  postgres-mcp:
    image: mcp/postgres-server:latest
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=password
```

**配置 Gemini CLI**:
```json
{
  "mcpServers": {
    "postgres": {
      "transport": "sse",
      "url": "http://localhost:8080/mcp/postgres",
      "headers": {
        "Authorization": "Bearer ${MCP_AUTH_TOKEN}"
      }
    }
  }
}
```

### 4.4 OAuth 2.0 认证的 MCP 服务器

```json
{
  "mcpServers": {
    "enterprise-api": {
      "transport": "http",
      "url": "https://api.example.com/mcp",
      "oauth": {
        "clientId": "${OAUTH_CLIENT_ID}",
        "clientSecret": "${OAUTH_CLIENT_SECRET}",
        "tokenUrl": "https://auth.example.com/oauth/token",
        "scopes": ["mcp:read", "mcp:write"]
      }
    }
  }
}
```

## 5. 高级脚本和自动化

### 5.1 复杂工作流脚本

```bash
#!/bin/bash
# advanced-workflow.sh

set -e

echo "开始自动化工作流..."

# 1. 分析变更
echo "分析代码变更..."
CHANGES=$(git diff main --name-only)
ANALYSIS=$(gemini -p "分析这些变更: $CHANGES" --output-format json)

# 2. 运行测试
echo "运行测试..."
if ! npm test; then
  echo "测试失败，让 Gemini 修复..."
  gemini --yolo -p "修复失败的测试" --output-format stream-json | tee test-fix.log
  npm test
fi

# 3. 生成文档
echo "生成文档..."
gemini -p "为变更的文件生成文档" --output-format json > docs.json

# 4. 代码审查
echo "执行代码审查..."
gemini -p "审查这个 PR 的变更，关注安全和性能" > review.md

# 5. 生成提交消息
echo "生成提交消息..."
COMMIT_MSG=$(gemini -p "基于这些变更生成语义化提交消息: $CHANGES" --output-format json | jq -r '.response')

echo "工作流完成！"
echo "提交消息: $COMMIT_MSG"
```

### 5.2 条件执行和错误处理

```bash
#!/bin/bash
# smart-deploy.sh

# 错误处理
trap 'handle_error $?' ERR

handle_error() {
  local exit_code=$1
  echo "发生错误，退出代码: $exit_code"

  # 使用 Gemini 分析错误
  gemini -p "分析部署错误日志 @./deploy.log 并提供解决方案" > error-analysis.md

  echo "错误分析已保存到 error-analysis.md"
  exit $exit_code
}

# 部署前检查
echo "运行部署前检查..."
PRE_CHECK=$(gemini -p "检查代码是否准备好部署" --output-format json)

if echo "$PRE_CHECK" | jq -e '.ready == true' > /dev/null; then
  echo "通过检查，开始部署..."
  ./deploy.sh 2>&1 | tee deploy.log
else
  echo "未通过检查，需要修复:"
  echo "$PRE_CHECK" | jq -r '.issues[]'
  exit 1
fi
```

### 5.3 并行处理

```bash
#!/bin/bash
# parallel-processing.sh

FILES=(src/*.js)

# 为每个文件并行生成测试
for file in "${FILES[@]}"; do
  (
    echo "处理 $file..."
    gemini -p "为 @./$file 生成单元测试" > "${file%.js}.test.js"
    echo "完成 $file"
  ) &
done

# 等待所有后台任务完成
wait

echo "所有文件处理完成！"
```

## 6. 高级 IDE 集成

### 6.1 VS Code 配置

```json
// .vscode/settings.json
{
  "gemini-cli.enable": true,
  "gemini-cli.model": "gemini-2.5-pro",
  "gemini-cli.autoAccept": false,
  "gemini-cli.showDiffInEditor": true,
  "gemini-cli.keybindings": {
    "explain": "ctrl+shift+e",
    "refactor": "ctrl+shift+r",
    "test": "ctrl+shift+t"
  }
}
```

### 6.2 VS Code 任务集成

```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Gemini: 审查当前文件",
      "type": "shell",
      "command": "gemini",
      "args": [
        "-p",
        "审查 @./${relativeFile}"
      ],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Gemini: 生成测试",
      "type": "shell",
      "command": "gemini",
      "args": [
        "-p",
        "为 @./${relativeFile} 生成完整的测试套件"
      ]
    }
  ]
}
```

### 6.3 代码片段集成

```json
// .vscode/gemini-snippets.json
{
  "Gemini Review": {
    "prefix": "gemini-review",
    "body": [
      "// Gemini Review:",
      "// ${1:添加审查说明}",
      "// 运行: gemini -p '审查 @./$TM_FILEPATH'"
    ]
  },
  "Gemini TODO": {
    "prefix": "gemini-todo",
    "body": [
      "// TODO (Gemini): ${1:任务描述}",
      "// Context: ${2:上下文}",
      "// Priority: ${3|high,medium,low|}"
    ]
  }
}
```

## 7. 高级安全和沙箱

### 7.1 自定义沙箱配置

```json
// .gemini/sandbox-config.json
{
  "sandbox": {
    "image": "ubuntu:22.04",
    "volumes": [
      "./src:/workspace/src:ro",
      "./tests:/workspace/tests:rw"
    ],
    "environment": {
      "NODE_ENV": "test",
      "CI": "true"
    },
    "resources": {
      "cpus": 2,
      "memory": "2g"
    },
    "network": "none",
    "capabilities": {
      "drop": ["ALL"],
      "add": []
    }
  }
}
```

### 7.2 安全策略

```json
// .gemini/security-policy.json
{
  "tools": {
    "write_file": {
      "allowedPaths": ["src/**", "tests/**"],
      "deniedPaths": [".env", "*.key", "secrets/**"],
      "requireApproval": true
    },
    "run_shell_command": {
      "allowedCommands": ["npm", "git", "node"],
      "deniedCommands": ["rm -rf", "sudo", "curl"],
      "requireApproval": true
    },
    "web_fetch": {
      "allowedDomains": ["github.com", "npmjs.com"],
      "deniedDomains": ["*"],
      "requireApproval": true
    }
  }
}
```

### 7.3 审计日志

```bash
# 启用审计日志
export GEMINI_AUDIT_LOG="~/.gemini/audit.log"

# 审计日志格式
# [2025-01-12 14:30:25] USER:john TOOL:write_file PATH:src/main.js APPROVED:yes
# [2025-01-12 14:30:30] USER:john TOOL:run_shell_command CMD:npm test APPROVED:yes
```

## 8. 性能优化

### 8.1 令牌缓存策略

```json
// .gemini/cache-config.json
{
  "cache": {
    "enabled": true,
    "ttl": 3600,
    "strategy": "aggressive",
    "cacheableContexts": [
      "GEMINI.md",
      "package.json",
      "tsconfig.json"
    ]
  }
}
```

### 8.2 增量分析

```bash
# 只分析变更的文件
CHANGED_FILES=$(git diff --name-only main)
gemini -p "只分析这些变更的文件: $CHANGED_FILES"
```

### 8.3 批量操作优化

```bash
# 批量处理而不是逐个处理
gemini -p "
为以下所有文件生成测试（一次性处理）:
$(find src -name '*.js' -type f)

使用批量操作以提高效率。
"
```

## 9. 企业部署

### 9.1 中央配置管理

```bash
# /etc/gemini-cli/settings.json
{
  "organization": "acme-corp",
  "defaults": {
    "model": "gemini-2.5-pro",
    "vertex-ai": true,
    "project-id": "acme-prod"
  },
  "policies": {
    "requireApproval": true,
    "auditLog": "/var/log/gemini-cli/audit.log",
    "telemetry": true
  },
  "mcpServers": {
    "enterprise-tools": {
      "url": "https://mcp.acme.com"
    }
  }
}
```

### 9.2 SSO 集成

```bash
# 使用 gcloud 认证
gcloud auth application-default login

# 配置 Vertex AI
export VERTEX_AI_PROJECT="acme-prod"
export VERTEX_AI_LOCATION="us-central1"

gemini --vertex-ai
```

### 9.3 监控和遥测

```json
{
  "telemetry": {
    "enabled": true,
    "endpoint": "https://telemetry.acme.com/gemini-cli",
    "metrics": [
      "usage",
      "errors",
      "performance",
      "tool_calls"
    ]
  }
}
```

## 下一步

- 查看 [05-mcp-servers.md](05-mcp-servers.md) 深入了解 MCP
- 查看 [06-tips-tricks.md](06-tips-tricks.md) 学习最佳实践
- 查看 [07-examples.md](07-examples.md) 查看完整示例
