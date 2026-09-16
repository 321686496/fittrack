#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 build/i18n/batches/out_*.json 合并生成 lib/l10n/strings_en.dart。

会做以下校验并打印报告：
  - 覆盖率：抽取出的中文串里有多少拿到了译文
  - 占位符一致性：译文里的 $var / ${expr} 是否与原文一致
  - 首尾空格一致性
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BATCH_DIR = os.path.join(ROOT, 'build', 'i18n', 'batches')
STRINGS_JSON = os.path.join(ROOT, 'build', 'i18n', 'strings.json')
OUT_FILE = os.path.join(ROOT, 'lib', 'l10n', 'strings_en.dart')

# 注意：这里必须用 [A-Za-z0-9_] 而非 \w —— Python 的 \w 会匹配中文，
# 会把「$actual秒」整体当成一个占位符，造成误报（Dart RegExp 的 \w 是 ASCII 语义）。
PLACEHOLDER = re.compile(r'\$[A-Za-z_][A-Za-z0-9_]*|\$\{[^}]*\}')

RUNTIME = r'''// 中 → 英 文案词典
//
// key 为中文源串，value 为英文译文。未命中时 [I18nStrings.translate] 原样返回
// 中文，保证不会出现空文案。
//
// 词条表 _enMap 由 scripts/gen_i18n_dict.py 生成；需要补充词条时
// 直接往 _enMap 里加即可。本文件除 _enMap 外的代码为通用匹配逻辑，请勿改动。

/// 插值占位符（`$name` 或 `${expr}`）
final RegExp _interpPattern = RegExp(r'\$[A-Za-z_]\w*|\$\{[^}]*\}', dotAll: true);

final RegExp _digitPattern = RegExp(r'\d+');

/// 归一化哨兵字符（词典内部使用）
const String _ph = '\u0000';

/// 精确匹配表
final Map<String, String> _exact = <String, String>{};

/// 数字归一化表（处理「共3天 / 共5天」这类同模板不同数字的文案）
final Map<String, String> _normalized = <String, String>{};

/// 插值模板规则（处理「第${day}天」这类运行时才确定参数的文案）
final List<_TemplateRule> _templates = <_TemplateRule>[];

bool _built = false;

class I18nStrings {
  I18nStrings._();

  /// 中文 → 英文。未命中词典时原样返回（回落中文）。
  static String translate(String text) {
    if (text.isEmpty) return text;
    _ensureBuilt();

    final exact = _exact[text];
    if (exact != null) return exact;

    if (_digitPattern.hasMatch(text)) {
      final hit = _normalized[_normalize(text)];
      if (hit != null) return _fillDigits(hit, text);
    }

    for (final rule in _templates) {
      final result = rule.apply(text);
      if (result != null) return result;
    }
    return text;
  }
}

void _ensureBuilt() {
  if (_built) return;
  _built = true;
  for (final entry in _enMap.entries) {
    final zh = entry.key;
    final en = entry.value;
    if (en.isEmpty) continue;
    if (_interpPattern.hasMatch(zh)) {
      final rule = _TemplateRule.tryBuild(zh, en);
      if (rule != null) {
        _templates.add(rule);
        continue;
      }
    }
    if (_digitPattern.hasMatch(zh)) {
      _normalized[_normalize(zh)] = en;
      continue;
    }
    _exact[zh] = en;
  }
  // 字面量越多的规则越具体，优先匹配，避免 "^(.*?)$" 这类宽松规则吞掉后面的规则
  _templates.sort((a, b) => b.literalLength.compareTo(a.literalLength));
}

String _normalize(String s) => s.replaceAll(_digitPattern, _ph);

/// 把原文中的数字按出现顺序回填到译文模板的占位符上
String _fillDigits(String template, String source) {
  final runs = _digitPattern
      .allMatches(source)
      .map((m) => m.group(0)!)
      .toList(growable: false);
  var index = 0;
  final buffer = StringBuffer();
  for (var i = 0; i < template.length; i++) {
    if (template[i] == _ph) {
      buffer.write(index < runs.length ? runs[index] : _ph);
      index++;
    } else {
      buffer.write(template[i]);
    }
  }
  return buffer.toString();
}

class _TemplateRule {
  _TemplateRule(this.pattern, this.enParts, this.literalLength);

  final RegExp pattern;
  final List<String> enParts;

  /// 中文模板里固定字面量的总长度，用于规则优先级排序
  final int literalLength;

  static _TemplateRule? tryBuild(String zh, String en) {
    final zhParts = _splitByInterp(zh);
    final enParts = _splitByInterp(en);
    // 译文增删了插值时无法安全替换，放弃该词条
    if (zhParts.length != enParts.length) return null;

    final buffer = StringBuffer();
    var literalLength = 0;
    for (final part in zhParts) {
      if (part == _ph) {
        buffer.write('(.*?)');
      } else {
        literalLength += part.length;
        buffer.write(RegExp.escape(part));
      }
    }
    // 完全没有固定字面量的规则（如 "${x ?? '中文'}"）会退化成匹配任意串的 (.*?)，
    // 既翻译不出内容，又会遮蔽其他规则 —— 直接丢弃
    if (literalLength == 0) return null;

    try {
      return _TemplateRule(
        RegExp('^${buffer.toString()}\$', dotAll: true),
        enParts,
        literalLength,
      );
    } catch (_) {
      return null;
    }
  }

  String? apply(String source) {
    final match = pattern.firstMatch(source);
    if (match == null) return null;
    final buffer = StringBuffer();
    var groupIndex = 1;
    for (final part in enParts) {
      if (part == _ph) {
        buffer.write(match.group(groupIndex) ?? '');
        groupIndex++;
      } else {
        buffer.write(part);
      }
    }
    return buffer.toString();
  }
}

/// 按插值占位符切分，占位符位置统一替换为哨兵字符
List<String> _splitByInterp(String source) {
  final parts = <String>[];
  source.splitMapJoin(
    _interpPattern,
    onMatch: (_) {
      parts.add(_ph);
      return '';
    },
    onNonMatch: (s) {
      parts.add(s);
      return '';
    },
  );
  return parts;
}

/// 词条表（scripts/gen_i18n_dict.py 生成，勿手改）
const Map<String, String> _enMap = <String, String>{
'''


# 手工兜底词条：构建期生成的写法（如 '周${['一',...][weekday-1]}'）在运行时
# 得到的是 '周一' 这类完整串，必须靠精确词条才能翻对；批量翻译容易漏掉这类。
MANUAL: dict[str, str] = {
    '周一': 'Mon', '周二': 'Tue', '周三': 'Wed', '周四': 'Thu',
    '周五': 'Fri', '周六': 'Sat', '周日': 'Sun',
    '星期一': 'Monday', '星期二': 'Tuesday', '星期三': 'Wednesday',
    '星期四': 'Thursday', '星期五': 'Friday', '星期六': 'Saturday',
    '星期日': 'Sunday', '星期天': 'Sunday',
    '小红书': 'Xiaohongshu', '抖音': 'Douyin',
    # 设置页新增的语言区块（词典批量生成之后才加的文案）
    '语言': 'Language',
    '简体中文': 'Simplified Chinese',
    '版本 1.0.0': 'Version 1.0.0',
    # 品牌名统一：批量翻译把「微信」留成了中文
    '微信/QQ/复制': 'WeChat / QQ / Copy',
    '微信群': 'WeChat Group',
    # 英文里不应保留中文直角引号「」
    "添加「${ex['name']}」到计划": 'Add "${ex[\'name\']}" to Plan',
    '点击上方「+ 训练日」开始添加，或选择训练类型使用模板快速生成':
        'Tap "+ Training Day" above to start adding, or pick a training type to '
        'generate one quickly from a template',
    "确定要删除「${card['name']}」吗？删除后无法恢复。":
        'Are you sure you want to delete "${card[\'name\']}"? '
        'This cannot be undone.',
}


# 批量翻译里残留的中文品牌名 / 专有名词，统一替换（作用于所有译文）
EN_POST_REPLACE: dict[str, str] = {
    '薄荷健康': 'Bohe Health',
}


def dart_escape(s: str) -> str:
    s = s.replace('\\', '\\\\')
    s = s.replace("'", "\\'")
    s = s.replace('$', r'\$')
    s = s.replace('\r', r'\r')
    s = s.replace('\n', r'\n')
    s = s.replace('\t', r'\t')
    return s


def dart_unescape(s: str) -> str:
    """把 Dart 字面量里的转义还原成运行时的真实字符，保证 key 与实际传入值一致。"""
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nxt = s[i + 1]
            mapping = {'n': '\n', 't': '\t', 'r': '\r', "'": "'", '"': '"',
                       '\\': '\\', '$': '$', '0': '\0'}
            out.append(mapping.get(nxt, '\\' + nxt))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return ''.join(out)


def main() -> None:
    if not os.path.isdir(BATCH_DIR):
        sys.exit(f'no batch dir: {BATCH_DIR}')

    merged: dict[str, str] = {}
    dup = 0
    for path in sorted(glob.glob(os.path.join(BATCH_DIR, 'out_*.json'))):
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        if not isinstance(data, dict):
            sys.exit(f'{path} is not a JSON object')
        for k, v in data.items():
            if k in merged:
                dup += 1
            merged[k] = v
        print(f'  {os.path.basename(path)}: {len(data)}')

    # 还原转义，使 key 与运行时传入的字符串一致
    merged = {dart_unescape(k): dart_unescape(v) for k, v in merged.items()}
    merged.update(MANUAL)

    # 对全部译文做统一替换（品牌名等批量翻译容易漏掉的中文）
    for zh_key, en_val in list(merged.items()):
        fixed = en_val
        for src, dst in EN_POST_REPLACE.items():
            fixed = fixed.replace(src, dst)
        if fixed != en_val:
            merged[zh_key] = fixed

    # ── 校验 ──
    problems_ph, problems_ws, unchanged = [], [], []
    for zh, en in merged.items():
        if sorted(PLACEHOLDER.findall(zh)) != sorted(PLACEHOLDER.findall(en)):
            problems_ph.append((zh, en))
        if (zh != zh.strip()) and (
            len(zh) - len(zh.lstrip()) != len(en) - len(en.lstrip())
            or len(zh) - len(zh.rstrip()) != len(en) - len(en.rstrip())
        ):
            problems_ws.append((zh, en))
        if zh == en and re.search(r'[\u4e00-\u9fff]', zh):
            unchanged.append(zh)

    covered = 0
    missing = []
    if os.path.exists(STRINGS_JSON):
        with open(STRINGS_JSON, encoding='utf-8') as f:
            scanned = json.load(f)
        for k in scanned:
            if dart_unescape(k) in merged:
                covered += 1
            else:
                missing.append(k)
        print(f'\n覆盖率: {covered}/{len(scanned)}')

    print(f'合并词条: {len(merged)}  重复: {dup}')
    print(f'占位符不一致: {len(problems_ph)}')
    for zh, en in problems_ph[:10]:
        print(f'  ! {zh[:50]!r} -> {en[:50]!r}')
    print(f'首尾空格不一致: {len(problems_ws)}')
    for zh, en in problems_ws[:10]:
        print(f'  ! {zh[:50]!r} -> {en[:50]!r}')
    print(f'疑似未翻译: {len(unchanged)}')
    for zh in unchanged[:10]:
        print(f'  ? {zh[:50]!r}')

    # ── 写文件 ──
    # 占位符集合不一致的条目直接剔除：这类译文改动了插值内部的内容
    # （如 ${(v / 10000)} 被改成 ${(v / 1000)}、中文星期数组被换成英文数组），
    # 运行时模板规则会把原文求出的值塞进译文，导致显示错误，不如回落中文。
    dropped = {zh for zh, _ in problems_ph}

    lines = [RUNTIME]
    kept = 0
    for zh, en in sorted(merged.items()):
        if not en or en == zh or zh in dropped:
            continue
        lines.append(f"  '{dart_escape(zh)}': '{dart_escape(en)}',\n")
        kept += 1
    lines.append('};\n')

    with open(OUT_FILE, 'w', encoding='utf-8', newline='\n') as f:
        f.write(''.join(lines))
    print(f'\nwritten: {OUT_FILE}')

    if missing:
        with open(os.path.join(ROOT, 'build', 'i18n', 'missing.json'), 'w',
                  encoding='utf-8') as f:
            json.dump(missing, f, ensure_ascii=False, indent=1)
        print(f'missing list -> build/i18n/missing.json ({len(missing)})')


if __name__ == '__main__':
    main()
