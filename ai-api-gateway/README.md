# AI API Gateway - 开源API聚合转化工具

## 项目概述

AI API Gateway 是一个开源的API聚合与格式转换工具，旨在统一各大AI厂商的API接口，提供标准化的访问方式，支持多种CLI工具的接口格式。

### 核心功能

1. **API格式转换** - 在不同AI厂商API格式之间进行转换
2. **多CLI支持** - 支持不同CLI工具的接口格式（Claude Code、OpenAI CLI等）
3. **统一管理** - 集中管理多个AI服务账户和配额
4. **使用追踪** - 详细的token消耗和成本分析
5. **协议适配** - 支持多种AI Agent协议标准

## 设计目标

- 🎯 **标准化** - 提供统一的OpenAI兼容API接口
- 🔄 **双向转换** - 支持各厂商格式与OpenAI格式的双向转换
- 🚀 **高性能** - 低延迟的请求转发和格式转换
- 🔒 **安全可靠** - 自托管方案，数据隐私保证
- 🛠️ **易扩展** - 插件化架构，易于添加新的厂商支持

## 项目结构

```
ai-api-gateway/
├── docs/                          # 文档目录
│   ├── 01-research-analysis.md   # 调研分析文档
│   ├── 02-architecture-design.md # 架构设计文档
│   ├── 03-api-specification.md   # API规范文档
│   └── 04-development-plan.md    # 开发计划
├── src/                          # 源代码目录
│   ├── core/                     # 核心模块
│   ├── providers/                # 厂商适配器
│   ├── protocols/                # 协议适配
│   └── utils/                    # 工具函数
├── config/                       # 配置文件
├── tests/                        # 测试文件
└── README.md                     # 项目说明
```

## 技术栈（待定）

- **后端框架**: Node.js/Go/Python (待评估)
- **数据库**: PostgreSQL/SQLite
- **缓存**: Redis (可选)
- **部署**: Docker + Docker Compose

## 快速开始

> 项目正在设计开发中，敬请期待...

## 贡献指南

欢迎贡献代码、提出问题和建议！

## 许可证

MIT License
