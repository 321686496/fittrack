#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按 flutter analyze 报出的 const_with_non_const / const_initialized_with_non_constant_value
位置，去掉调用点上的 const（构造函数的 const 声明被清理后，调用点也要跟着去掉）。

用法：
  python scripts/i18n_fix_const_call.py [analyze_errors.txt]
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ERR = os.path.join(ROOT, 'build', 'i18n', 'analyze_errors.txt')

LINE_RE = re.compile(
    r" - ([^\s:]+):(\d+):(\d+) - "
    r"(?:const_with_non_const|const_initialized_with_non_constant_value)$")


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ERR
    if not os.path.exists(path):
        sys.exit(f'no such file: {path}')
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()

    by_file: dict[str, list[tuple[int, int]]] = {}
    for line in lines:
        m = LINE_RE.search(line)
        if not m:
            continue
        rel = m.group(1).replace('\\', '/')
        by_file.setdefault(rel, []).append((int(m.group(2)), int(m.group(3))))

    total = 0
    for rel, items in sorted(by_file.items()):
        fp = os.path.join(ROOT, rel)
        if not os.path.exists(fp):
            print(f'  skip (missing): {rel}')
            continue
        with open(fp, encoding='utf-8', newline='') as f:
            content = f.read()
        eol = '\r\n' if '\r\n' in content else '\n'
        file_lines = [ln[:-1] if ln.endswith('\r') else ln for ln in content.split('\n')]
        changed = 0
        for ln, col in sorted(items, reverse=True):
            idx = ln - 1
            if not (0 <= idx < len(file_lines)):
                continue
            text = file_lines[idx]
            # 报错列指向构造函数名，const 可能就在本行（也可能在上一行，多行写法）
            found = [m for m in re.finditer(r'\bconst[ \t]+', text) if m.start() < col]
            if found:
                m = found[-1]
                file_lines[idx] = text[:m.start()] + text[m.end():]
                changed += 1
                continue
            for back in range(1, 4):                      # 往回找 3 行
                j = idx - back
                if j < 0:
                    break
                found = list(re.finditer(r'\bconst[ \t]+', file_lines[j]))
                if found:
                    m = found[-1]
                    file_lines[j] = file_lines[j][:m.start()] + file_lines[j][m.end():]
                    changed += 1
                    break
        if changed:
            with open(fp, 'w', encoding='utf-8', newline='') as f:
                f.write(eol.join(file_lines))
            total += changed
            print(f'  {changed:3d}  {rel}')
    print(f'total: {total}')


if __name__ == '__main__':
    main()
