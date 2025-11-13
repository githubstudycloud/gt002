# Claude Code 快速参考

这是一个快速参考指南，包含最常用的命令、概念和技巧。

---

## 基本命令

```bash
# 启动 Claude Code
claude

# 在特定目录启动
claude --cwd /path/to/project

# 使用特定模型
claude --model claude-opus-4

# Headless 模式（非交互）
claude headless "执行任务"

# 显示版本
claude --version

# 显示帮助
claude --help
```

---

## 交互模式命令

```bash
/help              # 显示帮助
/clear             # 清除对话历史
/exit              # 退出（或 Ctrl+D）
/settings          # 查看设置
/checkpoint save   # 保存检查点
/checkpoint list   # 列出检查点
/rewind N          # 回退 N 步
```

---

## 配置命令

```bash
# 查看配置
claude config list
claude config get <key>

# 设置配置
claude config set api_key sk-ant-...
claude config set model claude-sonnet-4

# 编辑配置文件
claude config edit
```

---

## 常用任务

### 代码分析
```
分析这个项目的架构
解释 src/auth/login.ts 的工作原理
找出所有的 API 端点
这个错误是什么意思：[粘贴错误]
```

### 代码生成
```
创建一个 React 用户表单组件，包含验证
实现一个 RESTful API 端点用于用户注册
生成这个数据库表的 TypeScript 类型定义
```

### Bug 修复
```
修复 src/utils/api.ts 的类型错误
运行测试并修复所有失败的用例
解决这个性能问题
```

### 测试
```
为 calculateTotal 函数编写单元测试
添加集成测试覆盖支付流程
运行测试并生成覆盖率报告
```

### Git 操作
```
帮我创建一个 commit
创建一个 pull request
审查 PR #123
```

### 重构
```
重构 UserService 使其更模块化
优化这个函数的性能
应用单一职责原则重构这个类
```

---

## 工具系统

### 文件操作
- **Read**: 读取文件
- **Write**: 创建新文件
- **Edit**: 编辑现有文件
- **Glob**: 文件模式匹配
- **Grep**: 内容搜索

### Shell 操作
- **Bash**: 执行命令
- **BashOutput**: 获取后台输出
- **KillShell**: 终止进程

### Web 操作
- **WebFetch**: 获取网页
- **WebSearch**: 搜索引擎

### 任务管理
- **Task**: 启动子代理
- **TodoWrite**: 管理任务列表

---

## 提示词技巧

### ✅ 清晰具体
```
在 src/components/Header.tsx 中添加一个深色模式切换按钮，
使用 React hooks 管理状态，样式使用 TailwindCSS
```

### ✅ 提供上下文
```
我正在使用 React 18 和 TypeScript。
需要创建一个表单组件，使用 React Hook Form 进行验证。
```

### ✅ 分步骤
```
1. 首先创建数据模型
2. 然后实现 API 端点
3. 最后添加前端集成
```

### ❌ 避免模糊
```
改一下代码      # 太模糊
测试一下        # 不清楚
优化性能        # 缺少具体目标
```

---

## 快捷操作

### 并行操作
```
同时执行：
1. 读取 package.json
2. 读取 tsconfig.json
3. 运行 git status
```

### 使用 Sub-agents
```
使用 Explore 代理找出所有的数据库查询
使用 code-reviewer 代理审查最近的变更
```

---

## 文件结构

### 推荐的 .claude 目录
```
.claude/
├── memory.json           # 项目记忆
├── commands/             # 自定义命令
│   ├── feature.md
│   ├── review.md
│   └── test.md
├── hooks/                # 钩子脚本
│   ├── format.sh
│   └── lint.sh
└── plugins/              # 插件
```

---

## 配置模板

### 基本配置
```json
{
  "model": "claude-sonnet-4",
  "apiKey": "从环境变量读取",
  "sandbox": {
    "enabled": true
  }
}
```

### 企业配置
```json
{
  "provider": "bedrock",
  "model": "claude-3-5-sonnet-20240620",
  "security": {
    "sandbox": { "enabled": true },
    "allowedTools": ["Read", "Edit", "Bash"]
  },
  "audit": { "enabled": true },
  "hooks": {
    "file-write-hook": "./hooks/format.sh"
  }
}
```

---

## Git 工作流

### 创建 Commit
```
帮我创建一个 commit

# Claude 会自动：
# 1. git status
# 2. git diff
# 3. 分析变更
# 4. 生成提交消息
# 5. git commit
```

### 创建 PR
```
创建一个 pull request

# Claude 会自动：
# 1. 分析所有变更
# 2. 生成 PR 描述
# 3. 使用 gh pr create
```

---

## 常用 Hooks

### 格式化
```bash
# .claude/hooks/format.sh
#!/bin/bash
prettier --write "$1"
eslint --fix "$1"
```

### Lint 检查
```bash
# .claude/hooks/lint.sh
#!/bin/bash
eslint "$1"
exit $?
```

### 类型检查
```bash
# .claude/hooks/type-check.sh
#!/bin/bash
tsc --noEmit "$1"
exit $?
```

---

## 常见问题

### API 密钥
```bash
# 设置 API 密钥
export ANTHROPIC_API_KEY=sk-ant-...

# 或使用配置
claude config set api_key sk-ant-...
```

### 代理设置
```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

### 调试模式
```bash
claude --debug
claude --log-level trace
claude --log-file debug.log
```

---

## 快捷键（交互模式）

- `Ctrl+C`: 中断当前操作
- `Ctrl+D`: 退出
- `↑` / `↓`: 浏览历史
- `Ctrl+R`: 搜索历史
- `Tab`: 自动补全（如启用）

---

## 最佳实践速查

### ✅ 做
- 清晰具体的指令
- 提供足够上下文
- 分步骤处理复杂任务
- 使用检查点保存状态
- 审查生成的代码
- 编写测试
- 使用版本控制

### ❌ 不做
- 模糊的指令
- 跳过测试
- 不审查代码
- 忽略错误
- 硬编码敏感信息
- 过度依赖不理解

---

## 性能提示

- 使用 Sub-agents 处理大任务
- 并行执行独立操作
- 启用缓存
- 定期清理历史
- 选择合适的模型

---

## 模型选择

| 模型 | 用途 | 特点 |
|------|------|------|
| Claude 3 Haiku | 快速任务 | 速度快、成本低 |
| Claude 3.5 Sonnet | 日常开发 | 平衡性能和成本 |
| Claude 3 Opus | 复杂任务 | 最强能力 |

---

## 有用的链接

- **官方文档**: https://code.claude.com/docs/
- **GitHub**: https://github.com/anthropics/claude-code
- **社区**: https://github.com/anthropics/claude-code/discussions
- **问题报告**: https://github.com/anthropics/claude-code/issues

---

## 快速开始检查清单

- [ ] 安装 Claude Code
- [ ] 设置 API 密钥
- [ ] 配置编辑器（可选）
- [ ] 创建项目 memory.json
- [ ] 添加常用 hooks
- [ ] 创建自定义命令
- [ ] 开始使用！

---

## 应急命令

```bash
# 清除所有数据
claude clear-all

# 重置配置
claude reset

# 检查连接
claude test-connection

# 查看日志
claude logs

# 查看统计
claude stats
```

---

**提示**: 将此文件加入书签，随时查阅！

**下一步**: 查看 [完整文档](./README.md) 深入学习。
