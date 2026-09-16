#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
i18n_coverage.py
================

统计「英文模式下仍会显示中文」的字符串，即代码里包了 tr()/trn() 但词典里
没有对应英译的条目，并给出出现位置，方便补翻译。

用法
----
    python scripts/i18n_coverage.py                # 只打印汇总
    python scripts/i18n_coverage.py --detail       # 打印全部缺失条目及位置
    python scripts/i18n_coverage.py --top 50       # 按出现次数打印前 50 条
    python scripts/i18n_coverage.py --lint         # 词典质量自检

默认自动定位项目根目录（含 `lib/l10n/strings_en.dart` 的那一层）。
如果脚本被放在项目之外（例如技能目录里），用 `--root` 显式指定：

    python i18n_coverage.py --root /path/to/fittrack_flutter --detail
    python i18n_coverage.py --root . --dict lib/l10n/strings_en.dart --lint
"""

from __future__ import annotations

import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

DICT_REL = Path("lib") / "l10n" / "strings_en.dart"

CJK = re.compile(r"[一-鿿]")
# 词典条目：'中文': 'English',
ENTRY_RE = re.compile(r"^\s*'((?:[^'\\]|\\.)*)'\s*:\s*'((?:[^'\\]|\\.)*)'\s*,?\s*$")
# tr(context, '中文') / trn('中文')
CALL_RE = re.compile(r"\b(?:tr|trn)\(\s*(?:context,\s*)?'((?:[^'\\]|\\.)*)'")


def resolve_root(cli_root: str | None = None) -> Path:
    """定位项目根目录。

    优先级：`--root` 参数 > 脚本所在目录向上查找 > 当前工作目录向上查找 > 当前工作目录。
    """
    if cli_root:
        return Path(cli_root).resolve()
    for base in (Path(__file__).resolve().parent, Path.cwd()):
        for cand in [base, *base.parents]:
            if (cand / DICT_REL).exists():
                return cand
    return Path.cwd()


ROOT = resolve_root()
DICT_FILE = ROOT / DICT_REL


def unescape(s: str) -> str:
    return (s.replace(r"\'", "'")
             .replace(r'\"', '"')
             .replace(r"\\", "\\")
             .replace(r"\$", "$")
             .replace(r"\n", "\n"))


def load_dict() -> set[str]:
    keys: set[str] = set()
    for line in DICT_FILE.read_text(encoding="utf-8").splitlines():
        m = ENTRY_RE.match(line)
        if m:
            keys.add(unescape(m.group(1)))
    return keys


def load_dict_pairs() -> list[tuple[str, str]]:
    pairs: list[tuple[str, str]] = []
    for line in DICT_FILE.read_text(encoding="utf-8").splitlines():
        m = ENTRY_RE.match(line)
        if m:
            pairs.append((unescape(m.group(1)), unescape(m.group(2))))
    return pairs


# 占位符：$name / ${expr} / {name}
PLACEHOLDER = re.compile(r"\$[A-Za-z_][A-Za-z0-9_]*|\$\{[^}]*\}|\{[A-Za-z_][A-Za-z0-9_]*\}")


def lint() -> int:
    """词典自检：找出译文本身有问题的条目。"""
    problems: list[tuple[str, str, str]] = []  # (类型, 中文, 英文)
    seen: dict[str, str] = {}

    for zh, en in load_dict_pairs():
        if zh in seen and seen[zh] != en:
            problems.append(("重复 key 且译文不一致", zh, f"{seen[zh]!r} vs {en!r}"))
        seen[zh] = en

        if not en.strip():
            problems.append(("译文为空", zh, en))
        if en == zh:
            problems.append(("译文与原文相同（疑似未翻译）", zh, en))
        if CJK.search(en):
            problems.append(("译文里残留中文", zh, en))
        # 前导/尾随空格本身没问题（多用于字符串拼接），但中英必须一致
        if (zh.strip() != zh) != (en.strip() != en):
            problems.append(("首尾空格不一致", zh, en))
        # 占位符集合必须一致，否则运行时替换会出错
        pz, pe = sorted(PLACEHOLDER.findall(zh)), sorted(PLACEHOLDER.findall(en))
        if pz != pe:
            problems.append(("占位符不一致", zh, f"{pz} -> {pe}"))
        # 中英标点混用（英文里出现中文全角标点）
        for bad in "，。、；：（）「」【】":
            if bad in en:
                problems.append(("英文里出现全角标点", zh, en))
                break

    print(f"词典条目数: {len(seen)}")
    if not problems:
        print("自检通过：没有发现问题条目")
        return 0

    buckets: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for kind, zh, en in problems:
        buckets[kind].append((zh, en))

    print(f"发现 {len(problems)} 条问题：\n")
    for kind, items in sorted(buckets.items(), key=lambda kv: -len(kv[1])):
        print(f"── {kind}（{len(items)}）")
        for zh, en in items[:20]:
            print(f"   {zh!r} -> {en!r}")
        if len(items) > 20:
            print(f"   …还有 {len(items) - 20} 条")
        print()
    return 1


def scan_calls() -> dict[str, list[tuple[str, int]]]:
    """返回 {中文串: [(文件:行号, ...)]}

    说明：
    - 只扫 `lib/`，跳过 `test/`（测试里有故意造的假串）与 `lib/l10n/`（词典自身的文档注释）。
    - `CALL_RE` 是按单引号字符串写的，遇到 `'…${a['b']}…'` 这种嵌套引号会被截断，
      截断片段会出现 `${` 与 `}` 数量不匹配。这类片段不是真实 key，直接丢弃。
    """
    hits: dict[str, list[tuple[str, int]]] = defaultdict(list)
    lib = ROOT / "lib"
    if not lib.is_dir():
        return hits
    for f in sorted(lib.rglob("*.dart")):
        if f.name == "strings_en.dart":
            continue
        rel = f.relative_to(ROOT).as_posix()
        if rel.startswith("lib/l10n/"):
            continue
        src = f.read_text(encoding="utf-8", errors="ignore")
        for i, line in enumerate(src.splitlines(), 1):
            for m in CALL_RE.finditer(line):
                text = unescape(m.group(1))
                if not CJK.search(text):
                    continue
                # 正则被嵌套引号截断的片段：丢弃
                if text.count("${") != text.count("}"):
                    continue
                hits[text].append((rel, i))
    return hits


def main() -> int:
    global ROOT, DICT_FILE

    args = sys.argv[1:]
    if "-h" in args or "--help" in args:
        print(__doc__)
        return 0

    if "--root" in args:
        ROOT = resolve_root(args[args.index("--root") + 1])
        DICT_FILE = ROOT / DICT_REL
    if "--dict" in args:
        DICT_FILE = Path(args[args.index("--dict") + 1]).resolve()

    if not DICT_FILE.exists():
        print(f"找不到词典文件：{DICT_FILE}", file=sys.stderr)
        print("用 --root <项目根目录> 或 --dict <词典路径> 指定。", file=sys.stderr)
        return 2

    detail = "--detail" in args
    top = 0
    if "--top" in args:
        idx = args.index("--top")
        top = int(args[idx + 1])

    if "--lint" in args:
        return lint()

    dictionary = load_dict()
    calls = scan_calls()

    missing = {k: v for k, v in calls.items() if k not in dictionary}
    total_kinds = len(calls)
    total_uses = sum(len(v) for v in calls.values())
    miss_kinds = len(missing)
    miss_uses = sum(len(v) for v in missing.values())

    print(f"项目根目录        : {ROOT}")
    print(f"词典文件          : {DICT_FILE.relative_to(ROOT).as_posix() if DICT_FILE.is_relative_to(ROOT) else DICT_FILE}")
    print(f"词典词条数        : {len(dictionary)}")
    print(f"代码中中文串种类  : {total_kinds}（引用 {total_uses} 处）")
    print(f"缺英译种类        : {miss_kinds}（引用 {miss_uses} 处）")
    if total_uses:
        print(f"英文覆盖率(按引用): {(1 - miss_uses / total_uses) * 100:.2f}%")
    if total_kinds:
        print(f"英文覆盖率(按种类): {(1 - miss_kinds / total_kinds) * 100:.2f}%")

    if detail or top:
        ordered = sorted(missing.items(), key=lambda kv: -len(kv[1]))
        if top:
            ordered = ordered[:top]
        print("\n缺失条目（按出现次数）:")
        for text, locs in ordered:
            where = ", ".join(f"{p}:{n}" for p, n in locs[:3])
            more = f"  …共 {len(locs)} 处" if len(locs) > 3 else ""
            print(f"  [{len(locs):>3}] {text!r}  <- {where}{more}")

    # 词典里有、但代码里已不再使用的词条（可选清理项）
    unused = dictionary - set(calls)
    print(f"\n词典中未被引用词条 : {len(unused)}（可忽略，插值匹配可能用到）")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
