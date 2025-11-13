# Gemini CLI 技巧和最佳实践

## 基础技巧

### 1. 始终从项目根目录运行

```bash
# ✅ 正确
cd /path/to/project
gemini

# ❌ 错误
cd /path/to/project/src
gemini
```

**原因**: Gemini 需要正确的上下文来加载 GEMINI.md 和项目配置。

### 2. 先生成计划，再执行

```bash
gemini -p "生成一个重构 src/utils.js 的计划"
# 审查计划
gemini -p "按照计划执行重构"
```

**优势**: 可以在实际修改前审查和调整计划。

### 3. 使用 /compress 节省令牌

长对话会话时：

```bash
/compress
```

这会将对话历史压缩为摘要，节省令牌并提高性能。

### 4. 使用 /copy 快速复制

```bash
/copy
```

复制最后的响应到剪贴板，方便分享或保存。

### 5. 使用检查点保护代码

```bash
# 启用检查点
gemini --checkpointing

# 如果出错，恢复
/restore
```

## 上下文管理技巧

### 1. 使用 GEMINI.md 提供项目上下文

```bash
gemini
/init
```

在 GEMINI.md 中包含：
- 项目架构概述
- 代码风格指南
- 重要约束和规则
- 测试命令
- 常见任务流程

### 2. 使用 /memory 快速记录

```bash
# 快速记录临时信息
/memory add 数据库端口 5432
/memory add API_URL https://api.example.com
/memory add 记得更新文档
```

比每次编辑 GEMINI.md 更快。

### 3. 引用特定文件

```bash
# 精确引用
gemini -p "分析 @./src/auth.js 的安全性"

# 引用多个文件
gemini -p "比较 @./v1/api.js 和 @./v2/api.js 的差异"
```

### 4. 引用图像获得更好的结果

```bash
# UI 设计
gemini -p "根据 @./design.png 实现这个登录页面"

# 错误截图
gemini -p "调试这个错误 @./error-screenshot.png"

# 图表
gemini -p "根据 @./architecture-diagram.png 解释系统架构"
```

### 5. 使用 .geminiignore 排除无关文件

```bash
# .geminiignore
node_modules/
dist/
build/
*.log
.env
.git/
coverage/
*.test.js
*.spec.js
```

**优势**: 减少上下文噪音，提高响应质量。

## 交互模式技巧

### 1. 使用 Ctrl+V 粘贴图像

直接从剪贴板粘贴截图：

```bash
gemini
# 拍截图，复制到剪贴板
# 按 Ctrl+V
> 修复这个 UI 问题
```

### 2. 使用 ! 快速执行 Shell 命令

```bash
# 单次命令
!git status

# 持久 shell 模式
!
# 现在所有输入都是 shell 命令
git status
npm test
!  # 退出 shell 模式
```

### 3. 使用 Ctrl+Y 切换 YOLO 模式

在交互模式中按 `Ctrl+Y` 快速启用/禁用自动批准。

**注意**: YOLO 模式有风险，只在信任的操作中使用。

### 4. 使用 /vim 启用 Vim 模式

```bash
/vim
```

现在可以使用 Vim 键绑定编辑提示。

### 5. 使用 Ctrl+X 在外部编辑器中编写

对于长提示，按 `Ctrl+X` 在默认编辑器中打开。

## 非交互模式技巧

### 1. 使用 JSON 输出进行脚本处理

```bash
# 获取结构化输出
RESULT=$(gemini -p "列出所有函数" --output-format json)

# 解析 JSON
echo "$RESULT" | jq -r '.response'
```

### 2. 使用 Stream JSON 监控长时间任务

```bash
gemini -p "运行完整测试套件" --output-format stream-json | \
  jq -r 'select(.event == "tool_result") | .output'
```

### 3. 结合其他命令行工具

```bash
# 分析 git diff
git diff main | gemini -p "审查这些更改并提供建议"

# 分析日志
tail -100 error.log | gemini -p "找出根本原因"

# 分析测试输出
npm test 2>&1 | gemini -p "修复失败的测试"
```

### 4. 使用 --yolo 进行自动化

```bash
# CI/CD 中自动修复
gemini --yolo -p "修复所有 lint 错误" || exit 1
```

### 5. 使用多个 --include-directories

```bash
gemini --include-directories ../shared,../utils -p "重构共享代码"
```

## 高级工作流技巧

### 1. 代码审查工作流

```bash
#!/bin/bash
# review-workflow.sh

echo "=== 代码审查工作流 ==="

# 1. 获取变更
echo "获取变更..."
CHANGES=$(git diff main --name-only)
echo "变更的文件: $CHANGES"

# 2. 生成审查
echo "生成审查..."
gemini -p "审查这些文件的变更:
$CHANGES

关注:
1. 代码质量
2. 潜在 bug
3. 性能问题
4. 安全漏洞

生成详细报告。" > review.md

# 3. 检查测试
echo "检查测试覆盖..."
npm test -- --coverage

# 4. 生成摘要
echo "生成摘要..."
gemini -p "基于 @./review.md 和测试结果，
生成简洁的 PR 描述" > pr-description.md

echo "完成！查看 review.md 和 pr-description.md"
```

### 2. Bug 修复工作流

```bash
#!/bin/bash
# bug-fix-workflow.sh

# 1. 描述问题
echo "描述bug..."
cat > bug-description.txt << EOF
Bug 描述: 用户无法登录
重现步骤:
1. 打开登录页面
2. 输入凭证
3. 点击登录
4. 看到错误消息

错误消息: "Network request failed"
EOF

# 2. 收集相关代码
echo "收集相关代码..."
find src -name "*auth*" -o -name "*login*" > relevant-files.txt

# 3. 分析和修复
echo "分析问题..."
gemini --checkpointing -p "
Bug 信息: @./bug-description.txt
相关文件: $(cat relevant-files.txt)

请:
1. 分析问题
2. 找出根本原因
3. 提供修复方案
4. 实施修复
"

# 4. 验证修复
echo "运行测试..."
npm test

echo "如果测试失败，使用 /restore 回滚"
```

### 3. 文档生成工作流

```bash
#!/bin/bash
# docs-workflow.sh

# 为所有 JS 文件生成文档
for file in src/**/*.js; do
  echo "生成 $file 的文档..."

  gemini -p "为 @./$file 生成详细的 JSDoc 注释和 README" \
    --output-format json > "/tmp/doc-$file.json"

  # 提取生成的文档
  jq -r '.response' "/tmp/doc-$file.json" > "docs/$(basename $file .js).md"
done

# 生成总索引
gemini -p "基于 docs/ 中的所有文档，生成一个总索引 README.md"
```

### 4. 重构工作流

```bash
#!/bin/bash
# refactor-workflow.sh

TARGET_FILE="$1"

if [ -z "$TARGET_FILE" ]; then
  echo "用法: $0 <文件路径>"
  exit 1
fi

echo "=== 重构工作流: $TARGET_FILE ==="

# 1. 备份
cp "$TARGET_FILE" "${TARGET_FILE}.backup"

# 2. 分析
echo "分析代码质量..."
gemini -p "分析 @./$TARGET_FILE 的:
1. 代码复杂度
2. 重复代码
3. 潜在改进点
生成详细报告。" > refactor-analysis.md

# 3. 生成重构计划
echo "生成重构计划..."
gemini -p "基于 @./refactor-analysis.md，
为 @./$TARGET_FILE 生成详细的重构计划。" > refactor-plan.md

# 4. 审查计划
echo "请审查 refactor-plan.md"
read -p "继续重构？(y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 5. 执行重构
  echo "执行重构..."
  gemini --checkpointing -p "根据 @./refactor-plan.md 重构 @./$TARGET_FILE"

  # 6. 运行测试
  echo "运行测试..."
  if npm test; then
    echo "重构成功！"
    rm "${TARGET_FILE}.backup"
  else
    echo "测试失败！恢复备份..."
    mv "${TARGET_FILE}.backup" "$TARGET_FILE"
  fi
else
  echo "取消重构"
  rm "${TARGET_FILE}.backup"
fi
```

## 性能优化技巧

### 1. 使用更快的模型处理简单任务

```bash
# 简单问题使用 flash
gemini -m gemini-2.5-flash -p "这个函数做什么？"

# 复杂分析使用 pro
gemini -m gemini-2.5-pro -p "深入分析这个架构的优缺点"
```

### 2. 增量操作而不是重新处理

```bash
# ❌ 每次重新处理整个项目
gemini -p "为所有文件生成文档"

# ✅ 只处理变更的文件
CHANGED=$(git diff --name-only main)
gemini -p "为这些变更的文件生成文档: $CHANGED"
```

### 3. 使用 /compress 定期压缩对话

```bash
# 每隔几轮对话
/compress
```

### 4. 合理使用 .geminiignore

排除不必要的文件减少上下文大小。

## 调试技巧

### 1. 使用 --debug 查看详细信息

```bash
gemini --debug -p "..."
```

查看:
- 令牌使用
- 工具调用
- API 请求/响应
- 错误堆栈

### 2. 使用 /stats 监控令牌使用

```bash
/stats
```

显示:
- 输入令牌
- 输出令牌
- 缓存命中
- 估算成本

### 3. 检查工具执行

```bash
/tools
```

查看所有可用工具及其状态。

### 4. 测试单个工具

```bash
# 直接测试 MCP 工具
gemini mcp test github
```

## 安全技巧

### 1. 审查工具调用

```bash
# 不使用 --yolo，手动批准每个操作
gemini -p "..."

# 查看工具调用详情
# 批准或拒绝每个操作
```

### 2. 使用沙箱处理不信任的代码

```bash
gemini --sandbox -p "测试这段代码"
```

### 3. 使用环境变量管理敏感信息

```bash
# ✅ 正确
export GEMINI_API_KEY="..."

# ❌ 错误 - 不要硬编码
gemini -p "使用 API key sk-123456 调用 API"
```

### 4. 限制 MCP 服务器权限

```json
{
  "mcpServers": {
    "github": {
      "permissions": {
        "allowedRepos": ["myorg/*"],
        "deniedActions": ["delete"]
      }
    }
  }
}
```

### 5. 定期审计日志

```bash
# 查看审计日志
cat ~/.gemini/audit.log

# 搜索可疑活动
grep "DENIED" ~/.gemini/audit.log
```

## 团队协作技巧

### 1. 共享项目配置

```bash
# 将 .gemini/ 目录加入版本控制
git add .gemini/settings.json
git add .gemini/GEMINI.md
git commit -m "Add Gemini CLI configuration"
```

### 2. 使用自定义命令标准化工作流

```bash
# .gemini/commands/review.toml
[command]
name = "review"
description = "标准代码审查"

[prompt]
content = """
执行标准代码审查:
1. 检查代码风格
2. 查找潜在 bug
3. 检查测试覆盖
4. 生成审查报告
"""
```

团队成员都可以用 `/review`。

### 3. 文档化 GEMINI.md

在 GEMINI.md 中包含:
- 团队约定
- 项目特定规则
- 常见任务
- 联系人信息

### 4. 使用环境变量区分环境

```bash
# 开发环境
export GEMINI_ENV=development
export DATABASE_URL=localhost

# 生产环境
export GEMINI_ENV=production
export DATABASE_URL=prod-db.example.com
```

## 常见陷阱和解决方案

### 陷阱 1: 上下文过大导致性能下降

**解决方案**:
- 使用 .geminiignore
- 引用特定文件而不是整个目录
- 定期使用 /compress

### 陷阱 2: 忘记从项目根目录运行

**解决方案**:
- 创建别名: `alias gm='cd $(git rev-parse --show-toplevel) && gemini'`

### 陷阱 3: 丢失重要的对话上下文

**解决方案**:
- 经常使用 `/chat save`
- 重要信息添加到 `/memory add`

### 陷阱 4: 过度依赖 YOLO 模式

**解决方案**:
- 只在信任的简单任务使用
- 重要修改始终手动审查

### 陷阱 5: 不使用检查点

**解决方案**:
- 始终启用检查点: `gemini --checkpointing`
- 或在 settings.json 中设置默认启用

## 提高生产力的快捷方式

### Bash 别名

```bash
# ~/.bashrc 或 ~/.zshrc

# 基础别名
alias gm='gemini'
alias gmi='gemini -i'
alias gmd='gemini --debug'
alias gmy='gemini --yolo'
alias gmc='gemini --checkpointing'

# 常用任务
alias gm-review='gemini -p "审查当前变更"'
alias gm-test='gemini -p "为变更的文件生成测试"'
alias gm-docs='gemini -p "更新文档"'
alias gm-fix='gemini --checkpointing -p "修复 lint 错误"'

# 组合别名
alias gm-safe='gemini --checkpointing --sandbox'
```

### Shell 函数

```bash
# 快速代码审查
gm-quick-review() {
  git diff main --name-only | xargs -I {} gemini -p "简要审查 @./{}"
}

# 智能提交
gm-commit() {
  local msg=$(gemini -p "基于当前变更生成提交消息" --output-format json | jq -r '.response')
  git commit -m "$msg"
}

# 生成 PR 描述
gm-pr() {
  gemini -p "生成 PR 描述，包含变更摘要和测试计划" > pr-description.md
  cat pr-description.md
}
```

### Git Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "运行 Gemini CLI 预提交检查..."

# 检查代码质量
if ! gemini -p "快速检查暂存的变更是否有明显问题" --output-format json | \
     jq -e '.response | contains("no issues")' > /dev/null; then
  echo "发现潜在问题，请审查"
  exit 1
fi

echo "通过检查！"
```

## 最佳实践总结

### DO（推荐）

✅ 始终从项目根目录运行
✅ 使用 GEMINI.md 提供上下文
✅ 启用检查点保护代码
✅ 先生成计划再执行
✅ 使用 .geminiignore 排除无关文件
✅ 定期保存重要会话
✅ 使用合适的模型（flash vs pro）
✅ 审查工具调用再批准
✅ 将配置加入版本控制
✅ 使用环境变量管理敏感信息

### DON'T（不推荐）

❌ 过度使用 YOLO 模式
❌ 硬编码敏感信息
❌ 忽略检查点功能
❌ 在错误的目录运行
❌ 包含整个 node_modules
❌ 不审查生成的代码
❌ 忘记压缩长对话
❌ 不使用 MCP 扩展功能
❌ 跳过测试验证
❌ 不读懂就批准操作

## 下一步

- 查看 [07-examples.md](07-examples.md) 获取完整示例
- 查看 [08-resources.md](08-resources.md) 获取更多资源
- 加入社区分享你的技巧
