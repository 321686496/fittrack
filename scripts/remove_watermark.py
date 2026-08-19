#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
去除默认角色素材和帧序列中的"豆包AI生成"水印。

水印位置：右下角，约占图片宽度的 15%、高度的 8%。
处理方式：将水印区域替换为透明像素（RGBA alpha=0）。

用法:
  python scripts/remove_watermark.py
"""
import os
import numpy as np
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE_DIR, 'fittrack_flutter', 'assets', 'opponent')

# 需要处理的文件
FILES_TO_PROCESS = [
    # 精灵图
    'default_male.png',
    'default_female.png',
]

# 视频帧目录
FRAME_DIRS = [
    'default_male_idle',
    'default_male_train',
    'default_female_idle',
    'default_female_train',
]


def remove_watermark_from_image(img: Image.Image) -> Image.Image:
    """去除右下角水印区域，设为透明，并清除该区域的背景色残影。"""
    img = img.convert('RGBA')
    arr = np.array(img)
    h, w = arr.shape[:2]

    # 水印区域：右下角约 18% 宽 × 10% 高（比水印文字稍大，覆盖残影）
    wm_h = int(h * 0.10)
    wm_w = int(w * 0.18)
    y_start = h - wm_h
    x_start = w - wm_w

    # 将该区域完全设为透明（RGB 也清零，避免半透明残影）
    arr[y_start:, x_start:, 0] = 0
    arr[y_start:, x_start:, 1] = 0
    arr[y_start:, x_start:, 2] = 0
    arr[y_start:, x_start:, 3] = 0

    return Image.fromarray(arr, 'RGBA')


def process_sprite(filename: str):
    path = os.path.join(OUT_DIR, filename)
    if not os.path.exists(path):
        print(f'[SKIP] {filename} not found')
        return

    img = Image.open(path)
    result = remove_watermark_from_image(img)
    result.save(path, 'PNG')
    print(f'[OK] {filename}: watermark removed')


def process_frames():
    frames_dir = os.path.join(OUT_DIR, 'video_frames')
    total = 0
    for dir_name in FRAME_DIRS:
        dir_path = os.path.join(frames_dir, dir_name)
        if not os.path.isdir(dir_path):
            print(f'[SKIP] {dir_name} not found')
            continue
        count = 0
        for f in os.listdir(dir_path):
            if not f.endswith('.png'):
                continue
            fpath = os.path.join(dir_path, f)
            img = Image.open(fpath)
            result = remove_watermark_from_image(img)
            result.save(fpath, 'PNG')
            count += 1
        total += count
        print(f'[OK] {dir_name}: {count} frames processed')
    print(f'Total frames: {total}')


def main():
    print('=== Processing sprites ===')
    for f in FILES_TO_PROCESS:
        process_sprite(f)

    print('\n=== Processing video frames ===')
    process_frames()

    print('\nDone!')


if __name__ == '__main__':
    main()
