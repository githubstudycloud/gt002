# Claude Code 最佳实践

本目录总结使用 Claude Code 的最佳实践、技巧和经验。

---

## 1. 提示词工程

### 1.1 清晰具体的指令

#### ❌ 不好的例子
```
帮我改一下这个
测试一下
优化代码
```

#### ✅ 好的例子
```
在 src/utils/validation.ts 中的 validateEmail 函数添加对国际域名的支持

为 UserService 类的所有公共方法编写 Jest 单元测试

重构 calculateDiscount 函数，使用策略模式替代 if-else 链
```

### 1.2 提供足够的上下文

#### ❌ 缺少上下文
```
创建一个登录表单
```

#### ✅ 包含上下文
```
创建一个 React 登录表单组件：
- 使用 TypeScript
- 使用 React Hook Form 进行表单管理
- 使用 Zod 进行验证
- 包含邮箱和密码字段
- 有记住我的选项
- 样式使用 TailwindCSS
- 集成我们现有的 auth API
```

### 1.3 分步骤的复杂任务

#### ❌ 过于复杂
```
创建一个完整的电商购物车系统
```

#### ✅ 分解步骤
```
第一步：创建购物车的数据模型和类型定义
第二步：实现添加、删除、更新商品的功能
第三步：创建 React 组件显示购物车
第四步：添加价格计算和折扣逻辑
第五步：编写单元测试
```

### 1.4 使用示例

#### ✅ 提供示例格式
```
生成 API 文档，使用以下格式：

## Endpoint: /api/users
**Method**: GET
**Description**: 获取用户列表
**Parameters**:
- page (optional): 页码
- limit (optional): 每页数量
**Response**:
```json
{
  "users": [...],
  "total": 100
}
```
```

---

## 2. 代码质量

### 2.1 一致的代码风格

#### 配置格式化
```json
// .claude/hooks/format.sh
#!/bin/bash
prettier --write "$1"
eslint --fix "$1"
```

#### 使用 hooks
```json
// settings.json
{
  "hooks": {
    "file-write-hook": "./.claude/hooks/format.sh {file}",
    "file-edit-hook": "./.claude/hooks/format.sh {file}"
  }
}
```

### 2.2 代码审查清单

创建自定义命令：
```markdown
<!-- .claude/commands/review.md -->
# 代码审查

请审查最近的变更，检查：

1. **代码质量**
   - 是否遵循项目编码规范
   - 是否有代码重复
   - 是否有潜在的 bug

2. **性能**
   - 是否有性能问题
   - 是否有不必要的计算
   - 是否正确使用缓存

3. **安全**
   - 是否有 SQL 注入风险
   - 是否有 XSS 漏洞
   - 是否正确处理用户输入

4. **测试**
   - 是否有足够的测试覆盖
   - 测试是否有意义
   - 边界情况是否被测试

5. **文档**
   - 是否有必要的注释
   - API 文档是否更新
   - README 是否需要更新
```

### 2.3 测试驱动开发

#### 工作流程
```
1. 描述功能需求
2. 让 Claude Code 编写测试
3. 运行测试（应该失败）
4. 让 Claude Code 实现功能
5. 运行测试（应该通过）
6. 重构代码
7. 再次运行测试
```

#### 示例
```
# 第一步：编写测试
为 calculateShipping 函数编写测试，包括：
- 免费配送（订单 > $50）
- 标准配送（$5.99）
- 加急配送（$12.99）
- 国际配送（$25）

# 第二步：实现功能
现在实现 calculateShipping 函数，使所有测试通过

# 第三步：重构
重构 calculateShipping，使用配置对象而不是硬编码值
```

---

## 3. 项目组织

### 3.1 项目记忆配置

创建详细的项目记忆：
```json
// .claude/memory.json
{
  "project": {
    "name": "MyApp",
    "type": "web-application",

    "techStack": {
      "frontend": {
        "framework": "React 18",
        "language": "TypeScript 5.0",
        "styling": "TailwindCSS + CSS Modules",
        "stateManagement": "Zustand",
        "routing": "React Router v6",
        "forms": "React Hook Form + Zod"
      },
      "backend": {
        "runtime": "Node.js 20",
        "framework": "Express 4",
        "database": "PostgreSQL 15",
        "orm": "Prisma",
        "auth": "Passport.js + JWT"
      },
      "testing": {
        "unit": "Vitest",
        "integration": "Supertest",
        "e2e": "Playwright",
        "coverage": "minimum 80%"
      }
    },

    "structure": {
      "type": "feature-based",
      "description": "Each feature has its own directory with components, hooks, utils, types"
    },

    "conventions": {
      "naming": {
        "files": "kebab-case",
        "components": "PascalCase",
        "hooks": "use + PascalCase",
        "utils": "camelCase",
        "constants": "UPPER_SNAKE_CASE"
      },
      "imports": {
        "order": ["external", "internal", "relative"],
        "alias": "@/ for src directory"
      },
      "commits": {
        "format": "conventional commits",
        "examples": ["feat:", "fix:", "docs:", "refactor:", "test:"]
      }
    },

    "rules": [
      "Always use TypeScript strict mode",
      "No any types unless absolutely necessary",
      "All components must be functional components with hooks",
      "Props must have TypeScript interfaces",
      "All API calls must use React Query",
      "Error boundaries for all route components",
      "Loading states for all async operations",
      "Accessibility: all interactive elements must be keyboard accessible",
      "Responsive design: mobile-first approach"
    ],

    "patterns": {
      "api": "RESTful with /api/v1 prefix",
      "errorHandling": "Custom error classes + error boundary",
      "authentication": "JWT in httpOnly cookies",
      "authorization": "Role-based access control (RBAC)"
    }
  }
}
```

### 3.2 .claude 目录结构

```
.claude/
├── memory.json              # 项目记忆
├── commands/                # 自定义命令
│   ├── feature.md          # 新功能开发流程
│   ├── review.md           # 代码审查
│   ├── release.md          # 发布流程
│   └── test.md             # 测试流程
├── hooks/                   # 钩子脚本
│   ├── format.sh           # 格式化
│   ├── lint.sh             # 代码检查
│   └── security.sh         # 安全检查
├── plugins/                 # 插件
│   └── team-tools/
├── skills/                  # 技能
│   ├── deploy.ts
│   └── analytics.ts
├── agents/                  # 自定义代理
│   └── security-reviewer.json
└── output-styles/          # 输出样式
    └── team-style.json
```

---

## 4. 团队协作

### 4.1 共享配置

#### 提交 .claude 到版本控制
```gitignore
# .gitignore

# 保留共享配置
!.claude/memory.json
!.claude/commands/
!.claude/hooks/
!.claude/plugins/

# 但排除个人配置
.claude/personal/
.claude/history/
```

### 4.2 团队约定

创建团队文档：
```markdown
<!-- .claude/TEAM_GUIDE.md -->
# Claude Code 团队使用指南

## 常用命令

- `/review`: 代码审查当前变更
- `/feature <name>`: 开始新功能开发
- `/test`: 运行测试并修复失败
- `/deploy <env>`: 部署到指定环境

## 工作流程

### 1. 开始新功能
```
/feature user-profile
```

### 2. 开发过程
- 小步提交
- 编写测试
- 定期运行 `/review`

### 3. 完成功能
```
/test
git commit
/review
创建 PR
```

## 最佳实践

1. **保持上下文清晰**: 每次对话开始时，简要说明你在做什么
2. **使用检查点**: 重要节点保存检查点
3. **遵循记忆中的规则**: 项目约定已配置在 memory.json 中
4. **共享有用的命令**: 发现好用的命令添加到 .claude/commands/
```

---

## 5. 性能优化

### 5.1 减少 Token 使用

#### 使用 Sub-agents
```
# 不好：在主对话中搜索
帮我找出所有使用旧 API 的地方

# 好：使用专门的代理
使用 Explore 代理找出所有使用旧 API 的地方
```

#### 总结长对话
```
请总结我们刚才的讨论和所做的变更
```

### 5.2 并行操作

#### ❌ 串行
```
读取 package.json
读取 tsconfig.json
读取 .eslintrc
运行 git status
```

#### ✅ 并行
```
同时执行：
1. 读取 package.json
2. 读取 tsconfig.json
3. 读取 .eslintrc
4. 运行 git status
```

### 5.3 缓存利用

```json
{
  "cache": {
    "enabled": true,
    "ttl": 3600
  }
}
```

---

## 6. 安全最佳实践

### 6.1 敏感信息

#### ❌ 不要做
```
我的 API 密钥是 sk-ant-xxxxx
数据库密码是 password123
```

#### ✅ 应该做
```
请帮我配置环境变量来存储 API 密钥
创建 .env.example 文件展示需要的环境变量
```

### 6.2 代码审查

创建安全检查命令：
```markdown
<!-- .claude/commands/security-check.md -->
# 安全检查

审查最近的变更，检查：

1. 是否有硬编码的密钥或密码
2. 是否正确验证用户输入
3. 是否有 SQL 注入风险
4. 是否有 XSS 漏洞
5. 是否正确处理错误（不泄露敏感信息）
6. 是否使用安全的依赖版本
7. 是否有不安全的文件操作
8. 是否正确设置 CORS
```

### 6.3 依赖管理

```
检查 package.json 中的依赖是否有已知漏洞
运行 npm audit 并修复问题
更新所有依赖到安全版本
```

---

## 7. 调试技巧

### 7.1 问题诊断

#### 系统化方法
```
1. 描述问题：发生了什么？
2. 预期行为：应该发生什么？
3. 重现步骤：如何触发问题？
4. 环境信息：版本、配置等
5. 相关日志：错误消息、堆栈跟踪
```

#### 示例
```
我在运行 npm test 时遇到错误。

错误信息：
```
TypeError: Cannot read property 'name' of undefined
  at UserService.getUser (src/services/user.ts:42)
```

预期：应该返回用户对象或 null

重现步骤：
1. 创建新用户
2. 调用 getUser(userId)
3. 错误发生

相关代码：src/services/user.ts
```

### 7.2 逐步调试

```
# 第一步：理解问题
解释这个错误是什么意思

# 第二步：定位问题
找出导致这个错误的代码行

# 第三步：分析原因
为什么会出现这个问题？

# 第四步：提出方案
有哪些修复方案？

# 第五步：实施修复
使用最佳方案修复问题

# 第六步：验证
添加测试确保问题已解决
```

---

## 8. 文档实践

### 8.1 代码注释

#### ✅ 好的注释
```typescript
/**
 * 计算用户的配送费用
 *
 * 免费配送条件：订单金额 >= $50
 *
 * @param orderAmount - 订单总金额（美元）
 * @param shippingSpeed - 配送速度 ('standard' | 'express' | 'international')
 * @returns 配送费用（美元）
 *
 * @example
 * calculateShipping(60, 'standard') // 返回 0（免费配送）
 * calculateShipping(30, 'express') // 返回 12.99
 */
function calculateShipping(orderAmount: number, shippingSpeed: string): number {
  // 实现...
}
```

#### ❌ 无用的注释
```typescript
// 这个函数计算配送费用
function calculateShipping() {
  // 如果订单金额大于50
  if (amount > 50) {
    // 返回0
    return 0;
  }
}
```

### 8.2 README 结构

```markdown
# 项目名称

简短描述（一句话）

## 功能特性

- 特性 1
- 特性 2
- 特性 3

## 技术栈

- 前端：React + TypeScript
- 后端：Node.js + Express
- 数据库：PostgreSQL

## 快速开始

```bash
# 安装依赖
npm install

# 运行开发服务器
npm run dev

# 运行测试
npm test
```

## 项目结构

```
src/
├── components/
├── services/
├── utils/
└── types/
```

## 配置

详见 `.env.example`

## 贡献指南

详见 `CONTRIBUTING.md`

## 许可证

MIT
```

---

## 9. 持续改进

### 9.1 学习和反思

#### 每周回顾
```
回顾本周的开发工作：
1. 列出完成的主要功能
2. 识别遇到的问题和解决方案
3. 总结学到的技巧
4. 提出改进建议
```

#### 保存有用的模式
```
将这个解决方案保存到项目记忆中，
以便将来遇到类似问题时参考
```

### 9.2 优化工作流程

#### 识别重复任务
```
分析过去30天的 git log，
识别重复的任务类型
```

#### 创建自动化
```
为这些重复任务创建自定义命令或 hooks
```

---

## 10. 常见陷阱

### 10.1 避免的错误

#### ❌ 过度依赖
不要完全不理解就接受代码。
始终审查和理解生成的代码。

#### ❌ 忽视错误
不要忽略警告和错误消息。
让 Claude Code 解释并修复它们。

#### ❌ 缺少测试
不要跳过测试。
始终为重要功能编写测试。

#### ❌ 不清晰的指令
不要给出模糊的指令。
提供具体、详细的要求。

### 10.2 最佳方法

#### ✅ 迭代开发
小步前进，频繁测试。

#### ✅ 保持上下文
使用检查点保存重要状态。

#### ✅ 文档化
记录重要决策和约定。

#### ✅ 代码审查
定期审查生成的代码。

---

## 11. 效率提升

### 11.1 快捷工作流

#### 功能开发模板
```markdown
<!-- .claude/commands/quick-feature.md -->
开发新功能 {feature_name}:

1. 在 .claude/memory.json 中记录功能需求
2. 创建功能分支: git checkout -b feature/{feature_name}
3. 创建必要的文件结构
4. 编写测试（TDD）
5. 实现功能
6. 运行所有测试
7. 更新文档
8. 创建 commit
9. 询问是否创建 PR
```

### 11.2 自动化检查

#### Pre-commit Hook
```bash
#!/bin/bash
# .claude/hooks/pre-commit.sh

echo "运行 pre-commit 检查..."

# 运行测试
if ! npm test; then
  echo "❌ 测试失败"
  exit 1
fi

# 运行 lint
if ! npm run lint; then
  echo "❌ Lint 检查失败"
  exit 1
fi

# 检查类型
if ! npm run type-check; then
  echo "❌ 类型检查失败"
  exit 1
fi

echo "✅ 所有检查通过"
exit 0
```

---

## 12. 资源链接

- [官方最佳实践](https://code.claude.com/docs/en/best-practices)
- [社区示例](../08-community-resources/)
- [常见问题解答](../01-getting-started/)

---

**记住**: Claude Code 是工具，你是开发者。
保持批判性思维，理解你的代码，持续学习和改进！
