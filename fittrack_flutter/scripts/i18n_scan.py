#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""扫描 lib/ 下的 Dart 源码，抽取所有含中日韩字符的字符串字面量。

输出：
  build/i18n/strings.json  ——  { "中文串": {"count": n, "files": [...] } }

扫描时会跳过注释、import 语句，并支持：
  - 单引号 / 双引号 / 三引号
  - r'' 原始字符串
  - 字符串插值 ${...} / $var（保留原文，作为翻译模板）
"""
from __future__ import annotations

import json
import os
import re
import sys

CJK = re.compile(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\u3000-\u303f\uff00-\uffef]')


class Scanner:
    """极简 Dart 词法扫描器：只关心「代码中的字符串字面量」边界。"""

    def __init__(self, src: str):
        self.src = src
        self.n = len(src)
        self.i = 0
        self.strings: list[tuple[int, int, str]] = []  # (start, end, raw_text_with_quotes)
        # 处于字符串插值 ${...} 内部时不记录字面量——插值里的 'xxx' 是表达式的
        # 一部分，不是独立文案，包裹它会破坏外层字符串
        self.in_interp = False

    def scan(self) -> list[tuple[int, int, str]]:
        while self.i < self.n:
            c = self.src[self.i]
            nxt = self.src[self.i + 1] if self.i + 1 < self.n else ''
            if c == '/' and nxt == '/':
                self._skip_line_comment()
            elif c == '/' and nxt == '*':
                self._skip_block_comment()
            elif c in ('"', "'"):
                self._read_string()
            elif c == 'r' and nxt in ('"', "'"):
                self.i += 1
                self._read_string()
            else:
                self.i += 1
        return self.strings

    def _skip_line_comment(self) -> None:
        j = self.src.find('\n', self.i)
        self.i = self.n if j == -1 else j + 1

    def _skip_block_comment(self) -> None:
        depth = 1
        self.i += 2
        while self.i < self.n and depth > 0:
            if self.src.startswith('/*', self.i):
                depth += 1
                self.i += 2
            elif self.src.startswith('*/', self.i):
                depth -= 1
                self.i += 2
            else:
                self.i += 1

    def _read_string(self) -> None:
        quote = self.src[self.i]
        start = self.i
        self.i += 1
        # 三引号
        if self.src.startswith(quote * 2, self.i):
            self._read_multiline(quote * 3, start)
            return
        while self.i < self.n:
            c = self.src[self.i]
            if c == '\\':
                self.i += 2
                continue
            if c == quote:
                self.i += 1
                self.strings.append((start, self.i, self.src[start:self.i]))
                return
            if c == '\n':  # 单引号串不允许跨行，视为异常，终止
                return
            if c == '$' and self.i + 1 < self.n and self.src[self.i + 1] == '{':
                self._skip_interp()
                continue
            self.i += 1

    def _read_multiline(self, delim: str, start: int) -> None:
        self.i = start + 3
        while self.i < self.n:
            if self.src[self.i] == '\\':
                self.i += 2
                continue
            if self.src.startswith(delim, self.i):
                self.i += len(delim)
                self.strings.append((start, self.i, self.src[start:self.i]))
                return
            if self.src.startswith('${', self.i):
                self._skip_interp()
                continue
            self.i += 1

    def _skip_interp(self) -> None:
        depth = 1
        self.i += 2  # 越过 ${
        while self.i < self.n and depth > 0:
            c = self.src[self.i]
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    self.i += 1
                    return
            elif c in ('"', "'"):
                self._read_string()  # 嵌套字符串（会污染 strings 列表，后续按内容过滤）
                continue
            self.i += 1


def strip_quotes(raw: str) -> str:
    if raw.startswith("r'''") or raw.startswith('r"""'):
        return raw[4:-3]
    if raw.startswith("r'") or raw.startswith('r"'):
        return raw[2:-1]
    if raw.startswith("'''") or raw.startswith('"""'):
        return raw[3:-3]
    return raw[1:-1]


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lib_dir = os.path.join(root, 'lib')
    out: dict[str, dict] = {}

    count_files = 0
    for dirpath, _, filenames in os.walk(lib_dir):
        for fn in filenames:
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, root).replace('\\', '/')
            with open(path, encoding='utf-8') as f:
                src = f.read()
            count_files += 1
            for start, end, raw in Scanner(src).scan():
                text = strip_quotes(raw)
                if not CJK.search(text):
                    continue
                # 跳过 import / export 语句
                line_start = src.rfind('\n', 0, start) + 1
                head = src[line_start:start]
                if re.match(r'\s*(import|export|part)\b', head):
                    continue
                entry = out.setdefault(text, {'count': 0, 'files': []})
                entry['count'] += 1
                if rel not in entry['files']:
                    entry['files'].append(rel)

    out_dir = os.path.join(root, 'build', 'i18n')
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, 'strings.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)

    total = sum(v['count'] for v in out.values())
    print(f'files scanned: {count_files}')
    print(f'unique CJK strings: {len(out)}')
    print(f'total occurrences: {total}')
    top = sorted(out.items(), key=lambda kv: -kv[1]['count'])[:20]
    print('--- top 20 ---')
    for k, v in top:
        print(f"{v['count']:5d}  {k[:60]}")


if __name__ == '__main__':
    sys.exit(main())
