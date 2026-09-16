#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""移除因包裹 tr()/trn() 而失效的 const。

codemod 里的括号匹配对 `const List<Map<String, dynamic>>` 这类泛型写法会失手，
这里改用「按 token 判断 + 只处理代码区（跳过注释与字符串）」的方式统一清理：

  - static const X    -> static final X
  - const X = ...     -> final X = ...        （声明）
  - const [ / { / <   -> 直接删除 const       （表达式）
  - const Foo(...)    -> 直接删除 const       （表达式）
  - 参数默认值里的 const（({this.x = const []})）保持不动

用法：
  python scripts/i18n_fix_const.py
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')
SKIP_DIRS = ('lib/l10n',)

CONST_RE = re.compile(r'\bconst\b')


def code_mask(src: str) -> bytearray:
    """1 = 代码区，0 = 注释或字符串内部。"""
    mask = bytearray(b'\x01') * len(src)
    n = len(src)
    i = 0
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if c == '/' and nxt == '/':
            j = src.find('\n', i)
            j = n if j == -1 else j
            mask[i:j] = b'\x00' * (j - i)
            i = j
        elif c == '/' and nxt == '*':
            depth = 1
            start = i
            i += 2
            while i < n and depth > 0:
                if src.startswith('/*', i):
                    depth += 1
                    i += 2
                elif src.startswith('*/', i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            mask[start:i] = b'\x00' * (i - start)
        elif c in ('"', "'"):
            start, i = _skip_string(src, i, mask)
        elif c == 'r' and nxt in ('"', "'"):
            start, i = _skip_string(src, i + 1, mask)
            mask[start:start + 1] = b'\x00'
        else:
            i += 1
    return mask


def _skip_string(src: str, i: int, mask: bytearray):
    n = len(src)
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
            if src.startswith(delim, i):
                i += 3
                break
            i += 1
    else:
        while i < n:
            c = src[i]
            if c == '\\':
                i += 2
                continue
            if c == quote:
                i += 1
                break
            if c == '\n':
                break
            i += 1
    mask[start:i] = b'\x00' * (i - start)
    return start, i


def _expr_after(src: str, j: int) -> bool:
    """从 j 起的标识符（可带 . 成员访问）后面是否紧跟 '(' 或 '<'，即构造/泛型表达式。"""
    n = len(src)
    k = j
    while k < n:
        if src[k].isalnum() or src[k] in '_$':
            k += 1
        elif src[k] == '.' and k + 1 < n and (src[k + 1].isalnum() or src[k + 1] in '_$'):
            k += 2
        else:
            break
    return k < n and src[k] in '(<'


def repair_bad_final(src: str) -> str:
    """上一版脚本把 `const EdgeInsets.symmetric(` 误改成 `final EdgeInsets.symmetric(`，
    这里把「final + 表达式调用」还原为直接删掉 final。"""
    # 仅处理后面紧跟 '(' 的情况，避免误伤 `final List<String> x = ...` 这类声明
    return re.sub(r'(?<![\w.$])final\s+(?=[A-Za-z_$][\w$]*(?:\.[\w$]+)*\s*\()', '', src)


def is_default_value(src: str, pos: int) -> bool:
    """const 是否位于形参默认值位置（({this.x = const []})）—— 这类不能删。"""
    j = pos - 1
    while j >= 0 and src[j] in ' \t\r\n':
        j -= 1
    if j < 0 or src[j] != '=':
        return False
    # 往前找最近的 ( 或 , ，若中间没有 ; { } 则认定为参数列表
    k = j - 1
    while k >= 0 and src[k] not in '(),{};':
        k -= 1
    return k >= 0 and src[k] in '(,'


def process(path: str) -> int:
    with open(path, encoding='utf-8', newline='') as f:
        original = f.read()
    src = repair_bad_final(original)
    if src != original and '\n' not in src:  # 安全兜底，理论上不会触发
        src = original
    mask = code_mask(src)

    edits: list[tuple[int, int, str]] = []  # (start, end, replacement)
    for m in CONST_RE.finditer(src):
        s, e = m.start(), m.end()
        if not mask[s]:
            continue
        if is_default_value(src, s):
            continue

        # static const -> static final
        head = src[:s]
        sm = re.search(r'\bstatic\s+$', head)
        if sm:
            edits.append((sm.start(), e, 'static final'))
            continue

        j = e
        while j < len(src) and src[j] in ' \t\r\n':
            j += 1
        if j >= len(src):
            continue
        c = src[j]
        if c in '[{<':
            edits.append((s, j, ''))  # 删掉 const 及其后空白
        elif c.isalpha() or c in '_$':
            # 标识符（含 EdgeInsets.symmetric 这种带点的构造调用）后紧跟 '(' / '<'
            # 说明是表达式；否则是「const x = ...」声明，改成 final
            if _expr_after(src, j):
                edits.append((s, j, ''))
            else:
                edits.append((s, e, 'final'))
        # 其他情况保持原样

    edits.sort(key=lambda x: x[0], reverse=True)
    out = src
    for s, e, rep in edits:
        out = out[:s] + rep + out[e:]

    if out != original:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(out)
        return max(len(edits), 1)
    return 0


def main() -> None:
    total_files = 0
    total_edits = 0
    for dirpath, _, filenames in os.walk(LIB):
        r = os.path.relpath(dirpath, ROOT).replace('\\', '/')
        if any(r.startswith(d) for d in SKIP_DIRS):
            continue
        for fn in sorted(filenames):
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn)
            with open(path, encoding='utf-8', newline='') as f:
                if 'l10n/i18n.dart' not in f.read():
                    continue
            n = process(path)
            if n:
                total_files += 1
                total_edits += n
                print(f'  {n:4d}  {os.path.relpath(path, ROOT)}')
    print(f'files: {total_files}, const removed: {total_edits}')


if __name__ == '__main__':
    sys.exit(main())
