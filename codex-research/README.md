# OpenAI Codex 功能探究

本项目目录收集整理了 OpenAI Codex 的所有功能、使用技巧和社区讨论。

## 目录结构

- `official-docs/` - 官方文档和功能说明
- `forum-discussions/` - 技术论坛和社区讨论摘要
- `features/` - 详细功能列表和说明
- `examples/` - 实际使用案例和代码示例

## Codex 简介

OpenAI Codex 是基于 GPT-5-o3 模型微调的 AI 编程助手，于 2025 年 5 月发布研究预览版。它能够执行完整的软件工程任务，包括编写功能、回答代码库问题、运行测试、提出 PR 审查等。

## 核心特性

### 基础能力
- 自然语言转代码
- 代码补全与重构
- 错误检测与调试
- API 集成支持
- 多编程语言支持

### 高级功能（2025 更新）
- 基于 GPT-5-Codex 优化的代理式软件工程
- 任务进度跟踪（待办列表）
- 网络搜索工具
- MCP（模型上下文协议）外部系统连接
- 云沙盒环境执行

### 集成与配置
- VSCode、Cursor、Windsurf 插件
- GitHub Actions CI/CD 集成
- AGENTS.md 文件自定义配置
- 自动 PR 审查功能

## 性能指标

- **HumanEval 基准测试**: 原始 Codex 首次通过率 28.7%，经 100 次尝试可达 77.5%
- **SWE-Bench**: GPT-5-Codex 首次通过率 74.9%，是 GPT-4 的两倍
- **专项优化**: GPT-5-Codex 评分 51.3%，显著超过基础 GPT-5 的 33.9%

## 订阅计划

Codex 包含在以下订阅计划中：
- ChatGPT Plus
- ChatGPT Pro
- ChatGPT Business
- ChatGPT Edu
- ChatGPT Enterprise

## 最新更新（2025 年 11 月）

引入了 `gpt-5-codex-mini` 模型选项：
- 成本效益更高
- 功能相对较弱但速度更快
- 提供约 4 倍的使用量

## 文档资源

- 官方文档: https://developers.openai.com/codex/
- GitHub 仓库: https://github.com/openai/codex
- CLI 参考手册
- IDE 设置指南
- 企业管理文档

## 更新日期

2025-11-12
