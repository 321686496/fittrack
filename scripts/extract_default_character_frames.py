#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import cv2
import numpy as np
from PIL import Image

SRC_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'skinanimalandimage')
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)),
                       'fittrack_flutter', 'assets', 'opponent', 'video_frames')

VIDEO_MAP = [
    ('man.mp4', 'default_male', 12, 24, 2.0, False),
    ('woman.mp4', 'default_female', 12, 24, 2.0, True),
]

PROCESS_SIZE = 512
KEY_PARAMS = dict(hue_tol=8, hue_feather=15, spill_exp=0.5, erode=3)


def detect_bg(rgb):
    h, w = rgb.shape[:2]
    s = max(4, min(h, w) // 36)
    wm_h = int(h * 0.12)
    wm_w = int(w * 0.24)
    top = rgb[:s, wm_w:w-wm_w].reshape(-1, 3)
    bottom = rgb[-s:, wm_w:w-wm_w].reshape(-1, 3)
    left = rgb[wm_h:h-wm_h, :s].reshape(-1, 3)
    right = rgb[wm_h:h-wm_h, -s:].reshape(-1, 3)
    edges = np.concatenate([top, bottom, left, right]).astype(np.float32)
    return np.median(edges, axis=0)


def fill_watermark(rgb, bg_color):
    h, w = rgb.shape[:2]
    wm_h = int(h * 0.10)
    wm_w = int(w * 0.22)
    rgb[h - wm_h:, w - wm_w:] = bg_color
    rgb[:wm_h, :wm_w] = bg_color
    return rgb


def morphological_clean(alpha8, erode_iters=2):
    kernel = np.ones((3, 3), np.uint8)
    eroded = cv2.erode(alpha8, kernel, iterations=erode_iters)
    cleaned = cv2.dilate(eroded, kernel, iterations=erode_iters)
    return cleaned


def remove_bottom_shadow(rgba, bg_hsv, hue_tol=15):
    h, w = rgba.shape[:2]
    alpha = rgba[..., 3]
    hsv = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2HSV).astype(np.float32)
    bg_h = bg_hsv[0]
    hue_diff = np.abs(hsv[..., 0] - bg_h)
    hue_diff = np.minimum(hue_diff, 180.0 - hue_diff)
    is_bg_like = (hue_diff < hue_tol) & (alpha < 200) & (alpha > 0)
    col_has_content = (alpha > 128).any(axis=0)
    if not col_has_content.any():
        return rgba
    bottom_y = np.zeros(w, dtype=np.int32)
    for x in range(w):
        if col_has_content[x]:
            bottom_y[x] = np.where(alpha[:, x] > 128)[0].max()
    y_coords, x_coords = np.where(is_bg_like)
    if len(y_coords) > 0:
        below_bottom = y_coords > bottom_y[x_coords] + 3
        remove_idx = (y_coords[below_bottom], x_coords[below_bottom])
        rgba[remove_idx[0], remove_idx[1], 3] = 0
    return rgba


def cutout_frame(rgb, hue_tol=15, hue_feather=20, spill_exp=0.5, erode=2):
    arr = rgb.astype(np.float32)
    bg_rgb = detect_bg(rgb)
    arr_wm = rgb.copy()
    fill_watermark(arr_wm, bg_rgb.astype(np.uint8))
    hsv = cv2.cvtColor(arr_wm, cv2.COLOR_RGB2HSV).astype(np.float32)
    bg_hsv = cv2.cvtColor(bg_rgb.astype(np.uint8).reshape(1, 1, 3), cv2.COLOR_RGB2HSV).reshape(3)
    bg_h = bg_hsv[0]
    hue_diff = np.abs(hsv[..., 0] - bg_h)
    hue_diff = np.minimum(hue_diff, 180.0 - hue_diff)
    alpha = np.clip((hue_diff - hue_tol) / max(hue_feather, 1e-6), 0.0, 1.0)
    val = arr.max(axis=2)
    alpha[val < 60] = 1.0
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    gray = (r + g + b) / 3.0
    out = arr.copy()
    semi = (alpha > 0) & (alpha < 1)
    un = semi & (alpha >= 0.5)
    a_safe = np.maximum(alpha[un], 1e-3)
    out[un, 0] = (r[un] - (1 - a_safe) * bg_rgb[0]) / a_safe
    out[un, 1] = (g[un] - (1 - a_safe) * bg_rgb[1]) / a_safe
    out[un, 2] = (b[un] - (1 - a_safe) * bg_rgb[2]) / a_safe
    low = semi & (alpha < 0.5)
    s_low = 0.9 * (1.0 - alpha[low]) ** 0.7
    out[low, 0] = r[low] + (gray[low] - r[low]) * s_low
    out[low, 1] = g[low] + (gray[low] - g[low]) * s_low
    out[low, 2] = b[low] + (gray[low] - b[low]) * s_low
    spill_band = (hue_tol + hue_feather) * 4.0
    near = (alpha >= 1) & (hue_diff < spill_band)
    t = np.clip(1.0 - hue_diff[near] / spill_band, 0.0, 1.0) ** spill_exp
    out[near, 0] = r[near] + (gray[near] - r[near]) * t
    out[near, 1] = g[near] + (gray[near] - g[near]) * t
    out[near, 2] = b[near] + (gray[near] - b[near]) * t
    alpha8 = morphological_clean((alpha * 255).astype(np.uint8), erode)
    rgba = np.dstack([out, alpha8])
    rgba = np.clip(rgba, 0, 255).astype(np.uint8)
    rgba = remove_bottom_shadow(rgba, bg_hsv, hue_tol=hue_tol + 5)
    return rgba


def extract_frames(video_path, target_fps=12, skip_first=False):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f'  [ERROR] Cannot open {video_path}')
        return []
    src_fps = cap.get(cv2.CAP_PROP_FPS)
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(f'    Source: {src_fps:.1f}fps, {total} frames, target: {target_fps}fps')
    interval = max(1, round(src_fps / target_fps))
    frames = []
    frame_idx = 0
    first_skipped = False
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if skip_first and not first_skipped:
            first_skipped = True
            frame_idx += 1
            continue
        if frame_idx % interval == 0:
            frames.append(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        frame_idx += 1
    cap.release()
    if skip_first:
        print(f'    Extracted: {len(frames)} frames (first frame skipped)')
    else:
        print(f'    Extracted: {len(frames)} frames')
    return frames


def process_character(video_name, character_id, target_fps, idle_frame_count, train_start_sec, skip_first=False):
    video_path = os.path.join(SRC_DIR, video_name)
    if not os.path.exists(video_path):
        print(f'  [SKIP] {video_name} not found')
        return
    print(f'\n  Processing: {video_name} -> {character_id}')
    all_frames = extract_frames(video_path, target_fps, skip_first=skip_first)
    if not all_frames:
        return
    train_start_idx = int(train_start_sec * target_fps)

    idle_out = os.path.join(OUT_DIR, f'{character_id}_idle')
    os.makedirs(idle_out, exist_ok=True)
    idle_count = min(idle_frame_count, len(all_frames))
    for i in range(idle_count):
        small = cv2.resize(all_frames[i], (PROCESS_SIZE, PROCESS_SIZE), interpolation=cv2.INTER_AREA)
        rgba = cutout_frame(small, **KEY_PARAMS)
        Image.fromarray(rgba).save(os.path.join(idle_out, f'{character_id}_idle_{i:04d}.png'))
    print(f'    Idle frames: {idle_count}')

    train_out = os.path.join(OUT_DIR, f'{character_id}_train')
    os.makedirs(train_out, exist_ok=True)
    train_idx = 0
    for i in range(train_start_idx, len(all_frames)):
        small = cv2.resize(all_frames[i], (PROCESS_SIZE, PROCESS_SIZE), interpolation=cv2.INTER_AREA)
        rgba = cutout_frame(small, **KEY_PARAMS)
        Image.fromarray(rgba).save(os.path.join(train_out, f'{character_id}_train_{train_idx:04d}.png'))
        train_idx += 1
    print(f'    Train frames: {train_idx}')


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'Output dir: {OUT_DIR}')
    for video_name, character_id, fps, idle_count, train_start, skip_first in VIDEO_MAP:
        process_character(video_name, character_id, fps, idle_count, train_start, skip_first)
    print('\n=== Result ===')
    for character_id in ['default_male', 'default_female']:
        idle_dir = os.path.join(OUT_DIR, f'{character_id}_idle')
        train_dir = os.path.join(OUT_DIR, f'{character_id}_train')
        ic = len([f for f in os.listdir(idle_dir) if f.endswith('.png')]) if os.path.isdir(idle_dir) else 0
        tc = len([f for f in os.listdir(train_dir) if f.endswith('.png')]) if os.path.isdir(train_dir) else 0
        print(f'  {character_id}: idle={ic}, train={tc}')


if __name__ == '__main__':
    main()
