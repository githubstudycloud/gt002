# 贡献指南

感谢你考虑为AI API Gateway做出贡献！

## 如何贡献

### 报告Bug
1. 确认bug未被报告过
2. 创建详细的issue,包括:
   - 环境信息(OS, Go版本等)
   - 复现步骤
   - 期望行为
   - 实际行为
   - 错误日志

### 提出功能请求
1. 检查是否已有类似的功能请求
2. 清楚描述功能需求和使用场景
3. 如果可能,提供实现思路

### 提交代码

#### 开发环境设置
```bash
# 克隆仓库
git clone https://github.com/your-org/ai-api-gateway.git
cd ai-api-gateway

# 安装依赖
go mod download

# 运行测试
go test ./...
```

#### 开发流程
1. Fork本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

#### Commit规范
遵循[Conventional Commits](https://www.conventionalcommits.org/):

```
feat: 新功能
fix: bug修复
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具相关
```

示例:
```
feat: add Gemini provider adapter
fix: correct token counting in Claude adapter
docs: update API specification
```

#### 代码规范
- 遵循Go官方代码风格
- 运行`gofmt`格式化代码
- 运行`golint`检查代码
- 确保所有测试通过
- 新功能需要添加测试
- 代码覆盖率不能降低

#### Pull Request检查清单
- [ ] 代码通过所有测试
- [ ] 代码风格符合规范
- [ ] 添加了必要的测试
- [ ] 更新了相关文档
- [ ] Commit信息符合规范
- [ ] PR描述清晰完整

## 项目结构

```
ai-api-gateway/
├── cmd/              # 命令行入口
├── internal/         # 内部包
│   ├── api/         # API处理
│   ├── auth/        # 认证
│   ├── config/      # 配置
│   ├── converter/   # 格式转换
│   ├── provider/    # Provider适配器
│   └── ...
├── pkg/             # 公开包
├── config/          # 配置文件
├── docs/            # 文档
└── tests/           # 测试
```

## 社区

- GitHub Discussions: 技术讨论
- GitHub Issues: Bug报告和功能请求

## 行为准则

请遵守友好、包容、尊重的社区准则。

## 许可证

提交代码即表示同意在MIT许可证下发布。
