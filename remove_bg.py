import os
from PIL import Image

BASE = r'd:\app\projects\health_training\fittrack_flutter\assets\opponent\video_frames'

def remove_background(img, tolerance=30):
    """Remove background color from image, making it transparent."""
    img = img.convert('RGBA')
    pixels = img.load()
    width, height = img.size
    
    # Sample background color from corners
    bg_colors = [
        pixels[0, 0],
        pixels[width-1, 0],
        pixels[0, height-1],
        pixels[width-1, height-1]
    ]
    
    # Average the corner colors
    avg_r = sum(c[0] for c in bg_colors) // 4
    avg_g = sum(c[1] for c in bg_colors) // 4
    avg_b = sum(c[2] for c in bg_colors) // 4
    
    print(f"Background color: RGB({avg_r}, {avg_g}, {avg_b})")
    
    # Remove pixels matching background color
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if (abs(int(r) - avg_r) <= tolerance and 
                abs(int(g) - avg_g) <= tolerance and 
                abs(int(b) - avg_b) <= tolerance):
                pixels[x, y] = (0, 0, 0, 0)
    
    return img

# Process all subdirectories
for folder in os.listdir(BASE):
    folder_path = os.path.join(BASE, folder)
    if not os.path.isdir(folder_path):
        continue
    
    print(f"\nProcessing {folder}...")
    count = 0
    for filename in os.listdir(folder_path):
        if not filename.endswith('.png'):
            continue
        
        filepath = os.path.join(folder_path, filename)
        img = Image.open(filepath)
        img = remove_background(img)
        img.save(filepath, 'PNG')
        count += 1
    
    print(f"Processed {count} frames")

print("\nDone!")
