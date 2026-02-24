from PIL import Image
import os

def prepare_store_icon():
    source_path = "assets/icon/icon_main.png"
    output_path = "assets/store_icon_512.png"
    
    if not os.path.exists(source_path):
        print(f"Error: {source_path} not found.")
        return

    try:
        img = Image.open(source_path)
        print(f"Original size: {img.size}")
        
        # Resize to 512x512 using high-quality resampling
        store_icon = img.resize((512, 512), Image.Resampling.LANCZOS)
        store_icon.save(output_path)
        
        print(f"Successfully created store icon at {output_path} (512x512)")
        
    except Exception as e:
        print(f"Failed to process icon: {e}")

if __name__ == "__main__":
    prepare_store_icon()
