"""
从视频素材提取帧并做洋红(#FF00FF)色键抠图，输出透明PNG帧序列。

用法:
  python scripts/extract_video_frames.py

输入: skinanimalandimage/ 下的 mp4 文件
输出: fittrack_flutter/assets/opponent/video_frames/ 下的 PNG 序列

帧命名规则:
  {skin_id}_idle_{idx:04d}.png   待机帧
  {skin_id}_train_{idx:04d}.png  训练帧
"""

import os
import sys
import cv2
import numpy as np
from PIL import Image

SRC_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'skinanimalandimage')
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                       'fittrack_flutter', 'assets', 'opponent', 'video_frames')

# 视频 → 皮肤映射
# (视频文件名, 皮肤ID, 目标fps, 待机帧数, 训练起始秒)
VIDEO_MAP = [
    # 晨光起步者: 10s视频, 前2s=待机, 后8s=训练
    ('Q版少年运动动画生成.mp4', 'beginner', 12, 24, 2.0),
    # 熔铁匠人: 4s视频, 取前1s为待机, 剩余为训练
    ('Q版熔铁匠人动画生成.mp4', 'iron', 12, 12, 1.0),
    # 风行游侠: 10s视频, 取前1s为待机, 剩余为训练
    ('Q版忍者角色动画生成.mp4', 'ninja', 12, 12, 1.0),
    # 传承导师: 4s视频, 取前1s为待机, 剩余为训练
    ('Q版卡通导师动画生成.mp4', 'ambassador', 12, 12, 1.0),
]

MAGENTA = np.array([255, 0, 255], dtype=np.uint8)
TOLERANCE = 60  # 色键容差


def extract_frames_opencv(video_path: str, target_fps: int = 12) -> list:
    """用 OpenCV 提取帧，返回帧列表 (RGB numpy arrays)"""
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"  [ERROR] Cannot open {video_path}")
        return []

    src_fps = cap.get(cv2.CAP_PROP_FPS)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(f"    Source: {src_fps:.1f}fps, {total} frames, target: {target_fps}fps")

    # 计算跳帧间隔
    interval = max(1, round(src_fps / target_fps))

    frames = []
    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if frame_idx % interval == 0:
            # BGR → RGB
            frames.append(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        frame_idx += 1

    cap.release()
    print(f"    Extracted: {len(frames)} frames")
    return frames


def cutout_magenta(img: np.ndarray) -> np.ndarray:
    """洋红色键抠图，返回 RGBA"""
    if img.shape[2] == 4:
        img = img[:, :, :3]
    diff = np.abs(img.astype(np.int16) - MAGENTA.astype(np.int16))
    mask = np.all(diff < TOLERANCE, axis=2)
    alpha = np.where(mask, 0, 255).astype(np.uint8)
    rgba = np.dstack([img, alpha])
    return rgba


def process_skin(video_name: str, skin_id: str, target_fps: int,
                 idle_frame_count: int, train_start_sec: float):
    video_path = os.path.join(SRC_DIR, video_name)
    if not os.path.exists(video_path):
        print(f"  [SKIP] {video_name} not found")
        return

    print(f"\n  Processing: {video_name} -> {skin_id}")

    # 1. 提取全部帧
    all_frames = extract_frames_opencv(video_path, target_fps)
    if not all_frames:
        return

    # 2. 计算待机/训练分界
    train_start_idx = int(train_start_sec * target_fps)

    # 3. 处理待机帧
    idle_out = os.path.join(OUT_DIR, f'{skin_id}_idle')
    os.makedirs(idle_out, exist_ok=True)
    idle_count = min(idle_frame_count, len(all_frames))
    for i in range(idle_count):
        rgba = cutout_magenta(all_frames[i])
        out_path = os.path.join(idle_out, f'{skin_id}_idle_{i:04d}.png')
        Image.fromarray(rgba).save(out_path)
    print(f"    Idle frames: {idle_count}")

    # 4. 处理训练帧
    train_out = os.path.join(OUT_DIR, f'{skin_id}_train')
    os.makedirs(train_out, exist_ok=True)
    train_idx = 0
    for i in range(train_start_idx, len(all_frames)):
        rgba = cutout_magenta(all_frames[i])
        out_path = os.path.join(train_out, f'{skin_id}_train_{train_idx:04d}.png')
        Image.fromarray(rgba).save(out_path)
        train_idx += 1
    print(f"    Train frames: {train_idx}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Output dir: {OUT_DIR}")

    for video_name, skin_id, fps, idle_count, train_start in VIDEO_MAP:
        process_skin(video_name, skin_id, fps, idle_count, train_start)

    # 列出结果
    print("\n=== Result ===")
    for skin_id in ['beginner', 'iron', 'ninja', 'ambassador']:
        idle_dir = os.path.join(OUT_DIR, f'{skin_id}_idle')
        train_dir = os.path.join(OUT_DIR, f'{skin_id}_train')
        idle_count = len([f for f in os.listdir(idle_dir) if f.endswith('.png')]) if os.path.isdir(idle_dir) else 0
        train_count = len([f for f in os.listdir(train_dir) if f.endswith('.png')]) if os.path.isdir(train_dir) else 0
        print(f"  {skin_id}: idle={idle_count}, train={train_count}")


if __name__ == '__main__':
    main()
