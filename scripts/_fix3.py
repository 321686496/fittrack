import re
path = r"d:\app\projects\health_training\scripts\extract_default_character_frames.py"
with open(path, "r", encoding="utf-8") as f:
    c = f.read()
m = "Q" + "\u7248\u5361\u901a\u5065\u8eab\u89d2\u8272\u89c6\u9891\u5236\u4f5c" + ".mp4"
f2 = "Q" + "\u7248\u5065\u8eab\u89d2\u8272\u89c6\u9891\u5236\u4f5c" + ".mp4"
new = "VIDEO_MAP = [(m, 'default_male', 12, 12, 1.0), (f2, 'default_female', 12, 12, 1.0)]"
c = re.sub(r"VIDEO_MAP = \[.*?\]", new, c, flags=re.DOTALL)
with open(path, "w", encoding="utf-8") as f:
    f.write(c)
print("Fixed")