# 快速开始指南 (Quick Start)

## 最简安装方法（无需构建）

### 1. 生成图标（可选）

如果没有图标文件，运行：

```bash
cd icons
python generate-icons.py
```

或者手动创建四个 PNG 文件：icon16.png, icon32.png, icon48.png, icon128.png

### 2. 加载扩展

1. 打开 Chrome 或 Edge 浏览器
2. 访问 `chrome://extensions/` 或 `edge://extensions/`
3. 打开右上角的 **"开发者模式"**
4. 点击 **"加载已解压的扩展程序"**
5. 选择 `web-to-markdown-extension` 文件夹
6. 完成！扩展已安装

### 3. 使用

访问任意网页，右键点击 → 选择 **"Convert page to Markdown"**

文件将保存到 **下载文件夹/tmp/日期时间/** 目录下

---

## 核心功能

✅ **突破复制限制** - 绕过 `user-select: none` 等限制
✅ **标准 Markdown** - 转换为通用 Markdown 格式
✅ **自动下载图片** - 保存所有媒体文件到本地
✅ **按时间组织** - 文件自动分类到时间戳目录
✅ **多种触发方式** - 右键菜单 / 工具栏按钮 / 快捷键

---

## 3 种使用方式

### 方式 1: 右键菜单（推荐）
右键点击页面 → **"Convert page to Markdown"**

### 方式 2: 工具栏按钮
点击扩展图标 → 配置选项 → **"Convert Entire Page"**

### 方式 3: 快捷键
按 `Ctrl+Shift+M` (Windows) 或 `Cmd+Shift+M` (Mac)

---

## 输出示例

```
Downloads/tmp/20250111_143025/
├── content.md          # Markdown 文件
├── metadata.json       # 元数据
└── media/              # 图片等媒体文件
    ├── image_001.jpg
    └── image_002.png
```

**content.md** 内容：

```markdown
---
title: "网页标题"
source: https://example.com
created: 2025-01-11T14:30:25Z
---

# 网页标题

这是转换后的内容...

![图片描述](media/image_001.jpg)
```

---

## 常见问题

### Q: 需要安装 Node.js 吗？
**A**: V1 版本不需要！直接加载扩展即可使用。构建工具是可选的。

### Q: 文件保存在哪里？
**A**: 浏览器的默认下载文件夹，`tmp/` 子目录下。

### Q: 支持哪些浏览器？
**A**: Chrome 和 Edge（Manifest V3 兼容）。

### Q: 能转换动态加载的内容吗？
**A**: 可以。在扩展弹出窗口中启用"Wait for dynamic content"选项。

### Q: 图片下载失败怎么办？
**A**: 某些网站的跨域限制可能导致下载失败，此时 Markdown 中会保留原始 URL。

---

## 测试建议

推荐在以下网站测试：

- ✅ **Wikipedia** - 测试复杂表格和图片
- ✅ **Medium** - 测试富文本和代码块
- ✅ **GitHub** - 测试代码高亮
- ✅ **知乎/CSDN** - 测试复制限制突破

---

## 下一步

- 查看 [INSTALLATION.md](INSTALLATION.md) 了解详细安装说明
- 阅读 [DESIGN_V1.md](DESIGN_V1.md) 了解技术设计
- 查看 [README.md](README.md) 了解完整功能

---

## 技术支持

遇到问题？

1. 检查浏览器控制台（F12）是否有错误
2. 刷新网页后重试
3. 在 `chrome://extensions/` 重新加载扩展
4. 提交 GitHub Issue

---

**享受使用！如果觉得有用，请给项目加星 ⭐**
