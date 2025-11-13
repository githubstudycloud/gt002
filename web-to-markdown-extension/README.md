# Web to Markdown 浏览器扩展

一个强大的浏览器扩展，可将任何网页转换为标准 Markdown 格式，突破复制限制，保存媒体资源。

## 特性

- ✅ **兼容性强** - 支持 Chrome 和 Edge 浏览器
- 🚫 **突破限制** - 绕过网页复制限制（user-select: none 等）
- 📝 **标准格式** - 生成符合 CommonMark/GFM 规范的 Markdown
- 🖼️ **媒体保存** - 自动下载图片、视频等媒体文件
- 📁 **智能组织** - 按时间戳自动分类存储
- ⚡ **性能优化** - 异步处理，支持大型页面

## 项目结构

```
web-to-markdown-extension/
├── manifest.json              # 扩展配置文件
├── src/
│   ├── background/            # 后台服务
│   ├── content/               # 内容脚本
│   ├── popup/                 # 弹出界面
│   └── utils/                 # 工具函数
├── icons/                     # 扩展图标
├── tmp/                       # 输出目录
├── DESIGN_V1.md              # 详细设计文档
└── README.md                  # 本文件
```

## 快速开始

### 最简安装（无需构建）

1. **生成图标**（可选）
   ```bash
   cd icons
   python generate-icons.py
   ```

2. **加载扩展**
   - 打开浏览器访问 `chrome://extensions/`
   - 开启"开发者模式"
   - 点击"加载已解压的扩展程序"
   - 选择 `web-to-markdown-extension` 目录

3. **开始使用**
   - 访问任意网页
   - 右键点击 → "Convert page to Markdown"
   - 文件保存在下载文件夹的 `tmp/` 目录

详细说明请查看 [QUICK_START.md](QUICK_START.md) 和 [INSTALLATION.md](INSTALLATION.md)

## 使用方法

### 方法 1: 右键菜单
1. 在任意网页右键点击
2. 选择"转换为 Markdown"
3. 等待转换完成

### 方法 2: 工具栏按钮
1. 点击浏览器工具栏中的扩展图标
2. 选择转换选项
3. 点击"开始转换"

### 方法 3: 快捷键
- Windows/Linux: `Ctrl+Shift+M`
- macOS: `Cmd+Shift+M`

## 输出格式

转换后的文件保存在 `tmp/` 目录下，按时间戳分类：

```
tmp/
└── 20250111_143025/
    ├── content.md            # Markdown 文件
    ├── media/                # 媒体文件
    │   ├── image_001.jpg
    │   └── image_002.png
    └── metadata.json         # 元数据
```

## 支持的元素

| HTML 元素 | Markdown 输出 |
|-----------|--------------|
| 标题 h1-h6 | `#` - `######` |
| 段落 | 自动段落 |
| 粗体 | `**粗体**` |
| 斜体 | `*斜体*` |
| 链接 | `[文本](URL)` |
| 图片 | `![alt](路径)` |
| 列表 | `- / 1.` |
| 代码 | `` `代码` `` |
| 代码块 | ` ```代码块``` ` |
| 引用 | `> 引用` |
| 表格 | Markdown 表格 |

## 技术栈

- **核心转换**: 自定义 HTML→Markdown 引擎（文字优先策略）
- **扩展框架**: Manifest V3（Chrome/Edge 兼容）
- **媒体处理**: Fetch API + Blob（跨域下载）
- **文件管理**: chrome.downloads API（自动组织）
- **DOM 访问**: TreeWalker API（突破复制限制）

## 核心功能 (V1.0)

✅ **已实现**
- 完整页面转 Markdown
- 选择区域转换
- 交互式元素选择器
- 图片自动下载
- 复制限制突破
- 懒加载图片支持
- 元数据生成（YAML frontmatter）
- 时间戳目录组织
- 右键菜单 + 快捷键 + 工具栏

## 开发计划

- [x] V1.0 - 基础转换功能（已完成）
- [ ] V1.1 - 批量页面转换
- [ ] V1.2 - 自定义转换模板
- [ ] V2.0 - 视频/音频下载支持
- [ ] V2.1 - Notion/Obsidian 直接导入
- [ ] V3.0 - 云端同步和分享

## 参考项目

- [Turndown](https://github.com/mixmark-io/turndown) - HTML→MD 转换
- [MarkDownload](https://github.com/deathau/markdownload) - 扩展架构
- [SingleFile](https://github.com/gildas-lormeau/SingleFile) - 页面保存

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

- 问题反馈: GitHub Issues
- 功能建议: GitHub Discussions
