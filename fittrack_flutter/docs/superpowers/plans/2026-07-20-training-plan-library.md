# 训练计划库系统实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现训练计划库系统 — JSON 数据驱动、独立推荐算法、积分解锁机制、三层路由页面、三段式主页布局

**Architecture:** 方案 B — JSON 配置文件（5 个按目标拆分）+ SystemPlanLibrary 单例加载器 + PlanRecommendationService 评分算法 + PlanUnlockService 时效解锁 + 3 个新页面 + plan_page 三段式改造

**Tech Stack:** Flutter (Dart >=2.19.6 <3.0.0) + go_router ^6.5.0 + SharedPreferences + sqflite + 现有 FitTrackColors 主题扩展 + 现有 PointsService

## Global Constraints

- Dart SDK: `>=2.19.6 <3.0.0`（禁止使用 Dart 3+ 特性如 records、patterns）
- 路由：使用 go_router ^6.5.0，新路由用 `parentNavigatorKey: rootNavigatorKey` 全屏呈现
- 主题色：使用 `FitTrackColors` 扩展（bgCard/bgSecondary/bgElevated/borderColor/accentGlow/textPrimary/textSecondary/textMuted/successColor/warningColor/purpleColor/infoColor/accentSecondary）
- 图标：使用 `PhosphorIcons` 或 SVG，禁止 emoji 作为图标（但允许在 coverEmoji 字段中使用 emoji 作为封面装饰）
- 边距：紧凑布局，卡片边距 24rpx（约 12pt）而非 36rpx
- 信息层级：两列卡片布局，从最重要到最次要
- 平台兼容：使用 `utils/platform_utils.dart` 的 `isOhos` getter，不直接用 `Platform.isOhos`
- 数据存储：精品解锁记录存入 `Storage.getSettings()['planUnlockRecords']`（JSON 字符串）
- 启动加载：在 `main.dart` 的 `Storage.init()` 之后调用 `SystemPlanLibrary.load()`

---

## File Structure

### 新建文件

| 路径 | 职责 |
|------|------|
| `lib/data/system_plan_library.dart` | SystemPlan/SystemPlanDay 数据类 + SystemPlanLibrary 单例加载器 |
| `lib/services/plan_recommendation_service.dart` | 4 信号评分推荐算法 |
| `lib/services/plan_unlock_service.dart` | 精品计划 90 天时效解锁管理 |
| `lib/pages/plan_library_home_page.dart` | 5 个目标分类瀑布流首页 |
| `lib/pages/plan_library_category_page.dart` | 目标子类页（难度+训练类型筛选） |
| `lib/pages/plan_library_detail_page.dart` | 计划详情+解锁+采用 |
| `assets/data/system_plans/bulk.json` | 增肌计划（~12个，6精品） |
| `assets/data/system_plans/cut.json` | 减脂计划（~10个，5精品） |
| `assets/data/system_plans/shape.json` | 塑形计划（~10个，5精品） |
| `assets/data/system_plans/keep.json` | 保持健康计划（~8个，3精品） |
| `assets/data/system_plans/strength.json` | 力量计划（~10个，6精品） |

### 修改文件

| 路径 | 修改内容 |
|------|----------|
| `lib/main.dart` | 启动时调用 `SystemPlanLibrary.load()` |
| `lib/router.dart` | 新增 3 条路由 |
| `pubspec.yaml` | 注册 `assets/data/system_plans/` |
| `lib/pages/plan_page.dart` | 三段式布局改造，推荐区段始终展示 |
| `lib/pages/home_page.dart` | 接收 'plan' 类型 banner，跳转到详情页 |
| `lib/services/recommendation_service.dart` | 新增 'plan' 类型 banner |
| `lib/pages/questionnaire_page.dart` | 推荐数据源改为从系统计划库获取 |
| `lib/pages/plan_recommend_page.dart` | 推荐数据源改为从系统计划库获取 |
| `lib/pages/add_plan_page.dart` | 推荐数据源改为从系统计划库获取 |

---

## Task 1: 创建 SystemPlan 数据类与加载器

**Files:**
- Create: `lib/data/system_plan_library.dart`

**Interfaces:**
- Produces: `SystemPlan` 类（字段：id/name/goal/difficulty/trainingType/isPremium/pointsCost/totalWeeks/defaultRestTime/description/coverEmoji/coverColors/tags/recommendedFrequency/suitableFor/days）
- Produces: `SystemPlanDay` 类（字段：day/label/muscle/exercises）
- Produces: `SystemPlanExercise` 类（字段：id/name/sets/reps/restTime/weight）
- Produces: `SystemPlanLibrary` 单例（方法：`load()`/`getByGoal()`/`getByDifficulty()`/`getByGoalAndDifficulty()`/`getById()`/`getAll()`/`recommend()`）
- Produces: 常量 `kPlanGoals` = `['bulk', 'cut', 'shape', 'keep', 'strength']`
- Produces: 常量 `kPlanDifficulties` = `['beginner', 'elementary', 'intermediate', 'advanced']`
- Produces: 常量 `kPlanTrainingTypes` = `['3day_split', '4day_split', '5day_split', 'full_body', 'hiit']`
- Produces: 常量 `kGoalLabelsZh` = `{'bulk': '增肌', 'cut': '减脂', 'shape': '塑形', 'keep': '保持健康', 'strength': '力量'}`
- Produces: 常量 `kDifficultyLabelsZh` = `{'beginner': '入门', 'elementary': '初级', 'intermediate': '进阶', 'advanced': '高级'}`
- Produces: 常量 `kTrainingTypeLabelsZh` = `{'3day_split': '三分化', '4day_split': '四分化', '5day_split': '五分化', 'full_body': '全身训练', 'hiit': 'HIIT'}`
- Produces: 常量 `kDifficultyPointsCost` = `{'beginner': 100, 'elementary': 200, 'intermediate': 400, 'advanced': 800}`
- Produces: 常量 `kPlanUnlockValidityDays` = `90`

- [ ] **Step 1: 创建 system_plan_library.dart 文件骨架**

```dart
// lib/data/system_plan_library.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 系统训练计划库 — 从 assets/data/system_plans/*.json 加载内置计划
/// 数据驱动架构，方便 Phase 3 远程下发

// ── 常量 ───────────────────────────────────────────────────────────

const List<String> kPlanGoals = ['bulk', 'cut', 'shape', 'keep', 'strength'];

const List<String> kPlanDifficulties = [
  'beginner',
  'elementary',
  'intermediate',
  'advanced',
];

const List<String> kPlanTrainingTypes = [
  '3day_split',
  '4day_split',
  '5day_split',
  'full_body',
  'hiit',
];

const Map<String, String> kGoalLabelsZh = {
  'bulk': '增肌',
  'cut': '减脂',
  'shape': '塑形',
  'keep': '保持健康',
  'strength': '力量',
};

const Map<String, String> kDifficultyLabelsZh = {
  'beginner': '入门',
  'elementary': '初级',
  'intermediate': '进阶',
  'advanced': '高级',
};

const Map<String, String> kTrainingTypeLabelsZh = {
  '3day_split': '三分化',
  '4day_split': '四分化',
  '5day_split': '五分化',
  'full_body': '全身训练',
  'hiit': 'HIIT',
};

/// 按难度的积分价格（精品计划）
const Map<String, int> kDifficultyPointsCost = {
  'beginner': 100,
  'elementary': 200,
  'intermediate': 400,
  'advanced': 800,
};

/// 精品计划解锁有效期（天）
const int kPlanUnlockValidityDays = 90;

// ── 数据类 ─────────────────────────────────────────────────────────

class SystemPlanExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final int restTime;
  final double? weight;

  const SystemPlanExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTime,
    this.weight,
  });

  factory SystemPlanExercise.fromJson(Map<String, dynamic> json) {
    return SystemPlanExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      restTime: (json['restTime'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'restTime': restTime,
        if (weight != null) 'weight': weight,
      };
}

class SystemPlanDay {
  final int day;
  final String label;
  final String muscle;
  final List<SystemPlanExercise> exercises;

  const SystemPlanDay({
    required this.day,
    required this.label,
    required this.muscle,
    required this.exercises,
  });

  factory SystemPlanDay.fromJson(Map<String, dynamic> json) {
    return SystemPlanDay(
      day: (json['day'] as num).toInt(),
      label: json['label'] as String,
      muscle: json['muscle'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => SystemPlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'label': label,
        'muscle': muscle,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class SystemPlan {
  final String id;
  final String name;
  final String goal;
  final String difficulty;
  final String trainingType;
  final bool isPremium;
  final int pointsCost;
  final int totalWeeks;
  final int defaultRestTime;
  final String description;
  final String coverEmoji;
  final List<String> coverColors;
  final List<String> tags;
  final int recommendedFrequency;
  final String suitableFor;
  final List<SystemPlanDay> days;

  const SystemPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.difficulty,
    required this.trainingType,
    required this.isPremium,
    required this.pointsCost,
    required this.totalWeeks,
    required this.defaultRestTime,
    required this.description,
    required this.coverEmoji,
    required this.coverColors,
    required this.tags,
    required this.recommendedFrequency,
    required this.suitableFor,
    required this.days,
  });

  factory SystemPlan.fromJson(Map<String, dynamic> json) {
    return SystemPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String,
      difficulty: json['difficulty'] as String,
      trainingType: json['trainingType'] as String,
      isPremium: json['isPremium'] as bool? ?? false,
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      totalWeeks: (json['totalWeeks'] as num).toInt(),
      defaultRestTime: (json['defaultRestTime'] as num).toInt(),
      description: json['description'] as String,
      coverEmoji: json['coverEmoji'] as String? ?? '💪',
      coverColors: (json['coverColors'] as List? ?? ['#FF6B6B', '#C44D4D'])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      recommendedFrequency: (json['recommendedFrequency'] as num).toInt(),
      suitableFor: json['suitableFor'] as String? ?? '',
      days: (json['days'] as List)
          .map((e) => SystemPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为 Storage 中存储的 plan 格式（用于"采用此计划"时写入）
  Map<String, dynamic> toStoragePlan() {
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
                'exercises': d.exercises.map((e) => e.toJson()).toList(),
              })
          .toList(),
      'week': 1,
      'progress': 0,
      'status': 'active',
      'sourcePlanId': id,
      'isFromSystemLibrary': true,
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

// ── 加载器单例 ────────────────────────────────────────────────────

class SystemPlanLibrary {
  SystemPlanLibrary._();
  static final SystemPlanLibrary instance = SystemPlanLibrary._();

  List<SystemPlan> _plans = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<SystemPlan> get all => List.unmodifiable(_plans);

  /// 启动时加载全部 JSON
  Future<void> load() async {
    if (_loaded) return;
    final List<SystemPlan> all = [];
    for (final goal in kPlanGoals) {
      try {
        final raw = await rootBundle.loadString(
          'assets/data/system_plans/$goal.json',
        );
        final List<dynamic> list = jsonDecode(raw) as List;
        all.addAll(
          list.map((e) => SystemPlan.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        debugPrint('SystemPlanLibrary: 加载 $goal.json 失败: $e');
      }
    }
    _plans = all;
    _loaded = true;
    debugPrint('SystemPlanLibrary: 已加载 ${_plans.length} 个系统计划');
  }

  List<SystemPlan> getByGoal(String goal) =>
      _plans.where((p) => p.goal == goal).toList();

  List<SystemPlan> getByDifficulty(String difficulty) =>
      _plans.where((p) => p.difficulty == difficulty).toList();

  List<SystemPlan> getByGoalAndDifficulty(String goal, String difficulty) =>
      _plans
          .where((p) => p.goal == goal && p.difficulty == difficulty)
          .toList();

  SystemPlan? getById(String id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 推荐入口 — 委托给 PlanRecommendationService
  /// 此处保留方法签名，实际实现在 plan_recommendation_service.dart 中
  /// 通过 import 该文件并扩展实现
}
```

- [ ] **Step 2: 验证文件无错误**

Run: `flutter analyze lib/data/system_plan_library.dart`
Expected: 无错误，可能有 "unused field" 警告（暂可忽略，后续任务会使用）

- [ ] **Step 3: 提交**

```bash
git add lib/data/system_plan_library.dart
git commit -m "feat: add SystemPlan data classes and library loader"
```

---

## Task 2: 创建 5 个 JSON 种子数据文件

**Files:**
- Create: `assets/data/system_plans/bulk.json`
- Create: `assets/data/system_plans/cut.json`
- Create: `assets/data/system_plans/shape.json`
- Create: `assets/data/system_plans/keep.json`
- Create: `assets/data/system_plans/strength.json`

**Interfaces:**
- Consumes: Task 1 的 JSON Schema
- Produces: 5 个 JSON 文件，总计 ~50 个计划（25 精品）

**说明：** 由于 50+ 计划数据量巨大，使用 subagent 并行生成。每个文件需严格遵循 Task 1 中定义的 JSON Schema。

- [ ] **Step 1: 在 pubspec.yaml 中注册 assets 目录**

修改 `pubspec.yaml`，在 `flutter.assets` 下新增：

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/data/system_plans/   # 新增此行
```

- [ ] **Step 2: 创建 assets 目录**

```bash
mkdir -p assets/data/system_plans
```

- [ ] **Step 3: 用 subagent 并行生成 5 个 JSON 文件**

由于 50+ 计划内容量大，分别派 5 个 subagent 并行生成（每个 agent 生成一个 JSON 文件）：

**Subagent 任务模板（以 bulk.json 为例）：**

```
创建文件 assets/data/system_plans/bulk.json，包含 12 个增肌训练计划，其中 6 个精品计划。

每个计划必须严格遵循以下 JSON Schema：
{
  "id": "bulk_<trainingType>_<difficulty>_<序号>",  // 如 "bulk_3day_beginner_01"
  "name": "中文名称",
  "goal": "bulk",
  "difficulty": "beginner" | "elementary" | "intermediate" | "advanced",
  "trainingType": "3day_split" | "4day_split" | "5day_split" | "full_body" | "hiit",
  "isPremium": true | false,
  "pointsCost": <难度对应价格, 精品才填, 非精品为 0>,
  "totalWeeks": 4-16,
  "defaultRestTime": 60-180,
  "description": "详细描述，至少 50 字",
  "coverEmoji": "💪" | "🏋️" | "🔥" 等,
  "coverColors": ["#XXXXXX", "#YYYYYY"],
  "tags": ["标签1", "标签2"],
  "recommendedFrequency": 3-6,
  "suitableFor": "适合人群描述",
  "days": [
    {
      "day": 1,
      "label": "训练日名称",
      "muscle": "胸部" | "背部" | "腿部" | "肩部" | "手臂" | "核心" | "全身",
      "exercises": [
        {"id": "ex_<muscle>_<序号>", "name": "动作名", "sets": 3-5, "reps": 8-15, "restTime": 60-180}
      ]
    }
  ]
}

精品价格表：beginner=100, elementary=200, intermediate=400, advanced=800

要求：
1. 12 个计划，覆盖 4 种难度（beginner=3, elementary=3, intermediate=3, advanced=3）
2. 6 个精品（isPremium=true），分布在各种难度
3. 每个计划的 days 数量应与 trainingType 对应（3day_split=3天, 4day_split=4天, 5day_split=5天, full_body=3-4天, hiit=3-4天）
4. 每个 day 至少 4 个 exercises
5. 动作名称用中文，符合健身房常见动作
6. ID 全局唯一，前缀为 "bulk_"
7. 输出为合法 JSON 数组（最外层是 [...]）
8. 颜色用 Morandi 色系（柔和、低饱和度）
```

类似派 5 个 subagent 并行生成 bulk/cut/shape/keep/strength 五个文件。

- [ ] **Step 4: 验证 JSON 合法性**

Run: 在 dart 代码中临时加载并打印长度

```bash
flutter run -d windows
```
（在 main.dart 中临时添加 `print(await rootBundle.loadString('assets/data/system_plans/bulk.json'));` 验证）

或用 Python:
```bash
python -c "import json; [print(f, len(json.load(open(f'assets/data/system_plans/{f}.json')))) for f in ['bulk','cut','shape','keep','strength']]"
```

Expected: 5 个文件均合法 JSON，总数 ~50 个计划

- [ ] **Step 5: 提交**

```bash
git add pubspec.yaml assets/data/system_plans/
git commit -m "feat: add 5 JSON seed data files for system plan library"
```

---

## Task 3: 创建 PlanUnlockService 解锁服务

**Files:**
- Create: `lib/services/plan_unlock_service.dart`

**Interfaces:**
- Consumes: `PointsService.instance.spendPoints(int, String)` 返回 `Future<bool>`
- Consumes: `Storage.getSettings()` / `Storage.saveSettings()`
- Consumes: `kPlanUnlockValidityDays` 常量
- Produces: `PlanUnlockService.instance.isPlanUnlocked(String planId)` 返回 `bool`
- Produces: `PlanUnlockService.instance.unlockPlan(String planId, int cost)` 返回 `Future<UnlockResult>`
- Produces: `PlanUnlockService.instance.getUnlockInfo(String planId)` 返回 `PlanUnlockInfo?`
- Produces: `UnlockResult` 枚举（`success` / `insufficientPoints` / `alreadyUnlocked` / `unknownPlan`）
- Produces: `PlanUnlockInfo` 类（`planId` / `unlockTime` / `expireTime` / `isExpired`）

- [ ] **Step 1: 创建 plan_unlock_service.dart**

```dart
// lib/services/plan_unlock_service.dart
import 'dart:convert';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import 'points_service.dart';

enum UnlockResult {
  success,
  insufficientPoints,
  alreadyUnlocked,
  unknownPlan,
}

class PlanUnlockInfo {
  final String planId;
  final int unlockTime;
  final int expireTime;

  const PlanUnlockInfo({
    required this.planId,
    required this.unlockTime,
    required this.expireTime,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expireTime;

  int get remainingDays {
    if (isExpired) return 0;
    final ms = expireTime - DateTime.now().millisecondsSinceEpoch;
    return (ms / (24 * 60 * 60 * 1000)).ceil();
  }

  factory PlanUnlockInfo.fromJson(Map<String, dynamic> json) {
    return PlanUnlockInfo(
      planId: json['planId'] as String,
      unlockTime: (json['unlockTime'] as num).toInt(),
      expireTime: (json['expireTime'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'unlockTime': unlockTime,
        'expireTime': expireTime,
      };
}

class PlanUnlockService {
  static final PlanUnlockService instance = PlanUnlockService._();
  PlanUnlockService._();

  static const int _validityMs = kPlanUnlockValidityDays * 24 * 60 * 60 * 1000;

  /// 检查计划是否已解锁且在有效期内
  bool isPlanUnlocked(String planId) {
    final info = getUnlockInfo(planId);
    return info != null && !info.isExpired;
  }

  /// 获取解锁信息（可能已过期）
  PlanUnlockInfo? getUnlockInfo(String planId) {
    final list = _readRecords();
    try {
      final match = list.firstWhere((r) => r.planId == planId);
      return match;
    } catch (_) {
      return null;
    }
  }

  /// 解锁精品计划
  /// 返回 success 表示扣费成功且已解锁
  Future<UnlockResult> unlockPlan(String planId, int cost) async {
    final plan = SystemPlanLibrary.instance.getById(planId);
    if (plan == null) return UnlockResult.unknownPlan;
    if (!plan.isPremium) return UnlockResult.alreadyUnlocked;

    if (isPlanUnlocked(planId)) return UnlockResult.alreadyUnlocked;

    final success = await PointsService.instance.spendPoints(
      cost,
      'unlock_plan_$planId',
    );
    if (!success) return UnlockResult.insufficientPoints;

    final now = DateTime.now().millisecondsSinceEpoch;
    final info = PlanUnlockInfo(
      planId: planId,
      unlockTime: now,
      expireTime: now + _validityMs,
    );

    final list = _readRecords();
    list.removeWhere((r) => r.planId == planId); // 替换旧记录
    list.add(info);
    _writeRecords(list);

    Storage.dataChanged.value = !Storage.dataChanged.value;
    return UnlockResult.success;
  }

  /// 清理已过期的解锁记录（可选调用，节省存储）
  void cleanExpiredRecords() {
    final list = _readRecords();
    final before = list.length;
    list.removeWhere((r) => r.isExpired);
    if (list.length != before) {
      _writeRecords(list);
    }
  }

  // ── 内部辅助 ──────────────────────────────────────────

  List<PlanUnlockInfo> _readRecords() {
    final settings = Storage.getSettings();
    final raw = settings['planUnlockRecords'] as String? ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => PlanUnlockInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _writeRecords(List<PlanUnlockInfo> records) {
    final settings = Storage.getSettings();
    settings['planUnlockRecords'] = jsonEncode(
      records.map((r) => r.toJson()).toList(),
    );
    Storage.saveSettings(settings);
  }
}
```

- [ ] **Step 2: 验证无错误**

Run: `flutter analyze lib/services/plan_unlock_service.dart`
Expected: 无错误

- [ ] **Step 3: 提交**

```bash
git add lib/services/plan_unlock_service.dart
git commit -m "feat: add PlanUnlockService for premium plan 90-day unlock"
```

---

## Task 4: 创建 PlanRecommendationService 推荐算法

**Files:**
- Create: `lib/services/plan_recommendation_service.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.all` / `getByGoal()`
- Consumes: `Storage.getBodyData()` 返回 `Map<String, dynamic>`（含 height/weight/bmi/bodyFat/restingHeartRate）
- Consumes: `Storage.getRecords()` 返回 `List<Map<String, dynamic>>`（含 date/setRecords/duration）
- Consumes: `Storage.getSettings()` 返回 `Map<String, dynamic>`（含 fitnessGoal/fitnessLevel）
- Consumes: `Storage.getPlans()` 返回 `List<Map<String, dynamic>>`（含 sourcePlanId 字段，用于判断历史使用）
- Produces: `PlanRecommendationService.instance.recommend({int limit = 5})` 返回 `List<PlanRecommendation>`
- Produces: `PlanRecommendation` 类（`plan` / `score` / `reasons`）

- [ ] **Step 1: 创建 plan_recommendation_service.dart**

```dart
// lib/services/plan_recommendation_service.dart
import '../data/storage.dart';
import '../data/system_plan_library.dart';

/// 推荐结果项
class PlanRecommendation {
  final SystemPlan plan;
  final double score; // 0-100
  final List<String> reasons; // 推荐理由（中文，最多 3 条）

  const PlanRecommendation({
    required this.plan,
    required this.score,
    required this.reasons,
  });
}

class PlanRecommendationService {
  static final PlanRecommendationService instance =
      PlanRecommendationService._();
  PlanRecommendationService._();

  /// 主推荐入口 — 返回 top N 推荐计划
  List<PlanRecommendation> recommend({int limit = 5}) {
    if (!SystemPlanLibrary.instance.isLoaded) return [];
    final allPlans = SystemPlanLibrary.instance.all;
    if (allPlans.isEmpty) return [];

    final settings = Storage.getSettings();
    final bodyData = Storage.getBodyData();
    final records = Storage.getRecords();
    final userPlans = Storage.getPlans();

    final userGoal = settings['fitnessGoal'] as String? ?? '';
    final userLevel = _inferFitnessLevel(records, settings);

    // 1. 筛选：优先匹配 goal；无 goal 时全候选
    List<SystemPlan> candidates;
    if (userGoal.isNotEmpty &&
        kPlanGoals.contains(_mapGoalFromSettings(userGoal))) {
      final mappedGoal = _mapGoalFromSettings(userGoal);
      candidates = SystemPlanLibrary.instance.getByGoal(mappedGoal);
      // 候选不足时补充其他目标
      if (candidates.length < 5) {
        final others = allPlans.where((p) => p.goal != mappedGoal).toList();
        candidates = [...candidates, ...others];
      }
    } else {
      candidates = allPlans;
    }

    // 2. 评分
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;
    final recentRecords = records.where((r) {
      final ts = r['date'] as int? ?? r['createTime'] as int? ?? 0;
      return ts >= thirtyDaysAgo;
    }).toList();

    final scored = candidates.map((plan) {
      return _scorePlan(
        plan: plan,
        userLevel: userLevel,
        userGoal: userGoal,
        bodyData: bodyData,
        recentRecords: recentRecords,
        userPlans: userPlans,
      );
    }).toList();

    // 3. 排序+截断
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }

  // ── 评分核心 ──────────────────────────────────────────────────

  PlanRecommendation _scorePlan({
    required SystemPlan plan,
    required String userLevel,
    required String userGoal,
    required Map<String, dynamic> bodyData,
    required List<Map<String, dynamic>> recentRecords,
    required List<Map<String, dynamic>> userPlans,
  }) {
    final reasons = <String>[];
    double score = 0;

    // 难度匹配度（30 分）
    final difficultyScore = _scoreDifficulty(plan.difficulty, userLevel);
    score += difficultyScore.points;
    if (difficultyScore.reason != null) reasons.add(difficultyScore.reason!);

    // 频率匹配度（25 分）
    final frequencyScore = _scoreFrequency(
      plan.recommendedFrequency,
      recentRecords,
    );
    score += frequencyScore.points;
    if (frequencyScore.reason != null) reasons.add(frequencyScore.reason!);

    // BMI 区间匹配（15 分）
    final bmiScore = _scoreBmi(plan.suitableFor, bodyData);
    score += bmiScore.points;
    if (bmiScore.reason != null) reasons.add(bmiScore.reason!);

    // 肌群偏好匹配（15 分）
    final muscleScore = _scoreMusclePreference(plan, recentRecords);
    score += muscleScore.points;

    // 未训练过的计划加分（15 分）
    final noveltyScore = _scoreNovelty(plan.id, userPlans);
    score += noveltyScore.points;
    if (noveltyScore.reason != null) reasons.add(noveltyScore.reason!);

    return PlanRecommendation(
      plan: plan,
      score: score,
      reasons: reasons.take(3).toList(),
    );
  }

  // ── 子评分函数 ────────────────────────────────────────────────

  ({double points, String? reason}) _scoreDifficulty(
    String planDifficulty,
    String userLevel,
  ) {
    // level: 'newbie'/'beginner'/'intermediate'/'advanced'
    // difficulty: 'beginner'/'elementary'/'intermediate'/'advanced'
    final levelMap = {
      'newbie': 0,
      'beginner': 1,
      'intermediate': 2,
      'advanced': 3,
    };
    final diffMap = {
      'beginner': 0,
      'elementary': 1,
      'intermediate': 2,
      'advanced': 3,
    };
    final userLv = levelMap[userLevel] ?? 0;
    final planLv = diffMap[planDifficulty] ?? 0;
    final diff = (userLv - planLv).abs();
    final points = switch (diff) {
      0 => 30.0,
      1 => 22.0,
      2 => 12.0,
      _ => 5.0,
    };
    return (points: points, reason: '难度匹配当前训练水平');
  }

  ({double points, String? reason}) _scoreFrequency(
    int planFreq,
    List<Map<String, dynamic>> recentRecords,
  ) {
    if (recentRecords.isEmpty) {
      // 新用户：推荐低频计划
      final points = planFreq <= 3 ? 20.0 : 10.0;
      return (points: points, reason: '适合新手的训练频率');
    }
    // 去重训练日
    final days = <String>{};
    for (final r in recentRecords) {
      final ts = r['date'] as int? ?? 0;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      days.add('${d.year}-${d.month}-${d.day}');
    }
    final avgFreqPerWeek = (days.length / 30 * 7).round();
    final diff = (avgFreqPerWeek - planFreq).abs();
    final points = switch (diff) {
      0 => 25.0,
      1 => 20.0,
      2 => 12.0,
      _ => 5.0,
    };
    return (points: points, reason: '频率契合你近期的训练节奏');
  }

  ({double points, String? reason}) _scoreBmi(
    String suitableFor,
    Map<String, dynamic> bodyData,
  ) {
    final height = (bodyData['height'] as num?)?.toDouble() ?? 0;
    final weight = (bodyData['weight'] as num?)?.toDouble() ?? 0;
    if (height <= 0 || weight <= 0) return (points: 8.0, reason: null);

    final bmi = weight / (height * height / 10000);
    String bmiCategory;
    if (bmi < 18.5) {
      bmiCategory = '偏瘦';
    } else if (bmi < 24) {
      bmiCategory = '正常';
    } else if (bmi < 28) {
      bmiCategory = '超重';
    } else {
      bmiCategory = '肥胖';
    }

    // 简单关键词匹配
    if (suitableFor.contains(bmiCategory) ||
        suitableFor.contains(bmi.toStringAsFixed(0))) {
      return (points: 15.0, reason: '符合你的身体指标');
    }
    return (points: 7.0, reason: null);
  }

  ({double points, String? reason}) _scoreMusclePreference(
    SystemPlan plan,
    List<Map<String, dynamic>> recentRecords,
  ) {
    if (recentRecords.isEmpty) return (points: 8.0, reason: null);

    // 统计用户近期训练肌群分布
    final muscleCount = <String, int>{};
    for (final r in recentRecords) {
      final setRecords = r['setRecords'] as List? ?? [];
      for (final sr in setRecords) {
        final muscle = (sr as Map<String, dynamic>)['muscle'] as String? ?? '';
        if (muscle.isNotEmpty) {
          muscleCount[muscle] = (muscleCount[muscle] ?? 0) + 1;
        }
      }
    }
    if (muscleCount.isEmpty) return (points: 8.0, reason: null);

    // 统计计划覆盖的肌群
    final planMuscles = <String>{};
    for (final d in plan.days) {
      planMuscles.add(d.muscle);
    }

    // 计算重合度
    int matchCount = 0;
    for (final m in planMuscles) {
      if (muscleCount.containsKey(m)) matchCount++;
    }
    final overlap = matchCount / planMuscles.length;
    final points = overlap * 15.0;
    return (points: points, reason: null);
  }

  ({double points, String? reason}) _scoreNovelty(
    String planId,
    List<Map<String, dynamic>> userPlans,
  ) {
    // 检查用户历史计划中是否使用过此系统计划
    final used = userPlans.any((p) => p['sourcePlanId'] == planId);
    if (used) {
      return (points: 3.0, reason: null); // 已用过加分低
    }
    return (points: 15.0, reason: '全新计划，为你推荐');
  }

  // ── 辅助 ──────────────────────────────────────────────────────

  /// 从 settings.fitnessGoal 映射到 plan.goal
  /// settings 中的值: '增肌'/'减脂'/'塑形'/'保持健康' 等
  String _mapGoalFromSettings(String settingsGoal) {
    if (settingsGoal.contains('增肌') || settingsGoal.contains('bulk')) {
      return 'bulk';
    }
    if (settingsGoal.contains('减脂') || settingsGoal.contains('cut')) {
      return 'cut';
    }
    if (settingsGoal.contains('塑形') || settingsGoal.contains('shape')) {
      return 'shape';
    }
    if (settingsGoal.contains('保持') || settingsGoal.contains('keep')) {
      return 'keep';
    }
    if (settingsGoal.contains('力量') || settingsGoal.contains('strength')) {
      return 'strength';
    }
    return 'bulk'; // 默认
  }

  /// 从训练记录推断用户水平
  /// 返回: 'newbie'/'beginner'/'intermediate'/'advanced'
  String _inferFitnessLevel(
    List<Map<String, dynamic>> records,
    Map<String, dynamic> settings,
  ) {
    // 优先使用 settings 中的 fitnessLevel
    final settingLevel = settings['fitnessLevel'] as String? ?? '';
    if (settingLevel.contains('高级') || settingLevel.contains('advanced')) {
      return 'advanced';
    }
    if (settingLevel.contains('中级') || settingLevel.contains('intermediate')) {
      return 'intermediate';
    }
    if (settingLevel.contains('初级') || settingLevel.contains('beginner')) {
      return 'beginner';
    }
    if (settingLevel.contains('新手') || settingLevel.contains('newbie')) {
      return 'newbie';
    }

    // 无设置时，从训练记录推断
    if (records.isEmpty) return 'newbie';
    if (records.length < 10) return 'beginner';
    if (records.length < 50) return 'intermediate';
    return 'advanced';
  }
}
```

- [ ] **Step 2: 验证无错误**

Run: `flutter analyze lib/services/plan_recommendation_service.dart`
Expected: 无错误

- [ ] **Step 3: 提交**

```bash
git add lib/services/plan_recommendation_service.dart
git commit -m "feat: add PlanRecommendationService with 4-signal scoring algorithm"
```

---

## Task 5: 在 main.dart 中启动加载

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.load()`

- [ ] **Step 1: 读取 main.dart 找到 Storage.init() 调用位置**

Run: `grep -n "Storage.init" lib/main.dart`（用 Grep 工具替代）

- [ ] **Step 2: 在 Storage.init() 后添加 SystemPlanLibrary.load()**

定位 `await Storage.init();` 这一行，在其后添加：

```dart
await SystemPlanLibrary.instance.load();
```

文件顶部需要 import：
```dart
import 'data/system_plan_library.dart';
```

- [ ] **Step 3: 验证无错误**

Run: `flutter analyze lib/main.dart`
Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/main.dart
git commit -m "feat: load SystemPlanLibrary at app startup"
```

---

## Task 6: 创建 PlanLibraryHomePage（瀑布流首页）

**Files:**
- Create: `lib/pages/plan_library_home_page.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.getByGoal(goal)` 返回 `List<SystemPlan>`
- Consumes: `kPlanGoals` / `kGoalLabelsZh` 常量
- Produces: `PlanLibraryHomePage` Widget
- 路由: `/plan-library`

- [ ] **Step 1: 创建 plan_library_home_page.dart**

```dart
// lib/pages/plan_library_home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/system_plan_library.dart';
import '../theme/app_theme.dart';

class PlanLibraryHomePage extends StatelessWidget {
  const PlanLibraryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<FitTrackColors>()!.bgSecondary,
      appBar: AppBar(
        title: const Text('系统训练计划库'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择你的训练目标',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final goal = kPlanGoals[index];
                  return _GoalCard(goal: goal);
                },
                childCount: kPlanGoals.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final plans = SystemPlanLibrary.instance.getByGoal(goal);
    final premiumCount = plans.where((p) => p.isPremium).length;
    final label = kGoalLabelsZh[goal] ?? goal;
    final emoji = _goalEmoji(goal);
    final colors = _goalColors(goal);
    final ft = Theme.of(context).extension<FitTrackColors>()!;

    return GestureDetector(
      onTap: () => context.go('/plan-library/$goal'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 12,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plans.length}个计划',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '含 $premiumCount 个精品',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalEmoji(String goal) {
    return switch (goal) {
      'bulk' => '💪',
      'cut' => '🔥',
      'shape' => '🧘',
      'keep' => '❤️',
      'strength' => '⚡',
      _ => '🏋️',
    };
  }

  List<Color> _goalColors(String goal) {
    return switch (goal) {
      'bulk' => [const Color(0xFFE89B9B), const Color(0xFFC47070)],
      'cut' => [const Color(0xFFE8B97A), const Color(0xFFC4914D)],
      'shape' => [const Color(0xFFB5C5E0), const Color(0xFF8FA3C7)],
      'keep' => [const Color(0xFFA8D5BA), const Color(0xFF7AB593)],
      'strength' => [const Color(0xFFC5B0D8), const Color(0xFF9C82B8)],
      _ => [const Color(0xFFB0B0B0), const Color(0xFF808080)],
    };
  }
}
```

- [ ] **Step 2: 验证无错误**

Run: `flutter analyze lib/pages/plan_library_home_page.dart`
Expected: 无错误（可能需要根据项目实际 FitTrackColors 字段调整）

- [ ] **Step 3: 提交**

```bash
git add lib/pages/plan_library_home_page.dart
git commit -m "feat: add PlanLibraryHomePage with waterfall goal cards"
```

---

## Task 7: 创建 PlanLibraryCategoryPage（目标子类页）

**Files:**
- Create: `lib/pages/plan_library_category_page.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.getByGoal(goal)`
- Consumes: `PlanUnlockService.instance.isPlanUnlocked(planId)`
- Consumes: `kPlanDifficulties` / `kPlanTrainingTypes` / `kDifficultyLabelsZh` / `kTrainingTypeLabelsZh` / `kDifficultyPointsCost`
- Consumes: `PointsService.instance.points`
- Produces: `PlanLibraryCategoryPage` Widget，接收 `goal` 参数

- [ ] **Step 1: 创建 plan_library_category_page.dart**

```dart
// lib/pages/plan_library_category_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/system_plan_library.dart';
import '../services/plan_unlock_service.dart';
import '../services/points_service.dart';
import '../theme/app_theme.dart';

class PlanLibraryCategoryPage extends StatefulWidget {
  final String goal;
  const PlanLibraryCategoryPage({super.key, required this.goal});

  @override
  State<PlanLibraryCategoryPage> createState() =>
      _PlanLibraryCategoryPageState();
}

class _PlanLibraryCategoryPageState extends State<PlanLibraryCategoryPage> {
  String? _selectedDifficulty; // null = 全部
  final Set<String> _selectedTypes = {}; // 空集合 = 全部

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final allPlans = SystemPlanLibrary.instance.getByGoal(widget.goal);
    final filtered = allPlans.where((p) {
      if (_selectedDifficulty != null && p.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(p.trainingType)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      appBar: AppBar(
        title: Text(kGoalLabelsZh[widget.goal] ?? widget.goal),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 难度筛选
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: _buildDifficultyChips(ft),
            ),
          ),
          // 训练类型筛选
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildTrainingTypeChips(ft),
            ),
          ),
          // 计划列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _PlanListCard(plan: filtered[index]);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildDifficultyChips(FitTrackColors ft) {
    final options = [null, ...kPlanDifficulties];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((d) {
        final selected = _selectedDifficulty == d;
        final label = d == null ? '全部难度' : kDifficultyLabelsZh[d];
        return ChoiceChip(
          label: Text(label!),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedDifficulty = selected ? null : d;
            });
          },
          selectedColor: ft.purpleColor,
          labelStyle: TextStyle(
            color: selected ? Colors.white : ft.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrainingTypeChips(FitTrackColors ft) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kPlanTrainingTypes.map((t) {
        final selected = _selectedTypes.contains(t);
        return FilterChip(
          label: Text(kTrainingTypeLabelsZh[t]!),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedTypes.add(t);
              } else {
                _selectedTypes.remove(t);
              }
            });
          },
          selectedColor: ft.infoColor,
          labelStyle: TextStyle(
            color: selected ? Colors.white : ft.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _PlanListCard extends StatelessWidget {
  final SystemPlan plan;
  const _PlanListCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final isUnlocked = plan.isPremium &&
        PlanUnlockService.instance.isPlanUnlocked(plan.id);
    final pointsBalance = PointsService.instance.points;

    return GestureDetector(
      onTap: () => context.go('/plan-library/detail/${plan.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ft.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ft.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧封面
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: plan.coverColors
                      .map((c) => Color(int.parse(c.substring(1), radix: 16) |
                          0xFF000000))
                      .toList(),
                ),
              ),
              child: Center(
                child: Text(
                  plan.coverEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            color: ft.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (plan.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ft.warningColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '精品',
                            style: TextStyle(
                              color: ft.warningColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${kDifficultyLabelsZh[plan.difficulty]} · '
                    '${kTrainingTypeLabelsZh[plan.trainingType]} · '
                    '每周${plan.recommendedFrequency}练 · '
                    '${plan.totalWeeks}周',
                    style: TextStyle(color: ft.textSecondary, fontSize: 13),
                  ),
                  if (plan.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: plan.tags
                          .map((t) => Text(
                                '#$t',
                                style: TextStyle(
                                  color: ft.textMuted,
                                  fontSize: 12,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // 右侧价格
            if (plan.isPremium)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isUnlocked)
                    Text(
                      '已解锁',
                      style: TextStyle(
                        color: ft.successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    Text(
                      '${plan.pointsCost}',
                      style: TextStyle(
                        color: ft.warningColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '积分',
                      style: TextStyle(color: ft.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              )
            else
              Text(
                '免费',
                style: TextStyle(
                  color: ft.successColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 验证无错误**

Run: `flutter analyze lib/pages/plan_library_category_page.dart`
Expected: 无错误

- [ ] **Step 3: 提交**

```bash
git add lib/pages/plan_library_category_page.dart
git commit -m "feat: add PlanLibraryCategoryPage with difficulty/type filters"
```

---

## Task 8: 创建 PlanLibraryDetailPage（详情+解锁+采用）

**Files:**
- Create: `lib/pages/plan_library_detail_page.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.getById(planId)`
- Consumes: `PlanUnlockService.instance.unlockPlan(planId, cost)` 返回 `Future<UnlockResult>`
- Consumes: `PlanUnlockService.instance.isPlanUnlocked(planId)` / `getUnlockInfo(planId)`
- Consumes: `PointsService.instance.points`
- Consumes: `Storage.addPlan(plan)` / `Storage.updatePlan(planId, updates)` 用于"采用此计划"时暂停现有 active
- Consumes: `SystemPlan.toStoragePlan()` 转换方法
- Produces: `PlanLibraryDetailPage` Widget，接收 `planId` 参数

- [ ] **Step 1: 创建 plan_library_detail_page.dart**

```dart
// lib/pages/plan_library_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/plan_unlock_service.dart';
import '../services/points_service.dart';
import '../theme/app_theme.dart';

class PlanLibraryDetailPage extends StatefulWidget {
  final String planId;
  const PlanLibraryDetailPage({super.key, required this.planId});

  @override
  State<PlanLibraryDetailPage> createState() => _PlanLibraryDetailPageState();
}

class _PlanLibraryDetailPageState extends State<PlanLibraryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final plan = SystemPlanLibrary.instance.getById(widget.planId);

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('计划不存在', style: TextStyle(color: ft.textSecondary)),
        ),
      );
    }

    final isUnlocked = !plan.isPremium ||
        PlanUnlockService.instance.isPlanUnlocked(plan.id);
    final unlockInfo = PlanUnlockService.instance.getUnlockInfo(plan.id);

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      appBar: AppBar(
        title: Text(plan.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(plan, ft),
                const SizedBox(height: 16),
                _buildStats(plan, ft),
                const SizedBox(height: 16),
                _buildDescription(plan, ft),
                const SizedBox(height: 16),
                _buildDays(plan, ft),
                const SizedBox(height: 80), // 底部按钮空间
              ],
            ),
          ),
          _buildBottomBar(plan, isUnlocked, unlockInfo, ft),
        ],
      ),
    );
  }

  Widget _buildHeader(SystemPlan plan, FitTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plan.coverColors
              .map((c) =>
                  Color(int.parse(c.substring(1), radix: 16) | 0xFF000000))
              .toList(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.coverEmoji, style: const TextStyle(fontSize: 48)),
              const Spacer(),
              if (plan.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '精品计划',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(SystemPlan plan, FitTrackColors ft) {
    final stats = [
      ('难度', kDifficultyLabelsZh[plan.difficulty]!),
      ('类型', kTrainingTypeLabelsZh[plan.trainingType]!),
      ('频率', '每周${plan.recommendedFrequency}练'),
      ('周期', '${plan.totalWeeks}周'),
      ('休息', '${plan.defaultRestTime}秒'),
      ('训练日', '${plan.days.length}天'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: stats
            .map((s) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.$2,
                      style: TextStyle(
                        color: ft.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.$1,
                      style: TextStyle(color: ft.textMuted, fontSize: 11),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDescription(SystemPlan plan, FitTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '计划说明',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(color: ft.textSecondary, fontSize: 14, height: 1.6),
          ),
          if (plan.suitableFor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '适合人群',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.suitableFor,
              style: TextStyle(color: ft.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDays(SystemPlan plan, FitTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '训练日安排',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.days.map((d) => _buildDayItem(d, ft)),
        ],
      ),
    );
  }

  Widget _buildDayItem(SystemPlanDay day, FitTrackColors ft) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ft.purpleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'D${day.day}',
                style: TextStyle(
                  color: ft.purpleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.label,
                  style: TextStyle(
                    color: ft.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${day.muscle} · ${day.exercises.length}个动作',
                  style: TextStyle(color: ft.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        ...day.exercises.map((e) => Padding(
              padding: const EdgeInsets.only(
                left: 38,
                top: 4,
                bottom: 4,
                right: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: TextStyle(color: ft.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${e.sets}×${e.reps}',
                    style: TextStyle(
                      color: ft.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${e.restTime}s',
                    style: TextStyle(color: ft.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBottomBar(
    SystemPlan plan,
    bool isUnlocked,
    PlanUnlockInfo? unlockInfo,
    FitTrackColors ft,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        border: Border(top: BorderSide(color: ft.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (plan.isPremium) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnlocked && unlockInfo != null)
                      Text(
                        '剩余 ${unlockInfo.remainingDays} 天有效',
                        style: TextStyle(
                          color: ft.successColor,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        '当前积分: ${PointsService.instance.points}',
                        style: TextStyle(color: ft.textMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? '已解锁'
                          : '需 ${plan.pointsCost} 积分解锁（90天有效）',
                      style: TextStyle(
                        color: isUnlocked ? ft.successColor : ft.warningColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: plan.isPremium ? 1 : 1,
              child: ElevatedButton(
                onPressed: () => _handleAction(plan, isUnlocked),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked ? ft.purpleColor : ft.warningColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isUnlocked
                      ? '采用此计划'
                      : '支付 ${plan.pointsCost} 积分解锁',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(SystemPlan plan, bool isUnlocked) async {
    if (!isUnlocked) {
      // 解锁流程
      final result = await PlanUnlockService.instance.unlockPlan(
        plan.id,
        plan.pointsCost,
      );
      if (!mounted) return;
      switch (result) {
        case UnlockResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('解锁成功！90天内可使用此计划')),
          );
          setState(() {}); // 刷新 UI
          break;
        case UnlockResult.insufficientPoints:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '积分不足，还差 ${plan.pointsCost - PointsService.instance.points} 积分',
              ),
            ),
          );
          break;
        case UnlockResult.alreadyUnlocked:
          setState(() {});
          break;
        case UnlockResult.unknownPlan:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('计划不存在')),
          );
          break;
      }
      return;
    }

    // 已解锁（或免费计划）→ 采用
    await _adoptPlan(plan);
  }

  Future<void> _adoptPlan(SystemPlan plan) async {
    // 暂停现有 active 计划
    final existingPlans = Storage.getPlans();
    for (final p in existingPlans) {
      if (p['status'] == 'active') {
        Storage.updatePlan(p['id'] as String, {'status': 'paused'});
      }
    }
    // 添加新计划
    final newPlan = plan.toStoragePlan();
    Storage.addPlan(newPlan);
    Storage.dataChanged.value = !Storage.dataChanged.value;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已采用计划：${plan.name}')),
    );
    context.go('/plan');
  }
}
```

- [ ] **Step 2: 验证无错误**

Run: `flutter analyze lib/pages/plan_library_detail_page.dart`
Expected: 无错误

- [ ] **Step 3: 提交**

```bash
git add lib/pages/plan_library_detail_page.dart
git commit -m "feat: add PlanLibraryDetailPage with unlock and adopt actions"
```

---

## Task 9: 注册路由

**Files:**
- Modify: `lib/router.dart`

**Interfaces:**
- Consumes: Task 6/7/8 的 3 个页面

- [ ] **Step 1: 读取 router.dart 找到路由列表位置**

读取 `lib/router.dart` 文件，找到 `GoRouter` 配置中的 `routes:` 列表。

- [ ] **Step 2: 在 routes 列表中添加 3 条新路由**

在 `/add-plan` 路由之后添加：

```dart
GoRoute(
  path: '/plan-library',
  name: 'planLibraryHome',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const PlanLibraryHomePage(),
),
GoRoute(
  path: '/plan-library/:goal',
  name: 'planLibraryCategory',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => PlanLibraryCategoryPage(
    goal: state.pathParameters['goal']!,
  ),
),
GoRoute(
  path: '/plan-library/detail/:planId',
  name: 'planLibraryDetail',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => PlanLibraryDetailPage(
    planId: state.pathParameters['planId']!,
  ),
),
```

文件顶部添加 import：
```dart
import 'pages/plan_library_home_page.dart';
import 'pages/plan_library_category_page.dart';
import 'pages/plan_library_detail_page.dart';
```

- [ ] **Step 3: 验证无错误**

Run: `flutter analyze lib/router.dart`
Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/router.dart
git commit -m "feat: register 3 plan library routes"
```

---

## Task 10: 改造 plan_page 三段式布局

**Files:**
- Modify: `lib/pages/plan_page.dart`

**Interfaces:**
- Consumes: `PlanRecommendationService.instance.recommend(limit: 3)` 返回 `List<PlanRecommendation>`
- Consumes: `SystemPlanLibrary` 间接调用（通过推荐服务）
- Consumes: `Storage.getPlans()` 返回 `List<Map<String, dynamic>>`，字段含 createTime/status/sourcePlanId
- Consumes: `Storage.getRecords()` 用于计算使用次数

- [ ] **Step 1: 读取 plan_page.dart 找到现有结构**

读取 `lib/pages/plan_page.dart`，重点关注：
- `_loadPlans()` 方法
- `_activePlans` / `_otherPlans` getter
- `_buildPlanList()` 方法
- `_buildRecommendedPlans()` 方法

- [ ] **Step 2: 添加推荐服务和系统计划库的 import**

文件顶部添加：
```dart
import '../services/plan_recommendation_service.dart';
import '../data/system_plan_library.dart';
```

- [ ] **Step 3: 添加自定义计划排序算法**

在 `_PlanPageState` 类中添加方法：

```dart
/// 自定义计划排序：创建时间 30% + 使用次数 70%
List<Map<String, dynamic>> _sortCustomPlans(List<Map<String, dynamic>> plans) {
  final customPlans = plans.where((p) => p['sourcePlanId'] == null).toList();
  final records = Storage.getRecords();
  
  // 计算每个计划的使用次数（基于 records 中出现的 sourcePlanId）
  final useCount = <String, int>{};
  for (final r in records) {
    final planId = r['planId'] as String? ?? r['sourcePlanId'] as String?;
    if (planId != null) {
      useCount[planId] = (useCount[planId] ?? 0) + 1;
    }
  }
  
  final now = DateTime.now().millisecondsSinceEpoch;
  final scored = customPlans.map((p) {
    final planId = p['id'] as String;
    final createTime = (p['createTime'] as num?)?.toInt() ?? now;
    final daysSinceCreated = ((now - createTime) / (24 * 60 * 60 * 1000)).clamp(0, 365);
    // 创建时间越近分数越高（归一化到 0-30）
    final timeScore = (30 * (1 - daysSinceCreated / 365)).clamp(0, 30);
    // 使用次数归一化到 0-70
    final count = useCount[planId] ?? 0;
    final maxCount = useCount.values.fold(0, (a, b) => a > b ? a : b);
    final useScore = maxCount > 0 ? (70 * count / maxCount) : 0.0;
    return {'plan': p, 'score': timeScore + useScore};
  }).toList();
  
  scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  return scored.map((e) => e['plan'] as Map<String, dynamic>).toList();
}
```

- [ ] **Step 4: 添加推荐计划区段构建方法**

```dart
Widget _buildRecommendedSection() {
  if (!SystemPlanLibrary.instance.isLoaded) {
    return const SizedBox.shrink();
  }
  final recommendations = PlanRecommendationService.instance.recommend(limit: 3);
  if (recommendations.isEmpty) return const SizedBox.shrink();
  
  final ft = Theme.of(context).extension<FitTrackColors>()!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Text(
              '为你推荐',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/plan-library'),
              child: Row(
                children: [
                  Text(
                    '全部系统计划',
                    style: TextStyle(color: ft.purpleColor, fontSize: 13),
                  ),
                  Icon(Icons.chevron_right, color: ft.purpleColor, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      ...recommendations.map((r) => _buildRecommendationCard(r, ft)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/plan-library'),
            icon: const Icon(Icons.library_books),
            label: const Text('浏览系统计划库'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ft.purpleColor,
              side: BorderSide(color: ft.purpleColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildRecommendationCard(PlanRecommendation rec, FitTrackColors ft) {
  final plan = rec.plan;
  final isUnlocked = !plan.isPremium ||
      PlanUnlockService.instance.isPlanUnlocked(plan.id);
  return GestureDetector(
    onTap: () => context.go('/plan-library/detail/${plan.id}'),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: plan.coverColors
                    .map((c) => Color(int.parse(c.substring(1), radix: 16) | 0xFF000000))
                    .toList(),
              ),
            ),
            child: Center(
              child: Text(plan.coverEmoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          color: ft.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (plan.isPremium && !isUnlocked)
                      Icon(Icons.lock, size: 14, color: ft.warningColor),
                  ],
                ),
                const SizedBox(height: 4),
                if (rec.reasons.isNotEmpty)
                  Text(
                    rec.reasons.first,
                    style: TextStyle(color: ft.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 匹配度
          Column(
            children: [
              Text(
                '${rec.score.toInt()}%',
                style: TextStyle(
                  color: ft.successColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('匹配', style: TextStyle(color: ft.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 5: 修改主构建方法**

在 `_buildPlanList` 或主页 `build` 方法中，按以下顺序构建：
1. 当前训练计划区段（现有 active 计划，保持不变）
2. 自定义计划 Top 3（新算法）
3. 推荐计划区段（始终展示）

在原 `if (_plans.isEmpty) return _buildRecommendedPlans();` 处改为三段式：
```dart
// 移除原 _plans.isEmpty 的特殊处理，改为始终按顺序构建
```

具体修改：
- 在原"当前计划"区段之后，添加"自定义计划 Top 3"区段
- 在"自定义计划 Top 3"之后，添加"推荐计划"区段（不再依赖 `_plans.isEmpty`）

- [ ] **Step 6: 验证无错误**

Run: `flutter analyze lib/pages/plan_page.dart`
Expected: 无错误

- [ ] **Step 7: 提交**

```bash
git add lib/pages/plan_page.dart
git commit -m "feat: refactor plan_page to three-section layout"
```

---

## Task 11: 扩展 RecommendationService 增加 plan banner

**Files:**
- Modify: `lib/services/recommendation_service.dart`

**Interfaces:**
- Consumes: `PlanRecommendationService.instance.recommend(limit: 1)` 返回 `List<PlanRecommendation>`
- Produces: `BannerItem(type: 'plan', ...)` 新类型

- [ ] **Step 1: 读取 recommendation_service.dart**

读取现有代码，找到 `generateBanners()` 方法和 `BannerItem` 类定义。

- [ ] **Step 2: 在 BannerItem 中允许 'plan' 类型，并在 generateBanners() 中添加 plan banner**

在 `generateBanners()` 方法中（建议在成就挑战 banner 之前）添加：

```dart
// 训练计划推荐 banner
if (SystemPlanLibrary.instance.isLoaded) {
  final planRecs = PlanRecommendationService.instance.recommend(limit: 1);
  if (planRecs.isNotEmpty) {
    final rec = planRecs.first;
    banners.add(BannerItem(
      type: 'plan',
      title: '推荐计划：${rec.plan.name}',
      subtitle: rec.reasons.isNotEmpty ? rec.reasons.first : '为你智能推荐',
      icon: 'fitness_center',
      route: '/plan-library/detail/${rec.plan.id}',
      extra: {'planId': rec.plan.id, 'score': rec.score},
    ));
  }
}
```

文件顶部添加 import：
```dart
import 'plan_recommendation_service.dart';
import '../data/system_plan_library.dart';
```

- [ ] **Step 3: 验证无错误**

Run: `flutter analyze lib/services/recommendation_service.dart`
Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/services/recommendation_service.dart
git commit -m "feat: add plan recommendation banner type"
```

---

## Task 12: home_page.dart 接收 plan banner

**Files:**
- Modify: `lib/pages/home_page.dart`

**Interfaces:**
- Consumes: `BannerItem(type: 'plan', route: '/plan-library/detail/:planId')`

- [ ] **Step 1: 读取 home_page.dart 找到 banner 处理逻辑**

读取 `lib/pages/home_page.dart`，找到 banner 点击处理或类型分支逻辑。

- [ ] **Step 2: 在 banner 类型分支中添加 'plan' 处理**

通常现有代码会有 `switch (banner.type)` 或 `if (banner.type == 'teaching')` 等分支。添加：

```dart
if (banner.type == 'plan') {
  context.go(banner.route);  // 路由已是 /plan-library/detail/:planId
  return;
}
```

如果 banner 卡片 UI 渲染逻辑也按类型分支，需要为 'plan' 添加对应图标/颜色样式（通常用 fitness_center 图标 + purpleColor 主题色）。

- [ ] **Step 3: 验证无错误**

Run: `flutter analyze lib/pages/home_page.dart`
Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/pages/home_page.dart
git commit -m "feat: handle plan banner type in home_page"
```

---

## Task 13: 改造 questionnaire_page 推荐数据源

**Files:**
- Modify: `lib/pages/questionnaire_page.dart`

**Interfaces:**
- Consumes: `SystemPlanLibrary.instance.getByGoalAndDifficulty(goal, difficulty)`
- Consumes: `PlanRecommendationService.instance.recommend()`

- [ ] **Step 1: 读取 questionnaire_page.dart 找到跳转推荐页的逻辑**

读取 `lib/pages/questionnaire_page.dart`，找到 `_complete()` 方法和跳转到 `PlanRecommendPage` 的位置。

- [ ] **Step 2: 修改跳转逻辑**

`_complete()` 中保存 settings/bodyData 后，应跳转到 `PlanRecommendPage`。该页面（Task 14 中改造）会自动从系统计划库获取推荐数据。

如果当前是直接调用 `_generateRecommendations()` 硬编码生成，需要改为依赖 `PlanRecommendPage` 内部从系统计划库获取。

通常改动较小，主要是确保跳转时携带的 `profileData` 完整（包含 fitnessGoal/fitnessLevel/trainingFrequency/bodyData），让 `PlanRecommendPage` 能正确调用推荐服务。

- [ ] **Step 3: 验证无错误**

Run: `flutter analyze lib/pages/questionnaire_page.dart`
Expected: 无错误

- [ ] **Step 4: 提交**

```bash
git add lib/pages/questionnaire_page.dart
git commit -m "refactor: questionnaire hands off to PlanRecommendPage with system library"
```

---

## Task 14: 改造 plan_recommend_page 推荐数据源

**Files:**
- Modify: `lib/pages/plan_recommend_page.dart`

**Interfaces:**
- Consumes: `PlanRecommendationService.instance.recommend(limit: 5)` 返回 `List<PlanRecommendation>`
- Consumes: `SystemPlan.toStoragePlan()` 转换方法

- [ ] **Step 1: 读取 plan_recommend_page.dart 找到推荐生成逻辑**

读取 `lib/pages/plan_recommend_page.dart`，重点关注 `_generateRecommendations()` 方法和 `_reorderByBodyData()` 方法。

- [ ] **Step 2: 用 PlanRecommendationService 替换硬编码推荐**

将 `_generateRecommendations()` 方法替换为：

```dart
List<PlanRecommendation> _generateRecommendations() {
  if (!SystemPlanLibrary.instance.isLoaded) return [];
  return PlanRecommendationService.instance.recommend(limit: 5);
}
```

删除 `_reorderByBodyData()` 方法（评分逻辑已统一到 `PlanRecommendationService`）。
删除 5 个硬编码训练日模板（`_fiveDaySplitDays` / `_threeDaySplitDays` / `_hiitDays` / `_shapingDays` / `_fullBodyDays`）。

- [ ] **Step 3: 修改 UI 适配 PlanRecommendation 数据结构**

UI 中原来展示 plan 数据的地方需要改为展示 `PlanRecommendation.plan`，并可以新增显示：
- `PlanRecommendation.score`（匹配度）
- `PlanRecommendation.reasons`（推荐理由，作为副标题）

- [ ] **Step 4: 修改 _selectPlan() 使用 toStoragePlan()**

```dart
Future<void> _selectPlan(PlanRecommendation rec) async {
  // 暂停现有 active 计划
  final existingPlans = Storage.getPlans();
  for (final p in existingPlans) {
    if (p['status'] == 'active') {
      Storage.updatePlan(p['id'] as String, {'status': 'paused'});
    }
  }
  
  // 检查是否为精品计划且未解锁
  if (rec.plan.isPremium && !PlanUnlockService.instance.isPlanUnlocked(rec.plan.id)) {
    // 跳转到详情页让用户解锁
    if (!mounted) return;
    context.go('/plan-library/detail/${rec.plan.id}');
    return;
  }
  
  // 添加新计划
  final newPlan = rec.plan.toStoragePlan();
  Storage.addPlan(newPlan);
  Storage.dataChanged.value = !Storage.dataChanged.value;
  
  widget.onComplete();
}
```

- [ ] **Step 5: 添加 import**

```dart
import '../services/plan_recommendation_service.dart';
import '../services/plan_unlock_service.dart';
import '../data/system_plan_library.dart';
```

- [ ] **Step 6: 验证无错误**

Run: `flutter analyze lib/pages/plan_recommend_page.dart`
Expected: 无错误

- [ ] **Step 7: 提交**

```bash
git add lib/pages/plan_recommend_page.dart
git commit -m "refactor: plan_recommend_page uses system library via PlanRecommendationService"
```

---

## Task 15: 改造 add_plan_page 推荐数据源

**Files:**
- Modify: `lib/pages/add_plan_page.dart`

**Interfaces:**
- Consumes: `PlanRecommendationService.instance.recommend(limit: 3)`

- [ ] **Step 1: 读取 add_plan_page.dart 找到推荐逻辑**

读取 `lib/pages/add_plan_page.dart`，找到 `_generateRecommendedPlans()` 方法和顶部推荐展示 UI。

- [ ] **Step 2: 替换硬编码推荐为系统计划库推荐**

将 `_generateRecommendedPlans()` 替换为：

```dart
List<PlanRecommendation> _generateRecommendedPlans() {
  if (!SystemPlanLibrary.instance.isLoaded) return [];
  return PlanRecommendationService.instance.recommend(limit: 3);
}
```

- [ ] **Step 3: 修改 UI 适配新数据结构**

将原展示 plan 数据的地方改为展示 `PlanRecommendation.plan`。点击推荐卡片跳转到 `/plan-library/detail/:planId` 而非直接采用。

- [ ] **Step 4: 添加 import 并删除冗余模板代码**

```dart
import '../services/plan_recommendation_service.dart';
import '../data/system_plan_library.dart';
```

可以删除 `_quickSetup` 副本（与 plan_page.dart 中重复的硬编码模板），改为从系统计划库引用。

- [ ] **Step 5: 验证无错误**

Run: `flutter analyze lib/pages/add_plan_page.dart`
Expected: 无错误

- [ ] **Step 6: 提交**

```bash
git add lib/pages/add_plan_page.dart
git commit -m "refactor: add_plan_page uses system library recommendations"
```

---

## Task 16: 端到端验证

**Files:** 无文件修改，仅运行验证

- [ ] **Step 1: flutter analyze 全项目**

Run: `flutter analyze lib/`
Expected: 0 errors

- [ ] **Step 2: flutter run 启动应用**

Run: `flutter run -d windows`
Expected: 应用正常启动，控制台输出 "SystemPlanLibrary: 已加载 N 个系统计划"

- [ ] **Step 3: 手动验证页面流转**

1. 进入 plan tab → 看到三段式布局（当前/自定义/推荐）
2. 点击"浏览系统计划库" → 进入 `/plan-library` → 看到 5 个目标卡片
3. 点击"增肌" → 进入 `/plan-library/bulk` → 看到筛选+计划列表
4. 点击一个免费计划 → 进入详情页 → 点击"采用此计划" → 返回 plan tab 看到新计划
5. 点击一个精品计划 → 进入详情页 → 点击"支付 N 积分解锁" → 弹出 SnackBar → 按钮变为"采用此计划"
6. 返回 home_page → 检查 banner 区域是否出现"推荐计划"类型 banner
7. 完成一次问卷 → 检查推荐页是否显示来自系统计划库的计划

- [ ] **Step 4: 验证解锁过期逻辑（可选，模拟）**

在 `PlanUnlockService` 中临时把 `_validityMs` 改为 1 秒，验证过期后再次进入详情页是否提示重新支付。验证完成后改回 90 天。

- [ ] **Step 5: 提交最终状态**

```bash
git add -A
git commit -m "chore: end-to-end verification of plan library system"
```

---

## 总结

| Task | 内容 | 依赖 |
|------|------|------|
| 1 | SystemPlan 数据类 + 加载器 | 无 |
| 2 | 5 个 JSON 种子数据（subagent 并行生成） | Task 1 |
| 3 | PlanUnlockService 解锁服务 | Task 1 |
| 4 | PlanRecommendationService 推荐算法 | Task 1 |
| 5 | main.dart 启动加载 | Task 1 |
| 6 | PlanLibraryHomePage 瀑布流首页 | Task 1 |
| 7 | PlanLibraryCategoryPage 子类页 | Task 1, 3 |
| 8 | PlanLibraryDetailPage 详情页 | Task 1, 3 |
| 9 | 注册 3 条路由 | Task 6, 7, 8 |
| 10 | plan_page 三段式改造 | Task 4, 9 |
| 11 | RecommendationService 扩展 banner | Task 4 |
| 12 | home_page 接收 plan banner | Task 11 |
| 13 | questionnaire_page 改用系统库 | Task 4, 14 |
| 14 | plan_recommend_page 改用系统库 | Task 4 |
| 15 | add_plan_page 改用系统库 | Task 4 |
| 16 | 端到端验证 | 所有 |

**关键并行机会：**
- Task 1 完成后，Task 2 / 3 / 4 可并行
- Task 6 / 7 / 8 可在 Task 1 完成后并行（7/8 依赖 Task 3）
- Task 13 / 14 / 15 可在 Task 4 完成后并行
