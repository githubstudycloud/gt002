# Gemini CLI 安装和配置指南

## 系统要求

- **Node.js**: 版本 20 或更高
- **操作系统**: macOS, Linux, 或 Windows
- **可选**: Docker/Podman（用于沙箱模式）

## 安装方法

### 1. NPX（无需安装，即用即走）

```bash
npx @google/gemini-cli
```

优点：
- 无需安装，直接运行
- 始终使用最新版本
- 适合临时使用

### 2. 全局 NPM 安装

```bash
npm install -g @google/gemini-cli

# 运行
gemini
```

优点：
- 安装后可快速启动
- 可选择特定版本
- 适合日常使用

### 3. Homebrew（macOS/Linux）

```bash
brew install gemini-cli

# 运行
gemini
```

优点：
- 与系统包管理器集成
- 自动管理依赖
- 便于更新

### 4. 从 GitHub 运行

```bash
npx https://github.com/google-gemini/gemini-cli
```

## 身份验证方法

### 方法 1: Google 账户登录（推荐个人开发者）

```bash
gemini
# 首次运行时会提示登录
```

**免费层额度**:
- 60 请求/分钟
- 1,000 请求/天
- 访问 Gemini 2.5 Pro
- 1M 令牌上下文窗口

### 方法 2: Gemini API Key

1. 获取 API Key: https://aistudio.google.com/apikey

2. 设置环境变量:

```bash
# Linux/macOS
export GEMINI_API_KEY="your-api-key-here"

# Windows PowerShell
$env:GEMINI_API_KEY="your-api-key-here"

# Windows CMD
set GEMINI_API_KEY=your-api-key-here
```

3. 或创建 `.env` 文件在 `~/.gemini/`:

```env
GEMINI_API_KEY=your-api-key-here
```

**免费层额度**:
- 100 请求/天
- 按使用量付费可选

### 方法 3: Vertex AI（企业选项）

```bash
# 配置 Google Cloud 项目
gcloud auth application-default login

# 使用 Vertex AI
gemini --vertex-ai --project-id your-project-id
```

**优势**:
- 高级安全功能
- 更高的速率限制
- 企业级支持

## 初始配置

### 1. 创建配置目录

```bash
# 用户级配置
mkdir -p ~/.gemini

# 项目级配置
mkdir -p .gemini
```

### 2. 生成项目上下文文件

```bash
cd your-project
gemini
# 在交互模式中运行:
/init
```

这会创建 `GEMINI.md` 文件，用于提供项目特定的上下文。

### 3. 配置文件位置（优先级顺序）

1. `.gemini/settings.json` (项目级)
2. `~/.gemini/settings.json` (用户级)
3. `/etc/gemini-cli/settings.json` (系统级)

### 4. 基本 settings.json 示例

```json
{
  "autoAccept": false,
  "sandbox": false,
  "vimMode": false,
  "checkpointing": true,
  "model": "gemini-2.5-pro",
  "customThemes": {
    "myTheme": {
      "primary": "#00ff00",
      "secondary": "#ff00ff"
    }
  }
}
```

## 关键配置选项

### autoAccept (自动接受)

```json
{
  "autoAccept": true  // 自动批准所有工具调用（谨慎使用）
}
```

### checkpointing (检查点)

```json
{
  "checkpointing": true  // 在修改文件前自动保存快照
}
```

### sandbox (沙箱模式)

```json
{
  "sandbox": true  // 需要 Docker/Podman
}
```

### vimMode (Vim 模式)

```json
{
  "vimMode": true  // 启用 Vim 键绑定
}
```

## 创建 .geminiignore 文件

类似于 `.gitignore`，用于排除文件和目录：

```bash
# .geminiignore 示例
node_modules/
dist/
build/
*.log
.env
.git/
coverage/
```

## 验证安装

```bash
# 检查版本
gemini --version

# 运行帮助
gemini --help

# 测试运行
gemini -p "Hello, Gemini!"
```

## 版本选择

### 稳定版（默认）

```bash
npm install -g @google/gemini-cli@latest
```

### 预览版（周更）

```bash
npm install -g @google/gemini-cli@preview
```

### 夜间版（日更）

```bash
npm install -g @google/gemini-cli@nightly
```

## 更新

```bash
# NPM 全局更新
npm update -g @google/gemini-cli

# Homebrew 更新
brew upgrade gemini-cli
```

## 卸载

```bash
# NPM 卸载
npm uninstall -g @google/gemini-cli

# Homebrew 卸载
brew uninstall gemini-cli

# 清理配置文件（可选）
rm -rf ~/.gemini
```

## 故障排除

### 问题: 找不到 Node.js

**解决方案**: 安装 Node.js 20+
```bash
# 使用 nvm
nvm install 20
nvm use 20

# 或从 https://nodejs.org 下载
```

### 问题: 权限错误（NPM 全局安装）

**解决方案**: 使用 npx 或修复 npm 权限
```bash
# 选项 1: 使用 npx（推荐）
npx @google/gemini-cli

# 选项 2: 修复 npm 权限
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

### 问题: API Key 未识别

**解决方案**: 验证环境变量
```bash
# 检查是否设置
echo $GEMINI_API_KEY  # Linux/macOS
echo %GEMINI_API_KEY%  # Windows

# 重新设置
export GEMINI_API_KEY="your-key"
```

## 下一步

- 查看 [02-core-features.md](02-core-features.md) 了解核心功能
- 查看 [03-commands-reference.md](03-commands-reference.md) 学习所有命令
- 查看 [06-tips-tricks.md](06-tips-tricks.md) 获取最佳实践
