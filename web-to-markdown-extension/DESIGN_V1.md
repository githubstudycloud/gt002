# Web to Markdown 浏览器扩展 - V1 设计文档

## 项目概述

### 目标
创建一个兼容 Chrome/Edge 的浏览器扩展，将网页内容转换为标准 Markdown 格式，突破网页复制限制，保存文字和媒体资源。

### 核心特性
- ✅ 兼容 Chrome 和 Edge 浏览器
- ✅ 绕过网页复制限制（user-select: none 等）
- ✅ 从 DOM 元素直接提取内容
- ✅ 转换为标准 Markdown 格式（文字优先）
- ✅ 保存图片、视频等媒体文件
- ✅ 按时间戳组织文件到 `tmp/` 目录

---

## 技术架构

### 1. 扩展组件结构

```
web-to-markdown-extension/
├── manifest.json              # Manifest V3 配置
├── src/
│   ├── background/
│   │   └── service-worker.js  # 后台服务（下载管理）
│   ├── content/
│   │   ├── content.js         # 内容脚本（DOM 访问）
│   │   └── selector.js        # 元素选择器
│   ├── popup/
│   │   ├── popup.html         # 弹出界面
│   │   ├── popup.js           # 弹出逻辑
│   │   └── popup.css          # 样式
│   └── utils/
│       ├── html-to-markdown.js    # HTML→MD 转换核心
│       ├── media-downloader.js    # 媒体文件下载
│       ├── dom-parser.js          # DOM 解析器
│       └── file-manager.js        # 文件管理
├── icons/                     # 扩展图标
└── tmp/                       # 临时文件存储
    └── YYYYMMDD_HHMMSS/       # 时间戳目录
```

### 2. 技术栈选择

| 组件 | 技术方案 | 原因 |
|------|---------|------|
| Manifest | V3 | Chrome/Edge 最新标准 |
| 转换引擎 | Turndown.js + 自定义规则 | 成熟的 HTML→MD 库 |
| DOM 解析 | 原生 DOM API | 直接访问，绕过复制限制 |
| 媒体下载 | Fetch API + Blob | 支持跨域下载 |
| 文件保存 | chrome.downloads API | 浏览器原生下载管理 |
| 样式处理 | CSS-in-JS 提取 | 保留关键格式信息 |

---

## 核心功能设计

### 功能 1: 突破复制限制

#### 问题分析
网站常用的复制限制技术:
- `user-select: none` CSS 属性
- `oncopy` / `oncut` 事件拦截
- 文本分层/覆盖（使用透明层）
- 虚拟 DOM 渲染

#### 解决方案
```javascript
// 直接从 DOM 提取文本节点
function extractTextFromNode(node) {
  // 忽略 CSS 样式，直接读取 textContent
  // 递归遍历 DOM 树
  // 保持文档结构（标题、段落、列表等）
}
```

**技术要点:**
1. 使用 `TreeWalker` API 遍历 DOM
2. 读取 `node.textContent` 而非依赖 `window.getSelection()`
3. 根据 HTML 标签推断 Markdown 结构
4. 忽略 `display: none` 和隐藏元素

---

### 功能 2: HTML → Markdown 转换

#### 转换策略（文字优先）

```markdown
优先级:
1. 文字内容（标题、段落、列表）
2. 链接和图片
3. 代码块和引用
4. 表格
5. 样式（粗体、斜体）- 尽力保留
6. 其他样式 - 忽略或降级处理
```

#### 核心转换规则

| HTML 元素 | Markdown 输出 | 备注 |
|-----------|--------------|------|
| `<h1>-<h6>` | `# - ######` | 标题层级 |
| `<p>` | 段落 + 空行 | 自动换行 |
| `<strong>/<b>` | `**粗体**` | 保留 |
| `<em>/<i>` | `*斜体*` | 保留 |
| `<a href>` | `[文本](URL)` | 绝对路径 |
| `<img src>` | `![alt](本地路径)` | 下载后替换 |
| `<ul>/<ol>` | `- / 1.` | 嵌套列表 |
| `<blockquote>` | `> 引用` | 保留 |
| `<code>` | `` `代码` `` | 行内代码 |
| `<pre>` | ` ```代码块``` ` | 多行代码 |
| `<table>` | Markdown 表格 | GFM 格式 |
| `<br>` | `  \n` | 硬换行 |
| `<hr>` | `---` | 分隔线 |

#### 特殊处理
```javascript
// 1. 嵌套列表缩进
<ul>
  <li>Level 1
    <ul>
      <li>Level 2</li>
    </ul>
  </li>
</ul>
→
- Level 1
  - Level 2

// 2. 复杂表格降级
// 如果表格包含合并单元格 → 转为 HTML 注释保留原结构
```

---

### 功能 3: 媒体文件处理

#### 支持的媒体类型
- ✅ 图片: `jpg, png, gif, svg, webp`
- ✅ 视频: `mp4, webm` (链接或下载)
- ✅ 音频: `mp3, wav` (链接或下载)

#### 下载流程

```
1. 提取媒体 URL (src/href 属性)
   ↓
2. 转换为绝对路径
   ↓
3. 使用 Fetch API 下载 Blob
   ↓
4. 通过 chrome.downloads 保存到 tmp/时间戳/media/
   ↓
5. 替换 Markdown 中的路径为相对路径
```

#### 文件命名规则
```
原始URL: https://example.com/images/photo.jpg?v=123
保存为: tmp/20250111_143025/media/photo_a3f2.jpg

格式: {原始文件名}_{hash前4位}.{扩展名}
```

#### 跨域处理
```javascript
// manifest.json 添加权限
"permissions": [
  "downloads",
  "<all_urls>"  // 允许访问所有域名
]

// 使用 background script 下载
chrome.runtime.sendMessage({
  type: 'download',
  url: imageUrl
});
```

---

### 功能 4: 文件组织与保存

#### 目录结构
```
tmp/
└── 20250111_143025/          # 时间戳目录
    ├── content.md            # 转换后的 Markdown
    ├── media/                # 媒体文件
    │   ├── image_001.jpg
    │   ├── image_002.png
    │   └── video_001.mp4
    └── metadata.json         # 元数据
```

#### metadata.json 示例
```json
{
  "url": "https://example.com/article",
  "title": "Article Title",
  "timestamp": "2025-01-11T14:30:25.123Z",
  "mediaFiles": [
    {
      "original": "https://example.com/image.jpg",
      "local": "media/image_001.jpg",
      "type": "image/jpeg"
    }
  ],
  "statistics": {
    "characters": 5420,
    "images": 3,
    "links": 15
  }
}
```

---

## 用户交互设计

### 1. 触发方式

#### 方式 A: 右键菜单（推荐 V1）
```javascript
chrome.contextMenus.create({
  id: "convertToMarkdown",
  title: "转换为 Markdown",
  contexts: ["page", "selection"]
});
```

#### 方式 B: 工具栏按钮
点击扩展图标 → 弹出菜单 → 选择转换选项

#### 方式 C: 快捷键
`Ctrl+Shift+M` (Windows) / `Cmd+Shift+M` (Mac)

### 2. 转换选项

用户可选择:
- [ ] 转换整个页面
- [ ] 转换选中区域
- [ ] 包含/排除图片
- [ ] 包含/排除视频
- [ ] 下载媒体文件 / 仅保留链接

### 3. 进度反馈

```
[进度条界面]
┌─────────────────────────────┐
│ 正在转换...                 │
│ ████████░░░░░░░░ 45%        │
│ 已下载 3/8 张图片            │
└─────────────────────────────┘
```

### 4. 完成通知

```javascript
chrome.notifications.create({
  type: 'basic',
  title: '转换完成',
  message: '已保存到 tmp/20250111_143025/',
  iconUrl: 'icons/success.png'
});
```

---

## 技术难点与解决方案

### 难点 1: 动态加载内容

**问题:** SPA 应用、懒加载图片可能未在 DOM 中

**方案:**
1. 等待页面完全加载（监听 `readyState`）
2. 滚动到底部触发懒加载
3. 监听 DOM 变化（`MutationObserver`）
4. 提供手动"等待加载"选项

### 难点 2: 样式到 Markdown 的映射

**问题:** Markdown 不支持颜色、字体等样式

**方案:**
```markdown
<!-- V1 策略: 降级处理 -->
<span style="color: red; font-size: 24px">重要</span>
→ **重要** (保留粗体语义)

<!-- 保留原始 HTML 作为注释 -->
**重要**
<!-- 原始样式: color: red; font-size: 24px -->
```

### 难点 3: 复杂表格转换

**问题:** rowspan/colspan 在 Markdown 中无法表示

**方案:**
```markdown
<!-- 简单表格 → 标准 Markdown -->
| 列1 | 列2 |
|-----|-----|
| A   | B   |

<!-- 复杂表格 → HTML 代码块 -->
```html
<table>
  <tr>
    <td rowspan="2">合并单元格</td>
  </tr>
</table>
```
```

### 难点 4: 大文件处理

**问题:** 长文章或大量图片导致内存溢出

**方案:**
1. 分块处理 DOM (每次处理 500 个节点)
2. 图片按需下载（队列机制，最多并发 5 个）
3. 流式写入文件（使用 StreamSaver.js）

---

## 性能优化

### 1. 转换性能

| 指标 | 目标 | 策略 |
|------|------|------|
| 小页面 (<100KB) | <1s | 同步处理 |
| 中等页面 (<1MB) | <3s | 异步分块 |
| 大页面 (>1MB) | <10s | Worker 线程 |

### 2. 内存优化

```javascript
// 使用 WeakMap 避免内存泄漏
const nodeCache = new WeakMap();

// 及时释放 Blob URL
URL.revokeObjectURL(blobUrl);

// 限制并发下载
const downloadQueue = new PQueue({ concurrency: 5 });
```

---

## 安全考虑

### 1. XSS 防护
```javascript
// 清理潜在的恶意脚本
function sanitizeHTML(html) {
  const temp = document.createElement('div');
  temp.textContent = html; // 自动转义
  return temp.innerHTML;
}
```

### 2. URL 验证
```javascript
// 仅下载 http/https 协议的资源
if (!url.startsWith('http://') && !url.startsWith('https://')) {
  console.warn('跳过非 HTTP 资源:', url);
  return;
}
```

### 3. 文件大小限制
```javascript
const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB
if (blob.size > MAX_FILE_SIZE) {
  throw new Error('文件过大，跳过下载');
}
```

---

## 开源参考项目

### 1. Turndown
- **仓库:** https://github.com/mixmark-io/turndown
- **用途:** HTML → Markdown 转换核心
- **特点:** 可扩展规则系统

### 2. MarkDownload
- **仓库:** https://github.com/deathau/markdownload
- **用途:** 浏览器扩展架构参考
- **特点:** 支持模板自定义

### 3. SingleFile
- **仓库:** https://github.com/gildas-lormeau/SingleFile
- **用途:** 完整页面保存技术
- **特点:** 处理动态内容

### 4. Readability
- **仓库:** https://github.com/mozilla/readability
- **用途:** 提取主要内容
- **特点:** 去除广告和导航

---

## V1 版本范围

### ✅ 包含功能
1. 基础 HTML → Markdown 转换
   - 标题、段落、列表
   - 粗体、斜体、链接
   - 图片下载和引用
   - 代码块、引用块
   - 简单表格

2. 复制限制突破
   - 绕过 user-select: none
   - 直接读取 DOM 内容

3. 媒体文件保存
   - 图片下载（jpg, png, gif, webp）
   - 保存到时间戳目录

4. 基础 UI
   - 右键菜单触发
   - 转换进度提示
   - 完成通知

### ❌ 不包含（后续版本）
- 视频/音频下载（V2）
- 自定义转换模板（V2）
- 云端同步（V3）
- OCR 图片识别（V3）
- Notion/Obsidian 集成（V3）

---

## 开发计划

### 阶段 1: 核心引擎 (Week 1-2)
- [x] 项目脚手架搭建
- [ ] HTML → Markdown 转换器
- [ ] DOM 遍历和解析
- [ ] 基础单元测试

### 阶段 2: 媒体处理 (Week 2-3)
- [ ] 图片下载模块
- [ ] 文件管理系统
- [ ] 路径替换逻辑

### 阶段 3: 扩展集成 (Week 3-4)
- [ ] Manifest V3 配置
- [ ] Content Script 注入
- [ ] Background Service Worker
- [ ] 消息传递机制

### 阶段 4: UI 与交互 (Week 4)
- [ ] 右键菜单
- [ ] 进度反馈
- [ ] 通知系统

### 阶段 5: 测试与发布 (Week 5)
- [ ] 多网站兼容性测试
- [ ] 性能优化
- [ ] Chrome Web Store 发布准备

---

## 测试策略

### 1. 单元测试
```javascript
// html-to-markdown.test.js
test('converts heading', () => {
  const html = '<h1>Title</h1>';
  expect(convert(html)).toBe('# Title\n');
});
```

### 2. 集成测试
- 测试网站列表:
  - Wikipedia（复杂表格）
  - Medium（富文本编辑器）
  - GitHub（代码高亮）
  - 知乎（动态加载）
  - CSDN（复制限制）

### 3. 性能测试
```javascript
// 测试 10,000 节点的页面转换时间
console.time('conversion');
convertToMarkdown(largePage);
console.timeEnd('conversion'); // 应 < 5s
```

---

## 依赖项

```json
{
  "dependencies": {
    "turndown": "^7.1.2",
    "turndown-plugin-gfm": "^1.0.2"
  },
  "devDependencies": {
    "@types/chrome": "^0.0.254",
    "jest": "^29.7.0",
    "webpack": "^5.89.0",
    "webpack-cli": "^5.1.4"
  }
}
```

---

## 许可证

MIT License

---

## 变更日志

### V1.0.0 (2025-01-11)
- 初始设计文档
- 确定核心功能范围
- 技术架构设计完成
