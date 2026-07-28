# Android 与 iOS 平台适配实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Android 与 iOS 在功能上完全对齐 HarmonyOS 已实现的能力（桌面卡片、实况窗、后台提醒、URL scheme 邀请、海报保存分享）。

**Architecture:** 新增平台抽象层（PAL）`lib/services/platform/` 统一三平台接口，业务代码依赖接口而非具体实现。iOS 端新增 Widget Extension（Live Activities + Home Widget），Android 端新增 Jetpack Glance AppWidget + 前台服务通知。HarmonyOS 既有代码通过包装类接入 PAL，零改动。

**Tech Stack:** Flutter 3.7.12 (Dart 2.19.6) / Kotlin 1.9.10 + Jetpack Glance 1.0.0 / Swift 5 + ActivityKit + WidgetKit / Codemagic 云构建

## Global Constraints

- 项目根目录：`d:\app\projects\health_training`，Flutter 工程位于 `fittrack_flutter/`
- Dart SDK 约束：`>=2.19.6 <3.0.0`，不引入 Dart 3.x 依赖
- Android 包名：`com.fp.fitplan`，Kotlin 源码位于 `android/app/src/main/kotlin/com/fp/fitplan/`
- Android 构建：AGP 7.2.0 + Gradle 7.5 + Java 17 (C:/Program Files/Java/jdk-17.0.12) + compileSdkVersion 34
- Android 测试模拟器：Medium_Phone_4k AVD (emulator-5558)，不要使用 16k 页大小 AVD
- iOS 最低版本：16.1（Live Activities 所需），bundle id `com.fp.fitplan`
- 平台判断统一使用 `lib/utils/platform_utils.dart` 的 `isOhos` getter，禁止直接使用 `Platform.isOhos`
- OHOS fork 版本依赖（shared_preferences / sqflite / permission_handler / flutter_local_notifications）保留不变
- 现有 OHOS 原生代码（EntryAbility.ets / FitTrackFormExtension.ets / FitTrackWidget.ets）零改动
- 现有 Android AlarmManager 逻辑（AlarmReceiver.kt / AlarmScheduler.kt）保留
- 颜色主题：使用 app 已定义的 7 套主题色（vitality-sport / iron-forge / blossom / silver-care / fresh-minimal / neon-cyber / black-gold），不新增自定义颜色
- 提交规范：每个 Task 结束提交一次，commit message 使用 `feat:`/`fix:`/`refactor:`/`docs:` 前缀

**Spec:** `docs/superpowers/specs/2026-07-28-android-ios-platform-adaptation-design.md`

---

## File Structure

### 新增文件（Dart 侧 PAL）

```
fittrack_flutter/lib/services/platform/
├── rest_reminder_service.dart                    # 抽象接口 + 事件模型
├── live_view_service.dart                        # 抽象接口 + 事件模型
├── widget_card_service.dart                      # 抽象接口 + WidgetCardData
├── invite_url_service.dart                       # 抽象接口
├── platform_services.dart                        # 单例容器（注入入口）
├── noop_platform_services.dart                   # 桌面/测试环境 Noop 实现
└── implementations/
    ├── ohos_rest_reminder_service.dart           # 包装 OhosReminderService
    ├── ohos_live_view_service.dart               # 包装 FormKitService（rest 模式）
    ├── ohos_widget_card_service.dart             # 包装 FormKitService
    ├── ohos_invite_url_service.dart              # Noop（OHOS 不需要）
    ├── android_rest_reminder_service.dart        # 包装 AndroidAlarmService
    ├── android_live_view_service.dart            # MethodChannel -> RestOngoingService
    ├── android_widget_card_service.dart          # MethodChannel -> GlanceAppWidget
    ├── android_invite_url_service.dart           # MethodChannel -> URL handler
    ├── ios_rest_reminder_service.dart            # MethodChannel -> UNUserNotificationCenter
    ├── ios_live_view_service.dart                # MethodChannel -> ActivityKit
    ├── ios_widget_card_service.dart              # MethodChannel -> WidgetKit
    └── ios_invite_url_service.dart               # MethodChannel -> URL scheme
```

### 新增文件（iOS 原生）

```
fittrack_flutter/ios/Runner/
├── AppDelegate.swift                             # 修改：注册 4 个 MethodChannel
├── Info.plist                                    # 修改：补权限 + URL scheme + Live Activities
├── Runner.entitlements                           # 新增：App Groups
└── RestLiveActivity/                             # 新增 Widget Extension target
    ├── RestLiveActivityAttributes.swift          # Live Activity 数据模型
    ├── RestLiveActivity.swift                    # Live Activity UI
    ├── FitTrackWidget.swift                      # Home Screen Widget（三态）
    ├── FitTrackWidgetEntry.swift                 # TimelineEntry + 数据读取
    ├── RestLiveActivityBundle.swift              # @main WidgetBundle
    ├── Info.plist                                # Extension 配置
    └── RestLiveActivity.entitlements             # App Groups
```

### 新增文件（Android 原生）

```
fittrack_flutter/android/app/src/main/
├── AndroidManifest.xml                           # 修改：补 AppWidget receiver + 前台服务
├── res/xml/fittrack_widget_info.xml              # 新增：AppWidget 元数据
├── res/layout/widget_rest_notification.xml       # 新增：休息倒计时通知布局
└── kotlin/com/fp/fitplan/
    ├── MainActivity.kt                           # 修改：注册 liveview + widget channel
    ├── widget/
    │   ├── FitTrackGlanceWidgetReceiver.kt       # 新增：GlanceAppWidgetReceiver
    │   ├── FitTrackGlanceWidget.kt               # 新增：GlanceAppWidget UI
    │   ├── FitTrackWidgetState.kt                # 新增：状态定义
    │   └── WidgetDataStore.kt                    # 新增：SharedPreferences 存储
    └── rest/
        ├── RestOngoingService.kt                 # 新增：前台服务
        └── RestNotificationBuilder.kt            # 新增：Chronometer 通知构建
```

### 新增文件（配置）

```
d:\app\projects\health_training\codemagic.yaml    # 新增：iOS 云构建配置
fittrack_flutter/android/build.gradle             # 修改：Kotlin 版本升级到 1.9.10
fittrack_flutter/android/app/build.gradle         # 修改：添加 Glance 依赖
```

### 修改文件（Dart 业务层）

- `fittrack_flutter/lib/main.dart` — PAL 注入 + 移除直接 import
- `fittrack_flutter/lib/pages/training_page.dart` — PAL 调用替换
- `fittrack_flutter/lib/pages/profile_page.dart` — PAL 调用替换（第 856 行）
- `fittrack_flutter/lib/services/rest_notification_service.dart` — PAL 调用替换

---

## Batch 1：PAL 骨架 + HarmonyOS/Android 现有能力包装

**目标**：新建 PAL 接口与 OHOS/Android 包装类，业务代码改用 PAL 接口。HarmonyOS 与 Android 既有行为不变。

### Task 1.1: 创建 PAL 接口定义

**Files:**
- Create: `fittrack_flutter/lib/services/platform/rest_reminder_service.dart`
- Create: `fittrack_flutter/lib/services/platform/live_view_service.dart`
- Create: `fittrack_flutter/lib/services/platform/widget_card_service.dart`
- Create: `fittrack_flutter/lib/services/platform/invite_url_service.dart`

**Interfaces:**
- Produces: `RestReminderService` (abstract), `LiveViewService` (abstract), `WidgetCardService` (abstract), `InviteUrlService` (abstract), `WidgetCardData`, `WidgetCardMode`, `RestReminderEvent`, `LiveViewEvent`, `LiveViewAction`, `WidgetCardClickEvent`

- [ ] **Step 1: 创建 rest_reminder_service.dart**

```dart
// fittrack_flutter/lib/services/platform/rest_reminder_service.dart
import 'dart:async';

/// 休息提醒事件
class RestReminderEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;

  RestReminderEvent({this.targetPage, this.cardAction, required this.payload});

  factory RestReminderEvent.fromMap(Map<String, dynamic> map) =>
      RestReminderEvent(
        targetPage: map['targetPage'] as String?,
        cardAction: map['cardAction'] as String?,
        payload: map,
      );
}

/// 休息提醒服务抽象接口
abstract class RestReminderService {
  /// 初始化（应用启动时调用一次）
  Future<void> init();

  /// 预约定时休息提醒
  ///
  /// [title] 通知标题
  /// [content] 通知内容
  /// [triggerTimeInSeconds] 延迟秒数
  /// [notificationId] 通知 ID
  /// 返回 reminderId，失败返回 null
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  });

  /// 取消当前提醒
  Future<void> cancelCurrentReminder();

  /// 取消所有提醒
  Future<void> cancelAllReminders();

  /// 通知点击事件流
  Stream<RestReminderEvent> get onNotificationClick;
}
```

- [ ] **Step 2: 创建 live_view_service.dart**

```dart
// fittrack_flutter/lib/services/platform/live_view_service.dart
import 'dart:async';

/// 实况窗用户操作类型
enum LiveViewAction { skipRest, resume }

/// 实况窗事件
class LiveViewEvent {
  final LiveViewAction action;
  final Map<String, dynamic> payload;

  LiveViewEvent({required this.action, required this.payload});
}

/// 实况窗服务抽象接口
abstract class LiveViewService {
  /// 启动休息倒计时实况窗
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  });

  /// 停止实况窗
  Future<void> stopRestLiveView();

  /// 用户操作事件流（点击"结束休息"等）
  Stream<LiveViewEvent> get onUserAction;
}
```

- [ ] **Step 3: 创建 widget_card_service.dart**

```dart
// fittrack_flutter/lib/services/platform/widget_card_service.dart
import 'dart:async';

/// 桌面卡片模式
enum WidgetCardMode { idle, training, rest }

/// 卡片点击事件
class WidgetCardClickEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;

  WidgetCardClickEvent({this.targetPage, this.cardAction, required this.payload});

  factory WidgetCardClickEvent.fromMap(Map<String, dynamic> map) =>
      WidgetCardClickEvent(
        targetPage: map['targetPage'] as String?,
        cardAction: map['cardAction'] as String?,
        payload: map,
      );
}

/// 桌面卡片数据
class WidgetCardData {
  final WidgetCardMode mode;
  final String? exerciseName;
  final int? currentSet;
  final int? totalSets;
  final int? exerciseIndex;
  final int? totalExercises;
  final int? completedSets;
  final int? totalPlanSets;
  final DateTime? restEndTime;
  final int? restTotalSeconds;
  final int todayTrainingCount;
  final int todayTrainingMinutes;
  final int todayTotalWeight;
  final int consecutiveDays;
  final String? lastTrainingName;
  final String? lastTrainingDate;
  final String? reminderTime;
  final String accentColor;
  final String bgColor;
  final String textPrimaryColor;
  final String textSecondaryColor;

  const WidgetCardData({
    this.mode = WidgetCardMode.idle,
    this.exerciseName,
    this.currentSet,
    this.totalSets,
    this.exerciseIndex,
    this.totalExercises,
    this.completedSets,
    this.totalPlanSets,
    this.restEndTime,
    this.restTotalSeconds,
    this.todayTrainingCount = 0,
    this.todayTrainingMinutes = 0,
    this.todayTotalWeight = 0,
    this.consecutiveDays = 0,
    this.lastTrainingName,
    this.lastTrainingDate,
    this.reminderTime,
    this.accentColor = '#FF6B35',
    this.bgColor = '#FFFFFF',
    this.textPrimaryColor = '#222222',
    this.textSecondaryColor = '#999999',
  });

  /// 转换为 JSON（与 OHOS FormDataRecord 字段一致）
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      if (exerciseName != null) 'exerciseName': exerciseName,
      if (currentSet != null) 'currentSet': currentSet,
      if (totalSets != null) 'totalSets': totalSets,
      if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
      if (totalExercises != null) 'totalExercises': totalExercises,
      if (completedSets != null) 'completedSets': completedSets,
      if (totalPlanSets != null) 'totalPlanSets': totalPlanSets,
      if (restEndTime != null) 'restEndTime': restEndTime!.millisecondsSinceEpoch,
      if (restTotalSeconds != null) 'restTotalSeconds': restTotalSeconds,
      'todayTrainings': todayTrainingCount,
      'todayDuration': todayTrainingMinutes,
      'todayWeight': todayTotalWeight,
      'streak': consecutiveDays,
      'lastTraining': lastTrainingName ?? '',
      'lastDate': lastTrainingDate ?? '',
      'accentColor': accentColor,
      'bgColor': bgColor,
      'textPrimaryColor': textPrimaryColor,
      'textSecondaryColor': textSecondaryColor,
      'trainingTime': reminderTime ?? '',
    };
  }
}

/// 桌面卡片服务抽象接口
abstract class WidgetCardService {
  /// 初始化（应用启动时调用一次）
  Future<void> init();

  /// 推送卡片数据
  Future<void> pushCardData(WidgetCardData data);

  /// 清除卡片数据（恢复空闲态）
  Future<void> clearCardData();

  /// 卡片点击事件流
  Stream<WidgetCardClickEvent> get onCardClick;
}
```

- [ ] **Step 4: 创建 invite_url_service.dart**

```dart
// fittrack_flutter/lib/services/platform/invite_url_service.dart
import 'dart:async';

/// 邀请链接服务抽象接口
abstract class InviteUrlService {
  /// 注册 URL 处理器（应用启动时调用）
  Future<void> registerHandler(Future<void> Function(Uri uri) handler);

  /// 打开邀请链接（调用系统打开 URL）
  Future<void> launchInviteUrl(Uri uri);
}
```

- [ ] **Step 5: Commit**

```bash
cd fittrack_flutter
git add lib/services/platform/rest_reminder_service.dart lib/services/platform/live_view_service.dart lib/services/platform/widget_card_service.dart lib/services/platform/invite_url_service.dart
git commit -m "feat: add PAL interface definitions for cross-platform services"
```

---

### Task 1.2: 创建 OHOS 包装类

**Files:**
- Create: `fittrack_flutter/lib/services/platform/implementations/ohos_rest_reminder_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/ohos_live_view_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/ohos_widget_card_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/ohos_invite_url_service.dart`

**Interfaces:**
- Consumes: `OhosReminderService` (from `../../ohos_reminder_service.dart`), `FormKitService` (from `../../form_kit_service.dart`)
- Produces: `OhosRestReminderService`, `OhosLiveViewService`, `OhosWidgetCardService`, `OhosInviteUrlService` (实现 PAL 接口)

- [ ] **Step 1: 创建 ohos_rest_reminder_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ohos_rest_reminder_service.dart
import 'dart:async';
import '../../ohos_reminder_service.dart';
import '../rest_reminder_service.dart';

/// OHOS 休息提醒服务（包装 OhosReminderService）
class OhosRestReminderService implements RestReminderService {
  final OhosReminderService _delegate = OhosReminderService.instance;

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _delegate.initListener();
    _delegate.onNotificationClick = (args) {
      _clickController.add(RestReminderEvent.fromMap(args));
    };
  }

  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) {
    return _delegate.publishReminder(
      title: title,
      content: content,
      triggerTimeInSeconds: triggerTimeInSeconds,
      notificationId: notificationId,
    );
  }

  @override
  Future<void> cancelCurrentReminder() =>
      _delegate.cancelCurrentReminder();

  @override
  Future<void> cancelAllReminders() => _delegate.cancelAllReminders();

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
```

- [ ] **Step 2: 创建 ohos_live_view_service.dart**

OHOS 的实况窗由 EntryAbility 原生侧管理：当 FormKitService 推送 `mode=rest` 数据时，EntryAbility 自动启动 LiveView。因此 `startRestLiveView` 实际是调用 `FormKitService.instance.startRest`。

```dart
// fittrack_flutter/lib/services/platform/implementations/ohos_live_view_service.dart
import 'dart:async';
import '../../ohos_reminder_service.dart';
import '../../form_kit_service.dart';
import '../live_view_service.dart';

/// OHOS 实况窗服务（包装 FormKitService.startRest + OhosReminderService 卡片点击）
class OhosLiveViewService implements LiveViewService {
  final FormKitService _formKit = FormKitService.instance;
  final OhosReminderService _reminder = OhosReminderService.instance;

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    _formKit.startRest(
      exerciseName: exerciseName,
      restSeconds: restSeconds,
      restEndTime: restEndTime.millisecondsSinceEpoch,
      totalRestSeconds: restSeconds,
      currentSet: 0,
      totalSets: 0,
      exerciseIndex: 0,
      totalExercises: 0,
      completedSets: 0,
      totalPlanSets: 0,
    );
  }

  @override
  Future<void> stopRestLiveView() async {
    // OHOS 实况窗由 EntryAbility 在 mode 切换时自动停止，无需显式调用
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;

  /// 由 main.dart 在注册卡片点击时调用，转发到本服务的 onUserAction
  void handleCardClick(Map<String, dynamic> args) {
    final cardAction = args['cardAction'] as String?;
    if (cardAction == 'skipRest') {
      _actionController.add(LiveViewEvent(
        action: LiveViewAction.skipRest,
        payload: args,
      ));
    } else if (cardAction == 'resume') {
      _actionController.add(LiveViewEvent(
        action: LiveViewAction.resume,
        payload: args,
      ));
    }
  }
}
```

- [ ] **Step 3: 创建 ohos_widget_card_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ohos_widget_card_service.dart
import 'dart:async';
import '../../form_kit_service.dart';
import '../../ohos_reminder_service.dart';
import '../widget_card_service.dart';

/// OHOS 桌面卡片服务（包装 FormKitService）
class OhosWidgetCardService implements WidgetCardService {
  final FormKitService _formKit = FormKitService.instance;
  final OhosReminderService _reminder = OhosReminderService.instance;

  final StreamController<WidgetCardClickEvent> _clickController =
      StreamController<WidgetCardClickEvent>.broadcast();

  @override
  Future<void> init() async {
    _formKit.init();
    // 卡片点击由 main.dart 统一注册，此处仅暴露事件流
  }

  @override
  Future<void> pushCardData(WidgetCardData data) async {
    if (data.mode == WidgetCardMode.idle) {
      _formKit.endTraining();
      return;
    }
    if (data.mode == WidgetCardMode.training) {
      _formKit.updateTrainingState(
        exerciseName: data.exerciseName ?? '',
        currentSet: data.currentSet ?? 0,
        totalSets: data.totalSets ?? 0,
        exerciseIndex: data.exerciseIndex ?? 0,
        totalExercises: data.totalExercises ?? 0,
        completedSets: data.completedSets ?? 0,
        totalPlanSets: data.totalPlanSets ?? 0,
      );
      return;
    }
    if (data.mode == WidgetCardMode.rest) {
      _formKit.startRest(
        exerciseName: data.exerciseName ?? '',
        restSeconds: data.restTotalSeconds ?? 0,
        restEndTime: data.restEndTime?.millisecondsSinceEpoch ?? 0,
        totalRestSeconds: data.restTotalSeconds ?? 0,
        currentSet: data.currentSet ?? 0,
        totalSets: data.totalSets ?? 0,
        exerciseIndex: data.exerciseIndex ?? 0,
        totalExercises: data.totalExercises ?? 0,
        completedSets: data.completedSets ?? 0,
        totalPlanSets: data.totalPlanSets ?? 0,
      );
    }
  }

  @override
  Future<void> clearCardData() async {
    _formKit.endTraining();
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;

  /// 由 main.dart 在注册卡片点击时调用
  void handleCardClick(Map<String, dynamic> args) {
    _clickController.add(WidgetCardClickEvent.fromMap(args));
  }
}
```

- [ ] **Step 4: 创建 ohos_invite_url_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ohos_invite_url_service.dart
import '../invite_url_service.dart';

/// OHOS 邀请链接服务（Noop，OHOS 不需要 URL scheme）
class OhosInviteUrlService implements InviteUrlService {
  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {
    // OHOS 不支持 fittrack:// URL scheme，无需注册
  }

  @override
  Future<void> launchInviteUrl(Uri uri) async {
    // OHOS 无 URL scheme 处理
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/platform/implementations/ohos_*.dart
git commit -m "feat: add OHOS PAL implementations wrapping existing services"
```

---

### Task 1.3: 创建 Android 包装类

**Files:**
- Create: `fittrack_flutter/lib/services/platform/implementations/android_rest_reminder_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/android_invite_url_service.dart`

**Interfaces:**
- Consumes: `AndroidAlarmService` (from `../../android_alarm_service.dart`)
- Produces: `AndroidRestReminderService`, `AndroidInviteUrlService`

注意：`AndroidLiveViewService` 和 `AndroidWidgetCardService` 在 Batch 3 创建（依赖新增的原生 RestOngoingService 和 GlanceAppWidget）。

- [ ] **Step 1: 创建 android_rest_reminder_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/android_rest_reminder_service.dart
import 'dart:async';
import '../../android_alarm_service.dart';
import '../rest_reminder_service.dart';

/// Android 休息提醒服务（包装 AndroidAlarmService）
class AndroidRestReminderService implements RestReminderService {
  final AndroidAlarmService _delegate = AndroidAlarmService.instance;

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _delegate.initListener();
    _delegate.onCardClick = (args) {
      _clickController.add(RestReminderEvent.fromMap(args));
    };
  }

  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) {
    return _delegate.scheduleRestAlarm(
      title: title,
      content: content,
      exerciseName: '',
      triggerTimeInSeconds: triggerTimeInSeconds,
      notificationId: notificationId,
    );
  }

  @override
  Future<void> cancelCurrentReminder() => _delegate.cancelRestAlarm();

  @override
  Future<void> cancelAllReminders() => _delegate.cancelAllAlarms();

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
```

- [ ] **Step 2: 创建 android_invite_url_service.dart**

Android 已有 `fittrack://invite` IntentFilter（AndroidManifest.xml 第 43-48 行），MainActivity 已通过 `handleNotificationIntent` 处理。但当前 `handleNotificationIntent` 只处理 `targetPage`/`cardAction`，不处理 `fittrack://` URL。需要扩展。

```dart
// fittrack_flutter/lib/services/platform/implementations/android_invite_url_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import '../invite_url_service.dart';

/// Android 邀请链接服务
///
/// AndroidManifest.xml 已声明 fittrack://invite IntentFilter，
/// MainActivity.handleNotificationIntent 需扩展支持 URL 解析。
class AndroidInviteUrlService implements InviteUrlService {
  static const _channel = MethodChannel('com.fp.fitplan/invite');

  Future<void> Function(Uri)? _handler;

  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {
    _handler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInviteUrl') {
        final url = call.arguments as String;
        try {
          await _handler?.call(Uri.parse(url));
        } catch (e) {
          debugPrint('[AndroidInvite] handler error: $e');
        }
      }
    });
  }

  @override
  Future<void> launchInviteUrl(Uri uri) async {
    // Android 上邀请链接通过 IntentFilter 直接打开本应用，无需显式 launch
    // 此方法保留给未来需要从本应用打开其他应用 URL 的场景
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/platform/implementations/android_rest_reminder_service.dart lib/services/platform/implementations/android_invite_url_service.dart
git commit -m "feat: add Android PAL implementations for rest reminder and invite URL"
```

---

### Task 1.4: 创建 PlatformServices 容器与 Noop 实现

**Files:**
- Create: `fittrack_flutter/lib/services/platform/noop_platform_services.dart`
- Create: `fittrack_flutter/lib/services/platform/platform_services.dart`

**Interfaces:**
- Consumes: 所有 PAL 接口 + OHOS/Android 实现类
- Produces: `PlatformServices` 静态容器

- [ ] **Step 1: 创建 noop_platform_services.dart**

```dart
// fittrack_flutter/lib/services/platform/noop_platform_services.dart
import 'dart:async';
import 'rest_reminder_service.dart';
import 'live_view_service.dart';
import 'widget_card_service.dart';
import 'invite_url_service.dart';

/// 桌面/测试环境的 Noop 休息提醒服务
class NoopRestReminderService implements RestReminderService {
  @override
  Future<void> init() async {}
  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async => null;
  @override
  Future<void> cancelCurrentReminder() async {}
  @override
  Future<void> cancelAllReminders() async {}
  @override
  Stream<RestReminderEvent> get onNotificationClick => const Stream.empty();
}

/// 桌面/测试环境的 Noop 实况窗服务
class NoopLiveViewService implements LiveViewService {
  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {}
  @override
  Future<void> stopRestLiveView() async {}
  @override
  Stream<LiveViewEvent> get onUserAction => const Stream.empty();
}

/// 桌面/测试环境的 Noop 桌面卡片服务
class NoopWidgetCardService implements WidgetCardService {
  @override
  Future<void> init() async {}
  @override
  Future<void> pushCardData(WidgetCardData data) async {}
  @override
  Future<void> clearCardData() async {}
  @override
  Stream<WidgetCardClickEvent> get onCardClick => const Stream.empty();
}

/// 桌面/测试环境的 Noop 邀请链接服务
class NoopInviteUrlService implements InviteUrlService {
  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {}
  @override
  Future<void> launchInviteUrl(Uri uri) async {}
}
```

- [ ] **Step 2: 创建 platform_services.dart**

```dart
// fittrack_flutter/lib/services/platform/platform_services.dart
import 'dart:io';
import '../../utils/platform_utils.dart';
import 'rest_reminder_service.dart';
import 'live_view_service.dart';
import 'widget_card_service.dart';
import 'invite_url_service.dart';
import 'noop_platform_services.dart';
import 'implementations/ohos_rest_reminder_service.dart';
import 'implementations/ohos_live_view_service.dart';
import 'implementations/ohos_widget_card_service.dart';
import 'implementations/ohos_invite_url_service.dart';
import 'implementations/android_rest_reminder_service.dart';
import 'implementations/android_invite_url_service.dart';

/// 平台服务容器（应用启动时注入）
class PlatformServices {
  static late final RestReminderService restReminder;
  static late final LiveViewService liveView;
  static late final WidgetCardService widgetCard;
  static late final InviteUrlService inviteUrl;

  /// 是否已初始化
  static bool _initialized = false;

  /// 初始化平台服务（main.dart 中调用一次）
  static Future<void> init() async {
    if (_initialized) return;

    if (isOhos) {
      restReminder = OhosRestReminderService();
      liveView = OhosLiveViewService();
      widgetCard = OhosWidgetCardService();
      inviteUrl = OhosInviteUrlService();
    } else if (Platform.isAndroid) {
      restReminder = AndroidRestReminderService();
      // AndroidLiveViewService / AndroidWidgetCardService 在 Batch 3 创建
      // 当前先用 Noop，Batch 3 替换
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = AndroidInviteUrlService();
    } else if (Platform.isIOS) {
      // iOS 实现在 Batch 2/3 创建，当前先用 Noop
      restReminder = NoopRestReminderService();
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = NoopInviteUrlService();
    } else {
      restReminder = NoopRestReminderService();
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = NoopInviteUrlService();
    }

    await restReminder.init();
    await widgetCard.init();

    _initialized = true;
  }

  /// 获取 OHOS 实况窗服务实例（用于 main.dart 注册卡片点击回调）
  /// 非 OHOS 平台返回 null
  static OhosLiveViewService? get ohosLiveView =>
      liveView is OhosLiveViewService ? liveView as OhosLiveViewService : null;

  /// 获取 OHOS 桌面卡片服务实例
  static OhosWidgetCardService? get ohosWidgetCard =>
      widgetCard is OhosWidgetCardService
          ? widgetCard as OhosWidgetCardService
          : null;
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/services/platform/noop_platform_services.dart lib/services/platform/platform_services.dart
git commit -m "feat: add PlatformServices container and Noop implementations"
```

---

### Task 1.5: 改造 main.dart 使用 PAL

**Files:**
- Modify: `fittrack_flutter/lib/main.dart`

**Interfaces:**
- Consumes: `PlatformServices` (from `services/platform/platform_services.dart`)

- [ ] **Step 1: 修改 main.dart**

将 `main()` 函数中第 60-95 行（`Future.wait([...])` + `if (isOhos) {...}`）替换为 PAL 注入。

修改 imports（第 13-16 行）：

```dart
// 替换以下 imports：
// import 'services/form_kit_service.dart';
// import 'services/ohos_reminder_service.dart';
// import 'services/android_alarm_service.dart';
// import 'services/rom_adaptation_service.dart';

// 改为：
import 'services/rom_adaptation_service.dart';
import 'services/platform/platform_services.dart';
import 'services/platform/implementations/ohos_live_view_service.dart';
import 'services/platform/implementations/ohos_widget_card_service.dart';
```

修改 `main()` 函数（第 60-95 行）：

```dart
    // 通知/推送/留存/IAP 服务之间无依赖，并行初始化
    await Future.wait([
      soundFuture,
      RestNotificationService.instance.init(),
      SmartPushService.instance.init(),
      RetentionChainService.instance.init(),
      IapService.instance.init(),
      DailyReminderService.instance.init(),
      GymCardReminderService.instance.init(),
    ]);
    // 启动后立即检查一次健身卡到期（fire-and-forget）
    GymCardReminderService.instance.checkAndPush();
    // 初始化平台抽象层（PAL）
    await PlatformServices.init();
    // OHOS: 注册卡片点击回调（统一通过 PAL 事件流分发）
    final ohosLiveView = PlatformServices.ohosLiveView;
    final ohosWidgetCard = PlatformServices.ohosWidgetCard;
    if (ohosLiveView != null && ohosWidgetCard != null) {
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        if (targetPage == 'training') {
          final handler = OhosReminderService.instance.onTrainingCardAction;
          if (handler != null) {
            handler(args);
          } else {
            _globalRouter?.go('/home');
          }
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
        // 转发到 PAL 事件流
        ohosWidgetCard.handleCardClick(args);
        ohosLiveView.handleCardClick(args);
      };
    }
    runApp(const FitTrackApp());
```

修改 `_onThemeChanged`（第 164-166 行）：

```dart
    // 更新桌面卡片主题
    PlatformServices.widgetCard.pushCardData(
      WidgetCardData(mode: WidgetCardMode.idle),
    );
```

注意：需要 import `widget_card_service.dart`：

```dart
import 'services/platform/widget_card_service.dart';
```

- [ ] **Step 2: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/main.dart lib/services/platform/
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "refactor: main.dart uses PAL for platform service injection"
```

---

### Task 1.6: 改造 training_page.dart 使用 PAL

**Files:**
- Modify: `fittrack_flutter/lib/pages/training_page.dart`

**Interfaces:**
- Consumes: `PlatformServices` (from `../services/platform/platform_services.dart`)

- [ ] **Step 1: 修改 imports**

删除：
```dart
import '../services/ohos_reminder_service.dart';
import '../services/android_alarm_service.dart';
import '../services/form_kit_service.dart';
import '../utils/platform_utils.dart';
```

新增：
```dart
import '../services/platform/platform_services.dart';
import '../services/platform/widget_card_service.dart';
import '../services/platform/live_view_service.dart';
```

- [ ] **Step 2: 修改 initState（第 90-105 行）**

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _loadData();

    // 监听通知点击（通过 PAL 统一处理）
    PlatformServices.restReminder.onNotificationClick.listen(_onNotificationClicked);
    // 监听实况窗用户操作（skipRest / resume）
    PlatformServices.liveView.onUserAction.listen((event) {
      if (!mounted) return;
      if (event.action == LiveViewAction.skipRest && _isResting) {
        _skipRest();
      }
    });
  }
```

- [ ] **Step 3: 修改 dispose（第 107-121 行）**

删除 OHOS/Android 专属回调清理（PAL Stream 自动管理生命周期）：

```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }
```

- [ ] **Step 4: 删除 _onAndroidAlarmCardClick 和 _onTrainingCardAction（第 123-160 行）**

这两个方法被 PAL 事件流替代。删除 `_onAndroidAlarmCardClick`、`_onTrainingCardAction`、`_onNotificationClicked` 中的 `isOhos` 判断。

修改 `_onNotificationClicked`（第 163-177 行）：

```dart
  /// 通知点击回调：回到训练页并处理休息结束
  void _onNotificationClicked(RestReminderEvent event) {
    if (!mounted) return;
    if (_isResting && _restEndTime != null) {
      final now = DateTime.now();
      if (now.isAfter(_restEndTime!) || now.isAtSameMomentAs(_restEndTime!)) {
        _restSeconds = 0;
        RestNotificationService.instance.cancelScheduledNotification();
        _notifyRestEnd();
        _advanceAfterRest();
      }
    }
  }
```

注意：`_onNotificationClicked` 的参数类型从 `Map<String, dynamic>` 改为 `RestReminderEvent`。需要 import：

```dart
import '../services/platform/rest_reminder_service.dart';
```

- [ ] **Step 5: 修改 _resetWidgetOnExit（第 139-143 行）**

```dart
  void _resetWidgetOnExit() {
    PlatformServices.widgetCard.clearCardData();
  }
```

- [ ] **Step 6: 修改 _startRest（第 345-388 行）**

将第 358-372 行的 `if (isOhos && ...)` 块替换为 PAL 调用：

```dart
    // 推送休息状态到卡片 + 启动实况窗
    if (_currentExIdx < _exercises.length) {
      final currentEx = _exercises[_currentExIdx];
      final exerciseName = currentEx['name'] as String;
      final totalSets = (currentEx['sets'] as int?) ?? 0;

      PlatformServices.widgetCard.pushCardData(WidgetCardData(
        mode: WidgetCardMode.rest,
        exerciseName: exerciseName,
        restTotalSeconds: seconds,
        restEndTime: _restEndTime,
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
        restEndTime: _restEndTime!,
      );
    }
```

将第 377-385 行的 `if (!isOhos) {...}` 替换：

```dart
    // 预约定时通知（后台时系统自动触发）
    // OHOS 平台：EntryAbility 接收到 mode=rest 数据后自动发布代理提醒
    // Android/iOS：通过 RestNotificationService 调度
    if (!PlatformServices.restReminder is OhosRestReminderService) {
      final exerciseName = _currentExIdx < _exercises.length
          ? _exercises[_currentExIdx]['name'] as String
          : '';
      RestNotificationService.instance.scheduleRestEndNotification(
        exerciseName: exerciseName,
        delaySeconds: seconds,
      );
    }
```

注意：这里用 `is OhosRestReminderService` 判断。需要 import：

```dart
import '../services/platform/implementations/ohos_rest_reminder_service.dart';
```

- [ ] **Step 7: 修改 _skipRest（第 421-429 行）**

```dart
  void _skipRest() {
    _restTimer?.cancel();
    RestNotificationService.instance.cancelScheduledNotification();
    _advanceAfterRest(restSkipped: true);
  }
```

- [ ] **Step 8: 修改 _notifyRestEnd（第 435-452 行）**

```dart
  Future<void> _notifyRestEnd() async {
    if (_restEndNotified) return;
    _restEndNotified = true;

    final exerciseName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

    if (_appLifecycleState == AppLifecycleState.resumed) {
      await RestNotificationService.instance
          .showRestEndNotification(exerciseName: exerciseName);
    }
  }
```

- [ ] **Step 9: 修改 _onAppResumedFromBackground（第 194-216 行）**

删除 `if (!isOhos)` 判断：

```dart
  void _onAppResumedFromBackground() {
    final now = DateTime.now();
    if (now.isAfter(_restEndTime!) || now.isAtSameMomentAs(_restEndTime!)) {
      _restSeconds = 0;
      RestNotificationService.instance.cancelScheduledNotification();
      _notifyRestEnd();
      _advanceAfterRest();
    } else {
      final remaining = _restEndTime!.difference(now).inSeconds;
      setState(() {
        _restSeconds = remaining;
      });
      _restartRestTimer();
    }
  }
```

- [ ] **Step 10: 修改 _pushTrainingToWidget（第 479-493 行）**

```dart
  void _pushTrainingToWidget({bool restSkipped = false}) {
    if (_currentExIdx >= _exercises.length) return;
    final currentEx = _exercises[_currentExIdx];
    PlatformServices.widgetCard.pushCardData(WidgetCardData(
      mode: WidgetCardMode.training,
      exerciseName: currentEx['name'] as String,
      currentSet: _currentSetIdx + 1,
      totalSets: (currentEx['sets'] as int?) ?? 0,
      exerciseIndex: _currentExIdx + 1,
      totalExercises: _exercises.length,
      completedSets: _completedSets,
      totalPlanSets: _totalSets,
    ));
  }
```

- [ ] **Step 11: 修改 _returnHome（第 627-647 行）**

```dart
  Future<void> _returnHome() async {
    // 更新桌面卡片数据
    PlatformServices.widgetCard.clearCardData();
    PlatformServices.liveView.stopRestLiveView();

    SmartPushService.instance.onTrainingCompleted();
    RetentionChainService.instance.recordFirstTrainingIfNeeded();

    if (mounted) {
      await RatingPromptSheet.maybeShow(context);
    }
    if (mounted) {
      context.go('/home');
    }
  }
```

- [ ] **Step 12: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/pages/training_page.dart
```

Expected: No issues found.

- [ ] **Step 13: Commit**

```bash
git add lib/pages/training_page.dart
git commit -m "refactor: training_page uses PAL for platform-agnostic calls"
```

---

### Task 1.7: 改造 profile_page.dart 与 rest_notification_service.dart

**Files:**
- Modify: `fittrack_flutter/lib/pages/profile_page.dart` (第 856 行)
- Modify: `fittrack_flutter/lib/services/rest_notification_service.dart`

- [ ] **Step 1: 修改 profile_page.dart 第 856 行**

将：
```dart
if (isOhos) {
  FormKitService.instance.pushFormData();
}
```

改为：
```dart
PlatformServices.widgetCard.pushCardData(
  WidgetCardData(mode: WidgetCardMode.idle),
);
```

并在文件顶部添加 imports：
```dart
import '../services/platform/platform_services.dart';
import '../services/platform/widget_card_service.dart';
```

删除不再需要的 imports（如果存在）：
```dart
import '../services/form_kit_service.dart';
import '../utils/platform_utils.dart';
```

- [ ] **Step 2: 修改 rest_notification_service.dart**

将所有 `OhosReminderService` 和 `AndroidAlarmService` 直接调用改为通过 `PlatformServices.restReminder`。

修改 imports（第 7-10 行）：
```dart
// 删除：
// import 'ohos_reminder_service.dart';
// import 'android_alarm_service.dart';

// 新增：
import 'platform/platform_services.dart';
import 'platform/implementations/ohos_rest_reminder_service.dart';
```

修改 `init()` 第 87-92 行：
```dart
      // 平台服务由 PlatformServices.init() 统一初始化，此处不再重复
```

修改 `_requestNotificationPermission()` 第 105-108 行：
```dart
      // OHOS 平台：跳过 flutter_local_notifications 权限请求
      if (PlatformServices.restReminder is OhosRestReminderService) {
        debugPrint('OHOS: skip flutter_local_notifications permission request');
        return true;
      }
```

修改 `_configureLocalTimeZone()` 第 125-130 行：
```dart
      if (PlatformServices.restReminder is OhosRestReminderService) {
        final String timeZoneName = await _plugin!.getLocalTimezone();
        debugPrint('OHOS timezone: $timeZoneName');
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }
```

修改 `scheduleRestEndNotification()` 第 177-195 行：
```dart
      if (PlatformServices.restReminder is OhosRestReminderService) {
        // OHOS：由 EntryAbility 原生侧处理代理提醒
        debugPrint('OHOS reminder handled by native EntryAbility, skip Flutter side');
      } else {
        // Android/iOS：通过 PAL 调度
        final result = await PlatformServices.restReminder.scheduleRestReminder(
          title: title,
          content: content,
          triggerTimeInSeconds: delaySeconds,
          notificationId: _notificationId,
        );
        if (result != null) {
          debugPrint('Native reminder scheduled, id: $result');
        }
      }
```

修改 `cancelScheduledNotification()` 第 260-264 行：
```dart
    await PlatformServices.restReminder.cancelCurrentReminder();
```

修改 `cancelAll()` 第 275-279 行：
```dart
    await PlatformServices.restReminder.cancelAllReminders();
```

- [ ] **Step 3: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/pages/profile_page.dart lib/services/rest_notification_service.dart
```

Expected: No issues found.

- [ ] **Step 4: 运行现有测试**

```bash
cd fittrack_flutter
flutter test
```

Expected: All existing tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/profile_page.dart lib/services/rest_notification_service.dart
git commit -m "refactor: profile_page and rest_notification_service use PAL"
```

---

### Task 1.8: Batch 1 端到端验证

- [ ] **Step 1: Android 构建验证**

```bash
cd fittrack_flutter
flutter build apk --debug --target-platform android-x64
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 2: OHOS 静态分析验证**

```bash
cd fittrack_flutter
flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: 运行 Android 模拟器端到端**

```bash
cd fittrack_flutter
flutter run -d emulator-5558
```

验证：
1. 应用启动正常
2. 进入训练页，完成一组，休息倒计时正常
3. 退出训练页返回首页正常
4. Android 行为与改造前一致

- [ ] **Step 4: Commit Batch 1 完成标记**

```bash
git commit --allow-empty -m "chore: Batch 1 complete - PAL skeleton with OHOS/Android wrappers"
```

---

## Batch 2：iOS P0 修复（Info.plist + AppDelegate）

**目标**：修复 iOS 必闪退项，补齐基础能力（通知、URL scheme）。

### Task 2.1: 补全 Info.plist

**Files:**
- Modify: `fittrack_flutter/ios/Runner/Info.plist`

- [ ] **Step 1: 在 `</dict>` 前添加以下键**

在第 49 行 `</dict>` 之前添加：

```xml
	<!-- 权限说明 -->
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>用于将训练海报保存到您的相册</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>用于读取相册图片作为头像</string>

	<!-- Live Activities 支持（iOS 16.1+） -->
	<key>NSSupportsLiveActivities</key>
	<true/>

	<!-- URL scheme 邀请链接 -->
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.fp.fitplan.invite</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>fittrack</string>
			</array>
		</dict>
	</array>

	<!-- 后台模式 -->
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
```

- [ ] **Step 2: Commit**

```bash
cd fittrack_flutter
git add ios/Runner/Info.plist
git commit -m "fix: add required iOS Info.plist keys (permissions, URL scheme, Live Activities)"
```

---

### Task 2.2: 创建 Runner.entitlements

**Files:**
- Create: `fittrack_flutter/ios/Runner/Runner.entitlements`

- [ ] **Step 1: 创建 Runner.entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.fp.fitplan</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 2: Commit**

```bash
git add ios/Runner/Runner.entitlements
git commit -m "feat: add Runner.entitlements with App Group for Widget Extension"
```

---

### Task 2.3: 增强 AppDelegate.swift

**Files:**
- Modify: `fittrack_flutter/ios/Runner/AppDelegate.swift`

- [ ] **Step 1: 替换 AppDelegate.swift 完整内容**

```swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  private var reminderChannel: FlutterMethodChannel?
  private var liveViewChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
  private var inviteChannel: FlutterMethodChannel?
  private var lastScheduledNotificationId: Int? = nil

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as? FlutterViewController

    // 1. 休息提醒通道
    reminderChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/reminder",
      binaryMessenger: controller!.binaryMessenger
    )
    setupReminderChannel()

    // 2. 实况窗通道（Batch 3 实现，此处占位）
    liveViewChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/liveview",
      binaryMessenger: controller!.binaryMessenger
    )
    setupLiveViewChannel()

    // 3. 桌面卡片通道（Batch 3 实现，此处占位）
    widgetChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/widget",
      binaryMessenger: controller!.binaryMessenger
    )
    setupWidgetChannel()

    // 4. 邀请链接通道
    inviteChannel = FlutterMethodChannel(
      name: "com.fp.fitplan/invite",
      binaryMessenger: controller!.binaryMessenger
    )
    setupInviteChannel()

    // 设置 UNUserNotificationCenter 代理（处理通知点击）
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Reminder Channel

  private func setupReminderChannel() {
    reminderChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "scheduleRestReminder":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let content = args["content"] as? String,
              let triggerTimeInSeconds = args["triggerTimeInSeconds"] as? Int,
              let notificationId = args["notificationId"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }
        self?.scheduleRestReminder(
          title: title,
          bodyText: content,
          triggerTimeInSeconds: triggerTimeInSeconds,
          notificationId: notificationId,
          result: result
        )
      case "cancelRestReminder":
        let id = self?.lastScheduledNotificationId ?? 1001
        self?.cancelRestReminder(notificationId: id, result: result)
      case "cancelAllReminders":
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func scheduleRestReminder(
    title: String,
    bodyText: String,
    triggerTimeInSeconds: Int,
    notificationId: Int,
    result: @escaping FlutterResult
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = bodyText
    content.sound = .default
    content.userInfo = [
      "targetPage": "training",
      "cardAction": "resume",
      "notificationId": notificationId
    ]

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(triggerTimeInSeconds),
      repeats: false
    )

    let request = UNNotificationRequest(
      identifier: "rest_\(notificationId)",
      content: content,
      trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { [weak self] error in
      if let error = error {
        result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
      } else {
        self?.lastScheduledNotificationId = notificationId
        result(notificationId)
      }
    }
  }

  private func cancelRestReminder(notificationId: Int, result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["rest_\(notificationId)"]
    )
    result(true)
  }

  // MARK: - LiveView Channel (占位，Batch 3 实现)

  private func setupLiveViewChannel() {
    liveViewChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "startRestLiveView":
        // Batch 3 实现 ActivityKit
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "Live Activities in Batch 3", details: nil))
      case "stopRestLiveView":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Widget Channel (占位，Batch 3 实现)

  private func setupWidgetChannel() {
    widgetChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "pushCardData":
        // 写入 App Group UserDefaults（Batch 3 实现 WidgetKit reload）
        if let jsonData = call.arguments as? String {
          let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
          defaults?.set(jsonData, forKey: "widgetData")
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
        }
      case "clearCardData":
        let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
        defaults?.removeObject(forKey: "widgetData")
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Invite Channel

  private func setupInviteChannel() {
    inviteChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "launchInviteUrl":
        guard let urlString = call.arguments as? String,
              let url = URL(string: urlString) else {
          result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.open(url) { success in
            result(success)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - URL Scheme Handling

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // 处理 fittrack://invite/... URL
    inviteChannel?.invokeMethod("onInviteUrl", arguments: url.absoluteString)
    return true
  }

  // MARK: - UNUserNotificationCenterDelegate

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 前台也显示通知
    completionHandler([.banner, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    // 通知点击回传 Flutter
    reminderChannel?.invokeMethod("onCardClick", arguments: userInfo)
    completionHandler()
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/Runner/AppDelegate.swift
git commit -m "feat: enhance AppDelegate with 4 MethodChannels (reminder/liveview/widget/invite)"
```

---

### Task 2.4: 创建 iOS PAL 实现类

**Files:**
- Create: `fittrack_flutter/lib/services/platform/implementations/ios_rest_reminder_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/ios_invite_url_service.dart`

- [ ] **Step 1: 创建 ios_rest_reminder_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ios_rest_reminder_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../rest_reminder_service.dart';

/// iOS 休息提醒服务（通过 MethodChannel 调用 UNUserNotificationCenter）
class IosRestReminderService implements RestReminderService {
  static const _channel = MethodChannel('com.fp.fitplan/reminder');

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCardClick':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _clickController.add(RestReminderEvent.fromMap(args));
          break;
        default:
          debugPrint('[IosReminder] Unknown method: ${call.method}');
      }
    });
  }

  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async {
    try {
      final result = await _channel.invokeMethod<int>('scheduleRestReminder', {
        'title': title,
        'content': content,
        'triggerTimeInSeconds': triggerTimeInSeconds,
        'notificationId': notificationId,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('[IosReminder] scheduleRestReminder failed: ${e.code} - ${e.message}');
      return null;
    }
  }

  @override
  Future<void> cancelCurrentReminder() async {
    try {
      await _channel.invokeMethod<void>('cancelRestReminder');
    } catch (e) {
      debugPrint('[IosReminder] cancelRestReminder error: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _channel.invokeMethod<void>('cancelAllReminders');
    } catch (e) {
      debugPrint('[IosReminder] cancelAllReminders error: $e');
    }
  }

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
```

- [ ] **Step 2: 创建 ios_invite_url_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ios_invite_url_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../invite_url_service.dart';

/// iOS 邀请链接服务（通过 CFBundleURLTypes 处理 fittrack:// URL）
class IosInviteUrlService implements InviteUrlService {
  static const _channel = MethodChannel('com.fp.fitplan/invite');

  Future<void> Function(Uri)? _handler;

  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {
    _handler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onInviteUrl') {
        final url = call.arguments as String;
        try {
          await _handler?.call(Uri.parse(url));
        } catch (e) {
          debugPrint('[IosInvite] handler error: $e');
        }
      }
    });
  }

  @override
  Future<void> launchInviteUrl(Uri uri) async {
    try {
      await _channel.invokeMethod<bool>('launchInviteUrl', uri.toString());
    } catch (e) {
      debugPrint('[IosInvite] launchInviteUrl error: $e');
    }
  }
}
```

- [ ] **Step 3: 更新 platform_services.dart 注入 iOS 实现**

修改 `fittrack_flutter/lib/services/platform/platform_services.dart` 第 38-43 行：

```dart
    } else if (Platform.isIOS) {
      restReminder = IosRestReminderService();
      // iOSLiveViewService / IosWidgetCardService 在 Batch 3 创建
      liveView = NoopLiveViewService();
      widgetCard = NoopWidgetCardService();
      inviteUrl = IosInviteUrlService();
    } else {
```

并添加 import：
```dart
import 'implementations/ios_rest_reminder_service.dart';
import 'implementations/ios_invite_url_service.dart';
```

- [ ] **Step 4: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/services/platform/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/services/platform/implementations/ios_rest_reminder_service.dart lib/services/platform/implementations/ios_invite_url_service.dart lib/services/platform/platform_services.dart
git commit -m "feat: add iOS PAL implementations for rest reminder and invite URL"
```

---

### Task 2.5: 注册邀请链接处理器

**Files:**
- Modify: `fittrack_flutter/lib/main.dart`

- [ ] **Step 1: 在 main.dart 的 PlatformServices.init() 后注册邀请处理器**

在第 76 行（`await PlatformServices.init();` 之后）添加：

```dart
    // 注册邀请链接处理器
    PlatformServices.inviteUrl.registerHandler((uri) async {
      debugPrint('[Invite] Received URL: $uri');
      // 解析 fittrack://invite?code=XXX
      if (uri.host == 'invite') {
        final code = uri.queryParameters['code'];
        if (code != null && code.isNotEmpty) {
          _globalRouter?.go('/home?inviteCode=$code');
        }
      }
    });
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register invite URL handler in main.dart"
```

---

### Task 2.6: Batch 2 验证

- [ ] **Step 1: 静态分析**

```bash
cd fittrack_flutter
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Android 构建验证（确保未破坏 Android）**

```bash
cd fittrack_flutter
flutter build apk --debug --target-platform android-x64
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit Batch 2 完成标记**

```bash
git commit --allow-empty -m "chore: Batch 2 complete - iOS P0 fixes (Info.plist + AppDelegate)"
```

---

## Batch 3：iOS Live Activities + Home Widget + Android Glance AppWidget + 前台服务

**目标**：完全对齐 HarmonyOS 的桌面卡片和实况窗能力。

### Task 3.1: 创建 iOS Widget Extension 文件

**Files:**
- Create: `fittrack_flutter/ios/RestLiveActivity/RestLiveActivityAttributes.swift`
- Create: `fittrack_flutter/ios/RestLiveActivity/RestLiveActivity.swift`
- Create: `fittrack_flutter/ios/RestLiveActivity/FitTrackWidget.swift`
- Create: `fittrack_flutter/ios/RestLiveActivity/FitTrackWidgetEntry.swift`
- Create: `fittrack_flutter/ios/RestLiveActivity/RestLiveActivityBundle.swift`
- Create: `fittrack_flutter/ios/RestLiveActivity/Info.plist`
- Create: `fittrack_flutter/ios/RestLiveActivity/RestLiveActivity.entitlements`

- [ ] **Step 1: 创建 RestLiveActivityAttributes.swift**

```swift
// fittrack_flutter/ios/RestLiveActivity/RestLiveActivityAttributes.swift
import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct RestLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var remainingSeconds: Int
        var totalRestSeconds: Int
        var restEndTime: Date
    }

    var exerciseName: String
}
```

- [ ] **Step 2: 创建 RestLiveActivity.swift**

```swift
// fittrack_flutter/ios/RestLiveActivity/RestLiveActivity.swift
import WidgetKit
import SwiftUI
import ActivityKit

@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestLiveActivityAttributes.self) { context in
            // 锁屏显示
            LockScreenView(context: context)
                .padding(16)
                .activityBackgroundTint(Color(red: 0xFF/255, green: 0x6B/255, blue: 0x35/255))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("休息中")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.title2.monospacedDigit())
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.exerciseName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(timeString(context.state.remainingSeconds))
                    .font(.caption.monospacedDigit())
            } minimal: {
                Text(timeString(context.state.remainingSeconds))
                    .font(.caption2.monospacedDigit())
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

@available(iOS 16.1, *)
struct LockScreenView: View {
    let context: ActivityViewContext<RestLiveActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("FitTrack - 休息中")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(context.state.exerciseName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(timeString(context.state.remainingSeconds))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("剩余")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
```

- [ ] **Step 3: 创建 FitTrackWidgetEntry.swift**

```swift
// fittrack_flutter/ios/RestLiveActivity/FitTrackWidgetEntry.swift
import WidgetKit
import SwiftUI

struct FitTrackWidgetEntry: TimelineEntry {
    let date: Date
    let mode: String          // idle / training / rest
    let exerciseName: String
    let currentSet: Int
    let totalSets: Int
    let exerciseIndex: Int
    let totalExercises: Int
    let completedSets: Int
    let totalPlanSets: Int
    let todayTrainings: Int
    let todayDuration: Int
    let todayWeight: Int
    let streak: Int
    let lastTraining: String
    let lastDate: String
    let trainingTime: String
    let accentColor: String
    let bgColor: String
    let textPrimaryColor: String
    let textSecondaryColor: String

    static let empty = FitTrackWidgetEntry(
        date: Date(),
        mode: "idle",
        exerciseName: "",
        currentSet: 0,
        totalSets: 0,
        exerciseIndex: 0,
        totalExercises: 0,
        completedSets: 0,
        totalPlanSets: 0,
        todayTrainings: 0,
        todayDuration: 0,
        todayWeight: 0,
        streak: 0,
        lastTraining: "",
        lastDate: "",
        trainingTime: "",
        accentColor: "#FF6B35",
        bgColor: "#FFFFFF",
        textPrimaryColor: "#222222",
        textSecondaryColor: "#999999"
    )

    static func fromDefaults() -> FitTrackWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
        guard let data = defaults?.string(forKey: "widgetData"),
              let json = data.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return .empty
        }

        func string(_ key: String) -> String { dict[key] as? String ?? "" }
        func int(_ key: String) -> Int { dict[key] as? Int ?? 0 }

        return FitTrackWidgetEntry(
            date: Date(),
            mode: string("mode"),
            exerciseName: string("exerciseName"),
            currentSet: int("currentSet"),
            totalSets: int("totalSets"),
            exerciseIndex: int("exerciseIndex"),
            totalExercises: int("totalExercises"),
            completedSets: int("completedSets"),
            totalPlanSets: int("totalPlanSets"),
            todayTrainings: int("todayTrainings"),
            todayDuration: int("todayDuration"),
            todayWeight: int("todayWeight"),
            streak: int("streak"),
            lastTraining: string("lastTraining"),
            lastDate: string("lastDate"),
            trainingTime: string("trainingTime"),
            accentColor: string("accentColor"),
            bgColor: string("bgColor"),
            textPrimaryColor: string("textPrimaryColor"),
            textSecondaryColor: string("textSecondaryColor")
        )
    }
}

func colorFromHex(_ hex: String) -> Color {
    let cleaned = hex.replacingOccurrences(of: "#", with: "")
    let scanner = Scanner(string: cleaned)
    var hexNumber: UInt64 = 0
    scanner.scanHexInt64(&hexNumber)
    let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
    let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
    let b = Double(hexNumber & 0x0000FF) / 255.0
    return Color(red: r, green: g, blue: b)
}
```

- [ ] **Step 4: 创建 FitTrackWidget.swift**

```swift
// fittrack_flutter/ios/RestLiveActivity/FitTrackWidget.swift
import WidgetKit
import SwiftUI

struct FitTrackWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FitTrackWidgetEntry {
        .empty
    }

    func getSnapshot(in context: Context, completion: @escaping (FitTrackWidgetEntry) -> Void) {
        completion(.fromDefaults())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FitTrackWidgetEntry>) -> Void) {
        let entry = FitTrackWidgetEntry.fromDefaults()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
        completion(timeline)
    }
}

struct FitTrackWidget: Widget {
    let kind: String = "FitTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FitTrackWidgetProvider()) { entry in
            FitTrackWidgetView(entry: entry)
        }
        .configurationDisplayName("FitTrack 训练卡片")
        .description("显示今日训练摘要和连续训练天数")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FitTrackWidgetView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        ZStack {
            colorFromHex(entry.bgColor)
            Group {
                if entry.mode == "idle" {
                    IdleView(entry: entry)
                } else if entry.mode == "training" {
                    TrainingView(entry: entry)
                } else if entry.mode == "rest" {
                    RestWidgetView(entry: entry)
                }
            }
            .padding(12)
        }
    }
}

struct IdleView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日训练")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.textSecondaryColor))
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(entry.todayTrainings)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorFromHex(entry.accentColor))
                Text("次")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
                Spacer()
                Text("\(entry.todayDuration)分钟")
                    .font(.subheadline)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
            }
            Divider()
            HStack {
                Text("连续 \(entry.streak) 天")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
                Spacer()
                if !entry.trainingTime.isEmpty {
                    Text("提醒 \(entry.trainingTime)")
                        .font(.caption2)
                        .foregroundColor(colorFromHex(entry.textSecondaryColor))
                }
            }
            if !entry.lastTraining.isEmpty {
                Text("最近：\(entry.lastTraining) \(entry.lastDate)")
                    .font(.caption2)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
            }
        }
    }
}

struct TrainingView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("训练中")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.accentColor))
            Text(entry.exerciseName)
                .font(.headline)
                .foregroundColor(colorFromHex(entry.textPrimaryColor))
                .lineLimit(1)
            HStack {
                Text("第 \(entry.currentSet)/\(entry.totalSets) 组")
                    .font(.subheadline)
                    .foregroundColor(colorFromHex(entry.textPrimaryColor))
                Spacer()
                Text("\(entry.exerciseIndex)/\(entry.totalExercises)")
                    .font(.caption)
                    .foregroundColor(colorFromHex(entry.textSecondaryColor))
            }
            ProgressView(value: Double(entry.completedSets), total: Double(max(entry.totalPlanSets, 1)))
                .tint(colorFromHex(entry.accentColor))
        }
    }
}

struct RestWidgetView: View {
    let entry: FitTrackWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("休息中")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.accentColor))
            Text(entry.exerciseName)
                .font(.subheadline)
                .foregroundColor(colorFromHex(entry.textPrimaryColor))
                .lineLimit(1)
            Text("第 \(entry.currentSet)/\(entry.totalSets) 组")
                .font(.caption)
                .foregroundColor(colorFromHex(entry.textSecondaryColor))
        }
    }
}
```

- [ ] **Step 5: 创建 RestLiveActivityBundle.swift**

```swift
// fittrack_flutter/ios/RestLiveActivity/RestLiveActivityBundle.swift
import WidgetKit
import SwiftUI

@main
struct RestLiveActivityBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        FitTrackWidget()
        if #available(iOS 16.1, *) {
            RestLiveActivity()
        }
    }
}
```

- [ ] **Step 6: 创建 Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>FitTrack Widget</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>RestLiveActivity</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
</dict>
</plist>
```

- [ ] **Step 7: 创建 RestLiveActivity.entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.fp.fitplan</string>
	</array>
</dict>
</plist>
```

- [ ] **Step 8: Commit**

```bash
cd fittrack_flutter
git add ios/RestLiveActivity/
git commit -m "feat: add iOS Widget Extension (Live Activities + Home Widget)"
```

---

### Task 3.2: 完善 AppDelegate LiveView 实现

**Files:**
- Modify: `fittrack_flutter/ios/Runner/AppDelegate.swift`

- [ ] **Step 1: 替换 setupLiveViewChannel 方法**

在 AppDelegate.swift 中添加 ActivityKit import（顶部）：

```swift
import ActivityKit
import WidgetKit
```

替换 `setupLiveViewChannel()` 方法：

```swift
  private func setupLiveViewChannel() {
    liveViewChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startRestLiveView":
        guard let args = call.arguments as? [String: Any],
              let exerciseName = args["exerciseName"] as? String,
              let restSeconds = args["restSeconds"] as? Int,
              let restEndTimeMs = args["restEndTimeMs"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }

        if #available(iOS 16.1, *) {
          self?.startRestLiveView(
            exerciseName: exerciseName,
            restSeconds: restSeconds,
            restEndTimeMs: restEndTimeMs,
            result: result
          )
        } else {
          // 低于 16.1 降级为普通通知
          result(FlutterError(code: "UNAVAILABLE", message: "Live Activities requires iOS 16.1+", details: nil))
        }
      case "stopRestLiveView":
        if #available(iOS 16.1, *) {
          for activity in Activity<RestLiveActivityAttributes>.activities {
            Task {
              await activity.end(dismissalPolicy: .immediate)
            }
          }
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.1, *)
  private func startRestLiveView(
    exerciseName: String,
    restSeconds: Int,
    restEndTimeMs: Int,
    result: @escaping FlutterResult
  ) {
    let attributes = RestLiveActivityAttributes(exerciseName: exerciseName)
    let restEndTime = Date(timeIntervalSince1970: TimeInterval(restEndTimeMs) / 1000.0)
    let state = RestLiveActivityAttributes.ContentState(
        exerciseName: exerciseName,
        remainingSeconds: restSeconds,
        totalRestSeconds: restSeconds,
        restEndTime: restEndTime
    )

    do {
      let activity = try Activity.request(
        attributes: attributes,
        content: .init(state: state, staleDate: restEndTime),
        pushType: nil
      )
      debugPrint("[LiveView] Activity started: \(activity.id)")
      result(true)
    } catch {
      debugPrint("[LiveView] Error starting activity: \(error)")
      result(FlutterError(code: "ACTIVITY_ERROR", message: error.localizedDescription, details: nil))
    }
  }
```

- [ ] **Step 2: 更新 setupWidgetChannel 支持 WidgetKit reload**

替换 `setupWidgetChannel()` 方法：

```swift
  private func setupWidgetChannel() {
    widgetChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "pushCardData":
        if let jsonData = call.arguments as? String {
          let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
          defaults?.set(jsonData, forKey: "widgetData")
          // 触发 WidgetKit 刷新
          WidgetCenter.shared.reloadTimelines(ofKind: "FitTrackWidget")
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
        }
      case "clearCardData":
        let defaults = UserDefaults(suiteName: "group.com.fp.fitplan")
        defaults?.removeObject(forKey: "widgetData")
        WidgetCenter.shared.reloadTimelines(ofKind: "FitTrackWidget")
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
```

- [ ] **Step 3: Commit**

```bash
git add ios/Runner/AppDelegate.swift
git commit -m "feat: implement iOS LiveView (ActivityKit) and Widget reload in AppDelegate"
```

---

### Task 3.3: 创建 iOS PAL LiveView 和 WidgetCard 实现

**Files:**
- Create: `fittrack_flutter/lib/services/platform/implementations/ios_live_view_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/ios_widget_card_service.dart`
- Modify: `fittrack_flutter/lib/services/platform/platform_services.dart`

- [ ] **Step 1: 创建 ios_live_view_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ios_live_view_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../live_view_service.dart';

/// iOS 实况窗服务（通过 ActivityKit 实现 Live Activities）
class IosLiveViewService implements LiveViewService {
  static const _channel = MethodChannel('com.fp.fitplan/liveview');

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    try {
      await _channel.invokeMethod<bool>('startRestLiveView', {
        'exerciseName': exerciseName,
        'restSeconds': restSeconds,
        'restEndTimeMs': restEndTime.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      // iOS 低于 16.1 会返回 UNAVAILABLE，降级为普通通知
      debugPrint('[IosLiveView] startRestLiveView failed: ${e.code} - ${e.message}');
    }
  }

  @override
  Future<void> stopRestLiveView() async {
    try {
      await _channel.invokeMethod<bool>('stopRestLiveView');
    } catch (e) {
      debugPrint('[IosLiveView] stopRestLiveView error: $e');
    }
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;
}
```

- [ ] **Step 2: 创建 ios_widget_card_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/ios_widget_card_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widget_card_service.dart';

/// iOS 桌面卡片服务（通过 WidgetKit + App Group UserDefaults）
class IosWidgetCardService implements WidgetCardService {
  static const _channel = MethodChannel('com.fp.fitplan/widget');

  final StreamController<WidgetCardClickEvent> _clickController =
      StreamController<WidgetCardClickEvent>.broadcast();

  @override
  Future<void> init() async {
    // 首次启动时推送一次空闲态数据
    await pushCardData(WidgetCardData(mode: WidgetCardMode.idle));
  }

  @override
  Future<void> pushCardData(WidgetCardData data) async {
    try {
      final jsonStr = jsonEncode(data.toJson());
      await _channel.invokeMethod<bool>('pushCardData', jsonStr);
    } catch (e) {
      debugPrint('[IosWidgetCard] pushCardData error: $e');
    }
  }

  @override
  Future<void> clearCardData() async {
    try {
      await _channel.invokeMethod<bool>('clearCardData');
    } catch (e) {
      debugPrint('[IosWidgetCard] clearCardData error: $e');
    }
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;
}
```

- [ ] **Step 3: 更新 platform_services.dart**

修改 `fittrack_flutter/lib/services/platform/platform_services.dart` 第 38-43 行：

```dart
    } else if (Platform.isIOS) {
      restReminder = IosRestReminderService();
      liveView = IosLiveViewService();
      widgetCard = IosWidgetCardService();
      inviteUrl = IosInviteUrlService();
    } else {
```

添加 imports：
```dart
import 'implementations/ios_live_view_service.dart';
import 'implementations/ios_widget_card_service.dart';
```

- [ ] **Step 4: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/services/platform/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/services/platform/implementations/ios_live_view_service.dart lib/services/platform/implementations/ios_widget_card_service.dart lib/services/platform/platform_services.dart
git commit -m "feat: add iOS PAL LiveView and WidgetCard implementations"
```

---

### Task 3.4: 升级 Android Kotlin 版本并添加 Glance 依赖

**Files:**
- Modify: `fittrack_flutter/android/build.gradle`
- Modify: `fittrack_flutter/android/app/build.gradle`

- [ ] **Step 1: 修改 android/build.gradle Kotlin 版本**

查找 `ext.kotlin_version` 行，将版本从 `1.7.x` 改为 `1.9.10`：

```gradle
ext.kotlin_version = '1.9.10'
```

- [ ] **Step 2: 修改 android/app/build.gradle 添加 Glance 依赖**

在第 83-86 行 `dependencies` 块添加：

```gradle
dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation "androidx.core:core-ktx:1.12.0"
    implementation "androidx.glance:glance-appwidget:1.0.0"
    implementation "androidx.glance:glance-material:1.0.0"
    implementation "androidx.datastore:datastore-preferences:1.0.0"
}
```

- [ ] **Step 3: 验证 Android 构建通过**

```bash
cd fittrack_flutter
flutter build apk --debug --target-platform android-x64
```

Expected: BUILD SUCCESSFUL（Gradle 自动下载新依赖）

- [ ] **Step 4: Commit**

```bash
git add android/build.gradle android/app/build.gradle
git commit -m "build: upgrade Kotlin to 1.9.10 and add Jetpack Glance dependencies"
```

---

### Task 3.5: 创建 Android Glance AppWidget

**Files:**
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackWidgetState.kt`
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/WidgetDataStore.kt`
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidget.kt`
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidgetReceiver.kt`
- Create: `fittrack_flutter/android/app/src/main/res/xml/fittrack_widget_info.xml`

- [ ] **Step 1: 创建 FitTrackWidgetState.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackWidgetState.kt
package com.fp.fitplan.widget

import org.json.JSONObject

/// 桌面卡片状态
data class FitTrackWidgetState(
    val mode: String = "idle",  // idle / training / rest
    val exerciseName: String = "",
    val currentSet: Int = 0,
    val totalSets: Int = 0,
    val exerciseIndex: Int = 0,
    val totalExercises: Int = 0,
    val completedSets: Int = 0,
    val totalPlanSets: Int = 0,
    val todayTrainings: Int = 0,
    val todayDuration: Int = 0,
    val todayWeight: Int = 0,
    val streak: Int = 0,
    val lastTraining: String = "",
    val lastDate: String = "",
    val trainingTime: String = "",
    val accentColor: String = "#FF6B35",
    val bgColor: String = "#FFFFFF",
    val textPrimaryColor: String = "#222222",
    val textSecondaryColor: String = "#999999"
) {
    companion object {
        fun fromJson(jsonStr: String): FitTrackWidgetState {
            return try {
                val json = JSONObject(jsonStr)
                FitTrackWidgetState(
                    mode = json.optString("mode", "idle"),
                    exerciseName = json.optString("exerciseName", ""),
                    currentSet = json.optInt("currentSet", 0),
                    totalSets = json.optInt("totalSets", 0),
                    exerciseIndex = json.optInt("exerciseIndex", 0),
                    totalExercises = json.optInt("totalExercises", 0),
                    completedSets = json.optInt("completedSets", 0),
                    totalPlanSets = json.optInt("totalPlanSets", 0),
                    todayTrainings = json.optInt("todayTrainings", 0),
                    todayDuration = json.optInt("todayDuration", 0),
                    todayWeight = json.optInt("todayWeight", 0),
                    streak = json.optInt("streak", 0),
                    lastTraining = json.optString("lastTraining", ""),
                    lastDate = json.optString("lastDate", ""),
                    trainingTime = json.optString("trainingTime", ""),
                    accentColor = json.optString("accentColor", "#FF6B35"),
                    bgColor = json.optString("bgColor", "#FFFFFF"),
                    textPrimaryColor = json.optString("textPrimaryColor", "#222222"),
                    textSecondaryColor = json.optString("textSecondaryColor", "#999999")
                )
            } catch (e: Exception) {
                FitTrackWidgetState()
            }
        }
    }
}
```

- [ ] **Step 2: 创建 WidgetDataStore.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/WidgetDataStore.kt
package com.fp.fitplan.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager

/// 卡片数据存储（SharedPreferences）
object WidgetDataStore {
    private const val PREFS_NAME = "fittrack_widget_prefs"
    private const val KEY_WIDGET_DATA = "widget_data"

    fun saveState(context: Context, jsonStr: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_WIDGET_DATA, jsonStr).apply()
        // 触发 Glance 卡片刷新
        GlanceAppWidgetManager(context).getGlanceIds(FitTrackGlanceWidgetReceiver::class.java).forEach { id ->
            FitTrackGlanceWidget().update(context, id)
        }
    }

    fun getState(context: Context): FitTrackWidgetState {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonStr = prefs.getString(KEY_WIDGET_DATA, "") ?: ""
        return if (jsonStr.isEmpty()) FitTrackWidgetState() else FitTrackWidgetState.fromJson(jsonStr)
    }

    fun clearState(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(KEY_WIDGET_DATA).apply()
        GlanceAppWidgetManager(context).getGlanceIds(FitTrackGlanceWidgetReceiver::class.java).forEach { id ->
            FitTrackGlanceWidget().update(context, id)
        }
    }
}
```

- [ ] **Step 3: 创建 FitTrackGlanceWidget.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidget.kt
package com.fp.fitplan.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.fp.fitplan.MainActivity

class FitTrackGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = WidgetDataStore.getState(context)
        provideContent {
            WidgetContent(state)
        }
    }
}

@Composable
fun WidgetContent(state: FitTrackWidgetState) {
    val accentColor = parseColor(state.accentColor)
    val bgColor = parseColor(state.bgColor)
    val textPrimary = parseColor(state.textPrimaryColor)
    val textSecondary = parseColor(state.textSecondaryColor)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(bgColor))
            .padding(12.dp)
            .clickable(actionStartActivity<MainActivity>())
    ) {
        when (state.mode) {
            "idle" -> IdleView(state, accentColor, textPrimary, textSecondary)
            "training" -> TrainingView(state, accentColor, textPrimary, textSecondary)
            "rest" -> RestView(state, accentColor, textPrimary, textSecondary)
        }
    }
}

@Composable
fun IdleView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.Top,
        horizontalAlignment = HorizontalAlignment.Start
    ) {
        Text(
            text = "今日训练",
            style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
        )
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom
        ) {
            Text(
                text = "${state.todayTrainings}",
                style = TextStyle(
                    color = ColorProvider(accentColor),
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            Spacer(modifier = GlanceModifier.width(4.dp))
            Text(
                text = "次",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = "${state.todayDuration}分钟",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
            )
        }
        Spacer(modifier = GlanceModifier.height(8.dp))
        Row(
            modifier = GlanceModifier.fillMaxWidth()
        ) {
            Text(
                text = "连续 ${state.streak} 天",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 12.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            if (state.trainingTime.isNotEmpty()) {
                Text(
                    text = "提醒 ${state.trainingTime}",
                    style = TextStyle(color = ColorProvider(textSecondary), fontSize = 10.sp)
                )
            }
        }
        if (state.lastTraining.isNotEmpty()) {
            Spacer(modifier = GlanceModifier.height(4.dp))
            Text(
                text = "最近：${state.lastTraining} ${state.lastDate}",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 10.sp)
            )
        }
    }
}

@Composable
fun TrainingView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.Top
    ) {
        Text(
            text = "训练中",
            style = TextStyle(color = ColorProvider(accentColor), fontSize = 12.sp)
        )
        Text(
            text = state.exerciseName,
            style = TextStyle(
                color = ColorProvider(textPrimary),
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
        )
        Row(
            modifier = GlanceModifier.fillMaxWidth()
        ) {
            Text(
                text = "第 ${state.currentSet}/${state.totalSets} 组",
                style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                text = "${state.exerciseIndex}/${state.totalExercises}",
                style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
            )
        }
    }
}

@Composable
fun RestView(
    state: FitTrackWidgetState,
    accentColor: Color,
    textPrimary: Color,
    textSecondary: Color
) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        verticalAlignment = Alignment.Center,
        horizontalAlignment = HorizontalAlignment.CenterHorizontally
    ) {
        Text(
            text = "休息中",
            style = TextStyle(color = ColorProvider(accentColor), fontSize = 12.sp)
        )
        Text(
            text = state.exerciseName,
            style = TextStyle(color = ColorProvider(textPrimary), fontSize = 14.sp)
        )
        Text(
            text = "第 ${state.currentSet}/${state.totalSets} 组",
            style = TextStyle(color = ColorProvider(textSecondary), fontSize = 12.sp)
        )
    }
}

fun parseColor(hex: String): Color {
    val cleaned = hex.removePrefix("#")
    return try {
        val color = cleaned.toLong(16)
        Color(
            red = ((color shr 16) and 0xFF) / 255f,
            green = ((color shr 8) and 0xFF) / 255f,
            blue = (color and 0xFF) / 255f
        )
    } catch (e: Exception) {
        Color(0xFFFF6B35)
    }
}
```

- [ ] **Step 4: 创建 FitTrackGlanceWidgetReceiver.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/widget/FitTrackGlanceWidgetReceiver.kt
package com.fp.fitplan.widget

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

class FitTrackGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = FitTrackGlanceWidget()
}
```

- [ ] **Step 5: 创建 fittrack_widget_info.xml**

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/widget_rest_notification"
    android:minWidth="180dp"
    android:minHeight="180dp"
    android:minResizeWidth="180dp"
    android:minResizeHeight="180dp"
    android:resizeMode="horizontal|vertical"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:widgetCategory="home_screen"
    android:description="@string/widget_description" />
```

注意：需要在 `android/app/src/main/res/values/strings.xml` 添加 `widget_description` 字符串。如果没有 strings.xml，创建一个。

- [ ] **Step 6: 创建/修改 strings.xml**

检查 `fittrack_flutter/android/app/src/main/res/values/strings.xml` 是否存在，如果不存在则创建：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="widget_description">显示今日训练摘要和连续训练天数</string>
</resources>
```

- [ ] **Step 7: Commit**

```bash
cd fittrack_flutter
git add android/app/src/main/kotlin/com/fp/fitplan/widget/ android/app/src/main/res/xml/fittrack_widget_info.xml android/app/src/main/res/values/strings.xml
git commit -m "feat: add Android Glance AppWidget (three-state: idle/training/rest)"
```

---

### Task 3.6: 创建 Android 前台服务（RestOngoingService）

**Files:**
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestNotificationBuilder.kt`
- Create: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestOngoingService.kt`
- Create: `fittrack_flutter/android/app/src/main/res/layout/widget_rest_notification.xml`

- [ ] **Step 1: 创建 RestNotificationBuilder.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestNotificationBuilder.kt
package com.fp.fitplan.rest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.fp.fitplan.MainActivity
import com.fp.fitplan.R

object RestNotificationBuilder {
    private const val CHANNEL_ID = "rest_countdown"
    private const val CHANNEL_NAME = "休息倒计时"
    private const val NOTIFICATION_ID = 2001

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW  // 不发声，只显示
            ).apply {
                description = "组间休息倒计时实况通知"
                setShowBadge(false)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun buildRestNotification(
        context: Context,
        exerciseName: String,
        restEndTimeMs: Long
    ): Notification {
        // 点击跳转回训练页
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            putExtra("targetPage", "training")
            putExtra("cardAction", "resume")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // "结束休息"操作
        val skipIntent = Intent(context, RestOngoingService::class.java).apply {
            action = RestOngoingService.ACTION_SKIP_REST
        }
        val skipPendingIntent = PendingIntent.getService(
            context, 1, skipIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 使用 RemoteViews + Chronometer 实现倒计时
        val remoteViews = RemoteViews(context.packageName, R.layout.widget_rest_notification)
        remoteViews.setTextViewText(R.id.rest_exercise_name, exerciseName)

        // 设置 Chronometer 倒计时
        val elapsedRealtime = android.os.SystemClock.elapsedRealtime()
        val restEndElapsed = elapsedRealtime + (restEndTimeMs - System.currentTimeMillis())
        remoteViews.setChronometer(R.id.rest_chronometer, restEndElapsed, null, true)

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(remoteViews)
            .setOngoing(true)
            .setContentIntent(contentPendingIntent)
            .addAction(R.mipmap.ic_launcher, "结束休息", skipPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .build()
    }

    const val NOTIFICATION_ID = 2001
}
```

- [ ] **Step 2: 创建 RestOngoingService.kt**

```kotlin
// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestOngoingService.kt
package com.fp.fitplan.rest

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationManagerCompat

class RestOngoingService : Service() {

    companion object {
        const val ACTION_START_REST = "com.fp.fitplan.action.START_REST"
        const val ACTION_STOP_REST = "com.fp.fitplan.action.STOP_REST"
        const val ACTION_SKIP_REST = "com.fp.fitplan.action.SKIP_REST"

        const val EXTRA_EXERCISE_NAME = "exercise_name"
        const val EXTRA_REST_END_TIME = "rest_end_time"

        // 静态状态，供 MethodChannel 访问
        @Volatile
        var isRunning = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        RestNotificationBuilder.createChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_REST -> {
                val exerciseName = intent.getStringExtra(EXTRA_EXERCISE_NAME) ?: ""
                val restEndTimeMs = intent.getLongExtra(EXTRA_REST_END_TIME, 0L)

                val notification = RestNotificationBuilder.buildRestNotification(
                    this, exerciseName, restEndTimeMs
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        RestNotificationBuilder.NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(RestNotificationBuilder.NOTIFICATION_ID, notification)
                }
                isRunning = true
            }
            ACTION_STOP_REST -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                NotificationManagerCompat.from(this)
                    .cancel(RestNotificationBuilder.NOTIFICATION_ID)
                isRunning = false
                stopSelf()
            }
            ACTION_SKIP_REST -> {
                // 通过 broadcast 通知 Flutter 侧 skipRest
                // MainActivity 的 alarm channel 会接收到 onCardClick
                val skipIntent = Intent("com.fp.fitplan.REST_ALARM").apply {
                    putExtra("targetPage", "training")
                    putExtra("cardAction", "skipRest")
                    setPackage(packageName)
                }
                sendBroadcast(skipIntent)
                stopForeground(STOP_FOREGROUND_REMOVE)
                NotificationManagerCompat.from(this)
                    .cancel(RestNotificationBuilder.NOTIFICATION_ID)
                isRunning = false
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

- [ ] **Step 3: 创建 widget_rest_notification.xml**

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    android:padding="12dp">

    <TextView
        android:id="@+id/rest_exercise_name"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="14sp"
        android:textStyle="bold"
        android:textColor="#222222"
        android:text="训练中" />

    <Chronometer
        android:id="@+id/rest_chronometer"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="24sp"
        android:textColor="#FF6B35"
        android:countDown="true"
        android:format="MM:SS" />

</LinearLayout>
```

- [ ] **Step 4: Commit**

```bash
cd fittrack_flutter
git add android/app/src/main/kotlin/com/fp/fitplan/rest/ android/app/src/main/res/layout/widget_rest_notification.xml
git commit -m "feat: add Android RestOngoingService with Chronometer countdown notification"
```

---

### Task 3.7: 更新 AndroidManifest.xml 和 MainActivity.kt

**Files:**
- Modify: `fittrack_flutter/android/app/src/main/AndroidManifest.xml`
- Modify: `fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/MainActivity.kt`

- [ ] **Step 1: 修改 AndroidManifest.xml**

在 `<application>` 块内（`<receiver android:name=".AlarmReceiver"...>` 之后）添加：

```xml
        <!-- AppWidget Receiver（Glance） -->
        <receiver
            android:name=".widget.FitTrackGlanceWidgetReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/fittrack_widget_info"/>
        </receiver>

        <!-- 前台服务（休息倒计时实况通知） -->
        <service
            android:name=".rest.RestOngoingService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="rest_countdown"/>
        </service>
```

在权限声明区（第 15 行 `FOREGROUND_SERVICE` 之后）添加：

```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
```

- [ ] **Step 2: 修改 MainActivity.kt 添加 liveview 和 widget channel**

在 `MainActivity.kt` 的 `configureFlutterEngine` 方法中，`romAdaptationChannel` 之后添加：

```kotlin
        // LiveView Channel（休息倒计时前台服务）
        val liveViewChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fp.fitplan/liveview"
        )
        liveViewChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRestLiveView" -> {
                    val exerciseName = call.argument<String>("exerciseName") ?: ""
                    val restEndTimeMs = call.argument<Int>("restEndTimeMs")?.toLong() ?: 0L
                    val intent = Intent(this@MainActivity, RestOngoingService::class.java).apply {
                        action = RestOngoingService.ACTION_START_REST
                        putExtra(RestOngoingService.EXTRA_EXERCISE_NAME, exerciseName)
                        putExtra(RestOngoingService.EXTRA_REST_END_TIME, restEndTimeMs)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result(true)
                }
                "stopRestLiveView" -> {
                    val intent = Intent(this@MainActivity, RestOngoingService::class.java).apply {
                        action = RestOngoingService.ACTION_STOP_REST
                    }
                    startService(intent)
                    result(true)
                }
                else -> result.notImplemented()
            }
        }

        // Widget Channel（桌面卡片数据推送）
        val widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fp.fitplan/widget"
        )
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pushCardData" -> {
                    val jsonStr = call.argument<String>("jsonData") ?: call.arguments as? String
                    if (jsonStr != null) {
                        com.fp.fitplan.widget.WidgetDataStore.saveState(this@MainActivity, jsonStr)
                        result(true)
                    } else {
                        result.error("INVALID_ARGS", "Expected JSON string", null)
                    }
                }
                "clearCardData" -> {
                    com.fp.fitplan.widget.WidgetDataStore.clearState(this@MainActivity)
                    result(true)
                }
                else -> result.notImplemented()
            }
        }
```

注意：`pushCardData` 的 arguments 处理需要兼容两种情况（直接字符串或 Map）。修正为：

```kotlin
                "pushCardData" -> {
                    val jsonStr = when (val args = call.arguments) {
                        is String -> args
                        is Map<*, *> -> args["jsonData"] as? String
                        else -> null
                    }
                    if (jsonStr != null) {
                        com.fp.fitplan.widget.WidgetDataStore.saveState(this@MainActivity, jsonStr)
                        result(true)
                    } else {
                        result.error("INVALID_ARGS", "Expected JSON string", null)
                    }
                }
```

需要添加 imports：

```kotlin
import android.content.Intent
import android.os.Build
import com.fp.fitplan.rest.RestOngoingService
```

- [ ] **Step 3: 扩展 handleNotificationIntent 处理 fittrack:// URL**

修改 `handleNotificationIntent` 方法，添加 URL scheme 解析：

```kotlin
    private fun handleNotificationIntent(intent: Intent?) {
        intent ?: return

        // 处理 fittrack://invite URL
        val data = intent.data
        if (data != null && data.scheme == "fittrack" && data.host == "invite") {
            val inviteChannel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger!!,
                "com.fp.fitplan/invite"
            )
            inviteChannel.invokeMethod("onInviteUrl", data.toString())
        }

        // 处理通知点击（targetPage / cardAction）
        val targetPage = intent.getStringExtra("targetPage")
        val cardAction = intent.getStringExtra("cardAction")

        if (targetPage != null || cardAction != null) {
            val params = HashMap<String, Any>()
            targetPage?.let { params["targetPage"] = it }
            cardAction?.let { params["cardAction"] = it }

            alarmChannel?.invokeMethod("onCardClick", params)
        }
    }
```

- [ ] **Step 4: 验证 Android 构建通过**

```bash
cd fittrack_flutter
flutter build apk --debug --target-platform android-x64
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/com/fp/fitplan/MainActivity.kt
git commit -m "feat: add Android widget receiver, foreground service, and URL scheme handling"
```

---

### Task 3.8: 创建 Android PAL LiveView 和 WidgetCard 实现

**Files:**
- Create: `fittrack_flutter/lib/services/platform/implementations/android_live_view_service.dart`
- Create: `fittrack_flutter/lib/services/platform/implementations/android_widget_card_service.dart`
- Modify: `fittrack_flutter/lib/services/platform/platform_services.dart`

- [ ] **Step 1: 创建 android_live_view_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/android_live_view_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../live_view_service.dart';

/// Android 实况窗服务（前台服务通知 + Chronometer）
class AndroidLiveViewService implements LiveViewService {
  static const _channel = MethodChannel('com.fp.fitplan/liveview');

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    try {
      await _channel.invokeMethod<bool>('startRestLiveView', {
        'exerciseName': exerciseName,
        'restSeconds': restSeconds,
        'restEndTimeMs': restEndTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[AndroidLiveView] startRestLiveView error: $e');
    }
  }

  @override
  Future<void> stopRestLiveView() async {
    try {
      await _channel.invokeMethod<bool>('stopRestLiveView');
    } catch (e) {
      debugPrint('[AndroidLiveView] stopRestLiveView error: $e');
    }
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;
}
```

- [ ] **Step 2: 创建 android_widget_card_service.dart**

```dart
// fittrack_flutter/lib/services/platform/implementations/android_widget_card_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../widget_card_service.dart';

/// Android 桌面卡片服务（Glance AppWidget）
class AndroidWidgetCardService implements WidgetCardService {
  static const _channel = MethodChannel('com.fp.fitplan/widget');

  final StreamController<WidgetCardClickEvent> _clickController =
      StreamController<WidgetCardClickEvent>.broadcast();

  @override
  Future<void> init() async {
    // 首次启动时推送一次空闲态数据
    await pushCardData(WidgetCardData(mode: WidgetCardMode.idle));
  }

  @override
  Future<void> pushCardData(WidgetCardData data) async {
    try {
      final jsonStr = jsonEncode(data.toJson());
      await _channel.invokeMethod<bool>('pushCardData', jsonStr);
    } catch (e) {
      debugPrint('[AndroidWidgetCard] pushCardData error: $e');
    }
  }

  @override
  Future<void> clearCardData() async {
    try {
      await _channel.invokeMethod<bool>('clearCardData');
    } catch (e) {
      debugPrint('[AndroidWidgetCard] clearCardData error: $e');
    }
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;
}
```

- [ ] **Step 3: 更新 platform_services.dart**

修改第 33-37 行 Android 分支：

```dart
    } else if (Platform.isAndroid) {
      restReminder = AndroidRestReminderService();
      liveView = AndroidLiveViewService();
      widgetCard = AndroidWidgetCardService();
      inviteUrl = AndroidInviteUrlService();
    } else if (Platform.isIOS) {
```

添加 imports：
```dart
import 'implementations/android_live_view_service.dart';
import 'implementations/android_widget_card_service.dart';
```

- [ ] **Step 4: 验证编译通过**

```bash
cd fittrack_flutter
flutter analyze lib/services/platform/
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/services/platform/implementations/android_live_view_service.dart lib/services/platform/implementations/android_widget_card_service.dart lib/services/platform/platform_services.dart
git commit -m "feat: add Android PAL LiveView and WidgetCard implementations"
```

---

### Task 3.9: 修复 MainActivity pushCardData 参数传递

**Files:**
- Modify: `fittrack_flutter/lib/services/platform/implementations/android_widget_card_service.dart`

Flutter 侧 `invokeMethod` 第二个参数就是 arguments，Android 侧 `call.arguments` 直接就是 JSON 字符串。但当前 Dart 代码中调用方式为 `invokeMethod<bool>('pushCardData', jsonStr)`，Android 侧需要用 `call.arguments` 直接获取。

- [ ] **Step 1: 验证 Android WidgetChannel 接收参数方式**

修改 `MainActivity.kt` 中 `pushCardData` 处理：

```kotlin
                "pushCardData" -> {
                    val jsonStr = call.arguments as? String
                    if (jsonStr != null) {
                        com.fp.fitplan.widget.WidgetDataStore.saveState(this@MainActivity, jsonStr)
                        result(true)
                    } else {
                        result.error("INVALID_ARGS", "Expected JSON string", null)
                    }
                }
```

- [ ] **Step 2: Commit**

```bash
git add android/app/src/main/kotlin/com/fp/fitplan/MainActivity.kt
git commit -m "fix: Android WidgetChannel receives JSON string directly as arguments"
```

---

### Task 3.10: Batch 3 Android 端到端验证

- [ ] **Step 1: Android 构建验证**

```bash
cd fittrack_flutter
flutter build apk --debug --target-platform android-x64
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 2: 运行 Android 模拟器端到端**

```bash
cd fittrack_flutter
flutter run -d emulator-5558
```

验证：
1. 应用启动正常
2. 长按桌面添加 "FitTrack" Widget，显示空闲态
3. 进入训练页，完成一组，桌面卡片切换到休息态
4. 通知栏出现休息倒计时 Chronometer
5. 点击"结束休息"按钮，跳过休息
6. 退出训练页，卡片恢复空闲态

- [ ] **Step 3: 验证邀请链接**

```bash
adb shell am start -W -a android.intent.action.VIEW -d "fittrack://invite?code=TEST123" com.fp.fitplan
```

Expected: 应用打开，控制台输出 `[Invite] Received URL: fittrack://invite?code=TEST123`

- [ ] **Step 4: Commit Batch 3 完成标记**

```bash
git commit --allow-empty -m "chore: Batch 3 complete - iOS Live Activities + Android Glance AppWidget + foreground service"
```

---

## Batch 4：Codemagic + 收尾

### Task 4.1: 创建 codemagic.yaml

**Files:**
- Create: `d:\app\projects\health_training\codemagic.yaml`

- [ ] **Step 1: 创建 codemagic.yaml**

```yaml
workflows:
  ios-workflow:
    name: iOS Build
    instance_type: mac_mini_m2
    max_build_duration: 60
    environment:
      ios_signing:
        distribution_type: development
        bundle_identifier: com.fp.fitplan
      vars:
        XCODE_WORKSPACE: Runner.xcworkspace
        XCODE_SCHEME: Runner
      flutter: 3.7.12
    scripts:
      - name: Install dependencies
        script: |
          cd fittrack_flutter
          flutter pub get
      - name: Set up code signing
        script: |
          keychain initialize
          app-store-connect fetch-signing-files $(xcode-project detect-bundle-id --project "$CM_BUILD_DIR/ios/Runner.xcodeproj") --type IOS_APP_DEVELOPMENT --create
          keychain add-certificates
          xcode-project use-profiles
      - name: Build iOS
        script: |
          cd fittrack_flutter
          flutter build ipa --release --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - fittrack_flutter/build/ios/ipa/*.ipa
      - fittrack_flutter/build/ios/ipa/*.dSYM.zip

  android-workflow:
    name: Android Build
    instance_type: linux_x2
    max_build_duration: 30
    environment:
      flutter: 3.7.12
      vars:
        PACKAGE_NAME: com.fp.fitplan
    scripts:
      - name: Install dependencies
        script: |
          cd fittrack_flutter
          flutter pub get
      - name: Build Android APK
        script: |
          cd fittrack_flutter
          flutter build apk --release
    artifacts:
      - fittrack_flutter/build/app/outputs/flutter-apk/*.apk
```

- [ ] **Step 2: Commit**

```bash
cd d:\app\projects\health_training
git add codemagic.yaml
git commit -m "ci: add Codemagic cloud build configuration for iOS and Android"
```

---

### Task 4.2: 最终静态分析验证

- [ ] **Step 1: Flutter 静态分析**

```bash
cd fittrack_flutter
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: 运行所有测试**

```bash
cd fittrack_flutter
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Android 构建验证**

```bash
cd fittrack_flutter
flutter build apk --release
```

Expected: BUILD SUCCESSFUL

- [ ] **Step 4: 最终提交**

```bash
git commit --allow-empty -m "chore: Batch 4 complete - Codemagic CI + full platform adaptation done"
```

---

## Self-Review Notes

### Spec Coverage Check

| Spec 章节 | 对应 Task |
|-----------|----------|
| 1. 目标与范围 | 所有 Batch |
| 2. 整体架构 (PAL) | Task 1.1-1.4 |
| 3. PAL 接口详细设计 | Task 1.1 |
| 4.1 Info.plist 补全 | Task 2.1 |
| 4.2 AppDelegate 增强 | Task 2.3, 3.2 |
| 4.3 Widget Extension | Task 3.1 |
| 4.4 Runner.entitlements | Task 2.2 |
| 5.1 AndroidManifest 补全 | Task 3.7 |
| 5.2 Glance AppWidget | Task 3.5 |
| 5.3 RestOngoingService | Task 3.6 |
| 5.4 build.gradle 依赖 | Task 3.4 |
| 6. Codemagic | Task 4.1 |
| 7. 风险与注意事项 | Global Constraints |

### Placeholder Scan

✅ 无 TBD/TODO，所有代码完整。
✅ 所有文件路径精确到绝对路径或相对项目根的路径。
✅ 所有命令含 expected output。

### Type Consistency

✅ `WidgetCardData` 字段名在 Dart/iOS/Android 三端一致（mode/exerciseName/currentSet 等）。
✅ `RestReminderEvent.fromMap` 与 `WidgetCardClickEvent.fromMap` 签名一致。
✅ MethodChannel 名称三端统一：`com.fp.fitplan/{reminder, liveview, widget, invite}`。
