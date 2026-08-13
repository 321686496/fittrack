#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LiftTrack 美术资源生成脚本（本地程序化绘制，无需 API）

生成健身 App 所需的封面/横幅背景资源：
  - 5 张目标主题封面（增肌/减脂/塑形/保持健康/力量）
  - 7 张系统课程封面
  - 5 张首页 Banner 背景

风格：深色高级质感 + 主题色径向辉光 + 器材剪影 + 斜向光带 + 暗角。
所有图片不含文字/水印，可直接作为 Flutter 资源使用。

依赖：Pillow（pip install pillow）
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_COVERS = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "art")
OUT_BANNERS = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "banners")

# ── 主题配色 ─────────────────────────────────────────────────────
THEMES = {
    # key: (底色1, 底色2, 主强调色, 次强调色)
    "bulk":     ((0x1A, 0x12, 0x0C), (0x24, 0x17, 0x0E), (0xFF, 0x6B, 0x35), (0xFF, 0xD2, 0x7A)),
    "cut":      ((0x17, 0x0D, 0x0F), (0x22, 0x12, 0x12), (0xFF, 0x4D, 0x4D), (0xFF, 0xB0, 0x4D)),
    "shape":    ((0x12, 0x0E, 0x18), (0x1C, 0x14, 0x26), (0xF4, 0x72, 0xB6), (0xC0, 0x84, 0xFC)),
    "keep":     ((0x0D, 0x16, 0x12), (0x14, 0x20, 0x18), (0x34, 0xD3, 0x99), (0x86, 0xEF, 0xAC)),
    "strength": ((0x0F, 0x11, 0x18), (0x18, 0x1C, 0x28), (0x38, 0xBD, 0xF8), (0x81, 0x8C, 0xF8)),
}

COURSE_THEMES = {
    "course_beginner_bulk":       "bulk",
    "course_advanced_bulk":       "bulk",
    "course_cut_diet":            "cut",
    "course_hiit_cut":            "cut",
    "course_intermediate_shape":  "shape",
    "course_strength_basic":      "strength",
    "course_keep_health":         "keep",
}

BANNER_THEMES = {
    "banner_teaching":    "strength",
    "banner_premium":     "bulk",
    "banner_plan":        "bulk",
    "banner_achievement": "strength",
    "banner_invitation":  "shape",
}


def _lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def _vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        color = _lerp_color(top, bottom, t)
        for x in range(w):
            px[x, y] = color
    return img


def _radial_glow(size, center, radius, color, alpha=150):
    """在透明层上画径向辉光"""
    w, h = size
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    cx, cy = center
    steps = 60
    for i in range(steps, 0, -1):
        r = radius * i / steps
        a = int(alpha * (1 - i / steps) ** 2)
        if a <= 0:
            continue
        d.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=(color[0], color[1], color[2], a),
        )
    return glow


def _light_streaks(size, color=(255, 255, 255), alpha=26):
    """斜向光带"""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(4):
        y0 = int(h * (0.12 + 0.22 * i))
        x0 = -w // 3
        width = int(w * (0.16 + 0.08 * i))
        d.polygon(
            [
                (x0, y0),
                (x0 + width, y0 + int(h * 0.04)),
                (x0 + width + int(w * 0.08), y0 + int(h * 0.10)),
                (x0 + int(w * 0.08), y0 + int(h * 0.06)),
            ],
            fill=(color[0], color[1], color[2], alpha),
        )
    layer = layer.filter(ImageFilter.GaussianBlur(8))
    return layer


def _vignette(size, strength=110):
    w, h = size
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    cx, cy = w / 2, h / 2
    r = math.hypot(w, h) / 2
    steps = 50
    for i in range(steps):
        rr = r * (0.35 + 0.65 * i / steps)
        a = int(strength * (i / steps) ** 2.2)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=a, width=8)
    mask = mask.filter(ImageFilter.GaussianBlur(20))
    black = Image.new("RGBA", size, (0, 0, 0, 255))
    vign = Image.new("RGBA", size)
    vign.paste(black, (0, 0), mask)
    return vign


# ── 器材剪影（绘制到透明层，返回 RGBA）────────────────────────

def _barbell(w, h, color, scale=1.0):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w / 2, h / 2
    bar_len = int(w * 0.62 * scale)
    bar_h = max(4, int(h * 0.018 * scale))
    # 杠
    d.rounded_rectangle(
        [cx - bar_len / 2, cy - bar_h / 2, cx + bar_len / 2, cy + bar_h / 2],
        radius=bar_h,
        fill=color,
    )
    # 杠铃片
    plate_w = int(bar_len * 0.10)
    plate_h = int(h * 0.30 * scale)
    inner = int(h * 0.09 * scale)
    for side in (-1, 1):
        base = cx + side * (bar_len / 2 - plate_w * 0.55)
        for i in range(3):
            ox = base - side * i * int(plate_w * 0.62)
            ph = plate_h - i * int(h * 0.07 * scale)
            d.rounded_rectangle(
                [ox - plate_w / 2, cy - ph / 2, ox + plate_w / 2, cy + ph / 2],
                radius=int(plate_w / 2),
                fill=color,
            )
        # 锁扣
        d.ellipse([base - side * 2 * plate_w - inner / 2, cy - inner / 2,
                   base - side * 2 * plate_w + inner / 2, cy + inner / 2], fill=color)
    return layer


def _dumbbell(w, h, color, scale=1.0):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w / 2, h / 2
    handle_len = int(w * 0.30 * scale)
    handle_h = max(5, int(h * 0.03 * scale))
    d.rounded_rectangle(
        [cx - handle_len / 2, cy - handle_h / 2, cx + handle_len / 2, cy + handle_h / 2],
        radius=handle_h,
        fill=color,
    )
    ball_r = int(h * 0.13 * scale)
    for side in (-1, 1):
        bx = cx + side * (handle_len / 2 + ball_r * 0.72)
        d.ellipse([bx - ball_r, cy - ball_r, bx + ball_r, cy + ball_r], fill=color)
        small_r = int(ball_r * 0.62)
        d.ellipse([bx - small_r, cy - small_r, bx + small_r, cy + small_r], fill=color)
    return layer


def _kettlebell(w, h, color, scale=1.0):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w / 2, h * 0.56
    bell_r = int(h * 0.18 * scale)
    d.ellipse([cx - bell_r, cy - bell_r, cx + bell_r, cy + bell_r], fill=color)
    # 把手
    handle_r = int(bell_r * 0.78)
    hx, hy = cx, cy - bell_r + int(bell_r * 0.12)
    d.arc(
        [hx - handle_r, hy - handle_r, hx + handle_r, hy + handle_r],
        start=20,
        end=160,
        fill=color,
        width=max(6, int(h * 0.022 * scale)),
    )
    return layer


def _trophy(w, h, color, scale=1.0):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w / 2, h * 0.52
    cup_w = int(w * 0.26 * scale)
    cup_h = int(h * 0.30 * scale)
    # 杯体
    d.pieslice(
        [cx - cup_w / 2, cy - cup_h, cx + cup_w / 2, cy + cup_h * 0.15],
        start=0,
        end=180,
        fill=color,
    )
    d.rectangle(
        [cx - cup_w / 2, cy - cup_h * 0.10, cx + cup_w / 2, cy + cup_h * 0.18],
        fill=color,
    )
    # 把手
    d.arc(
        [cx + cup_w / 2 - int(cup_w * 0.14), cy - cup_h * 0.85,
         cx + cup_w / 2 + int(cup_w * 0.40), cy + cup_h * 0.10],
        start=270,
        end=90,
        fill=color,
        width=max(5, int(h * 0.018 * scale)),
    )
    d.arc(
        [cx - cup_w / 2 - int(cup_w * 0.40), cy - cup_h * 0.85,
         cx - cup_w / 2 + int(cup_w * 0.14), cy + cup_h * 0.10],
        start=90,
        end=270,
        fill=color,
        width=max(5, int(h * 0.018 * scale)),
    )
    # 底座
    d.rounded_rectangle(
        [cx - cup_w * 0.32, cy + cup_h * 0.16, cx + cup_w * 0.32, cy + cup_h * 0.28],
        radius=int(h * 0.01),
        fill=color,
    )
    d.rounded_rectangle(
        [cx - cup_w * 0.52, cy + cup_h * 0.26, cx + cup_w * 0.52, cy + cup_h * 0.36],
        radius=int(h * 0.012),
        fill=color,
    )
    return layer


def _gift(w, h, color, scale=1.0):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = w / 2, h * 0.54
    box_w = int(w * 0.34 * scale)
    box_h = int(h * 0.22 * scale)
    d.rounded_rectangle(
        [cx - box_w / 2, cy - box_h / 2, cx + box_w / 2, cy + box_h / 2],
        radius=int(h * 0.02),
        fill=color,
    )
    # 盖子
    lid_h = int(h * 0.07 * scale)
    d.rounded_rectangle(
        [cx - box_w * 0.56, cy - box_h / 2 - lid_h, cx + box_w * 0.56, cy - box_h / 2],
        radius=int(h * 0.012),
        fill=color,
    )
    # 丝带
    d.rectangle(
        [cx - max(3, int(w * 0.008)), cy - box_h / 2 - lid_h, cx + max(3, int(w * 0.008)), cy + box_h / 2],
        fill=(255, 255, 255),
    )
    # 蝴蝶结
    br = int(h * 0.045 * scale)
    d.ellipse([cx - br * 2, cy - box_h / 2 - lid_h - br * 2, cx, cy - box_h / 2 - lid_h], fill=color)
    d.ellipse([cx, cy - box_h / 2 - lid_h - br * 2, cx + br * 2, cy - box_h / 2 - lid_h], fill=color)
    return layer


SUBJECTS = {
    "barbell": _barbell,
    "dumbbell": _dumbbell,
    "kettlebell": _kettlebell,
    "trophy": _trophy,
    "gift": _gift,
}

COURSE_SUBJECTS = {
    "course_beginner_bulk": "barbell",
    "course_advanced_bulk": "barbell",
    "course_cut_diet": "kettlebell",
    "course_hiit_cut": "kettlebell",
    "course_intermediate_shape": "dumbbell",
    "course_strength_basic": "barbell",
    "course_keep_health": "dumbbell",
}

BANNER_SUBJECTS = {
    "banner_teaching": "dumbbell",
    "banner_premium": "trophy",
    "banner_plan": "barbell",
    "banner_achievement": "trophy",
    "banner_invitation": "gift",
}


def _glow_subject(layer, color, radius):
    glow = layer.filter(ImageFilter.GaussianBlur(radius))
    # 将辉光染成强调色
    glow = glow.point(lambda p: p)
    r, g, b = color
    tint = Image.new("RGBA", glow.size, (r, g, b, 0))
    glow = Image.alpha_composite(glow, tint)
    return glow


def compose(size, theme_key, subject_key, subject_offset=(0, 0), glow_alpha=120):
    """合成一张主题封面/横幅"""
    top, bottom, accent, accent2 = THEMES[theme_key]
    w, h = size

    base = _vertical_gradient(size, top, bottom)
    base = base.convert("RGBA")

    # 左上与右下各一处径向辉光
    glow1 = _radial_glow(size, (int(w * 0.25), int(h * 0.25)), int(min(w, h) * 0.62), accent, alpha=glow_alpha)
    glow2 = _radial_glow(size, (int(w * 0.85), int(h * 0.82)), int(min(w, h) * 0.55), accent2, alpha=glow_alpha)
    base = Image.alpha_composite(base, glow1)
    base = Image.alpha_composite(base, glow2)

    # 斜向光带
    base = Image.alpha_composite(base, _light_streaks(size, alpha=22))

    # 器材剪影（带辉光）
    subject = SUBJECTS[subject_key](w, h, (255, 255, 255), scale=1.0)
    cx, cy = w / 2 + subject_offset[0], h / 2 + subject_offset[1]
    # 手动偏移整层：绘制在放大画布上再裁剪
    pad = int(min(w, h) * 0.12)
    big = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    big.paste(subject, (pad, pad))
    big = big.crop((int(pad + (cx - w / 2)), int(pad + (cy - h / 2)),
                    int(pad + (cx - w / 2) + w), int(pad + (cy - h / 2) + h)))
    glow = _glow_subject(big, accent, int(min(w, h) * 0.035))
    glow = glow.point(lambda p: p)
    # 降低辉光透明度
    glow.putalpha(glow.split()[3].point(lambda p: min(160, p)))
    base = Image.alpha_composite(base, glow)
    base = Image.alpha_composite(base, big)

    # 暗角
    base = Image.alpha_composite(base, _vignette(size, strength=95))
    return base.convert("RGB")


def generate_covers():
    os.makedirs(OUT_COVERS, exist_ok=True)
    size = (512, 512)
    for key, theme in THEMES.items():
        subject = "barbell" if key in ("bulk", "strength") else ("kettlebell" if key == "cut" else "dumbbell")
        img = compose(size, key, subject, subject_offset=(0, int(size[1] * 0.05)))
        path = os.path.join(OUT_COVERS, f"goal_{key}.png")
        img.save(path, optimize=True)
        print("cover:", path)
    for cid, theme in COURSE_THEMES.items():
        subject = COURSE_SUBJECTS[cid]
        img = compose(size, theme, subject, subject_offset=(0, int(size[1] * 0.05)))
        path = os.path.join(OUT_COVERS, f"{cid}.png")
        img.save(path, optimize=True)
        print("cover:", path)


def generate_banners():
    os.makedirs(OUT_BANNERS, exist_ok=True)
    size = (1080, 432)
    for name, theme in BANNER_THEMES.items():
        subject = BANNER_SUBJECTS[name]
        img = compose(size, theme, subject, subject_offset=(int(size[0] * 0.22), 0))
        path = os.path.join(OUT_BANNERS, f"{name}.png")
        img.save(path, optimize=True)
        print("banner:", path)


if __name__ == "__main__":
    generate_covers()
    generate_banners()
    print("done")
