# 训练记录 UI 优化实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复训练详情页动作名称不显示的 bug，为动作卡片增加汇总信息与容量分析图表，并将记录列表卡片统计区改造为 2×2 网格。

**Architecture:** 仅修改两个页面文件（`record_detail_page.dart`、`records_page.dart`），不新建业务文件、不改数据层。动作名称反查在详情页内新增私有方法实现三级查找链；图表用项目已有的 fl_chart 依赖。每个任务以 widget 测试驱动。

**Tech Stack:** Flutter 3.7.12（Dart >=2.19.6 <3.0.0）、fl_chart 0.61.0、flutter_test + sqflite_common_ffi + shared_preferences mock。

**Spec:** `docs/superpowers/specs/2026-09-09-training-record-ui-design.md`（已获用户批准）

## Global Constraints

- SDK 约束 Dart >=2.19.6 <3.0.0，禁止使用 Dart 3 特有语法（records、pattern matching 等）
- 所有颜色必须取自 `LiftTrackColors` 主题扩展，禁止新增自定义颜色
- 不引新依赖：图表只用已有的 fl_chart 0.61.0
- 所有命令在 `d:\app\projects\health_training\fittrack_flutter` 目录下执行
- 不修改 `storage.dart`、`mock_data.dart` 等数据层文件
- 代码注释使用中文

---

### Task 1: 详情页动作名称三级反查（bug 修复）

**Files:**
- Modify: `fittrack_flutter/lib/pages/record_detail_page.dart`（L116-L123 反查逻辑、L213-L217 fallback）
- Test: `fittrack_flutter/test/record_detail_page_test.dart`（新建）

**Interfaces:**
- Consumes: `Storage.getCustomExercises()`、`Storage.getPlans()`、`MockData.exercises`（均已存在）
- Produces: 私有方法 `Map<String, String> _buildExerciseNameLookup()`（后续 Task 2/3 的代码与它共存于同一文件，但只在本任务定义一次）

**背景：** 当前 `record_detail_page.dart` L116-L123 只从 `MockData.exercises`（内置 e1~e21）反查动作名，自定义动作（id 形如 `customex_xxx`）查不到，卡片头部直接显示原始 id。本任务建立三级反查链：自定义动作库 → 计划内嵌动作 → 内置动作，全部未命中显示「未知动作」。

- [ ] **Step 1: 写失败测试**

新建 `fittrack_flutter/test/record_detail_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/pages/record_detail_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.getTheme('vitality-sport'),
      home: child,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.savePlansAsync([]);
    await Storage.saveRecordsAsync([]);
    await Storage.getPlansAsync();
    await Storage.getRecordsAsync();
  });

  testWidgets('详情页显示自定义动作名称而非动作id', (tester) async {
    final custom = Storage.addCustomExercise({
      'name': '我的自定义动作',
      'category': '胸部',
      'equip': '哑铃',
    });
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 240,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        custom['id']: [
          {'weight': 30, 'reps': 4, 'rest': 90},
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('我的自定义动作'), findsOneWidget);
    expect(find.text('未知动作'), findsNothing);
  });

  testWidgets('id不在任何动作来源中时显示未知动作', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 1,
      'totalWeight': 120,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'nonexistent_id': [
          {'weight': 120, 'reps': 1, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('未知动作'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/record_detail_page_test.dart`
Expected: FAIL —— 第一个测试找不到「我的自定义动作」（页面显示的是原始 id `customex_xxx`），第二个测试找不到「未知动作」（页面显示的是 `nonexistent_id`）。

- [ ] **Step 3: 实现三级反查**

修改 `fittrack_flutter/lib/pages/record_detail_page.dart`。

3a. 将 L116-L123 的反查逻辑：

```dart
    // setRecords 的 key 是动作 id，需要解析成动作名展示
    final exLookup = <String, String>{};
    for (final ex in MockData.exercises) {
      exLookup[ex['id'] as String] = ex['name'] as String;
    }
    final exerciseNames = setRecords.keys
        .map((k) => exLookup[k.toString()] ?? k.toString())
        .toList();
```

替换为：

```dart
    // setRecords 的 key 是动作 id，需要解析成动作名展示
    final exLookup = _buildExerciseNameLookup();
    final exerciseNames = setRecords.keys
        .map((k) => exLookup[k.toString()] ?? '未知动作')
        .toList();
```

3b. 在 `_formatDuration` 方法之后新增方法：

```dart
  /// 三级反查动作名：自定义动作库 → 计划内嵌动作 → 内置动作
  Map<String, String> _buildExerciseNameLookup() {
    final lookup = <String, String>{};
    for (final ex in Storage.getCustomExercises()) {
      final id = ex['id']?.toString() ?? '';
      final name = ex['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
    }
    for (final plan in Storage.getPlans()) {
      final days = plan['days'] as List? ?? [];
      for (final day in days) {
        final exercises = (day as Map)['exercises'] as List? ?? [];
        for (final ex in exercises) {
          final id = ex['id']?.toString() ?? '';
          final name = ex['name']?.toString() ?? '';
          if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
        }
      }
    }
    for (final ex in MockData.exercises) {
      final id = ex['id']?.toString() ?? '';
      final name = ex['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
    }
    return lookup;
  }
```

3c. 将动作列表渲染处的 fallback（原 L213-L217）：

```dart
              ...setRecords.entries.map((entry) {
                final exId = entry.key.toString();
                final exName = exLookup[exId] ?? exId;
                return _buildExerciseDetailCard(colors, exName, entry.value);
              }),
```

替换为：

```dart
              ...setRecords.entries.map((entry) {
                final exId = entry.key.toString();
                final exName = exLookup[exId] ?? '未知动作';
                return _buildExerciseDetailCard(colors, exName, entry.value);
              }),
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/record_detail_page_test.dart`
Expected: PASS（2 个测试全绿）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/record_detail_page.dart fittrack_flutter/test/record_detail_page_test.dart
git commit -m "fix: 训练详情页动作名称三级反查修复自定义动作显示原始id的问题"
```

---

### Task 2: 详情页动作卡片新增汇总行

**Files:**
- Modify: `fittrack_flutter/lib/pages/record_detail_page.dart`（`_buildExerciseDetailCard` 方法）
- Test: `fittrack_flutter/test/record_detail_page_test.dart`（追加测试）

**Interfaces:**
- Consumes: Task 1 的 `_buildExerciseNameLookup()`（已存在，无需改动）
- Produces: 私有方法 `String _fmtKg(double v)` —— **Task 3 的图表也依赖此方法，必须在本任务定义**；以及 `_buildSummaryStat`、`_buildSummaryDivider` 两个私有 widget 构建方法

**背景：** 动作卡片目前只有「N组」+ 逐组列表，没有汇总。在卡片头部与逐组列表之间插入三列汇总行：总容量（Σ 重量×次数）、最重组（最大重量×该组次数）、总次数（Σ 次数）。

- [ ] **Step 1: 写失败测试**

在 `test/record_detail_page_test.dart` 的 `main()` 内追加：

```dart
  testWidgets('动作卡片展示汇总信息', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 500,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
          {'weight': 35, 'reps': 2, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    // 总容量 30×4 + 35×2 = 190
    expect(find.text('190kg'), findsOneWidget);
    // 最重组 35kg×2
    expect(find.text('35kg×2'), findsOneWidget);
    // 总次数 4 + 2 = 6
    expect(find.text('6次'), findsOneWidget);
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/record_detail_page_test.dart --plain-name "动作卡片展示汇总信息"`
Expected: FAIL —— 找不到 `190kg` / `35kg×2` / `6次`（汇总行尚未实现）

- [ ] **Step 3: 实现汇总行**

修改 `fittrack_flutter/lib/pages/record_detail_page.dart` 的 `_buildExerciseDetailCard` 方法。

3a. 在 `sets` 解析循环之后（`if (setsData is List) {...}` 块结束后）追加汇总计算：

```dart
    // 汇总统计：总容量 / 最重组 / 总次数
    double totalVolume = 0;
    int totalReps = 0;
    double bestWeight = 0;
    int bestReps = 0;
    for (final s in sets) {
      final w = (s['weight'] as num?)?.toDouble() ?? 0;
      final r = (s['reps'] as num?)?.toInt() ?? 0;
      totalVolume += w * r;
      totalReps += r;
      if (w > bestWeight || (w == bestWeight && r > bestReps)) {
        bestWeight = w;
        bestReps = r;
      }
    }
```

3b. 在卡片头部 `Container`（含图标与动作名的那个）闭合的 `),` 之后、`if (sets.isNotEmpty)` 逐组列表之前，插入汇总行：

```dart
          if (sets.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: colors.borderColor.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  _buildSummaryStat(
                      colors, '总容量', '${_fmtKg(totalVolume)}kg'),
                  _buildSummaryDivider(colors),
                  _buildSummaryStat(
                      colors, '最重组', '${_fmtKg(bestWeight)}kg×$bestReps'),
                  _buildSummaryDivider(colors),
                  _buildSummaryStat(colors, '总次数', '$totalReps次'),
                ],
              ),
            ),
```

3c. 在 `_RecordDetailPageState` 类内（`_buildExerciseDetailCard` 方法之后）新增三个方法：

```dart
  /// 数值格式化：整数不带小数点，小数保留 1 位
  String _fmtKg(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildSummaryStat(
      LiftTrackColors colors, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider(LiftTrackColors colors) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.borderColor.withOpacity(0.6),
    );
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/record_detail_page_test.dart`
Expected: PASS（3 个测试全绿）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/record_detail_page.dart fittrack_flutter/test/record_detail_page_test.dart
git commit -m "feat: 训练详情页动作卡片新增总容量/最重组/总次数汇总行"
```

---

### Task 3: 详情页容量分析图表卡片

**Files:**
- Modify: `fittrack_flutter/lib/pages/record_detail_page.dart`（新增 fl_chart import、容量数据计算、图表卡片构建方法、插入位置）
- Test: `fittrack_flutter/test/record_detail_page_test.dart`（追加测试）

**Interfaces:**
- Consumes: Task 1 的 `exLookup` 与「未知动作」fallback；Task 2 的 `_fmtKg(double)`
- Produces: 私有方法 `Widget _buildVolumeChartCard(LiftTrackColors colors, List<Map<String, dynamic>> data)`；build() 内局部变量 `volumeData`

**背景：** 在概要卡片之后、训练动作列表之前插入「容量分析」柱状图卡片（fl_chart BarChart，复用 `gym_card_stats_page.dart` 的使用模式）。数据为各动作总容量（Σ weight×reps）；≤1 个有数据的动作或无数据时隐藏整卡。fl_chart 0.61 不支持柱顶数值标签，用 Y 轴刻度 + 点击 tooltip 替代。

- [ ] **Step 1: 写失败测试**

在 `test/record_detail_page_test.dart` 的 `main()` 内追加：

```dart
  testWidgets('多动作记录显示容量分析图表卡片', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 220,
      'exerciseCount': 2,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
        'e2': [
          {'weight': 20, 'reps': 5, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('容量分析'), findsOneWidget);
    // 30×4 + 20×5 = 220
    expect(find.text('合计 220kg'), findsOneWidget);
  });

  testWidgets('单动作记录不显示容量分析图表卡片', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 1,
      'totalWeight': 120,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('容量分析'), findsNothing);
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/record_detail_page_test.dart`
Expected: FAIL —— 第一个测试找不到「容量分析」（图表卡片尚未实现）；第二个测试会 PASS（当前本来就没有图表），以第一个测试的失败为准。

- [ ] **Step 3: 实现图表卡片**

修改 `fittrack_flutter/lib/pages/record_detail_page.dart`。

3a. 文件顶部 import 区新增：

```dart
import 'package:fl_chart/fl_chart.dart';
```

3b. build() 内，`exerciseNames` 赋值之后追加容量数据计算：

```dart
    // 容量分析数据（仅含有实际组数的动作）
    final volumeData = <Map<String, dynamic>>[];
    for (final entry in setRecords.entries) {
      final setsList = entry.value as List? ?? [];
      if (setsList.isEmpty) continue;
      double vol = 0;
      for (final s in setsList) {
        if (s is Map) {
          vol += ((s['weight'] as num?) ?? 0).toDouble() *
              ((s['reps'] as num?) ?? 0).toDouble();
        }
      }
      volumeData.add({
        'name': exLookup[entry.key.toString()] ?? '未知动作',
        'volume': vol,
      });
    }
```

3c. 在训练概要卡片的 `Container` 闭合 `),` 之后、`// 动作详情列表` 注释之前插入：

```dart
            // 容量分析图表
            if (volumeData.length > 1) ...[
              const SizedBox(height: 20),
              _buildVolumeChartCard(colors, volumeData),
            ],
```

3d. 在 `_RecordDetailPageState` 类内（`_buildSummaryDivider` 方法之后）新增：

```dart
  Widget _buildVolumeChartCard(
      LiftTrackColors colors, List<Map<String, dynamic>> data) {
    final totalVolume = data.fold<double>(
        0, (sum, e) => sum + ((e['volume'] as num?) ?? 0).toDouble());
    final maxVol = data
        .map((e) => ((e['volume'] as num?) ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: ((data[i]['volume'] as num?) ?? 0).toDouble(),
            color: colors.accentGlow,
            width: 18,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: '容量分析')),
              Text(
                '合计 ${_fmtKg(totalVolume)}kg',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVol <= 0 ? 1 : maxVol * 1.15,
              minY: 0,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: colors.borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIdx, rod, rodIdx) =>
                      BarTooltipItem(
                    '${data[groupIdx]['name']}\n${_fmtKg(rod.toY)}kg',
                    TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxVol > 0 ? maxVol / 3 : 1,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _fmtKg(v),
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final name = data[idx]['name'].toString();
                      final label =
                          name.length > 4 ? '${name.substring(0, 4)}…' : name;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/record_detail_page_test.dart`
Expected: PASS（5 个测试全绿）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/record_detail_page.dart fittrack_flutter/test/record_detail_page_test.dart
git commit -m "feat: 训练详情页新增各动作总容量柱状图卡片"
```

---

### Task 4: 记录列表卡片 2×2 统计网格

**Files:**
- Modify: `fittrack_flutter/lib/pages/records_page.dart`（`_buildRecordCard` 方法及 `_buildStatItem` → 新方法）
- Test: `fittrack_flutter/test/records_page_test.dart`（新建）

**Interfaces:**
- Consumes: 无（仅页面内部重构）
- Produces: 私有方法 `_buildStatsGrid`、`_buildStatCell`、`_buildGridDivider`（替换原 `_buildStatItem`，后者删除）

**背景：** 列表卡片统计区当前是 3 个 stat 挤一行。改为 2×2 网格（时长/组数/重量/动作数，动作数为新增），每格 icon+数值+label，浅色分隔线；删除底部「查看详情」提示行，标题行右侧加 chevron。

- [ ] **Step 1: 写失败测试**

新建 `fittrack_flutter/test/records_page_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/pages/records_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.savePlansAsync([]);
    await Storage.saveRecordsAsync([]);
    await Storage.getPlansAsync();
    await Storage.getRecordsAsync();
  });

  testWidgets('记录卡片以2x2网格展示四个统计项且无查看详情提示', (tester) async {
    Storage.addRecord({
      'name': '胸部训练',
      'planName': '三分化计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 45,
      'totalSets': 12,
      'totalWeight': 2400,
      'exerciseCount': 4,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 60, 'reps': 10, 'rest': 90},
        ],
        'e2': [
          {'weight': 20, 'reps': 12, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.getTheme('vitality-sport'),
      home: const RecordsPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('时长'), findsOneWidget);
    expect(find.text('组数'), findsOneWidget);
    expect(find.text('重量'), findsOneWidget);
    expect(find.text('动作数'), findsOneWidget);
    expect(find.text('查看详情'), findsNothing);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/records_page_test.dart`
Expected: FAIL —— `expect(find.text('动作数'), findsOneWidget)` 失败（当前只有 3 个统计项且无动作数）

- [ ] **Step 3: 实现 2×2 网格**

修改 `fittrack_flutter/lib/pages/records_page.dart` 的 `_buildRecordCard` 方法。

3a. 方法开头（`final muscles = ...` 之后）追加：

```dart
    final setRecords = record['setRecords'] as Map? ?? {};
    final exerciseCount = record['exerciseCount'] as int? ?? setRecords.length;
```

3b. 标题行 Row 中删除图标之后加 chevron，将：

```dart
              GestureDetector(
                onTap: () => _deleteRecord(recordId),
                child: Icon(Icons.delete_outline,
                    size: 20, color: colors.textMuted),
              ),
```

替换为：

```dart
              GestureDetector(
                onTap: () => _deleteRecord(recordId),
                child: Icon(Icons.delete_outline,
                    size: 20, color: colors.textMuted),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
```

3c. 将统计 Row 及「查看详情」块（从 `const SizedBox(height: 10),` 到「查看详情」`Center` 块结束）：

```dart
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatItem(colors, Icons.timer_outlined,
                  _formatDuration(record['duration']), '时长'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.fitness_center,
                  '${record['totalSets'] ?? 0}', '组数'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.monitor_weight_outlined,
                  '${record['totalWeight'] ?? 0}kg', '重量'),
            ],
          ),
          const SizedBox(height: 6),
          // 点击查看详情提示
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '查看详情',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: colors.accentGlow),
              ],
            ),
          ),
```

替换为：

```dart
          const SizedBox(height: 10),
          _buildStatsGrid(colors, record, exerciseCount),
```

3d. 将原 `_buildStatItem` 方法整体删除，替换为以下三个方法：

```dart
  Widget _buildStatsGrid(
      LiftTrackColors colors, Map<String, dynamic> record, int exerciseCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgSecondary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCell(colors, Icons.timer_outlined,
                  _formatDuration(record['duration']), '时长'),
              _buildGridDivider(colors),
              _buildStatCell(colors, Icons.fitness_center,
                  '${record['totalSets'] ?? 0}', '组数'),
            ],
          ),
          Container(height: 1, color: colors.borderColor.withOpacity(0.6)),
          Row(
            children: [
              _buildStatCell(colors, Icons.monitor_weight_outlined,
                  '${record['totalWeight'] ?? 0}kg', '重量'),
              _buildGridDivider(colors),
              _buildStatCell(colors, Icons.sports_gymnastics,
                  '$exerciseCount', '动作数'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
      LiftTrackColors colors, IconData icon, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accentGlow),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(label,
                    style:
                        TextStyle(color: colors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDivider(LiftTrackColors colors) {
    return Container(
      width: 1,
      height: 36,
      color: colors.borderColor.withOpacity(0.6),
    );
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/records_page_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/pages/records_page.dart fittrack_flutter/test/records_page_test.dart
git commit -m "feat: 训练记录卡片统计区改造为2x2网格并新增动作数统计"
```

---

### Task 5: 全量回归验证

**Files:**
- 无代码修改，仅验证

**Interfaces:**
- Consumes: Task 1-4 的全部产物
- Produces: 验证结论

- [ ] **Step 1: 静态分析**

Run: `flutter analyze`
Expected: No issues found（或至少无本次改动引入的新告警）

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: All tests passed（原有测试 + 新增 6 个测试全部通过）

- [ ] **Step 3: 手动验证（有模拟器环境时执行）**

- 用含自定义动作的计划完成一次训练 → 训练记录详情页动作卡片显示动作名（非 `customex_xxx` 原始 id）
- 详情页可见「容量分析」图表卡片（≥2 个动作时）、动作卡片头部下方三列汇总行
- 记录列表卡片为 2×2 统计网格，无「查看详情」底部提示
- 切换其他主题（如 硬核铁馆/黑金尊享）验证颜色全部来自主题色

- [ ] **Step 4: 提交（如有遗留未提交文件）**

```bash
git status
```

Expected: working tree clean（Task 1-4 已分别提交）
