#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LiftTrack 美术资源批量生成脚本（调用 scripts/gen_image.py 的 MaaS 平台接口）

生成资源：
  - 5 张首页 Banner 背景（assets/images/banners/）  横版 16:9
  - 5 张计划目标封面（assets/images/art/goal_*.png） 正方形 1:1
  - 7 张系统课程封面（assets/images/art/course_*.png） 正方形 1:1
  - 5 张详情内容配图（assets/images/art/detail_*.png） 正方形 1:1

用法:
    python scripts/batch_generate_art.py [--model qwen-image-3.0-pro] [--only banners|covers|courses|details]
"""

import argparse
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_image as gi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "art")
BANNER_DIR = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "banners")

MODEL = os.environ.get("MASS_MODEL", "qwen-image-3.0-pro")
BANNER_SIZE = "16:9"   # 横版，适配首页 Banner 轮播
ART_SIZE = "1:1"       # 正方形，适配封面/详情卡片

# 统一风格基底：强调高级质感 + 无文字（UI 层会叠加文案）
STYLE = (
    "ultra-detailed cinematic 3D render, 8k quality, volumetric studio lighting, "
    "soft depth of field, rich gradient glow, premium fitness app aesthetic, "
    "photorealistic metallic and matte materials, dramatic dark atmosphere, "
    "subtle particle and light dust effects, elegant composition, "
    "no text, no words, no letters, no watermark, no logo, no human face"
)

# Banner 专用：横版构图 + 左侧留暗区（UI 文字叠加在左侧）
BANNER_STYLE = (
    "wide horizontal banner composition, main subject positioned on the right third, "
    "spacious dark negative space on the left side for text overlay, "
    "cinematic left-to-right lighting falloff" + ", " + STYLE
)

# ── 首页 Banner 背景（5 张）──────────────────────────────────────
BANNERS = {
    "banner_teaching": (
        "fitness education banner background, an open anatomy book with glowing 3D muscle diagrams "
        "floating above it, a sleek dumbbell resting on the book, deep navy blue background "
        "with cyan and violet gradient glow, knowledge and training combined concept, "
        + BANNER_STYLE
    ),
    "banner_premium": (
        "premium fitness membership banner background, a golden trophy with a crown emblem, "
        "sparkling gold particles, luxurious dark amber and gold gradient background, "
        "exclusive high-end mood, "
        + BANNER_STYLE
    ),
    "banner_plan": (
        "fitness training plan banner background, a heavy barbell with stacked weight plates "
        "on a dark charcoal platform, orange and amber gradient glow, chalk dust in the air, "
        "raw power gym atmosphere, "
        + BANNER_STYLE
    ),
    "banner_achievement": (
        "fitness achievement banner background, a shining gold medal with a ribbon, "
        "glowing stars and light rays, deep black background with gold and teal gradient glow, "
        "victory and glory mood, "
        + BANNER_STYLE
    ),
    "banner_invitation": (
        "invitation reward banner background, an elegant gift box with a glowing ribbon, "
        "floating reward coins and sparkles, dark purple background with pink and violet gradient glow, "
        "celebration and gift mood, "
        + BANNER_STYLE
    ),
}

# ── 目标主题封面（5 张，训练计划/教程共用）────────────────────────
GOALS = {
    "goal_bulk": (
        "muscle building cover art, a powerful 3D barbell with heavy weight plates and dumbbells, "
        "dark charcoal background with intense orange and gold gradient glow, "
        "dynamic energy streaks and embers, raw power atmosphere, "
        "centered square composition, " + STYLE
    ),
    "goal_cut": (
        "fat burning cover art, a dynamic jump rope and battle ropes in motion with flying sweat droplets, "
        "dark red-black background with red and orange gradient glow, "
        "high intensity burning energy, centered square composition, " + STYLE
    ),
    "goal_shape": (
        "body shaping cover art, an elegant 3D dumbbell and resistance band with soft pink glow, "
        "dark plum background with pink and purple gradient glow, "
        "refined feminine energy, centered square composition, " + STYLE
    ),
    "goal_keep": (
        "health keeping cover art, a 3D running shoe and yoga mat with a green leaf, "
        "dark green background with emerald and mint gradient glow, "
        "fresh morning vitality, centered square composition, " + STYLE
    ),
    "goal_strength": (
        "strength training cover art, a massive barbell on a squat rack with 3D weight plates, "
        "deep blue background with cyan and indigo gradient glow, "
        "raw technical power atmosphere, centered square composition, " + STYLE
    ),
}

# ── 系统课程封面（7 张）──────────────────────────────────────────
COURSES = {
    "course_beginner_bulk": (
        "beginner muscle building course cover, friendly 3D dumbbells with a glowing upward growth arrow, "
        "warm orange gradient on dark background, approachable energetic mood, "
        "centered square composition, " + STYLE
    ),
    "course_advanced_bulk": (
        "advanced muscle building course cover, a heavy 3D barbell with stacked plates and crackling lightning, "
        "intense orange-red gradient on dark background, extreme power mood, "
        "centered square composition, " + STYLE
    ),
    "course_cut_diet": (
        "fat loss nutrition course cover, a 3D healthy food bowl with measuring tape and a calorie counter dial, "
        "fresh green and red gradient on dark background, clean nutrition mood, "
        "centered square composition, " + STYLE
    ),
    "course_hiit_cut": (
        "HIIT fat burning course cover, an explosive kettlebell with flame effects and motion blur, "
        "fiery red-orange gradient on dark background, high intensity mood, "
        "centered square composition, " + STYLE
    ),
    "course_intermediate_shape": (
        "body shaping course cover, an elegant 3D dumbbell with a flowing silk ribbon, "
        "pink and purple gradient on dark background, refined feminine mood, "
        "centered square composition, " + STYLE
    ),
    "course_strength_basic": (
        "strength basics course cover, a 3D barbell with a glowing blue energy aura and technical grid lines, "
        "cyan and indigo gradient on dark background, technical precision mood, "
        "centered square composition, " + STYLE
    ),
    "course_keep_health": (
        "health keeping course cover, a 3D glowing heart with a sunrise and running silhouette, "
        "emerald and mint gradient on dark background, calm healthy mood, "
        "centered square composition, " + STYLE
    ),
}

# ── 详情内容配图（5 张）──────────────────────────────────────────
DETAILS = {
    "detail_bulk": (
        "muscle building knowledge illustration, an anatomy-inspired 3D muscle figure with a dumbbell, "
        "glowing muscle fiber details, dark background with warm orange gradient glow, "
        "premium medical infographic style, centered square composition, " + STYLE
    ),
    "detail_cut": (
        "fat loss nutrition illustration, 3D healthy ingredients with a glowing calorie counter, "
        "dark background with fresh green-red gradient glow, premium infographic style, "
        "centered square composition, " + STYLE
    ),
    "detail_shape": (
        "body shaping illustration, a 3D female silhouette in a yoga pose with pink glow, "
        "dark background with pink-purple gradient glow, premium infographic style, "
        "centered square composition, " + STYLE
    ),
    "detail_strength": (
        "strength training illustration, a 3D barbell with a biomechanics diagram and blue glow, "
        "dark background with cyan-indigo gradient glow, premium infographic style, "
        "centered square composition, " + STYLE
    ),
    "detail_keep": (
        "healthy lifestyle illustration, a 3D glowing running heart with a sunrise, "
        "dark background with emerald-mint gradient glow, premium infographic style, "
        "centered square composition, " + STYLE
    ),
}


def save_to(url: str, target: str):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    tmp = target + ".tmp"
    req = urllib.request.Request(url, headers={"User-Agent": "MaaS-script/1.0"})
    with gi._opener.open(req, timeout=120) as r, open(tmp, "wb") as f:
        f.write(r.read())
    os.replace(tmp, target)


def crop_to_aspect(target: str, ratio_w: float, ratio_h: float):
    """部分模型会忽略 size 参数返回 1:1，此处按目标宽高比居中裁剪（banner 用）。"""
    try:
        from PIL import Image
    except ImportError:
        print(f"[跳过] 裁剪需要 Pillow，未安装: {target}")
        return
    img = Image.open(target)
    w, h = img.size
    target_h = int(w * ratio_h / ratio_w)
    if target_h >= h:
        return  # 已满足或更矮，无需裁剪
    top = (h - target_h) // 2
    img.crop((0, top, w, top + target_h)).save(target, optimize=True)
    print(f"[裁剪] {os.path.basename(target)} {w}x{h} -> {w}x{target_h}")


def generate(name: str, prompt: str, target: str, size: str):
    print(f"[生成] {name} ({size}) -> {target}", flush=True)
    for attempt in (1, 2):
        try:
            submit = gi.submit_task(MODEL, prompt, {"size": size})
            task = gi.poll_task(submit["id"], 5, 600)
            if task.get("status") != "succeeded":
                print(f"[失败] {name} status={task.get('status')}", flush=True)
                return False
            url = task.get("result_url")
            if not url:
                print(f"[失败] {name} 无 result_url", flush=True)
                return False
            save_to(url, target)
            # banner 是横版资源：模型可能忽略 16:9 返回 1:1，按显示比例(≈2.37:1)居中裁剪
            if os.path.dirname(target) == BANNER_DIR:
                crop_to_aspect(target, 1024, 432)
            print(f"[完成] {name}", flush=True)
            return True
        except SystemExit:
            # 渠道不可用等错误，重试一次
            if attempt == 2:
                print(f"[失败] {name} 两次尝试均失败", flush=True)
                return False
            print(f"[重试] {name} (attempt {attempt + 1})", flush=True)
            time.sleep(3)
        except Exception as e:
            print(f"[异常] {name}: {e}", flush=True)
            return False
    return False


def main():
    global MODEL
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--only", choices=["banners", "covers", "courses", "details"])
    parser.add_argument("--name", help="只生成指定资源名（如 banner_achievement）")
    args = parser.parse_args()
    MODEL = args.model or MODEL

    os.makedirs(ART_DIR, exist_ok=True)
    os.makedirs(BANNER_DIR, exist_ok=True)

    # (name, prompt, target, size)
    tasks = []
    if args.only in (None, "banners"):
        tasks += [(n, p, os.path.join(BANNER_DIR, n + ".png"), BANNER_SIZE)
                  for n, p in BANNERS.items()]
    if args.only in (None, "covers"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png"), ART_SIZE)
                  for n, p in GOALS.items()]
    if args.only in (None, "courses"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png"), ART_SIZE)
                  for n, p in COURSES.items()]
    if args.only in (None, "details"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png"), ART_SIZE)
                  for n, p in DETAILS.items()]
    if args.name:
        tasks = [t for t in tasks if t[0] == args.name]
        if not tasks:
            print(f"未找到资源: {args.name}")
            return

    ok = 0
    for name, prompt, target, size in tasks:
        if generate(name, prompt, target, size):
            ok += 1
    print(f"全部完成: 成功 {ok}/{len(tasks)}")


if __name__ == "__main__":
    main()
