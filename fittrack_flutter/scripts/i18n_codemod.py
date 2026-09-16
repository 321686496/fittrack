#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""批量为 lib/ 下的中文字符串字面量包裹 tr(context, ...) / trn(...)。

规则：
  1. 跳过注释里的文本
  2. 跳过 import / export / part 语句
  3. 跳过 map key、case 标签（后面紧跟 ':'）、下标取值 map['中文']
  4. 跳过资源路径（含 .png/.jpg/... 或以 assets/ 开头）
  5. 跳过纯标点、debugPrint/print 日志
  6. pages/ widgets/ main.dart router.dart 用 tr(context, ...)，其余用 trn(...)
  7. 自动移除因包裹而失效的 const（含 static const -> static final）
  8. 自动补齐 ../l10n/i18n.dart 导入

用法：
  python scripts/i18n_codemod.py            # 执行改造
  python scripts/i18n_codemod.py --dry      # 只统计不落盘
"""
from __future__ import annotations

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from i18n_scan import Scanner, strip_quotes, CJK  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')

ASSET_EXT = re.compile(r'\.(png|jpe?g|gif|webp|svg|mp3|wav|mp4|json|txt|ttf|otf)\b', re.I)
LOG_CALL = re.compile(r'\b(debugPrint|print|debugPrintThrottled)\s*\($')
PURE_PUNCT = re.compile(r'^[\s\W\d_]+$', re.U)

# 需要 tr(context, ...) 的目录/文件（能拿到 BuildContext）
CONTEXT_DIRS = ('pages', 'widgets')
CONTEXT_FILES = ('lib/main.dart', 'lib/router.dart')

# 不需要改造的目录
SKIP_DIRS = ('lib/l10n',)

stats = {'files': 0, 'wrapped': 0, 'const_removed': 0, 'imports': 0}


def rel_path(path: str) -> str:
    return os.path.relpath(path, ROOT).replace('\\', '/')


def needs_context(rel: str) -> bool:
    if rel in CONTEXT_FILES:
        return True
    parts = rel.split('/')
    return len(parts) > 2 and parts[1] in CONTEXT_DIRS


def import_prefix(rel: str) -> str:
    """lib/pages/a.dart -> ../l10n/i18n.dart"""
    parts = rel.split('/')
    depth = len(parts) - 2  # lib/x/y.dart -> 1
    return '../' * max(depth, 0) + 'l10n/i18n.dart'


def should_skip(src: str, start: int, end: int, text: str) -> bool:
    # 资源路径 / 纯标点
    if ASSET_EXT.search(text) or text.startswith('assets/'):
        return True
    if PURE_PUNCT.match(text):
        return True
    # 已包裹
    before = src[:start]
    if re.search(r'\btrn?\s*\(\s*$', before):
        return True
    # 行首到字面量之间是日志调用
    line_start = src.rfind('\n', 0, start) + 1
    head = src[line_start:start]
    if LOG_CALL.search(head):
        return True
    if re.match(r'\s*(import|export|part)\b', head):
        return True

    # 下标取值 map['中文'] / 后继字符：map key / case 标签
    j = end
    while j < len(src) and src[j] in ' \t\n':
        j += 1
    k = start - 1
    while k >= 0 and src[k] in ' \t\n':
        k -= 1
    prev_ch = src[k] if k >= 0 else ''
    next_ch = src[j] if j < len(src) else ''

    if prev_ch == '[' and next_ch == ']':
        return True

    if next_ch == ':':
        # 三元表达式的真值分支不能被跳过：cond ? '中文' : 'x'
        if prev_ch == '?':
            return False
        # map 字面量的 key：{'中文': v} 或 '中文': v,
        if prev_ch in '{,':
            return True
        # 行首起就是本字面量（多行 map / case '中文':）
        if src[line_start:start].strip() == '':
            return True
        # case '中文':
        if re.search(r'\bcase\s+$', src[line_start:start]):
            return True
    return False


def remove_broken_const(src: str) -> tuple[str, int]:
    """移除因包裹 tr() 而失效的 const。返回 (新源码, 移除数量)。"""
    removed = 0
    for _ in range(6):
        changed = False
        for m in list(re.finditer(r'\b(static\s+)?const\b', src)):
            start, end = m.start(), m.end()
            # 后续第一个非空白字符
            j = end
            while j < len(src) and src[j] in ' \t\n':
                j += 1
            if j >= len(src):
                continue
            nxt = src[j]
            is_decl = False
            span_start = -1
            if nxt in '[{<':
                span_start = j
            elif nxt.isupper():
                # const Foo(  —— 找到 '('
                k = j
                while k < len(src) and (src[k].isalnum() or src[k] == '_'):
                    k += 1
                if k < len(src) and src[k] == '(':
                    span_start = k
                elif k < len(src) and src[k] in '[{<':
                    span_start = k
            elif nxt.islower() or nxt == '_' or nxt == '$':
                is_decl = True  # const foo = ...
                k = j
                while k < len(src) and (src[k].isalnum() or src[k] in '_$'):
                    k += 1
                k2 = k
                while k2 < len(src) and src[k2] in ' \t':
                    k2 += 1
                if not (k2 < len(src) and src[k2] == '='):
                    continue
                span_start = k2
            if span_start < 0:
                continue

            # 匹配 span_start 起的括号，取表达式范围
            open_ch = src[span_start]
            close_map = {'(': ')', '[': ']', '{': '}', '<': '>'}
            if open_ch == '=':
                # 声明：扫到分号或换行（简单处理：到行尾分号）
                line_end = src.find(';', span_start)
                line_end = len(src) if line_end == -1 else line_end
                span = src[start:line_end]
            else:
                close_ch = close_map[open_ch]
                depth = 0
                k = span_start
                while k < len(src):
                    if src[k] == open_ch:
                        depth += 1
                    elif src[k] == close_ch:
                        depth -= 1
                        if depth == 0:
                            break
                    k += 1
                span = src[start:k + 1]

            if 'tr(' not in span and 'trn(' not in span:
                continue

            if is_decl:
                repl = ('static final' if m.group(1) else 'final')
            elif m.group(1):
                repl = 'static final'
            else:
                repl = ''
            # 用 repl 替换 [start, j) 之间的 "static const" / "const" 及其空白
            src = src[:start] + repl + (' ' if repl else '') + src[j:]
            removed += 1
            changed = True
            break
        if not changed:
            break
    return src, removed


def process(path: str, dry: bool) -> None:
    rel = rel_path(path)
    # newline='' 保留原文件的 CRLF/LF，避免整文件产生行尾 diff
    with open(path, encoding='utf-8', newline='') as f:
        src = f.read()

    hits = []
    for start, end, raw in Scanner(src).scan():
        text = strip_quotes(raw)
        if not CJK.search(text):
            continue
        if should_skip(src, start, end, text):
            continue
        hits.append((start, end, raw))
    if not hits:
        return

    use_ctx = needs_context(rel)
    fn = 'tr(context, ' if use_ctx else 'trn('
    out = []
    prev = 0
    for start, end, raw in hits:
        out.append(src[prev:start])
        out.append(f'{fn}{raw})')
        prev = end
    out.append(src[prev:])
    new_src = ''.join(out)

    new_src, removed = remove_broken_const(new_src)

    # 补 import
    imp = import_prefix(rel)
    if f"l10n/i18n.dart" not in new_src:
        # 插入到最后一个 import 之后，否则插到文件头
        imports = list(re.finditer(r'^import .*?;\s*$', new_src, re.M))
        eol = '\r\n' if '\r\n' in new_src else '\n'
        line = f"import '{imp}';{eol}"
        if imports:
            pos = imports[-1].end()
            new_src = new_src[:pos] + '\n' + line.rstrip('\n') + new_src[pos:]
        else:
            new_src = line + new_src
        stats['imports'] += 1

    if not dry:
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(new_src)
    stats['files'] += 1
    stats['wrapped'] += len(hits)
    stats['const_removed'] += removed
    print(f'  {len(hits):4d} wrapped  {rel}')


def main() -> None:
    dry = '--dry' in sys.argv
    targets = [a for a in sys.argv[1:] if not a.startswith('--')]
    print('dry run' if dry else 'applying codemod')

    if targets:
        for t in targets:
            process(os.path.join(ROOT, t.replace('/', os.sep)), dry)
        print(stats)
        return

    for dirpath, _, filenames in os.walk(LIB):
        r = os.path.relpath(dirpath, ROOT).replace('\\', '/')
        if any(r.startswith(d) for d in SKIP_DIRS):
            continue
        for fn in sorted(filenames):
            if not fn.endswith('.dart'):
                continue
            process(os.path.join(dirpath, fn), dry)
    print(stats)


if __name__ == '__main__':
    main()
