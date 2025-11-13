# 项目文件结构

## 完整文件树

```
web-to-markdown-extension/
├── 📄 .gitignore                      # Git 忽略配置
├── 📘 DESIGN_V1.md                    # V1 详细设计文档（14 页）
├── 📘 INSTALLATION.md                 # 完整安装指南
├── 📘 QUICK_START.md                  # 快速开始指南
├── 📘 README.md                       # 项目说明
├── 📘 PROJECT_SUMMARY.md              # 项目总结
├── 📘 FILE_STRUCTURE.md               # 本文件
│
├── 📦 package.json                    # NPM 依赖配置
├── ⚙️ webpack.config.js               # 构建配置（可选）
├── 🎯 manifest.json                   # Chrome 扩展配置
│
├── 📁 icons/                          # 扩展图标
│   ├── 📘 README.md                   # 图标说明
│   ├── 🐍 generate-icons.py           # 图标生成脚本
│   ├── 🖼️ icon16.png                  # 16x16 图标（待生成）
│   ├── 🖼️ icon32.png                  # 32x32 图标（待生成）
│   ├── 🖼️ icon48.png                  # 48x48 图标（待生成）
│   └── 🖼️ icon128.png                 # 128x128 图标（待生成）
│
├── 📁 src/                            # 源代码目录
│   │
│   ├── 📁 background/                 # 后台服务
│   │   └── 📜 service-worker.js       # 后台脚本（下载、菜单）
│   │
│   ├── 📁 content/                    # 内容脚本
│   │   └── 📜 content.js              # 页面交互脚本
│   │
│   ├── 📁 popup/                      # 弹出界面
│   │   ├── 📄 popup.html              # 弹出窗口 HTML
│   │   ├── 🎨 popup.css               # 弹出窗口样式
│   │   └── 📜 popup.js                # 弹出窗口逻辑
│   │
│   └── 📁 utils/                      # 工具模块
│       ├── 📜 html-to-markdown.js     # HTML→MD 转换引擎
│       ├── 📜 dom-parser.js           # DOM 解析和提取
│       ├── 📜 media-downloader.js     # 媒体文件下载器
│       └── 📜 file-manager.js         # 文件管理器
│
├── 📁 tmp/                            # 输出目录（运行时生成）
│   └── 📁 YYYYMMDD_HHMMSS/            # 时间戳子目录
│       ├── 📄 content.md              # 转换后的 Markdown
│       ├── 📄 metadata.json           # 元数据
│       └── 📁 media/                  # 媒体文件
│           └── 🖼️ image_*.jpg
│
└── 📁 node_modules/                   # NPM 依赖（安装后生成）
    └── ...
```

---

## 核心文件说明

### 配置文件

#### manifest.json
```json
{
  "manifest_version": 3,
  "name": "Web to Markdown",
  "permissions": ["downloads", "activeTab", "contextMenus"],
  "background": { "service_worker": "..." },
  "content_scripts": [...],
  "action": { "default_popup": "..." }
}
```
- **作用**: 扩展配置入口
- **关键点**: Manifest V3 标准，Chrome/Edge 兼容

#### package.json
```json
{
  "name": "web-to-markdown-extension",
  "dependencies": {},
  "devDependencies": {
    "webpack": "^5.89.0"
  }
}
```
- **作用**: Node.js 项目配置
- **注意**: V1 无必需依赖（可选构建）

---

### 核心模块（src/utils/）

#### 1. html-to-markdown.js (~400 行)
**功能**: HTML 到 Markdown 的核心转换引擎

**关键类**:
```javascript
class HTMLToMarkdownConverter {
  convert(html, baseUrl)      // 主转换函数
  processNode(node, context)  // 递归处理节点
  tagHandlers = { ... }       // 标签处理器映射
  cleanMarkdown(markdown)     // 清理输出
  getMediaFiles()             // 获取媒体列表
}
```

**支持元素**:
- 标题 (h1-h6)
- 段落 (p)
- 文本格式 (strong, em, del)
- 链接 (a)
- 图片 (img)
- 列表 (ul, ol, li)
- 代码 (code, pre)
- 引用 (blockquote)
- 表格 (table, tr, td)
- 其他 20+ 元素

---

#### 2. dom-parser.js (~350 行)
**功能**: DOM 遍历、内容提取、复制限制突破

**关键方法**:
```javascript
class DOMParser {
  extractContent(rootElement)     // 提取主内容
  extractTitle()                  // 提取标题
  extractMetadata()               // 提取元数据
  removeCopyRestrictions(element) // 移除复制限制
  extractTextContent(element)     // 提取纯文本（TreeWalker）
  waitForDynamicContent()         // 等待动态内容
  loadLazyImages()                // 触发懒加载
  enableElementSelector(callback) // 交互式选择器
}
```

**技术要点**:
- 使用 `TreeWalker` 遍历文本节点
- 绕过 `user-select: none`
- 处理动态加载（MutationObserver）
- 提取 meta 标签信息

---

#### 3. media-downloader.js (~300 行)
**功能**: 媒体文件下载和管理

**关键方法**:
```javascript
class MediaDownloader {
  downloadMedia(url, options)           // 单个文件下载
  downloadMultiple(mediaList, callback) // 批量下载（并发控制）
  generateFilename(url, mimeType)       // 生成本地文件名
  saveBlobWithChrome(blob, filename)    // 使用 chrome.downloads
  getStatistics()                       // 下载统计
}
```

**特性**:
- 并发控制（最多 5 个）
- 文件大小限制（50MB）
- 智能文件名（避免冲突）
- 进度回调

---

#### 4. file-manager.js (~350 行)
**功能**: 文件组织和元数据管理

**关键方法**:
```javascript
class FileManager {
  createSession()                        // 创建时间戳会话
  generateMetadata(data)                 // 生成 JSON 元数据
  generateMarkdownFile(content, metadata)// 生成带 frontmatter 的 MD
  replaceMediaUrls(markdown, mediaFiles) // 替换 URL 为本地路径
  downloadFiles(files)                   // 批量下载文件
  validateMarkdown(markdown)             // 验证 Markdown
}
```

**输出结构**:
```
tmp/20250111_143025/
├── content.md          # 带 YAML frontmatter
├── metadata.json       # 完整元数据
└── media/
    └── image_xxx.jpg
```

---

### 扩展脚本

#### src/content/content.js (~200 行)
**运行环境**: 网页上下文

**功能**:
- 接收扩展命令
- 调用转换引擎
- 显示进度通知
- 监听快捷键

**消息处理**:
```javascript
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  switch (request.type) {
    case 'CONVERT_PAGE': ...
    case 'CONVERT_SELECTION': ...
    case 'START_SELECTOR': ...
    case 'GET_PAGE_INFO': ...
  }
});
```

---

#### src/background/service-worker.js (~200 行)
**运行环境**: 扩展后台

**功能**:
- 创建右键菜单
- 处理快捷键命令
- 管理文件下载
- 发送通知

**右键菜单**:
- Convert page to Markdown
- Convert selection to Markdown
- Select element to convert
- Save image as Markdown

---

#### src/popup/popup.js (~200 行)
**运行环境**: 弹出窗口

**功能**:
- 显示页面统计
- 配置转换选项
- 触发转换操作
- 显示进度

**选项**:
- Download media files
- Load lazy images
- Wait for dynamic content
- Include metadata

---

### 界面文件

#### src/popup/popup.html
```html
<div class="container">
  <header>...</header>
  <section class="page-info">...</section>
  <section class="statistics">...</section>
  <section class="options">...</section>
  <section class="actions">
    <button id="btn-convert-page">...</button>
  </section>
</section>
```

#### src/popup/popup.css
- 紫色渐变主题 (#667eea → #764ba2)
- 现代化卡片设计
- 响应式布局
- 动画效果

---

## 文档文件

### DESIGN_V1.md (14 页)
详细技术设计文档，包含：
- 项目概述和目标
- 技术架构图
- 核心功能设计
- 转换规则详解
- 媒体处理流程
- 文件组织方案
- 用户交互设计
- 技术难点解决方案
- 性能优化策略
- 安全考虑
- 开源参考项目
- V1 版本范围
- 开发计划（5 周）
- 测试策略

### INSTALLATION.md
完整安装指南，包含：
- 前置要求
- 安装步骤
- 使用方法
- 输出结构
- 配置选项
- 故障排除
- 开发指南
- FAQ

### QUICK_START.md
快速上手指南（中文），包含：
- 3 步安装
- 3 种使用方式
- 输出示例
- 常见问题
- 测试建议

### PROJECT_SUMMARY.md
项目总结，包含：
- 完成情况清单
- 技术亮点
- 代码统计
- 功能清单
- 测试建议
- 已知限制
- 性能指标
- 下一步计划

---

## 依赖关系图

```
manifest.json
    │
    ├─→ background/service-worker.js
    │       └─→ chrome.downloads API
    │       └─→ chrome.contextMenus API
    │
    ├─→ content/content.js
    │       ├─→ utils/html-to-markdown.js
    │       ├─→ utils/dom-parser.js
    │       ├─→ utils/media-downloader.js
    │       └─→ utils/file-manager.js
    │
    └─→ popup/popup.html
            └─→ popup.js
                └─→ popup.css
```

---

## 运行时文件流

```
用户触发（右键/快捷键）
    ↓
background/service-worker.js（接收命令）
    ↓
content/content.js（执行转换）
    ├─→ dom-parser.js（提取 DOM）
    ├─→ html-to-markdown.js（转换 MD）
    ├─→ media-downloader.js（下载媒体）
    └─→ file-manager.js（组织文件）
    ↓
background/service-worker.js（处理下载）
    ↓
chrome.downloads API（保存文件）
    ↓
tmp/YYYYMMDD_HHMMSS/（输出目录）
```

---

## 文件大小（估算）

| 文件 | 行数 | 大小 |
|------|------|------|
| html-to-markdown.js | ~400 | ~15 KB |
| dom-parser.js | ~350 | ~14 KB |
| media-downloader.js | ~300 | ~12 KB |
| file-manager.js | ~350 | ~14 KB |
| content.js | ~200 | ~8 KB |
| service-worker.js | ~200 | ~8 KB |
| popup.js | ~200 | ~8 KB |
| popup.css | ~150 | ~4 KB |
| **总计** | **~2,150** | **~83 KB** |

文档: ~2,000 行 (~80 KB)

**整体项目**: ~4,150 行代码 + 文档

---

## 图标文件

需要创建 4 个尺寸的图标：

```python
# 使用 icons/generate-icons.py 生成
python generate-icons.py

# 输出:
icons/icon16.png   (16x16)
icons/icon32.png   (32x32)
icons/icon48.png   (48x48)
icons/icon128.png  (128x128)
```

---

## Git 忽略配置

.gitignore 包含：
```
node_modules/    # NPM 依赖
dist/            # 构建输出
tmp/             # 转换输出（临时）
*.log            # 日志文件
.DS_Store        # macOS
*.zip            # 打包文件
```

---

## 下一步操作

1. **生成图标**
   ```bash
   cd icons && python generate-icons.py
   ```

2. **加载扩展**
   - 打开 `chrome://extensions/`
   - 加载 `web-to-markdown-extension` 目录

3. **测试转换**
   - 访问任意网页
   - 右键 → "Convert page to Markdown"

4. **查看输出**
   - 检查 Downloads 文件夹
   - 查看 `tmp/YYYYMMDD_HHMMSS/` 目录

---

**文件结构文档更新**: 2025-01-11
