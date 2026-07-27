# 用户增长与留存体系重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构 FitTrack 的留存/裂变体系——建立虚拟物品价格表、邀请奖励积分化、教学分章节改造、对手功能 P0 完善、推荐免费优先、修复邀请页对齐。

**Architecture:** 6 个独立子项目按依赖顺序实施（D→G→B→E→C→F）。新建 `virtual_goods.dart` 作为基础数据层，复用现有 `UnlockPanel`、`Storage`、`PointsService`。

**Tech Stack:** Flutter 3.7.12 / Dart 2.19.6 / go_router / SharedPreferences

## Global Constraints

- Dart SDK: `>=2.19.6 <3.0.0`（禁用 Dart 3 records 语法）
- 路由：go_router，使用 `state.params` 而非 `state.pathParameters`
- 存储：`Storage.getSettings()` 返回 `Map<String, dynamic>`，`Storage.saveSettings(map)` 持久化
- 颜色：所有 UI 颜色从 `Theme.of(context).extension<FitTrackColors>()!` 获取，禁用自定义色值
- `unlockedFeatures` 字段是 JSON-encoded String（非 List），通过 `PointsService.isFeatureUnlocked(id)` 查询、`unlockFeature(id, cost)` 写入
- 平台判断用 `utils/platform_utils.dart` 的 `isOhos` getter（不要用 `Platform.isOhos`）

参考 spec：[docs/superpowers/specs/2026-07-27-profile-invite-tutorial-opponent-design.md](file:///d:/app/projects/health_training/docs/superpowers/specs/2026-07-27-profile-invite-tutorial-opponent-design.md)

---

## Task 1: 子项目 D — 新建虚拟物品价格表

**Files:**
- Create: `fittrack_flutter/lib/data/virtual_goods.dart`
- Test: `fittrack_flutter/test/virtual_goods_test.dart`

**Interfaces:**
- Produces: `class VirtualGood`、`enum GoodCategory`、`class VirtualGoodsStore`（含静态方法 `byId(String) -> VirtualGood?`、`byCategory(GoodCategory) -> List<VirtualGood>`、`affordableWith(int) -> List<VirtualGood>`、`isUnlocked(String) -> bool`、`unlock(String) -> Future<bool>`）

- [ ] **Step 1: 写失败测试**

创建 `fittrack_flutter/test/virtual_goods_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/data/virtual_goods.dart';

void main() {
  group('VirtualGoodsStore', () {
    test('byId 返回已知商品', () {
      expect(VirtualGoodsStore.byId('skin_iron_warrior')?.name, '钢铁战士');
      expect(VirtualGoodsStore.byId('skin_ambassador')?.isLimited, true);
    });

    test('byId 未知 id 返回 null', () {
      expect(VirtualGoodsStore.byId('not_exist'), isNull);
    });

    test('byCategory 过滤对手皮肤', () {
      final skins = VirtualGoodsStore.byCategory(GoodCategory.opponentSkin);
      expect(skins.length, 4);
      expect(skins.every((g) => g.category == GoodCategory.opponentSkin), true);
    });

    test('affordableWith 返回可负担商品（限定款排除）', () {
      final list = VirtualGoodsStore.affordableWith(300);
      // 300 积分可购买入门款(100)和标准款(300)，不可购买精品款(600)/典藏款(1200)
      // 限定款 skin_ambassador 永远不可纯积分购买
      expect(list.any((g) => g.id == 'skin_beginner'), true);
      expect(list.any((g) => g.id == 'skin_iron_warrior'), true);
      expect(list.any((g) => g.id == 'skin_cyber_ninja'), false);
      expect(list.any((g) => g.id == 'skin_ambassador'), false);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/virtual_goods_test.dart`
Expected: FAIL with "fittrack/data/virtual_goods.dart" not found

- [ ] **Step 3: 实现 virtual_goods.dart**

创建 `fittrack_flutter/lib/data/virtual_goods.dart`：

```dart
import 'dart:convert';
import 'storage.dart';

/// 虚拟物品类别
enum GoodCategory {
  opponentSkin, // 对手皮肤
  badge,        // 徽章
  avatarFrame,  // 头像框
  title,        // 称号
}

/// 虚拟物品数据模型
class VirtualGood {
  final String id;
  final String name;
  final GoodCategory category;
  final int pointsCost;
  final String emoji;
  final String? unlockCondition; // 非空表示不可纯积分购买（需通过里程碑解锁）
  final bool isLimited;
  final Map<String, dynamic>? metadata;

  const VirtualGood({
    required this.id,
    required this.name,
    required this.category,
    required this.pointsCost,
    required this.emoji,
    this.unlockCondition,
    this.isLimited = false,
    this.metadata,
  });

  /// 是否可纯积分购买（false 表示需通过里程碑解锁）
  bool get isPurchasableWithPoints => unlockCondition == null;
}

/// 虚拟物品价格表与查询
class VirtualGoodsStore {
  VirtualGoodsStore._();

  /// 全部商品清单
  static const List<VirtualGood> kAllGoods = [
    // ── 对手皮肤 ──
    VirtualGood(
      id: 'skin_beginner',
      name: '健身小白',
      category: GoodCategory.opponentSkin,
      pointsCost: 100,
      emoji: '🐣',
    ),
    VirtualGood(
      id: 'skin_iron_warrior',
      name: '钢铁战士',
      category: GoodCategory.opponentSkin,
      pointsCost: 300,
      emoji: '🤖',
    ),
    VirtualGood(
      id: 'skin_cyber_ninja',
      name: '赛博忍者',
      category: GoodCategory.opponentSkin,
      pointsCost: 600,
      emoji: '🥷',
    ),
    VirtualGood(
      id: 'skin_ambassador',
      name: '燃力大使',
      category: GoodCategory.opponentSkin,
      pointsCost: 1200,
      emoji: '👑',
      unlockCondition: '累计邀请 5 人',
      isLimited: true,
    ),
    // ── 徽章 ──
    VirtualGood(
      id: 'badge_standard',
      name: '标准徽章',
      category: GoodCategory.badge,
      pointsCost: 300,
      emoji: '🏅',
    ),
    // ── 头像框 ──
    VirtualGood(
      id: 'frame_basic',
      name: '基础头像框',
      category: GoodCategory.avatarFrame,
      pointsCost: 100,
      emoji: '🖼️',
    ),
    VirtualGood(
      id: 'frame_premium',
      name: '精品头像框',
      category: GoodCategory.avatarFrame,
      pointsCost: 600,
      emoji: '🖼️',
    ),
    // ── 称号 ──
    VirtualGood(
      id: 'title_ambassador',
      name: '燃力大使称号',
      category: GoodCategory.title,
      pointsCost: 1200,
      emoji: '🎖️',
      unlockCondition: '累计邀请 10 人',
      isLimited: true,
    ),
  ];

  /// 按 id 查询
  static VirtualGood? byId(String id) {
    for (final g in kAllGoods) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// 按类别查询
  static List<VirtualGood> byCategory(GoodCategory c) {
    return kAllGoods.where((g) => g.category == c).toList();
  }

  /// 查询当前积分可负担的商品（限定款/里程碑款排除）
  static List<VirtualGood> affordableWith(int points) {
    return kAllGoods.where((g) {
      if (!g.isPurchasableWithPoints) return false;
      return g.pointsCost <= points;
    }).toList();
  }

  /// 查询物品是否已解锁
  /// key 约定：`good_<id>`（如 `good_skin_iron_warrior`）
  static bool isUnlocked(String goodId) {
    final settings = Storage.getSettings();
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.contains('good_$goodId');
    } catch (_) {
      return false;
    }
  }

  /// 解锁物品（积分购买）—— 仅可购买 isPurchasableWithPoints=true 的物品
  /// 返回是否解锁成功（积分不足或不可购买时返回 false）
  static Future<bool> unlock(String goodId) async {
    final good = byId(goodId);
    if (good == null || !good.isPurchasableWithPoints) return false;
    if (isUnlocked(goodId)) return true;

    final settings = Storage.getSettings();
    final current = settings['points'] as int? ?? 0;
    if (current < good.pointsCost) return false;

    // 扣减积分
    settings['points'] = current - good.pointsCost;
    final spent = settings['pointsSpentTotal'] as int? ?? 0;
    settings['pointsSpentTotal'] = spent + good.pointsCost;

    // 写入解锁列表
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    final list = (jsonDecode(raw) as List).cast<String>();
    list.add('good_$goodId');
    settings['unlockedFeatures'] = jsonEncode(list);

    // 写入积分日志
    final logRaw = settings['pointsLog'] as String? ?? '[]';
    final logs = (jsonDecode(logRaw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    logs.insert(0, {
      'time': DateTime.now().millisecondsSinceEpoch,
      'delta': -good.pointsCost,
      'source': 'unlock_good_$goodId',
      'balance': current - good.pointsCost,
    });
    if (logs.length > 50) logs.removeRange(50, logs.length);
    settings['pointsLog'] = jsonEncode(logs);

    Storage.saveSettings(settings);
    Storage.dataChanged.value = !Storage.dataChanged.value;
    return true;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/virtual_goods_test.dart`
Expected: PASS（4 个测试）

- [ ] **Step 5: 提交**

```bash
cd fittrack_flutter
git add lib/data/virtual_goods.dart test/virtual_goods_test.dart
git commit -m "feat: 新建虚拟物品价格表（子项目D）"
```

---

## Task 2: 子项目 G — 邀请流程卡片纵向对齐修复

**Files:**
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart:565-601`

**Interfaces:**
- 无新接口；纯 UI 修复

- [ ] **Step 1: 修改 invitation_page.dart 流程卡 Row 对齐**

替换 [invitation_page.dart:565-601](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/invitation_page.dart#L565-L601) 的 `Row(...)` 整段：

```dart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isLast = idx == steps.length - 1;
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s.icon, color: colors.accentGlow, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(s.title, style: TextStyle(
                            color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600,
                          ), textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Text(s.desc, style: TextStyle(
                            color: colors.textMuted, fontSize: 10,
                          ), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (!isLast)
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
```

- [ ] **Step 2: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/pages/invitation_page.dart`
Expected: No issues found

- [ ] **Step 3: 提交**

```bash
cd fittrack_flutter
git add lib/pages/invitation_page.dart
git commit -m "fix: 修复邀请流程卡片纵向对齐（子项目G）"
```

---

## Task 3: 子项目 B — 引导页推荐计划免费优先

**Files:**
- Modify: `fittrack_flutter/lib/services/plan_recommendation_service.dart:80-82`
- Test: `fittrack_flutter/test/plan_recommendation_service_test.dart`

**Interfaces:**
- 无新接口；修改 `recommend()` 内部 sort 逻辑

- [ ] **Step 1: 写失败测试**

创建 `fittrack_flutter/test/plan_recommendation_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/services/plan_recommendation_service.dart';
import 'package:fittrack/data/system_plan_library.dart';

void main() {
  group('PlanRecommendationService 免费优先排序', () {
    // 此测试通过构造两个 score 相近但 isPremium 不同的推荐结果，
    // 验证同段内免费计划排前
    test('同段内免费计划应排在付费计划前', () {
      // 构造 mock 推荐列表（score 差 ≤ 5）
      final mockRecommendations = <PlanRecommendation>[
        PlanRecommendation(
          plan: _MockSystemPlan(id: 'paid_a', isPremium: true),
          score: 80.0,
          reasons: [],
        ),
        PlanRecommendation(
          plan: _MockSystemPlan(id: 'free_a', isPremium: false),
          score: 78.0,
          reasons: [],
        ),
        PlanRecommendation(
          plan: _MockSystemPlan(id: 'paid_b', isPremium: true),
          score: 95.0, // 高分段，应排在最前
          reasons: [],
        ),
      ];

      // 调用排序工具方法（暴露为静态方法供测试）
      final sorted = PlanRecommendationService.sortWithFreePriority(mockRecommendations);

      // 验证顺序：高分付费(95) → 同段免费(78) → 同段付费(80) 不能出现
      // 95 高于 80/78 段差5以上，应在最前
      // 78 和 80 段差 ≤ 5，同段内免费(78) 应在付费(80) 前
      expect(sorted[0].plan.id, 'paid_b');
      expect(sorted[1].plan.id, 'free_a');
      expect(sorted[2].plan.id, 'paid_a');
    });
  });
}

// 简化的 Mock SystemPlan，仅含排序所需字段
class _MockSystemPlan implements SystemPlan {
  @override final String id;
  @override final bool isPremium;
  _MockSystemPlan({required this.id, required this.isPremium});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/plan_recommendation_service_test.dart`
Expected: FAIL with "sortWithFreePriority 方法未定义"

- [ ] **Step 3: 在 PlanRecommendationService 添加静态排序方法**

修改 [plan_recommendation_service.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/services/plan_recommendation_service.dart)：

**3a. 在 `recommend()` 方法内（第 80-82 行）替换 sort 调用：**

```dart
    // 3. 排序+截断
    final sorted = sortWithFreePriority(scored);
    return sorted.take(limit).toList();
```

**3b. 在 `PlanRecommendationService` 类内（`recommend` 方法之后、`_scorePlan` 之前）添加静态排序方法：**

```dart
  /// 排序：同段内免费优先
  /// 同段判定：score 差 ≤ 5 视为同段
  static List<PlanRecommendation> sortWithFreePriority(
    List<PlanRecommendation> scored,
  ) {
    final list = List<PlanRecommendation>.from(scored);
    list.sort((a, b) {
      final scoreDiff = b.score.compareTo(a.score);
      // 不同段：按 score 降序
      if ((b.score - a.score).abs() > 5) return scoreDiff;
      // 同段：免费（isPremium=false）排前
      final aPremium = a.plan.isPremium ? 1 : 0;
      final bPremium = b.plan.isPremium ? 1 : 0;
      if (aPremium != bPremium) return aPremium.compareTo(bPremium);
      // 同段同付费状态：按 score 降序
      return scoreDiff;
    });
    return list;
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/plan_recommendation_service_test.dart`
Expected: PASS

- [ ] **Step 5: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/services/plan_recommendation_service.dart`
Expected: No issues found

- [ ] **Step 6: 提交**

```bash
cd fittrack_flutter
git add lib/services/plan_recommendation_service.dart test/plan_recommendation_service_test.dart
git commit -m "feat: 引导页推荐计划同段内免费优先排序（子项目B）"
```

---

## Task 4: 子项目 E - 数据层 — Tutorial 增加 chapters 字段

**Files:**
- Modify: `fittrack_flutter/lib/data/tutorial_content.dart:123-201`（Tutorial 类）
- Test: `fittrack_flutter/test/tutorial_chapters_test.dart`

**Interfaces:**
- Produces: `Tutorial.chapters` 字段（`List<Chapter>`），`Chapter` 复用自 `course_content.dart`
- Produces: `Tutorial.chapterPointsCost` getter（按 type 返回 50/80/120/0）

- [ ] **Step 1: 写失败测试**

创建 `fittrack_flutter/test/tutorial_chapters_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/data/tutorial_content.dart';
import 'package:fittrack/data/course_content.dart';

void main() {
  group('Tutorial chapters', () {
    test('非 basic 类型应有 chapters 列表', () {
      final t = TutorialLibrary.basicTutorials.first;
      // basic 类型也应能产生 chapters（虽然不强制解锁）
      expect(t.chapters.length, greaterThan(0));
    });

    test('chapters 应包含 3 章', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.chapters.length, 3);
      expect(t.chapters[0].title, '动作要领');
      expect(t.chapters[1].title, '常见错误');
      expect(t.chapters[2].title, '呼吸与变式');
    });

    test('chapterPointsCost 按 type 返回正确价格', () {
      // 找一个 advanced 类型的 tutorial
      final advanced = TutorialLibrary.allTutorials.firstWhere(
        (t) => t.type == TutorialType.advanced,
        orElse: () => TutorialLibrary.basicTutorials.first,
      );
      if (advanced.type == TutorialType.advanced) {
        expect(advanced.chapterPointsCost, 50);
      }
    });

    test('basic 类型 chapterPointsCost 为 0', () {
      final basic = TutorialLibrary.basicTutorials.first;
      expect(basic.chapterPointsCost, 0);
    });

    test('chapter featureId 格式正确', () {
      final t = TutorialLibrary.basicTutorials.first;
      final chapterId = t.chapters[0].id;
      expect(t.chapterFeatureId(chapterId), 'tutorial_${t.id}_chapter_$chapterId');
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/tutorial_chapters_test.dart`
Expected: FAIL with "chapters getter 未定义"

- [ ] **Step 3: 修改 Tutorial 类**

修改 [tutorial_content.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/tutorial_content.dart)：

**3a. 在文件顶部新增 import：**

```dart
import 'course_content.dart'; // 复用 Chapter 类
```

**3b. 在 Tutorial 类的 `blocks` 字段之后（第 156 行后）新增 `chapters` 字段：**

```dart
  final List<ContentBlock> blocks; // 富文本块（预留字段，当前未使用）

  /// 章节列表（v1.3 引入）：将 keyPoints/commonMistakes/breathingTip 拆为 3 章
  /// UI 优先读 chapters，fallback 读旧字段
  final List<Chapter> chapters;
```

**3c. 在构造函数（第 158-178 行）增加 `chapters` 参数：**

```dart
  const Tutorial({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.primaryMuscle,
    this.equipment,
    this.avatarAsset,
    required this.keyPoints,
    required this.commonMistakes,
    this.alternativeExerciseIds = const [],
    required this.coachName,
    this.breathingTip,
    this.unlockRequirement,
    this.goal = FitnessGoal.bulk,
    this.contentType = ContentType.exercise,
    this.coverColors = const [Color(0xFFFF6B35), Color(0xFFFFD700)],
    this.recommendedExerciseIds = const [],
    this.coverEmoji,
    this.blocks = const [],
    this.chapters = const [], // 新增
  });
```

**3d. 在类底部（`toJson` 方法之前）新增章节相关 getter 和方法：**

```dart
  /// 按章节积分解锁价格（basic=0，advanced=50，topic=80，master=120）
  int get chapterPointsCost {
    switch (type) {
      case TutorialType.basic:
        return 0;
      case TutorialType.advanced:
        return 50;
      case TutorialType.topic:
        return 80;
      case TutorialType.master:
        return 120;
    }
  }

  /// 单章 featureId
  String chapterFeatureId(String chapterId) {
    return 'tutorial_${id}_chapter_$chapterId';
  }

  /// 整套 featureId
  String get allChaptersFeatureId => 'tutorial_${id}_all';

  /// 章节是否已解锁
  bool isChapterUnlocked(String chapterId) {
    if (type == TutorialType.basic) return true;
    // 整套已解锁 → 所有章节免费
    if (PointsService.instance.isFeatureUnlocked(allChaptersFeatureId)) return true;
    return PointsService.instance.isFeatureUnlocked(chapterFeatureId(chapterId));
  }
```

**3e. 新增 PointsService import（在文件顶部）：**

```dart
import '../services/points_service.dart';
```

**3f. 在 TutorialLibrary 类内新增 `allTutorials` getter 和 `chaptersFor` 静态方法（用于把现有字段转 chapters）：**

在 TutorialLibrary 类定义中找到 `basicTutorials` 字段，在其下方添加：

```dart
  /// 把现有 Tutorial 字段转换为 3 章节
  /// 此方法用于给已有 Tutorial 实例填充 chapters
  static List<Chapter> chaptersFor(Tutorial t) {
    return [
      Chapter(
        id: 'keypoints',
        title: '动作要领',
        content: t.keyPoints.join('\n'),
        blocks: t.keyPoints.map((p) => ContentBlock.bulletList(p)).toList(),
      ),
      Chapter(
        id: 'mistakes',
        title: '常见错误',
        content: t.commonMistakes.join('\n'),
        blocks: t.commonMistakes.map((p) => ContentBlock.callout(p, 'warning')).toList(),
      ),
      Chapter(
        id: 'breathing',
        title: '呼吸与变式',
        content: t.breathingTip ?? '保持自然呼吸，发力时呼气，还原时吸气',
        blocks: [
          if (t.breathingTip != null)
            ContentBlock.paragraph(t.breathingTip!),
          if (t.alternativeExerciseIds.isNotEmpty)
            ContentBlock.paragraph('替代动作：${t.alternativeExerciseIds.join(", ")}'),
        ],
      ),
    ];
  }
```

**3g. 由于现有 `const Tutorial(...)` 构造函数要求 `chapters` 是 const，但 `chaptersFor` 生成的是运行时列表，需要修改所有 Tutorial 定义的方式。**

为避免改动所有 30+ 个 Tutorial 定义，采用 getter fallback 方案：

**修改 Step 3d 的 isChapterUnlocked 之前的代码**，把 `final List<Chapter> chapters;` 字段改为 getter：

```dart
  // 删除字段：final List<Chapter> chapters;
  // 改为 getter：
  List<Chapter> get chapters => TutorialLibrary.chaptersFor(this);
```

**移除构造函数中的 `this.chapters = const []` 参数。**

**3h. 在 TutorialLibrary 类中添加 allTutorials getter：**

在 `TutorialLibrary` 类内查找现有定义，添加：

```dart
  /// 所有教学合集
  static List<Tutorial> get allTutorials => [
    ...basicTutorials,
    ...advancedTutorials,
    ...topicTutorials,
    ...masterTutorials,
  ];
```

> ⚠️ 注意：如果 TutorialLibrary 中没有 `advancedTutorials`/`topicTutorials`/`masterTutorials` 字段，需要先确认这些列表的实际名称（可能是 `advancedTutorialList` 或别的）。运行 `grep -n "static const List<Tutorial>" lib/data/tutorial_content.dart` 查找实际名称并相应调整。

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/tutorial_chapters_test.dart`
Expected: PASS（5 个测试）

- [ ] **Step 5: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/data/tutorial_content.dart`
Expected: No issues found

- [ ] **Step 6: 提交**

```bash
cd fittrack_flutter
git add lib/data/tutorial_content.dart test/tutorial_chapters_test.dart
git commit -m "feat: Tutorial 增加 chapters 字段和章节解锁方法（子项目E数据层）"
```

---

## Task 5: 子项目 E - UI 层 — Tutorial 详情页按章节渲染

**Files:**
- Modify: `fittrack_flutter/lib/pages/tutorial_detail_page.dart:53-99`（build 方法）和 `:488-537`（_buildBottomBar）

**Interfaces:**
- Consumes: `Tutorial.chapters`、`Tutorial.chapterPointsCost`、`Tutorial.isChapterUnlocked(chapterId)`、`Tutorial.chapterFeatureId(chapterId)`、`Tutorial.allChaptersFeatureId`
- Consumes: `UnlockPanel.show()`（来自 `lib/widgets/unlock_panel.dart`）

- [ ] **Step 1: 修改 tutorial_detail_page.dart 顶部 import**

在文件顶部添加 import：

```dart
import '../widgets/unlock_panel.dart';
import '../services/points_service.dart';
```

- [ ] **Step 2: 替换 build 方法中的内容渲染部分**

将 [tutorial_detail_page.dart:62-94](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/tutorial_detail_page.dart#L62-L94) 中 `Expanded(child: SingleChildScrollView(...))` 内的 Column children 替换为：

```dart
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaCard(colors, tutorial),
                  const SizedBox(height: 16),
                  // 按章节渲染（替代旧的 keyPoints/mistakes/breathing 卡片）
                  ...tutorial.chapters.map((ch) => _buildChapterCard(colors, tutorial, ch, context)),
                  const SizedBox(height: 16),
                  if (tutorial.recommendedExerciseIds.isNotEmpty) ...[
                    _buildRecommendedExercisesCard(colors, tutorial, context),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
```

- [ ] **Step 3: 新增 _buildChapterCard 方法**

在 TutorialDetailPage 类内（建议放在 `_buildMetaCard` 之后）添加：

```dart
  Widget _buildChapterCard(
    FitTrackColors colors,
    Tutorial tutorial,
    Chapter chapter,
    BuildContext context,
  ) {
    final isUnlocked = tutorial.isChapterUnlocked(chapter.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.menu_book : Icons.lock_outline,
                  size: 18,
                  color: isUnlocked ? colors.accentGlow : colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tutorial.chapterPointsCost} 积分',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isUnlocked) ...[
              // 已解锁：渲染 blocks
              ...chapter.blocks.map((b) => _buildContentBlock(colors, b, context)),
            ] else ...[
              // 未解锁：显示提示文案 + 解锁按钮
              Text(
                '本章内容已锁定，观看广告或消耗积分即可解锁',
                style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await UnlockPanel.show(
                      context: context,
                      title: '解锁《${chapter.title}》',
                      description: '该章节属于「${tutorial.type.label}」教学',
                      pointsCost: tutorial.chapterPointsCost,
                      featureId: tutorial.chapterFeatureId(chapter.id),
                    );
                    if (ok && context.mounted) {
                      // 触发重建
                      (context as Element).markNeedsBuild();
                    }
                  },
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('解锁本章'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlock(
    FitTrackColors colors,
    ContentBlock block,
    BuildContext context,
  ) {
    // 复用 course_detail_page 已有的 ContentBlock 渲染逻辑
    // 简化版本：
    switch (block.type) {
      case BlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            block.text ?? '',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            block.text ?? '',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
          ),
        );
      case BlockType.bulletList:
        return Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
              Expanded(
                child: Text(
                  block.text ?? '',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
        );
      case BlockType.callout:
        final isWarning = block.calloutType == 'warning';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isWarning ? colors.warningColor : colors.accentGlow).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isWarning ? colors.warningColor : colors.accentGlow).withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.warning_amber : Icons.info_outline,
                size: 16,
                color: isWarning ? colors.warningColor : colors.accentGlow,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.text ?? '',
                  style: TextStyle(
                    color: isWarning ? colors.warningColor : colors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
```

- [ ] **Step 4: 在文件顶部 import ContentBlock 类型**

```dart
import '../data/content_block.dart';
```

- [ ] **Step 5: 修改 _buildBottomBar 文案**

将 [tutorial_detail_page.dart:519-522](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/tutorial_detail_page.dart#L519-L522) 的 "邀请解锁" 按钮文案改为 "邀请加速解锁"：

```dart
              child: ElevatedButton.icon(
                onPressed: () => context.push('/invitation'),
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('邀请加速解锁'),
```

- [ ] **Step 6: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/pages/tutorial_detail_page.dart`
Expected: No issues found

- [ ] **Step 7: 提交**

```bash
cd fittrack_flutter
git add lib/pages/tutorial_detail_page.dart
git commit -m "feat: Tutorial 详情页按章节渲染+单章积分解锁（子项目E UI层）"
```

---

## Task 6: 子项目 C — 邀请奖励积分化重构

**Files:**
- Modify: `fittrack_flutter/lib/services/invitation_service.dart:116-149`（activateInvitationCode）
- Modify: `fittrack_flutter/lib/services/invitation_service.dart:188-217`（recordReferralActivation + _unlockBadge）
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart:439-492`（奖励规则文案）
- Test: `fittrack_flutter/test/invitation_service_test.dart`

**Interfaces:**
- Consumes: `PointsService.addPoints(int, String)`、`Storage.saveSettings(map)`
- Produces: 邀请人里程碑积分按 `100/300/600/1200` 发放；被邀请人激活得 50 积分；累计5人同步写 `unlockedOpponentSkin=true` 和 `unlockedFeatures=['good_skin_ambassador']`

- [ ] **Step 1: 写失败测试**

创建 `fittrack_flutter/test/invitation_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/data/storage.dart';
import 'package:fittrack/services/points_service.dart';
import 'package:fittrack/services/invitation_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('邀请奖励积分化', () {
    test('被邀请人激活应获得 50 积分', () async {
      // 模拟一个合法的邀请码（邀请人身份 ≠ 当前用户身份）
      // 通过 service 自身方法生成一个不同的邀请码
      final inviterDeviceId = 'inviter_device_seed_123';
      final inviteeDeviceId = 'invitee_device_seed_456';
      // 模拟 inviter 的邀请码：先生成，再用 invitee 身份激活
      // 由于 generateInvitationCode 依赖 deviceId，先设置 inviter 的
      Storage.getSettings()['deviceId'] = inviterDeviceId;
      final code = InvitationService.instance.generateInvitationCode();

      // 切到 invitee 身份
      Storage.getSettings()['deviceId'] = inviteeDeviceId;
      final result = await InvitationService.instance.activateInvitationCode(code);

      expect(result, InvitationResult.success);
      expect(PointsService.instance.points, 50);
    });

    test('累计邀请 5 人应解锁限定皮肤 skin_ambassador', () async {
      final settings = Storage.getSettings();
      settings['deviceId'] = 'inviter_main';
      Storage.saveSettings(settings);

      // 模拟 5 个不同的被邀请激活码（需通过 _verifySignature 校验）
      // 此处直接调用 recordReferralActivation 5 次（不同 code）
      // 由于生成邀请码依赖 deviceId，分别用 5 个不同 deviceId 生成 5 个 code
      final codes = <String>[];
      for (int i = 0; i < 5; i++) {
        Storage.getSettings()['deviceId'] = 'invitee_$i';
        codes.add(InvitationService.instance.generateInvitationCode());
      }
      // 切回邀请人
      Storage.getSettings()['deviceId'] = 'inviter_main';

      ReferralMilestone? lastMilestone;
      for (final code in codes) {
        lastMilestone = await InvitationService.instance.recordReferralActivation(code);
      }
      expect(lastMilestone, ReferralMilestone.fiveActivations);

      final s = Storage.getSettings();
      expect(s['unlockedOpponentSkin'], true);
      // unlockedFeatures 应包含 good_skin_ambassador
      final raw = s['unlockedFeatures'] as String;
      expect(raw.contains('good_skin_ambassador'), true);
    });

    test('邀请人累计积分应为 100+300+600=1000（前3档）', () async {
      // 邀请 5 人：1人=100, 3人=+300=400, 5人=+600=1000
      final settings = Storage.getSettings();
      settings['deviceId'] = 'inviter_main2';
      Storage.saveSettings(settings);

      for (int i = 0; i < 5; i++) {
        Storage.getSettings()['deviceId'] = 'invitee_v2_$i';
        final code = InvitationService.instance.generateInvitationCode();
        Storage.getSettings()['deviceId'] = 'inviter_main2';
        await InvitationService.instance.recordReferralActivation(code);
      }

      // 累计：100(1人) + 300(3人) + 600(5人) = 1000
      expect(PointsService.instance.points, 1000);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/invitation_service_test.dart`
Expected: FAIL（旧逻辑发 50 积分每次，5 人 = 250 积分；皮肤字段未写入）

- [ ] **Step 3: 修改 invitation_service.dart 的 activateInvitationCode 方法**

将 [invitation_service.dart:139-148](file:///d:/app/projects/health_training/fittrack_flutter/lib/services/invitation_service.dart#L139-L148) 替换为：

```dart
    // 写入激活记录
    settings['activatedInvitationCode'] = normalized;
    settings['invitationActivatedAt'] = DateTime.now().millisecondsSinceEpoch;
    settings['inviterIdentity'] = inviterIdentity;
    Storage.saveSettings(settings);

    // 被邀请人激励：50 积分（替代旧的 7 天高级统计体验）
    await PointsService.instance.addPoints(50, 'invited');

    return InvitationResult.success;
  }
```

- [ ] **Step 4: 修改 recordReferralActivation 方法**

将 [invitation_service.dart:188-207](file:///d:/app/projects/health_training/fittrack_flutter/lib/services/invitation_service.dart#L188-L207) 替换为：

```dart
  Future<ReferralMilestone?> recordReferralActivation(String inviteeCode) async {
    if (!_verifySignature(inviteeCode)) return null;
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    if (myList.contains(inviteeCode)) return null;
    myList.add(inviteeCode);
    settings['myReferralCodes'] = myList;
    Storage.saveSettings(settings);

    final count = myList.length;
    // 按里程碑发放积分（每达成新档位发放对应积分，不累加同档位）
    // 1 人 → +100, 3 人 → +300, 5 人 → +600, 10 人 → +1200
    int reward = 0;
    if (count == 1) reward = 100;
    else if (count == 3) reward = 300;
    else if (count == 5) reward = 600;
    else if (count == 10) reward = 1200;
    if (reward > 0) {
      await PointsService.instance.addPoints(reward, 'invite_milestone_$count');
    }

    if (count >= 1) _unlockBadge('referral_first');
    if (count >= 3) _unlockBadge('referral_three');
    if (count >= 5) {
      _unlockBadge('referral_five');
      _unlockOpponentSkin(); // 新增：累计5人解锁限定皮肤
    }
    if (count >= 10) _unlockBadge('referral_ten');

    return _currentMilestone(count);
  }

  /// 累计邀请 5 人时解锁限定对手皮肤 skin_ambassador
  void _unlockOpponentSkin() {
    final settings = Storage.getSettings();
    // 写入 unlockedOpponentSkin 标记（兼容旧字段）
    settings['unlockedOpponentSkin'] = true;
    // 写入 unlockedFeatures：good_skin_ambassador
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    final list = (jsonDecode(raw) as List).cast<String>();
    if (!list.contains('good_skin_ambassador')) {
      list.add('good_skin_ambassador');
      settings['unlockedFeatures'] = jsonEncode(list);
    }
    Storage.saveSettings(settings);
  }
```

- [ ] **Step 5: 修改 invitation_service.dart 顶部注释表**

将 [invitation_service.dart:15-22](file:///d:/app/projects/health_training/fittrack_flutter/lib/services/invitation_service.dart#L15-L22) 注释表更新为：

```dart
/// 激励分层（v1.3 积分化重构）：
/// | 累计邀请人数 | 邀请人获得 | 被邀请人获得 |
/// |---|---|---|
/// | 1 人 | 100 积分 + "引路人"徽章 | 50 积分 |
/// | 3 人 | 300 积分 + "布道者"徽章 | 50 积分 |
/// | 5 人 | 600 积分 + "传道者"徽章 + 限定对手皮肤 skin_ambassador | 50 积分 |
/// | 10 人 | 1200 积分 + "燃力大使"称号 | 50 积分 |
```

- [ ] **Step 6: 修改 invitation_page.dart 的奖励规则文案**

将 [invitation_page.dart:440-445](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/invitation_page.dart#L440-L445) 的 `rules` 列表替换为：

```dart
    final rules = [
      _RewardRule(1, '首次激活', '100 积分 + 引路人徽章', '50 积分'),
      _RewardRule(3, '累计 3 人', '300 积分 + 布道者徽章', '50 积分'),
      _RewardRule(5, '累计 5 人', '600 积分 + 传道者徽章 + 限定对手皮肤', '50 积分'),
      _RewardRule(10, '累计 10 人', '1200 积分 + 燃力大使称号', '50 积分'),
    ];
```

- [ ] **Step 7: 修改 invitation_page.dart 的提示文案**

将 [invitation_page.dart:482](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/invitation_page.dart#L482) 的提示文案替换为：

```dart
                  child: Text(
                    '好友输入你的邀请码激活后，双方均获得对应积分奖励。好友奖励为 50 积分，可立即用于解锁教学章节或购买皮肤。',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
                  ),
```

- [ ] **Step 8: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/invitation_service_test.dart`
Expected: PASS（3 个测试）

- [ ] **Step 9: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/services/invitation_service.dart lib/pages/invitation_page.dart`
Expected: No issues found

- [ ] **Step 10: 提交**

```bash
cd fittrack_flutter
git add lib/services/invitation_service.dart lib/pages/invitation_page.dart test/invitation_service_test.dart
git commit -m "feat: 邀请奖励积分化+兑现限定皮肤（子项目C）"
```

---

## Task 7: 子项目 F - 数据层 — VirtualOpponent 增加 appliedSkinId + dailyAdvance

**Files:**
- Modify: `fittrack_flutter/lib/data/virtual_opponent.dart:92-157`（VirtualOpponent 类）
- Modify: `fittrack_flutter/lib/data/virtual_opponent.dart:160-329`（VirtualOpponentEngine 类）
- Modify: `fittrack_flutter/lib/data/storage.dart:397-453`（getSettings 新增字段）
- Test: `fittrack_flutter/test/virtual_opponent_skin_test.dart`

**Interfaces:**
- Produces: `VirtualOpponent.appliedSkinId` getter（返回 `String`，可能为空串）
- Produces: `VirtualOpponentEngine.dailyAdvance()` 方法

- [ ] **Step 1: 写失败测试**

创建 `fittrack_flutter/test/virtual_opponent_skin_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/data/storage.dart';
import 'package:fittrack/data/virtual_opponent.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('VirtualOpponent.appliedSkinId', () {
    test('无解锁时返回空串', () {
      final opp = VirtualOpponent(
        id: 'test1',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_1',
        persona: '测试人设',
      );
      expect(opp.appliedSkinId, '');
    });

    test('unlockedOpponentSkin=true 时返回 skin_ambassador', () {
      final settings = Storage.getSettings();
      settings['unlockedOpponentSkin'] = true;
      Storage.saveSettings(settings);

      final opp = VirtualOpponent(
        id: 'test2',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_2',
        persona: '测试',
      );
      expect(opp.appliedSkinId, 'skin_ambassador');
    });

    test('已购精品皮肤应返回精品皮肤 id', () {
      final settings = Storage.getSettings();
      settings['unlockedFeatures'] = '["good_skin_cyber_ninja","good_skin_iron_warrior"]';
      Storage.saveSettings(settings);

      final opp = VirtualOpponent(
        id: 'test3',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_3',
        persona: '测试',
      );
      // 优先返回最贵的（精品款优先）
      expect(opp.appliedSkinId, 'skin_cyber_ninja');
    });
  });

  group('VirtualOpponentEngine.dailyAdvance', () {
    test('同一天重复调用不应重复推进', () {
      final opp = VirtualOpponent(
        id: 'test4',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_4',
        persona: '测试',
        weeklyTrainings: 1,
      );
      // 持久化对手数据
      final settings = Storage.getSettings();
      settings['virtualOpponentData'] = opp.toJson();
      Storage.saveSettings(settings);

      VirtualOpponentEngine.instance.dailyAdvance();
      final trainingsAfter1 = (Storage.getSettings()['virtualOpponentData']
          as Map<String, dynamic>)['weeklyTrainings'] as int;

      VirtualOpponentEngine.instance.dailyAdvance();
      final trainingsAfter2 = (Storage.getSettings()['virtualOpponentData']
          as Map<String, dynamic>)['weeklyTrainings'] as int;

      expect(trainingsAfter2, trainingsAfter1);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter && flutter test test/virtual_opponent_skin_test.dart`
Expected: FAIL with "appliedSkinId getter 未定义"

- [ ] **Step 3: 在 storage.dart getSettings 默认值中新增字段**

修改 [storage.dart:436](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/storage.dart#L436)（`virtualOpponentLastAdvance` 之后），新增一行：

```dart
      'virtualOpponentLastAdvance': 0, // 上次对手数据推进时间戳
      'opponentLastAdvanceDate': '', // 每日推进防重复日期字符串（YYYY-MM-DD）
```

- [ ] **Step 4: 在 virtual_opponent.dart 顶部添加 import**

```dart
import 'storage.dart';
import 'virtual_goods.dart';
```

- [ ] **Step 5: 在 VirtualOpponent 类内新增 appliedSkinId getter**

在 [virtual_opponent.dart:157](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/virtual_opponent.dart#L157)（`fromJson` factory 之后、类结束 `}` 之前）添加：

```dart
  /// 当前应用的皮肤 id（运行时计算，不持久化）
  /// 返回空串表示无皮肤（使用默认 Icon）
  String get appliedSkinId {
    final settings = Storage.getSettings();
    // 优先：邀请里程碑解锁的限定皮肤
    if (settings['unlockedOpponentSkin'] == true) return 'skin_ambassador';
    // 其次：从 unlockedFeatures 中查找已购皮肤（精品 → 标准 → 入门 顺序）
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    try {
      final unlocked = (jsonDecode(raw) as List).cast<String>();
      // 按价值降序遍历，优先应用最贵的皮肤
      for (final id in ['skin_cyber_ninja', 'skin_iron_warrior', 'skin_beginner']) {
        if (unlocked.contains('good_$id')) return id;
      }
    } catch (_) {}
    return '';
  }
```

**注意：需要在文件顶部添加 `import 'dart:convert';`（如果还没有）**

- [ ] **Step 6: 在 VirtualOpponentEngine 类内新增 dailyAdvance 方法**

在 [virtual_opponent.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/virtual_opponent.dart) 的 `VirtualOpponentEngine` 类内（`advanceWeekly` 方法之后）添加：

```dart
  /// 每日推进对手训练状态（不再每周才推进）
  ///
  /// 职责：仅负责"本周内"的增量推进（训练次数/重量/时长/偶尔动态）
  /// 周一首次推进时调用 advanceWeekly 重置本周数据
  /// 防重复：通过 settings['opponentLastAdvanceDate'] 严格按日期去重
  void dailyAdvance() {
    final settings = Storage.getSettings();
    final opponentJson = settings['virtualOpponentData'] as Map<String, dynamic>?;
    if (opponentJson == null) return; // 冷启动尚未匹配对手

    final opponent = VirtualOpponent.fromJson(Map<String, dynamic>.from(opponentJson));
    final today = _todayString();
    final lastAdvanceDate = settings['opponentLastAdvanceDate'] as String? ?? '';

    // 防重复：同一天不重复推进
    if (lastAdvanceDate == today) return;

    // 周一：先调用 advanceWeekly 把上周数据快照并重置本周
    if (DateTime.now().weekday == DateTime.monday && lastAdvanceDate != today) {
      advanceWeekly(opponent);
    }

    // 按 tier 调整今日训练概率
    double trainProbability;
    switch (opponent.tier) {
      case OpponentTier.hardcore:
        trainProbability = 0.60;
        break;
      case OpponentTier.active:
        trainProbability = 0.40;
        break;
      case OpponentTier.regular:
        trainProbability = 0.25;
        break;
      case OpponentTier.casual:
        trainProbability = 0.15;
        break;
    }

    if (_random.nextDouble() < trainProbability) {
      // 对手今天训练
      final durationRange = opponent.tier.sessionDurationRange;
      final weightRange = opponent.tier.sessionWeightRange;
      final duration = _random.nextInt(durationRange.max - durationRange.min + 1) + durationRange.min;
      final weight = _random.nextInt(weightRange.max - weightRange.min + 1) + weightRange.min;
      opponent.weeklyTrainings += 1;
      opponent.weeklyWeight += weight;
      opponent.weeklyDuration += duration;
    }

    // 10% 概率发布偶尔动态
    if (_random.nextDouble() < 0.10) {
      opponent.currentStatus = _statusTemplates[_random.nextInt(_statusTemplates.length)];
    }

    // 持久化
    settings['virtualOpponentData'] = opponent.toJson();
    settings['opponentLastAdvanceDate'] = today;
    settings['virtualOpponentLastAdvance'] = DateTime.now().millisecondsSinceEpoch;
    Storage.saveSettings(settings);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
```

- [ ] **Step 7: 运行测试确认通过**

Run: `cd fittrack_flutter && flutter test test/virtual_opponent_skin_test.dart`
Expected: PASS（4 个测试）

- [ ] **Step 8: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/data/virtual_opponent.dart lib/data/storage.dart`
Expected: No issues found

- [ ] **Step 9: 提交**

```bash
cd fittrack_flutter
git add lib/data/virtual_opponent.dart lib/data/storage.dart test/virtual_opponent_skin_test.dart
git commit -m "feat: VirtualOpponent 新增皮肤 getter 和每日推进（子项目F数据层）"
```

---

## Task 8: 子项目 F - UI 层 — 对手详情页 + 卡片可点击 + 路由

**Files:**
- Create: `fittrack_flutter/lib/pages/opponent_detail_page.dart`
- Modify: `fittrack_flutter/lib/router.dart`（新增 /opponent-detail 路由）
- Modify: `fittrack_flutter/lib/widgets/virtual_opponent_card.dart:175-176`（onTap 接入跳转）和 `:184`（头像渲染改用皮肤 emoji）
- Modify: `fittrack_flutter/lib/pages/training_page.dart:1405-1466`（_buildOpponentPKCard 用 InkWell 包裹）
- Modify: `fittrack_flutter/lib/pages/home_page.dart`（initState 调用 dailyAdvance）

**Interfaces:**
- Consumes: `VirtualOpponent.appliedSkinId`、`VirtualGoodsStore.byId(id)`、`VirtualOpponentEngine.instance.dailyAdvance()`
- Produces: `OpponentDetailPage` 路由 `/opponent-detail`

- [ ] **Step 1: 新建 opponent_detail_page.dart**

创建 `fittrack_flutter/lib/pages/opponent_detail_page.dart`：

```dart
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/virtual_opponent.dart';
import '../data/virtual_goods.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 对手详情页 —— P0 最小可用版
class OpponentDetailPage extends StatelessWidget {
  const OpponentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final settings = Storage.getSettings();
    final opponentJson = settings['virtualOpponentData'] as Map<String, dynamic>?;

    if (opponentJson == null) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: '对手详情',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text('对手尚未匹配', style: TextStyle(color: colors.textMuted)),
              ),
            ),
          ],
        ),
      );
    }

    final opponent = VirtualOpponent.fromJson(Map<String, dynamic>.from(opponentJson));
    final skinId = opponent.appliedSkinId;
    final skin = skinId.isNotEmpty ? VirtualGoodsStore.byId(skinId) : null;
    final emoji = skin?.emoji ?? '🤖';

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '对手详情',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(colors, opponent, emoji),
                  const SizedBox(height: 16),
                  _buildWeeklyStatsCard(colors, opponent),
                  const SizedBox(height: 16),
                  if (opponent.currentStatus != null) ...[
                    _buildStatusCard(colors, opponent),
                    const SizedBox(height: 16),
                  ],
                  _buildSkinCard(colors, skinId, context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(FitTrackColors colors, VirtualOpponent opp, String emoji) {
    return CardWidget(
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opp.nickname, style: TextStyle(
                  color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(opp.tier.label, style: TextStyle(
                        color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600,
                      )),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(opp.persona, style: TextStyle(
                        color: colors.textMuted, fontSize: 12,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(FitTrackColors colors, VirtualOpponent opp) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周战绩', style: TextStyle(
            color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(colors, '${opp.weeklyTrainings}', '次训练'),
              _buildStatItem(colors, '${opp.weeklyWeight}', 'kg 总量'),
              _buildStatItem(colors, '${opp.weeklyDuration}', '分钟时长'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(FitTrackColors colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(
            color: colors.accentGlow, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(FitTrackColors colors, VirtualOpponent opp) {
    return CardWidget(
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 18, color: colors.accentGlow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${opp.nickname}：${opp.currentStatus}',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard(FitTrackColors colors, String skinId, BuildContext context) {
    final skin = skinId.isNotEmpty ? VirtualGoodsStore.byId(skinId) : null;
    final allSkins = VirtualGoodsStore.byCategory(GoodCategory.opponentSkin);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text('对手皮肤', style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          // 当前皮肤
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.accentGlow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(skin?.emoji ?? '🤖', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skin?.name ?? '默认皮肤', style: TextStyle(
                        color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
                      )),
                      if (skin != null)
                        Text(skin.isLimited ? '限定款 · 邀请解锁' : '${skin.pointsCost} 积分', style: TextStyle(
                          color: colors.textMuted, fontSize: 11,
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 所有皮肤列表
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: allSkins.map((s) {
              final unlocked = VirtualGoodsStore.isUnlocked(s.id) ||
                  (s.id == 'skin_ambassador' && Storage.getSettings()['unlockedOpponentSkin'] == true);
              return _buildSkinTile(colors, s, unlocked);
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 去邀请入口
          if (skinId != 'skin_ambassador') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/invitation'),
                icon: const Icon(Icons.card_giftcard, size: 16),
                label: const Text('邀请好友解锁限定皮肤'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkinTile(FitTrackColors colors, VirtualGood good, bool unlocked) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? colors.accentGlow.withOpacity(0.06) : colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? colors.accentGlow.withOpacity(0.3) : colors.borderColor,
        ),
      ),
      child: Column(
        children: [
          Text(good.emoji, style: TextStyle(
            fontSize: 24,
            color: unlocked ? null : colors.textMuted,
          )),
          const SizedBox(height: 4),
          Text(good.name, style: TextStyle(
            color: unlocked ? colors.textPrimary : colors.textMuted,
            fontSize: 10, fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            size: 12,
            color: unlocked ? colors.accentGlow : colors.textMuted,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 在 router.dart 添加 /opponent-detail 路由**

修改 [router.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/router.dart)：

**2a. 在文件顶部 import 区添加：**

```dart
import 'pages/opponent_detail_page.dart';
```

**2b. 在 `/max-weight-detail` 路由（[router.dart:409-413](file:///d:/app/projects/health_training/fittrack_flutter/lib/router.dart#L409-L413)）之后添加新路由：**

```dart
      GoRoute(
        path: '/opponent-detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OpponentDetailPage(),
      ),
```

- [ ] **Step 3: 修改 home_page.dart initState 调用 dailyAdvance**

在 [home_page.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/home_page.dart) 找到 `initState` 方法，在 `super.initState()` 之后添加：

```dart
  @override
  void initState() {
    super.initState();
    // v1.3 每日推进对手数据
    VirtualOpponentEngine.instance.dailyAdvance();
    _loadData(); // 保留原有逻辑
  }
```

**注意：** 实际 initState 中可能已有 `_loadData()` 等调用，只需在 `super.initState()` 之后、其他逻辑之前插入 `VirtualOpponentEngine.instance.dailyAdvance();` 即可。

**确保文件顶部已 import：**

```dart
import '../data/virtual_opponent.dart';
```

- [ ] **Step 4: 修改 virtual_opponent_card.dart 接入 onTap + 皮肤渲染**

**4a. 修改 [virtual_opponent_card.dart:175-176](file:///d:/app/projects/health_training/fittrack_flutter/lib/widgets/virtual_opponent_card.dart#L175-L176) 的 GestureDetector：**

```dart
    return GestureDetector(
      onTap: widget.onTap ?? () => context.push('/opponent-detail'),
      child: CardWidget(
```

**4b. 修改 [virtual_opponent_card.dart:184](file:///d:/app/projects/health_training/fittrack_flutter/lib/widgets/virtual_opponent_card.dart#L184) 的图标行为标题：**

将 `Icon(Icons.sports_kabaddi, size: 18, color: colors.accentGlow),` 替换为：

```dart
                Text(
                  VirtualGoodsStore.byId(_opponent!.appliedSkinId)?.emoji ?? '🤖',
                  style: const TextStyle(fontSize: 18),
                ),
```

**4c. 修改 [virtual_opponent_card.dart:218-224](file:///d:/app/projects/health_training/fittrack_flutter/lib/widgets/virtual_opponent_card.dart#L218-L224) 用户方 label "你" 旁边显示对手皮肤 emoji：**

将 `_buildSide` 方法中对对手方的调用：

```dart
                Expanded(
                  child: _buildSide(
                    colors,
                    label: _opponent!.nickname,
                    count: opponentTrainings,
                    maxCount: maxCount,
                    isUser: false,
                  ),
                ),
```

修改为先显示对手皮肤 emoji + 昵称：

实际上更简单的做法：在 `_buildSide` 中针对对手方，在 nickname 上方加一个 emoji 行。但这会改变现有 UI 结构。**保守起见，本步骤 4c 跳过，仅在标题行显示皮肤 emoji（已在 4b 完成）。**

**4d. 在文件顶部添加 import：**

```dart
import 'package:go_router/go_router.dart';
import '../data/virtual_goods.dart';
```

- [ ] **Step 5: 修改 training_page.dart _buildOpponentPKCard 用 InkWell 包裹**

修改 [training_page.dart:1405](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/training_page.dart#L1405) 的 `return Container(...)` 改为 `return InkWell(...)`：

将 [training_page.dart:1405-1466](file:///d:/app/projects/health_training/fittrack_flutter/lib/pages/training_page.dart#L1405-L1466) 整段 `return Container(...)` 替换为：

```dart
    return InkWell(
      onTap: () => context.push('/opponent-detail'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: userWon ? colors.successColor.withOpacity(0.4) : colors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: colors.accentGlow),
                const SizedBox(width: 6),
                Text(
                  '本周PK · vs ${opponent.nickname}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (userWon ? colors.successColor : colors.warningColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    userWon ? '领先' : '追赶中',
                    style: TextStyle(
                      color: userWon ? colors.successColor : colors.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPKBar(colors, '我', userWeeklyTrainings, outcome.userScore, colors.accentGlow),
            const SizedBox(height: 8),
            _buildPKBar(colors, opponent.nickname, opponent.weeklyTrainings, outcome.opponentScore, colors.textMuted),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '超越同水平 $percentile% 用户',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                if (opponent.currentStatus != null)
                  Text(
                    '${opponent.nickname}：${opponent.currentStatus}',
                    style: TextStyle(color: colors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
```

**5b. 确认 training_page.dart 顶部已 import go_router：**

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 6: 运行 flutter analyze 确认无错误**

Run: `cd fittrack_flutter && flutter analyze lib/pages/opponent_detail_page.dart lib/router.dart lib/widgets/virtual_opponent_card.dart lib/pages/training_page.dart lib/pages/home_page.dart`
Expected: No issues found

- [ ] **Step 7: 手动验证流程**

启动 app，进入首页：
- 对手卡片显示皮肤 emoji（默认 🤖）
- 点击对手卡片 → 进入对手详情页 → 显示对手档案/战绩/皮肤列表
- 进入训练并完成 → 训练结束页对手 PK 卡片可点击 → 进入对手详情页

- [ ] **Step 8: 提交**

```bash
cd fittrack_flutter
git add lib/pages/opponent_detail_page.dart lib/router.dart lib/widgets/virtual_opponent_card.dart lib/pages/training_page.dart lib/pages/home_page.dart
git commit -m "feat: 对手详情页+卡片可点击+皮肤渲染+每日推进（子项目F UI层）"
```

---

## Task 9: 全局回归验证

**Files:**
- 无新增文件，仅运行验证

- [ ] **Step 1: 运行 flutter analyze 整个项目**

Run: `cd fittrack_flutter && flutter analyze`
Expected: 已知的第三方插件 `flutter_local_notifications_linux` 错误可忽略；自定义代码无新增 error

- [ ] **Step 2: 运行所有新增测试**

Run: `cd fittrack_flutter && flutter test test/virtual_goods_test.dart test/plan_recommendation_service_test.dart test/tutorial_chapters_test.dart test/invitation_service_test.dart test/virtual_opponent_skin_test.dart`
Expected: All tests PASS

- [ ] **Step 3: 手动验收 — 按验收标准逐项检查**

参考 spec 验收标准 [docs/superpowers/specs/2026-07-27-profile-invite-tutorial-opponent-design.md#13](file:///d:/app/projects/health_training/docs/superpowers/specs/2026-07-27-profile-invite-tutorial-opponent-design.md)

逐项检查：
- [ ] 邀请页流程卡片 4 个圆形图标顶端在同一水平线，chevron_right 与图标中线对齐
- [ ] 引导页推荐计划列表中，同评分段内免费计划排在付费计划前面
- [ ] Tutorial 详情页按章节渲染，每章可单独积分解锁或广告解锁
- [ ] 邀请激活成功后，邀请人按里程碑获得 100/300/600/1200 积分，被邀请人获得 50 积分
- [ ] 累计邀请 5 人后 `unlockedOpponentSkin = true` 且 `unlockedFeatures` 包含 `good_skin_ambassador`
- [ ] 首页对手卡片可点击进入对手详情页
- [ ] 训练结束页对手 PK 卡片可点击进入对手详情页
- [ ] 对手详情页展示皮肤（5 人邀请后展示 `skin_ambassador`）
- [ ] 每日首次打开 App 时对手推进一次（防重复推进）

- [ ] **Step 4: 提交最终验证记录**

```bash
cd fittrack_flutter
git log --oneline -10
```

确认 8 个 commit 全部就位：
1. feat: 新建虚拟物品价格表（子项目D）
2. fix: 修复邀请流程卡片纵向对齐（子项目G）
3. feat: 引导页推荐计划同段内免费优先排序（子项目B）
4. feat: Tutorial 增加 chapters 字段和章节解锁方法（子项目E数据层）
5. feat: Tutorial 详情页按章节渲染+单章积分解锁（子项目E UI层）
6. feat: 邀请奖励积分化+兑现限定皮肤（子项目C）
7. feat: VirtualOpponent 新增皮肤 getter 和每日推进（子项目F数据层）
8. feat: 对手详情页+卡片可点击+皮肤渲染+每日推进（子项目F UI层）

---

## Self-Review Notes

### Spec 覆盖检查
- ✅ 子项目 D（虚拟物品价格表）→ Task 1
- ✅ 子项目 G（邀请流程卡对齐）→ Task 2
- ✅ 子项目 B（推荐排序免费优先）→ Task 3
- ✅ 子项目 E（教学分章节改造）→ Task 4（数据层）+ Task 5（UI 层）
- ✅ 子项目 C（邀请奖励积分化）→ Task 6
- ✅ 子项目 F（对手功能 P0）→ Task 7（数据层）+ Task 8（UI 层）
- ✅ 全局回归验证 → Task 9

### 类型一致性
- `VirtualGood.id` 在 Task 1 定义，Task 7 `appliedSkinId` getter 返回相同 id 格式（`skin_*`）✅
- `Tutorial.chapterFeatureId` 在 Task 4 定义，Task 5 在 UnlockPanel 调用中使用相同格式 `tutorial_<id>_chapter_<chapterId>` ✅
- `unlockedFeatures` 写入格式 `good_<id>` 在 Task 1（VirtualGoodsStore.isUnlocked）和 Task 6（_unlockOpponentSkin）一致 ✅

### 已知风险点
- **Task 4 Step 3h**：需要确认 TutorialLibrary 中 `advancedTutorials` 等列表字段的实际名称。如果名称不同，需相应调整 `allTutorials` getter 的实现。
- **Task 6 Step 1 测试**：邀请码生成依赖 deviceId，测试中通过切换 deviceId 模拟不同用户。如果 `_getDeviceId` 有缓存，可能需要先调用 `Storage.saveSettings` 强制刷新。
- **Task 8 Step 5**：training_page.dart 的 `_buildOpponentPKCard` 原代码用 `Container`，替换为 `InkWell + Container` 嵌套。InkWell 的 borderRadius 必须与 Container 一致以保持水波纹效果在边界内。

