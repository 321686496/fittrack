"""扫描被"冻结"的 trn() —— 位于字段 / 顶层初始化位置的翻译调用。

背景
----
`trn()` 在调用瞬间查表，返回一个普通 String。如果它出现在

    static final List<X> xxx = [ trn('中文'), ... ];   // 类字段
    static final String yyy = trn('中文');             // 类字段
    final List<X> zzz = [ trn('中文'), ... ];          // 顶层变量

这类**初始化位置**，整个程序生命周期内只会求值一次，
结果被冻结在**首次访问时**的语言。用户在设置页切到英文后，
动作名 / 课程正文 / 教学文案仍然是中文。

注意区分：方法体里的 `final title = trn('...')` 每次调用都会重新求值，
**不是**冻结，不需要处理。本脚本用作用域分析（class 体 vs 函数体）来区分。

安全的写法只有两种：
1. 放在方法体里（每次调用重新求值）
2. 包一层 `LocaleMemo`，按语言代次缓存 —— 见 `lib/l10n/i18n.dart`

用法
----
    python scripts/i18n_check_frozen.py            # 汇总
    python scripts/i18n_check_frozen.py --detail   # 逐条列出
"""
import io
import os
import re
import sys

DECL_RE = re.compile(
    r'^(?P<indent>\s*)(?P<mods>(?:static\s+|late\s+|external\s+)*)'
    r'(?P<kind>final|const|var)?\s*'
    r'(?:(?P<type>[A-Za-z_][\w<>,\.\?\[\]\s]*?)\s+)?'
    r'(?P<name>[A-Za-z_]\w*)\s*=\s*(?P<rest>.*)$'
)

OPEN_TO_CLOSE = {'[': ']', '{': '}', '(': ')'}
CLASS_LIKE_RE = re.compile(r'\b(?:class|mixin|enum|extension)\b')


def strip_comment(line):
    out = []
    i = 0
    quote = None
    while i < len(line):
        c = line[i]
        if quote:
            out.append(c)
            if c == chr(92):
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


def _brace_kind(head):
    """判断 `{` 打开的是 class 体、函数体，还是表达式（继承父作用域）。"""
    h = head.rstrip()
    if CLASS_LIKE_RE.search(h):
        return 'class'
    if h.endswith(('=', ',', '(', '[', ':', '=>')):
        return 'inherit'
    return 'function'


def scope_kinds(lines):
    """返回每行**行首**所处的作用域栈（list of 'class'|'function'）。"""
    stack = []
    result = []
    for raw in lines:
        code = strip_comment(raw)
        result.append(list(stack))
        head = ''
        for ch in code:
            if ch == '{':
                kind = _brace_kind(head)
                if kind == 'inherit':
                    kind = stack[-1] if stack else 'top'
                stack.append(kind)
                head = ''
            elif ch == '}':
                if stack:
                    stack.pop()
                head = ''
            else:
                head += ch
    return result


def is_member_scope(scopes):
    """全部外层都是 class 体（或顶层）才算字段 / 顶层变量。"""
    return all(s == 'class' for s in scopes)


def find_initializer_end(lines, start_idx, start_col):
    """从 (行, 列) 处的开括号出发，返回配对闭括号的 (行, 列)。"""
    depth = 0
    started = False
    for i in range(start_idx, min(len(lines), start_idx + 20000)):
        code = strip_comment(lines[i])
        for j, ch in enumerate(code):
            if i == start_idx and j < start_col:
                continue
            if ch in OPEN_TO_CLOSE:
                depth += 1
                started = True
            elif ch in (']', '}', ')'):
                depth -= 1
                if started and depth == 0:
                    return i, j
    return None


def find_statement_end(lines, start_idx):
    """单值初始化：向后找到以 ';' 结尾的行。"""
    for i in range(start_idx, min(len(lines), start_idx + 500)):
        code = strip_comment(lines[i]).rstrip()
        if i == start_idx:
            code = code
        if code.endswith(';'):
            return i
    return start_idx


def scan(root='lib'):
    frozen = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ('.git', 'build', '.dart_tool')]
        for fn in sorted(filenames):
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn).replace(os.sep, '/')
            if path.endswith('lib/l10n/i18n.dart'):
                continue
            lines = io.open(path, encoding='utf-8').read().split('\n')
            scopes = scope_kinds(lines)
            for i, raw in enumerate(lines):
                m = DECL_RE.match(raw)
                if not m:
                    continue
                rest = m.group('rest')
                if not rest or 'LocaleMemo' in raw:
                    continue
                if not is_member_scope(scopes[i]):
                    continue  # 方法体内的局部变量：每次调用重新求值，不是冻结

                first = rest.lstrip()[:1]
                is_static = 'static' in (m.group('mods') or '')
                is_top_level = len(scopes[i]) == 0
                if first in OPEN_TO_CLOSE:
                    col = raw.index(rest) + (len(rest) - len(rest.lstrip()))
                    end = find_initializer_end(lines, i, col)
                    if end is None:
                        continue
                    if 'trn(' not in '\n'.join(lines[i:end[0] + 1]):
                        continue
                    frozen.append({
                        'path': path, 'line': i + 1, 'end_line': end[0] + 1,
                        'name': m.group('name'), 'kind': m.group('kind') or '',
                        'type': (m.group('type') or '').strip(), 'shape': 'collection',
                        'static': is_static, 'top_level': is_top_level,
                    })
                elif 'trn(' in rest:
                    end = find_statement_end(lines, i)
                    frozen.append({
                        'path': path, 'line': i + 1, 'end_line': end + 1,
                        'name': m.group('name'), 'kind': m.group('kind') or '',
                        'type': (m.group('type') or '').strip(), 'shape': 'scalar',
                        'static': is_static, 'top_level': is_top_level,
                    })
    return frozen


def main(argv):
    detail = '--detail' in argv
    frozen = scan('lib')
    by_file = {}
    for item in frozen:
        by_file.setdefault(item['path'], []).append(item)

    print('被冻结的 trn() 声明：%d 处，分布在 %d 个文件' % (len(frozen), len(by_file)))
    for path in sorted(by_file, key=lambda p: -len(by_file[p])):
        items = by_file[path]
        shapes = {'collection': 0, 'scalar': 0}
        for it in items:
            shapes[it['shape']] += 1
        notype = sum(1 for it in items if not it['type'])
        print('  %-44s %3d  (集合 %d / 单值 %d%s)' % (
            path, len(items), shapes['collection'], shapes['scalar'],
            '，%d 条无显式类型' % notype if notype else ''))
        if detail:
            for it in items:
                scope = 'static' if it['static'] else ('顶层' if it['top_level'] else '实例字段')
                print('        L%-5d %-30s %-26s [%s/%s]' % (
                    it['line'], it['name'], it['type'] or '(推断)', it['shape'], scope))
    return 0 if not frozen else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
