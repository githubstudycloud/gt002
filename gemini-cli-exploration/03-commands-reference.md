# Gemini CLI 命令参考手册

## 命令行标志（Flags）

### 基本选项

| 标志 | 简写 | 描述 | 示例 |
|------|------|------|------|
| `--prompt` | `-p` | 非交互式提示 | `gemini -p "解释代码"` |
| `--prompt-interactive` | `-i` | 以初始提示启动交互模式 | `gemini -i "分析项目"` |
| `--model` | `-m` | 指定模型 | `gemini -m gemini-2.5-flash` |
| `--help` | `-h` | 显示帮助信息 | `gemini --help` |
| `--version` | `-v` | 显示版本 | `gemini --version` |

### 配置选项

| 标志 | 描述 | 示例 |
|------|------|------|
| `--debug` | `-d` | 启用调试输出 | `gemini --debug` |
| `--yolo` | 自动批准所有工具调用 | `gemini --yolo -p "修复错误"` |
| `--checkpointing` | `-c` | 启用检查点 | `gemini --checkpointing` |
| `--sandbox` | 在沙箱环境中运行 | `gemini --sandbox` |
| `--no-telemetry` | 禁用遥测 | `gemini --no-telemetry` |

### 上下文选项

| 标志 | 描述 | 示例 |
|------|------|------|
| `--include-directories` | 包含额外目录 | `gemini --include-directories ../lib,../docs` |
| `--exclude-directories` | 排除目录 | `gemini --exclude-directories node_modules,dist` |
| `--max-context-files` | 最大上下文文件数 | `gemini --max-context-files 100` |

### 输出选项

| 标志 | 描述 | 示例 |
|------|------|------|
| `--output-format` | 输出格式 | `gemini -p "..." --output-format json` |
| `--quiet` | `-q` | 静默模式 | `gemini -q -p "..."` |
| `--no-color` | 禁用颜色输出 | `gemini --no-color` |

### 认证选项

| 标志 | 描述 | 示例 |
|------|------|------|
| `--vertex-ai` | 使用 Vertex AI | `gemini --vertex-ai --project-id my-project` |
| `--project-id` | GCP 项目 ID | `gemini --project-id my-project` |
| `--region` | GCP 区域 | `gemini --region us-central1` |

## 交互式命令（Slash Commands）

### 基础命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `/help` | 显示帮助 | `/help` |
| `/clear` | 清空屏幕 | `/clear` |
| `/exit` | 退出 Gemini CLI | `/exit` |
| `/quit` | 退出 Gemini CLI | `/quit` |

### 上下文管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `/init` | 生成 GEMINI.md | `/init` |
| `/memory show` | 显示记忆 | `/memory show` |
| `/memory add` | 添加记忆 | `/memory add PORT=3000` |
| `/memory refresh` | 刷新上下文 | `/memory refresh` |
| `/compress` | 压缩对话历史 | `/compress` |

### 对话管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `/chat save` | 保存对话 | `/chat save my-session` |
| `/chat resume` | 恢复对话 | `/chat resume my-session` |
| `/chat list` | 列出保存的对话 | `/chat list` |
| `/chat delete` | 删除对话 | `/chat delete my-session` |

### 工具和信息

| 命令 | 描述 | 示例 |
|------|------|------|
| `/tools` | 列出可用工具 | `/tools` |
| `/stats` | 显示令牌统计 | `/stats` |
| `/copy` | 复制最后响应 | `/copy` |

### 检查点和恢复

| 命令 | 描述 | 示例 |
|------|------|------|
| `/restore` | 列出/恢复检查点 | `/restore` |
| `/checkpoint list` | 列出检查点 | `/checkpoint list` |
| `/checkpoint create` | 创建检查点 | `/checkpoint create` |

### 配置命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `/settings` | 编辑 settings.json | `/settings` |
| `/vim` | 切换 Vim 模式 | `/vim` |

### IDE 集成

| 命令 | 描述 | 示例 |
|------|------|------|
| `/ide install` | 安装 IDE 集成 | `/ide install` |
| `/ide enable` | 启用 IDE 集成 | `/ide enable` |
| `/ide disable` | 禁用 IDE 集成 | `/ide disable` |

### MCP 服务器管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `/mcp list` | 列出 MCP 服务器 | `/mcp list` |
| `/mcp add` | 添加 MCP 服务器 | `/mcp add server-name` |
| `/mcp remove` | 移除 MCP 服务器 | `/mcp remove server-name` |
| `/mcp status` | 检查 MCP 服务器状态 | `/mcp status` |

## 上下文引用（@ 符号）

### 文件引用

```bash
# 引用单个文件
@./src/main.js

# 引用多个文件
@./src/utils.js @./src/helpers.js

# 使用通配符
@./src/**/*.js
```

### 目录引用

```bash
# 递归包含整个目录
@./src/

# 排除某些文件
@./src/ （配合 .geminiignore）
```

### 图像引用

```bash
# 引用图像文件
@./design.png
@./screenshots/login.jpg

# 多个图像
@./mockup1.png @./mockup2.png
```

### URL 引用

```bash
# 引用 Web 资源
@https://api.github.com/repos/user/repo

# 引用文档
@https://docs.example.com/api
```

## Shell 命令（! 符号）

### 单次命令执行

```bash
# 执行单个 shell 命令
!git status
!npm test
!ls -la
```

### 持久 Shell 模式

```bash
# 切换持久 shell 模式
!

# 在持久模式中，所有输入都作为 shell 命令执行
# 再次输入 ! 退出持久模式
```

### 常用 Shell 命令示例

```bash
# Git 操作
!git log --oneline -10
!git diff main

# 测试和构建
!npm test
!npm run build
!cargo test

# 文件操作
!find . -name "*.js"
!grep -r "TODO" src/

# 系统信息
!df -h
!ps aux | grep node
```

## 键盘快捷键

### 通用快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+L` | 清空屏幕 |
| `Ctrl+C` | 取消当前操作 |
| `Ctrl+D` | 退出（EOF）|
| `Ctrl+V` | 粘贴剪贴板内容（包括图像）|
| `Ctrl+Y` | 切换 YOLO 模式 |
| `Ctrl+X` | 在外部编辑器中打开提示 |

### 编辑快捷键（非 Vim 模式）

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A` | 移到行首 |
| `Ctrl+E` | 移到行末 |
| `Ctrl+K` | 删除到行末 |
| `Ctrl+U` | 删除到行首 |
| `Ctrl+W` | 删除前一个单词 |
| `Alt+B` | 后退一个单词 |
| `Alt+F` | 前进一个单词 |

### Vim 模式快捷键

启用 Vim 模式后 (`/vim`):

| 快捷键 | 功能 |
|--------|------|
| `Esc` | 进入命令模式 |
| `i` | 插入模式 |
| `a` | 在光标后插入 |
| `A` | 在行末插入 |
| `dd` | 删除行 |
| `yy` | 复制行 |
| `p` | 粘贴 |
| `/` | 搜索 |

## 输出格式

### 标准输出（默认）

```bash
gemini -p "解释代码"
```

输出: 格式化的人类可读文本

### JSON 输出

```bash
gemini -p "列出函数" --output-format json
```

输出结构:
```json
{
  "response": "...",
  "metadata": {
    "model": "gemini-2.5-pro",
    "tokens": {
      "input": 1234,
      "output": 567
    }
  }
}
```

### Stream JSON 输出

```bash
gemini -p "运行测试" --output-format stream-json
```

实时流式事件:
```json
{"event": "start", "timestamp": "..."}
{"event": "tool_call", "tool": "run_shell_command", "args": {...}}
{"event": "tool_result", "output": "..."}
{"event": "response", "text": "..."}
{"event": "complete", "timestamp": "..."}
```

## 模型选择

### 可用模型

| 模型 | 速度 | 成本 | 适用场景 |
|------|------|------|---------|
| `gemini-2.5-pro` | 中等 | 高 | 复杂任务、大型代码库 |
| `gemini-2.5-flash` | 快 | 低 | 简单问题、快速响应 |
| `gemini-2.0-flash-exp` | 快 | 低 | 实验性功能 |

### 指定模型

```bash
# 使用快速模型
gemini -m gemini-2.5-flash -p "简单问题"

# 使用高级模型
gemini -m gemini-2.5-pro -p "复杂分析"
```

## MCP 相关命令

### 列出 MCP 服务器

```bash
gemini mcp list
```

### 添加 MCP 服务器

```bash
# 从 npm 包添加
gemini mcp add @modelcontextprotocol/server-github

# 从本地路径添加
gemini mcp add ./my-custom-server

# 使用 FastMCP
fastmcp install gemini-cli
```

### 移除 MCP 服务器

```bash
gemini mcp remove server-name
```

### 在 settings.json 中配置

```json
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

## 自定义命令

### 创建自定义命令

1. 创建命令目录:
```bash
mkdir -p ~/.gemini/commands
```

2. 创建 TOML 文件 (例如 `~/.gemini/commands/review.toml`):
```toml
[command]
name = "review"
description = "代码审查"

[prompt]
content = """
请审查当前项目的代码，关注:
1. 代码质量和最佳实践
2. 潜在的 bug
3. 性能问题
4. 安全漏洞

生成详细的审查报告。
"""
```

3. 使用自定义命令:
```bash
gemini /review
```

### 项目特定命令

在项目根目录创建 `.gemini/commands/`:
```bash
mkdir -p .gemini/commands
```

优先级: 项目命令 > 用户命令 > 系统命令

## 环境变量

### 常用环境变量

| 变量 | 描述 | 示例 |
|------|------|------|
| `GEMINI_API_KEY` | API 密钥 | `export GEMINI_API_KEY="..."` |
| `GEMINI_MODEL` | 默认模型 | `export GEMINI_MODEL="gemini-2.5-flash"` |
| `GEMINI_SYSTEM_MD` | 自定义系统指令 | `export GEMINI_SYSTEM_MD="./system.md"` |
| `GEMINI_CONFIG_DIR` | 配置目录 | `export GEMINI_CONFIG_DIR="~/.config/gemini"` |
| `NO_COLOR` | 禁用颜色 | `export NO_COLOR=1` |

### 设置环境变量

#### Linux/macOS

```bash
# 临时设置
export GEMINI_API_KEY="your-key"

# 永久设置（添加到 ~/.bashrc 或 ~/.zshrc）
echo 'export GEMINI_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc
```

#### Windows PowerShell

```powershell
# 临时设置
$env:GEMINI_API_KEY="your-key"

# 永久设置
[System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', 'your-key', 'User')
```

#### Windows CMD

```cmd
# 临时设置
set GEMINI_API_KEY=your-key

# 永久设置
setx GEMINI_API_KEY "your-key"
```

## 管道和重定向

### 输入管道

```bash
# 从 echo 管道输入
echo "解释这段代码" | gemini

# 从文件管道输入
cat prompt.txt | gemini

# 从其他命令管道输入
git diff | gemini -p "审查这些更改"
```

### 输出重定向

```bash
# 重定向到文件
gemini -p "生成报告" > report.txt

# 追加到文件
gemini -p "额外信息" >> report.txt

# 同时查看和保存
gemini -p "分析" | tee output.txt
```

### 组合使用

```bash
# 复杂管道
cat error.log | gemini -p "分析这些错误" --output-format json | jq '.response'
```

## 退出代码

Gemini CLI 使用标准退出代码:

| 代码 | 含义 |
|------|------|
| `0` | 成功 |
| `1` | 一般错误 |
| `2` | 使用错误（无效参数等）|
| `130` | 用户中断（Ctrl+C）|

### 脚本中使用

```bash
#!/bin/bash

if gemini -p "运行测试"; then
  echo "成功"
else
  echo "失败，退出代码: $?"
  exit 1
fi
```

## 配置优先级

配置来源按以下优先级应用（从高到低）:

1. 命令行标志
2. 环境变量
3. 项目 `.gemini/settings.json`
4. 用户 `~/.gemini/settings.json`
5. 系统 `/etc/gemini-cli/settings.json`
6. 默认值

### 示例

```bash
# 这会覆盖所有其他设置
gemini --model gemini-2.5-flash -p "..."
```

## 下一步

- 查看 [04-advanced-features.md](04-advanced-features.md) 了解高级功能
- 查看 [06-tips-tricks.md](06-tips-tricks.md) 学习最佳实践
- 查看 [07-examples.md](07-examples.md) 查看实用示例
