# Claude Code 定制化指南

本目录介绍如何通过各种定制功能来扩展和优化 Claude Code。

---

## 1. Sub-agents（子代理）

### 什么是 Sub-agents？
Sub-agents 是专门用于特定任务的 AI 代理，可以独立运行复杂的多步骤任务。

### 可用的 Sub-agents
- **general-purpose**: 通用任务代理
- **Explore**: 代码库探索专家（快速、中等、深度模式）
- **code-reviewer**: 代码审查
- **test-runner**: 测试执行
- **data-science**: 数据分析

### 使用示例
```
# 让 Explore 代理分析代码库
使用 Explore 代理找出所有的 API 端点

# 代码审查
使用 code-reviewer 审查 src/auth/ 目录

# 数据分析
分析这个 CSV 文件的统计信息
```

### 创建自定义 Sub-agent
```typescript
// 在 .claude/agents/ 目录下创建配置
{
  "name": "my-custom-agent",
  "description": "专门处理特定任务",
  "tools": ["Read", "Edit", "Bash"],
  "prompt": "你是一个专门的代理..."
}
```

📖 **官方文档**: [Sub-agents](https://code.claude.com/docs/en/sub-agents.md)

---

## 2. Plugins（插件）

### 什么是 Plugins？
Plugins 是可扩展的组件，用于添加自定义功能和团队工作流程。

### 插件类型
1. **工具插件**: 添加新的工具功能
2. **集成插件**: 连接外部服务
3. **工作流插件**: 自动化常见任务

### 插件结构
```
.claude/
  plugins/
    my-plugin/
      plugin.json      # 插件配置
      index.ts         # 主要逻辑
      README.md        # 文档
```

### 示例：创建简单插件
```json
// plugin.json
{
  "name": "code-formatter",
  "version": "1.0.0",
  "description": "自动格式化代码",
  "tools": [{
    "name": "format",
    "description": "格式化代码文件",
    "parameters": {
      "file": "string",
      "style": "string"
    }
  }]
}
```

### 团队共享插件
- 放在项目的 `.claude/plugins/` 目录
- 提交到版本控制
- 团队成员自动获得

📖 **官方文档**: [Plugins](https://code.claude.com/docs/en/plugins.md)

---

## 3. Skills（技能）

### 什么是 Skills？
Skills 是聚焦的工具，具有受控权限，可在团队间共享。

### Skills vs Plugins
| 特性 | Skills | Plugins |
|------|--------|---------|
| 范围 | 单一功能 | 多功能 |
| 权限 | 受限 | 灵活 |
| 共享 | 容易 | 中等 |
| 复杂度 | 简单 | 复杂 |

### 创建 Skill
```typescript
// .claude/skills/deploy.ts
export default {
  name: "deploy",
  description: "部署应用到生产环境",
  permissions: ["bash"],

  async execute(args: { environment: string }) {
    // 部署逻辑
  }
}
```

### 使用 Skill
```
/skill deploy environment=production
```

📖 **官方文档**: [Skills](https://code.claude.com/docs/en/skills.md)

---

## 4. Output Styles（输出样式）

### 什么是 Output Styles？
自定义 Claude 的响应格式和风格。

### 预设样式
- **concise**: 简洁模式
- **detailed**: 详细模式
- **technical**: 技术模式
- **educational**: 教学模式

### 创建自定义样式
```json
// .claude/output-styles/custom.json
{
  "name": "custom",
  "description": "我的自定义输出样式",
  "rules": [
    "始终使用中文回复",
    "代码示例要包含注释",
    "提供多个解决方案",
    "解释技术决策的原因"
  ],
  "format": {
    "codeBlocks": true,
    "emoji": false,
    "markdown": true
  }
}
```

### 应用样式
```
/style custom
```

📖 **官方文档**: [Output Styles](https://code.claude.com/docs/en/output-styles.md)

---

## 5. Hooks（钩子）

### 什么是 Hooks？
Hooks 是事件驱动的自动化脚本，在特定事件发生时执行。

### 可用的 Hooks
- **user-prompt-submit-hook**: 用户提交提示词前
- **tool-call-hook**: 工具调用前
- **file-write-hook**: 文件写入前
- **file-edit-hook**: 文件编辑前
- **bash-hook**: Bash 命令执行前

### 配置 Hooks
```json
// settings.json
{
  "hooks": {
    "file-write-hook": "npm run format {file}",
    "bash-hook": "echo '执行: {command}'"
  }
}
```

### 使用场景

#### 5.1 代码格式化
```json
{
  "hooks": {
    "file-write-hook": "prettier --write {file}",
    "file-edit-hook": "eslint --fix {file}"
  }
}
```

#### 5.2 代码检查
```json
{
  "hooks": {
    "file-write-hook": "npm run lint {file}"
  }
}
```

#### 5.3 通知
```bash
# .claude/hooks/notify.sh
#!/bin/bash
echo "文件已修改: $1" | notify-send
```

#### 5.4 安全检查
```json
{
  "hooks": {
    "bash-hook": "security-check.sh {command}"
  }
}
```

### Hook 返回值
- **0**: 允许操作
- **非0**: 阻止操作

### Hook 模板
```bash
#!/bin/bash
# .claude/hooks/pre-write.sh

FILE=$1

# 检查文件扩展名
if [[ $FILE == *.ts ]]; then
  # 运行 TypeScript 检查
  tsc --noEmit $FILE
  exit $?
fi

exit 0
```

📖 **官方文档**: [Hooks Guide](https://code.claude.com/docs/en/hooks-guide.md)

---

## 6. Slash Commands（斜杠命令）

### 什么是 Slash Commands？
自定义命令，用于快速执行常见任务。

### 内置命令
- `/help`: 帮助
- `/clear`: 清除对话
- `/settings`: 设置
- `/checkpoint`: 检查点
- `/rewind`: 回退

### 创建项目级命令
```markdown
<!-- .claude/commands/review-pr.md -->
# Review PR

请执行以下步骤审查 Pull Request {pr_number}:

1. 获取 PR 信息
2. 检查代码质量
3. 运行测试
4. 生成审查报告
```

### 创建个人命令
```markdown
<!-- ~/.config/claude-code/commands/daily.md -->
# Daily Routine

执行每日开发例程:

1. git pull origin main
2. npm install
3. npm run test
4. 生成今日任务列表
```

### 使用命令
```
/review-pr 123
/daily
```

### 命令参数
命令可以接受参数：
```
/review-pr {pr_number}
/deploy {environment} {version}
```

调用：
```
/review-pr 42
/deploy production v1.2.3
```

📖 **官方文档**: [Slash Commands](https://code.claude.com/docs/en/slash-commands.md)

---

## 7. Memory（记忆）

### 什么是 Memory？
持久化的上下文存储，在对话间保持信息。

### Memory 类型
1. **项目 Memory**: 特定项目的上下文
2. **组织 Memory**: 团队共享的知识

### 配置 Memory
```json
// .claude/memory.json
{
  "project": {
    "name": "MyApp",
    "tech_stack": ["React", "TypeScript", "Node.js"],
    "conventions": {
      "naming": "camelCase",
      "testing": "Jest",
      "linting": "ESLint"
    },
    "architecture": {
      "pattern": "MVC",
      "structure": "feature-based"
    }
  }
}
```

### Memory 使用
Claude Code 会自动记住：
- 项目结构
- 代码风格
- 常用模式
- 团队约定

### 更新 Memory
```
记住：我们使用 Prettier 进行代码格式化
记住：API 使用 REST 风格
记住：测试覆盖率要求 80%
```

📖 **官方文档**: [Memory](https://code.claude.com/docs/en/memory.md)

---

## 8. 配置层级

Claude Code 支持多层级配置：

```
1. 系统级配置
   ~/.config/claude-code/

2. 用户级配置
   ~/.claude/

3. 项目级配置
   .claude/

4. 运行时配置
   命令行参数
```

优先级：运行时 > 项目 > 用户 > 系统

---

## 9. 最佳实践

### 9.1 Sub-agents
- 用于复杂、多步骤任务
- 让主对话保持简洁
- 并行运行独立的 agents

### 9.2 Plugins
- 封装可重用逻辑
- 与团队共享
- 版本控制

### 9.3 Skills
- 单一职责
- 最小权限
- 清晰文档

### 9.4 Hooks
- 保持简单快速
- 避免阻塞操作
- 记录日志

### 9.5 Slash Commands
- 命名清晰
- 包含帮助文档
- 支持参数

### 9.6 Memory
- 定期更新
- 保持相关性
- 不要过度填充

---

## 10. 实战示例

### 示例 1: 完整的开发工作流

**.claude/commands/feature.md**
```markdown
# 新功能开发流程

1. 创建功能分支
2. 实现功能代码
3. 编写测试
4. 运行测试和 lint
5. 创建 commit
6. 创建 PR
```

**.claude/hooks/pre-commit.sh**
```bash
#!/bin/bash
npm run test && npm run lint
```

**使用**:
```
/feature user-authentication
```

### 示例 2: 代码审查自动化

**.claude/commands/review.md**
```markdown
# 代码审查

分析 PR #{pr_number}:
1. 检查代码质量
2. 验证测试覆盖
3. 检查安全问题
4. 生成审查评论
```

**.claude/agents/code-reviewer.json**
```json
{
  "name": "code-reviewer",
  "tools": ["Read", "Bash", "WebFetch"],
  "checklist": [
    "代码符合规范",
    "有足够的测试",
    "无安全漏洞",
    "性能可接受"
  ]
}
```

### 示例 3: 文档生成

**.claude/commands/docs.md**
```markdown
# 生成文档

1. 分析代码结构
2. 生成 API 文档
3. 更新 README
4. 生成变更日志
```

---

## 11. 配置示例集合

### 完整的 .claude 目录结构
```
.claude/
├── commands/
│   ├── feature.md
│   ├── review.md
│   └── deploy.md
├── hooks/
│   ├── pre-write.sh
│   └── pre-commit.sh
├── plugins/
│   └── team-tools/
│       ├── plugin.json
│       └── index.ts
├── skills/
│   ├── deploy.ts
│   └── test.ts
├── agents/
│   └── custom-reviewer.json
├── output-styles/
│   └── team-style.json
└── memory.json
```

---

## 下一步

学习如何将 Claude Code [集成到 CI/CD](../04-integration-deployment/) 流程！
