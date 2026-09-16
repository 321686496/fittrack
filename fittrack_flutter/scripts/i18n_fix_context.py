#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把「没有 context 可用」的位置从 tr(context, X) 改成 trn(X)。

codemod 按目录推断是否传 context，静态函数/顶层函数里并不存在 context。
依据 flutter analyze 报出的 undefined_identifier 定位这些行并降级为 trn(...)。

用法：
  python scripts/i18n_fix_context.py [analyze_errors.txt]
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_ERR = os.path.join(ROOT, 'build', 'i18n', 'analyze_errors.txt')

# 三种拿不到 BuildContext 的典型场景：
#   undefined_identifier                    静态/顶层函数里没有 context
#   implicit_this_reference_in_initializer   字段初始化器里访问 context
#   instance_member_access_from_static       静态方法里访问实例成员 context
LINE_RE = re.compile(
    r"'context'.*? - ([^\s:]+):(\d+):(\d+) - "
    r"(?:undefined_identifier|implicit_this_reference_in_initializer"
    r"|instance_member_access_from_static)$")

# 静态方法里访问 context —— 报错文案里不含 'context' 字样，单独匹配
STATIC_RE = re.compile(
    r" - ([^\s:]+):(\d+):(\d+) - instance_member_access_from_static$")

# 形参默认值必须是常量，包了 tr() 就非法 —— 直接还原成原始字面量
DEFAULT_RE = re.compile(
    r" - ([^\s:]+):(\d+):(\d+) - non_constant_default_value$")


UNWRAP_RE = re.compile(
    r"tr\(\s*context\s*,\s*('(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\")\s*\)"
    r"|trn\(\s*('(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\")\s*\)")


def _unwrap_file(rel: str, linenos) -> None:
    """形参默认值位置：把 tr(context, '中文') / trn('中文') 还原成 '中文'。"""
    fp = os.path.join(ROOT, rel)
    if not os.path.exists(fp):
        return
    with open(fp, encoding='utf-8', newline='') as f:
        content = f.read()
    eol = '\r\n' if '\r\n' in content else '\n'
    file_lines = [ln[:-1] if ln.endswith('\r') else ln for ln in content.split('\n')]
    changed = 0
    for ln in sorted(linenos):
        idx = ln - 1
        if not (0 <= idx < len(file_lines)):
            continue
        new = UNWRAP_RE.sub(lambda m: m.group(1) or m.group(2), file_lines[idx])
        if new != file_lines[idx]:
            file_lines[idx] = new
            changed += 1
    if changed:
        with open(fp, 'w', encoding='utf-8', newline='') as f:
            f.write(eol.join(file_lines))
        print(f'  unwrap {changed:3d}  {rel}')


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_ERR
    if not os.path.exists(path):
        sys.exit(f'no such file: {path}')
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()

    by_file: dict[str, set[int]] = {}
    unwrap: dict[str, set[int]] = {}
    for line in lines:
        for pattern, target in ((LINE_RE, by_file), (STATIC_RE, by_file),
                                (DEFAULT_RE, unwrap)):
            m = pattern.search(line)
            if m:
                rel = m.group(1).replace('\\', '/')
                target.setdefault(rel, set()).add(int(m.group(2)))
                break

    total = 0
    for rel, linenos in sorted(unwrap.items()):
        _unwrap_file(rel, linenos)
    for rel, linenos in sorted(by_file.items()):
        fp = os.path.join(ROOT, rel)
        if not os.path.exists(fp):
            print(f'  skip (missing): {rel}')
            continue
        with open(fp, encoding='utf-8', newline='') as f:
            content = f.read()
        # 注意：源文件可能是混合行尾，必须按 '\n' 切（只按 '\r\n' 切会少算行，导致行号错位）
        eol = '\r\n' if '\r\n' in content else '\n'
        file_lines = [ln[:-1] if ln.endswith('\r') else ln for ln in content.split('\n')]
        changed = 0
        for ln in sorted(linenos):
            idx = ln - 1
            if not (0 <= idx < len(file_lines)):
                continue
            new = re.sub(r'\btr\(\s*context\s*,', 'trn(', file_lines[idx])
            if new != file_lines[idx]:
                file_lines[idx] = new
                changed += 1
        if changed:
            with open(fp, 'w', encoding='utf-8', newline='') as f:
                f.write(eol.join(file_lines))
            total += changed
            print(f'  {changed:3d}  {rel}')
    print(f'total lines fixed: {total}')


if __name__ == '__main__':
    main()
