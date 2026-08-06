#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
对手皮肤精灵素材色键抠图脚本

将 _gen/ 目录下带纯洋红 (#FF00FF) 背景的 JPG 素材抠图为透明背景 PNG，
输出到 opponent/ 目录覆盖旧素材。

算法：
  - 计算 magenta_score = (R - G) + (B - G)，洋红区域该值显著为正
  - 硬背景：magenta_score > 150 且 R > 150 且 B > 150 → alpha=0
  - 软过渡：80 < magenta_score <= 150 且 R/B > 120 → alpha 线性渐变
  - 其余区域 → alpha=255
  - 边缘半透明像素做绿色去污染（reduce green spill）
  - 最终缩放到 512×512（与现有素材规格一致）

用法：
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


def cutout_magenta(arr: np.ndarray) -> np.ndarray:
    """对 RGB numpy 数组做洋红色键抠图，返回 RGBA 数组。"""
    r = arr[:, :, 0].astype(np.int32)
    g = arr[:, :, 1].astype(np.int32)
    b = arr[:, :, 2].astype(np.int32)

    magenta_score = (r - g) + (b - g)

    # 硬背景：完全透明
    is_bg_hard = (magenta_score > 150) & (r > 150) & (b > 150)
    # 软过渡：边缘抗锯齿
    is_bg_soft = (magenta_score > 80) & (magenta_score <= 150) & (r > 120) & (b > 120) & (~is_bg_hard)

    alpha = np.full(r.shape, 255, dtype=np.uint8)
    alpha[is_bg_hard] = 0

    # 软过渡区：magenta_score 从 80→150 时 alpha 从 255→0
    soft_score = magenta_score[is_bg_soft]
    soft_alpha = ((150 - soft_score) / 70.0 * 255.0).clip(0, 255).astype(np.uint8)
    alpha[is_bg_soft] = soft_alpha

    # 绿色去污染：边缘半透明像素的 G 通道减半，去除洋红背景的绿色溢出
    out = arr.copy()
    edge_mask = is_bg_soft
    out[edge_mask, 1] = (out[edge_mask, 1].astype(np.int32) * 5 // 10).astype(np.uint8)

    rgba = np.dstack([out, alpha])
    return rgba


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
    rgba = cutout_magenta(arr)

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
    print(f'\n完成：{ok}/{len(names)} 张成功')
    if do_backup := True:
        print(f'旧素材备份于: {BACKUP_DIR}')


if __name__ == '__main__':
    main()
