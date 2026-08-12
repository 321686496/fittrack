# 首页邀请专属 Banner 卡片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将「邀请有礼」卡片固定为首页推荐轮播第一项，展示动态邀请进度（已邀请 X/Y 人 + 进度条 + 动态 CTA），提高邀请曝光与转化。

**Architecture:** `RecommendationService.generateBanners()` 中 invitation 不再参与 shuffle，改为提取后固定 `insert(0)`；`BannerItem.invitation()` 去 const 并读 `getReferralProgress()` 填充 `extra`；`RecommendationBanner._buildBanner` 对 `type == 'invitation'` 特判渲染专属布局（图标 + 进度文案 + 进度条 + 动态 CTA）。其余 banner 渲染逻辑不变。

**Tech Stack:** Flutter 3.7.12 / Dart 2.19.6（无新依赖）。

## Global Constraints

- Dart SDK 约束：`>=2.19.6 <3.0.0` —— **禁止使用 Dart 3 特性**（records、switch 表达式、pattern matching、enhanced enums）
- 不新增任何 pub 依赖、不新增文件（测试文件除外）
- 颜色仅用 `LiftTrackColors` 既有色（successColor / accentGlow / borderColor / textPrimary 等），**不新增自定义颜色**
- `BannerItem` 类结构与 `extra` 字段（`Map<String, dynamic>?`）不变，仅 `BannerItem.invitation()` 工厂改为非 const
- 轮播固定高度 150、其余 banner 渲染、`_gradientFor`、`_buildIndicator` 全部不变
- 邀请数据来源 `InvitationService.instance.getReferralProgress()`（同步返回 Map，键 `totalReferrals` / `nextMilestone` / `isAmbassador`）
- 点击跳转沿用 `route: '/invitation'` + `context.push`

---

### Task 1: 服务层 — invitation 固定首位 + 动态数据

**Files:**
- Modify: `fittrack_flutter/lib/services/recommendation_service.dart`
- Create: `fittrack_flutter/test/recommendation_service_test.dart`

**Interfaces:**
- Consumes: `Storage.getSettings()`、`InvitationService.instance.getReferralProgress()`（返回 `{'totalReferrals': int, 'totalPoints': int, 'nextMilestone': int, 'unlockedBadges': List, 'isAmbassador': bool, 'adFreeReport': bool}`）
- Produces: `BannerItem.invitation()`（非 const 工厂，`extra` 含 `totalReferrals` / `nextMilestone` / `isAmbassador`）；`generateBanners()` 返回列表 `first.type == 'invitation'`

- [ ] **Step 1: 写失败测试**

创建 `test/recommendation_service_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/data/storage.dart';
import '../lib/services/recommendation_service.dart';

void main() {
  setUp(() async {
    await Storage.init();
    Storage.clearAll();
  });

  group('RecommendationService.generateBanners', () {
    test('首项必为 invitation 类型', () {
      final banners = RecommendationService.generateBanners();
      expect(banners, isNotEmpty);
      expect(banners.first.type, 'invitation');
    });

    test('invitation 携带进度数据（默认无邀请 → nextMilestone 1）', () {
      final banners = RecommendationService.generateBanners();
      final first = banners.first;
      expect(first.type, 'invitation');
      final extra = first.extra!;
      expect(extra['totalReferrals'], 0);
      expect(extra['nextMilestone'], 1);
      expect(extra['isAmbassador'], false);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/recommendation_service_test.dart`
Expected: FAIL —— `first.type` 不是 'invitation'（shuffle 后位置随机）、`extra` 为 null（当前工厂无 extra）

- [ ] **Step 3: 实现服务层**

修改 `lib/services/recommendation_service.dart`：

a) 顶部新增 import：

```dart
import 'invitation_service.dart';
```

b) 将 `BannerItem.invitation()` 工厂改为非 const 并填充进度数据（替换 L25-L31）：

```dart
  factory BannerItem.invitation() {
    final progress = InvitationService.instance.getReferralProgress();
    return BannerItem(
      type: 'invitation',
      title: '邀请有礼',
      subtitle: '最高 2000 积分等你拿',
      icon: 'card_giftcard',
      route: '/invitation',
      extra: {
        'totalReferrals': progress['totalReferrals'],
        'nextMilestone': progress['nextMilestone'],
        'isAmbassador': progress['isAmbassador'],
      },
    );
  }
```

c) `generateBanners()` 中，将 L101 的 `items.add(BannerItem.invitation());` **删除**，并在 shuffle 前后调整为：先对 invitation 之外的部分 shuffle，再 insert(0)。替换 L104-L105：

```dart
    // 邀请有礼固定为轮播第一项，其余 banner 每日随机顺序
    final inviteBanner = BannerItem.invitation();
    items.shuffle(Random(DateTime.now().day));
    items.insert(0, inviteBanner);
    return items;
```

> 说明：`items` 中不再包含 invitation（L101 已删），先对教学/付费/计划/成就 shuffle，再统一 `insert(0)`，保证邀请恒在首位、其余顺序每日随机。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/recommendation_service_test.dart`
Expected: PASS（2 个测试全绿）

- [ ] **Step 5: 回归 + 提交**

Run: `flutter test test/invitation_service_test.dart`
Expected: PASS（11 个测试不受影响）

```bash
git add fittrack_flutter/lib/services/recommendation_service.dart fittrack_flutter/test/recommendation_service_test.dart
git commit -m "feat(home): 邀请 banner 固定首位并携带动态进度数据"
```

---

### Task 2: UI — 邀请专属卡片渲染

**Files:**
- Modify: `fittrack_flutter/lib/widgets/recommendation_banner.dart`

**Interfaces:**
- Consumes: `BannerItem`（`type`/`title`/`icon`/`route`/`extra`，Task 1 已保证 `extra['totalReferrals']`/`extra['nextMilestone']`/`extra['isAmbassador']`）；`LiftTrackColors`；`context.push`（go_router）
- Produces: `_buildInvitationBanner(LiftTrackColors colors, BannerItem banner)` 私有方法；`_buildBanner` 内 `type == 'invitation'` 分支

- [ ] **Step 1: 在 `_buildBanner` 增加邀请分支**

修改 `lib/widgets/recommendation_banner.dart` 的 `_buildBanner`（L63 起），在方法开头加特判：

```dart
  Widget _buildBanner(BannerItem banner) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    if (banner.type == 'invitation') {
      return _buildInvitationBanner(colors, banner);
    }
    final gradient = _gradientFor(banner.type, colors);
    // ... 原有逻辑不变
```

- [ ] **Step 2: 新增 `_buildInvitationBanner` 方法**

在 `_buildBanner` 方法之后、`_buildIndicator` 之前新增：

```dart
  /// 邀请有礼专属卡片：动态进度 + 进度条 + 动态 CTA
  Widget _buildInvitationBanner(LiftTrackColors colors, BannerItem banner) {
    final totalReferrals =
        (banner.extra?['totalReferrals'] as num?)?.toInt() ?? 0;
    final nextMilestone = (banner.extra?['nextMilestone'] as num?)?.toInt() ?? 1;
    final isAmbassador = banner.extra?['isAmbassador'] == true;
    final remaining = nextMilestone - totalReferrals;
    final progress = (totalReferrals / nextMilestone).clamp(0.0, 1.0);

    final String ctaText;
    if (totalReferrals == 0) {
      ctaText = '邀请好友，双方得积分 →';
    } else if (remaining > 0) {
      ctaText = '还差 $remaining 人解锁奖励 →';
    } else {
      ctaText = '查看全部奖励 →';
    }

    return GestureDetector(
      onTap: () {
        if (banner.route != null) context.push(banner.route!);
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: _gradientFor('invitation', colors),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // 装饰几何：右上圆形光晕
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // 装饰几何：左下小圆
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头部：礼物图标 + 标题 + 大使角标
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isAmbassador)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '大使',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // 进度文案
                  Text(
                    isAmbassador
                        ? '已邀请 $totalReferrals 人 · 大使'
                        : '已邀请 $totalReferrals / $nextMilestone 人',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: Colors.white.withOpacity(0.25),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 动态 CTA
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

> 说明：轮播固定高度 150，`Column` 内用 `Spacer()` 将进度区推至中部偏下，避免底部溢出（与现有 `mainAxisAlignment.center` 视觉保持一致）。

- [ ] **Step 3: 静态检查**

Run: `flutter analyze lib/widgets/recommendation_banner.dart lib/services/recommendation_service.dart`
Expected: 无新增 error/warning（可能提示 const 优化项，属 info 级可忽略）

- [ ] **Step 4: 运行相关测试**

Run: `flutter test test/recommendation_service_test.dart test/invitation_service_test.dart`
Expected: PASS（2 + 11 个测试全绿）

- [ ] **Step 5: 手动验证清单**（模拟器或 OHOS 设备）

1. 首页轮播第一项为「邀请有礼」专属卡片（绿色渐变 + 礼物图标 + 进度条）
2. 无邀请时：显示「已邀请 0 / 1 人」、进度条空、CTA「邀请好友，双方得积分 →」
3. 录入 1 人后：显示「已邀请 1 / 3 人」、进度条 1/3、CTA「还差 2 人解锁奖励 →」
4. 达 10 人：显示「已邀请 10 人 · 大使」、进度条满、CTA「查看全部奖励 →」
5. 点击卡片跳转 `/invitation` 页
6. 轮播自动翻页、指示器、其余 banner 正常
7. 下拉刷新后进度数据更新（`_loadData` → `generateBanners` 重新调用）

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/widgets/recommendation_banner.dart
git commit -m "feat(home): 邀请有礼专属 banner 卡片（进度条+动态CTA）"
```

---

## 自审记录

- **Spec 覆盖**：§3.1 置顶（Task 1）、§3.2 动态数据（Task 1）、§3.3 点击跳转（Task 2 沿用）、§4 专属视觉（Task 2）、§5 边界处理（Task 2 `ctaText`/`progress` clamp/isAmbassador）、§6 文件清单（Task 1/2）、§7 测试（Task 1 单测 + Task 2 手测）。无缺口。
- **类型一致性**：`extra` 键 `totalReferrals`/`nextMilestone`/`isAmbassador` 在 Task 1 写入、Task 2 读取，命名一致；`(banner.extra?[...] as num?)?.toInt()` 兼容 `int` 存储。
- **Dart 2.19 兼容**：无 records/switch 表达式/pattern；`progress` 用 `clamp` 后赋给 `widthFactor`（double 参数）——`num.clamp` 返回 `num`，赋给 `double` 类型参数 `widthFactor` 会报类型错误。已在代码中将 `progress` 声明为 `(totalReferrals / nextMilestone).clamp(0.0, 1.0)`——`double.clamp` 返回 `num`，需改为 `.toDouble()`。见下方修正注记。

> **注（类型修正，实现时必须应用）**：`final progress = (totalReferrals / nextMilestone).clamp(0.0, 1.0);` 中 `double.clamp` 静态返回 `num`，传给 `FractionallySizedBox.widthFactor`（`double?`）会编译失败。改为 `final progress = (totalReferrals / nextMilestone).clamp(0.0, 1.0).toDouble();`
