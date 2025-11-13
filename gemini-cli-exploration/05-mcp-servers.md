# MCP 服务器集成指南

## 什么是 MCP？

**Model Context Protocol (MCP)** 是一个开放协议，允许 AI 应用与外部数据源和工具安全地连接。

### MCP 的优势

- **扩展性**: 添加自定义工具和功能
- **标准化**: 统一的协议接口
- **安全性**: 受控的权限和访问
- **可组合性**: 多个服务器协同工作

## MCP 传输方式

### 1. STDIO (标准输入/输出)

本地进程通信，适合本地工具。

```json
{
  "mcpServers": {
    "local-tool": {
      "command": "node",
      "args": ["./mcp-server.js"]
    }
  }
}
```

### 2. SSE (Server-Sent Events)

远程 HTTP 连接，适合云服务。

```json
{
  "mcpServers": {
    "remote-service": {
      "transport": "sse",
      "url": "https://mcp.example.com/sse"
    }
  }
}
```

### 3. Streamable HTTP

双向流式 HTTP，适合高性能需求。

```json
{
  "mcpServers": {
    "high-performance": {
      "transport": "http",
      "url": "https://mcp.example.com/stream"
    }
  }
}
```

## 官方 MCP 服务器

### 1. GitHub MCP Server

#### 安装和配置

```bash
# 安装
npm install -g @modelcontextprotocol/server-github

# 获取 GitHub Token
# 访问: https://github.com/settings/tokens
# 权限: repo, read:org, read:user
```

#### 配置

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

#### 可用工具

| 工具 | 功能 | 示例 |
|------|------|------|
| `create_issue` | 创建 issue | "创建一个 issue 跟踪这个 bug" |
| `comment_on_issue` | 评论 issue | "在 issue #123 上添加评论" |
| `create_pull_request` | 创建 PR | "创建 PR 合并这些更改" |
| `list_issues` | 列出 issues | "列出所有开放的 issues" |
| `get_repository` | 获取仓库信息 | "获取仓库统计信息" |
| `search_code` | 搜索代码 | "搜索所有使用 async/await 的地方" |

#### 使用示例

```bash
gemini
> 在我的仓库 user/repo 中创建一个 issue 来跟踪性能优化任务

> 列出 facebook/react 仓库中最近 10 个 issues

> 搜索 microsoft/vscode 中所有 TODO 注释
```

### 2. PostgreSQL MCP Server

#### 安装和配置

```bash
npm install -g @modelcontextprotocol/server-postgres
```

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:password@localhost:5432/mydb"
      }
    }
  }
}
```

#### 可用工具

- `query`: 执行 SQL 查询
- `list_tables`: 列出所有表
- `describe_table`: 获取表结构
- `execute`: 执行 DML 语句

#### 使用示例

```bash
gemini
> 列出数据库中的所有表

> 查询 users 表的结构

> 找出最近 7 天注册的用户数量

> 分析 orders 表的性能问题
```

### 3. Filesystem MCP Server

#### 安装和配置

```bash
npm install -g @modelcontextprotocol/server-filesystem
```

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"],
      "args_extra": ["/allowed/path1", "/allowed/path2"]
    }
  }
}
```

#### 安全提示

只授予必要目录的访问权限。

### 4. Slack MCP Server

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-token",
        "SLACK_TEAM_ID": "T01234567"
      }
    }
  }
}
```

### 5. Google Drive MCP Server

```json
{
  "mcpServers": {
    "gdrive": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gdrive"],
      "env": {
        "GOOGLE_CLIENT_ID": "your-client-id",
        "GOOGLE_CLIENT_SECRET": "your-client-secret"
      }
    }
  }
}
```

## 使用 FastMCP 创建自定义服务器

### 1. 基础示例

```python
# my_mcp_server.py
from fastmcp import FastMCP

mcp = FastMCP("My Custom Tools")

@mcp.tool()
def calculate_checksum(file_path: str) -> str:
    """计算文件的 SHA256 校验和"""
    import hashlib
    with open(file_path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()

@mcp.tool()
def count_lines(file_path: str, extension: str = ".py") -> dict:
    """统计代码行数"""
    import os
    total_lines = 0
    file_count = 0

    for root, dirs, files in os.walk(file_path):
        for file in files:
            if file.endswith(extension):
                file_count += 1
                with open(os.path.join(root, file), 'r') as f:
                    total_lines += len(f.readlines())

    return {
        "total_files": file_count,
        "total_lines": total_lines,
        "average_lines": total_lines // file_count if file_count > 0 else 0
    }

if __name__ == "__main__":
    mcp.run()
```

### 2. 安装 FastMCP

```bash
# 安装
pip install fastmcp>=2.12.3

# 安装到 Gemini CLI
fastmcp install gemini-cli
```

### 3. 配置

```json
{
  "mcpServers": {
    "custom-tools": {
      "command": "python",
      "args": ["./my_mcp_server.py"]
    }
  }
}
```

### 4. 高级示例 - API 集成

```python
# api_mcp_server.py
from fastmcp import FastMCP
import requests

mcp = FastMCP("API Integration Tools")

@mcp.tool()
def fetch_weather(city: str) -> dict:
    """获取城市天气信息"""
    api_key = os.getenv('WEATHER_API_KEY')
    url = f"https://api.openweathermap.org/data/2.5/weather"
    params = {"q": city, "appid": api_key, "units": "metric"}

    response = requests.get(url, params=params)
    data = response.json()

    return {
        "temperature": data["main"]["temp"],
        "humidity": data["main"]["humidity"],
        "description": data["weather"][0]["description"]
    }

@mcp.tool()
def search_packages(query: str, registry: str = "npm") -> list:
    """搜索包管理器"""
    if registry == "npm":
        url = f"https://registry.npmjs.org/-/v1/search"
        params = {"text": query, "size": 10}
        response = requests.get(url, params=params)
        data = response.json()
        return [
            {
                "name": obj["package"]["name"],
                "description": obj["package"]["description"],
                "version": obj["package"]["version"]
            }
            for obj in data["objects"]
        ]

@mcp.tool()
def analyze_docker_image(image_name: str) -> dict:
    """分析 Docker 镜像"""
    import docker
    client = docker.from_env()
    image = client.images.get(image_name)

    return {
        "id": image.id,
        "tags": image.tags,
        "size": image.attrs["Size"] / (1024 * 1024),  # MB
        "created": image.attrs["Created"],
        "layers": len(image.history())
    }

if __name__ == "__main__":
    mcp.run()
```

### 5. 数据库集成示例

```python
# database_mcp_server.py
from fastmcp import FastMCP
import psycopg2
import os

mcp = FastMCP("Database Tools")

def get_db_connection():
    return psycopg2.connect(os.getenv('DATABASE_URL'))

@mcp.tool()
def analyze_table_size(table_name: str) -> dict:
    """分析表大小和行数"""
    conn = get_db_connection()
    cur = conn.cursor()

    # 获取表大小
    cur.execute(f"""
        SELECT
            pg_size_pretty(pg_total_relation_size('{table_name}')) as total_size,
            pg_size_pretty(pg_relation_size('{table_name}')) as table_size,
            pg_size_pretty(pg_indexes_size('{table_name}')) as indexes_size
    """)
    sizes = cur.fetchone()

    # 获取行数
    cur.execute(f"SELECT COUNT(*) FROM {table_name}")
    row_count = cur.fetchone()[0]

    cur.close()
    conn.close()

    return {
        "table": table_name,
        "row_count": row_count,
        "total_size": sizes[0],
        "table_size": sizes[1],
        "indexes_size": sizes[2]
    }

@mcp.tool()
def find_slow_queries() -> list:
    """查找慢查询"""
    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            query,
            calls,
            total_time,
            mean_time,
            max_time
        FROM pg_stat_statements
        ORDER BY mean_time DESC
        LIMIT 10
    """)

    results = []
    for row in cur.fetchall():
        results.append({
            "query": row[0][:100],  # 截断长查询
            "calls": row[1],
            "total_time_ms": round(row[2], 2),
            "mean_time_ms": round(row[3], 2),
            "max_time_ms": round(row[4], 2)
        })

    cur.close()
    conn.close()

    return results

if __name__ == "__main__":
    mcp.run()
```

## Docker MCP Toolkit

### 1. 配置 Docker Desktop

Docker Desktop 自动配置 MCP Gateway 连接。

### 2. 使用示例

```bash
gemini
> 列出所有运行中的容器

> 分析 my-app 容器的资源使用

> 查看 nginx 镜像的层信息
```

### 3. 自定义 Docker MCP 配置

```json
{
  "mcpServers": {
    "docker": {
      "transport": "http",
      "url": "http://localhost:8080/mcp/docker",
      "headers": {
        "Authorization": "Bearer ${DOCKER_MCP_TOKEN}"
      }
    }
  }
}
```

## 远程 MCP 服务器

### 1. 使用 OAuth 2.0 认证

```json
{
  "mcpServers": {
    "enterprise-api": {
      "transport": "sse",
      "url": "https://mcp.company.com/api",
      "oauth": {
        "clientId": "${OAUTH_CLIENT_ID}",
        "clientSecret": "${OAUTH_CLIENT_SECRET}",
        "tokenUrl": "https://auth.company.com/oauth/token",
        "scopes": ["mcp:read", "mcp:write", "mcp:admin"]
      }
    }
  }
}
```

### 2. 使用 API Key 认证

```json
{
  "mcpServers": {
    "api-service": {
      "transport": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "X-API-Key": "${API_KEY}",
        "X-Client-ID": "gemini-cli"
      }
    }
  }
}
```

### 3. 自定义请求头

```json
{
  "mcpServers": {
    "custom-service": {
      "transport": "sse",
      "url": "https://mcp.example.com",
      "headers": {
        "Authorization": "Bearer ${ACCESS_TOKEN}",
        "X-Tenant-ID": "acme-corp",
        "X-Environment": "production"
      }
    }
  }
}
```

## MCP 服务器管理

### 命令行管理

```bash
# 列出所有配置的 MCP 服务器
gemini mcp list

# 添加服务器
gemini mcp add github

# 移除服务器
gemini mcp remove github

# 检查服务器状态
gemini mcp status

# 测试服务器连接
gemini mcp test github
```

### 在交互模式中管理

```bash
gemini

# 列出可用工具（包括 MCP 工具）
/tools

# 查看特定服务器的工具
/tools github

# 重新加载 MCP 配置
/mcp reload
```

## 调试 MCP 服务器

### 1. 启用调试模式

```bash
# 启用详细日志
gemini --debug

# 或设置环境变量
export DEBUG=mcp:*
gemini
```

### 2. 测试 MCP 服务器

```bash
# 直接测试 STDIO 服务器
node ./mcp-server.js

# 测试 HTTP 服务器
curl -X POST https://mcp.example.com/tools \
  -H "Content-Type: application/json" \
  -d '{"method": "list_tools"}'
```

### 3. 查看日志

```bash
# MCP 日志位置
~/.gemini/logs/mcp-*.log

# 实时查看日志
tail -f ~/.gemini/logs/mcp-github.log
```

## 多内容响应

MCP 工具可以返回多种内容类型：

### 文本 + 图像

```python
@mcp.tool()
def generate_chart(data: list) -> dict:
    """生成数据图表"""
    import matplotlib.pyplot as plt
    import io
    import base64

    # 生成图表
    plt.plot(data)
    buf = io.BytesIO()
    plt.savefig(buf, format='png')
    buf.seek(0)
    image_base64 = base64.b64encode(buf.read()).decode()

    return {
        "content": [
            {
                "type": "text",
                "text": f"图表包含 {len(data)} 个数据点"
            },
            {
                "type": "image",
                "data": image_base64,
                "mimeType": "image/png"
            }
        ]
    }
```

### 文本 + 文件

```python
@mcp.tool()
def generate_report(query: str) -> dict:
    """生成分析报告"""
    report_text = "..."  # 生成报告
    csv_data = "..."     # 生成 CSV

    return {
        "content": [
            {
                "type": "text",
                "text": report_text
            },
            {
                "type": "resource",
                "uri": "file:///tmp/report.csv",
                "mimeType": "text/csv",
                "text": csv_data
            }
        ]
    }
```

## 安全最佳实践

### 1. 环境变量管理

```bash
# 不要硬编码敏感信息
# ❌ 错误
{
  "env": {
    "API_KEY": "sk-1234567890abcdef"
  }
}

# ✅ 正确
{
  "env": {
    "API_KEY": "${API_KEY}"
  }
}
```

### 2. 最小权限原则

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "permissions": {
        "allowedRepos": ["myorg/*"],
        "allowedActions": ["read", "comment"],
        "deniedActions": ["delete", "force-push"]
      }
    }
  }
}
```

### 3. 网络隔离

```json
{
  "mcpServers": {
    "internal-tool": {
      "command": "node",
      "args": ["./server.js"],
      "network": {
        "allowedHosts": ["api.internal.com"],
        "deniedHosts": ["*"],
        "allowedPorts": [443, 8080]
      }
    }
  }
}
```

## 实用 MCP 服务器集合

### 社区服务器

1. **Brave Search MCP** - Web 搜索
2. **Puppeteer MCP** - 浏览器自动化
3. **SQLite MCP** - SQLite 数据库
4. **Git MCP** - Git 操作
5. **Kubernetes MCP** - K8s 管理
6. **AWS MCP** - AWS 服务
7. **Sentry MCP** - 错误追踪
8. **Stripe MCP** - 支付集成

### 安装社区服务器

```bash
# 通过 npm
npm install -g @community/mcp-server-name

# 配置
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@community/mcp-server-name"]
    }
  }
}
```

## 故障排除

### 问题: MCP 服务器连接失败

```bash
# 检查服务器是否可达
gemini mcp test server-name

# 查看详细错误
gemini --debug mcp test server-name
```

### 问题: 工具未出现

```bash
# 重新加载配置
/mcp reload

# 检查 settings.json 语法
cat ~/.gemini/settings.json | jq .
```

### 问题: 认证错误

```bash
# 验证环境变量
echo $GITHUB_TOKEN
echo $API_KEY

# 重新设置
export GITHUB_TOKEN="your-new-token"
```

## 下一步

- 查看 [06-tips-tricks.md](06-tips-tricks.md) 学习使用技巧
- 查看 [07-examples.md](07-examples.md) 查看完整示例
- 访问 [MCP 官方文档](https://modelcontextprotocol.io)
