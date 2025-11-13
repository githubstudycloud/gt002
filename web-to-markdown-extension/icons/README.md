# Extension Icons

This directory should contain the extension icons in the following sizes:

- `icon16.png` - 16x16 pixels (browser toolbar)
- `icon32.png` - 32x32 pixels (Windows computers)
- `icon48.png` - 48x48 pixels (extension management page)
- `icon128.png` - 128x128 pixels (Chrome Web Store)

## Creating Icons

You can create these icons using:

1. **Online Tool**: https://www.favicon-generator.org/
2. **Design Software**: Adobe Illustrator, Figma, or Canva
3. **Icon Libraries**: https://icons8.com/ or https://www.flaticon.com/

## Temporary Solution

For development, you can use simple placeholder icons. Here's how to create them:

### Using ImageMagick:
```bash
# Install ImageMagick first
convert -size 16x16 xc:#667eea -pointsize 12 -fill white -gravity center -annotate +0+0 "M" icon16.png
convert -size 32x32 xc:#667eea -pointsize 24 -fill white -gravity center -annotate +0+0 "M" icon32.png
convert -size 48x48 xc:#667eea -pointsize 36 -fill white -gravity center -annotate +0+0 "M" icon48.png
convert -size 128x128 xc:#667eea -pointsize 96 -fill white -gravity center -annotate +0+0 "M" icon128.png
```

### Using Python (PIL):
```python
from PIL import Image, ImageDraw, ImageFont

def create_icon(size, filename):
    img = Image.new('RGB', (size, size), color='#667eea')
    draw = ImageDraw.Draw(img)
    font_size = size // 2
    draw.text((size//2, size//2), 'M', fill='white', anchor='mm')
    img.save(filename)

create_icon(16, 'icon16.png')
create_icon(32, 'icon32.png')
create_icon(48, 'icon48.png')
create_icon(128, 'icon128.png')
```

### Online SVG to PNG Converter:
1. Create an SVG file with your icon design
2. Convert to PNG at different sizes using: https://cloudconvert.com/svg-to-png

## Design Guidelines

- Use simple, recognizable symbols (e.g., a markdown "M" or document icon)
- Maintain consistency across all sizes
- Use the extension's color scheme (#667eea purple gradient)
- Ensure good contrast for visibility
- Test on both light and dark backgrounds
