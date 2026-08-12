"""Build app icons from transparent logo PNG for Android and iOS."""
from PIL import Image
import os

SRC = r"d:\app\projects\health_training\logo\logo_nobg.png"
BASE = r"d:\app\projects\health_training\fittrack_flutter"

# Android mipmap sizes (icon should fill ~75% of the canvas for safe area)
ANDROID_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# iOS AppIcon sizes
IOS_SIZES = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

def make_icon(src_img, canvas_size, padding_ratio=0.12, bg_color=(255, 255, 255)):
    """Place logo on white background with proper padding."""
    canvas = Image.new("RGBA", (canvas_size, canvas_size), bg_color + (255,))
    # Calculate logo size with padding
    padding = int(canvas_size * padding_ratio)
    logo_size = canvas_size - 2 * padding
    # Resize logo to fit
    logo = src_img.resize((logo_size, logo_size), Image.LANCZOS)
    # Center on canvas
    x = (canvas_size - logo_size) // 2
    y = (canvas_size - logo_size) // 2
    canvas.paste(logo, (x, y), logo)  # Use logo as mask for alpha
    return canvas.convert("RGB")

src = Image.open(SRC).convert("RGBA")
print(f"Source: {src.size}, mode: {src.mode}")

# Android
for density, size in ANDROID_SIZES.items():
    icon = make_icon(src, size)
    path = os.path.join(BASE, "android", "app", "src", "main", "res", f"mipmap-{density}", "ic_launcher.png")
    icon.save(path)
    print(f"Android {density}: {size}x{size} -> saved")

# iOS
ios_dir = os.path.join(BASE, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
for name, size in IOS_SIZES:
    icon = make_icon(src, size)
    path = os.path.join(ios_dir, name)
    icon.save(path)
    print(f"iOS {name}: {size}x{size} -> saved")

print("\nAll icons built successfully!")
