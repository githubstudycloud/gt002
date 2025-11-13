# Installation Guide

## Quick Start

### Prerequisites

- Node.js 16+ and npm
- Chrome or Edge browser
- Python 3.x (optional, for generating icons)

### Installation Steps

#### 1. Clone or Download the Project

```bash
cd web-to-markdown-extension
```

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Generate Icons (Optional)

If you want to use placeholder icons:

```bash
cd icons
pip install pillow
python generate-icons.py
cd ..
```

Or manually create icon files (icon16.png, icon32.png, icon48.png, icon128.png) in the `icons/` directory.

#### 4. Build the Extension

For development (with source maps):
```bash
npm run dev
```

For production:
```bash
npm run build
```

This will create a `dist/` directory with the compiled extension.

**Note:** Since we're not using webpack in V1 (to keep it simple), you can skip the build step and load the extension directly from the source.

#### 5. Load Extension in Chrome/Edge

1. Open your browser and navigate to:
   - **Chrome**: `chrome://extensions/`
   - **Edge**: `edge://extensions/`

2. Enable **Developer mode** (toggle in the top-right corner)

3. Click **Load unpacked**

4. Select the project directory (`web-to-markdown-extension/`)
   - Or select the `dist/` directory if you built the project

5. The extension should now appear in your extensions list!

---

## Usage

### Method 1: Right-Click Menu

1. Navigate to any webpage
2. Right-click anywhere on the page
3. Select **"Convert page to Markdown"**
4. Wait for the conversion to complete
5. Files will be saved to your Downloads folder in `tmp/YYYYMMDD_HHMMSS/`

### Method 2: Extension Popup

1. Click the extension icon in your browser toolbar
2. View page statistics
3. Configure options (download media, lazy load images, etc.)
4. Click **"Convert Entire Page"**

### Method 3: Keyboard Shortcut

- **Windows/Linux**: `Ctrl + Shift + M`
- **macOS**: `Cmd + Shift + M`

### Method 4: Select Element

1. Right-click and select **"Select element to convert"**
2. Click on any element on the page
3. Only that element will be converted to Markdown

---

## Output Structure

After conversion, files are organized in a timestamp directory:

```
Downloads/
└── tmp/
    └── 20250111_143025/
        ├── content.md          # Converted Markdown
        ├── metadata.json       # Page metadata
        └── media/              # Downloaded images/videos
            ├── image_001.jpg
            ├── image_002.png
            └── ...
```

### content.md Example

```markdown
---
title: "Article Title"
source: https://example.com/article
author: "John Doe"
date: 2025-01-11
created: 2025-01-11T14:30:25.123Z
---

# Article Title

This is the converted content...

![Image description](media/image_001.jpg)
```

---

## Configuration

### Extension Options

Access options by clicking the extension icon:

- **Download media files**: Automatically download images, videos, etc.
- **Load lazy images**: Trigger lazy-loaded images before conversion
- **Wait for dynamic content**: Wait for JavaScript-rendered content
- **Include metadata**: Add YAML frontmatter to Markdown file

### Storage Location

Files are saved to your browser's default Downloads folder under `tmp/`.

To change the download location, you'll need to modify your browser's download settings.

---

## Troubleshooting

### Extension Not Loading

**Problem**: "Manifest file is missing or unreadable"

**Solution**: Ensure you're selecting the root directory containing `manifest.json`

---

### Content Script Errors

**Problem**: "Could not establish connection. Receiving end does not exist."

**Solution**:
1. Refresh the webpage you're trying to convert
2. Reload the extension from `chrome://extensions/`

---

### No Files Downloaded

**Problem**: Files aren't appearing in Downloads folder

**Solution**:
1. Check your browser's download permissions
2. Look in your Downloads folder under `tmp/`
3. Check browser console for errors (F12)

---

### Images Not Downloading

**Problem**: Images show original URLs instead of local paths

**Solution**:
1. Enable "Download media files" in extension options
2. Check that the website allows cross-origin image loading
3. Some images may be blocked by CORS - this is a browser limitation

---

### Dynamic Content Missing

**Problem**: Content loaded by JavaScript is not captured

**Solution**:
1. Enable "Wait for dynamic content" in options
2. Scroll to the bottom of the page before converting
3. Wait a few seconds after page load before converting

---

## Development

### Project Structure

```
web-to-markdown-extension/
├── manifest.json              # Extension configuration
├── src/
│   ├── background/
│   │   └── service-worker.js  # Background tasks
│   ├── content/
│   │   └── content.js         # Page interaction
│   ├── popup/
│   │   ├── popup.html         # UI
│   │   ├── popup.css          # Styles
│   │   └── popup.js           # UI logic
│   └── utils/
│       ├── html-to-markdown.js    # Converter
│       ├── dom-parser.js          # DOM extraction
│       ├── media-downloader.js    # Media handling
│       └── file-manager.js        # File organization
├── icons/                     # Extension icons
├── package.json
└── README.md
```

### Making Changes

1. Edit source files in `src/`
2. Reload extension in browser (click reload icon in `chrome://extensions/`)
3. Refresh any open webpages to use updated content script
4. Test the changes

### Debugging

**Content Script**:
- Open page you want to debug
- Open DevTools (F12)
- Check Console tab for errors
- Use `console.log()` in content.js

**Background Script**:
- Go to `chrome://extensions/`
- Click "Inspect views: service worker"
- Check Console tab

**Popup**:
- Right-click popup
- Select "Inspect"

---

## Testing

### Test Websites

Try the extension on these types of sites:

1. **Simple Article**: Wikipedia article
2. **Rich Media**: Medium blog post
3. **Complex Layout**: GitHub repository page
4. **Dynamic Content**: Twitter/X feed
5. **Copy Protection**: Sites with `user-select: none`

### Known Limitations (V1)

- Large files (>50MB) may fail to download
- Complex table merging not supported
- Some CSS-generated content may not convert
- CORS may block some cross-origin images
- Video/audio files create links, not embedded files

---

## Uninstallation

1. Go to `chrome://extensions/`
2. Find "Web to Markdown"
3. Click "Remove"
4. Confirm removal

Downloaded files in `tmp/` folder will remain on your computer.

---

## Next Steps

- Read [DESIGN_V1.md](DESIGN_V1.md) for technical details
- Report issues on GitHub
- Contribute improvements via pull requests
- Star the repository if you find it useful!

---

## FAQ

**Q: Can I use this on Chrome and Edge?**
A: Yes, it's fully compatible with both browsers.

**Q: Does it work offline?**
A: The extension works offline, but media downloads require internet.

**Q: Is my data sent to any server?**
A: No, everything runs locally in your browser.

**Q: Can I customize the Markdown format?**
A: V1 uses a fixed format, but V2 will add customization options.

**Q: Why are some styles lost?**
A: Markdown has limited styling support. We prioritize text content.

**Q: Can I convert password-protected pages?**
A: Yes, as long as you're logged in and can view the page.

---

## Support

- **Documentation**: See README.md and DESIGN_V1.md
- **Issues**: Report bugs on GitHub Issues
- **Questions**: Open a GitHub Discussion

---

## License

MIT License - See LICENSE file for details
