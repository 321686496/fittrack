#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import cv2
import numpy as np
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(BASE_DIR, 'skinanimalandimage')
OUT_DIR = os.path.join(BASE_DIR, 'fittrack_flutter', 'assets', 'opponent')
TARGET_SIZE = 512

ASSET_MAP = [
    ('man.png', 'default_male'),
    ('woman.png', 'default_female'),
]
KEY_PARAMS = dict(hue_tol=8, hue_feather=15, spill_exp=0.5, erode=2)

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

def cutout_solid_bg(rgb, hue_tol=15, hue_feather=20, spill_exp=0.5, erode=2):
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
    return np.clip(rgba, 0, 255).astype(np.uint8)

def process_one(src_name, out_name):
    in_path = os.path.join(SRC_DIR, src_name)
    out_path = os.path.join(OUT_DIR, out_name + '.png')
    if not os.path.exists(in_path):
        print(f'[SKIP] {in_path}')
        return False
    img = Image.open(in_path).convert('RGB')
    arr = np.array(img)
    print(f'  Processing {src_name} ({img.size})...')
    rgba = cutout_solid_bg(arr, **KEY_PARAMS)
    result = Image.fromarray(rgba, 'RGBA')
    result = result.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    result.save(out_path, 'PNG')
    alpha = np.array(result)[:, :, 3]
    tr = (alpha == 0).sum() / alpha.size
    print(f'[OK] {out_name}: {img.size} -> {TARGET_SIZE}x{TARGET_SIZE}, transparent={tr:.1%}')
    return True

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f'Processing {len(ASSET_MAP)} sprites (HSV hue-based v8)...')
    ok = sum(1 for s, o in ASSET_MAP if process_one(s, o))
    print(f'Done: {ok}/{len(ASSET_MAP)}')

if __name__ == '__main__':
    main()
