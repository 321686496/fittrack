#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把莫兰迪章节配图注入 course_content.dart 的每个章节 blocks 首位。

对每个章节 id，在其区块的 `blocks: [` 之后插入一行:
    ContentBlock.image('assets/images/art/ch_<id>.png', '示意图'),

用法: python scripts/inject_chapter_images.py
"""

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILE = os.path.join(ROOT, "fittrack_flutter", "lib", "data", "course_content.dart")

# 与 gen_teaching_morandi.py 一致的章节列表
CHAPTER_IDS = [
    "ch1_intro", "ch2_equipment", "ch3_plan", "ch4_diet", "ch5_recovery",
    "cut_ch1_deficit", "cut_ch2_macros", "cut_ch3_food", "cut_ch4_plateau",
    "shape_ch1_assess", "shape_ch2_split", "shape_ch3_compound_isolation",
    "shape_ch4_tempo", "shape_ch5_microcycle",
    "strength_ch1_principle", "strength_ch2_technique", "strength_ch3_breathing_core",
    "strength_ch4_progression",
    "keep_ch1_principle", "keep_ch2_strength", "keep_ch3_cardio", "keep_ch4_lifestyle",
    "bulk_ch1_assess", "bulk_ch2_periodization", "bulk_ch3_assistance",
    "bulk_ch4_metabolic", "bulk_ch5_deload", "bulk_ch6_advanced_split",
    "hiit_ch1_epoc", "hiit_ch2_exercises", "hiit_ch3_protocols",
    "hiit_ch4_balance", "hiit_ch5_safety",
    "home_ch1_env", "home_ch2_bodyweight", "home_ch3_schedule", "home_ch4_progress",
    "senior_ch1_health", "senior_ch2_strength", "senior_ch3_balance",
    "gym_ch1_freeweight", "gym_ch2_machine_upper", "gym_ch3_machine_leg", "gym_ch4_choose",
    "db_ch1_pick", "db_ch2_upper", "db_ch3_lower", "db_ch4_core_plan",
]


def inject(src: str, ch_id: str):
    marker = "id: '%s'," % ch_id
    start = src.find(marker)
    if start < 0:
        return src, False, "chapter marker not found"
    bs = src.find("blocks: [", start)
    if bs < 0:
        return src, False, "blocks not found after chapter"
    insert_at = bs + len("blocks: [")
    line = "            ContentBlock.image('assets/images/art/%s.png', '示意图')," % ch_id
    new = src[:insert_at] + "\n" + line + src[insert_at:]
    return new, True, "ok"


def main():
    with open(FILE, "r", encoding="utf-8") as f:
        src = f.read()
    ok = fail = 0
    for cid in CHAPTER_IDS:
        src, succ, msg = inject(src, cid)
        if succ:
            ok += 1
            print("[注入] %s" % cid)
        else:
            fail += 1
            print("[失败] %s: %s" % (cid, msg), flush=True)
    with open(FILE, "w", encoding="utf-8") as f:
        f.write(src)
    print("完成: 注入 %d, 失败 %d" % (ok, fail))


if __name__ == "__main__":
    main()