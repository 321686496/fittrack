# Android 与 iOS 平台适配设计文档

**日期**: 2026-07-28
**状态**: 已批准
**作者**: AI Assistant + User Review
**关联**: 基于 2026-07-28 三平台适配差异分析

## 1. 目标与范围

### 1.1 目标

让 Android 与 iOS 在功能上完全对齐 HarmonyOS 已实现的能力，三平台支持矩阵如下：

| 功能 | Android | iOS | HarmonyOS |
|------|---------|-----|-----------|
| 桌面卡片 | ✅ AppWidget (Glance) | ✅ WidgetKit | ✅ Form Kit（已实现） |
| 实况窗 | ✅ Rich Ongoing Notification | ✅ Live Activities (ActivityKit, iOS 16.1+) | ✅ Live View Kit（已实现） |
| 后台提醒 | ✅ AlarmManager（已实现） | ✅ UNUserNotificationCenter zonedSchedule | ✅ reminderAgentManager（已实施） |
| URL scheme 邀请 | ✅（已实现） | ✅ CFBundleURLTypes + AppDelegate | ❌（OHOS 不需要） |
| 海报保存/分享 | ✅（已实现） | ✅（已实现，补 Info.plist 权限） | ✅（已实现） |

### 1.2 范围决策

- **P0**：修复 iOS 必闪退项（Info.plist 权限说明、URL scheme 缺失）
- **P1**：补齐 iOS 后台通知、邀请链接、海报保存分享能力
- **P2**：完全对齐 HarmonyOS — Android 桌面卡片（AppWidget）、Android 实况窗（前台服务通知）、iOS Live Activities、iOS Home Screen Widget

### 1.3 不在本期范围

- iOS 推送通知（APNs）：仅本地通知
- Android 远程推送（FCM）：仅本地通知
- iOS 苹果登录（Sign in with Apple）
- 三平台深度链接（Universal Links / App Links）：仅 URL scheme
- HarmonyOS 改动：保留现状，仅通过 PAL 包装

### 1.4 关键决策

| 决策点 | 选择 | 原因 |
|--------|------|------|
| iOS 最低版本 | iOS 16.1+ | Live Activities / 灵动岛所需最低版本（覆盖现网 95%+） |
| Android 实况窗方案 | 前台服务通知 + Chronometer | Android 12+ 原生支持 Rich Ongoing Notifications |
| Android 桌面卡片技术 | Jetpack Glance | Google 2024 推荐，Compose 语法 |
| iOS 卡片范围 | Live Activities + Home Widget 同时实现 | 完全对齐 HarmonyOS Form Kit + Live View Kit |
| iOS 云构建 | Codemagic | Windows 环境无法构建 iOS |

## 2. 整体架构

### 2.1 平台抽象层（PAL）

新增 `lib/services/platform/` 目录，统一三平台接口。业务代码只依赖接口，不再直接 import `OhosReminderService` / `AndroidAlarmService` 等具体类。

```
lib/services/platform/
├── rest_reminder_service.dart       # 抽象接口
├── live_view_service.dart           # 抽象接口
├── widget_card_service.dart         # 抽象接口
├── invite_url_service.dart          # 抽象接口
├── platform_services.dart           # 单例容器（注入入口）
└── implementations/
    ├── ohos_rest_reminder_service.dart       # 包装现有 OhosReminderService
    ├── ohos_live_view_service.dart           # 包装现有 EntryAbility 调用
    ├── ohos_widget_card_service.dart         # 包装现有 FormKitService
    ├── android_rest_reminder_service.dart    # 包装现有 AndroidAlarmService
    ├── android_live_view_service.dart        # 新增：前台服务通知 + Chronometer
    ├── android_widget_card_service.dart      # 新增：Glance AppWidget
    ├── android_invite_url_service.dart       # 新增：解析 fittrack://
    ├── ios_rest_reminder_service.dart        # 新增：zonedSchedule 包装
    ├── ios_live_view_service.dart            # 新增：ActivityKit 包装
    ├── ios_widget_card_service.dart          # 新增：WidgetKit + AppGroup UserDefaults
    └── ios_invite_url_service.dart           # 新增：URL scheme 解析
```

### 2.2 注入机制

`main.dart` 在 `main()` 中根据平台注入：

```dart
final RestReminderService restReminderService = isOhos
    ? OhosRestReminderService()
    : Platform.isAndroid
        ? AndroidRestReminderService()
        : IosRestReminderService();
// 类似地注入 LiveViewService / WidgetCardService / InviteUrlService
```

业务代码改为：

```dart
// 改造前（training_page.dart 第 358-372 行）
if (isOhos && _currentExIdx < _exercises.length) {
  FormKitService.instance.startRest(...);
}

// 改造后
if (_currentExIdx < _exercises.length) {
  PlatformServices.liveView.startRestLiveView(...);
  PlatformServices.widgetCard.pushCardData(...);
}
```

### 2.3 现有服务包装策略

**不重写、只包装**：现有 `OhosReminderService` / `AndroidAlarmService` / `FormKitService` 的内部实现完全保留，新增 `XxxRestReminderService` / `XxxWidgetCardService` 作为薄包装类，方法签名转调原有 API。

- 风险可控：HarmonyOS 既有逻辑零改动
- Android 既有 AlarmManager 逻辑保留
- iOS 新增实现，但接口与 Android/OHOS 一致

### 2.4 三平台原生新增/修改清单

**iOS 新增：**
- `ios/Runner/Info.plist` — 补权限说明 + URL scheme + NSSupportsLiveActivities
- `ios/Runner/AppDelegate.swift` — 注册 4 个 MethodChannel（reminder/liveview/widget/invite）
- 新增 Widget Extension target `ios/RestLiveActivity/`：
  - `RestLiveActivity.swift`（ActivityKit 配置）
  - `RestLiveActivityAttributes.swift`（数据模型）
  - `FitTrackWidget.swift`（Home Screen Widget，三态）
  - `FitTrackWidgetEntry.swift`（TimelineEntry + 数据读取）
  - `RestLiveActivityBundle.swift`（Widget Bundle）
  - `Info.plist`
- `ios/Runner/Runner.entitlements` — 补 App Groups 能力

**Android 新增：**
- `android/app/src/main/AndroidManifest.xml` — 补 AppWidget receiver、前台服务权限
- `android/app/build.gradle` — 添加 Jetpack Glance 依赖
- `android/app/src/main/kotlin/com/fp/fitplan/widget/` — Glance AppWidget 三件套（与现有 .kt 同包）
- `android/app/src/main/kotlin/com/fp/fitplan/rest/RestOngoingService.kt` — 前台服务通知 + Chronometer
- `android/app/src/main/res/xml/fittrack_widget_info.xml` — AppWidget 元数据
- 修改 `MainActivity.kt` — 注册 liveview / widget MethodChannel

**HarmonyOS 不动**（已实现完整，仅通过 PAL 包装重构）

## 3. PAL 接口详细设计

### 3.1 RestReminderService

```dart
abstract class RestReminderService {
  Future<void> init();
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  });
  Future<void> cancelCurrentReminder();
  Future<void> cancelAllReminders();
  Stream<RestReminderEvent> get onNotificationClick;
}

class RestReminderEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;
}
```

### 3.2 LiveViewService

```dart
abstract class LiveViewService {
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  });
  Future<void> stopRestLiveView();
  Stream<LiveViewEvent> get onUserAction;  // skipRest / resume
}

class LiveViewEvent {
  final LiveViewAction action;  // skipRest / resume
  final Map<String, dynamic> payload;
}
```

### 3.3 WidgetCardService

```dart
abstract class WidgetCardService {
  Future<void> init();
  Future<void> pushCardData(WidgetCardData data);
  Future<void> clearCardData();
  Stream<WidgetCardClickEvent> get onCardClick;
}

enum WidgetCardMode { idle, training, rest }

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
  final int consecutiveDays;
  final String? lastTrainingName;
  final String? reminderTime;
  final int themeId;
  final List<int> themeColors;
}

class WidgetCardClickEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;
}
```

### 3.4 InviteUrlService

```dart
abstract class InviteUrlService {
  Future<void> registerHandler(Future<void> Function(Uri uri) handler);
  Future<void> launchInviteUrl(Uri uri);
}
```

### 3.5 PlatformServices 容器

```dart
class PlatformServices {
  static late final RestReminderService restReminder;
  static late final LiveViewService liveView;
  static late final WidgetCardService widgetCard;
  static late final InviteUrlService inviteUrl;

  static Future<void> init() async {
    if (isOhos) {
      restReminder = OhosRestReminderService();
      liveView = OhosLiveViewService();
      widgetCard = OhosWidgetCardService();
      inviteUrl = _NoopInviteUrlService();  // OHOS 不需要
    } else if (Platform.isAndroid) {
      restReminder = AndroidRestReminderService();
      liveView = AndroidLiveViewService();
      widgetCard = AndroidWidgetCardService();
      inviteUrl = AndroidInviteUrlService();
    } else if (Platform.isIOS) {
      restReminder = IosRestReminderService();
      liveView = IosLiveViewService();
      widgetCard = IosWidgetCardService();
      inviteUrl = IosInviteUrlService();
    } else {
      // 桌面/测试环境使用 Noop 实现
      restReminder = _NoopRestReminderService();
      liveView = _NoopLiveViewService();
      widgetCard = _NoopWidgetCardService();
      inviteUrl = _NoopInviteUrlService();
    }
    await restReminder.init();
    await widgetCard.init();
  }
}
```

## 4. iOS 端详细设计

### 4.1 Info.plist 补全

```xml
<!-- 新增权限说明 -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>用于将训练海报保存到您的相册</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>用于读取相册图片作为头像</string>
<key>NSUserNotificationsUsageDescription</key>
<string>用于发送训练提醒和休息结束通知</string>

<!-- Live Activities 支持 -->
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

<!-- 后台通知调度 -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

### 4.2 AppDelegate.swift 增强

注册 4 个 MethodChannel：

1. **`com.ft.fitplan/reminder`** — 休息结束本地通知
   - `scheduleRestReminder(title, content, triggerTimeInSeconds, notificationId)`
   - `cancelRestReminder(notificationId)`
   - `cancelAllReminders()`
   - 使用 `UNUserNotificationCenter` + `UNCalendarNotificationTrigger`

2. **`com.ft.fitplan/liveview`** — Live Activities
   - `startRestLiveView(exerciseName, restSeconds, restEndTimeMs)`
   - `stopRestLiveView()`
   - 使用 `ActivityKit`, iOS 16.1+；低于 16.1 返回错误由 Dart 侧降级

3. **`com.ft.fitplan/widget`** — Home Widget 数据推送
   - `pushCardData(jsonData)` — 写入 `UserDefaults(suiteName: "group.com.fp.fitplan")`
   - `WidgetKit.Center.shared.reloadTimelines(ofKind: "FitTrackWidget")`

4. **`com.ft.fitplan/invite`** — URL scheme 处理
   - `launchInviteUrl(url)` — Flutter 侧调用原生打开 URL
   - `AppDelegate` 处理 `application(_:open:options:)` 转发回 Flutter

通知点击路由回传（替代 HarmonyOS `onNewWant`）：

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                             didReceive response: UNNotificationResponse) async {
  let userInfo = response.notification.request.content.userInfo
  if let targetPage = userInfo["targetPage"] as? String {
    reminderChannel?.invokeMethod("onCardClick", arguments: userInfo)
  }
}
```

### 4.3 Widget Extension target

```
ios/RestLiveActivity/                    # 新 target
├── RestLiveActivityAttributes.swift     # Live Activity 数据模型
├── RestLiveActivity.swift               # Live Activity UI（锁屏 + 灵动岛）
├── FitTrackWidget.swift                 # Home Screen Widget（三态）
├── FitTrackWidgetEntry.swift            # TimelineEntry + 数据读取
├── RestLiveActivityBundle.swift         # @main WidgetBundle
└── Info.plist
```

**RestLiveActivityAttributes**（Live Activity 状态）：

```swift
struct RestLiveActivityAttributes: ActivityAttributes {
  struct ContentState {
    var exerciseName: String
    var remainingSeconds: Int
    var totalRestSeconds: Int
    var restEndTime: Date
  }
}
```

**三态 Home Widget** 通过读取 `UserDefaults(suiteName: "group.com.fp.fitplan")` 的 `widgetData` key，结构与 OHOS `FormDataRecord` 完全一致（mode / exerciseName / currentSet / themeColors 等），通过 `mode` 字段切换 IdleView / TrainingView / RestView。

**WidgetBundle**：

```swift
@main
struct RestLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    FitTrackWidget()
    RestLiveActivity()
  }
}
```

### 4.4 Runner.entitlements

```xml
<key>com.apple.security.application-groups</key>
<array>
  <string>group.com.fp.fitplan</string>
</array>
```

Widget Extension target 同样需要声明同一 App Group。

### 4.5 pubspec.yaml

无需新增依赖，iOS 端原生代码使用 `ActivityKit` / `WidgetKit` / `UserNotifications`，通过 MethodChannel 桥接，Flutter 侧仅依赖已有的 `flutter_local_notifications`。

## 5. Android 端详细设计

### 5.1 AndroidManifest.xml 补全

```xml
<!-- 新增权限 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<!-- AppWidget receiver -->
<receiver
    android:name=".widget.FitTrackGlanceWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/fittrack_widget_info" />
</receiver>

<!-- 前台服务（休息倒计时实况通知） -->
<service
    android:name=".rest.RestOngoingService"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="rest_countdown" />
</service>
```

### 5.2 Jetpack Glance AppWidget

```
android/app/src/main/kotlin/com/fp/fitplan/widget/
├── FitTrackGlanceWidgetReceiver.kt    # GlanceAppWidgetReceiver
├── FitTrackGlanceWidget.kt            # GlanceAppWidget — 提供 UI
├── FitTrackWidgetState.kt             # 状态定义（idle/training/rest）
└── WidgetDataStore.kt                 # SharedPreferences 读取
```

**`FitTrackGlanceWidget.kt`** 用 Compose 语法写三态：

```kotlin
@Composable
fun WidgetContent(state: FitTrackWidgetState) {
    Box(modifier = Modifier.fillMaxSize().padding(12.dp)) {
        when (state.mode) {
            "idle" -> IdleView(state)
            "training" -> TrainingView(state)
            "rest" -> RestView(state)
        }
    }
}
```

**数据流**：Flutter → MethodChannel `com.ft.fitplan/widget` → `WidgetDataStore.saveState(json)` → `GlanceAppWidget.updateAll(context)`。

**数据存储**：SharedPreferences key `widget_data`，与 HarmonyOS preferences 字段名一致。

### 5.3 RestOngoingService（前台服务 + Chronometer）

```
android/app/src/main/kotlin/com/fp/fitplan/rest/
├── RestOngoingService.kt              # Foreground Service
└── RestNotificationBuilder.kt         # 通知构建器（Chronometer 倒计时）
```

**`RestOngoingService.kt`** 关键点：
- `startForeground` 启动前台服务，显示 ongoing 通知
- 通知使用 `RemoteViews` + `Chronometer` 控件，`android:countDown="true"` 实现倒计时显示
- 通知 channel：`rest_countdown`，importance=LOW（不发声，只显示）
- 通知携带 `targetPage="training"`、`cardAction="resume"`，点击跳回训练页
- 通知携带"结束休息"操作按钮 → `PendingIntent` 携带 `cardAction="skipRest"`
- `stopRestLiveView` 时 `stopForeground(STOP_FOREGROUND_REMOVE)` + cancel notification

**`MainActivity.kt`** 新增两个 MethodChannel：
- `com.ft.fitplan/liveview` → `startRestLiveView` / `stopRestLiveView` → 启动/停止 `RestOngoingService`
- `com.ft.fitplan/widget` → `pushCardData` → `WidgetDataStore.saveState` + `GlanceAppWidget.updateAll`

### 5.4 build.gradle 依赖

```gradle
dependencies {
    implementation "androidx.core:core-ktx:1.12.0"
    implementation "androidx.glance:glance-appwidget:1.0.0"
    implementation "androidx.glance:glance-material:1.0.0"
    implementation "androidx.datastore:datastore-preferences:1.0.0"
}
```

### 5.5 Kotlin 插件版本

Jetpack Glance 1.0.0 需要 Kotlin 1.9+，将 `android/build.gradle` 中 Kotlin 版本从 1.7.x 升级到 1.9.10（与 AGP 7.2.0 兼容）。

## 6. Codemagic 云构建

### 6.1 codemagic.yaml

新增 `codemagic.yaml` 到项目根目录：

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
```

### 6.2 用户配置步骤

1. 注册 Codemagic 账号（免费 500 分钟/月）
2. 在 Codemagic 控制台绑定 Apple Developer 账号
3. Push 到 master 触发构建，下载 ipa 安装测试

### 6.3 限制说明

- Android 端可直接在 Windows 本地构建测试，无需云构建
- iOS 云构建只用于**编译验证 + ipa 出包**，UI 调试仍需 Mac + 模拟器/真机
- 用户可后续自行切换到 Bitrise / 自购 Mac mini

## 7. 风险与注意事项

### 7.1 兼容性风险

| 项 | 风险 | 缓解 |
|----|------|------|
| Jetpack Glance 需要 Kotlin 1.9+ / Compose 1.6+ | 项目用 Java 17 + AGP 7.2.0 | Glance 1.0.0 兼容 AGP 7.0+；Kotlin 插件升级到 1.9.10（与 AGP 7.2.0 兼容） |
| iOS 16.1 Live Activities | 用户低于 16.1 会崩溃 | `if #available(iOS 16.1, *)` 守卫，低版本降级为普通通知 |
| Android 12+ 前台服务限制 | `FOREGROUND_SERVICE_TYPE` 必须声明 | 用 `specialUse` 类型（API 34+ 要求）+ `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` |
| AppGroup 共享数据 | Widget Extension 与主 App 进程隔离 | App Groups 配置正确即可，UserDefaults(suiteName:) 跨进程 |
| iOS Widget Extension 与主 App 签名 | 同一 Apple Developer Team | 在 Xcode 中配置 Widget Extension target 与主 App 同一 Team |

### 7.2 测试策略

| 模块 | 测试方式 |
|------|----------|
| PAL 接口与包装层 | 现有 Dart 单测扩展，加 mock 平台实现 |
| Android 原生 | emulator-5558（Medium_Phone_4k AVD）跑端到端 |
| iOS 原生 | Codemagic 编译通过；用户在 Mac 真机/模拟器跑端到端 |
| 邀请链接 | Android 用 adb am start；iOS 用 xcrun simctl openurl |

## 8. 实施分批

考虑到工作量较大，分 4 批提交，每批可独立验证：

### Batch 1：PAL 骨架 + HarmonyOS/Android 现有能力包装
- 新建 `lib/services/platform/` 接口与 OHOS/Android 实现包装类
- `main.dart` / `training_page.dart` / `profile_page.dart` / `rest_notification_service.dart` 改用 PAL 接口
- 单测覆盖 PAL 注入
- 验证：HarmonyOS 与 Android 行为不变

### Batch 2：iOS P0 修复（Info.plist + AppDelegate）
- 补 Info.plist 权限说明、URL scheme、NSSupportsLiveActivities
- AppDelegate 注册 4 个 MethodChannel（liveview/widget 仅占位，reminder/invite 完整实现）
- 新增 `IosRestReminderService` / `IosInviteUrlService`
- 验证：iOS 不再闪退，邀请链接可打开，后台通知可用

### Batch 3：iOS P1（Live Activities + Home Widget）+ Android P1（前台服务 + Glance AppWidget）
- iOS Widget Extension target + ActivityKit + WidgetKit + AppGroup
- Android RestOngoingService + Glance AppWidget + WidgetDataStore
- 新增 `IosLiveViewService` / `IosWidgetCardService` / `AndroidLiveViewService` / `AndroidWidgetCardService`
- 验证：三平台桌面卡片 + 实况窗功能对齐

### Batch 4：Codemagic + 收尾
- 新增 `codemagic.yaml`
- iOS 证书签名流程文档化
- 三平台端到端验证清单

## 9. 关键证据文件（参考）

**HarmonyOS 独占服务（Dart 侧）：**
- `fittrack_flutter/lib/services/ohos_reminder_service.dart`
- `fittrack_flutter/lib/services/form_kit_service.dart`

**HarmonyOS 独占原生代码：**
- `fittrack_flutter/ohos/entry/src/main/ets/entryability/EntryAbility.ets`
- `fittrack_flutter/ohos/entry/src/main/ets/formability/FitTrackFormExtension.ets`
- `fittrack_flutter/ohos/entry/src/main/ets/pages/FitTrackWidget.ets`

**iOS 严重空白：**
- `fittrack_flutter/ios/Runner/AppDelegate.swift`（13 行模板代码，0 个 MethodChannel）
- `fittrack_flutter/ios/Runner/Info.plist`（无任何权限说明，无 URL scheme）

**Android 独占服务：**
- `fittrack_flutter/lib/services/android_alarm_service.dart`
- `fittrack_flutter/lib/services/rom_adaptation_service.dart`

**平台判断核心：**
- `fittrack_flutter/lib/utils/platform_utils.dart`
