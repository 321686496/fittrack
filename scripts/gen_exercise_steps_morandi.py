#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
动作库 step 步骤图（e1~e21 的 step1~5）批量重生成脚本
走 gpt_image2 的 HAPI gpt-image-2 通道，解析
fittrack_flutter/lib/data/mock_data.dart 的 exerciseSteps 定义，
为每个步骤的 title+desc 构造莫兰迪扁平插画提示词。

用法:
    python scripts/gen_exercise_steps_morandi.py            # 全部
    python scripts/gen_exercise_steps_morandi.py --only e1  # 只生成某个动作的5张step
    python scripts/gen_exercise_steps_morandi.py --force
可断点续跑：目标文件已存在且为有效 PNG 时自动跳过。
"""

import os
import sys
import re
import time
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX_DIR = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "exercises")
MOCK_FILE = os.path.join(ROOT, "fittrack_flutter", "lib", "data", "mock_data.dart")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gpt_image2 as im2

# 改用 MaaS 平台 (gpt/hapi 余额耗尽)，模型 qwen-image-3.0-pro
GEN_PLATFORM = os.environ.get("GEN_PLATFORM", "mass")
MASS_KEY = os.environ.get("MASS_API_KEY", "sk-ra-c57TT8YRQu5khVviGeqcfYkNvtQAJAwU")
MASS_BASE = "https://mass.hzxmfg.com/v1"
MODEL = os.environ.get("GEN_MODEL", "qwen-image-3.0-pro")
SIZE = "1024x1024"

PROGRESS = os.path.join(ROOT, "scripts", ".exercise_steps_morandi_progress.json")

STYLE = (
    "flat vector fitness exercise step illustration, one clear figure demonstrating the exact "
    "movement position, soft Morandi muted pastel palette (dusty rose, sage green, dusty blue, "
    "cream, lilac), clean geometric shapes, gentle soft gradient neutral gym background, "
    "subtle cast shadow, clear silhouette, premium wellness aesthetic, 2D flat illustration, "
    "high quality, no text, no words, no letters, no watermark, no logo"
)

GENERIC_PREPEND = ("clean wholesome fitness training scene, calm neutral gym, ")
GENERIC_SUBJECT = (
    "a person doing a safe seated core exercise on an exercise mat, "
)


def parse_exercise_steps():
    """解析 mock_data.dart 的 exerciseSteps，返回 {e_id: [(image_basename, prompt_subject)]}"""
    if not os.path.isfile(MOCK_FILE):
        print(f"!! 找不到 {MOCK_FILE}", flush=True)
        return {}
    with open(MOCK_FILE, "r", encoding="utf-8") as f:
        txt = f.read()

    # 截取 exerciseSteps 数据块
    m = re.search(r"exerciseSteps\s*=\s*\{(.*?)\n\s*\};", txt, re.S)
    if not m:
        print("!! 无法定位 exerciseSteps 数据块", flush=True)
        return {}
    block = m.group(1)
    result = {}
    # 每个 step 是独立一行；动作块为 'eXX': [ 起始、到下一个动作键或块尾结束。
    # 先按行拆，记录每个动作键出现的行号，用于切分动作块。
    lines = block.split("\n")
    action_idx = []  # (eid, line_index)
    for i, ln in enumerate(lines):
        am = re.match(r"\s*'([a-z]+[0-9]+)':\s*\[", ln)
        if am:
            action_idx.append((am.group(1), i))
    for n, (eid, si) in enumerate(action_idx):
        ei = action_idx[n + 1][1] if n + 1 < len(action_idx) else len(lines)
        body_lines = lines[si:ei]
        steps = []
        for ln in body_lines:
            sm = re.search(
                r"'title':\s*'((?:[^'\\]|\\.)*)'\s*,\s*'desc':\s*'((?:[^'\\]|\\.)*)'\s*,\s*'image':\s*'assets/images/exercises/([^']+_step\d+\.png)'",
                ln)
            if sm:
                title, desc, img = sm.group(1), sm.group(2), sm.group(3)
                steps.append((img, f"{title}：{desc}"))
        if steps:
            result[eid] = steps
    return result


def _target(basename: str) -> str:
    return os.path.join(EX_DIR, basename)


def is_valid_image(path: str, min_bytes: int = 8000) -> bool:
    try:
        if not os.path.isfile(path) or os.path.getsize(path) < min_bytes:
            return False
        with open(path, "rb") as f:
            head = f.read(12)
        if head.startswith(b"\x89PNG\r\n\x1a\n"):
            return True
        if head[:3] == b"\xff\xd8\xff":
            return True
        if head[:4] == b"RIFF" and b"WEBP" in head[:12]:
            return True
        return False
    except Exception:
        return False


def _load_progress() -> dict:
    if os.path.isfile(PROGRESS):
        try:
            with open(PROGRESS, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def _save_progress(prog: dict):
    os.makedirs(os.path.dirname(PROGRESS), exist_ok=True)
    with open(PROGRESS, "w", encoding="utf-8") as f:
        json.dump(prog, f, ensure_ascii=False)


def generate_one(client, basename: str, prompt: str) -> bool:
    target = _target(basename)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    attempts = [prompt, prompt, GENERIC_PREPEND + prompt, GENERIC_PREPEND + GENERIC_SUBJECT]
    for n, cur_prompt in enumerate(attempts, 1):
        try:
            print(f"[生成] {basename} (round {n})", flush=True)
            status, resp = client.generate(MODEL, cur_prompt, size=SIZE, n=1, timeout=300)
            if status != 200:
                print(f"  [失败] HTTP {status}: {resp}", flush=True)
                time.sleep(3)
                continue
            data = resp.get("data") or []
            if not data:
                print("  [失败] 无 data", flush=True)
                time.sleep(2)
                continue
            item = data[0]
            if item.get("b64_json"):
                import base64
                tmp = target + ".tmp"
                with open(tmp, "wb") as f:
                    f.write(base64.b64decode(item["b64_json"]))
                os.replace(tmp, target)
            elif item.get("url"):
                tmp_dir = os.path.join(os.path.dirname(target), "._tmp_dl")
                path, _n = im2.download_to_local(item["url"], tmp_dir, "")
                os.replace(path, target)
                try:
                    os.rmdir(tmp_dir)
                except Exception:
                    pass
            else:
                print("  [失败] 结果无 url/b64", flush=True)
                time.sleep(2)
                continue
            if is_valid_image(target, min_bytes=8000):
                print(f"[完成] {basename}", flush=True)
                return True
            print(f"  [失败] 文件校验未通过 {os.path.getsize(target)}B", flush=True)
            time.sleep(2)
        except Exception as e:
            print(f"  [异常] {e}", flush=True)
            time.sleep(3)
    return False


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", default=None, help="只生成指定动作id(逗号分隔)，如 e1,e2")
    args = ap.parse_args()

    steps = parse_exercise_steps()
    if not steps:
        print("!! 解析失败，未获得任何步骤定义", flush=True)
        return
    print(f"解析到 {len(steps)} 个动作的步骤图定义", flush=True)

    items = []
    for eid in sorted(steps.keys()):
        if args.only:
            only = set(x.strip() for x in args.only.split(","))
            if eid not in only:
                continue
        for basename, subject in steps[eid]:
            items.append((basename, subject + ", " + STYLE))

    prog = _load_progress()
    client = im2.make_client(GEN_PLATFORM, MASS_KEY, MASS_BASE)
    ok = 0
    for basename, prompt in items:
        if prog.get(basename, {}).get("ok") and not args.force and is_valid_image(_target(basename)):
            print(f"  .. 已完成 {basename}", flush=True)
            ok += 1
            continue
        succ = generate_one(client, basename, prompt)
        prog[basename] = {"ok": succ, "t": time.time()}
        _save_progress(prog)
        if succ:
            ok += 1
    print(f"全部完成: 成功 {ok}/{len(items)}")


if __name__ == "__main__":
    main()