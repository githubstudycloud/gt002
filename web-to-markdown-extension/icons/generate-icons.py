"""
Generate placeholder icons for the extension
Requires: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size, filename):
    """Create a simple icon with 'M' letter"""
    # Create image with gradient-like color
    img = Image.new('RGB', (size, size), color=(102, 126, 234))  # #667eea

    draw = ImageDraw.Draw(img)

    # Draw 'M' text
    try:
        # Try to use a nice font
        font_size = int(size * 0.6)
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()

    # Calculate text position
    text = "M"

    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]

    # Draw text
    draw.text((x, y), text, fill=(255, 255, 255), font=font)

    # Add a subtle border
    draw.rectangle([0, 0, size-1, size-1], outline=(80, 95, 200), width=max(1, size//32))

    # Save
    img.save(filename, 'PNG')
    print(f"Created {filename}")

def main():
    """Generate all icon sizes"""
    script_dir = os.path.dirname(os.path.abspath(__file__))

    sizes = [16, 32, 48, 128]

    for size in sizes:
        filename = os.path.join(script_dir, f'icon{size}.png')
        create_icon(size, filename)

    print("\nAll icons generated successfully!")
    print("These are placeholder icons. Replace them with professional designs before publishing.")

if __name__ == '__main__':
    main()
