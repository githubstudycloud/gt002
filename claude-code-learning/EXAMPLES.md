# Claude Code 实战示例

本文档包含各种实际使用场景的详细示例。

---

## 目录

1. [Web 开发](#1-web-开发)
2. [API 开发](#2-api-开发)
3. [数据库操作](#3-数据库操作)
4. [测试自动化](#4-测试自动化)
5. [DevOps 和部署](#5-devops-和部署)
6. [代码重构](#6-代码重构)
7. [Bug 修复](#7-bug-修复)
8. [文档生成](#8-文档生成)
9. [CI/CD 集成](#9-cicd-集成)
10. [团队协作](#10-团队协作)

---

## 1. Web 开发

### 示例 1.1: 创建 React 登录表单

**提示词**:
```
创建一个 React 登录表单组件，要求：

1. 使用 TypeScript
2. 使用 React Hook Form 进行表单管理
3. 使用 Zod 进行表单验证
4. 包含以下字段：
   - 邮箱（必填，格式验证）
   - 密码（必填，最少8位）
   - 记住我（复选框）
5. 显示验证错误消息
6. 提交按钮在验证通过前禁用
7. 样式使用 TailwindCSS
8. 包含 loading 状态
9. 错误处理
```

**Claude 会创建**:
- `LoginForm.tsx` - 完整的组件
- `loginSchema.ts` - Zod 验证模式
- `LoginForm.test.tsx` - 单元测试
- `LoginForm.stories.tsx` - Storybook 故事（可选）

---

### 示例 1.2: 添加深色模式

**提示词**:
```
为应用添加深色模式支持：

1. 使用 Context API 管理主题状态
2. 主题切换按钮（太阳/月亮图标）
3. 保存用户选择到 localStorage
4. 支持系统偏好检测
5. 平滑过渡动画
6. 更新所有组件的样式
```

---

## 2. API 开发

### 示例 2.1: 创建 RESTful API 端点

**提示词**:
```
创建用户注册的 API 端点：

技术栈：
- Node.js + Express
- PostgreSQL + Prisma
- JWT 认证
- bcrypt 密码哈希

要求：
1. POST /api/v1/auth/register
2. 验证输入（邮箱、密码、姓名）
3. 检查邮箱是否已存在
4. 哈希密码
5. 创建用户记录
6. 生成 JWT token
7. 返回用户信息（不包含密码）
8. 错误处理
9. 添加 rate limiting
10. 编写集成测试
```

---

### 示例 2.2: 添加 API 文档

**提示词**:
```
使用 Swagger/OpenAPI 为现有 API 添加文档：

1. 设置 swagger-jsdoc
2. 为所有端点添加 JSDoc 注释
3. 定义数据模型
4. 添加请求/响应示例
5. 配置 Swagger UI
6. 添加认证说明
```

---

## 3. 数据库操作

### 示例 3.1: Prisma Schema 设计

**提示词**:
```
设计电商平台的数据库模型：

实体：
- User（用户）
- Product（产品）
- Category（分类）
- Order（订单）
- OrderItem（订单项）
- Review（评价）

关系：
- 用户有多个订单
- 订单包含多个订单项
- 产品属于一个分类
- 产品有多个评价
- 评价属于一个用户

额外要求：
- 添加时间戳
- 软删除
- 索引优化
```

---

### 示例 3.2: 数据迁移

**提示词**:
```
创建 Prisma 迁移，为 User 表添加：
1. avatarUrl 字段（可选）
2. emailVerified 布尔字段（默认 false）
3. lastLoginAt 时间戳
4. 为 email 添加唯一索引

然后更新相关的 TypeScript 类型和 API 端点。
```

---

## 4. 测试自动化

### 示例 4.1: 单元测试套件

**提示词**:
```
为 src/utils/cart.ts 的所有函数编写 Jest 测试：

函数：
- addToCart
- removeFromCart
- updateQuantity
- calculateTotal
- applyDiscount

要求：
- 测试正常情况
- 测试边界情况
- 测试错误处理
- 使用 describe 和 it 组织测试
- 达到 100% 代码覆盖率
```

---

### 示例 4.2: E2E 测试

**提示词**:
```
使用 Playwright 创建用户注册流程的 E2E 测试：

场景：
1. 访问注册页面
2. 填写表单（邮箱、密码、确认密码）
3. 提交表单
4. 验证成功消息
5. 验证重定向到仪表板
6. 验证用户信息显示

额外测试：
- 无效邮箱格式
- 密码不匹配
- 已存在的邮箱
- 网络错误
```

---

## 5. DevOps 和部署

### 示例 5.1: Docker 配置

**提示词**:
```
为 Node.js + React 应用创建 Docker 配置：

要求：
1. 多阶段构建
2. 前端构建阶段
3. 后端运行阶段
4. 生产优化
5. 健康检查
6. 环境变量配置
7. Docker Compose 文件（包含数据库）
8. .dockerignore 文件
```

---

### 示例 5.2: Kubernetes 部署

**提示词**:
```
创建 Kubernetes 部署配置：

包含：
1. Deployment（3个副本）
2. Service（LoadBalancer）
3. ConfigMap（环境变量）
4. Secret（敏感信息）
5. Ingress（HTTPS）
6. HorizontalPodAutoscaler
7. PersistentVolumeClaim
```

---

## 6. 代码重构

### 示例 6.1: 应用设计模式

**提示词**:
```
重构 src/services/payment.ts：

当前问题：
- 巨大的 if-else 链处理不同支付方式
- 难以添加新的支付方式
- 测试困难

要求：
1. 使用策略模式
2. 每个支付方式一个策略类
3. 支付方式：信用卡、PayPal、Apple Pay
4. 易于扩展
5. 更新相关测试
```

---

### 示例 6.2: 提取可复用逻辑

**提示词**:
```
分析 src/components/ 目录，找出重复的逻辑：

1. 识别重复代码
2. 提取为自定义 hooks 或工具函数
3. 更新所有使用的地方
4. 保持功能不变
5. 添加测试
```

---

## 7. Bug 修复

### 示例 7.1: 调试错误

**提示词**:
```
我遇到这个错误：

```
TypeError: Cannot read properties of undefined (reading 'map')
    at ProductList (src/components/ProductList.tsx:25:15)
```

代码：
```tsx
function ProductList() {
  const { data } = useQuery(['products'], fetchProducts);

  return (
    <div>
      {data.products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

请：
1. 解释错误原因
2. 提供修复方案
3. 添加 loading 和 error 状态
4. 添加空状态处理
```

---

### 示例 7.2: 性能问题

**提示词**:
```
Dashboard 组件渲染很慢（3秒+）

分析性能问题：
1. 使用 React DevTools Profiler 分析
2. 识别不必要的重新渲染
3. 优化建议
4. 实施优化：
   - useMemo
   - useCallback
   - React.memo
   - 虚拟化长列表
5. 验证改进
```

---

## 8. 文档生成

### 示例 8.1: API 文档

**提示词**:
```
生成 API 端点文档：

端点：
- GET /api/v1/products
- GET /api/v1/products/:id
- POST /api/v1/products
- PUT /api/v1/products/:id
- DELETE /api/v1/products/:id

格式：
- Markdown
- 包含请求/响应示例
- 参数说明
- 错误代码
- 认证要求
```

---

### 示例 8.2: 组件文档

**提示词**:
```
为 src/components/ 中的所有组件生成 Storybook 故事：

要求：
1. 基本用法
2. 所有 props 变体
3. 交互状态
4. 边界情况
5. 可访问性测试
```

---

## 9. CI/CD 集成

### 示例 9.1: GitHub Actions 工作流

**提示词**:
```
创建 GitHub Actions 工作流：

触发条件：
- Pull Request
- Push to main

步骤：
1. 检出代码
2. 设置 Node.js
3. 安装依赖
4. 运行 linter
5. 运行类型检查
6. 运行测试（生成覆盖率）
7. 构建
8. 部署到 Vercel（仅 main 分支）
9. 发送通知

要求：
- 缓存依赖
- 并行执行
- 上传构件
```

---

### 示例 9.2: 自动代码审查

**提示词**:
```
创建 GitHub Action，使用 Claude Code 自动审查 PR：

检查：
1. 代码质量
2. 测试覆盖率
3. 安全问题
4. 性能问题
5. 最佳实践

要求：
- 发布审查评论
- 根据问题严重程度设置状态
- 生成审查摘要
```

---

## 10. 团队协作

### 示例 10.1: 项目设置

**提示词**:
```
为新项目设置完整的开发环境：

包含：
1. package.json（依赖、脚本）
2. tsconfig.json
3. .eslintrc.js
4. .prettierrc
5. .gitignore
6. .env.example
7. README.md
8. CONTRIBUTING.md
9. .claude/memory.json（项目约定）
10. .claude/commands/（常用命令）
11. pre-commit hooks（Husky）
```

---

### 示例 10.2: 代码审查模板

**提示词**:
```
创建 .claude/commands/review.md：

审查清单：
1. 代码质量
   - 可读性
   - 可维护性
   - 遵循项目规范
2. 功能
   - 符合需求
   - 边界情况处理
3. 测试
   - 足够的覆盖率
   - 有意义的测试
4. 性能
   - 无明显瓶颈
   - 优化建议
5. 安全
   - 无安全漏洞
   - 输入验证
6. 文档
   - 代码注释
   - API 文档更新
```

---

## 实用提示

### 组合使用

可以链式执行多个任务：

```
1. 首先创建 User API 端点
2. 然后编写测试
3. 添加 API 文档
4. 更新 Swagger
5. 创建 commit
6. 创建 PR
```

### 使用检查点

在关键步骤保存：

```
/checkpoint save before-refactor
[进行重构]
/checkpoint save after-refactor
```

### 迭代改进

```
创建基本版本 → 测试 → 获取反馈 → 改进 → 重复
```

---

## 更多示例

查看：
- [GitHub 示例仓库](https://github.com/anthropics/claude-code-examples)
- [社区示例](./08-community-resources/)
- [官方文档](https://code.claude.com/docs/en/common-workflows.md)

---

**提示**: 根据你的具体需求调整这些示例。
复制、修改、实验 - 找到最适合你的工作流程！
