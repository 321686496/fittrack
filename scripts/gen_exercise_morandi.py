#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LiftTrack 动作库预览图（21 个动作 preview 封面）批量生成脚本
走 gpt_image2 的 HAPI gpt-image-2 通道，统一莫兰迪扁平插画风，无文字。

用法:
    python scripts/gen_exercise_morandi.py            # 全部
    python scripts/gen_exercise_morandi.py --force    # 忽略已存在强制重跑
可断点续跑：目标文件已存在且为有效 PNG 时自动跳过。
"""

import os
import sys
import time
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "exercises")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gpt_image2 as im2

HAPI_KEY = os.environ.get("HAPI_API_KEY", "sk-8d0149c3e8dbf782ed1356b0be5e25579121eef8326c29db64884786bdf959df")
HAPI_BASE = "https://image.hapiopen.cc"
MODEL = "gpt-image-2"
SIZE = "1024x1024"

PROGRESS = os.path.join(ROOT, "scripts", ".exercise_morandi_progress.json")

STYLE = (
    "flat vector fitness exercise illustration, single clear figure performing the movement, "
    "soft Morandi muted pastel palette (dusty rose, sage green, dusty blue, cream, lilac), "
    "clean geometric shapes, gentle soft gradient gym background, subtle cast shadow, "
    "clear silhouette, premium wellness aesthetic, 2D flat illustration, "
    "high quality, no text, no words, no letters, no watermark, no logo"
)

# safety 兜底
GENERIC_PREPEND = ("clean wholesome fitness scene, calm neutral gym, ")
GENERIC_SUBJECT = (
    "an exercise mat and a set of gym equipment arranged neatly, "
)

# 21 个动作 preview 封面
EXERCISES = {
    "e1_barbell_bench_press_preview": "杠铃卧推：仰卧卧推凳上，双手握杠向上推起，练胸大肌",
    "e2_dumbbell_fly_preview": "哑铃飞鸟：仰卧持哑铃，双臂向两侧张开再合拢，练胸大肌中缝",
    "e3_incline_bench_press_preview": "上斜卧推：上斜凳上杠铃推举，练胸大肌上部",
    "e4_cable_crossover_preview": "绳索夹胸：站姿双手拉缆绳向胸前交叉合拢，孤立胸大肌",
    "e5_pull-up_preview": "引体向上：双手抓单杠向上拉起，练背阔肌与肱二头肌",
    "e6_barbell_row_preview": "杠铃划船：俯身屈髋，双手握杠横向拉至腹部，练背部",
    "e7_lat_pulldown_preview": "高位下拉：坐姿双手拉横杆至胸前，练背阔肌",
    "e8_seated_cable_row_preview": "坐姿划船：坐姿双手拉柄向后，练中背部与菱形肌",
    "e9_barbell_squat_preview": "杠铃深蹲：杠铃置于斜方肌，下蹲至大腿平行后站起，练臀腿",
    "e10_leg_press_preview": "腿举机：坐姿双腿蹬举负重踏板，练股四头肌与臀大肌",
    "e11_dumbbell_shoulder_press_preview": "哑铃肩上推举：坐或站立，双手持哑铃向上推过头，练三角肌",
    "e12_lateral_raise_preview": "侧平举：站姿双手持哑铃向两侧平举至肩高，练三角肌中束",
    "e13_dumbbell_curl_preview": "哑铃弯举：站姿手臂自然下垂，屈肘举起哑铃，练肱二头肌",
    "e14_hammer_curl_preview": "锤式弯举：掌心相对持哑铃屈肘举起，练肱肌与前臂",
    "e15_plank_preview": "平板支撑：俯卧以肘与前脚掌支撑，身体呈直线，练核心",
    "e16_crunch_preview": "卷腹：仰卧屈膝，卷起上身收缩腹肌，练腹部",
    "e17_jogging_preview": "慢跑：户外清晨慢跑姿态，双臂自然摆动，练有氧耐力",
    "e18_interval_run_preview": "间歇跑：户外冲刺与放松交替奔跑姿态，练心肺",
    "e19_long_distance_run_preview": "长距离跑：连续稳定跑步姿态，公园绿道，练持久耐力",
    "e20_sprint_preview": "冲刺跑：爆发力快速奔跑姿态，身体前倾，练爆发力",
    "e21_incline_treadmill_run_preview": "坡度跑：跑步机上坡道慢跑姿态，练下肢与心肺",
}


def _target(name: str) -> str:
    return os.path.join(ART_DIR, name + ".png")


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


def generate_one(client, name: str, prompt: str, force: bool) -> bool:
    target = _target(name)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    attempts = [prompt, prompt, prompt, GENERIC_PREPEND + prompt,
                GENERIC_PREPEND + GENERIC_SUBJECT]
    for n, cur_prompt in enumerate(attempts, 1):
        try:
            print(f"[生成] {name} (round {n})", flush=True)
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
                path, _name = im2.download_to_local(item["url"], tmp_dir, "")
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
                print(f"[完成] {name}", flush=True)
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
    ap.add_argument("--force", action="store_true", help="忽略已存在，强制重新生成")
    ap.add_argument("--only", default=None, help="只生成指定资源名(逗号分隔)")
    args = ap.parse_args()

    client = im2.make_client("hapi", HAPI_KEY, HAPI_BASE)
    prog = _load_progress()

    items = [(name, subj + ", " + STYLE) for name, subj in EXERCISES.items()]
    if args.only:
        only = set(x.strip() for x in args.only.split(","))
        items = [it for it in items if it[0] in only]

    ok = 0
    for name, prompt in items:
        if prog.get(name, {}).get("ok") and not args.force and is_valid_image(_target(name)):
            print(f"  .. 已完成 {name}", flush=True)
            ok += 1
            continue
        succ = generate_one(client, name, prompt, args.force)
        prog[name] = {"ok": succ, "t": time.time()}
        _save_progress(prog)
        if succ:
            ok += 1
    print(f"全部完成: 成功 {ok}/{len(items)}")


if __name__ == "__main__":
    main()