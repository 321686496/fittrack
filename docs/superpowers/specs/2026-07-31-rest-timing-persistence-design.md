# 训练页休息计时与持久化设计

- 日期：2026-07-31
- 范围：训练页休息状态机、休息时间统计、训练总时长统计、进行中训练持久化、跨天恢复、休息偏好推荐、设置项新增
- 状态：待评审

## 背景与目标

用户反馈训练页存在多个问题：

1. **休息时间统计永远为 0**：训练结束后统计的休息时间逻辑不正确
2. **休息结束交互不完整**：倒计时到 0 后休息页直接关闭，缺少"提醒休息结束 + 用户手动结束"的环节，无法记录用户实际休息时长
3. **缺少自动结束开关**：自制力强的用户希望休息到点自动结束并关闭弹窗，无需手动点击
4. **缺少训练总时长统计**：训练页与训练记录未统计用户训练的总时长（含/不含休息）
5. **进行中训练无持久化**：退出 App 或被系统杀死时，当天训练进度丢失

### 期望的休息流程

1. 用户完成一组动作 → 点击"完成本组" → 进入休息页
2. 休息页倒计时进行中 → 按钮文案为"跳过休息"（提前结束）
3. 倒计时到 0 → **休息页不关闭**，提醒休息结束（声音+振动），按钮文案切换为"结束休息"（高亮）
4. 后台静默计时继续 → 直到用户点击"结束休息"或到达静默计时上限
5. 用户点击"结束休息" → 记录本次实际休息时长 → 进入下一组
6. 系统根据历史实际休息时长，**满 7 天后**在用户新建/编辑计划时推荐休息时间

## 已确认的设计决策

- **休息结束交互**：单一按钮随状态变文案。倒计时进行中显示"跳过休息"，倒计时到 0 后切换为"结束休息"并高亮，页面不关闭，播放提示音+振动
- **超时上限**：设置上限自动结束。静默计时阶段最多持续 `设定休息时间 × restOvertimeLimitMultiplier`（默认 3.0 倍），超过后自动结束
- **训练总时长**：同时记录两个值。`duration`（含休息总时长，分钟精度，保持原语义）+ `pureDuration`（纯训练时长，秒精度，新增字段）
- **跨天处理**：弹窗处理。同天可直接恢复；跨天弹窗让用户选择"保存为记录（以当前时间为结束时间）"或"丢弃"
- **推荐算法**：加权平均 + IQR 异常过滤。取最近 10 条 records 的 restLog.actualRestSeconds，过滤 autoTimeout 异常记录，加权平均后取 5 秒粒度
- **推荐时机**：用户首次训练满 7 天后才显示推荐，之前不显示
- **整体方案**：方案 A。SharedPreferences 独立 key 存进行中训练，与设置 key 隔离

## 架构与约束

### 项目存储架构现状

- **Storage**（`fittrack_flutter/lib/data/storage.dart`）：静态类，双层结构（内存缓存 + 异步落盘）
  - Plans & Records：SQLite（`fittrack.db`，当前 schema v7）
  - Settings / Stats / BodyData：SharedPreferences（key `fittrack_fitplan_settings`）
- **TrainingPage**（`fittrack_flutter/lib/pages/training_page.dart`）：StatefulWidget，所有训练状态保存在内存字段中，**无任何持久化**，杀进程即丢失
- **休息实现**：`Timer.periodic` + wall-clock（`DateTime`）双重校正；休息 UI 是训练页 Stack overlay，无独立 Dialog/Page
- **休息记录字段名不一致 bug**：`_restLog.add` 写入 `exercise/restTime/actualTime`，但 `record_detail_page.dart` 读取 `after/seconds/skipped`，导致详情页休息记录全部回退默认值
- **setRecords 缺失 rest 字段 bug**：`_completeSet` 写入 `set/weight/reps`，详情页期望读取 `rest` 字段，导致每组右侧"Xs"标签永不显示

### 项目无状态管理框架

延续现有架构，不引入 Provider/Riverpod 等。新逻辑仍以 StatefulWidget + Storage 静态方法实现。

## 详细设计

### §1 整体架构与改动清单

```
┌─────────────────────────────────────────────────────────────────┐
│                    TrainingPage (StatefulWidget)                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ RestStateMachine (内存, 替换原 _isResting/_restSeconds)   │   │
│  │  状态: idle / resting / restingOvertime                   │   │
│  │  字段: restActualStartAt, restScheduledEndAt,             │   │
│  │        restOvertimeLimitAt, restEndReason                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 持久化触发点 (关键状态变化时调用 Storage)                  │   │
│  │  - 开始训练 / 完成一组 / 开始休息 / 结束休息 / 训练完成     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Storage (storage.dart)                       │
│  + saveInProgressTraining(json)        ← 新增 (SharedPreferences)│
│  + getInProgressTraining()             ← 新增 (同步读取内存缓存)  │
│  + clearInProgressTraining()           ← 新增                    │
│  + getSettings()['autoEndAfterRest']    ← defaults 新增 (false)  │
│  + getSettings()['restOvertimeLimitMultiplier'] ← defaults 3.0   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              DatabaseHelper (database_helper.dart)               │
│  records 表 schema v7 → v8:                                     │
│   + pureDuration INTEGER   (纯训练时长，秒)                      │
│   restLog JSON 字段格式升级:                                     │
│    {exercise, scheduledRestSeconds, actualRestSeconds,          │
│     restEndReason: manual|autoTimeout|skip}                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           RestPreferenceService (新建 rest_preference_service)   │
│  + computeRecommendedRestSeconds(): int?                         │
│  + isPreferenceAvailable(): bool                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│        PlanEditPage / reminder_settings_page 等消费方            │
│  - PlanEditPage: 休息时间输入框旁加推荐卡片                       │
│  - reminder_settings_page: 新增 autoEndAfterRest 开关            │
└─────────────────────────────────────────────────────────────────┘
```

**改动清单**：

| 文件 | 改动 |
|---|---|
| `fittrack_flutter/lib/pages/training_page.dart` | 休息状态机重构、持久化触发、跨天恢复、按钮文案逻辑、训练总时长统计 |
| `fittrack_flutter/lib/data/storage.dart` | 新增 3 个 in-progress 方法 + 2 个 settings defaults |
| `fittrack_flutter/lib/data/database_helper.dart` | schema v7→v8，records 加 `pureDuration` 列 |
| `fittrack_flutter/lib/pages/record_detail_page.dart` | 修复字段名 bug + 展示 pureDuration 与休息详情 |
| `fittrack_flutter/lib/pages/reminder_settings_page.dart` | 新增"休息结束后自动结束"开关 |
| `fittrack_flutter/lib/services/rest_preference_service.dart` | 新建 |
| `fittrack_flutter/lib/pages/plan_edit_page.dart`（待确认文件名） | 推荐卡片接入 |
| 新增测试文件 | 状态机、偏好计算、持久化恢复的单元测试 |

### §2 休息状态机与计时逻辑

#### 2.1 状态机定义

```
                  用户点击"完成本组"(非最后一组)
       ┌──────────────────────────────────────────┐
       │                                          │
       ▼                                          │
   ┌────────┐  倒计时进行中(_restDisplaySeconds>0) ┌──────────────┐
   │ Idle   │ ──────────────────────────────────▶ │   Resting    │
   └────────┘                                      └──────────────┘
       ▲                                                 │
       │                                                 │ 倒计时到 0
       │                                                 ▼
       │                                            ┌──────────────────┐
       │                                            │ RestingOvertime  │
       │                                            │ (静默计时中)      │
       │                                            └──────────────────┘
       │                                                 │
       │                                                 │ 用户点击"结束休息"
       │                                                 │ OR 超时上限到达
       │                                                 ▼
       └─────────────────────────────────────────────────┘
                      记录 restLog, advance 到下一组
```

#### 2.2 关键字段（替换现有 `_isResting/_restSeconds/_totalRestSeconds/_restEndTime/_restEndNotified`）

```dart
enum RestPhase { idle, resting, restingOvertime }
enum RestEndReason { manual, autoTimeout, skip }  // skip=提前结束

RestPhase _restPhase = RestPhase.idle;
int _restScheduledSeconds = 0;          // 设定的休息秒数
DateTime? _restActualStartAt;           // 实际开始休息时刻
DateTime? _restScheduledEndAt;          // 设定倒计时结束时刻
DateTime? _restOvertimeLimitAt;         // 静默计时上限时刻
RestEndReason? _restEndReason;          // 本次休息结束原因

int _restDisplaySeconds = 0;            // 当前显示的剩余/超时秒数
```

#### 2.3 计时主循环（基于 wall-clock 校正）

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
          _enterOvertimePhase();        // 切换到静默计时阶段
        }
      } else if (_restPhase == RestPhase.restingOvertime) {
        final overtime = now.difference(_restScheduledEndAt!).inSeconds;
        _restDisplaySeconds = overtime;  // UI 显示为 "+Ns"
        if (now.isAfter(_restOvertimeLimitAt!)) {
          _endRest(RestEndReason.autoTimeout);  // 超时上限到达,自动结束
        }
      }
    });
  });
}
```

#### 2.4 按钮文案与行为

| 阶段 | 按钮文案 | 行为 |
|---|---|---|
| `resting`（倒计时进行中） | "跳过休息" | `_endRest(RestEndReason.skip)`，actualRestSeconds < scheduledRestSeconds |
| `restingOvertime`（已超时静默中） | "结束休息"（高亮） | `_endRest(RestEndReason.manual)`，actualRestSeconds > scheduledRestSeconds |
| `restingOvertime` 且到达上限 | 自动结束 | `_endRest(RestEndReason.autoTimeout)` |

#### 2.5 `_endRest(reason, {actualSecondsOverride})` 统一收尾

```dart
void _endRest(RestEndReason reason, {int? actualSecondsOverride}) {
  _restTimer?.cancel();
  RestNotificationService.instance.cancelScheduledNotification();
  // 默认用 now - restActualStartAt; 恢复场景下由调用方传入保守值
  final actualSeconds = actualSecondsOverride
      ?? DateTime.now().difference(_restActualStartAt!).inSeconds;

  _restLog.add({
    'exercise': _exercises[_currentExIdx]['name'],
    'scheduledRestSeconds': _restScheduledSeconds,
    'actualRestSeconds': actualSeconds,
    'restEndReason': reason.name,   // manual / autoTimeout / skip
  });

  _lastRestActualSeconds = actualSeconds;  // 用于写入下一组的 setRecords.rest 字段
  _pushTrainingToWidget(restSkipped: reason == RestEndReason.skip);

  setState(() {
    _restPhase = RestPhase.idle;
    _restActualStartAt = null;
    _restScheduledEndAt = null;
    _restOvertimeLimitAt = null;
    _restEndReason = reason;
  });

  _advanceToNextSet();              // 推进到下一组/下一动作
  _persistInProgressTraining();     // 持久化(见 §3)
}
```

**`actualSecondsOverride` 使用场景**：
- 默认（无 override）：用 `now - restActualStartAt`，正常结束场景
- 恢复场景（§5.5）：调用方计算 `lastPersistedAt - restActualStartAt` 后传入，避免长时间杀进程导致 actualSeconds 异常过大

#### 2.6 设置项 `autoEndAfterRest` 的行为

当 `Storage.getSettings()['autoEndAfterRest'] == true` 时：
- 倒计时到 0 后**不进入** `restingOvertime` 阶段，直接调用 `_endRest(RestEndReason.autoTimeout)`，actualRestSeconds 等于 scheduledRestSeconds（不会超时）
- 即"自制力型"模式：到点自动结束并关闭休息弹窗
- 风险已在用户描述中明确：自制力弱的用户开启此选项会"假休息"，但这是用户主动选择，记录忠实反映设定值

### §3 持久化设计

#### 3.1 进行中训练的存储格式

存储 key：`fittrack_in_progress_training`（SharedPreferences，独立于设置的 `fittrack_fitplan_settings`）

JSON 结构：

```json
{
  "version": 1,
  "startedAt": 1722400000000,
  "startedAtDate": "2026-07-31",
  "planId": "plan_xxx",
  "planName": "胸部 + 三头肌",
  "dayConfig": {...},
  "exercises": [...],
  "currentExIdx": 2,
  "currentSetIdx": 1,
  "completedSets": 5,
  "setRecords": {
    "ex1": [{"set":1,"weight":60,"reps":10,"rest":105}, ...]
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

#### 3.2 Storage 新增方法

```dart
// storage.dart
static const _inProgressKey = 'fittrack_in_progress_training';

static Future<void> saveInProgressTraining(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  data['lastPersistedAt'] = DateTime.now().millisecondsSinceEpoch;
  await prefs.setString(_inProgressKey, jsonEncode(data));
}

static Map<String, dynamic>? getInProgressTraining() {
  // 同步读取: SharedPreferences 已在 main() 中预热
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

#### 3.3 持久化触发点

| 时机 | 触发位置 | 必要性 |
|---|---|---|
| 训练开始 | `_startTraining()` | 高 — 防止用户秒退 |
| 完成一组 | `_completeSet()` 写入 setRecords 后 | 高 |
| 开始休息 | `_startRest()` | 高 — 含休息快照 |
| 切换休息阶段 | `_enterOvertimePhase()` | 中 — 更新 phase |
| 结束休息 | `_endRest()` | 高 |
| 训练完成 | `_autoSaveTraining()` 后调用 `clearInProgressTraining()` | 高 — 清理 |
| 主动放弃训练 | 退出按钮回调 | 高 — 清理 |
| App 进入后台 | `didChangeAppLifecycleState(paused)` | 中 — 兜底 |
| 每 30 秒定时持久化 | `Timer.periodic`（训练中） | 低 — 兜底防异常杀进程 |

#### 3.4 数据完整性兜底

- 写入时使用 `await prefs.setString(...)`，确保落盘后才返回
- 每次写入带 `lastPersistedAt`，恢复时若发现 `now - lastPersistedAt > 5 分钟` 且 `restPhase != idle`，则按"restingOvertime 上限到达"自动结算该次休息（防止杀进程期间静默计时无限延长）

### §4 训练记录字段扩展

#### 4.1 records 表 schema v7 → v8

```sql
-- database_helper.dart _onUpgrade
ALTER TABLE records ADD COLUMN pureDuration INTEGER;  -- 纯训练时长(秒), 不含休息
```

`duration` 字段保留原语义（含休息的总时长，分钟精度），新增 `pureDuration`（秒精度）。

#### 4.2 `pureDuration` 计算

```dart
// training_page.dart _autoSaveTraining()
final totalDurationSec = DateTime.now().difference(_startTime).inSeconds;
final restTotalSec = _restLog.fold<int>(0, (sum, r) =>
    sum + (r['actualRestSeconds'] as int));
final pureDurationSec = totalDurationSec - restTotalSec;

Storage.addRecord({
  ...
  'duration': (totalDurationSec / 60).round(),   // 保持原字段语义(分钟)
  'pureDuration': pureDurationSec,               // 新字段(秒)
  'restLog': _restLog,                           // 已含新字段
  ...
});
```

#### 4.3 restLog 字段统一格式（修复既有 bug）

**统一为**：
```json
{
  "exercise": "卧推",
  "scheduledRestSeconds": 90,
  "actualRestSeconds": 105,
  "restEndReason": "manual"
}
```

**兼容旧数据**：`record_detail_page.dart` 读取时做 fallback：
```dart
final exercise = log['exercise'] as String? ?? '';
final scheduled = (log['scheduledRestSeconds'] as num?)?.toInt()
              ?? (log['restTime'] as num?)?.toInt() ?? 0;       // 兼容旧字段
final actual = (log['actualRestSeconds'] as num?)?.toInt()
            ?? (log['actualTime'] as num?)?.toInt() ?? 0;       // 兼容旧字段
final reason = log['restEndReason'] as String? ?? 'manual';
```

#### 4.4 setRecords 每组的 rest 字段（修复既有 bug）

`_completeSet()` 写入时附带本次组间休息：
```dart
_setRecords[exId]!.add({
  'set': setCurrent,
  'weight': weight,
  'reps': reps,
  'rest': _lastRestActualSeconds,   // 新增: 上一组结束后的实际休息秒数
});
```

详情页 `record_detail_page.dart:343` 现有逻辑可正确读取并显示"Xs"标签。

### §5 跨天恢复流程

#### 5.1 启动检查时机

在 `TrainingPage._loadData()` 末尾、原数据加载完成后调用 `_checkInProgressTraining()`。

#### 5.2 流程图

```
                    进入训练页 _loadData()
                            │
                            ▼
                  Storage.getInProgressTraining()
                            │
              ┌─────────────┴─────────────┐
              ▼                            ▼
         null (无进行中)            有进行中训练
              │                            │
              ▼                            ▼
        正常加载计划/动作            解析 startedAtDate
                                            │
                              ┌─────────────┴─────────────┐
                              ▼                            ▼
                startedAtDate == today              startedAtDate < today
                              │                            │
                              ▼                            ▼
                     恢复进行中训练                  弹窗: "上次训练未完成"
                     (恢复 state + restPhase)            │
                              │                ┌─────────┴─────────┐
                              ▼                ▼                    ▼
                     (如果 restPhase != idle)  "保存为记录"      "丢弃"
                              │                │                    │
                              ▼                ▼                    ▼
                     用 wall-clock 校正     _autoSaveAsIncomplete  clearInProgress
                     剩余时间/超时上限      (写 records 表)       开始新训练
                              │                │
                              ▼                ▼
                       重启 Timer        开始新训练
```

#### 5.3 跨天弹窗内容

```
┌─────────────────────────────────────┐
│  上次训练未完成                      │
│                                     │
│  您在 7 月 30 日开始的"胸部+三头肌"   │
│  训练未完成, 已完成 5/12 组.         │
│                                     │
│  保存为训练记录 (以当前时间为结束)?   │
│                                     │
│  [保存为记录]      [丢弃]            │
└─────────────────────────────────────┘
```

#### 5.4 同天恢复时的休息阶段校正

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
      _enterOvertimePhase(skipSound: true);  // 切后台期间倒计时已结束
    }
  } else if (phaseStr == 'restingOvertime') {
    if (now.isBefore(_restOvertimeLimitAt!)) {
      _restPhase = RestPhase.restingOvertime;
    } else {
      _endRest(RestEndReason.autoTimeout);   // 切后台期间已超上限
      return;
    }
  }
  _restartRestTimer();
}
```

#### 5.5 `lastPersistedAt > 5 分钟且休息中`的兜底

如果恢复时发现 `now - lastPersistedAt > 5min` 且 `restPhase != idle`，说明 App 被杀已较久，休息计时不可信——直接调用 `_endRest(RestEndReason.autoTimeout)`，actualRestSeconds 取 `lastPersistedAt - restActualStartAt`（保守值，避免无限延长污染统计）。

### §6 设置项 UI

#### 6.1 新增 settings defaults

```dart
// storage.dart getSettings() defaults Map 中
'autoEndAfterRest': false,             // 休息结束后自动结束(自制力模式)
'restOvertimeLimitMultiplier': 3.0,    // 静默计时上限倍数(设定时间 × 3)
```

#### 6.2 设置页 UI 接入位置

放在 `reminder_settings_page.dart` 的「休息提醒」SectionHeader 下，作为该区块的最后一项（紧跟"振动提醒"开关后）：

```
休息提醒
  └─ CardWidget
      ├─ SwitchTile('休息结束提醒')        [现有]
      ├─ 横幅通知引导                       [现有]
      ├─ SwitchTile('提示音')              [现有]
      ├─ SwitchTile('振动提醒')            [现有]
      └─ SwitchTile('休息结束后自动结束')  [新增]
          subtitle: "到点自动结束并关闭休息弹窗, 适合自制力强的用户. 自制力弱者开启可能造成假休息记录"
```

#### 6.3 开关样式参考现有写法

```dart
_buildSwitchTile(
  colors,
  PhosphorIcons.timer,
  '休息结束后自动结束',
  '到点自动结束并关闭休息弹窗, 适合自制力强的用户. 自制力弱者开启可能造成假休息记录',
  Storage.getSettings()['autoEndAfterRest'] as bool? ?? false,
  (v) => _saveSetting('autoEndAfterRest', v),
),
```

#### 6.4 `restOvertimeLimitMultiplier` 暂不暴露 UI

倍数 3.0 作为内部默认值，不暴露给用户调整（YAGNI）。若后续用户反馈需要可调，再单独加 UI。

### §7 休息偏好推荐服务

#### 7.1 新建 `fittrack_flutter/lib/services/rest_preference_service.dart`

```dart
class RestPreferenceService {
  static final instance = RestPreferenceService._();
  RestPreferenceService._();

  /// 是否已满足推荐条件: 用户首次训练满 7 天
  bool isPreferenceAvailable() {
    final records = Storage.getAllRecords();
    if (records.isEmpty) return false;

    final earliest = records.reduce((a, b) =>
        a['date'] < b['date'] ? a : b);
    final firstTrainingDate = DateTime.fromMillisecondsSinceEpoch(earliest['date']);
    return DateTime.now().difference(firstTrainingDate).inDays >= 7;
  }

  /// 计算推荐休息秒数, 数据不足返回 null
  int? computeRecommendedRestSeconds() {
    if (!isPreferenceAvailable()) return null;

    final records = Storage.getAllRecords();
    final allActuals = <int>[];
    for (final r in records.take(10)) {
      final restLog = r['restLog'] as List? ?? [];
      for (final log in restLog) {
        final actual = (log['actualRestSeconds'] as num?)?.toInt()
                    ?? (log['actualTime'] as num?)?.toInt();    // 兼容旧数据
        final reason = log['restEndReason'] as String?;
        // 过滤掉自动超时上限结算的异常记录
        if (actual != null && actual > 0 && reason != 'autoTimeout') {
          allActuals.add(actual);
        }
      }
    }

    if (allActuals.length < 3) return null;  // 至少 3 条有效样本

    // IQR 异常过滤
    allActuals.sort();
    final q1 = _percentile(allActuals, 25);
    final q3 = _percentile(allActuals, 75);
    final iqr = q3 - q1;
    final lower = q1 - 1.5 * iqr;
    final upper = q3 + 1.5 * iqr;
    final filtered = allActuals.where((s) => s >= lower && s <= upper).toList();

    if (filtered.isEmpty) return null;

    // 加权平均: 越近期权重越高(线性递增)
    filtered.sort();
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
    return sorted[idx];
  }
}
```

#### 7.2 PlanEditPage 推荐卡片接入

在休息时间输入框下方加一个条件展示的提示卡片：

```dart
Widget _buildRestRecommendationCard() {
  final recommended = RestPreferenceService.instance.computeRecommendedRestSeconds();
  if (recommended == null) return SizedBox.shrink();

  return Container(
    margin: EdgeInsets.only(top: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.primaryLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        PhosphorIcon(PhosphorIcons.sparkle, color: colors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '根据您的历史组间休息时间偏好, 推荐休息时间 $recommended 秒',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: () => _restTimeController.text = recommended.toString(),
          child: Text('应用'),
        ),
      ],
    ),
  );
}
```

#### 7.3 不显示推荐的条件汇总

满足以下任一条件则不显示推荐卡片：
1. 用户没有任何训练记录
2. 用户首次训练至今不满 7 天
3. 有效样本数 < 3（过滤后）
4. 推荐计算结果为 null

### §8 错误处理与边界场景

#### 8.1 持久化错误处理

| 场景 | 处理 |
|---|---|
| SharedPreferences 写入失败 | try-catch, 记录日志, 不阻塞训练流程(数据丢失风险接受) |
| JSON 解析失败(数据损坏) | `getInProgressTraining()` 返回 null, 视为无进行中训练, 同时尝试清理损坏数据 |
| Schema v7→v8 升级失败 | SQLite `_onUpgrade` 中 ALTER TABLE 失败时, 删除并重建 records 表(已有数据会丢, 但属极端情况) |

#### 8.2 计时边界

| 场景 | 处理 |
|---|---|
| 用户在休息中切换 autoEndAfterRest 设置 | 下次开始休息时生效, 当前休息不变更行为 |
| 休息中 App 被杀, 恢复时发现已超 `overtimeLimitAt` | 直接 `_endRest(autoTimeout)`, actualRestSeconds 取 `lastPersistedAt - restActualStartAt` 保守值 |
| 休息中 App 被杀, 恢复时发现 `now - lastPersistedAt > 5min` | 同上, 自动结算 |
| 用户在 resting 阶段切后台, 期间倒计时到 0 | 恢复时 `_enterOvertimePhase(skipSound: true)` 静默进入超时阶段 |
| 跨天恢复时, 进行中训练的 `restPhase == restingOvertime` | 弹窗保存为记录时, 该次休息按 `lastPersistedAt - restActualStartAt` 计算 actualRestSeconds, reason 标记为 `autoTimeout` |

#### 8.3 推荐服务边界

| 场景 | 处理 |
|---|---|
| 旧 records 数据没有 `actualRestSeconds` 字段 | fallback 到 `actualTime`/`restTime`, 都没有则跳过该条 |
| 所有样本都是 `autoTimeout` reason | 过滤后样本为空, 返回 null, 不显示推荐 |
| 计算结果 < 15 秒或 > 600 秒 | 钳制到合理区间 [15, 600] |

#### 8.4 测试策略

| 测试类型 | 覆盖范围 |
|---|---|
| 单元测试 | RestStateMachine 状态转换(各 reason)、RestPreferenceService(加权平均/IQR/数据不足场景)、Storage in-progress 序列化/反序列化 |
| 集成测试 | 训练页 → 休息 → 结束 → 记录写入 → 详情页读取 全流程字段一致 |
| 回归测试 | 旧 records 数据(无 pureDuration/新 restLog 字段)在详情页能正常显示 |
| 手动测试 | 杀进程恢复、跨天弹窗、autoEndAfterRest 开关效果、超时上限自动结束 |

新增测试文件：
- `fittrack_flutter/test/rest_state_machine_test.dart`
- `fittrack_flutter/test/rest_preference_service_test.dart`
- `fittrack_flutter/test/in_progress_training_persistence_test.dart`

## 实施顺序建议

1. **第 1 步**：Storage + DatabaseHelper 改造（settings defaults、in-progress 方法、schema v8 升级）
2. **第 2 步**：RestStateMachine 重构（training_page.dart 休息状态机）
3. **第 3 步**：记录字段扩展与 bug 修复（pureDuration、restLog 字段统一、setRecords.rest）
4. **第 4 步**：持久化触发与跨天恢复（_checkInProgressTraining、_restoreRestPhase）
5. **第 5 步**：设置项 UI（reminder_settings_page 开关）
6. **第 6 步**：RestPreferenceService 新建 + PlanEditPage 推荐卡片
7. **第 7 步**：详情页字段读取修复与 pureDuration 展示
8. **第 8 步**：单元测试与集成测试

## 不在本设计范围

- 服务器端同步（Phase 3 才考虑）
- 推荐算法的 A/B 测试与个性化（先用单一加权平均）
- 多设备间进行中训练同步
- `restOvertimeLimitMultiplier` 的可配置 UI（暂用默认 3.0）
- 训练页 UI 重设计（仅修改休息 overlay 按钮文案与提示）
