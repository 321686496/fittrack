"""把被冻结的 trn() 声明改写为 LocaleMemo + getter。

改写形态
--------
集合：
    static final List<Course> courses = [ ... ];
    ->
    static List<Course> get courses => _coursesMemo.value;
    static final LocaleMemo<List<Course>> _coursesMemo = LocaleMemo(() => [ ... ]);

单值：
    static final String defaultCoach = trn('教练·凯文');
    ->
    static String get defaultCoach => _defaultCoachMemo.value;
    static final LocaleMemo<String> _defaultCoachMemo = LocaleMemo(() => trn('教练·凯文'));

只有"能确定类型"的声明才会被自动改写，其余会列进 SKIP 报告由人工处理。

用法
----
    python scripts/i18n_fix_frozen.py --dry-run
    python scripts/i18n_fix_frozen.py --apply
"""
import io
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from i18n_check_frozen import (  # noqa: E402
    DECL_RE,
    OPEN_TO_CLOSE,
    find_initializer_end,
    find_statement_end,
    is_member_scope,
    scope_kinds,
)

# 这些名字必须保持"与语言无关的中文键"，不能 memo 化（否则切语言后身份判断错位）。
# - _planTypes / _difficulties：元素本身是数据键，会和持久化的 plan['type'] 比较
# - _quickSetup 的键是普通中文字面量，memo 化不影响键，故不在排除之列
EXCLUDE_NAMES = {
    '_planTypes',
    '_difficulties',
}


I18N_IMPORT_RE = re.compile(r"^import\s+'[^']*l10n/i18n\.dart';")


def needs_i18n_import(text):
    for line in text.split('\n'):
        if I18N_IMPORT_RE.match(line.strip()):
            return True
    return False


def add_import(lines, path):
    """确保文件已 import i18n.dart（LocaleMemo 的来源）。"""
    for line in lines:
        if I18N_IMPORT_RE.match(line.strip()):
            return lines
    # 相对深度：lib/a/b.dart -> ../l10n/i18n.dart；lib/a.dart -> l10n/i18n.dart
    rel = path.split('lib/', 1)[1]
    depth = rel.count('/')
    prefix = '../' * depth if depth else ''
    target = "import '%sl10n/i18n.dart';" % prefix
    last_import = -1
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import = i
    if last_import < 0:
        return lines
    lines.insert(last_import + 1, '')
    lines.insert(last_import + 2, target)
    return lines


def transform(path, lines, dry_run):
    """就地改写，返回 (新行列表, 改写条目列表, 跳过条目列表)。"""
    applied = []
    skipped = []
    out = list(lines)
    scopes = scope_kinds(lines)
    # 从后往前改，避免行号漂移
    targets = []
    for i, raw in enumerate(lines):
        m = DECL_RE.match(raw)
        if not m:
            continue
        rest = m.group('rest')
        if not rest or 'LocaleMemo' in raw:
            continue
        if not is_member_scope(scopes[i]):
            continue
        name = m.group('name')
        if name in EXCLUDE_NAMES:
            skipped.append(('excluded-identity-key', i + 1, name, '身份键，须保持中文'))
            continue
        # 只有 static 字段 / 顶层变量可以安全 memo 化：
        # 实例字段常被 initState 或 setState 重新赋值，改成 getter 会编译不过。
        if not ('static' in (m.group('mods') or '') or len(scopes[i]) == 0):
            skipped.append(('instance-field', i + 1, name, raw.strip()))
            continue
        first = rest.lstrip()[:1]
        if first in OPEN_TO_CLOSE:
            col = raw.index(rest) + (len(rest) - len(rest.lstrip()))
            end = find_initializer_end(lines, i, col)
            if end is None:
                continue
            if 'trn(' not in '\n'.join(lines[i:end[0] + 1]):
                continue
            targets.append(('collection', i, end[0], m, raw, col))
        elif 'trn(' in rest:
            end = find_statement_end(lines, i)
            targets.append(('scalar', i, end, m, raw, None))

    for shape, start, end, m, raw, col in sorted(targets, key=lambda t: -t[1]):
        indent = m.group('indent')
        name = m.group('name')
        mods = m.group('mods') or ''
        is_static = 'static' in mods
        decl_type = (m.group('type') or '').strip()
        memo_name = '_%sMemo' % name.lstrip('_')

        if any(re.search(r'\b%s\b' % re.escape(memo_name), ln) for ln in out):
            skipped.append(('memo-exists', start + 1, name, memo_name))
            continue

        # 去掉 late（memo 是 lazy 的，不需要 late）
        getter_mods = 'static ' if is_static else ''
        memo_mods = 'static final ' if is_static else 'final '

        if shape == 'collection':
            if not decl_type:
                skipped.append(('no-type', start + 1, name, raw.strip()))
                continue
            first_line = out[start]
            open_col = first_line.index(m.group('rest')) + (
                len(m.group('rest')) - len(m.group('rest').lstrip()))
            open_bracket = first_line[open_col]
            close_bracket = OPEN_TO_CLOSE[open_bracket]
            getter_line = '%s%s%s get %s => %s.value;' % (
                indent, getter_mods, decl_type, name, memo_name)
            memo_head = '%s%sLocaleMemo<%s> %s = LocaleMemo(() => ' % (
                indent, memo_mods, decl_type, memo_name)

            if start == end:
                # 单行声明：`static final List<X> y = [a, b];`
                # 在闭括号后补一个 ')' 收掉 LocaleMemo( ，整行其余部分原样保留
                after_open = first_line[open_col + 1:]
                close_col = open_col + 1 + after_open.rindex(close_bracket)
                new_decl = (memo_head + first_line[open_col:close_col + 1] + ')'
                            + first_line[close_col + 1:])
                out[start:end + 1] = [getter_line, new_decl]
            else:
                # 多行声明：首行尾部 + 中间各行 + 闭括号行（补 ')'）都要保留
                middle = out[start + 1:end]
                close_line = out[end]
                pos = close_line.rindex(close_bracket)
                new_close = close_line[:pos] + close_bracket + ')' + close_line[pos + 1:]
                out[start:end + 1] = (
                    [getter_line, memo_head + first_line[open_col:]] + middle + [new_close])
            applied.append((shape, start + 1, name, decl_type))
        else:
            expr_start = out[start].index(m.group('rest'))
            parts = [out[start][expr_start:]] + out[start + 1:end + 1]
            expr = '\n'.join(parts).strip()
            if expr.endswith(';'):
                expr = expr[:-1].rstrip()
            # 类型可推断：trn() 的返回值就是 String
            scalar_type = decl_type or ('String' if expr.lstrip().startswith('trn(') else '')
            if not scalar_type:
                skipped.append(('scalar-unknown-type', start + 1, name, expr[:80]))
                continue
            getter_line = '%s%s%s get %s => %s.value;' % (
                indent, getter_mods, scalar_type, name, memo_name)
            memo_line = '%s%sLocaleMemo<%s> %s = LocaleMemo(() => %s);' % (
                indent, memo_mods, scalar_type, memo_name, expr)
            out[start:end + 1] = [getter_line, memo_line]
            applied.append((shape, start + 1, name, scalar_type))

    if applied and not needs_i18n_import('\n'.join(out)):
        out = add_import(out, path)

    return out, applied, skipped


def main(argv):
    dry_run = '--apply' not in argv
    total_applied = 0
    all_skipped = []
    changed_files = []

    for dirpath, dirnames, filenames in os.walk('lib'):
        dirnames[:] = [d for d in dirnames if d not in ('.git', 'build', '.dart_tool')]
        for fn in sorted(filenames):
            if not fn.endswith('.dart'):
                continue
            path = os.path.join(dirpath, fn).replace(os.sep, '/')
            if path.endswith('lib/l10n/i18n.dart'):
                continue
            original = io.open(path, encoding='utf-8').read()
            lines = original.split('\n')
            new_lines, applied, skipped = transform(path, lines, dry_run)
            if not applied and not skipped:
                continue
            if applied:
                changed_files.append(path)
                total_applied += len(applied)
                print('%-46s 改写 %d 条' % (path, len(applied)))
                for shape, lineno, name, dtype in applied:
                    print('      L%-5d %-28s %s  [%s]' % (lineno, name, dtype, shape))
            all_skipped += [(path,) + s for s in skipped]
            if applied and not dry_run:
                io.open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(new_lines))

    print()
    print('总计改写 %d 条，涉及 %d 个文件%s' % (
        total_applied, len(changed_files), '（dry-run，未落盘）' if dry_run else ''))
    if all_skipped:
        print()
        print('需人工处理 %d 条：' % len(all_skipped))
        for path, kind, lineno, name, detail in all_skipped:
            print('  %s:%d  [%s] %s  %s' % (path, lineno, kind, name, detail[:90]))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
