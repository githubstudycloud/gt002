# Gemini CLI 核心功能详解

## 1. 交互模式 (Interactive Mode)

### 启动交互模式

```bash
gemini
```

### 交互模式特性

- **REPL 环境**: 实时对话和命令执行
- **多轮对话**: 保持上下文的连续交互
- **实时反馈**: 即时看到 AI 的响应
- **工具批准**: 可以选择批准或拒绝工具调用

### 交互式命令示例

```bash
> 帮我分析这个项目的架构
> 找出所有 TODO 注释
> 为 src/utils.js 生成单元测试
> 解释 main.py 的工作原理
```

## 2. 非交互模式 (Non-Interactive Mode)

### 基本用法

```bash
# 单个提示
gemini -p "解释这个代码库"

# 从文件读取提示
gemini -p "$(cat prompt.txt)"

# 通过管道输入
echo "生成 README" | gemini
```

### 高级选项

```bash
# 指定模型
gemini -m gemini-2.5-flash -p "快速问题"

# 结构化输出
gemini -p "列出所有函数" --output-format json

# 实时流式输出
gemini -p "运行测试" --output-format stream-json

# YOLO 模式（自动批准所有操作）
gemini --yolo -p "修复所有 lint 错误"
```

## 3. 代码能力

### 3.1 代码库分析

```bash
# 交互式分析
gemini -i "分析这个项目的结构"

# 查找特定模式
gemini -p "找出所有使用 deprecated API 的地方"

# 依赖分析
gemini -p "列出所有外部依赖及其用途"
```

### 3.2 代码生成

```bash
# 生成新功能
gemini -p "创建一个用户认证模块，支持 JWT"

# 从规范生成
gemini -p "根据 @./spec.md 生成 REST API"

# 从图像生成
gemini -p "根据 @./mockup.png 创建登录页面"
```

### 3.3 代码修改

```bash
# 重构
gemini -p "将 utils.js 中的函数拆分为多个模块"

# 优化
gemini -p "优化 process.js 的性能"

# 更新
gemini -p "将所有组件升级到 React 18"
```

### 3.4 调试

```bash
# 错误诊断
gemini -p "调试为什么测试失败"

# 日志分析
gemini -p "分析 @./error.log 并找出根本原因"

# 性能问题
gemini -p "找出导致内存泄漏的代码"
```

## 4. 内置工具

### 4.1 文件系统工具

| 工具 | 功能 | 示例 |
|------|------|------|
| `list_directory` | 列出目录内容 | 自动调用 |
| `glob` | 模式匹配查找文件 | 自动调用 |
| `read_file` | 读取文件内容 | 自动调用 |
| `write_file` | 写入文件 | 需要批准 |
| `replace` | 替换文件内容 | 需要批准 |
| `search_file_content` | 搜索文件内容 | 自动调用 |

### 4.2 Shell 工具

```bash
# Gemini 可以执行 shell 命令
gemini -p "运行 npm test 并分析失败"
```

**安全提示**: Shell 命令需要批准，除非启用 `--yolo` 模式。

### 4.3 Web 工具

#### Google Web Search

```bash
gemini -p "搜索 React 18 的新特性并总结"
```

#### Web Fetch

```bash
gemini -p "获取 @https://api.github.com/repos/user/repo 的信息"
```

### 4.4 记忆工具

```bash
# 保存跨会话信息
/memory add 数据库端口是 5432

# 查看记忆
/memory show

# 刷新记忆
/memory refresh
```

## 5. 多模态输入

### 5.1 图像处理

```bash
# 引用本地图像
gemini -p "描述 @./screenshot.png 中的 UI"

# 从剪贴板粘贴图像
# 在交互模式中按 Ctrl+V

# 基于图像生成代码
gemini -p "根据 @./design.png 实现这个界面"
```

### 5.2 自动图像重命名

```bash
gemini -p "扫描 images/ 目录并根据内容重命名所有图像"
```

示例输出:
- `IMG_1234.jpg` → `login_screen.jpg`
- `photo_567.png` → `dashboard_chart.png`

### 5.3 PDF 处理

```bash
gemini -p "根据 @./requirements.pdf 生成项目结构"
```

## 6. 上下文管理

### 6.1 GEMINI.md 文件

项目特定的上下文和指令文件。

```bash
# 生成 GEMINI.md
/init
```

**GEMINI.md 示例内容**:

```markdown
# 项目上下文

## 风格指南
- 使用 4 空格缩进
- 使用 ESLint 标准配置
- 所有函数必须有 JSDoc 注释

## 架构
这是一个 Express.js 后端应用，使用 PostgreSQL 数据库。

## 测试
- 运行测试: npm test
- 测试文件位于 tests/ 目录
- 使用 Jest 作为测试框架

## 重要提示
- 永远不要直接修改 database.js
- 所有 API 端点必须有错误处理
```

### 6.2 层级 GEMINI.md

支持多层级的上下文文件：

```
project/
├── GEMINI.md (根级上下文)
├── frontend/
│   └── GEMINI.md (前端特定上下文)
└── backend/
    └── GEMINI.md (后端特定上下文)
```

### 6.3 引用上下文

```bash
# 引用单个文件
gemini -p "使用 @./docs/api.md 的规范实现 API"

# 引用整个目录
gemini -p "分析 @./src/ 中的代码"

# 引用多个资源
gemini -p "基于 @./design.png 和 @./spec.md 创建页面"
```

### 6.4 记忆系统

```bash
# 快速添加信息
/memory add API_URL=https://api.example.com
/memory add 数据库密码在 LastPass 中

# 查看所有记忆
/memory show

# 记忆在会话间持久化
```

## 7. 对话管理

### 7.1 保存和恢复会话

```bash
# 保存当前对话
/chat save feature-auth

# 恢复之前的对话
/chat resume feature-auth

# 列出所有保存的对话
/chat list
```

### 7.2 压缩对话

```bash
# 总结长对话以节省令牌
/compress
```

这会将完整的对话历史替换为简洁的摘要。

### 7.3 清空屏幕

```bash
# 清空终端显示（不影响对话上下文）
/clear
# 或按 Ctrl+L
```

## 8. 检查点和恢复

### 8.1 启用检查点

```bash
# 方法 1: 命令行标志
gemini --checkpointing

# 方法 2: settings.json
{
  "checkpointing": true
}
```

### 8.2 使用检查点

```bash
# 在交互模式中，Gemini 修改文件前会自动创建检查点

# 查看和恢复检查点
/restore
```

**检查点界面**:
```
可用的检查点:
1. 2025-01-12 14:30:25 - 修改前: src/utils.js
2. 2025-01-12 14:25:10 - 修改前: src/index.js

选择要恢复的检查点编号:
```

## 9. 沙箱模式

### 9.1 启用沙箱

需要 Docker 或 Podman:

```bash
# 在沙箱中运行
gemini --sandbox -p "测试这段危险代码"
```

### 9.2 沙箱优势

- **隔离执行**: 代码在容器中运行
- **安全性**: 无法访问主机文件系统（除非明确挂载）
- **清洁环境**: 每次运行都是新的环境
- **实验友好**: 可以安全地测试不确定的操作

## 10. IDE 集成

### 10.1 VS Code 集成

```bash
# 在交互模式中
/ide install
/ide enable
```

### 10.2 原生 Diff 查看

启用后，代码更改会在 VS Code 的 diff 查看器中显示，而不是在终端中。

**优势**:
- 更好的视觉对比
- 使用熟悉的 IDE 界面
- 可以单独批准每个更改
- 语法高亮支持

## 11. 令牌和性能优化

### 11.1 大上下文窗口

Gemini 2.5 Pro 提供 1M 令牌上下文窗口：
- 可以处理整个大型代码库
- 可以包含大量文档
- 支持长时间对话

### 11.2 令牌缓存

Gemini CLI 自动缓存令牌以提高性能和降低成本。

### 11.3 查看令牌使用

```bash
# 在交互模式中
/stats
```

显示:
- 输入令牌数
- 输出令牌数
- 缓存令牌数
- 总成本估算

## 12. 输出格式

### 12.1 JSON 输出

```bash
gemini -p "列出所有函数" --output-format json
```

输出结构化的 JSON 数据，便于脚本处理。

### 12.2 Stream JSON

```bash
gemini -p "运行长时间任务" --output-format stream-json
```

实时流式传输事件，用于监控长时间运行的操作。

### 12.3 标准输出（默认）

```bash
gemini -p "解释代码"
```

人类可读的格式化输出。

## 13. 自动化和脚本

### 13.1 非交互式脚本

```bash
#!/bin/bash
# auto-review.sh

gemini --yolo -p "审查最近的提交并生成报告" --output-format json > review.json
```

### 13.2 条件执行

```bash
# 只在测试失败时运行
npm test || gemini -p "修复失败的测试"
```

### 13.3 批量处理

```bash
# 处理多个文件
for file in src/*.js; do
  gemini -p "为 $file 生成文档"
done
```

## 14. GitHub 集成

### 14.1 GitHub Actions

```yaml
# .github/workflows/gemini-review.yml
name: Gemini Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: google-github-actions/run-gemini-cli@v1
        with:
          prompt: "审查这个 PR 的代码更改"
```

### 14.2 @mentions

在 GitHub issue 或 PR 中提及:
```
@gemini-cli 请分析这个性能问题
```

## 下一步

- 查看 [03-commands-reference.md](03-commands-reference.md) 学习所有命令
- 查看 [04-advanced-features.md](04-advanced-features.md) 了解高级功能
- 查看 [07-examples.md](07-examples.md) 查看实用示例
