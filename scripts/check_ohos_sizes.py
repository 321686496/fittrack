from PIL import Image
import os

base = r"d:\app\projects\health_training\fittrack_flutter\ohos\entry\src\main\resources"
densities = ["phone-sdpi", "phone-ldpi", "phone-mdpi", "phone-xldpi", "phone-xxldpi", "phone-xxxldpi"]

for d in densities:
    p = os.path.join(base, d, "media", "icon.png")
    if os.path.exists(p):
        img = Image.open(p)
        print(f"{d}: {img.size}")
