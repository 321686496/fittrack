#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
对手皮肤精灵素材纯色背景键控抠图脚本

将 _gen/ 目录下带纯色背景（红/玫红/洋红系）的 JPG 素材抠图为透明背景 PNG，
输出到 opponent/ 目录覆盖旧素材。

算法（与 scripts/extract_video_frames.py 同源）:
  - 从四角区域取中位数颜色作为背景色（每张图独立检测）
  - 按到背景色的欧氏距离生成 alpha：容差内全透明，容差-羽化带线性过渡
  - 半透明边缘反预乘去污，低覆盖率像素完全去饱和
  - 不透明但贴近背景的像素按距离去饱和（清除红色描边）
  - alpha 做轻微腐蚀，移除最外圈背景残留
  - 最终缩放到 512x512（与现有素材规格一致）

用法:
  python cutout_opponent_sprites.py            # 处理全部 12 张
  python cutout_opponent_sprites.py face_beginner  # 处理单张（按名称前缀）
"""
import os
import sys
import shutil
import numpy as np
from PIL import Image

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN_DIR = os.path.join(BASE_DIR, 'fittrack_flutter', 'assets', 'opponent', '_gen')
OUT_DIR = os.path.join(BASE_DIR, 'fittrack_flutter', 'assets', 'opponent')
BACKUP_DIR = os.path.join(BASE_DIR, 'fittrack_flutter', 'assets', 'opponent', '_backup_old')

TARGET_SIZE = 512

# 12 个素材名称（无扩展名）
ASSET_NAMES = [
    'face_beginner', 'face_iron', 'face_ninja', 'face_ambassador',
    'outfit_beginner', 'outfit_iron', 'outfit_ninja', 'outfit_ambassador',
    'prop_beginner', 'prop_iron', 'prop_ninja', 'prop_ambassador',
]

# 键控参数（按皮肤，与视频帧参数同源；精灵图为 1920x1920 大图，容差更高）
SKIN_KEY_PARAMS = {
    'beginner':   dict(tolerance=48, feather=24, spill_exp=0.7, spill_extend=2.6, erode=1),
    'iron':       dict(tolerance=48, feather=24, spill_exp=0.7, spill_extend=2.6, erode=1),
    'ninja':      dict(tolerance=48, feather=24, spill_exp=0.6, spill_extend=3.0, erode=2),
    'ambassador': dict(tolerance=48, feather=24, spill_exp=0.7, spill_extend=2.6, erode=1),
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


def cutout_solid_bg(rgb, tolerance=48, feather=24, spill_exp=0.7,
                    spill_extend=2.6, erode=1, unspill_min=0.2):
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


def process_one(name: str, do_backup: bool = True) -> bool:
    # 优先使用 v2 版本（新生成的主体占画布 70%+ 素材）
    v2_path = os.path.join(GEN_DIR, name + '_v2.jpg')
    if os.path.exists(v2_path):
        in_path = v2_path
    else:
        in_path = os.path.join(GEN_DIR, name + '.jpg')
    out_path = os.path.join(OUT_DIR, name + '.png')

    if not os.path.exists(in_path):
        print(f'[SKIP] 输入不存在: {in_path}')
        return False

    # 备份旧 PNG
    if do_backup and os.path.exists(out_path):
        os.makedirs(BACKUP_DIR, exist_ok=True)
        backup_path = os.path.join(BACKUP_DIR, name + '.png')
        if not os.path.exists(backup_path):
            shutil.copy2(out_path, backup_path)

    img = Image.open(in_path).convert('RGB')
    arr = np.array(img)
    skin_key = name.split('_')[1] if len(name.split('_')) > 1 else 'beginner'
    params = SKIN_KEY_PARAMS.get(skin_key, SKIN_KEY_PARAMS['beginner'])
    rgba = cutout_solid_bg(arr, **params)

    result = Image.fromarray(rgba, 'RGBA')
    # 缩放到目标尺寸（LANCZOS 高质量重采样）
    result = result.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    result.save(out_path, 'PNG')

    # 统计透明像素占比（验证抠图有效性）
    alpha = np.array(result)[:, :, 3]
    transparent_ratio = (alpha == 0).sum() / alpha.size
    print(f'[OK] {name}: {img.size} -> {TARGET_SIZE}x{TARGET_SIZE}, 透明占比={transparent_ratio:.1%}')
    return True


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else None
    names = [n for n in ASSET_NAMES if (target is None or n == target or n.startswith(target))]
    if not names:
        print(f'未找到匹配的素材: {target}')
        print(f'可选: {ASSET_NAMES}')
        sys.exit(1)

    print(f'开始处理 {len(names)} 张素材...')
    ok = 0
    for name in names:
        if process_one(name):
            ok += 1
    print(f'\n完成: {ok}/{len(names)} 张成功')
    print(f'旧素材备份于: {BACKUP_DIR}')


if __name__ == '__main__':
    main()
