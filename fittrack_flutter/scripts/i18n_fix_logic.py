#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
i18n_fix_logic.py
=================

把「逻辑 / 匹配场景」下被误包的 trn('...') 还原成原始中文串。

背景
----
批量 codemod 给所有中文串都套了一层翻译调用，但下面这些位置的字符串一旦被
翻译，就会和持久化下来的中文数据（SharedPreferences / DB / 用户输入）对不上，
导致分类、匹配、判断全部失效：

    if (gender == trn('女'))            // 性别判断
    if (n.contains(trn('卧推')))        // 动作名关键词匹配
    final legKeywords = [trn('深蹲'), …] // 关键词表
    const x = {trn('次卡'): 1}           // map key
    case trn('高级'):                    // switch 分支

这些位置必须保留原始中文。而真正用于展示的串（通知文案、分享文案等）保持
trn() 不变。

用法
----
    python scripts/i18n_fix_logic.py            # 处理 lib/ 与 test/
    python scripts/i18n_fix_logic.py --dry      # 只报告不写盘
    python scripts/i18n_fix_logic.py lib/services/xxx.dart
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------- 词法：代码掩码


def code_mask(src: str) -> str:
    """把注释和字符串字面量替换成等长空格，保留换行，便于做上下文判断。"""
    out = list(src)
    i, n = 0, len(src)

    def blank(a: int, b: int) -> None:
        for k in range(a, min(b, n)):
            if out[k] not in "\r\n":
                out[k] = " "

    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            blank(i, n if j < 0 else j)
            i = n if j < 0 else j
        elif c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            blank(i, j)
            i = j
        elif c in "'\"":
            quote = c
            triple = src[i : i + 3] in ("'''", '"""')
            delim = quote * 3 if triple else quote
            j = i + len(delim)
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if delim == quote and src[j] == "\n":
                    break
                if src.startswith(delim, j):
                    j += len(delim)
                    break
                j += 1
            blank(i, j)
            i = j
        else:
            i += 1
    return "".join(out)


# ---------------------------------------------------------------- 工具


def match_paren(src: str, open_idx: int) -> int:
    """给定 '(' 的下标，返回配对 ')' 的下标（跳过字符串与注释）。"""
    depth = 0
    i, n = open_idx, len(src)
    while i < n:
        c = src[i]
        if c in "'\"":
            quote = c
            triple = src[i : i + 3] in ("'''", '"""')
            delim = quote * 3 if triple else quote
            j = i + len(delim)
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if delim == quote and src[j] == "\n":
                    break
                if src.startswith(delim, j):
                    j += len(delim)
                    break
                j += 1
            i = j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


CALL_RE = re.compile(r"\btrn\s*\(")

# 关键词表一类的变量名
KEYWORD_NAME_RE = re.compile(
    r"(?i)(keyword|blacklist|whitelist|stopword|pattern|exclude|synonym|alias)"
)

ASSIGN_LIST_RE = re.compile(r"([A-Za-z_]\w*)\s*=\s*(?:<[^<>]*>)?\s*\[")


def find_keyword_ranges(masked: str) -> list[tuple[int, int]]:
    """找出 `xxKeywords = [ ... ]` 这类集合字面量的区间。"""
    ranges = []
    for m in ASSIGN_LIST_RE.finditer(masked):
        name = m.group(1)
        if not KEYWORD_NAME_RE.search(name):
            continue
        open_idx = m.end() - 1
        close_idx = match_paren(masked, open_idx)
        if close_idx < 0:
            continue
        ranges.append((open_idx, close_idx + 1))
    return ranges


# ---------------------------------------------------------------- 单文件处理


def process(path: Path, dry: bool = False) -> int:
    original = path.read_text(encoding="utf-8", newline="")
    src = original
    masked = code_mask(src)
    kw_ranges = find_keyword_ranges(masked)

    edits: list[tuple[int, int]] = []  # (start, end) 待删除的 `trn(` … 只留参数
    count = 0

    for m in CALL_RE.finditer(src):
        open_idx = m.end() - 1
        close_idx = match_paren(src, open_idx)
        if close_idx < 0:
            continue
        # 参数区间
        arg_start, arg_end = open_idx + 1, close_idx
        # 整个调用区间
        call_start, call_end = m.start(), close_idx + 1

        prefix = masked[max(0, call_start - 80) : call_start].rstrip()
        suffix = masked[call_end : call_end + 4].lstrip()

        hit = False
        reason = ""

        # 1) 比较运算
        if re.search(r"(==|!=|>=|<=)$", prefix) or re.search(r"(?<![<>=!])[<>]$", prefix):
            hit, reason = True, "比较运算"
        # 2) 字符串匹配方法
        elif re.search(
            r"\.(contains|startsWith|endsWith|indexOf|lastIndexOf|compareTo|split|replaceAll|replaceFirst)\($",
            prefix,
        ):
            hit, reason = True, "字符串匹配"
        # 3) switch case
        elif re.search(r"\bcase$", prefix):
            hit, reason = True, "case 分支"
        # 4) map key：`{trn('x'): v}` 或 `, trn('x'): v`
        elif re.search(r"[{,]$", prefix) and suffix.startswith(":"):
            hit, reason = True, "map key"
        # 5) 关键词集合字面量
        else:
            for a, b in kw_ranges:
                if a <= call_start < b:
                    hit, reason = True, "关键词集合"
                    break

        if not hit:
            continue

        # 只替换 `trn(` 与末尾 `)`，中间参数原样保留
        edits.append((call_start, arg_start, "del"))
        edits.append((arg_end, call_end, "del"))
        count += 1
        if dry:
            line = src.count("\n", 0, call_start) + 1
            print(f"  {path.name}:{line}  [{reason}]  {src[arg_start:arg_end][:40]}")

    if dry or not edits:
        return count

    # 从后往前删，避免下标失效
    out = list(src)
    for a, b, _ in sorted(edits, key=lambda x: x[0], reverse=True):
        del out[a:b]
    new_src = "".join(out)
    if new_src != original:
        path.write_text(new_src, encoding="utf-8", newline="")
    return count


def main() -> int:
    args = [a for a in sys.argv[1:]]
    dry = "--dry" in args
    args = [a for a in args if not a.startswith("--")]

    files: list[Path] = []
    for a in args:
        p = (ROOT / a) if not Path(a).is_absolute() else Path(a)
        if p.is_file():
            files.append(p)
        elif p.is_dir():
            files += sorted(p.rglob("*.dart"))
    if not files:
        for d in ("lib", "test"):
            files += sorted((ROOT / d).rglob("*.dart"))

    files = [f for f in files if "trn(" in f.read_text(encoding="utf-8", errors="ignore")]
    total = 0
    for f in files:
        n = process(f, dry)
        if n:
            total += n
            if not dry:
                print(f"  {f.relative_to(ROOT)}: 还原 {n} 处")
    print(f"共还原 {total} 处 trn() 调用（文件 {len(files)} 个）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
