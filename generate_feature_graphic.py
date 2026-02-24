from PIL import Image, ImageDraw, ImageFont
import os

def create_feature_graphic():
    # Dimensions for Google Play Feature Graphic
    width = 1024
    height = 500
    
    # Create a new image with a gradient background (Blue to Dark Blue)
    image = Image.new('RGB', (width, height), color=(33, 150, 243))
    draw = ImageDraw.Draw(image)
    
    # Draw a gradient
    for y in range(height):
        r = int(33 - (33 - 13) * (y / height))
        g = int(150 - (150 - 71) * (y / height))
        b = int(243 - (243 - 161) * (y / height))
        draw.line([(0, y), (width, y)], fill=(r, g, b))
        
    # Add some decorative geometric shapes (circles)
    draw.ellipse((-100, -100, 300, 300), fill=(255, 255, 255, 30))
    draw.ellipse((800, 300, 1200, 700), fill=(255, 255, 255, 30))
    
    # Load font (using default if custom not found, but try to find a system font)
    # Windows typically has Meiryo or Yu Gothic for Japanese
    font_path = "C:\\Windows\\Fonts\\meiryo.ttc"
    try:
        font = ImageFont.truetype(font_path, 60)
        sub_font = ImageFont.truetype(font_path, 30)
    except:
        # Fallback to default
        font = ImageFont.load_default()
        sub_font = ImageFont.load_default()
        print("Warning: Japanese font not found, using default.")

    # Text content
    title = "ITパスポート"
    subtitle = "一問一答 徹底対策"
    
    # Calculate text position to center it
    # approximate size calculation since load_default doesn't support getbbox well in old versions
    # assuming we found Meiryo
    
    try:
        title_bbox = draw.textbbox((0, 0), title, font=font)
        title_w = title_bbox[2] - title_bbox[0]
        title_h = title_bbox[3] - title_bbox[1]
        
        subtitle_bbox = draw.textbbox((0, 0), subtitle, font=sub_font)
        subtitle_w = subtitle_bbox[2] - subtitle_bbox[0]
        
        draw.text(((width - title_w) / 2, (height - title_h) / 2 - 20), title, font=font, fill=(255, 255, 255))
        draw.text(((width - subtitle_w) / 2, (height - title_h) / 2 + 60), subtitle, font=sub_font, fill=(255, 255, 255, 200))
    except Exception as e:
         # Fallback for simple drawing if advanced text features fail or font issues
         draw.text((width/2 - 100, height/2 - 20), "IT Passport App", fill=(255, 255, 255))
         print(f"Fallback text drawing due to: {e}")

    # Save
    output_path = "assets/feature_graphic.png"
    image.save(output_path)
    print(f"Feature graphic saved to {output_path}")

if __name__ == "__main__":
    create_feature_graphic()
