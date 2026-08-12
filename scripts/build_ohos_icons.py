"""Build HarmonyOS app icons from transparent logo PNG."""
from PIL import Image
import os

SRC = r"d:\app\projects\health_training\logo\logo_nobg.png"
BASE = r"d:\app\projects\health_training\fittrack_flutter\ohos\entry\src\main\resources"

# HarmonyOS icon sizes per density (actual sizes from existing icons)
OHOS_DENSITIES = {
    "phone-sdpi": 41,
    "phone-ldpi": 81,
    "phone-mdpi": 54,
    "phone-xldpi": 108,
    "phone-xxldpi": 162,
    "phone-xxxldpi": 216,
    "base": 54,  # fallback
}

def make_icon(src_img, canvas_size, padding_ratio=0.12):
    """Place logo on white background with proper padding."""
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 255))
    padding = int(canvas_size * padding_ratio)
    logo_size = canvas_size - 2 * padding
    logo = src_img.resize((logo_size, logo_size), Image.LANCZOS)
    x = (canvas_size - logo_size) // 2
    y = (canvas_size - logo_size) // 2
    canvas.paste(logo, (x, y), logo)
    return canvas.convert("RGB")

src = Image.open(SRC).convert("RGBA")

for density, size in OHOS_DENSITIES.items():
    icon = make_icon(src, size)
    # icon.png
    path = os.path.join(BASE, density, "media", "icon.png")
    icon.save(path)
    print(f"{density} icon.png: {size}x{size} -> saved")
    # icon_startwindow.png (same size)
    path2 = os.path.join(BASE, density, "media", "icon_startwindow.png")
    icon.save(path2)
    print(f"{density} icon_startwindow.png: {size}x{size} -> saved")

print("\nAll HarmonyOS icons built!")
