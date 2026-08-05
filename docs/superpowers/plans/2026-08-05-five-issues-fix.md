# 五项问题修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复训练结束通知bug、iOS/Android后台提醒兼容、训练完成积分提示、未解锁皮肤预览、训练持久化（完整方案）

**Architecture:** 在现有 StatefulWidget + Storage 静态方法架构上，重构休息状态机（idle/resting/restingOvertime），增加 SharedPreferences 持久化进行中训练，扩展 SQLite records 表 schema v9（pureDuration 字段），统一 restLog 字段格式，新增 RestPreferenceService 推荐服务。

**Tech Stack:** Flutter 3.x, Dart, SQLite (sqflite), SharedPreferences, flutter_local_notifications, AlarmManager (Android), UNUserNotificationCenter (iOS)

## Global Constraints

- 不引入 Provider/Riverpod 等状态管理框架，延续 StatefulWidget + Storage 静态方法
- `duration` 字段保持原语义（含休息总时长，分钟精度），新增 `pureDuration`（秒精度）
- restLog 新格式字段：`exercise`、`scheduledRestSeconds`、`actualRestSeconds`、`restEndReason`
- 兼容旧数据：record_detail_page 读取 restLog 时 fallback 到 `restTime`/`actualTime`
- `restOvertimeLimitMultiplier` 默认 3.0，不暴露 UI
- OHOS 平台通知由原生 EntryAbility 处理，Flutter 侧跳过
- 训练持久化 key：`fittrack_in_progress_training`（独立于 settings key）

**Spec:** `docs/superpowers/specs/2026-08-05-five-issues-fix-design.md`

---

## Task 1: Storage + DatabaseHelper 基础改造

**Files:**
- Modify: `fittrack_flutter/lib/data/storage.dart` (settings defaults + in-progress 方法)
- Modify: `fittrack_flutter/lib/data/database_helper.dart` (schema v8→v9)
- Test: `fittrack_flutter/test/storage_in_progress_test.dart`

**Interfaces:**
- Produces: `Storage.saveInProgressTraining(Map<String,dynamic>)`, `Storage.getInProgressTraining()`, `Storage.clearInProgressTraining()`, settings defaults `autoEndAfterRest`/`restOvertimeLimitMultiplier`

- [ ] **Step 1: Write failing test for in-progress training storage**

Create `fittrack_flutter/test/storage_in_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveInProgressTraining stores data and getInProgressTraining retrieves it', () async {
    await Storage.init();
    final data = {
      'version': 1,
      'planId': 'test_plan',
      'currentExIdx': 2,
      'currentSetIdx': 1,
    };
    await Storage.saveInProgressTraining(data);

    final retrieved = Storage.getInProgressTraining();
    expect(retrieved, isNotNull);
    expect(retrieved!['planId'], 'test_plan');
    expect(retrieved['currentExIdx'], 2);
    expect(retrieved['lastPersistedAt'], isNotNull);
  });

  test('getInProgressTraining returns null when no data', () async {
    await Storage.init();
    final result = Storage.getInProgressTraining();
    expect(result, isNull);
  });

  test('clearInProgressTraining removes data', () async {
    await Storage.init();
    await Storage.saveInProgressTraining({'planId': 'test'});
    await Storage.clearInProgressTraining();
    expect(Storage.getInProgressTraining(), isNull);
  });

  test('settings defaults include autoEndAfterRest and restOvertimeLimitMultiplier', () async {
    await Storage.init();
    final settings = Storage.getSettings();
    expect(settings['autoEndAfterRest'], false);
    expect(settings['restOvertimeLimitMultiplier'], 3.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd fittrack_flutter && flutter test test/storage_in_progress_test.dart`
Expected: FAIL — `saveInProgressTraining` method not found

- [ ] **Step 3: Add settings defaults to storage.dart**

In `fittrack_flutter/lib/data/storage.dart`, find `getSettings()` method (around line 398), locate the defaults Map. Add these two entries before the closing `};` of the defaults map (after `'actionGuideCollapsed': false,` at line 465):

```dart
      'actionGuideCollapsed': false, // 训练页底部动作指导卡片是否收起（默认展开）
      // ── 休息状态机 + 持久化 ──
      'autoEndAfterRest': false, // 休息结束后自动结束（自制力模式）
      'restOvertimeLimitMultiplier': 3.0, // 静默计时上限倍数（设定时间 × 3）
```

- [ ] **Step 4: Add in-progress training storage methods**

In `fittrack_flutter/lib/data/storage.dart`, add a new section before the `// ============================================================` line that closes the Settings section (after `saveSettings` method, around line 480). Add:

```dart
  // ============================================================
  // In-Progress Training (SharedPreferences)
  // ============================================================

  static const String _inProgressKey = 'fittrack_in_progress_training';

  /// 保存进行中的训练数据（异步落盘）
  static Future<void> saveInProgressTraining(Map<String, dynamic> data) async {
    data['lastPersistedAt'] = DateTime.now().millisecondsSinceEpoch;
    _store[_inProgressKey] = data;
    _prefs?.setString('$_keyPrefsPrefix$_inProgressKey', jsonEncode(data));
  }

  /// 读取进行中的训练数据（同步，从内存缓存）
  static Map<String, dynamic>? getInProgressTraining() {
    final raw = _store[_inProgressKey];
    if (raw == null) {
      // 尝试从 prefs 加载（首次启动时 _store 可能未加载此 key）
      final prefsRaw = _prefs?.getString('$_keyPrefsPrefix$_inProgressKey');
      if (prefsRaw == null) return null;
      try {
        final decoded = jsonDecode(prefsRaw) as Map<String, dynamic>;
        _store[_inProgressKey] = decoded;
        return decoded;
      } catch (_) {
        return null;
      }
    }
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  /// 清除进行中的训练数据
  static Future<void> clearInProgressTraining() async {
    _store.remove(_inProgressKey);
    await _prefs?.remove('$_keyPrefsPrefix$_inProgressKey');
  }
```

Also, add `_inProgressKey` to the init loading loop. Find the `init()` method (around line 43) and update the key list:

```dart
    for (final key in [_keySettings, _keyStats, _keyBodyData, _keyBodyDataHistory, _inProgressKey]) {
```

- [ ] **Step 5: Add schema v9 migration to database_helper.dart**

In `fittrack_flutter/lib/data/database_helper.dart`, update `_dbVersion` (line 12):

```dart
  static const int _dbVersion = 9;
```

Add migration in `_onUpgrade` method, after the `if (oldVersion < 8)` block (around line 267):

```dart
    if (oldVersion < 9) {
      // records 表新增 pureDuration 列（纯训练时长，秒精度，不含休息）
      await db.execute(
          'ALTER TABLE records ADD COLUMN pureDuration INTEGER');
    }
```

Also add `pureDuration` to `_onCreate` for fresh installs. Find the records table CREATE statement in `_onCreate` and add `pureDuration INTEGER` column.

- [ ] **Step 6: Run test to verify it passes**

Run: `cd fittrack_flutter && flutter test test/storage_in_progress_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
cd fittrack_flutter
git add lib/data/storage.dart lib/data/database_helper.dart test/storage_in_progress_test.dart
git commit -m "feat: add in-progress training storage and schema v9 (pureDuration)"
```

---

## Task 2: iOS/Android 后台提醒权限修复

**Files:**
- Modify: `fittrack_flutter/lib/services/rest_notification_service.dart` (iOS 权限请求)
- Modify: `fittrack_flutter/android/app/src/main/kotlin/com/lt/lifttrack/AlarmReceiver.kt` (权限检查)
- Modify: `fittrack_flutter/lib/pages/training_page.dart` (权限引导)

**Interfaces:**
- Consumes: `PermissionService` from `permission_service.dart`
- Produces: iOS notification permission request in `RestNotificationService._requestNotificationPermission()`

- [ ] **Step 1: Add iOS permission request branch in RestNotificationService**

In `fittrack_flutter/lib/services/rest_notification_service.dart`, find `_requestNotificationPermission()` method (around line 94). Replace the entire method with:

```dart
  Future<bool> _requestNotificationPermission() async {
    try {
      // OHOS 平台：跳过 flutter_local_notifications 权限请求
      if (PlatformServices.restReminder is OhosRestReminderService) {
        debugPrint('OHOS: skip flutter_local_notifications permission request');
        return true;
      }
      final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final result = await androidPlugin.requestNotificationsPermission();
        debugPrint('Android notification permission: $result');
        return result ?? false;
      }
      // iOS: 通过 flutter_local_notifications 请求 alert/badge/sound 权限
      final iosPlugin = _plugin!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('iOS notification permission: $result');
        return result ?? false;
      }
    } catch (e) {
      debugPrint('Request notification permission error: $e');
    }
    return false;
  }
```

- [ ] **Step 2: Add POST_NOTIFICATIONS permission check in AlarmReceiver.kt**

In `fittrack_flutter/android/app/src/main/kotlin/com/lt/lifttrack/AlarmReceiver.kt`, update `onReceive` method. Add imports at top:

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
```

Update `onReceive` to check permission before showing notification:

```kotlin
    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.i("AlarmReceiver", "onReceive: action=${intent.action}, extras=${intent.extras}")

        // Android 13+ 检查通知权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                android.util.Log.w("AlarmReceiver", "POST_NOTIFICATIONS not granted, skip notification")
                return
            }
        }

        val title = intent.getStringExtra(EXTRA_TITLE) ?: "休息结束"
        val content = intent.getStringExtra(EXTRA_CONTENT) ?: "休息时间到了，继续训练吧！"
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, NOTIFICATION_ID)

        createNotificationChannel(context)
        showNotification(context, notificationId, title, content)
    }
```

Note: `Build` is already imported (`import android.os.Build`).

- [ ] **Step 3: Add permission check in TrainingPage.initState**

In `fittrack_flutter/lib/pages/training_page.dart`, find `initState()` (around line 100). Add permission check after `_loadData()`:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _actionGuideExpanded = !(Storage.getSettings()['actionGuideCollapsed'] as bool? ?? false);
    _loadData();

    // 检查通知权限，未授予时提示用户
    _checkNotificationPermission();

    _restReminderSub = PlatformServices.restReminder.onNotificationClick.listen(_onNotificationClicked);
    _liveViewSub = PlatformServices.liveView.onUserAction.listen((event) {
      if (!mounted) return;
      if (event.action == LiveViewAction.skipRest && _isResting) {
        _skipRest();
      }
    });
  }

  /// 检查通知权限，未授予时弹窗引导用户去设置
  Future<void> _checkNotificationPermission() async {
    final granted = await PermissionService.isNotificationGranted();
    if (!granted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PermissionService.showPermissionDeniedDialog(
          context,
          permissionName: '通知',
          reason: '休息结束提醒需要通知权限才能在后台向您发送提醒，请在设置中开启通知权限。',
        );
      });
    }
  }
```

Add import at top of file:

```dart
import '../services/permission_service.dart';
```

- [ ] **Step 4: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/services/rest_notification_service.dart lib/pages/training_page.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
cd fittrack_flutter
git add lib/services/rest_notification_service.dart android/app/src/main/kotlin/com/lt/lifttrack/AlarmReceiver.kt lib/pages/training_page.dart
git commit -m "fix: iOS notification permission request and Android POST_NOTIFICATIONS check"
```

---

## Task 3: 训练完成积分提示

**Files:**
- Modify: `fittrack_flutter/lib/services/points_service.dart` (返回值改为 int)
- Modify: `fittrack_flutter/lib/pages/training_page.dart` (传递 earnedPoints)
- Modify: `fittrack_flutter/lib/widgets/celebration_dialog.dart` (增加积分展示)

**Interfaces:**
- Produces: `PointsService.addDailyTrainingPoints()` returns `Future<int>`
- Produces: `CelebrationDialog.show(earnedPoints: int)`

- [ ] **Step 1: Change addDailyTrainingPoints return type to Future<int>**

In `fittrack_flutter/lib/services/points_service.dart`, find `addDailyTrainingPoints()` (around line 61). Replace with:

```dart
  /// 每日训练完成得积分（同日防重复）。
  /// 返回实际获得的积分数（0 表示今日已领过）。
  Future<int> addDailyTrainingPoints() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final settings = Storage.getSettings();
    if (settings['lastTrainingPointsDate'] == todayStr) return 0;
    settings['lastTrainingPointsDate'] = todayStr;
    Storage.saveSettings(settings);
    await addPoints(trainingPoints, 'training');
    return trainingPoints;
  }
```

- [ ] **Step 2: Update _autoSaveTraining to capture and pass earnedPoints**

In `fittrack_flutter/lib/pages/training_page.dart`, find `_autoSaveTraining()` (around line 507). Update the points call and CelebrationDialog call:

```dart
    // B4: 成就检查（训练完成后自动计算并弹出 — 修复 Issue 1d）
    int earnedPoints = 0;
    if (mounted) {
      final records = Storage.getRecords();
      final currentRecord = records.isNotEmpty ? records.first : <String, dynamic>{};
      final unlockedAchievements =
          await AchievementService.instance.checkAndUnlock(currentRecord);
      // 每日训练得积分（同日防重复）：成就检查之后调用
      earnedPoints = await PointsService.instance.addDailyTrainingPoints();
      if (unlockedAchievements.isNotEmpty && mounted) {
        for (final id in unlockedAchievements) {
          final all = AchievementService.instance.getAll();
          final ach = all.where((a) => a.id == id).first;
          await InfoDialog.show(
            context,
            title: '解锁新成就',
            content: '${ach.title}\n${ach.description}',
            actionText: '好的',
            icon: Icons.emoji_events,
            iconColor: Theme.of(context).colorScheme.primary,
          );
        }
      }
    }

    // B2: 训练完成庆祝动画
    if (mounted) {
      final records = Storage.getRecords();
      if (records.isNotEmpty) {
        final current = records.first;
        final previous = records.length > 1 ? records[1] : null;
        await CelebrationOverlay.show(context,
            record: current, previousRecord: previous);
      }
    }

    // v1 训练笔记情感化：弹出祝贺框
    if (mounted) {
      await CelebrationDialog.show(
        context,
        totalWeight: totalWeight,
        totalSets: _completedSets,
        duration: duration,
        recordId: _savedRecordId ?? '',
        earnedPoints: earnedPoints,
      );
    }
```

- [ ] **Step 3: Add earnedPoints parameter to CelebrationDialog**

In `fittrack_flutter/lib/widgets/celebration_dialog.dart`, find the `show` method (around line 7). Update signature and stats Row:

```dart
  static Future<void> show(BuildContext context, {
    required int totalWeight,
    required int totalSets,
    required int duration,
    required String recordId,
    required int earnedPoints,
  }) async {
```

Find the stats `Row` (around line 50-58). Replace with:

```dart
              // 训练数据摘要
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(colors, '${totalWeight}kg', '总重量'),
                  _stat(colors, '$totalSets', '总组数'),
                  _stat(colors, '${duration}min', '时长'),
                  if (earnedPoints > 0)
                    _stat(colors, '+$earnedPoints', '本次积分',
                          icon: Icons.stars, iconColor: colors.accentGlow),
                ],
              ),
```

Find the `_stat` helper method. Update it to accept optional icon:

```dart
  static Widget _stat(LiftTrackColors colors, String value, String label,
      {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? colors.accentGlow),
              const SizedBox(width: 2),
            ],
            Text(value, style: TextStyle(
              color: iconColor ?? colors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.bold,
            )),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: colors.textSecondary, fontSize: 11,
        )),
      ],
    );
  }
```

- [ ] **Step 4: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/services/points_service.dart lib/widgets/celebration_dialog.dart lib/pages/training_page.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
cd fittrack_flutter
git add lib/services/points_service.dart lib/widgets/celebration_dialog.dart lib/pages/training_page.dart
git commit -m "feat: show earned points in celebration dialog after training"
```

---

## Task 4: 未解锁皮肤点击预览

**Files:**
- Modify: `fittrack_flutter/lib/pages/opponent_detail_page.dart` (皮肤预览弹层)

**Interfaces:**
- Consumes: `OpponentRenderer` widget, `OpponentSkinConfig`, `VirtualGood`
- Produces: `_showSkinPreview()` method, `_SkinPreviewSheet` widget

- [ ] **Step 1: Add GestureDetector to _buildSkinTile**

In `fittrack_flutter/lib/pages/opponent_detail_page.dart`, find `_buildSkinTile` method (around line 452). Wrap the Container in a GestureDetector:

```dart
  Widget _buildSkinTile(LiftTrackColors colors, VirtualGood good, bool unlocked) {
    final skinCfg = OpponentSkinConfig.byId(good.id);
    final cardTheme = skinCfg.cardTheme;
    final isAmbassador = good.id == 'skin_ambassador';

    return GestureDetector(
      onTap: unlocked ? null : () => _showSkinPreview(colors, good, skinCfg),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: unlocked ? colors.accentGlow.withOpacity(0.06) : colors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked ? (cardTheme.borderColor) : colors.borderColor,
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(good.emoji, style: TextStyle(
                  fontSize: 24,
                  color: unlocked ? null : colors.textMuted,
                )),
                if (isAmbassador && !unlocked)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: BadgeWidget(text: '限定', variant: BadgeVariant.accent),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(good.name, style: TextStyle(
              color: unlocked ? colors.textPrimary : colors.textMuted,
              fontSize: 10, fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (unlocked)
              Icon(
                Icons.check_circle,
                size: 12,
                color: cardTheme.glowColor,
              )
            else if (good.isPurchasableWithPoints)
              _buildPurchaseButton(colors, good, cardTheme)
            else
              Text(
                good.unlockCondition ?? '',
                style: TextStyle(color: colors.textMuted, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: Add _showSkinPreview method**

In `fittrack_flutter/lib/pages/opponent_detail_page.dart`, add this method after `_buildSkinTile`:

```dart
  /// 弹出底部 sheet 预览未解锁皮肤
  void _showSkinPreview(
      LiftTrackColors colors, VirtualGood good, OpponentSkinConfig skinCfg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SkinPreviewSheet(
        colors: colors,
        good: good,
        skinCfg: skinCfg,
        unlocking: _unlocking,
        onPurchase: () {
          Navigator.of(ctx).pop();
          _purchaseSkin(good.id);
        },
        onInvite: () {
          Navigator.of(ctx).pop();
          context.push('/invitation');
        },
      ),
    );
  }
```

- [ ] **Step 3: Add _SkinPreviewSheet widget class**

At the end of `fittrack_flutter/lib/pages/opponent_detail_page.dart`, add the `_SkinPreviewSheet` widget:

```dart
/// 皮肤预览底部弹层
class _SkinPreviewSheet extends StatelessWidget {
  final LiftTrackColors colors;
  final VirtualGood good;
  final OpponentSkinConfig skinCfg;
  final bool unlocking;
  final VoidCallback onPurchase;
  final VoidCallback onInvite;

  const _SkinPreviewSheet({
    required this.colors,
    required this.good,
    required this.skinCfg,
    required this.unlocking,
    required this.onPurchase,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final isAmbassador = good.id == 'skin_ambassador';
    final cardTheme = skinCfg.cardTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // 皮肤名称
            Text(skinCfg.name, style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            // OpponentRenderer 渲染
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: cardTheme.gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardTheme.borderColor, width: 2),
              ),
              child: OpponentRenderer(
                skinConfig: skinCfg,
                motionType: MotionType.idle,
                size: 180,
              ),
            ),
            const SizedBox(height: 16),
            // 皮肤信息
            _infoRow(colors, '招牌动作', skinCfg.signatureMove),
            const SizedBox(height: 8),
            _infoRow(colors, '价格', skinCfg.pointsCost),
            if (good.unlockCondition != null) ...[
              const SizedBox(height: 8),
              _infoRow(colors, '解锁条件', good.unlockCondition!),
            ],
            const SizedBox(height: 20),
            // 购买/邀请按钮
            if (good.isPurchasableWithPoints)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: unlocking ? null : onPurchase,
                  icon: const Icon(Icons.stars, size: 18),
                  label: Text('积分购买 ($good.pointsCost)',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardTheme.borderColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isAmbassador) ...[
              if (good.isPurchasableWithPoints)
                const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onInvite,
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('邀请好友解锁',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentGlow,
                    side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('关闭', style: TextStyle(color: colors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(LiftTrackColors colors, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(
          color: colors.textSecondary, fontSize: 13,
        )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(
            color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
```

Add necessary imports at the top of the file if not already present:

```dart
import '../widgets/opponent/opponent_renderer.dart';
```

- [ ] **Step 4: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/opponent_detail_page.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
cd fittrack_flutter
git add lib/pages/opponent_detail_page.dart
git commit -m "feat: add skin preview bottom sheet for locked skins"
```

---

## Task 5: 休息状态机重构 + 通知 Bug 修复

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart` (核心重构)

**Interfaces:**
- Consumes: `Storage.saveInProgressTraining()`, `Storage.getInProgressTraining()` from Task 1
- Produces: `RestPhase`/`RestEndReason` enums, `_startRest()`, `_endRest()`, `_enterOvertimePhase()`, `_restartRestTimer()`

**注意：** 这是最大的改动块。重构休息状态机，修复通知 bug（§1），并集成持久化触发点。此 Task 完成后休息流程即可正常工作。

- [ ] **Step 1: Add RestPhase and RestEndReason enums**

In `fittrack_flutter/lib/pages/training_page.dart`, after the imports (around line 29), add:

```dart
/// 休息状态机阶段
enum RestPhase { idle, resting, restingOvertime }
/// 休息结束原因
enum RestEndReason { manual, autoTimeout, skip }
```

- [ ] **Step 2: Replace rest state fields**

In `_TrainingPageState`, find the rest state fields (around lines 53-66). Replace:

```dart
  // ── Training state ───────────────────────────────────────────
  int _currentExIdx = 0;
  int _currentSetIdx = 0;
  bool _trainingDone = false;

  /// 动作指导卡片是否展开（默认展开，状态从持久化设置读取）
  bool _actionGuideExpanded = true;

  // ── Rest state machine ──────────────────────────────────────
  RestPhase _restPhase = RestPhase.idle;
  int _restScheduledSeconds = 0;
  DateTime? _restActualStartAt;
  DateTime? _restScheduledEndAt;
  DateTime? _restOvertimeLimitAt;
  RestEndReason? _restEndReason;
  int _restDisplaySeconds = 0;
  int _lastRestActualSeconds = 0;

  /// 兼容字段：UI 读取 _restSeconds 来显示剩余秒数
  int get _restSeconds => _restDisplaySeconds;
  bool get _isResting => _restPhase != RestPhase.idle;

  // ── App lifecycle ────────────────────────────────────────────
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
```

Remove old fields: `_isResting`, `_restSeconds`, `_totalRestSeconds`, `_isLastSetOfExercise`, `_restEndTime`, `_restEndNotified`.

- [ ] **Step 3: Rewrite _startRest method**

Find `_startRest` method (around line 323). Replace with:

```dart
  void _startRest(int seconds, bool isLastSetOfExercise) {
    SoundService.instance.play(SoundType.restStart);
    final now = DateTime.now();
    _restScheduledSeconds = seconds;
    _restActualStartAt = now;
    _restScheduledEndAt = now.add(Duration(seconds: seconds));
    final multiplier =
        (Storage.getSettings()['restOvertimeLimitMultiplier'] as num?)?.toDouble() ?? 3.0;
    _restOvertimeLimitAt = _restScheduledEndAt!.add(
        Duration(seconds: (seconds * multiplier).round()));

    setState(() {
      _restPhase = RestPhase.resting;
      _restDisplaySeconds = seconds;
    });

    // 推送休息状态到卡片 + 启动实况窗
    if (_currentExIdx < _exercises.length) {
      final currentEx = _exercises[_currentExIdx];
      final exerciseName = currentEx['name'] as String;
      final totalSets = (currentEx['sets'] as int?) ?? 0;

      PlatformServices.widgetCard.pushCardData(WidgetCardData(
        mode: WidgetCardMode.rest,
        exerciseName: exerciseName,
        restTotalSeconds: seconds,
        restEndTime: _restScheduledEndAt,
        currentSet: _currentSetIdx + 1,
        totalSets: totalSets,
        exerciseIndex: _currentExIdx + 1,
        totalExercises: _exercises.length,
        completedSets: _completedSets + 1,
        totalPlanSets: _totalSets,
      ));
      PlatformServices.liveView.startRestLiveView(
        exerciseName: exerciseName,
        restSeconds: seconds,
        restEndTime: _restScheduledEndAt!,
      );
    }

    // 预约定时通知（后台时系统自动触发）
    if (PlatformServices.restReminder is! OhosRestReminderService) {
      final exerciseName = _currentExIdx < _exercises.length
          ? _exercises[_currentExIdx]['name'] as String
          : '';
      RestNotificationService.instance.scheduleRestEndNotification(
        exerciseName: exerciseName,
        delaySeconds: seconds,
      );
    }

    _restartRestTimer();
    _persistInProgressTraining();
  }
```

- [ ] **Step 4: Rewrite _restartRestTimer**

Find `_restartRestTimer` method (around line 377). Replace with:

```dart
  /// 启动/重启休息倒计时（基于 wall-clock 校正）
  void _restartRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restPhase == RestPhase.idle) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      setState(() {
        if (_restPhase == RestPhase.resting) {
          final remaining = _restScheduledEndAt!.difference(now).inSeconds;
          _restDisplaySeconds = remaining > 0 ? remaining : 0;
          if (remaining <= 3 && remaining > 0) {
            SoundService.instance.play(SoundType.tick);
          }
          if (remaining <= 0) {
            // 倒计时结束
            final autoEnd = Storage.getSettings()['autoEndAfterRest'] as bool? ?? false;
            if (autoEnd) {
              _endRest(RestEndReason.autoTimeout,
                  actualSecondsOverride: _restScheduledSeconds);
            } else {
              _enterOvertimePhase();
            }
          }
        } else if (_restPhase == RestPhase.restingOvertime) {
          final overtime = now.difference(_restScheduledEndAt!).inSeconds;
          _restDisplaySeconds = overtime;
          if (now.isAfter(_restOvertimeLimitAt!)) {
            _endRest(RestEndReason.autoTimeout);
          }
        }
      });
    });
  }
```

- [ ] **Step 5: Add _enterOvertimePhase method**

Add after `_restartRestTimer`:

```dart
  /// 进入超时静默计时阶段
  void _enterOvertimePhase({bool skipSound = false}) {
    setState(() {
      _restPhase = RestPhase.restingOvertime;
      _restDisplaySeconds = 0;
    });
    // 前台时取消预约通知（_notifyRestEnd 已处理），避免重复
    if (_appLifecycleState == AppLifecycleState.resumed) {
      RestNotificationService.instance.cancelScheduledNotification();
    }
    _notifyRestEnd();
    _persistInProgressTraining();
  }
```

- [ ] **Step 6: Rewrite _skipRest and _endRest**

Find `_skipRest` method (around line 407). Replace with:

```dart
  void _skipRest() {
    _endRest(RestEndReason.skip);
  }
```

Add `_endRest` method (replaces the old `_advanceAfterRest` logic):

```dart
  /// 统一的休息结束收尾
  void _endRest(RestEndReason reason, {int? actualSecondsOverride}) {
    _restTimer?.cancel();

    // §1 修复：前台时取消预约通知，避免重复/延迟触发
    if (_appLifecycleState == AppLifecycleState.resumed) {
      RestNotificationService.instance.cancelScheduledNotification();
    }

    // 计算实际休息秒数
    final actualSeconds = actualSecondsOverride
        ?? (_restActualStartAt != null
            ? DateTime.now().difference(_restActualStartAt!).inSeconds
            : _restScheduledSeconds);

    if (_currentExIdx < _exercises.length) {
      _restLog.add({
        'exercise': _exercises[_currentExIdx]['name'],
        'scheduledRestSeconds': _restScheduledSeconds,
        'actualRestSeconds': actualSeconds,
        'restEndReason': reason.name,
      });
    }

    _lastRestActualSeconds = actualSeconds;

    // 停止休息倒计时前台服务
    PlatformServices.liveView.stopRestLiveView();
    _pushTrainingToWidget(restSkipped: reason == RestEndReason.skip);

    setState(() {
      _restPhase = RestPhase.idle;
      _restActualStartAt = null;
      _restScheduledEndAt = null;
      _restOvertimeLimitAt = null;
      _restEndReason = reason;

      // 推进到下一组/下一动作
      final currentEx = _currentExIdx < _exercises.length ? _exercises[_currentExIdx] : null;
      final totalSets = currentEx != null ? (currentEx['sets'] as int?) ?? 0 : 0;
      if (_currentSetIdx + 1 >= totalSets) {
        // 当前动作最后一组完成，推进到下一个动作
        _currentExIdx++;
        _currentSetIdx = 0;
      } else {
        _currentSetIdx++;
      }
      _prefillWeightReps();
    });

    _persistInProgressTraining();
  }
```

Remove the old `_advanceAfterRest` method entirely.

- [ ] **Step 7: Update _notifyRestEnd**

Find `_notifyRestEnd` (around line 417). Replace with:

```dart
  /// 休息结束时提醒
  Future<void> _notifyRestEnd() async {
    if (_restEndReason != null) return; // 已通知过

    final exerciseName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

    if (_appLifecycleState == AppLifecycleState.resumed) {
      if (PlatformServices.restReminder is! OhosRestReminderService) {
        await RestNotificationService.instance
            .showRestEndNotification(exerciseName: exerciseName);
      }
    }
  }
```

- [ ] **Step 8: Update _completeSet to cancel notifications on training done + add rest field**

Find `_completeSet` (around line 282). Update:

```dart
  Future<void> _completeSet() async {
    if (_currentExIdx >= _exercises.length) return;

    final currentEx = _exercises[_currentExIdx];
    final exId = currentEx['id'] as String;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    _setRecords[exId]!.add({
      'set': _currentSetIdx + 1,
      'weight': weight,
      'reps': reps,
      'rest': _lastRestActualSeconds,  // 上一组结束后的实际休息秒数
    });

    final totalSets = (currentEx['sets'] as int?) ?? 0;
    final isLastSet = _currentSetIdx + 1 >= totalSets;
    final isLastExercise = _currentExIdx + 1 >= _exercises.length;

    if (isLastSet && isLastExercise) {
      // 训练完成：取消所有待发通知（§1 修复）
      RestNotificationService.instance.cancelScheduledNotification();
      try {
        final settings = Storage.getSettings();
        final vibrationEnabled = settings['vibrationEnabled'] as bool? ?? true;
        if (vibrationEnabled) {
          await HapticFeedback.heavyImpact();
        }
      } catch (_) {}

      setState(() {
        _trainingDone = true;
      });
      SoundService.instance.play(SoundType.completeTraining);
      _autoSaveTraining();
    } else {
      SoundService.instance.play(SoundType.completeSet);
      final restTime = _getRestTimeForCurrentExercise();
      _startRest(restTime, isLastSet);
    }
  }
```

- [ ] **Step 9: Update _autoSaveTraining to cancel notifications + add pureDuration**

In `_autoSaveTraining` (around line 507), add at the beginning:

```dart
  Future<void> _autoSaveTraining() async {
    if (_isSaved) return;
    _isSaved = true;

    // §1 修复：训练完成时兜底取消所有待发通知
    RestNotificationService.instance.cancelScheduledNotification();

    // 清理进行中训练持久化
    Storage.clearInProgressTraining();

    final totalDurationSec = DateTime.now().difference(_startTime).inSeconds;
    final restTotalSec = _restLog.fold<int>(0, (sum, r) =>
        sum + ((r['actualRestSeconds'] as num?) ?? 0).toInt());
    final pureDurationSec = totalDurationSec - restTotalSec;
    final duration = (totalDurationSec / 60).round();
```

Update the `Storage.addRecord` call to include `pureDuration`:

```dart
    final savedRecord = Storage.addRecord({
      'name': _dayConfig?['label'] ?? '训练',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
      'pureDuration': pureDurationSec,
      'totalWeight': totalWeight,
      'totalSets': _completedSets,
      'exerciseCount': _exercises.length,
      'muscles': muscles.toList(),
      'setRecords': _setRecords.map((k, v) => MapEntry(k, v)),
      'restLog': _restLog,
      'planId': _plan?['id'],
      'planName': _plan?['name'],
    });
```

- [ ] **Step 10: Update didChangeAppLifecycleState and _onAppResumedFromBackground**

Find `didChangeAppLifecycleState` (around line 166). Update the resume check:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prevState = _appLifecycleState;
    _appLifecycleState = state;

    // 从后台恢复到前台时，修正倒计时
    if (prevState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed &&
        _restPhase != RestPhase.idle &&
        _restScheduledEndAt != null) {
      _onAppResumedFromBackground();
    }

    // App 进入后台时持久化（兜底）
    if (state == AppLifecycleState.paused) {
      _persistInProgressTraining();
    }
  }

  /// 应用从后台恢复时，根据 wall-clock 修正倒计时
  void _onAppResumedFromBackground() {
    final now = DateTime.now();
    if (_restPhase == RestPhase.resting) {
      if (now.isAfter(_restScheduledEndAt!) || now.isAtSameMomentAs(_restScheduledEndAt!)) {
        // 倒计时已结束
        final autoEnd = Storage.getSettings()['autoEndAfterRest'] as bool? ?? false;
        if (autoEnd) {
          _endRest(RestEndReason.autoTimeout,
              actualSecondsOverride: _restScheduledSeconds);
        } else {
          _enterOvertimePhase(skipSound: true);
        }
      } else {
        setState(() {
          _restDisplaySeconds = _restScheduledEndAt!.difference(now).inSeconds;
        });
      }
    } else if (_restPhase == RestPhase.restingOvertime) {
      if (now.isAfter(_restOvertimeLimitAt!)) {
        _endRest(RestEndReason.autoTimeout);
      }
    }
  }
```

- [ ] **Step 11: Update _onNotificationClicked**

Find `_onNotificationClicked` (around line 135). Update to use new state machine:

```dart
  void _onNotificationClicked(RestReminderEvent event) {
    if (!mounted) return;
    if (event.cardAction == 'skipRest') {
      _skipRest();
      return;
    }
    // 通知点击回到训练页：如果休息已超时，直接结束
    if (_restPhase == RestPhase.restingOvertime) {
      _endRest(RestEndReason.manual);
    } else if (_restPhase == RestPhase.resting && _restScheduledEndAt != null) {
      final now = DateTime.now();
      if (now.isAfter(_restScheduledEndAt!)) {
        _endRest(RestEndReason.manual);
      }
    }
  }
```

- [ ] **Step 12: Update rest UI overlay button text**

Find the rest overlay UI (search for "跳过休息" or the rest button). Update the button to change text based on `_restPhase`:

The rest button should show:
- `RestPhase.resting` (倒计时中): "跳过休息"
- `RestPhase.restingOvertime` (已超时): "结束休息" (highlighted)

And the display should show:
- `resting`: remaining seconds (e.g. "90s")
- `restingOvertime`: "+Ns" (overtime seconds)

Search for `_restSeconds` usage in the UI and update to show `+_restDisplaySeconds` when in overtime.

- [ ] **Step 13: Add _persistInProgressTraining method**

Add this method to the state class:

```dart
  /// 持久化进行中训练到 Storage
  Future<void> _persistInProgressTraining() async {
    if (_trainingDone || _exercises.isEmpty) return;
    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      final data = <String, dynamic>{
        'version': 1,
        'startedAt': _startTime.millisecondsSinceEpoch,
        'startedAtDate': today,
        'planId': _plan?['id'],
        'planName': _plan?['name'],
        'dayConfig': _dayConfig,
        'exercises': _exercises,
        'currentExIdx': _currentExIdx,
        'currentSetIdx': _currentSetIdx,
        'setRecords': _setRecords.map((k, v) => MapEntry(k, v)),
        'restLog': _restLog,
        'restPhaseSnapshot': _restPhase != RestPhase.idle ? {
          'phase': _restPhase.name,
          'scheduledSeconds': _restScheduledSeconds,
          'actualStartAt': _restActualStartAt?.millisecondsSinceEpoch,
          'scheduledEndAt': _restScheduledEndAt?.millisecondsSinceEpoch,
          'overtimeLimitAt': _restOvertimeLimitAt?.millisecondsSinceEpoch,
        } : null,
      };
      await Storage.saveInProgressTraining(data);
    } catch (e) {
      debugPrint('_persistInProgressTraining error: $e');
    }
  }
```

- [ ] **Step 14: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/training_page.dart`
Expected: No errors (may have warnings about unused imports)

- [ ] **Step 15: Commit**

```bash
cd fittrack_flutter
git add lib/pages/training_page.dart
git commit -m "feat: rest state machine refactor + notification bug fix + persistence triggers"
```

---

## Task 6: 记录字段扩展与 restLog/setRecords bug 修复

**Files:**
- Modify: `fittrack_flutter/lib/pages/record_detail_page.dart` (字段读取修复)

**Interfaces:**
- Consumes: New restLog format from Task 5 (`scheduledRestSeconds`/`actualRestSeconds`/`restEndReason`)
- Consumes: `pureDuration` field from Task 5

- [ ] **Step 1: Fix restLog field reading in record_detail_page**

In `fittrack_flutter/lib/pages/record_detail_page.dart`, find the restLog rendering (around line 229). Update field names with fallback:

```dart
                  children: restLog.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final log = entry.value;
                    final logMap = log is Map<String, dynamic> ? log : <String, dynamic>{};
                    // 新格式字段，fallback 兼容旧数据
                    final exercise = logMap['exercise'] as String? ?? '';
                    final scheduled = (logMap['scheduledRestSeconds'] as num?)?.toInt()
                                  ?? (logMap['restTime'] as num?)?.toInt() ?? 0;
                    final actual = (logMap['actualRestSeconds'] as num?)?.toInt()
                                ?? (logMap['actualTime'] as num?)?.toInt() ?? 0;
                    final reason = logMap['restEndReason'] as String? ?? 'manual';
                    final skipped = reason == 'skip';
                    return Padding(
                      padding: EdgeInsets.only(bottom: idx < restLog.length - 1 ? 8 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: skipped ? colors.warningColor : colors.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              exercise.isNotEmpty ? exercise : '休息 ${idx + 1}',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Text(
                            skipped ? '已跳过' : '$actual秒',
                            style: TextStyle(
                              color: skipped ? colors.warningColor : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
```

- [ ] **Step 2: Add pureDuration display**

In `record_detail_page.dart`, find the stats area where `duration` is displayed. Add pureDuration next to duration. Find the duration display and add:

```dart
// 如果有 pureDuration 数据，显示纯训练时长
final pureDuration = record['pureDuration'] as num?;
if (pureDuration != null && pureDuration > 0) {
  final pureMin = (pureDuration.toInt() / 60).round();
  // 在时长统计旁增加"纯训练 Xmin"
}
```

- [ ] **Step 3: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/record_detail_page.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
cd fittrack_flutter
git add lib/pages/record_detail_page.dart
git commit -m "fix: restLog field name compatibility and pureDuration display"
```

---

## Task 7: 跨天恢复流程

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart` (_checkInProgressTraining, _restoreRestPhase)

**Interfaces:**
- Consumes: `Storage.getInProgressTraining()` from Task 1
- Produces: `_checkInProgressTraining()`, `_restoreRestPhase()`, `_autoSaveAsIncomplete()`

- [ ] **Step 1: Add _checkInProgressTraining method**

In `fittrack_flutter/lib/pages/training_page.dart`, add to `_loadData()` at the end (before `setState(() {})`):

```dart
  void _loadData() {
    // ... existing loading code ...

    // 检查是否有进行中的训练（持久化恢复）
    _checkInProgressTraining();

    setState(() {});

    // 进入训练页后推送训练态到桌面卡片
    _pushTrainingToWidget();
  }
```

Add the method:

```dart
  /// 检查是否有进行中的训练
  void _checkInProgressTraining() {
    final inProgress = Storage.getInProgressTraining();
    if (inProgress == null) return;

    final startedAtDate = inProgress['startedAtDate'] as String?;
    if (startedAtDate == null) return;

    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    if (startedAtDate == today) {
      // 同天：恢复进行中训练
      _restoreInProgressTraining(inProgress);
    } else {
      // 跨天：弹窗让用户选择
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCrossDayDialog(inProgress);
      });
    }
  }

  /// 恢复同天进行中的训练
  void _restoreInProgressTraining(Map<String, dynamic> data) {
    try {
      _startTime = DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);
      _plan = data['planId'] != null ? Storage.getPlanById(data['planId'] as String) : null;
      _plan?['currentDayIndex'] = data['currentExIdx']; // 不恢复此字段
      _dayConfig = data['dayConfig'] as Map<String, dynamic>?;
      final exList = _dayConfig?['exercises'] as List<dynamic>? ?? [];
      _exercises = List<Map<String, dynamic>>.from(
        exList.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      _currentExIdx = data['currentExIdx'] as int? ?? 0;
      _currentSetIdx = data['currentSetIdx'] as int? ?? 0;

      // 恢复 setRecords
      final setRecords = data['setRecords'] as Map<String, dynamic>?;
      if (setRecords != null) {
        for (final ex in _exercises) {
          final exId = ex['id'] as String;
          final records = setRecords[exId] as List?;
          _setRecords[exId] = records != null
              ? List<Map<String, dynamic>>.from(
                  records.map((r) => Map<String, dynamic>.from(r as Map)))
              : [];
        }
      }

      // 恢复 restLog
      final restLog = data['restLog'] as List?;
      if (restLog != null) {
        _restLog.clear();
        _restLog.addAll(
          restLog.map((r) => Map<String, dynamic>.from(r as Map)),
        );
      }

      // 恢复休息阶段
      final snapshot = data['restPhaseSnapshot'] as Map<String, dynamic>?;
      if (snapshot != null && snapshot['phase'] != null) {
        _restoreRestPhase(snapshot);
      }

      _prefillWeightReps();
    } catch (e) {
      debugPrint('_restoreInProgressTraining error: $e');
      Storage.clearInProgressTraining();
    }
  }

  /// 恢复休息阶段（wall-clock 校正）
  void _restoreRestPhase(Map<String, dynamic> snapshot) {
    _restScheduledSeconds = snapshot['scheduledSeconds'] as int? ?? 0;
    final actualStartMs = snapshot['actualStartAt'] as int?;
    final scheduledEndMs = snapshot['scheduledEndAt'] as int?;
    final overtimeLimitMs = snapshot['overtimeLimitAt'] as int?;

    if (actualStartMs != null) {
      _restActualStartAt = DateTime.fromMillisecondsSinceEpoch(actualStartMs);
    }
    if (scheduledEndMs != null) {
      _restScheduledEndAt = DateTime.fromMillisecondsSinceEpoch(scheduledEndMs);
    }
    if (overtimeLimitMs != null) {
      _restOvertimeLimitAt = DateTime.fromMillisecondsSinceEpoch(overtimeLimitMs);
    }

    final phaseStr = snapshot['phase'] as String?;
    final now = DateTime.now();
    final lastPersistedAt = snapshot['lastPersistedAt'] as int? ?? 0;

    // 兜底：lastPersistedAt > 5分钟且休息中
    if (lastPersistedAt > 0 &&
        now.millisecondsSinceEpoch - lastPersistedAt > 5 * 60 * 1000) {
      _endRest(RestEndReason.autoTimeout,
          actualSecondsOverride: _restActualStartAt != null
              ? DateTime.fromMillisecondsSinceEpoch(lastPersistedAt)
                  .difference(_restActualStartAt!).inSeconds
              : _restScheduledSeconds);
      return;
    }

    if (phaseStr == 'resting') {
      if (now.isBefore(_restScheduledEndAt!)) {
        _restPhase = RestPhase.resting;
        _restDisplaySeconds = _restScheduledEndAt!.difference(now).inSeconds;
      } else {
        _enterOvertimePhase(skipSound: true);
        return;
      }
    } else if (phaseStr == 'restingOvertime') {
      if (now.isBefore(_restOvertimeLimitAt!)) {
        _restPhase = RestPhase.restingOvertime;
        _restDisplaySeconds = now.difference(_restScheduledEndAt!).inSeconds;
      } else {
        _endRest(RestEndReason.autoTimeout);
        return;
      }
    }

    _restartRestTimer();
  }
```

- [ ] **Step 2: Add cross-day dialog**

```dart
  /// 跨天恢复弹窗
  void _showCrossDayDialog(Map<String, dynamic> data) {
    final planName = data['planName'] as String? ?? '训练';
    final startedAtDate = data['startedAtDate'] as String? ?? '';
    final completedSets = (data['setRecords'] as Map?)?.values
        .fold<int>(0, (sum, list) => sum + (list as List).length) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('上次训练未完成'),
        content: Text('您在 $startedAtDate 开始的"$planName"训练未完成，'
            '已完成 $completedSets 组。\n\n保存为训练记录（以当前时间为结束）?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _autoSaveAsIncomplete(data);
            },
            child: const Text('保存为记录'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Storage.clearInProgressTraining();
            },
            child: const Text('丢弃'),
          ),
        ],
      ),
    );
  }

  /// 跨天时将未完成的训练保存为记录
  Future<void> _autoSaveAsIncomplete(Map<String, dynamic> data) async {
    try {
      final startedAt = DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);
      final duration = DateTime.now().difference(startedAt).inMinutes;
      final setRecords = (data['setRecords'] as Map?)?.map((k, v) =>
          MapEntry(k as String, List<Map<String, dynamic>>.from(
              (v as List).map((r) => Map<String, dynamic>.from(r as Map))))) ?? {};
      final completedSets = setRecords.values.fold<int>(0, (sum, list) => sum + list.length);

      await Storage.addRecord({
        'name': data['planName'] ?? '未完成训练',
        'date': DateTime.now().millisecondsSinceEpoch,
        'duration': duration,
        'pureDuration': duration * 60,
        'totalWeight': 0,
        'totalSets': completedSets,
        'exerciseCount': (data['exercises'] as List?)?.length ?? 0,
        'muscles': [],
        'setRecords': setRecords,
        'restLog': data['restLog'] ?? [],
        'planId': data['planId'],
        'planName': data['planName'],
      });
      await Storage.clearInProgressTraining();
    } catch (e) {
      debugPrint('_autoSaveAsIncomplete error: $e');
    }
  }
```

- [ ] **Step 3: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/training_page.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
cd fittrack_flutter
git add lib/pages/training_page.dart
git commit -m "feat: cross-day training recovery and in-progress restore"
```

---

## Task 8: 设置项 UI — autoEndAfterRest 开关

**Files:**
- Modify: `fittrack_flutter/lib/pages/reminder_settings_page.dart`

**Interfaces:**
- Consumes: `autoEndAfterRest` setting from Task 1

- [ ] **Step 1: Add autoEndAfterRest switch to reminder_settings_page**

In `fittrack_flutter/lib/pages/reminder_settings_page.dart`, find the "休息提醒" section. Add a new switch tile after the vibration switch (查找 `振动提醒` 或现有的 SwitchTile 模式):

```dart
                _buildSwitchTile(
                  colors,
                  PhosphorIcons.timer,
                  '休息结束后自动结束',
                  '到点自动结束并关闭休息弹窗, 适合自制力强的用户',
                  Storage.getSettings()['autoEndAfterRest'] as bool? ?? false,
                  (v) => _saveSetting('autoEndAfterRest', v),
                ),
```

Follow the existing `_buildSwitchTile` and `_saveSetting` pattern used by other switches in the same file.

- [ ] **Step 2: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/reminder_settings_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd fittrack_flutter
git add lib/pages/reminder_settings_page.dart
git commit -m "feat: add autoEndAfterRest setting toggle"
```

---

## Task 9: RestPreferenceService + 推荐卡片

**Files:**
- Create: `fittrack_flutter/lib/services/rest_preference_service.dart`
- Modify: `fittrack_flutter/lib/pages/add_plan_page.dart`
- Test: `fittrack_flutter/test/rest_preference_service_test.dart`

**Interfaces:**
- Consumes: `Storage.getAllRecords()` with `restLog` from Task 5/6
- Produces: `RestPreferenceService.isPreferenceAvailable()`, `RestPreferenceService.computeRecommendedRestSeconds()`

- [ ] **Step 1: Write failing test for RestPreferenceService**

Create `fittrack_flutter/test/rest_preference_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/rest_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('isPreferenceAvailable returns false with no records', () {
    expect(RestPreferenceService.instance.isPreferenceAvailable(), false);
  });

  test('isPreferenceAvailable returns false within 7 days', () async {
    final now = DateTime.now();
    await Storage.addRecord({
      'name': 'test',
      'date': now.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
    });
    expect(RestPreferenceService.instance.isPreferenceAvailable(), false);
  });

  test('computeRecommendedRestSeconds returns null with insufficient data', () {
    expect(RestPreferenceService.instance.computeRecommendedRestSeconds(), null);
  });

  test('computeRecommendedRestSeconds returns value with sufficient data', () async {
    final now = DateTime.now();
    final oldDate = now.subtract(Duration(days: 10));
    // Create a record 10 days ago with rest log
    await Storage.addRecord({
      'name': 'test',
      'date': oldDate.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
      'restLog': [
        {'exercise': 'bench', 'scheduledRestSeconds': 90, 'actualRestSeconds': 95, 'restEndReason': 'manual'},
        {'exercise': 'squat', 'scheduledRestSeconds': 90, 'actualRestSeconds': 100, 'restEndReason': 'manual'},
        {'exercise': 'row', 'scheduledRestSeconds': 90, 'actualRestSeconds': 85, 'restEndReason': 'manual'},
      ],
    });
    // Create a recent record
    await Storage.addRecord({
      'name': 'test2',
      'date': now.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
      'restLog': [
        {'exercise': 'bench', 'scheduledRestSeconds': 90, 'actualRestSeconds': 90, 'restEndReason': 'manual'},
      ],
    });

    final result = RestPreferenceService.instance.computeRecommendedRestSeconds();
    expect(result, isNotNull);
    expect(result! >= 15, true);
    expect(result <= 600, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd fittrack_flutter && flutter test test/rest_preference_service_test.dart`
Expected: FAIL — `RestPreferenceService` not found

- [ ] **Step 3: Create RestPreferenceService**

Create `fittrack_flutter/lib/services/rest_preference_service.dart`:

```dart
import '../data/storage.dart';

/// 休息时间偏好推荐服务
///
/// 基于用户历史训练记录中的实际休息时间，计算推荐的休息秒数。
/// 需要用户首次训练满 7 天后才会提供推荐。
class RestPreferenceService {
  static final RestPreferenceService instance = RestPreferenceService._();
  RestPreferenceService._();

  /// 是否已满足推荐条件：用户首次训练满 7 天
  bool isPreferenceAvailable() {
    final records = Storage.getAllRecords();
    if (records.isEmpty) return false;

    final earliest = records.reduce((a, b) =>
        (a['date'] as num) < (b['date'] as num) ? a : b);
    final firstTrainingDate =
        DateTime.fromMillisecondsSinceEpoch((earliest['date'] as num).toInt());
    return DateTime.now().difference(firstTrainingDate).inDays >= 7;
  }

  /// 计算推荐休息秒数，数据不足返回 null
  int? computeRecommendedRestSeconds() {
    if (!isPreferenceAvailable()) return null;

    final records = Storage.getAllRecords();
    final allActuals = <int>[];

    // 取最近 10 条 records 的 restLog
    for (final r in records.take(10)) {
      final restLog = r['restLog'] as List? ?? [];
      for (final log in restLog) {
        final logMap = log is Map<String, dynamic>
            ? log
            : Map<String, dynamic>.from(log as Map);
        // 兼容新旧字段
        final actual = (logMap['actualRestSeconds'] as num?)?.toInt()
                    ?? (logMap['actualTime'] as num?)?.toInt();
        final reason = logMap['restEndReason'] as String?;
        // 过滤掉自动超时上限结算的异常记录
        if (actual != null && actual > 0 && reason != 'autoTimeout') {
          allActuals.add(actual);
        }
      }
    }

    if (allActuals.length < 3) return null; // 至少 3 条有效样本

    // IQR 异常过滤
    allActuals.sort();
    final q1 = _percentile(allActuals, 25);
    final q3 = _percentile(allActuals, 75);
    final iqr = q3 - q1;
    final lower = q1 - 1.5 * iqr;
    final upper = q3 + 1.5 * iqr;
    final filtered = allActuals.where((s) => s >= lower && s <= upper).toList();

    if (filtered.isEmpty) return null;

    // 加权平均：越近期权重越高（线性递增）
    double weightedSum = 0;
    double weightSum = 0;
    for (var i = 0; i < filtered.length; i++) {
      final w = (i + 1).toDouble();
      weightedSum += filtered[i] * w;
      weightSum += w;
    }
    final avg = (weightedSum / weightSum).round();
    // 取 5 秒为粒度对齐
    final aligned = ((avg + 2.5) ~/ 5) * 5;
    // 钳制到合理区间 [15, 600]
    return aligned.clamp(15, 600);
  }

  int _percentile(List<int> sorted, int p) {
    final idx = (p / 100 * (sorted.length - 1)).round();
    return sorted[idx.clamp(0, sorted.length - 1)];
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd fittrack_flutter && flutter test test/rest_preference_service_test.dart`
Expected: PASS

- [ ] **Step 5: Add recommendation card to add_plan_page**

In `fittrack_flutter/lib/pages/add_plan_page.dart`, find the rest time input field. Add a recommendation card below it:

```dart
// 在休息时间输入框下方添加推荐卡片
Widget _buildRestRecommendationCard() {
  final recommended = RestPreferenceService.instance.computeRecommendedRestSeconds();
  if (recommended == null) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.accentGlow.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.lightbulb, color: colors.accentGlow, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '根据您的历史组间休息偏好, 推荐休息时间 $recommended 秒',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () => _restTimeController.text = recommended.toString(),
          child: const Text('应用'),
        ),
      ],
    ),
  );
}
```

Add import: `import '../services/rest_preference_service.dart';`

Call `_buildRestRecommendationCard()` in the build method right after the rest time input field.

- [ ] **Step 6: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/services/rest_preference_service.dart lib/pages/add_plan_page.dart`
Expected: No errors

- [ ] **Step 7: Commit**

```bash
cd fittrack_flutter
git add lib/services/rest_preference_service.dart lib/pages/add_plan_page.dart test/rest_preference_service_test.dart
git commit -m "feat: rest preference recommendation service and plan edit card"
```

---

## Task 10: 30秒定时持久化兜底 + 退出时清理

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart`

- [ ] **Step 1: Add periodic persistence timer**

In `_TrainingPageState`, add a periodic timer field and initialize/clean it:

```dart
  // ── 持久化兜底定时器 ─────────────────────────────────────────
  Timer? _persistenceTimer;
```

In `initState()`, after `_loadData()`:

```dart
    // 每 30 秒定时持久化（兜底防异常杀进程）
    _persistenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _persistInProgressTraining();
    });
```

In `dispose()`:

```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _persistenceTimer?.cancel();
    _restReminderSub?.cancel();
    _liveViewSub?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Update _onBackPressed to clear in-progress training**

Find `_onBackPressed` (around line 160). Update:

```dart
  void _onBackPressed() {
    // 主动退出：清理进行中训练持久化
    if (!_trainingDone) {
      Storage.clearInProgressTraining();
    }
    _resetWidgetOnExit();
    context.pop();
  }
```

- [ ] **Step 3: Verify build compiles**

Run: `cd fittrack_flutter && flutter analyze lib/pages/training_page.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
cd fittrack_flutter
git add lib/pages/training_page.dart
git commit -m "feat: periodic persistence timer and exit cleanup"
```

---

## Self-Review Notes

### Spec Coverage
- §1 通知 bug 修复 → Task 5 (Step 6, 8, 9) ✓
- §2 iOS/Android 权限修复 → Task 2 ✓
- §3 积分提示 → Task 3 ✓
- §4 皮肤预览 → Task 4 ✓
- §5.1-5.4 休息状态机 → Task 5 ✓
- §5.5 Storage 持久化 → Task 1 (methods) + Task 5 (trigger) + Task 7 (restore) + Task 10 (periodic) ✓
- §5.6 schema v9 → Task 1 ✓
- §5.7 pureDuration → Task 5 (Step 9) ✓
- §5.8 restLog/setRecords → Task 5 (Step 6, 8) + Task 6 ✓
- §5.9 跨天恢复 → Task 7 ✓
- §5.10 设置项 → Task 8 ✓
- §5.11 RestPreferenceService → Task 9 ✓

### Task Dependencies
- Task 1: Foundation (no deps)
- Task 2: Independent (no deps on Task 1)
- Task 3: Independent
- Task 4: Independent
- Task 5: Depends on Task 1 (Storage methods, settings defaults)
- Task 6: Depends on Task 5 (new restLog format)
- Task 7: Depends on Task 1, 5 (Storage methods, state machine)
- Task 8: Depends on Task 1 (settings default)
- Task 9: Depends on Task 5/6 (restLog format)
- Task 10: Depends on Task 5 (persistence method)

### Parallelizable
Tasks 1, 2, 3, 4 can run in parallel. Task 5 is the critical path.
