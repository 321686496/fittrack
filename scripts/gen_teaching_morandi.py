#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LiftTrack 教学模块插图批量生成脚本（走 gpt_image2 的 HAPI gpt-image-2 通道）

统一风格：莫兰迪扁平插画（与 App 整体配色一致），无文字/水印。

用法:
    python scripts/gen_teaching_morandi.py            # 全部
    python scripts/gen_teaching_morandi.py --group courses   # 仅课程封面
    python scripts/gen_teaching_morandi.py --group chapters  # 仅章节配图
    python scripts/gen_teaching_morandi.py --force          # 忽略已存在，强制重跑

可断点续跑：目标文件已存在且为有效 PNG 时自动跳过。
API Key：环境变量 HAPI_API_KEY，默认为脚本内预设。
"""

import os
import sys
import time
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(ROOT, "fittrack_flutter", "assets", "images", "art")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gpt_image2 as im2

HAPI_KEY = os.environ.get("HAPI_API_KEY", "sk-8d0149c3e8dbf782ed1356b0be5e25579121eef8326c29db64884786bdf959df")
HAPI_BASE = "https://image.hapiopen.cc"
MODEL = "gpt-image-2"
SIZE = "1024x1024"

PROGRESS = os.path.join(ROOT, "scripts", ".morandi_progress.json")

# 统一风格基底：莫兰迪扁平插画 + 无文字
STYLE = (
    "flat vector fitness illustration, modern instructional guide style, "
    "soft Morandi muted pastel palette (dusty rose, sage green, dusty blue, cream, lilac), "
    "clean geometric shapes, gentle soft gradient background, subtle cast shadow, "
    "clear silhouette, premium wellness aesthetic, 2D flat illustration, "
    "high quality, no text, no words, no letters, no watermark, no logo"
)

# safety 兜底：前置强调无风险 + 通用主体
GENERIC_PREPEND = (
    "clean wholesome workout equipment scene, no people, "
)
GENERIC_SUBJECT = (
    "a neatly arranged set of fitness equipment (dumbbell, kettlebell, yoga mat, skipping rope) "
    "on a soft gradient surface, "
)

# ── 课程封面（11 门）─────────────────────────────────────────────
COURSE_COVERS = {
    "course_beginner_bulk": "新手零基础增肌入门课程封面, 一副友好的哑铃与向上的成长箭头, 柔和暖橙莫兰迪色调",
    "course_cut_diet": "减脂饮食全攻略课程封面, 一碗健康的轻食沙拉与刻度卷尺, 柔和不饱和绿粉色调",
    "course_intermediate_shape": "中级塑形进阶课程封面, 优雅的哑铃与流动丝带, 柔和雾紫与粉色调",
    "course_strength_basic": "力量训练基础课程封面, 一根杠铃与对称杠铃片, 柔和灰蓝与雾蓝色调",
    "course_keep_health": "健康保持指南课程封面, 一颗发光的心脏与晨光, 柔和灰绿与薄荷色调",
    "course_advanced_bulk": "高级增肌突破课程封面, 沉重的杠铃片堆叠与上扬弧线, 柔和灰橙与焦糖色调",
    "course_hiit_cut": "HIIT高效减脂课程封面, 一根战绳涡卷与跳跃的跳绳, 柔和雾蓝与灰绿色调",
    "course_home_beginner": "居家零器械新手入门课程封面, 铺开的瑜伽垫与瓶装水, 柔和暖米与灰粉色调",
    "course_senior_health": "中老年科学健身课程封面, 温和的徒手拉伸姿态与无声座垫, 柔和大地理性与米黄色调",
    "course_gym_equipment": "健身房器械使用指南课程封面, 简洁的坐姿推胸机与平台, 柔和灰蓝与浅紫色调",
    "course_dumbbell_fullbody": "一对哑铃练全身课程封面, 一对摆放整齐的哑铃, 柔和不饱和玫瑰与暖灰色调",
}

# ── 章节配图（48 章）────────────────────────────────────────────
CHAPTER_ARTS = {
    "ch1_intro": "整洁的健身房大厅, 一排排整齐的固定器械与落地镜, 柔和晨光",
    "ch2_equipment": "一组排序的杠铃、哑铃与固定器械剪影, 清爽构图",
    "ch3_plan": "一张展开的健身训练计划表与彩色分段色块, 桌面构图",
    "ch4_diet": "丰盛的增肌营养餐盘, 鸡胸肉、米饭与蔬菜, 俯视构图",
    "ch5_recovery": "舒适的床铺一角与睡前放松姿态, 温馨治愈氛围",
    "cut_ch1_deficit": "一台简洁的天平秤与刻度热量圆环, 减脂概念",
    "cut_ch2_macros": "三组代表蛋白质碳水脂肪的圆形食材拼盘",
    "cut_ch3_food": "几种健康的低卡替代食材并排摆放, 干净清新",
    "cut_ch4_plateau": "上扬又回落的折线图表与一杯水, 平台期突破概念",
    "shape_ch1_assess": "一面测量镜与腰带卷尺剪影, 塑形评估概念",
    "shape_ch2_split": "上下半身分割的训练日历色块划分",
    "shape_ch3_compound_isolation": "复合动作与孤立动作的对比示意图, 简洁图标化",
    "shape_ch4_tempo": "带节奏数字点的杠铃推举动作分解线条图",
    "shape_ch5_microcycle": "循环往复的微周期训练环形图表",
    "strength_ch1_principle": "力量攀升的阶梯式累积图表与杠铃剪影",
    "strength_ch2_technique": "标准深蹲动作的姿态示范轮廓图",
    "strength_ch3_breathing_core": "腹腔呼吸与核心收紧的示意人物剪影",
    "strength_ch4_progression": "一台记录力量增长的笔记本与递增箭头",
    "keep_ch1_principle": "一位面向朝阳做伸展的健康人物剪影, 草地场景",
    "keep_ch2_strength": "温和的徒手力量训练姿态, 如水瓶前平举, 居家场景",
    "keep_ch3_cardio": "一条湖畔慢跑的路线与轻度有氧剪影",
    "keep_ch4_lifestyle": "营养均衡的餐食与早睡晚起的作息时间轴",
    "bulk_ch1_assess": "体检与体成分测量仪剪影, 数据化诊断概念",
    "bulk_ch2_periodization": "分阶段递进的训练周期化波浪图表",
    "bulk_ch3_assistance": "协同辅助的孤立动作, 如弯举与腿弯举示意",
    "bulk_ch4_metabolic": "泵感充血的肌肉细胞示意与增压光环",
    "bulk_ch5_deload": "一次轻松的减量恢复训练周, 舒展放松氛围",
    "bulk_ch6_advanced_split": "六天分化训练的彩色周计划网格",
    "hiit_ch1_epoc": "训练后仍持续燃烧的火苗与呼吸剪影, EPOC概念",
    "hiit_ch2_exercises": "战绳、跳绳与波比跳的动作分解剪影组合",
    "hiit_ch3_protocols": "间歇计时器与冲刺/休息色块, 如30秒冲刺",
    "hiit_ch4_balance": "HIIT与力量训练的平衡天平示意",
    "hiit_ch5_safety": "心率表与腕表, 循序渐进的安全提示氛围",
    "home_ch1_env": "整洁的居家一角的瑜伽垫与水杯, 家庭热身场景",
    "home_ch2_bodyweight": "壁俯卧撑、深蹲与平板支撑的徒手动作剪影组合",
    "home_ch3_schedule": "带提醒闹钟的每周三练日历, 习惯养成概念",
    "home_ch4_progress": "记录进步的笔记本与递增曲线, 掌上打卡框",
    "senior_ch1_health": "一位长者温和地做热身活动与血压计剪影, 安心氛围",
    "senior_ch2_strength": "座椅上安全进行的力量训练姿态示范, 温和帮扶氛围",
    "senior_ch3_balance": "扶墙单脚站立与稳固靠墙的平衡站姿示范",
    "gym_ch1_freeweight": "自由重量区的杠铃架与哑铃架排布, 开阔清晰",
    "gym_ch2_machine_upper": "坐姿推胸机与高位下拉机的剪影对比",
    "gym_ch3_machine_leg": "腿举机与坐姿腿弯举机的剪影对比",
    "gym_ch4_choose": "根据目标选择器械的路线引导示意图",
    "db_ch1_pick": "两副不同重量的哑铃并排摆放, 选择概念",
    "db_ch2_upper": "哑铃卧推与哑铃划船的上肢动作剪影组合",
    "db_ch3_lower": "哑铃深蹲与哑铃硬拉的下肢动作剪影组合",
    "db_ch4_core_plan": "哑铃俄罗斯转体与折叠划船的核心动作组合",
}


def _target(name: str) -> str:
    return os.path.join(ART_DIR, name + ".png")


_IMAGE_MAGIC = {
    b"\x89PNG\r\n\x1a\n": "png",
    b"\xff\xd8\xff": "jpeg",   # JPEG (JFIF/EXIF)
    b"RIFF": "webp",           # 需再判断 WEBP
}
# WebP 额外校验: 前 12 字节含 "WEBP"
WEBP_CHECK = b"WEBP"


def is_valid_image(path: str, min_bytes: int = 8000) -> bool:
    """HAPI gpt-image-2 返回 PNG/JPEG/WebP，这里兼容三者。"""
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
    # 正常尝试 3 次；若都失败（尤其 safety 451），用通用莫兰迪兜底提示词再试 1 次
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
    ap.add_argument("--group", choices=["courses", "chapters"], default=None)
    ap.add_argument("--force", action="store_true", help="忽略已存在，强制重新生成")
    ap.add_argument("--only", default=None, help="只生成指定资源名(逗号分隔)")
    args = ap.parse_args()

    client = im2.make_client("hapi", HAPI_KEY, HAPI_BASE)
    prog = _load_progress()

    items = []
    if args.group in (None, "courses"):
        for name, subj in COURSE_COVERS.items():
            items.append((name, subj + ", " + STYLE))
    if args.group in (None, "chapters"):
        for name, subj in CHAPTER_ARTS.items():
            items.append((name, subj + ", " + STYLE))
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