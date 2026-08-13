"""
从视频素材提取帧并做纯色背景键控抠图，输出透明PNG帧序列。

用法:
  python scripts/extract_video_frames.py

输入: skinanimalandimage/ 下的 mp4 文件
输出: fittrack_flutter/assets/opponent/video_frames/ 下的 PNG 序列

帧命名规则:
  {skin_id}_idle_{idx:04d}.png   待机帧
  {skin_id}_train_{idx:04d}.png  训练帧

抠图算法（纯色背景键控）:
  1. 从四角区域取中位数颜色作为背景色（每帧独立检测，抗渐变/色偏）
  2. 按到背景色的欧氏距离生成 alpha：容差内全透明，容差-羽化带线性过渡
  3. 半透明边缘做反预乘去污（恢复前景色），低覆盖率像素完全去饱和
  4. 完全不透明但贴近背景的像素按距离做邻近去饱和
  5. 对 alpha 做 1-2 像素腐蚀，彻底移除最外圈的背景色残留（红色描边）
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
# (视频文件名, 皮肤ID, 目标fps, 待机帧数, 训练开始秒数)
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

# 每套皮肤的键控参数（各视频背景色/角色配色差异较大，分开调优）
SKIN_KEY_PARAMS = {
    'beginner':   dict(tolerance=26, feather=18, spill_exp=0.8, spill_extend=2.0, erode=1),
    'iron':       dict(tolerance=24, feather=12, spill_exp=0.8, spill_extend=1.8, erode=1),
    'ninja':      dict(tolerance=36, feather=16, spill_exp=0.6, spill_extend=3.0, erode=2),
    'ambassador': dict(tolerance=26, feather=18, spill_exp=0.8, spill_extend=2.0, erode=1),
}


def detect_bg_color(rgb):
    """取四角区域像素的中位数颜色作为背景色。"""
    h, w = rgb.shape[:2]
    s = max(4, min(h, w) // 36)
    corners = np.concatenate([
        rgb[:s, :s].reshape(-1, 3),
        rgb[:s, -s:].reshape(-1, 3),
        rgb[-s:, :s].reshape(-1, 3),
        rgb[-s:, -s:].reshape(-1, 3),
    ]).astype(np.float32)
    return np.median(corners, axis=0)


def erode_alpha(alpha8, iters):
    """对 alpha 蒙版做 3x3 最小值腐蚀，收缩前景轮廓，清除最外圈背景残留。"""
    for _ in range(iters):
        a = alpha8.astype(np.int32)
        eroded = a.copy()
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                eroded = np.minimum(eroded, np.roll(np.roll(a, dy, axis=0), dx, axis=1))
        alpha8 = np.clip(eroded, 0, 255).astype(np.uint8)
    return alpha8


def cutout_solid_bg(rgb, tolerance=26, feather=18, spill_exp=0.8,
                    spill_extend=2.0, erode=1, unspill_min=0.2):
    """纯色背景键控：软过渡 alpha + 反预乘去污 + 邻近去饱和 + 边缘腐蚀。"""
    arr = rgb.astype(np.float32)
    bg = detect_bg_color(arr)
    dist = np.sqrt(((arr - bg) ** 2).sum(axis=2))
    outer = tolerance + feather

    # 1) alpha：容差内全透明，羽化带线性过渡
    alpha = np.clip((dist - tolerance) / max(feather, 1e-6), 0.0, 1.0)

    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    gray = (r + g + b) / 3.0
    out = arr.copy()
    semi = (alpha > 0) & (alpha < 1)

    # 2) 半透明边缘：反预乘恢复前景色（覆盖率足够时）
    un = semi & (alpha >= unspill_min)
    a_safe = np.maximum(alpha[un], 1e-3)
    out[un, 0] = (r[un] - (1 - a_safe) * bg[0]) / a_safe
    out[un, 1] = (g[un] - (1 - a_safe) * bg[1]) / a_safe
    out[un, 2] = (b[un] - (1 - a_safe) * bg[2]) / a_safe

    # 3) 覆盖率极低的像素接近背景：直接去饱和
    low = semi & (alpha < unspill_min)
    s_low = 0.9 * (1.0 - alpha[low]) ** 0.7
    out[low, 0] = r[low] + (gray[low] - r[low]) * s_low
    out[low, 1] = g[low] + (gray[low] - g[low]) * s_low
    out[low, 2] = b[low] + (gray[low] - b[low]) * s_low

    # 4) 完全不透明但贴近背景的像素：按距离去饱和（清除残余色边）
    band = outer * spill_extend
    near = (alpha >= 1) & (dist < band)
    t = np.clip(1.0 - dist[near] / band, 0.0, 1.0) ** spill_exp
    out[near, 0] = r[near] + (gray[near] - r[near]) * t
    out[near, 1] = g[near] + (gray[near] - g[near]) * t
    out[near, 2] = b[near] + (gray[near] - b[near]) * t

    alpha8 = erode_alpha((alpha * 255).astype(np.uint8), erode)
    rgba = np.dstack([out, alpha8])
    return np.clip(rgba, 0, 255).astype(np.uint8)


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
    params = SKIN_KEY_PARAMS.get(skin_id, SKIN_KEY_PARAMS['beginner'])

    # 3. 处理待机帧
    idle_out = os.path.join(OUT_DIR, f'{skin_id}_idle')
    os.makedirs(idle_out, exist_ok=True)
    idle_count = min(idle_frame_count, len(all_frames))
    for i in range(idle_count):
        rgba = cutout_solid_bg(all_frames[i], **params)
        out_path = os.path.join(idle_out, f'{skin_id}_idle_{i:04d}.png')
        Image.fromarray(rgba).save(out_path)
    print(f"    Idle frames: {idle_count}")

    # 4. 处理训练帧
    train_out = os.path.join(OUT_DIR, f'{skin_id}_train')
    os.makedirs(train_out, exist_ok=True)
    train_idx = 0
    for i in range(train_start_idx, len(all_frames)):
        rgba = cutout_solid_bg(all_frames[i], **params)
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
