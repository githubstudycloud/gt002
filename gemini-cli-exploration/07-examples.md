# Gemini CLI 实用示例

## 1. Web 开发示例

### 示例 1.1: 创建 REST API

```bash
gemini -i "创建一个 Express.js REST API，包含:
- 用户认证（JWT）
- CRUD 操作
- 错误处理中间件
- 输入验证
- API 文档（Swagger）

使用 TypeScript 和最佳实践。"
```

### 示例 1.2: React 组件开发

```bash
gemini -p "
创建一个 React 数据表格组件，包含:
- 排序功能
- 搜索/过滤
- 分页
- 响应式设计
- TypeScript 类型
- 单元测试（React Testing Library）

参考设计: @./table-design.png
"
```

### 示例 1.3: 修复前端 Bug

```bash
gemini -p "
用户报告的 Bug: 表单提交后没有反馈

错误截图: @./bug-screenshot.png

相关代码: @./src/components/ContactForm.jsx

请:
1. 分析问题
2. 修复 bug
3. 添加适当的错误处理和用户反馈
4. 添加测试防止回归
"
```

## 2. 后端开发示例

### 示例 2.1: 数据库优化

```bash
gemini -p "
分析并优化数据库性能:

慢查询日志: @./slow-queries.log

数据库架构: @./schema.sql

请:
1. 识别性能瓶颈
2. 建议索引策略
3. 优化查询
4. 提供迁移脚本
"
```

### 示例 2.2: 微服务创建

```bash
gemini -p "
创建一个订单处理微服务:

要求:
- Node.js + Express
- PostgreSQL 数据库
- Redis 缓存
- RabbitMQ 消息队列
- Docker 容器化
- 健康检查端点
- 监控和日志

生成完整的项目结构和代码。
"
```

### 示例 2.3: API 安全审计

```bash
gemini -p "
审计 API 安全性:

API 代码: @./src/api/

关注:
1. SQL 注入
2. XSS 攻击
3. CSRF 防护
4. 认证/授权漏洞
5. 敏感数据泄露
6. 速率限制

生成详细的安全报告和修复建议。
"
```

## 3. DevOps 和自动化示例

### 示例 3.1: CI/CD Pipeline

```bash
gemini -p "
创建完整的 CI/CD pipeline（GitHub Actions）:

要求:
1. 运行测试（单元、集成、E2E）
2. 代码质量检查（ESLint, Prettier）
3. 安全扫描（npm audit, Snyk）
4. 构建 Docker 镜像
5. 部署到 Kubernetes
6. 自动回滚（如果失败）

项目技术栈: @./package.json
"
```

### 示例 3.2: Docker 配置优化

```bash
gemini -p "
优化 Docker 配置:

当前 Dockerfile: @./Dockerfile
当前 docker-compose: @./docker-compose.yml

优化目标:
1. 减小镜像大小
2. 提高构建速度
3. 多阶段构建
4. 安全最佳实践
5. 缓存优化

提供优化后的配置和说明。
"
```

### 示例 3.3: 监控和告警

```bash
gemini -p "
设置应用监控和告警:

技术栈: Node.js, Express, PostgreSQL, Redis

需要监控:
1. 应用性能（响应时间、错误率）
2. 服务器资源（CPU、内存、磁盘）
3. 数据库性能
4. API 端点健康
5. 自定义业务指标

使用 Prometheus + Grafana
提供配置文件和仪表板 JSON
"
```

## 4. 测试示例

### 示例 4.1: 生成单元测试

```bash
gemini -p "
为这个模块生成完整的单元测试:

代码: @./src/services/payment.js

要求:
- Jest 框架
- 覆盖所有函数
- 测试正常和异常情况
- 使用适当的 mock
- 测试覆盖率 > 90%
"
```

### 示例 4.2: E2E 测试套件

```bash
gemini -p "
创建 E2E 测试套件:

应用: 电商网站
工具: Playwright

测试场景:
1. 用户注册和登录
2. 浏览商品
3. 添加到购物车
4. 结账流程
5. 订单确认

包含适当的等待和断言。
"
```

### 示例 4.3: 修复失败的测试

```bash
npm test 2>&1 | gemini -p "
测试失败了，请:
1. 分析失败原因
2. 修复代码或测试
3. 确保所有测试通过
"
```

## 5. 代码重构示例

### 示例 5.1: 清理遗留代码

```bash
gemini --checkpointing -p "
重构这个遗留模块:

代码: @./src/legacy/order-processor.js

目标:
1. 提高可读性
2. 拆分大函数
3. 消除重复代码
4. 添加类型注解
5. 添加文档
6. 保持向后兼容

运行测试验证: npm test
"
```

### 示例 5.2: 迁移到新架构

```bash
gemini -p "
将这个模块从类组件迁移到函数组件:

代码: @./src/components/Dashboard.jsx

要求:
1. 使用 React Hooks
2. 保持相同功能
3. 优化性能（useMemo, useCallback）
4. 更新测试
5. 更新 PropTypes 为 TypeScript
"
```

### 示例 5.3: 性能优化

```bash
gemini -p "
优化这个模块的性能:

代码: @./src/utils/data-processor.js
性能分析: @./profiling-results.txt

问题:
- 处理大数据集时很慢
- 内存使用高

请:
1. 识别瓶颈
2. 实施优化
3. 添加性能测试
4. 记录改进结果
"
```

## 6. 文档生成示例

### 示例 6.1: API 文档

```bash
gemini -p "
为 API 生成 OpenAPI (Swagger) 文档:

API 路由: @./src/routes/
API 控制器: @./src/controllers/

包含:
- 所有端点
- 请求/响应示例
- 认证说明
- 错误代码
"
```

### 示例 6.2: README 生成

```bash
gemini -p "
为这个项目生成全面的 README.md:

项目代码: @./

包含:
- 项目描述
- 功能列表
- 安装说明
- 使用示例
- API 文档
- 贡献指南
- 许可证信息
"
```

### 示例 6.3: 代码注释

```bash
gemini -p "
为这些文件添加详细的注释:

文件: @./src/core/

要求:
- JSDoc 格式
- 函数描述
- 参数说明
- 返回值说明
- 使用示例
- 注意事项
"
```

## 7. 数据库相关示例

### 示例 7.1: 数据库设计

```bash
gemini -p "
设计数据库架构:

需求: @./requirements.md

创建:
1. ER 图（文本描述）
2. SQL 建表语句（PostgreSQL）
3. 索引策略
4. 关系定义
5. 示例查询
"
```

### 示例 7.2: 数据迁移

```bash
gemini -p "
创建数据库迁移:

从: @./old-schema.sql
到: @./new-schema.sql

要求:
1. 保留所有现有数据
2. 处理外键约束
3. 创建向上和向下迁移
4. 添加回滚策略
5. 包含测试数据验证
"
```

### 示例 7.3: 查询优化

```bash
gemini -p "
优化这些慢查询:

查询: @./slow-queries.sql
执行计划: @./explain-output.txt
表结构: @./schema.sql

提供:
1. 优化后的查询
2. 建议的索引
3. 性能对比
4. 实施步骤
"
```

## 8. GitHub 工作流示例

### 示例 8.1: 自动 PR 审查

```bash
# 配置 GitHub MCP
gemini

> 审查 PR #123 在仓库 user/repo

> 关注:
> - 代码质量
> - 测试覆盖
> - 安全问题
> - 性能影响
>
> 在 PR 上添加审查评论
```

### 示例 8.2: Issue 分类

```bash
gemini -p "
分析和分类这些 GitHub issues:

仓库: user/repo
Issues: 最近 20 个未分类的

对每个 issue:
1. 添加适当的标签（bug, feature, docs, etc.）
2. 设置优先级
3. 如果信息不足，请求更多细节
4. 分配给合适的团队成员（如果明确）
"
```

### 示例 8.3: 发布自动化

```bash
gemini -p "
准备新版本发布:

当前版本: @./package.json
变更: git log v1.0.0..HEAD

生成:
1. CHANGELOG.md 条目
2. 发布说明
3. 版本号建议（语义化版本）
4. 迁移指南（如果有破坏性更改）
5. GitHub Release 草稿
"
```

## 9. 机器学习相关示例

### 示例 9.1: 数据预处理

```bash
gemini -p "
创建数据预处理管道:

原始数据: @./raw-data.csv

处理步骤:
1. 清洗数据（缺失值、异常值）
2. 特征工程
3. 标准化/归一化
4. 数据划分（训练/验证/测试）
5. 生成统计报告

使用 Python + pandas + scikit-learn
"
```

### 示例 9.2: 模型评估

```bash
gemini -p "
评估模型性能:

模型: @./model.py
测试数据: @./test-data.csv
预测结果: @./predictions.csv

生成:
1. 性能指标（准确率、精确率、召回率等）
2. 混淆矩阵
3. ROC 曲线代码
4. 错误分析
5. 改进建议
"
```

## 10. 移动开发示例

### 示例 10.1: React Native 组件

```bash
gemini -p "
创建 React Native 用户配置屏幕:

要求:
- 用户信息编辑
- 头像上传
- 表单验证
- iOS 和 Android 样式
- 无障碍支持
- 单元测试

UI 参考: @./profile-screen-mockup.png
"
```

### 示例 10.2: 离线功能

```bash
gemini -p "
实现离线优先功能:

应用: 新闻阅读 app
平台: React Native

功能:
1. 本地数据缓存（AsyncStorage）
2. 离线队列（网络恢复后同步）
3. 冲突解决策略
4. 离线指示器
5. 后台同步
"
```

## 11. 安全相关示例

### 示例 11.1: 安全审计

```bash
gemini -p "
执行安全审计:

代码库: @./

检查:
1. 依赖项漏洞
2. 代码注入风险
3. 认证/授权问题
4. 敏感数据处理
5. 加密实现
6. API 安全

生成详细报告和修复优先级。
"
```

### 示例 11.2: 实现 OAuth 2.0

```bash
gemini -p "
实现 OAuth 2.0 认证:

提供商: Google, GitHub
框架: Express.js

功能:
1. 授权码流程
2. Token 管理（访问和刷新）
3. 用户会话
4. 安全最佳实践
5. 错误处理

包含完整代码和配置说明。
"
```

## 12. 性能分析示例

### 示例 12.1: 前端性能优化

```bash
gemini -p "
优化前端性能:

应用: @./src/
Lighthouse 报告: @./lighthouse-report.json

优化:
1. 代码分割
2. 懒加载
3. 图片优化
4. 缓存策略
5. CSS/JS 最小化
6. 字体优化

目标: Lighthouse 分数 > 90
"
```

### 示例 12.2: 后端性能分析

```bash
gemini -p "
分析和优化后端性能:

应用: @./src/
性能分析: @./profiling-results.json
日志: @./slow-requests.log

识别:
1. 慢端点
2. N+1 查询问题
3. 内存泄漏
4. 阻塞操作

提供优化方案和实施代码。
"
```

## 13. 实际工作流完整示例

### 示例 13.1: 完整的功能开发流程

```bash
#!/bin/bash
# feature-workflow.sh

FEATURE="user-profile-page"

echo "=== 功能开发工作流: $FEATURE ==="

# 1. 创建分支
git checkout -b feature/$FEATURE

# 2. 生成实施计划
echo "生成计划..."
gemini -p "
功能需求: @./requirements/$FEATURE.md
UI 设计: @./$FEATURE-design.png

生成详细的实施计划，包括:
1. 组件结构
2. API 端点设计
3. 数据库更改
4. 测试策略
5. 时间估算
" > $FEATURE-plan.md

# 3. 审查计划
echo "请审查 $FEATURE-plan.md"
read -p "继续实施？(y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# 4. 实施功能
echo "实施功能..."
gemini --checkpointing -p "
根据计划 @./$FEATURE-plan.md 实施功能。

创建:
1. 所有必要的组件
2. API 端点
3. 数据库迁移
4. 单元测试
5. 集成测试
"

# 5. 运行测试
echo "运行测试..."
if ! npm test; then
  echo "测试失败！"
  gemini --yolo -p "修复失败的测试"
  npm test || exit 1
fi

# 6. 代码审查
echo "执行代码审查..."
gemini -p "审查这个功能的实现，生成自审查报告" > $FEATURE-self-review.md

# 7. 生成文档
echo "生成文档..."
gemini -p "为这个功能生成用户文档和开发文档" > docs/$FEATURE.md

# 8. 创建 PR
echo "创建 PR..."
PR_BODY=$(gemini -p "
生成 PR 描述:

功能: $FEATURE
变更: $(git diff main --name-only)
计划: @./$FEATURE-plan.md
审查: @./$FEATURE-self-review.md

包含:
- 功能摘要
- 主要更改
- 测试说明
- 截图
- 检查清单
" --output-format json | jq -r '.response')

gh pr create --title "Feature: $FEATURE" --body "$PR_BODY"

echo "完成！PR 已创建"
```

### 示例 13.2: Bug 修复完整流程

```bash
#!/bin/bash
# bugfix-workflow.sh

BUG_ID="$1"

if [ -z "$BUG_ID" ]; then
  echo "用法: $0 <bug-id>"
  exit 1
fi

echo "=== Bug 修复工作流: Bug #$BUG_ID ==="

# 1. 获取 bug 信息
echo "获取 bug 信息..."
gh issue view $BUG_ID > bug-$BUG_ID.txt

# 2. 分析 bug
echo "分析 bug..."
gemini -p "
Bug 信息: @./bug-$BUG_ID.txt

请:
1. 理解问题
2. 找出可能的根本原因
3. 搜索相关代码
4. 生成调试计划
" > bug-$BUG_ID-analysis.md

# 3. 创建修复分支
git checkout -b fix/bug-$BUG_ID

# 4. 实施修复
echo "实施修复..."
gemini --checkpointing -p "
Bug 分析: @./bug-$BUG_ID-analysis.md

修复这个 bug:
1. 实施修复
2. 添加回归测试
3. 验证修复有效
"

# 5. 验证
echo "验证修复..."
npm test

if [ $? -eq 0 ]; then
  echo "测试通过！"
else
  echo "测试失败，重新修复..."
  gemini --yolo -p "测试失败，调试并修复"
  npm test || exit 1
fi

# 6. 提交和创建 PR
COMMIT_MSG=$(gemini -p "为这个 bug 修复生成提交消息" --output-format json | jq -r '.response')

git add .
git commit -m "$COMMIT_MSG"
git push -u origin fix/bug-$BUG_ID

gh pr create --title "Fix: Bug #$BUG_ID" \
  --body "Fixes #$BUG_ID\n\n$(cat bug-$BUG_ID-analysis.md)"

echo "完成！PR 已创建并关联 issue #$BUG_ID"
```

## 14. 批量操作示例

### 示例 14.1: 批量重命名

```bash
gemini -p "
批量重命名文件以遵循命名约定:

目录: @./src/components/

约定:
- 组件文件: PascalCase.jsx
- 样式文件: kebab-case.module.css
- 测试文件: PascalCase.test.jsx

生成重命名脚本并执行。
"
```

### 示例 14.2: 批量更新导入

```bash
gemini -p "
更新所有文件中的导入路径:

从: import { util } from '../../utils'
到: import { util } from '@/utils'

影响的文件: @./src/**/*.js

执行批量替换并验证。
"
```

## 下一步

- 查看 [08-resources.md](08-resources.md) 获取更多资源
- 参考 [06-tips-tricks.md](06-tips-tricks.md) 优化使用
- 加入社区分享你的示例
