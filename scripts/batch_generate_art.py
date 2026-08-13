#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LiftTrack 美术资源批量生成脚本（调用 scripts/gen_image.py 的 MaaS 平台接口）

生成资源：
  - 5 张首页 Banner 背景（assets/images/banners/）
  - 5 张计划目标封面（assets/images/art/goal_*.png）
  - 7 张系统课程封面（assets/images/art/course_*.png）
  - 5 张详情内容配图（assets/images/art/detail_*.png）

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
SIZE = "1024x1024"

STYLE = (
    "premium fitness app visual, dark moody background, cinematic studio lighting, "
    "rich gradient glow, high-end 3D render style, elegant composition, "
    "no text, no words, no watermark, no logo"
)

BANNERS = {
    "banner_teaching": (
        "fitness education banner background, stack of books and a glowing dumbbell, "
        "deep navy background with cyan and violet gradient glow, spacious dark area on left for text, "
        + STYLE
    ),
    "banner_premium": (
        "premium fitness membership banner background, golden trophy and crown on dark luxury background, "
        "amber and gold gradient glow, spacious dark area on left for text, "
        + STYLE
    ),
    "banner_plan": (
        "fitness training plan banner background, barbell with weight plates on dark charcoal background, "
        "orange and amber gradient glow, spacious dark area on left for text, "
        + STYLE
    ),
    "banner_achievement": (
        "fitness achievement banner background, golden medal and stars on deep black background, "
        "gold and teal gradient glow, spacious dark area on left for text, "
        + STYLE
    ),
    "banner_invitation": (
        "invitation reward banner background, elegant gift box with ribbon on dark purple background, "
        "pink and violet gradient glow, spacious dark area on left for text, "
        + STYLE
    ),
}

GOALS = {
    "goal_bulk": (
        "muscle building cover art, powerful 3D barbell and dumbbells with weight plates, "
        "dark charcoal background with orange and gold gradient glow, dynamic energy streaks, "
        + STYLE
    ),
    "goal_cut": (
        "fat burning cover art, dynamic jump rope and battle rope in motion with embers, "
        "dark red-black background with red and orange gradient glow, "
        + STYLE
    ),
    "goal_shape": (
        "body shaping cover art, elegant 3D dumbbell and resistance band with soft pink glow, "
        "dark plum background with pink and purple gradient glow, "
        + STYLE
    ),
    "goal_keep": (
        "health keeping cover art, 3D running shoe and yoga pose silhouette, "
        "dark green background with emerald and mint gradient glow, fresh morning mood, "
        + STYLE
    ),
    "goal_strength": (
        "strength training cover art, massive barbell squat scene with 3D plates, "
        "deep blue background with cyan and indigo gradient glow, power atmosphere, "
        + STYLE
    ),
}

COURSES = {
    "course_beginner_bulk": (
        "beginner muscle building course cover, friendly 3D dumbbells and growth chart, "
        "warm orange gradient on dark background, approachable energetic mood, "
        + STYLE
    ),
    "course_advanced_bulk": (
        "advanced muscle building course cover, heavy 3D barbell with stacked plates and lightning, "
        "intense orange-red gradient on dark background, "
        + STYLE
    ),
    "course_cut_diet": (
        "fat loss nutrition course cover, 3D healthy food bowl and measuring tape, "
        "fresh green and red gradient on dark background, "
        + STYLE
    ),
    "course_hiit_cut": (
        "HIIT fat burning course cover, explosive kettlebell and flame effects, "
        "fiery red-orange gradient on dark background, high intensity mood, "
        + STYLE
    ),
    "course_intermediate_shape": (
        "body shaping course cover, elegant 3D dumbbell with flowing ribbon, "
        "pink and purple gradient on dark background, refined feminine mood, "
        + STYLE
    ),
    "course_strength_basic": (
        "strength basics course cover, 3D barbell with blue energy aura, "
        "cyan and indigo gradient on dark background, technical mood, "
        + STYLE
    ),
    "course_keep_health": (
        "health keeping course cover, 3D heart and sunrise running scene, "
        "emerald and mint gradient on dark background, calm healthy mood, "
        + STYLE
    ),
}

DETAILS = {
    "detail_bulk": (
        "muscle building knowledge illustration, anatomy-inspired 3D muscle figure and dumbbell, "
        "dark background with warm orange gradient glow, premium infographic style, "
        + STYLE
    ),
    "detail_cut": (
        "fat loss nutrition illustration, 3D healthy ingredients and calorie counter, "
        "dark background with fresh green-red gradient glow, premium infographic style, "
        + STYLE
    ),
    "detail_shape": (
        "body shaping illustration, 3D female silhouette doing yoga with pink glow, "
        "dark background with pink-purple gradient glow, premium infographic style, "
        + STYLE
    ),
    "detail_strength": (
        "strength training illustration, 3D barbell and biomechanics diagram with blue glow, "
        "dark background with cyan-indigo gradient glow, premium infographic style, "
        + STYLE
    ),
    "detail_keep": (
        "healthy lifestyle illustration, 3D running heart and sunrise with green glow, "
        "dark background with emerald-mint gradient glow, premium infographic style, "
        + STYLE
    ),
}


def save_to(url: str, target: str):
    os.makedirs(os.path.dirname(target), exist_ok=True)
    tmp = target + ".tmp"
    req = urllib.request.Request(url, headers={"User-Agent": "MaaS-script/1.0"})
    with gi._opener.open(req, timeout=120) as r, open(tmp, "wb") as f:
        f.write(r.read())
    os.replace(tmp, target)


def generate(name: str, prompt: str, target: str):
    print(f"[生成] {name} -> {target}", flush=True)
    for attempt in (1, 2):
        try:
            submit = gi.submit_task(MODEL, prompt, {"size": SIZE})
            task = gi.poll_task(submit["id"], 5, 600)
            if task.get("status") != "succeeded":
                print(f"[失败] {name} status={task.get('status')}", flush=True)
                return False
            url = task.get("result_url")
            if not url:
                print(f"[失败] {name} 无 result_url", flush=True)
                return False
            save_to(url, target)
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

    tasks = []
    if args.only in (None, "banners"):
        tasks += [(n, p, os.path.join(BANNER_DIR, n + ".png")) for n, p in BANNERS.items()]
    if args.only in (None, "covers"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png")) for n, p in GOALS.items()]
    if args.only in (None, "courses"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png")) for n, p in COURSES.items()]
    if args.only in (None, "details"):
        tasks += [(n, p, os.path.join(ART_DIR, n + ".png")) for n, p in DETAILS.items()]
    if args.name:
        tasks = [t for t in tasks if t[0] == args.name]
        if not tasks:
            print(f"未找到资源: {args.name}")
            return

    ok = 0
    for name, prompt, target in tasks:
        if generate(name, prompt, target):
            ok += 1
    print(f"全部完成: 成功 {ok}/{len(tasks)}")


if __name__ == "__main__":
    main()
