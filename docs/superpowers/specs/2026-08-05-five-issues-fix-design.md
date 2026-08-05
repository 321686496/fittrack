# 五项问题修复设计

- **日期**：2026-08-05
- **范围**：训练结束通知 bug、iOS/Android 后台提醒兼容、训练完成积分提示、未解锁皮肤预览、训练持久化（完整方案）
- **状态**：已确认
- **依赖前置**：2026-07-31 休息计时与持久化设计（本设计为其完整实现方案）

---

## §1 训练结束后仍发送代理提醒的 Bug 修复

### 1.1 根因

`_completeSet()` 中 `isLastSet && isLastExercise` 分支调用 `_autoSaveTraining()`，但未取消已预约的定时通知。

更深层问题在 `_restartRestTimer()` 的 `remaining <= 0` 分支：

```dart
if (remaining <= 0) {
  timer.cancel();
  // 不取消预约通知！让系统通知自然触发（后台时需要）
  _notifyRestEnd();
  _advanceAfterRest();
}
```

休息自然结束时**不取消预约通知**（设计意图是让后台时系统通知自然触发），导致：
1. 前台时 `_notifyRestEnd()` 已显示通知，预约通知稍后再次触发 → 重复
2. 用户快速完成下一组（最后一组）→ 训练结束 → 预约通知延迟触发 → "训练结束后又收到休息结束通知"

### 1.2 修复方案

**前台休息结束时取消预约通知**：在 `_restartRestTimer()` 的 `remaining <= 0` 分支中，根据 `_appLifecycleState` 决定：
- `resumed`（前台）：取消预约通知（`_notifyRestEnd()` 已显示），避免重复
- `paused`（后台）：不取消，让系统通知自然触发

**训练完成时兜底取消**：在 `_completeSet()` 的训练完成分支和 `_autoSaveTraining()` 开头都调用 `RestNotificationService.instance.cancelScheduledNotification()`。

**`_advanceAfterRest()` 中增加取消逻辑**：休息结束推进到下一组时，如果当前在前台，取消预约通知。

### 1.3 改动文件

- `fittrack_flutter/lib/pages/training_page.dart`

---

## §2 iOS/Android 后台提醒兼容修复

### 2.1 iOS 修复

**问题**：通知权限未请求
- `RestNotificationService.init()` 中 `DarwinInitializationSettings` 设置 `requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false`
- `_requestNotificationPermission()` 只处理 Android 分支，iOS 分支缺失

**修复**：

`RestNotificationService._requestNotificationPermission()` 增加 iOS 分支：

```dart
final iosPlugin = _plugin!.resolvePlatformSpecificImplementation<
    IOSFlutterLocalNotificationsPlugin>();
if (iosPlugin != null) {
  final result = await iosPlugin.requestPermissions(
    alert: true, badge: true, sound: true,
  );
  return result ?? false;
}
```

`DarwinInitializationSettings` 保持 `requestAlertPermission: false`（不在 init 时弹权限框），改为在 `_requestNotificationPermission()` 中显式请求，与 Android 保持一致。

`AppDelegate.swift` 通知委托已正确设置（`willPresent` 前台显示通知，`didReceive` 处理点击回传），无需修改。

### 2.2 Android 修复

**问题**：`AlarmReceiver` 未检查通知权限
- Android 13+ 需要 `POST_NOTIFICATIONS` 权限才能调用 `NotificationManager.notify()`
- `AlarmReceiver.showNotification()` 中 `manager.notify()` 在权限被拒绝时静默失败

**修复**：在 `AlarmReceiver.onReceive()` 中增加权限检查：

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    val granted = ContextCompat.checkSelfPermission(
        context, Manifest.permission.POST_NOTIFICATIONS
    ) == PackageManager.PERMISSION_GRANTED
    if (!graced) {
        Log.w("AlarmReceiver", "POST_NOTIFICATIONS not granted")
        return
    }
}
```

通知渠道重复创建（`flutter_local_notifications` 和 `AlarmReceiver` 都创建 `rest_channel`）是安全的，Android 系统会忽略重复创建。

### 2.3 统一权限请求流程

- `PermissionService.requestCorePermissions()` 已在 `main.dart` 中调用，请求 `Permission.notification`
- `TrainingPage.initState()` 增加权限检查：如果通知权限未授予，弹窗提示用户去设置开启

### 2.4 改动文件

| 文件 | 改动 |
|---|---|
| `fittrack_flutter/lib/services/rest_notification_service.dart` | `_requestNotificationPermission()` 增加 iOS 分支 |
| `fittrack_flutter/android/app/src/main/kotlin/com/lt/lifttrack/AlarmReceiver.kt` | 增加 `POST_NOTIFICATIONS` 权限检查 |
| `fittrack_flutter/lib/pages/training_page.dart` | `initState` 增加权限引导 |

---

## §3 训练完成积分提示

### 3.1 PointsService 返回值改为 int

`PointsService.addDailyTrainingPoints()` 当前返回 `Future<bool>`，改为返回实际获得的积分数：

```dart
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

### 3.2 _autoSaveTraining 传递积分

```dart
final earnedPoints = await PointsService.instance.addDailyTrainingPoints();
// ... 成就检查 ...
await CelebrationDialog.show(
  context,
  totalWeight: totalWeight,
  totalSets: _completedSets,
  duration: duration,
  recordId: _savedRecordId ?? '',
  earnedPoints: earnedPoints,
);
```

### 3.3 CelebrationDialog 增加积分展示

在训练数据摘要 `Row` 中，根据 `earnedPoints > 0` 条件增加一项：

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _stat(colors, '${totalWeight}kg', '总重量'),
    _stat(colors, '$totalSets', '总组数'),
    _stat(colors, '${duration}min', '时长'),
    if (earnedPoints > 0)
      _stat(colors, '+$earnedPoints', '本次积分',
            icon: Icons.stars, color: colors.accentGlow),
  ],
),
```

如果 `earnedPoints == 0`（今日已领过），不显示积分项。

### 3.4 改动文件

| 文件 | 改动 |
|---|---|
| `fittrack_flutter/lib/services/points_service.dart` | `addDailyTrainingPoints` 返回 `Future<int>` |
| `fittrack_flutter/lib/pages/training_page.dart` | `_autoSaveTraining` 传递 `earnedPoints` |
| `fittrack_flutter/lib/widgets/celebration_dialog.dart` | 增加 `earnedPoints` 参数和积分展示 |

---

## §4 未解锁皮肤点击预览

### 4.1 _buildSkinTile 增加点击预览

对未解锁皮肤包裹 `GestureDetector`，点击弹出底部 sheet：

```dart
return GestureDetector(
  onTap: unlocked ? null : () => _showSkinPreview(colors, good, skinCfg),
  child: Container(/* 现有皮肤卡片 */),
);
```

### 4.2 _showSkinPreview 方法

弹出底部 sheet，展示完整皮肤渲染：

```dart
void _showSkinPreview(LiftTrackColors colors, VirtualGood good, OpponentSkinConfig skinCfg) {
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
      onPurchase: () {
        Navigator.of(ctx).pop();
        _purchaseSkin(good.id);
      },
      onInvite: () {
        Navigator.of(ctx).pop();
        context.push('/invitation');
      },
      unlocking: _unlocking,
    ),
  );
}
```

### 4.3 _SkinPreviewSheet 组件

布局结构：

```
┌─────────────────────────────────┐
│         [皮肤名称]               │
│   ┌─────────────────────────┐   │
│   │   OpponentRenderer      │   │  ← 完整渲染皮肤形象（含动画）
│   │   (200x200)             │   │
│   └─────────────────────────┘   │
│   皮肤特色：[signatureMove]      │
│   价格：[pointsCost]            │
│   解锁条件：[unlockCondition]    │
│   ┌─────────────────────────┐   │
│   │  积分购买 (100积分)      │   │  ← 购买按钮（可购买时）
│   └─────────────────────────┘   │
│   ┌─────────────────────────┐   │
│   │  邀请好友解锁            │   │  ← 邀请入口（ambassador限定款）
│   └─────────────────────────┘   │
└─────────────────────────────────┘
```

- 使用 `OpponentRenderer` 渲染皮肤完整形象（face + outfit + prop + 动画）
- 显示皮肤名称、招牌动作 `signatureMove`、价格 `pointsCost`
- 可购买皮肤（`isPurchasableWithPoints`）：显示购买按钮
- ambassador 限定款：显示"邀请好友解锁"按钮，跳转 `/invitation`
- 已解锁皮肤不触发预览（`onTap: null`）

### 4.4 改动文件

| 文件 | 改动 |
|---|---|
| `fittrack_flutter/lib/pages/opponent_detail_page.dart` | `_buildSkinTile` 增加 `GestureDetector` + 新增 `_showSkinPreview` + `_SkinPreviewSheet` |

---

## §5 训练持久化（完整方案）

基于 2026-07-31 设计文档，完整实现以下功能。

### 5.1 休息状态机重构

替换现有 `_isResting/_restSeconds/_totalRestSeconds/_restEndTime/_restEndNotified` 字段：

```dart
enum RestPhase { idle, resting, restingOvertime }
enum RestEndReason { manual, autoTimeout, skip }

RestPhase _restPhase = RestPhase.idle;
int _restScheduledSeconds = 0;
DateTime? _restActualStartAt;
DateTime? _restScheduledEndAt;
DateTime? _restOvertimeLimitAt;
RestEndReason? _restEndReason;
int _restDisplaySeconds = 0;
int _lastRestActualSeconds = 0;
```

**状态转换**：
- `idle → resting`：用户完成一组（非最后一组），`_startRest()`
- `resting → restingOvertime`：倒计时到 0，`_enterOvertimePhase()`
- `resting → idle`：用户点击"跳过休息"，`_endRest(skip)`
- `restingOvertime → idle`：用户点击"结束休息" 或 超时上限到达，`_endRest(manual/autoTimeout)`

**计时主循环**（基于 wall-clock 校正）：

```dart
void _restartRestTimer() {
  _restTimer?.cancel();
  _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (_restPhase == RestPhase.idle) { timer.cancel(); return; }
    final now = DateTime.now();
    setState(() {
      if (_restPhase == RestPhase.resting) {
        final remaining = _restScheduledEndAt!.difference(now).inSeconds;
        _restDisplaySeconds = remaining > 0 ? remaining : 0;
        if (remaining <= 3 && remaining > 0) {
          SoundService.instance.play(SoundType.tick);
        }
        if (remaining <= 0) {
          _enterOvertimePhase();
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

### 5.2 按钮文案与行为

| 阶段 | 按钮文案 | 行为 |
|---|---|---|
| `resting`（倒计时进行中） | "跳过休息" | `_endRest(RestEndReason.skip)` |
| `restingOvertime`（已超时静默中） | "结束休息"（高亮） | `_endRest(RestEndReason.manual)` |
| `restingOvertime` 且到达上限 | 自动结束 | `_endRest(RestEndReason.autoTimeout)` |

### 5.3 _endRest 统一收尾

```dart
void _endRest(RestEndReason reason, {int? actualSecondsOverride}) {
  _restTimer?.cancel();
  // 前台时取消预约通知（§1 修复）
  if (_appLifecycleState == AppLifecycleState.resumed) {
    RestNotificationService.instance.cancelScheduledNotification();
  }
  final actualSeconds = actualSecondsOverride
      ?? DateTime.now().difference(_restActualStartAt!).inSeconds;

  _restLog.add({
    'exercise': _exercises[_currentExIdx]['name'],
    'scheduledRestSeconds': _restScheduledSeconds,
    'actualRestSeconds': actualSeconds,
    'restEndReason': reason.name,
  });

  _lastRestActualSeconds = actualSeconds;
  _pushTrainingToWidget(restSkipped: reason == RestEndReason.skip);

  setState(() {
    _restPhase = RestPhase.idle;
    _restActualStartAt = null;
    _restScheduledEndAt = null;
    _restOvertimeLimitAt = null;
    _restEndReason = reason;
  });

  _advanceToNextSet();
  _persistInProgressTraining();
}
```

### 5.4 autoEndAfterRest 设置

当 `Storage.getSettings()['autoEndAfterRest'] == true` 时：
- 倒计时到 0 后不进入 `restingOvertime` 阶段，直接调用 `_endRest(RestEndReason.autoTimeout)`
- actualRestSeconds 等于 scheduledRestSeconds（不会超时）

### 5.5 Storage 持久化

**新增 3 个方法**（SharedPreferences，独立 key `fittrack_in_progress_training`）：

```dart
static const _inProgressKey = 'fittrack_in_progress_training';

static Future<void> saveInProgressTraining(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  data['lastPersistedAt'] = DateTime.now().millisecondsSinceEpoch;
  await prefs.setString(_inProgressKey, jsonEncode(data));
}

static Map<String, dynamic>? getInProgressTraining() {
  final prefs = _store;
  final raw = prefs.getString(_inProgressKey);
  if (raw == null) return null;
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

static Future<void> clearInProgressTraining() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_inProgressKey);
}
```

**JSON 结构**：

```json
{
  "version": 1,
  "startedAt": 1722400000000,
  "startedAtDate": "2026-08-05",
  "planId": "plan_xxx",
  "planName": "胸部+三头肌",
  "dayConfig": {...},
  "exercises": [...],
  "currentExIdx": 2,
  "currentSetIdx": 1,
  "setRecords": {
    "ex1": [{"set":1,"weight":60,"reps":10,"rest":105}]
  },
  "restLog": [
    {"exercise":"卧推","scheduledRestSeconds":90,"actualRestSeconds":105,"restEndReason":"manual"}
  ],
  "lastPersistedAt": 1722400123456,
  "restPhaseSnapshot": {
    "phase": "resting",
    "scheduledSeconds": 90,
    "actualStartAt": 1722400090000,
    "scheduledEndAt": 1722400180000,
    "overtimeLimitAt": 1722400450000
  }
}
```

**持久化触发点**：

| 时机 | 触发位置 | 必要性 |
|---|---|---|
| 训练开始 | `_startTraining()` | 高 |
| 完成一组 | `_completeSet()` 写入 setRecords 后 | 高 |
| 开始休息 | `_startRest()` | 高（含休息快照） |
| 切换休息阶段 | `_enterOvertimePhase()` | 中 |
| 结束休息 | `_endRest()` | 高 |
| 训练完成 | `_autoSaveTraining()` 后调用 `clearInProgressTraining()` | 高 |
| 主动放弃训练 | 退出按钮回调 | 高 |
| App 进入后台 | `didChangeAppLifecycleState(paused)` | 中 |
| 每 30 秒定时持久化 | `Timer.periodic`（训练中） | 低 |

### 5.6 DatabaseHelper schema v8 → v9

```sql
ALTER TABLE records ADD COLUMN pureDuration INTEGER;
```

`duration` 保持原语义（含休息总时长，分钟精度），`pureDuration` 为纯训练时长（秒精度）。

### 5.7 pureDuration 计算

```dart
final totalDurationSec = DateTime.now().difference(_startTime).inSeconds;
final restTotalSec = _restLog.fold<int>(0, (sum, r) =>
    sum + (r['actualRestSeconds'] as int));
final pureDurationSec = totalDurationSec - restTotalSec;

Storage.addRecord({
  ...
  'duration': (totalDurationSec / 60).round(),
  'pureDuration': pureDurationSec,
  'restLog': _restLog,
  ...
});
```

### 5.8 restLog 字段统一 + setRecords.rest 修复

**统一格式**：

```json
{
  "exercise": "卧推",
  "scheduledRestSeconds": 90,
  "actualRestSeconds": 105,
  "restEndReason": "manual"
}
```

**兼容旧数据**：`record_detail_page.dart` 读取时 fallback：

```dart
final scheduled = (log['scheduledRestSeconds'] as num?)?.toInt()
              ?? (log['restTime'] as num?)?.toInt() ?? 0;
final actual = (log['actualRestSeconds'] as num?)?.toInt()
            ?? (log['actualTime'] as num?)?.toInt() ?? 0;
```

**setRecords.rest**：`_completeSet()` 写入时附带本次组间休息：

```dart
_setRecords[exId]!.add({
  'set': _currentSetIdx + 1,
  'weight': weight,
  'reps': reps,
  'rest': _lastRestActualSeconds,
});
```

### 5.9 跨天恢复流程

在 `TrainingPage._loadData()` 末尾调用 `_checkInProgressTraining()`：

- `startedAtDate == today`：恢复进行中训练，用 wall-clock 校正休息阶段
- `startedAtDate < today`：弹窗提示"保存为记录"或"丢弃"

**跨天弹窗内容**：

```
┌─────────────────────────────────────┐
│  上次训练未完成                      │
│  您在 8 月 4 日开始的"胸部+三头肌"   │
│  训练未完成, 已完成 5/12 组.         │
│  保存为训练记录 (以当前时间为结束)?   │
│  [保存为记录]      [丢弃]            │
└─────────────────────────────────────┘
```

**同天恢复时休息阶段校正**：

```dart
void _restoreRestPhase(Map<String, dynamic> snapshot) {
  _restScheduledSeconds = snapshot['scheduledSeconds'] as int;
  _restActualStartAt = DateTime.fromMillisecondsSinceEpoch(snapshot['actualStartAt']);
  _restScheduledEndAt = DateTime.fromMillisecondsSinceEpoch(snapshot['scheduledEndAt']);
  _restOvertimeLimitAt = DateTime.fromMillisecondsSinceEpoch(snapshot['overtimeLimitAt']);
  final phaseStr = snapshot['phase'] as String;

  final now = DateTime.now();
  if (phaseStr == 'resting') {
    if (now.isBefore(_restScheduledEndAt!)) {
      _restPhase = RestPhase.resting;
    } else {
      _enterOvertimePhase(skipSound: true);
    }
  } else if (phaseStr == 'restingOvertime') {
    if (now.isBefore(_restOvertimeLimitAt!)) {
      _restPhase = RestPhase.restingOvertime;
    } else {
      _endRest(RestEndReason.autoTimeout);
      return;
    }
  }
  _restartRestTimer();
}
```

**lastPersistedAt > 5 分钟且休息中的兜底**：直接 `_endRest(RestEndReason.autoTimeout)`，actualRestSeconds 取 `lastPersistedAt - restActualStartAt`。

### 5.10 新增设置项

```dart
// storage.dart getSettings() defaults Map 中
'autoEndAfterRest': false,
'restOvertimeLimitMultiplier': 3.0,
```

在 `reminder_settings_page.dart` 的"休息提醒"区块增加开关：

```
休息提醒
  └─ CardWidget
      ├─ SwitchTile('休息结束提醒')        [现有]
      ├─ 横幅通知引导                       [现有]
      ├─ SwitchTile('提示音')              [现有]
      ├─ SwitchTile('振动提醒')            [现有]
      └─ SwitchTile('休息结束后自动结束')  [新增]
          subtitle: "到点自动结束并关闭休息弹窗, 适合自制力强的用户"
```

### 5.11 RestPreferenceService 新建

新建 `fittrack_flutter/lib/services/rest_preference_service.dart`：

```dart
class RestPreferenceService {
  static final instance = RestPreferenceService._();
  RestPreferenceService._();

  bool isPreferenceAvailable() {
    final records = Storage.getAllRecords();
    if (records.isEmpty) return false;
    final earliest = records.reduce((a, b) =>
        a['date'] < b['date'] ? a : b);
    final firstTrainingDate = DateTime.fromMillisecondsSinceEpoch(earliest['date']);
    return DateTime.now().difference(firstTrainingDate).inDays >= 7;
  }

  int? computeRecommendedRestSeconds() {
    if (!isPreferenceAvailable()) return null;
    // 取最近 10 条 records 的 restLog.actualRestSeconds
    // IQR 异常过滤 + 加权平均 + 5 秒粒度对齐 + 钳制 [15, 600]
  }
}
```

在 `add_plan_page.dart` 休息时间输入框下方加推荐卡片：

```dart
Widget _buildRestRecommendationCard() {
  final recommended = RestPreferenceService.instance.computeRecommendedRestSeconds();
  if (recommended == null) return SizedBox.shrink();
  // 显示推荐卡片 + "应用"按钮
}
```

### 5.12 改动文件清单

| 文件 | 改动 |
|---|---|
| `fittrack_flutter/lib/pages/training_page.dart` | 休息状态机重构、持久化触发、跨天恢复、按钮文案、通知取消（§1）、积分传递（§3）、权限引导（§2） |
| `fittrack_flutter/lib/data/storage.dart` | 新增 3 个 in-progress 方法 + 2 个 settings defaults |
| `fittrack_flutter/lib/data/database_helper.dart` | schema v8→v9，records 加 pureDuration 列 |
| `fittrack_flutter/lib/pages/record_detail_page.dart` | 修复 restLog 字段名 + setRecords.rest + pureDuration 展示 |
| `fittrack_flutter/lib/pages/reminder_settings_page.dart` | 新增 autoEndAfterRest 开关 |
| `fittrack_flutter/lib/services/rest_preference_service.dart` | 新建 |
| `fittrack_flutter/lib/pages/add_plan_page.dart` | 推荐卡片接入 |
| `fittrack_flutter/lib/widgets/celebration_dialog.dart` | 增加积分展示（§3） |
| `fittrack_flutter/lib/services/points_service.dart` | addDailyTrainingPoints 返回 int（§3） |
| `fittrack_flutter/lib/services/rest_notification_service.dart` | iOS 权限请求（§2） |
| `fittrack_flutter/lib/pages/opponent_detail_page.dart` | 皮肤预览弹层（§4） |
| `fittrack_flutter/android/app/src/main/kotlin/com/lt/lifttrack/AlarmReceiver.kt` | 通知权限检查（§2） |

---

## §6 错误处理与边界场景

### 6.1 持久化错误处理

| 场景 | 处理 |
|---|---|
| SharedPreferences 写入失败 | try-catch, 记录日志, 不阻塞训练流程 |
| JSON 解析失败(数据损坏) | `getInProgressTraining()` 返回 null, 视为无进行中训练 |
| Schema v8→v9 升级失败 | SQLite `_onUpgrade` 中 ALTER TABLE 失败时记录日志 |

### 6.2 计时边界

| 场景 | 处理 |
|---|---|
| 用户在休息中切换 autoEndAfterRest 设置 | 下次开始休息时生效, 当前休息不变更行为 |
| 休息中 App 被杀, 恢复时发现已超 `overtimeLimitAt` | 直接 `_endRest(autoTimeout)` |
| 休息中 App 被杀, 恢复时发现 `now - lastPersistedAt > 5min` | 同上, 自动结算 |
| 用户在 resting 阶段切后台, 期间倒计时到 0 | 恢复时 `_enterOvertimePhase(skipSound: true)` |
| 跨天恢复时, restPhase == restingOvertime | 弹窗保存为记录时按保守值计算 actualRestSeconds |

### 6.3 推荐服务边界

| 场景 | 处理 |
|---|---|
| 旧 records 数据没有 `actualRestSeconds` 字段 | fallback 到 `actualTime`/`restTime` |
| 所有样本都是 `autoTimeout` reason | 过滤后样本为空, 返回 null |
| 计算结果 < 15 秒或 > 600 秒 | 钳制到 [15, 600] |

---

## §7 实施顺序建议

1. **第 1 步**：Storage + DatabaseHelper 改造（settings defaults、in-progress 方法、schema v9 升级）
2. **第 2 步**：RestStateMachine 重构（training_page.dart 休息状态机）
3. **第 3 步**：通知 bug 修复（§1，前台取消预约通知 + 训练完成兜底取消）
4. **第 4 步**：iOS/Android 权限修复（§2）
5. **第 5 步**：积分提示（§3）
6. **第 6 步**：皮肤预览（§4）
7. **第 7 步**：记录字段扩展与 bug 修复（pureDuration、restLog 字段统一、setRecords.rest）
8. **第 8 步**：持久化触发与跨天恢复（_checkInProgressTraining、_restoreRestPhase）
9. **第 9 步**：设置项 UI（reminder_settings_page 开关）
10. **第 10 步**：RestPreferenceService 新建 + add_plan_page 推荐卡片
11. **第 11 步**：详情页字段读取修复与 pureDuration 展示

---

## 不在本设计范围

- 服务器端同步
- 推荐算法的 A/B 测试与个性化
- 多设备间进行中训练同步
- `restOvertimeLimitMultiplier` 的可配置 UI（暂用默认 3.0）
- 训练页 UI 重设计（仅修改休息 overlay 按钮文案与提示）
