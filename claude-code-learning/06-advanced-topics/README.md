# Claude Code 高级主题

本目录介绍 Claude Code 的高级功能和深度配置。

---

## 1. IDE 集成

### 1.1 VS Code 扩展

#### 安装
```bash
# 从市场安装
code --install-extension anthropic.claude-code

# 或在 VS Code 中搜索 "Claude Code"
```

#### 功能
- **内联建议**: 编码时的实时建议
- **聊天面板**: 侧边栏对话界面
- **快速操作**: 右键菜单集成
- **问题诊断**: 实时错误修复

#### 配置
```json
// settings.json
{
  "claude-code.apiKey": "sk-ant-...",
  "claude-code.model": "claude-sonnet-4",
  "claude-code.autoSuggest": true,
  "claude-code.inlineCompletions": true
}
```

#### 快捷键
- `Ctrl+Shift+C`: 打开 Claude 聊天
- `Ctrl+K Ctrl+C`: 解释代码
- `Ctrl+K Ctrl+F`: 修复错误
- `Ctrl+K Ctrl+R`: 重构代码

📖 **官方文档**: [VS Code](https://code.claude.com/docs/en/vs-code.md)

---

### 1.2 JetBrains IDE 插件

#### 支持的 IDE
- IntelliJ IDEA
- PyCharm
- WebStorm
- PhpStorm
- GoLand
- RubyMine
- Rider

#### 安装
```
Settings → Plugins → Marketplace
搜索 "Claude Code" → Install
```

#### 功能
- **智能补全**: 上下文感知的代码建议
- **重构助手**: AI 驱动的重构
- **测试生成**: 自动生成测试用例
- **文档生成**: 智能注释和文档

#### 配置
```
Settings → Tools → Claude Code
- API Key: sk-ant-...
- Model: claude-sonnet-4
- Enable inline suggestions
```

📖 **官方文档**: [JetBrains](https://code.claude.com/docs/en/jetbrains.md)

---

## 2. 模型配置

### 2.1 可用模型
- **Claude 3.5 Sonnet**: 平衡性能和成本
- **Claude 3 Opus**: 最强能力
- **Claude 3 Haiku**: 快速响应
- **Claude 3.5 Opus** (即将推出): 下一代旗舰

### 2.2 选择模型
```bash
# 命令行
claude --model claude-opus-4

# 配置文件
claude config set model claude-sonnet-4

# 环境变量
export CLAUDE_MODEL=claude-sonnet-4
```

### 2.3 模型别名
```json
// settings.json
{
  "modelAliases": {
    "fast": "claude-3-haiku-20240307",
    "balanced": "claude-3-5-sonnet-20240620",
    "powerful": "claude-3-opus-20240229"
  }
}
```

使用别名：
```bash
claude --model fast "快速分析这个文件"
claude --model powerful "深度重构这个模块"
```

### 2.4 上下文窗口
不同模型的限制：
- Claude 3 Haiku: 200K tokens
- Claude 3 Sonnet: 200K tokens
- Claude 3 Opus: 200K tokens

配置策略：
```json
{
  "contextManagement": {
    "maxTokens": 100000,
    "strategy": "sliding-window",
    "preserveRecent": true
  }
}
```

📖 **官方文档**: [Model Configuration](https://code.claude.com/docs/en/model-config.md)

---

## 3. Memory（记忆系统）

### 3.1 项目记忆
```json
// .claude/memory.json
{
  "project": {
    "name": "E-Commerce Platform",
    "description": "React + Node.js 电商平台",
    "techStack": {
      "frontend": ["React 18", "TypeScript", "TailwindCSS"],
      "backend": ["Node.js", "Express", "PostgreSQL"],
      "testing": ["Jest", "Cypress"]
    },
    "conventions": {
      "naming": {
        "files": "kebab-case",
        "components": "PascalCase",
        "functions": "camelCase"
      },
      "structure": "feature-based",
      "imports": "absolute paths with @/ alias"
    },
    "patterns": {
      "stateManagement": "Redux Toolkit",
      "styling": "CSS Modules + Tailwind",
      "apiCalls": "React Query"
    },
    "rules": [
      "Always use TypeScript strict mode",
      "All components must have PropTypes or TypeScript interfaces",
      "Test coverage must be above 80%",
      "Use ESLint and Prettier for code formatting"
    ]
  }
}
```

### 3.2 组织记忆
```json
// ~/.config/claude-code/org-memory.json
{
  "organization": {
    "name": "Acme Corp",
    "standards": {
      "codeStyle": "Airbnb JavaScript Style Guide",
      "gitWorkflow": "GitFlow",
      "cicd": "GitHub Actions",
      "deployment": "AWS ECS"
    },
    "tools": {
      "required": ["ESLint", "Prettier", "Husky"],
      "monitoring": ["Sentry", "DataDog"],
      "testing": ["Jest", "Playwright"]
    },
    "security": {
      "allowedLicenses": ["MIT", "Apache-2.0", "BSD-3-Clause"],
      "scanTools": ["Snyk", "npm audit"]
    }
  }
}
```

### 3.3 更新记忆
```
# 在对话中更新
记住：我们使用 pnpm 而不是 npm
记住：API 端点都以 /api/v1 开头
记住：所有日期使用 ISO 8601 格式
```

### 3.4 查看记忆
```bash
# 查看当前记忆
claude memory show

# 编辑记忆
claude memory edit

# 清除记忆
claude memory clear --project
```

📖 **官方文档**: [Memory](https://code.claude.com/docs/en/memory.md)

---

## 4. Checkpointing（检查点系统）

### 4.1 什么是检查点？
保存对话状态，可以随时恢复。

### 4.2 创建检查点
```
/checkpoint save feature-auth

# 或在关键节点
/checkpoint save before-refactor
/checkpoint save tests-passing
```

### 4.3 管理检查点
```
# 列出所有检查点
/checkpoint list

# 查看检查点详情
/checkpoint info feature-auth

# 删除检查点
/checkpoint delete feature-auth
```

### 4.4 恢复检查点
```
# 恢复到检查点
/checkpoint restore feature-auth

# 或回退
/rewind 10  # 回退10步
```

### 4.5 使用场景
- **实验性修改**: 在尝试前保存
- **里程碑**: 功能完成时保存
- **回滚**: 出错时恢复
- **对比**: 比较不同方案

📖 **官方文档**: [Checkpointing](https://code.claude.com/docs/en/checkpointing.md)

---

## 5. 终端配置

### 5.1 主题配置
```json
// settings.json
{
  "terminal": {
    "theme": "dark",
    "colors": {
      "primary": "#FF6B6B",
      "success": "#51CF66",
      "warning": "#FFD43B",
      "error": "#FF6B6B"
    },
    "font": {
      "family": "JetBrains Mono",
      "size": 14
    }
  }
}
```

### 5.2 通知配置
```json
{
  "notifications": {
    "enabled": true,
    "sound": true,
    "desktop": true,
    "events": [
      "task_complete",
      "error",
      "pr_created"
    ]
  }
}
```

### 5.3 多行输入
```bash
# 启用多行模式
claude config set multiline true

# 使用
> 帮我创建一个函数
> 它应该：
> 1. 接受数组参数
> 2. 过滤偶数
> 3. 返回结果
[Ctrl+D 结束输入]
```

### 5.4 历史搜索
```bash
# 搜索历史
Ctrl+R

# 浏览历史
↑ ↓
```

📖 **官方文档**: [Terminal Config](https://code.claude.com/docs/en/terminal-config.md)

---

## 6. 迁移指南

### 6.1 从其他工具迁移

#### 从 GitHub Copilot
```json
// 导入 Copilot 设置
{
  "import": {
    "source": "copilot",
    "settings": {
      "inlineCompletions": true,
      "autoSuggest": true
    }
  }
}
```

#### 从 Cursor
```bash
# 导出 Cursor 配置
cursor export-config cursor-config.json

# 导入到 Claude Code
claude import-config cursor-config.json
```

### 6.2 升级 TypeScript 项目
```bash
# 自动升级
claude headless "升级项目到 TypeScript 5.0"

# 检查
```

### 6.3 升级 Python 项目
```bash
# 升级到 Python 3.12
claude headless "升级项目到 Python 3.12，更新语法和依赖"
```

📖 **官方文档**: [Migration Guide](https://code.claude.com/docs/en/migration-guide.md)

---

## 7. 性能优化

### 7.1 缓存策略
```json
{
  "cache": {
    "enabled": true,
    "ttl": 3600,
    "maxSize": "1GB",
    "strategy": "lru"
  }
}
```

### 7.2 并行处理
```bash
# 并行执行多个任务
claude --parallel "分析 src/", "运行测试", "生成文档"
```

### 7.3 增量处理
```json
{
  "incremental": {
    "enabled": true,
    "trackChanges": true,
    "onlyProcessChanged": true
  }
}
```

### 7.4 Token 优化
```json
{
  "tokenOptimization": {
    "compressHistory": true,
    "summarizeLongContexts": true,
    "removeRedundancy": true
  }
}
```

---

## 8. 高级工作流

### 8.1 多项目管理
```bash
# 切换项目
claude --project backend
claude --project frontend

# 配置项目
claude project add backend --path /path/to/backend
claude project add frontend --path /path/to/frontend
```

### 8.2 团队协作
```json
// .claude/team.json
{
  "team": {
    "members": [
      {"name": "Alice", "role": "lead", "focus": "architecture"},
      {"name": "Bob", "role": "developer", "focus": "backend"},
      {"name": "Carol", "role": "developer", "focus": "frontend"}
    ],
    "sharedMemory": true,
    "sharedCheckpoints": true
  }
}
```

### 8.3 自动化流程
```yaml
# .claude/workflows/release.yml
name: Release Workflow
trigger: manual
steps:
  - name: Run tests
    command: npm test

  - name: Update version
    command: npm version patch

  - name: Generate changelog
    task: "生成从上次发布以来的变更日志"

  - name: Build
    command: npm run build

  - name: Create PR
    task: "创建发布 PR"
```

---

## 9. 调试技巧

### 9.1 详细日志
```bash
# 启用调试模式
claude --debug

# 指定日志级别
claude --log-level trace

# 输出到文件
claude --log-file debug.log
```

### 9.2 工具调用追踪
```bash
# 查看工具调用
claude --trace-tools

# 输出示例：
# [Tool] Read src/index.ts
# [Tool] Edit src/index.ts
# [Tool] Bash npm test
```

### 9.3 性能分析
```bash
# 启用性能分析
claude --profile

# 查看报告
claude profile report
```

---

## 10. 高级配置示例

### 10.1 完整的企业配置
```json
{
  "provider": "bedrock",
  "model": "claude-3-5-sonnet-20240620",
  "modelAliases": {
    "default": "claude-3-5-sonnet-20240620",
    "fast": "claude-3-haiku-20240307"
  },
  "security": {
    "sandbox": {
      "enabled": true,
      "filesystem": {
        "readonly": ["/usr", "/etc"],
        "readwrite": ["./workspace"]
      }
    },
    "allowedTools": ["Read", "Edit", "Bash"],
    "deniedPatterns": ["rm -rf", "sudo"]
  },
  "audit": {
    "enabled": true,
    "logPath": "/var/log/claude-code"
  },
  "hooks": {
    "file-write-hook": "./hooks/format.sh",
    "bash-hook": "./hooks/security-check.sh"
  },
  "memory": {
    "enabled": true,
    "path": "./.claude/memory.json"
  },
  "monitoring": {
    "enabled": true,
    "metrics": ["usage", "costs", "errors"],
    "alerts": {
      "dailyCost": 100,
      "errorRate": 0.05
    }
  }
}
```

---

## 11. 故障排查

### 11.1 常见问题

#### 性能慢
```bash
# 检查缓存
claude cache stats

# 清除缓存
claude cache clear

# 检查网络
claude network test
```

#### 内存问题
```bash
# 检查内存使用
claude stats memory

# 减少上下文窗口
claude config set maxTokens 50000
```

#### 工具失败
```bash
# 检查工具权限
claude tools check

# 测试工具
claude tools test Read
```

---

## 12. 实验性功能

### 12.1 启用实验性功能
```json
{
  "experimental": {
    "multimodalInput": true,
    "voiceInput": false,
    "collaborativeEdit": true
  }
}
```

### 12.2 Beta 功能
查看可用的 beta 功能：
```bash
claude beta list
```

启用 beta 功能：
```bash
claude beta enable feature-name
```

---

## 13. 扩展开发

### 13.1 创建工具
```typescript
// custom-tool.ts
import { Tool } from '@anthropic/claude-code-sdk';

export const myTool: Tool = {
  name: 'my-tool',
  description: '自定义工具',
  parameters: {
    input: 'string'
  },
  handler: async (params) => {
    // 实现逻辑
    return { result: 'success' };
  }
};
```

### 13.2 注册工具
```json
{
  "customTools": [
    "./tools/my-tool.ts"
  ]
}
```

---

## 下一步

查看 [最佳实践](../07-best-practices/) 以优化你的工作流程！
