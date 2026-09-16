#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修复 codemod 对「字符串插值里带引号」字面量的重复包裹。

错误形态（外层串含 ${... ?? '中文'} 时）：
    '${a ?? tr(context, '默认')tr(context, '${a ?? '默认'}')'
                 ^^^^^^^^^^^^^^^^^ 重复片段
正确结果：
    tr(context, '${a ?? '默认'}')

识别依据：正常代码里不可能出现 `)tr(` / `)trn(`（一个调用紧跟另一个调用）。
修复方式：删掉「外层字面量开头 → 内层包裹调用结束」这一段，只保留最后那个
完整的外层包裹调用。
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')
SKIP_DIRS = ('lib/l10n',)

MARKER = re.compile(r'\)tr(n?)\(')


def _skip_interp(src: str, i: int) -> int:
    """i 指向 '${' 的 '$'，返回插值结束（匹配的 '}' 之后）的位置。"""
    n = len(src)
    depth = 1
    i += 2
    while i < n and depth > 0:
        c = src[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return i


def read_literal(src: str, i: int):
    """从 i 处读一个 Dart 字符串字面量，返回 (start, end) 或 None。

    需跳过 ${...} 插值——插值里可能带引号（如 ${a ?? '中文'}），
    简单按引号配对会提前截断。
    """
    n = len(src)
    if i >= n or src[i] not in '\'"':
        return None
    quote = src[i]
    start = i
    i += 1
    if src.startswith(quote * 3, i):
        delim = quote * 3
        i += 3
        while i < n:
            if src[i] == '\\':
                i += 2
                continue
            if src.startswith('${', i):
                i = _skip_interp(src, i)
                continue
            if src.startswith(delim, i):
                return start, i + 3
            i += 1
        return None
    while i < n:
        c = src[i]
        if c == '\\':
            i += 2
            continue
        if c == quote:
            return start, i + 1
        if c == '\n':
            return None
        if c == '$' and i + 1 < n and src[i + 1] == '{':
            i = _skip_interp(src, i)
            continue
        i += 1
    return None


def find_call_start(src: str, close_pos: int):
    """给定调用的右括号位置，向前找到调用起点（tr / trn 的位置）。"""
    depth = 0
    i = close_pos
    while i >= 0:
        if src[i] == ')':
            depth += 1
        elif src[i] == '(':
            depth -= 1
            if depth == 0:
                paren = i
                ns = src.rfind('tr', max(0, paren - 20), paren)
                return ns if ns >= 0 else None
        i -= 1
    return None


def fix_once(src: str):
    m = MARKER.search(src)
    if not m:
        return src, 0

    close1 = m.start()            # 内层调用的右括号位置
    call2 = m.end() - 1           # 外层调用左括号 '(' 的位置

    ns = find_call_start(src, close1)
    if ns is None or ns >= close1:
        return src, 0

    # 外层调用的实参 = 完整的原始字面量（跳过 tr 的 context 形参）
    j = call2
    while j < len(src) and src[j] != '(':
        j += 1
    j += 1
    arg = re.match(r'\s*(?:context\s*,\s*)?', src[j:])
    j += arg.end() if arg else 0
    lit = read_literal(src, j)
    if lit is None:
        return src, 0
    outer_lit = src[lit[0]:lit[1]]

    # 外层字面量的起点 k：src[k:ns] 必须是 outer_lit 的前缀，取最长匹配
    best = None
    max_len = min(ns, len(outer_lit) - 1)
    for ln in range(max_len, 0, -1):
        if src[ns - ln:ns] == outer_lit[:ln]:
            best = ns - ln
            break
    if best is None:
        return src, 0

    return src[:best] + src[close1 + 1:], 1


# 相邻字符串字面量（Dart 隐式拼接）被分别包裹后成了两个紧邻的调用：
#     tr(context, '前半句')
#     tr(context, '后半句')
# 需要改成显式 + 拼接，否则既编译不过，也无法逐段命中词典
CALL_RE = re.compile(r'tr(?:n)?\(')
ARG_PREFIX = re.compile(r'\s*(?:context\s*,\s*)?')


def merge_adjacent(src: str):
    """把紧邻的两个 tr/trn 调用改成 `tr(...) + tr(...)` 显式拼接。

    只在「前一个调用的实参确实是字符串字面量且紧跟 ')'」时才插 '+',
    避免把 `foo(x)` 换行后接 `trn(...)` 这类无关语句误连成表达式。
    """
    n = len(src)
    inserts: list[int] = []
    i = 0
    while True:
        m = CALL_RE.search(src, i)
        if not m:
            break
        j = m.end()
        am = ARG_PREFIX.match(src, j)
        # 注意：match(str, pos) 返回的 end() 是绝对下标，直接赋值而非累加
        if am:
            j = am.end()
        lit = read_literal(src, j)
        if lit is None:
            i = m.end()
            continue
        k = lit[1]
        while k < n and src[k] in ' \t\r\n':
            k += 1
        if k < n and src[k] == ')':
            p = k + 1
            while p < n and src[p] in ' \t\r\n':
                p += 1
            if CALL_RE.match(src, p) and p not in inserts:
                inserts.append(p)
        i = m.end()

    if not inserts:
        return src
    out = src
    for p in sorted(inserts, reverse=True):
        out = out[:p] + ' + ' + out[p:]
    return out


def process(path: str) -> int:
    with open(path, encoding='utf-8', newline='') as f:
        src = f.read()
    total = 0
    for _ in range(60):
        src, n = fix_once(src)
        if not n:
            break
        total += n

    merged = merge_adjacent(src)
    if merged != src:
        total += merged.count(') + tr') or 1
        src = merged

    if total:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(src)
    return total


def main() -> None:
    files = 0
    fixes = 0
    for dirpath, _, filenames in os.walk(LIB):
        r = os.path.relpath(dirpath, ROOT).replace('\\', '/')
        if any(r.startswith(d) for d in SKIP_DIRS):
            continue
        for fn in sorted(filenames):
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn)
            n = process(path)
            if n:
                files += 1
                fixes += n
                print(f'  {n:3d}  {os.path.relpath(path, ROOT)}')
    print(f'files: {files}, fixes: {fixes}')


if __name__ == '__main__':
    sys.exit(main())
