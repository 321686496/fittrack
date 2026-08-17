# 系统训练计划自动填充重量 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用户采用系统训练计划时，App 根据身体信息（体重/性别/训练水平）自动估算每个动作的建议重量（有训练历史则优先用历史重量），经确认页确认/修改后随计划持久化，训练时自动预填。

**Architecture:** 新增独立 `WeightRecommendationService`（动作分类 + 估算公式 + 历史匹配），新增 `plan_weight_confirm_page.dart` 确认页，`SystemPlan.toStoragePlan` 增加重量注入参数，`_adoptPlan` 改为先跳确认页再保存。系统计划 JSON 数据无需改动。

**Tech Stack:** Flutter 3.7.12 / Dart 2.19（**必须兼容 Dart 2.19，禁止使用 Dart 3 语法**）、go_router、Storage（SharedPreferences + SQLite）。

## Global Constraints

- Dart >=2.19.6 <3.0.0，Flutter 3.7.12。禁止 Dart 3 语法（records、switch 表达式、patterns、`...?` null-aware spread 等）
- 代码注释使用中文
- 遵循项目现有模式：服务单例（如 `PlanRecommendationService.instance`）、Storage 静态方法访问
- 训练水平存储值：`新手/初级/中级/高级`（settings['fitnessLevel']）
- 性别存储值：`男/女`（bodyData['gender']）
- 重量取整到 2.5kg，下限 2.5kg；复合动作上限 150kg、孤立动作上限 50kg
- 身体数据缺失（体重 ≤ 0）时用默认 65kg 估算
- 历史匹配：records 缓存最新在前（`addRecord` 用 `insert(0, ...)`）；记录 `setRecords` 的 key 是动作 id，需通过 `record['planId']` → `Storage.getPlanById(planId)` 解析出动作名
- 仓库工作区存在无关未提交改动（`lib/services/daily_reminder_service.dart`、`lib/utils/platform_utils.dart`）——**不要提交这两个文件，也不要在它们上做任何改动**
- 每次 commit 只 `git add` 本任务涉及的具体文件
- 文件使用 LF/CRLF 均可（仓库已配置自动转换），提交时若出现 LF→CRLF 警告属正常

---

### Task 1: WeightRecommendationService — 动作分类与估算（纯函数）

**Files:**
- Create: `lib/services/weight_recommendation_service.dart`
- Test: `test/weight_recommendation_service_test.dart`

**Interfaces:**
- Produces（后续任务依赖的公共 API）：
  - `enum ExerciseCategory { compoundPush, compoundPull, compoundLeg, isolationUpper, isolationLower, bodyweight }`
  - `enum WeightSource { history, estimate, bodyweight }`
  - `class ExerciseWeightSuggestion { final double? weight; final WeightSource source; const ExerciseWeightSuggestion({this.weight, required this.source}); }`
  - `ExerciseCategory classifyExercise(String name)` — 按关键词分类（命中顺序：自重/有氧 → 复合下肢 → 复合上肢推 → 复合上肢拉 → 孤立下肢 → 孤立上肢；未命中回退 `isolationUpper`）
  - `double estimateWeight({required double bodyWeight, required ExerciseCategory category, required String fitnessLevel, required String gender})` — 估算公式 + 取整 + 上下限
  - `class WeightRecommendationService { static final WeightRecommendationService instance = WeightRecommendationService._(); ... }`（Task 2 在其中追加 `recommendForSystemPlan`）

- [ ] **Step 1: 写失败测试**

创建 `test/weight_recommendation_service_test.dart`：

```dart
// 系统训练计划自动填充重量：动作分类与估算测试
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/services/weight_recommendation_service.dart';

void main() {
  group('classifyExercise', () {
    test('复合动作分类正确', () {
      expect(classifyExercise('杠铃卧推'), ExerciseCategory.compoundPush);
      expect(classifyExercise('杠铃卧推（5×5）'), ExerciseCategory.compoundPush);
      expect(classifyExercise('哑铃推举'), ExerciseCategory.compoundPush);
      expect(classifyExercise('双杠臂屈伸'), ExerciseCategory.compoundPush);
      expect(classifyExercise('高位下拉'), ExerciseCategory.compoundPull);
      expect(classifyExercise('坐姿划船'), ExerciseCategory.compoundPull);
      expect(classifyExercise('杠铃划船'), ExerciseCategory.compoundPull);
      expect(classifyExercise('直臂下压'), ExerciseCategory.compoundPull);
      expect(classifyExercise('深蹲'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('硬拉'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('腿举'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('箭步蹲'), ExerciseCategory.compoundLeg);
    });

    test('孤立动作分类正确', () {
      expect(classifyExercise('哑铃飞鸟'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('哑铃弯举'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('三头肌下压'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('侧平举'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('腿弯举'), ExerciseCategory.isolationLower);
      expect(classifyExercise('腿屈伸'), ExerciseCategory.isolationLower);
      expect(classifyExercise('提踵'), ExerciseCategory.isolationLower);
      expect(classifyExercise('臀桥'), ExerciseCategory.isolationLower);
    });

    test('自重/有氧动作分类正确', () {
      expect(classifyExercise('俯卧撑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('引体向上'), ExerciseCategory.bodyweight);
      expect(classifyExercise('卷腹'), ExerciseCategory.bodyweight);
      expect(classifyExercise('平板支撑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('波比跳'), ExerciseCategory.bodyweight);
      expect(classifyExercise('慢跑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('自重深蹲'), ExerciseCategory.bodyweight);
    });

    test('未命中回退孤立上肢', () {
      expect(classifyExercise('某未知动作'), ExerciseCategory.isolationUpper);
    });
  });

  group('estimateWeight', () {
    test('公式与取整：65kg 新手男性复合推', () {
      // 65 * 0.45 * 1.0 * 1.0 = 29.25 → 取整到 2.5 → 30.0
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '新手',
        gender: '男',
      ), 30.0);
    });

    test('性别系数：女性 0.70', () {
      // 65 * 0.70 * 1.0 * 0.70 = 31.85 → 32.5
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundLeg,
        fitnessLevel: '新手',
        gender: '女',
      ), 32.5);
    });

    test('水平系数：高级 1.45', () {
      // 65 * 0.45 * 1.45 * 1.0 = 42.41 → 42.5
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '高级',
        gender: '男',
      ), 42.5);
    });

    test('下限 2.5kg', () {
      expect(estimateWeight(
        bodyWeight: 20,
        category: ExerciseCategory.isolationUpper,
        fitnessLevel: '新手',
        gender: '男',
      ), 2.5);
    });

    test('孤立动作上限 50kg，复合动作上限 150kg', () {
      expect(estimateWeight(
        bodyWeight: 500,
        category: ExerciseCategory.isolationUpper,
        fitnessLevel: '高级',
        gender: '男',
      ), 50.0);
      expect(estimateWeight(
        bodyWeight: 500,
        category: ExerciseCategory.compoundLeg,
        fitnessLevel: '高级',
        gender: '男',
      ), 150.0);
    });

    test('未知水平/性别按 1.0 处理', () {
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '未知',
        gender: '未知',
      ), 30.0);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: FAIL，报错 "classifyExercise" 未定义。

- [ ] **Step 3: 写最小实现**

创建 `lib/services/weight_recommendation_service.dart`：

```dart
// lib/services/weight_recommendation_service.dart
// 系统训练计划自动填充重量：动作分类 + 估算公式 + 历史匹配

enum ExerciseCategory {
  compoundPush, // 复合上肢推
  compoundPull, // 复合上肢拉
  compoundLeg, // 复合下肢
  isolationUpper, // 孤立上肢
  isolationLower, // 孤立下肢
  bodyweight, // 自重/有氧（不填重量）
}

enum WeightSource {
  history, // 历史记录
  estimate, // 估算
  bodyweight, // 自重
}

class ExerciseWeightSuggestion {
  final double? weight; // 自重动作为 null
  final WeightSource source;

  const ExerciseWeightSuggestion({this.weight, required this.source});
}

// ── 类别基础占比（入门男性，体重百分比）──
const Map<ExerciseCategory, double> _categoryRatio = {
  ExerciseCategory.compoundPush: 0.45,
  ExerciseCategory.compoundPull: 0.40,
  ExerciseCategory.compoundLeg: 0.70,
  ExerciseCategory.isolationUpper: 0.12,
  ExerciseCategory.isolationLower: 0.15,
  ExerciseCategory.bodyweight: 0.0,
};

// ── 水平系数（settings['fitnessLevel'] 实际值）──
const Map<String, double> _levelMultiplier = {
  '新手': 1.0,
  '初级': 1.15,
  '中级': 1.30,
  '高级': 1.45,
};

const double _defaultBodyWeight = 65.0; // 身体数据缺失时的默认体重
const double _minWeight = 2.5;
const double _compoundMax = 150.0;
const double _isolationMax = 50.0;

/// 动作分类：按关键词命中顺序判断（自重/有氧 → 复合下肢 → 复合上肢推 → 复合上肢拉 → 孤立下肢 → 孤立上肢）
ExerciseCategory classifyExercise(String name) {
  final n = name.replaceAll(RegExp(r'\s+'), '');
  // 自重/有氧（优先，避免“自重深蹲”误入复合下肢等）
  const bodyweightKeywords = [
    '自重深蹲', '俯卧撑', '引体向上', '卷腹', '平板支撑', '波比跳', '俄罗斯转体',
    '悬垂举腿', '仰卧举腿', '开合跳', '高抬腿', '登山跑', '鸟狗式', '死虫式',
    '深蹲跳', '箭步跳', '慢跑', '游泳', '动感单车', '椭圆机', '战绳', '农夫行走',
    '跳箱', '药球',
  ];
  for (final k in bodyweightKeywords) {
    if (n.contains(k)) return ExerciseCategory.bodyweight;
  }
  // 复合下肢
  const legKeywords = ['前蹲', '深蹲', '硬拉', '腿举', '箭步蹲', '弓步蹲', '保加利亚分腿蹲', '壶铃摆动', '力量翻', '箱式深蹲'];
  for (final k in legKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundLeg;
  }
  // 复合上肢推
  const pushKeywords = ['卧推', '推举', '实力举', '双杠臂屈伸', '阿诺德'];
  for (final k in pushKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundPush;
  }
  // 复合上肢拉（“直臂下压”用全称，避免误吞孤立“三头肌下压”）
  const pullKeywords = ['下拉', '划船', '直臂下压'];
  for (final k in pullKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundPull;
  }
  // 孤立下肢（“腿弯举”需在孤立上肢“弯举”之前判断）
  const isoLegKeywords = ['腿弯举', '腿屈伸', '提踵', '臀桥', '山羊挺身'];
  for (final k in isoLegKeywords) {
    if (n.contains(k)) return ExerciseCategory.isolationLower;
  }
  // 孤立上肢（未命中默认归入此类）
  const isoUpperKeywords = ['下压', '夹胸', '飞鸟', '平举', '面拉', '弯举', '臂屈伸', '三头', '法式推举'];
  for (final k in isoUpperKeywords) {
    if (n.contains(k)) return ExerciseCategory.isolationUpper;
  }
  return ExerciseCategory.isolationUpper;
}

/// 估算建议重量：体重 × 类别占比 × 水平系数 × 性别系数，取整到 2.5kg，并施加上下限
double estimateWeight({
  required double bodyWeight,
  required ExerciseCategory category,
  required String fitnessLevel,
  required String gender,
}) {
  final ratio = _categoryRatio[category] ?? 0.12;
  final level = _levelMultiplier[fitnessLevel] ?? 1.0;
  final genderMultiplier = gender == '女' ? 0.70 : 1.0;
  var v = bodyWeight * ratio * level * genderMultiplier;
  // 取整到 2.5kg
  v = (v / 2.5).round() * 2.5;
  if (v < _minWeight) v = _minWeight;
  final maxW = (category == ExerciseCategory.compoundPush ||
          category == ExerciseCategory.compoundPull ||
          category == ExerciseCategory.compoundLeg)
      ? _compoundMax
      : _isolationMax;
  if (v > maxW) v = maxW;
  return v;
}

class WeightRecommendationService {
  WeightRecommendationService._();
  static final WeightRecommendationService instance =
      WeightRecommendationService._();
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: PASS，全部通过。

- [ ] **Step 5: 提交**

```bash
git add lib/services/weight_recommendation_service.dart test/weight_recommendation_service_test.dart
git commit -m "feat: 训练重量自动填充服务（动作分类与估算公式）"
```

---

### Task 2: WeightRecommendationService — 历史匹配与计划级编排

**Files:**
- Modify: `lib/services/weight_recommendation_service.dart`（在类内追加方法）
- Test: `test/weight_recommendation_service_test.dart`（追加测试）

**Interfaces:**
- Consumes（Task 1）：`classifyExercise`、`estimateWeight`、`ExerciseCategory`、`WeightSource`、`ExerciseWeightSuggestion`
- Produces：
  - `Map<String, ExerciseWeightSuggestion> recommendForSystemPlan(SystemPlan plan, {List<Map<String, dynamic>>? records, Map<String, dynamic>? bodyData, Map<String, dynamic>? settings})` — 返回 `Map<动作id, 建议>`；参数缺省时从 `Storage` 读取（records/bodyData/settings）
  - 私有 `double? _historyWeight(String exerciseName, List<Map<String, dynamic>> records)`

- [ ] **Step 1: 追加失败测试**

在 `test/weight_recommendation_service_test.dart` 末尾追加：

```dart
group('recommendForSystemPlan', () {
  test('无历史时按身体信息估算，来源为 estimate', () {
    final service = WeightRecommendationService.instance;
    final plan = _buildPlan([
      _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
    ]);
    final result = service.recommendForSystemPlan(
      plan,
      records: [],
      bodyData: {'height': 175, 'weight': 65},
      settings: {'fitnessLevel': '新手'},
    );
    final sug = result['ex_001']!;
    expect(sug.source, WeightSource.estimate);
    expect(sug.weight, 30.0); // 65*0.45=29.25 → 30
  });

  test('有历史记录时优先使用历史重量，来源为 history', () {
    final service = WeightRecommendationService.instance;
    final plan = _buildPlan([
      _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
    ]);
    // 模拟历史记录：planId 指向一个包含 ex_001(杠铃卧推, weight=60) 的旧计划
    final oldPlan = _buildUserPlan('user_old_1', [
      _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
    ]);
    final result = service.recommendForSystemPlan(
      plan,
      records: [
        {
          'planId': 'user_old_1',
          'setRecords': {
            'ex_001': [
              {'set': 1, 'weight': 60, 'reps': 10},
            ],
          },
        },
      ],
      bodyData: {'height': 175, 'weight': 65},
      settings: {'fitnessLevel': '新手'},
      userPlans: [oldPlan],
    );
    final sug = result['ex_001']!;
    expect(sug.source, WeightSource.history);
    expect(sug.weight, 60.0);
  });

  test('自重动作 weight 为 null，来源为 bodyweight', () {
    final service = WeightRecommendationService.instance;
    final plan = _buildPlan([
      _day(1, '腹部日', [_ex('ex_002', '卷腹', 3, 20)]),
    ]);
    final result = service.recommendForSystemPlan(
      plan,
      records: [],
      bodyData: {'height': 175, 'weight': 65},
      settings: {'fitnessLevel': '新手'},
    );
    final sug = result['ex_002']!;
    expect(sug.weight, isNull);
    expect(sug.source, WeightSource.bodyweight);
  });
});

// ── 测试辅助 ──────────────────────────────────────────────────
Map<String, dynamic> _ex(String id, String name, int sets, int reps) {
  return {'id': id, 'name': name, 'sets': sets, 'reps': reps, 'restTime': 90};
}

Map<String, dynamic> _day(int day, String label, List<Map<String, dynamic>> exercises) {
  return {'day': day, 'label': label, 'muscle': label, 'exercises': exercises};
}

SystemPlan _buildPlan(List<Map<String, dynamic>> days) {
  return SystemPlan(
    id: 'plan_test',
    name: '测试计划',
    goal: 'bulk',
    difficulty: 'beginner',
    trainingType: '3day_split',
    isPremium: false,
    pointsCost: 0,
    totalWeeks: 4,
    defaultRestTime: 90,
    description: '',
    coverEmoji: '💪',
    coverColors: const ['#FF6B6B', '#C44D4D'],
    tags: const [],
    recommendedFrequency: 3,
    suitableFor: '',
    days: days.map((d) => SystemPlanDay(
      day: d['day'] as int,
      label: d['label'] as String,
      muscle: d['muscle'] as String,
      exercises: (d['exercises'] as List)
          .map((e) => SystemPlanExercise(
                id: e['id'] as String,
                name: e['name'] as String,
                sets: e['sets'] as int,
                reps: e['reps'] as int,
                restTime: e['restTime'] as int,
              ))
          .toList(),
    )).toList(),
  );
}

Map<String, dynamic> _buildUserPlan(String id, List<Map<String, dynamic>> days) {
  return {
    'id': id,
    'name': '旧计划',
    'type': '3day_split',
    'frequency': 3,
    'difficulty': 'beginner',
    'totalWeeks': 4,
    'defaultRestTime': 90,
    'days': days,
    'status': 'paused',
  };
}
```

测试用到 `SystemPlan` / `SystemPlanDay` / `SystemPlanExercise`，需在测试文件顶部追加 import：

```dart
import 'package:fittrack_flutter/data/system_plan_library.dart';
```

**注意**：`recommendForSystemPlan` 增加 `userPlans` 可选参数用于注入用户计划（解析记录中 exId→name）。默认从 `Storage.getPlans()` 读取。设计上 `_historyWeight` 通过 `userPlans` 构建每个 planId 的 exId→name 映射。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: FAIL，报错 "recommendForSystemPlan" 未定义。

- [ ] **Step 3: 实现推荐编排与历史匹配**

在 `lib/services/weight_recommendation_service.dart` 顶部追加 imports，并在类内追加方法：

```dart
import '../data/storage.dart';
import '../data/system_plan_library.dart';
```

在 `WeightRecommendationService` 类内追加：

```dart
  /// 为系统计划中每个动作生成建议重量
  /// 参数缺省时从 Storage 读取；records/bodyData/settings/userPlans 可注入便于测试
  Map<String, ExerciseWeightSuggestion> recommendForSystemPlan(
    SystemPlan plan, {
    List<Map<String, dynamic>>? records,
    Map<String, dynamic>? bodyData,
    Map<String, dynamic>? settings,
    List<Map<String, dynamic>>? userPlans,
  }) {
    final r = records ?? Storage.getRecords();
    final bd = bodyData ?? Storage.getBodyData();
    final st = settings ?? Storage.getSettings();
    final ups = userPlans ?? Storage.getPlans();

    final bodyWeight =
        (bd['weight'] as num?)?.toDouble() ?? 0;
    final effectiveWeight = bodyWeight > 0 ? bodyWeight : _defaultBodyWeight;
    final fitnessLevel = (st['fitnessLevel'] as String?) ?? '';
    final gender = (bd['gender'] as String?) ?? '';

    final result = <String, ExerciseWeightSuggestion>{};
    for (final day in plan.days) {
      for (final ex in day.exercises) {
        final category = classifyExercise(ex.name);
        if (category == ExerciseCategory.bodyweight) {
          result[ex.id] =
              const ExerciseWeightSuggestion(source: WeightSource.bodyweight);
          continue;
        }
        final history = _historyWeight(ex.name, r, ups);
        if (history != null && history > 0) {
          result[ex.id] = ExerciseWeightSuggestion(
            weight: history,
            source: WeightSource.history,
          );
        } else {
          result[ex.id] = ExerciseWeightSuggestion(
            weight: estimateWeight(
              bodyWeight: effectiveWeight,
              category: category,
              fitnessLevel: fitnessLevel,
              gender: gender,
            ),
            source: WeightSource.estimate,
          );
        }
      }
    }
    return result;
  }

  /// 在训练记录中按动作名查找最近一次使用的重量
  /// records 最新在前；通过 userPlans 解析记录 setRecords 的 exId → name
  double? _historyWeight(
    String exerciseName,
    List<Map<String, dynamic>> records,
    List<Map<String, dynamic>> userPlans,
  ) {
    final nameByPlan = <String, Map<String, String>>{};
    for (final p in userPlans) {
      final pid = p['id']?.toString();
      if (pid == null) continue;
      final lookup = <String, String>{};
      final days = p['days'] as List?;
      if (days == null) continue;
      for (final d in days) {
        final exs = d['exercises'] as List? ?? [];
        for (final ex in exs) {
          final id = ex['id']?.toString();
          final name = ex['name']?.toString();
          if (id != null && name != null) lookup[id] = name;
        }
      }
      nameByPlan[pid] = lookup;
    }

    for (final record in records) {
      final planId = record['planId']?.toString();
      final lookup = planId != null ? nameByPlan[planId] : null;
      if (lookup == null) continue;
      final setRecords = record['setRecords'] as Map?;
      if (setRecords == null) continue;
      for (final entry in setRecords.entries) {
        final exId = entry.key.toString();
        if (lookup[exId] != exerciseName) continue;
        final sets = entry.value as List? ?? [];
        if (sets.isEmpty) continue;
        final lastSet = sets.last as Map;
        final w = (lastSet['weight'] as num?)?.toDouble() ?? 0;
        if (w > 0) return w;
      }
    }
    return null;
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/services/weight_recommendation_service.dart test/weight_recommendation_service_test.dart
git commit -m "feat: 训练重量自动填充服务（历史优先 + 计划级编排）"
```

---

### Task 3: SystemPlan.toStoragePlan 支持注入重量

**Files:**
- Modify: `lib/data/system_plan_library.dart:212-239`
- Test: `test/weight_recommendation_service_test.dart`（追加测试）

**Interfaces:**
- Produces：`Map<String, dynamic> toStoragePlan({Map<String, double>? weights})` — `weights` 为 `动作id → 重量(kg)`；只对非自重动作注入，注入后的动作 JSON 含 `weight` 字段

- [ ] **Step 1: 追加失败测试**

在 `test/weight_recommendation_service_test.dart` 末尾追加：

```dart
group('toStoragePlan 重量注入', () {
  test('注入重量后动作 JSON 含 weight，未注入动作不含', () {
    final plan = _buildPlan([
      _day(1, '胸部日', [
        _ex('ex_001', '杠铃卧推', 4, 10),
        _ex('ex_002', '卷腹', 3, 20),
      ]),
    ]);
    final storage = plan.toStoragePlan(weights: {'ex_001': 30.0});
    final days = storage['days'] as List;
    final exs = (days.first['exercises'] as List).cast<Map<String, dynamic>>();
    expect(exs[0]['weight'], 30.0);
    expect(exs[1].containsKey('weight'), isFalse);
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: FAIL，`toStoragePlan` 不接受 `weights` 命名参数。

- [ ] **Step 3: 修改 toStoragePlan**

编辑 `lib/data/system_plan_library.dart` 的 `toStoragePlan` 方法（212-239 行）：

```dart
  /// 转换为 Storage 中存储的 plan 格式（用于"采用此计划"时写入）
  /// [weights] 为 动作id → 重量(kg)，用于填充系统计划自动计算的建议重量
  Map<String, dynamic> toStoragePlan({Map<String, double>? weights}) {
    return {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}_${id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      'name': name,
      'type': trainingType,
      'frequency': recommendedFrequency,
      'difficulty': difficulty,
      'totalWeeks': totalWeeks,
      'defaultRestTime': defaultRestTime,
      'days': days
          .map((d) => {
                'day': d.day,
                'label': d.label,
                'muscle': d.muscle,
                'exercises': d.exercises.map((e) {
                  final w = weights?[e.id];
                  return w != null
                      ? {...e.toJson(), 'weight': w}
                      : e.toJson();
                }).toList(),
              })
          .toList(),
      'week': 1,
      'progress': 0,
      'status': 'active',
      'sourcePlanId': id,
      // SQLite 不支持 bool 类型，仅接受 num/String/Uint8List，存为 int (0/1)
      'isFromSystemLibrary': 1,
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/weight_recommendation_service_test.dart`
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/data/system_plan_library.dart test/weight_recommendation_service_test.dart
git commit -m "feat: toStoragePlan 支持注入建议重量"
```

---

### Task 4: 新增重量确认页

**Files:**
- Create: `lib/pages/plan_weight_confirm_page.dart`
- Modify: `lib/router.dart`（注册路由 `/plan-weight-confirm`）

**Interfaces:**
- Consumes（Task 1/2/3）：`WeightRecommendationService.instance.recommendForSystemPlan(plan)` → `Map<String, ExerciseWeightSuggestion>`；`SystemPlan`
- Produces：`class PlanWeightConfirmPage extends StatefulWidget { final SystemPlan plan; }`，确认后 `Navigator.pop(context, Map<String, double>)`（动作id → 最终重量）；用户返回键/取消时 pop `null`
- 复用现有 UI 约定：`LiftTrackColors`（`Theme.of(context).extension<LiftTrackColors>()`）、`PageHeader`、`FitToast`、`common_widgets.dart`

- [ ] **Step 1: 编写确认页代码**

创建 `lib/pages/plan_weight_confirm_page.dart`（页面本身不写测试——属于 UI 层，遵循仓库惯例）：

```dart
// lib/pages/plan_weight_confirm_page.dart
// 系统训练计划采用前的重量确认页：展示并允许修改每个动作的建议重量
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/system_plan_library.dart';
import '../services/weight_recommendation_service.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';

class PlanWeightConfirmPage extends StatefulWidget {
  final SystemPlan plan;
  const PlanWeightConfirmPage({super.key, required this.plan});

  @override
  State<PlanWeightConfirmPage> createState() => _PlanWeightConfirmPageState();
}

class _PlanWeightConfirmPageState extends State<PlanWeightConfirmPage> {
  late final Map<String, ExerciseWeightSuggestion> _suggestions;
  final Map<String, TextEditingController> _controllers = {};
  bool _bodyInfoMissing = false;

  @override
  void initState() {
    super.initState();
    _suggestions =
        WeightRecommendationService.instance.recommendForSystemPlan(widget.plan);
    final bodyData = Storage.getBodyData();
    final bodyWeight = (bodyData['weight'] as num?)?.toDouble() ?? 0;
    _bodyInfoMissing = bodyWeight <= 0;
    for (final day in widget.plan.days) {
      for (final ex in day.exercises) {
        final sug = _suggestions[ex.id];
        if (sug != null && sug.source != WeightSource.bodyweight) {
          final c = TextEditingController(
            text: sug.weight != null ? _fmt(sug.weight!) : '',
          );
          _controllers[ex.id] = c;
        }
      }
    }
  }

  static String _fmt(double w) =>
      w == w.roundToDouble() ? w.round().toString() : w.toString();

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    // 校验所有非自重动作重量非空且 > 0
    final weights = <String, double>{};
    String? firstEmptyId;
    for (final day in widget.plan.days) {
      for (final ex in day.exercises) {
        final sug = _suggestions[ex.id];
        if (sug == null || sug.source == WeightSource.bodyweight) continue;
        final c = _controllers[ex.id];
        if (c == null) continue;
        final v = double.tryParse(c.text.trim());
        if (v == null || v <= 0) {
          firstEmptyId ??= ex.id;
          continue;
        }
        weights[ex.id] = v;
      }
    }
    if (firstEmptyId != null) {
      FitToast.error(context, '请为每个动作填写有效重量');
      _focusId = firstEmptyId;
      setState(() {});
      return;
    }
    Navigator.of(context).pop(weights);
  }

  String? _focusId;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '确认建议重量',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_bodyInfoMissing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ft.warningColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: ft.warningColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '未检测到你的体重信息，按 65kg 估算，可修改下方重量',
                            style: TextStyle(color: ft.warningColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '${widget.plan.name} · ${widget.plan.days.length} 个训练日',
                  style: TextStyle(
                    color: ft.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                for (final day in widget.plan.days) _buildDayCard(day, ft),
              ],
            ),
          ),
          _buildBottomBar(ft),
        ],
      ),
    );
  }

  Widget _buildDayCard(SystemPlanDay day, LiftTrackColors ft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${day.day} 天 · ${day.label}',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final ex in day.exercises) _buildExerciseRow(ex, ft),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(SystemPlanExercise ex, LiftTrackColors ft) {
    final sug = _suggestions[ex.id];
    final isBodyweight = sug?.source == WeightSource.bodyweight;
    final controller = _controllers[ex.id];
    final invalid = _focusId == ex.id;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ft.borderColor.withOpacity(0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: TextStyle(color: ft.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.sets} 组 × ${ex.reps} 次',
                  style: TextStyle(color: ft.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isBodyweight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ft.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '自重',
                style: TextStyle(color: ft.textSecondary, fontSize: 12),
              ),
            )
          else ...[
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ft.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: 'kg',
                      suffixStyle:
                          TextStyle(color: ft.textSecondary, fontSize: 12),
                      hintText: '重量',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: invalid ? Colors.red : ft.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: invalid ? Colors.red : ft.borderColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sug?.source == WeightSource.history ? '历史记录' : '估算',
                    style: TextStyle(
                      color: sug?.source == WeightSource.history
                          ? ft.accentSecondary
                          : ft.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: ft.bgCard,
        border: Border(top: BorderSide(color: ft.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: ft.accentGlow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('确认并使用计划'),
          ),
        ),
      ),
    );
  }
}
```

**注意**：上面引用了 `Storage.getBodyData()` 和 `FitToast`，需在文件顶部追加 import：

```dart
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
```

本页用到的颜色 getter（已按 `lib/themes/app_themes.dart` 核对存在）：`ft.bgSecondary / ft.bgCard / ft.textPrimary / ft.textSecondary / ft.textMuted / ft.borderColor / ft.accentSecondary / ft.accentGlow / ft.warningColor`。全页不新增自定义颜色常量（遵循项目规则：页面颜色必须使用 app 主题色）。

- [ ] **Step 2: 注册路由**

编辑 `lib/router.dart`：
1. 在 import 区追加：`import 'pages/plan_weight_confirm_page.dart';`
2. 在 `/plan-library/:goal` 路由之后、`/plan-search` 之前追加：

```dart
      GoRoute(
        path: '/plan-weight-confirm',
        name: 'planWeightConfirm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlanWeightConfirmPage(
          plan: state.extra as SystemPlan,
        ),
      ),
```

并在文件顶部确认已 import `data/system_plan_library.dart`（若未 import 则追加）。

- [ ] **Step 3: 静态检查**

Run: `flutter analyze lib/pages/plan_weight_confirm_page.dart lib/router.dart`
Expected: No issues found（若有报错按提示修复）。

- [ ] **Step 4: 提交**

```bash
git add lib/pages/plan_weight_confirm_page.dart lib/router.dart
git commit -m "feat: 新增计划重量确认页并注册路由"
```

---

### Task 5: 采用流程接入确认页

**Files:**
- Modify: `lib/pages/plan_library_detail_page.dart:526-550`（`_adoptPlan`）

**Interfaces:**
- Consumes（Task 3/4）：`plan.toStoragePlan(weights: ...)`、`context.push<Map<String, double>>('/plan-weight-confirm', extra: plan)`

- [ ] **Step 1: 修改 _adoptPlan**

将 `lib/pages/plan_library_detail_page.dart` 的 `_adoptPlan`（526-550 行）替换为：

```dart
  Future<void> _adoptPlan(SystemPlan plan) async {
    try {
      // 先进入重量确认页，用户确认/修改后返回 动作id → 重量
      final weights =
          await context.push<Map<String, double>>('/plan-weight-confirm',
              extra: plan);
      if (!mounted) return;
      if (weights == null) return; // 用户取消

      // 暂停现有 active 计划（await 确保持久化完成）
      final existingPlans = Storage.getPlans();
      for (final p in existingPlans) {
        if (p['status'] == 'active') {
          await Storage.updatePlanAsync(
              p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
        }
      }
      // 添加新计划（携带确认后的建议重量）
      final newPlan = plan.toStoragePlan(weights: weights);
      await Storage.addPlanAsync(newPlan);
      Storage.dataChanged.value = !Storage.dataChanged.value;

      if (!mounted) return;
      // 保存成功后跳转首页并提示用户可以开始训练
      FitToast.success(context, '已采用计划：${plan.name}，开始训练吧！');
      context.go('/home');
    } catch (e) {
      debugPrint('采用计划失败: $e');
      if (!mounted) return;
      FitToast.error(context, '采用计划失败，请重试');
    }
  }
```

- [ ] **Step 2: 静态检查**

Run: `flutter analyze lib/pages/plan_library_detail_page.dart`
Expected: No issues found。

- [ ] **Step 3: 运行全量相关测试**

Run: `flutter test test/weight_recommendation_service_test.dart test/plan_adopt_bug_test.dart`
Expected: PASS（plan_adopt_bug_test 验证 toStoragePlan 兼容性不回退）。

- [ ] **Step 4: 提交**

```bash
git add lib/pages/plan_library_detail_page.dart
git commit -m "feat: 采用系统计划接入重量确认页"
```

---

### Task 6: 端到端验证

**Files:**
- 无代码改动；验证完整流程

- [ ] **Step 1: 运行项目全部测试**

Run: `flutter test`
Expected: 全部通过（含既有测试）。若个别既有测试预存在失败（如 `widget_test.dart` Timer 泄漏），记录并跳过，不得改动无关代码。

- [ ] **Step 2: 构建校验**

Run: `flutter build apk --debug`（或若环境不允许则跳过，仅保证 `flutter analyze` 无错误）
Expected: 构建成功。

- [ ] **Step 3: 手工冒烟（如环境允许启动模拟器）**

在 Medium_Phone_4k AVD（emulator-5558，非 16k 页）上运行，验证：
1. 计划库详情页点「采用此计划」→ 进入重量确认页
2. 每个非自重动作显示估算/历史重量，自重动作显示「自重」
3. 修改某个重量 → 点「确认并使用计划」→ 计划保存成功，回首页
4. 进入该计划某训练日「开始训练」→ 重量输入框已按确认值预填

- [ ] **Step 4: 提交（如有冒烟期间的修复）**

```bash
git add <修复涉及的文件>
git commit -m "fix: 重量确认流程冒烟修复"
```
（若无修复则跳过本步）
