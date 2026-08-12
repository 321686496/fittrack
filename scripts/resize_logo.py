"""Resize logo for Android and iOS app icons."""
from PIL import Image
import os, shutil

SRC = r"d:\app\projects\health_training\qwen_images\logos_v7\logo_v7_08_stairs.jpg"
BASE = r"d:\app\projects\health_training\fittrack_flutter"

# Android mipmap sizes
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

img = Image.open(SRC)

# Android
for density, size in ANDROID_SIZES.items():
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(BASE, "android", "app", "src", "main", "res", f"mipmap-{density}", "ic_launcher.png")
    resized.save(path)
    print(f"Android {density}: {size}x{size} -> {path}")

# iOS
ios_dir = os.path.join(BASE, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
for name, size in IOS_SIZES:
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(ios_dir, name)
    resized.save(path)
    print(f"iOS {name}: {size}x{size} -> {path}")

print("\nDone! All icons resized.")
