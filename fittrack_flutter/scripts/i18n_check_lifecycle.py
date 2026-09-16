"""扫描生命周期方法里误用 tr(context) 的位置。

Dart 规则：initState() 完成前不能访问 InheritedWidget（dependOnInheritedWidgetOfExactType），
否则抛 FlutterError。codemod 机械包裹时容易把 tr(context, ...) 塞进 initState。
"""
import io
import os
import re
import sys


def strip_comment(line):
    """去掉行尾 // 注释，同时跳过字符串字面量内部。"""
    out = []
    i = 0
    quote = None
    while i < len(line):
        c = line[i]
        if quote:
            out.append(c)
            if c == chr(92):  # 反斜杠转义
                if i + 1 < len(line):
                    out.append(line[i + 1])
                    i += 2
                    continue
            elif c == quote:
                quote = None
            i += 1
            continue
        if c in ("'", '"'):
            quote = c
            out.append(c)
            i += 1
            continue
        if c == '/' and i + 1 < len(line) and line[i + 1] == '/':
            break
        out.append(c)
        i += 1
    return ''.join(out)


def find_block_end(lines, start_idx, max_scan=5000):
    """从 start_idx 行开始，找第一个 '{' 的配对 '}' 所在行号。"""
    depth = 0
    started = False
    for i in range(start_idx, min(len(lines), start_idx + max_scan)):
        for ch in strip_comment(lines[i]):
            if ch == '{':
                depth += 1
                started = True
            elif ch == '}':
                depth -= 1
                if started and depth == 0:
                    return i
    return None


METHOD_RE = re.compile(
    r'^\s*(?:@override\s*)?(?:void|Future<[^>]*>|Future)\s+'
    r'(initState|didChangeDependencies)\s*\(\s*\)\s*(?:async\s*)?\{?\s*$'
)
TR_CTX_RE = re.compile(r'\btr\s*\(\s*context\b')


def main(root='lib'):
    hits = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ('.git', 'build', '.dart_tool')]
        for fn in filenames:
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn).replace(os.sep, '/')
            lines = io.open(path, encoding='utf-8').read().split('\n')
            for i, line in enumerate(lines):
                m = METHOD_RE.match(line)
                if not m:
                    continue
                method = m.group(1)
                end = find_block_end(lines, i)
                if end is None:
                    continue
                for j in range(i, end + 1):
                    if TR_CTX_RE.search(strip_comment(lines[j])):
                        hits.append((path, method, j + 1, lines[j].strip()))

    print('命中 %d 处：' % len(hits))
    for path, method, lineno, code in hits:
        print('  %s:%d  [%s]  %s' % (path, lineno, method, code))
    return 0 if not hits else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else 'lib'))
