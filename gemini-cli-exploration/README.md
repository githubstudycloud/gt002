# Gemini CLI 完整功能探究

这个目录包含了关于 Google Gemini CLI 的全面研究和文档整理。

## 目录结构

- `01-installation-setup.md` - 安装和配置指南
- `02-core-features.md` - 核心功能详解
- `03-commands-reference.md` - 命令参考手册
- `04-advanced-features.md` - 高级特性
- `05-mcp-servers.md` - MCP 服务器集成
- `06-tips-tricks.md` - 技巧和最佳实践
- `07-examples.md` - 实用示例
- `08-resources.md` - 资源链接

## 快速导航

### 官方资源
- [GitHub 仓库](https://github.com/google-gemini/gemini-cli)
- [官方文档](https://developers.google.com/gemini-code-assist/docs/gemini-cli)
- [Google Cloud 文档](https://cloud.google.com/gemini/docs/codeassist/gemini-cli)

### 社区资源
- [Gemini CLI Cheatsheet](https://www.philschmid.de/gemini-cli-cheatsheet)
- [DataCamp 教程](https://www.datacamp.com/tutorial/gemini-cli)
- [Google Codelabs 实践](https://codelabs.developers.google.com/gemini-cli-hands-on)

## 什么是 Gemini CLI？

Gemini CLI 是 Google 推出的开源终端应用程序，让开发者能够直接在命令行中使用 Gemini AI 模型。它提供了强大的代码生成、调试、自动化等功能。

## 核心亮点

- ⚡ **1M 令牌上下文窗口** - 处理大型代码库
- 🔄 **免费层支持** - 60 请求/分钟，1000 请求/天
- 🛠️ **内置工具** - 文件操作、Shell 命令、Web 搜索
- 🔌 **MCP 支持** - 通过 Model Context Protocol 扩展功能
- 🤖 **ReAct 循环** - 推理和行动相结合的智能代理
- 🎨 **多模态输入** - 支持文本、图像等

## 快速开始

```bash
# 使用 NPX（无需安装）
npx @google/gemini-cli

# 全局安装
npm install -g @google/gemini-cli

# Homebrew
brew install gemini-cli

# 运行
gemini
```

## 主要功能分类

### 1. 代码开发
- 查询和修改大型代码库
- 从 PDF、图像、草图生成应用
- 使用自然语言调试问题
- 生成单元测试和文档

### 2. 自动化与集成
- GitHub Actions 集成
- PR 查询和复杂的 rebase 操作
- 问题分类和标签
- 自动化代码审查

### 3. 上下文管理
- GEMINI.md 项目特定上下文
- 对话检查点（保存/恢复会话）
- 令牌缓存优化
- 记忆系统（跨会话信息）

### 4. 扩展性
- MCP 服务器集成
- 自定义命令创建
- IDE 集成（VS Code）
- 沙箱环境安全执行

## 更新时间

本文档最后更新：2025-01-12

根据官方发布时间表：
- **Preview**: 每周二 23:59 UTC
- **Stable**: 每周二 20:00 UTC
- **Nightly**: 每日发布
