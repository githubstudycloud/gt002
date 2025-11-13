# 快速入门指南

## 1. Claude Code 概览

### 什么是 Claude Code？
Claude Code 是 Anthropic 开发的 AI 编程助手，能够：
- 理解和分析代码库
- 生成和编辑代码
- 修复 bug 和重构
- 编写测试
- 自动化开发工作流程

### 核心优势
- **上下文理解**: 深度理解整个代码库
- **多工具集成**: 支持文件操作、命令执行、Web 搜索等
- **可定制性**: 通过插件、技能和钩子扩展功能
- **安全性**: 沙箱隔离和权限控制
- **CI/CD 集成**: 与 GitHub Actions、GitLab CI 等集成

📖 **官方文档**: [Overview](https://code.claude.com/docs/en/overview.md)

---

## 2. 安装配置

### Windows 安装
```bash
# 使用安装程序
# 下载: https://code.claude.com/
```

### macOS 安装
```bash
# 使用 Homebrew
brew install claude-code

# 或下载 DMG
```

### Linux 安装
```bash
# 使用包管理器或 AppImage
# 详见官方文档
```

### 验证安装
```bash
claude --version
```

📖 **官方文档**: [Setup](https://code.claude.com/docs/en/setup.md)

---

## 3. 快速开始教程

### 第一步：登录
```bash
claude login
```

### 第二步：启动交互模式
```bash
claude
```

### 第三步：尝试基本命令
```
# 在交互模式中
/help           # 查看帮助
/settings       # 查看设置
/clear          # 清除对话
```

### 第四步：尝试第一个任务
```
帮我分析一下这个代码库的结构
```

📖 **官方文档**: [Quickstart](https://code.claude.com/docs/en/quickstart.md)

---

## 4. 常见工作流程

### 4.1 代码库分析
```
分析这个项目的架构并生成概述
找出所有的 API 端点
解释 auth 模块是如何工作的
```

### 4.2 Bug 修复
```
这个错误信息是什么意思：[粘贴错误]
帮我修复 src/utils/api.ts 中的类型错误
运行测试并修复所有失败的用例
```

### 4.3 功能开发
```
添加一个新的用户认证功能
实现 JWT token 刷新机制
创建一个 RESTful API 端点
```

### 4.4 代码重构
```
重构 UserService 类，使其更模块化
将这个函数拆分成更小的函数
优化这段代码的性能
```

### 4.5 测试编写
```
为 calculateTotal 函数编写单元测试
添加集成测试覆盖支付流程
运行所有测试并生成覆盖率报告
```

### 4.6 文档生成
```
为这个函数添加 JSDoc 注释
生成 API 文档
更新 README 文件
```

📖 **官方文档**: [Common Workflows](https://code.claude.com/docs/en/common-workflows.md)

---

## 5. 交互模式基础

### 键盘快捷键
- `Ctrl+C`: 中断当前操作
- `Ctrl+D`: 退出
- `↑/↓`: 浏览历史命令
- `Tab`: 自动补全（如果配置）

### 斜杠命令
- `/help`: 显示帮助
- `/clear`: 清除对话历史
- `/settings`: 查看/修改设置
- `/checkpoint`: 创建检查点
- `/rewind`: 回退到之前的状态

### Vim 模式（可选）
如果你是 Vim 用户，可以启用 Vim 编辑模式。

📖 **官方文档**: [Interactive Mode](https://code.claude.com/docs/en/interactive-mode.md)

---

## 6. Web 版本

Claude Code 也提供 Web 版本，特点：
- 浏览器中运行
- 云端执行环境
- 网络访问能力
- 协作功能

📖 **官方文档**: [Claude Code on the Web](https://code.claude.com/docs/en/claude-code-on-the-web.md)

---

## 7. 配置设置

### 查看当前设置
```bash
claude config list
```

### 修改设置
```bash
# 设置默认模型
claude config set model claude-sonnet-4

# 设置编辑器
claude config set editor vim
```

### 配置文件位置
- Windows: `%APPDATA%\claude-code\config.json`
- macOS/Linux: `~/.config/claude-code/config.json`

📖 **官方文档**: [Settings](https://code.claude.com/docs/en/settings.md)

---

## 8. CLI 命令参考

### 基本命令
```bash
# 启动交互模式
claude

# 在指定目录启动
claude --cwd /path/to/project

# 执行单个命令
claude "分析这个项目"

# 使用特定模型
claude --model claude-opus-4
```

### Headless 模式
```bash
# 非交互式执行
claude headless "生成测试报告"
```

📖 **官方文档**: [CLI Reference](https://code.claude.com/docs/en/cli-reference.md)

---

## 9. 下一步学习

完成快速入门后，建议继续学习：

1. **核心功能** (02-core-features/): 深入了解各种功能
2. **定制化** (03-customization/): 学习如何自定义 Claude Code
3. **集成部署** (04-integration-deployment/): 将 Claude Code 集成到工作流程

---

## 10. 常见问题

### Q: Claude Code 是免费的吗？
A: 需要 Anthropic API 密钥，使用按 API 调用计费。

### Q: 支持哪些编程语言？
A: 支持所有主流编程语言。

### Q: 如何获取帮助？
A:
- 官方文档: https://code.claude.com/docs/
- GitHub Issues: https://github.com/anthropics/claude-code/issues
- 社区论坛: https://github.com/anthropics/claude-code/discussions

### Q: 数据安全吗？
A: Claude Code 支持沙箱模式、数据加密，详见安全文档。

---

**准备好开始了吗？** 打开终端，输入 `claude` 开始你的 AI 编程之旅！
