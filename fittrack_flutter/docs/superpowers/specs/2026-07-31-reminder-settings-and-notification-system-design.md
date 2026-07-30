# 训练提醒设置优化与 App 内通知系统设计

> 日期：2026-07-31
> 状态：待实现
> 范围：Flutter + OHOS 原生

## 一、背景与目标

### 1.1 现状问题

| 模块 | 现状 | 问题 |
|---|---|---|
| 休息提醒设置 | [reminder_settings_page.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\pages\reminder_settings_page.dart) 有振动/提示音开关 | 振动/提示音是全局设置不分场景；无横幅通知引导；UI 简陋 |
| 横幅通知 | 应用无法通过 API 强制开启 | 用户不知道去哪里开启横幅通知，导致休息结束看不到顶部弹窗 |
| 健身卡到期提醒 | [gym_card_reminder_service.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\services\gym_card_reminder_service.dart) 仅 App 前台 checkAndPush | 用户不开 App 就收不到通知；非定时提醒 |
| App 内通知系统 | profile_page / home_page 的 `_showNotifications` 全是 mock 数据 | 不存在持久化通知记录；用户在 App 内看不到历史通知 |
| 每日训练提醒 | [daily_reminder_service.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\services\daily_reminder_service.dart) + EntryAbility 代理提醒 | 能准时发送，但不写入 App 内通知系统 |

### 1.2 目标

1. **休息提醒设置 UI 优化**：增加横幅通知强引导，灵活控制提示音/振动/关闭提醒
2. **横幅通知引导页**：说明 + 步骤 + 跳转按钮，引导用户去系统设置开启横幅
3. **健身卡到期提醒后台准时触发**：使用 OHOS 代理提醒调度到到期日触发，App 不在后台也能收到
4. **App 内通知系统**：从零搭建持久化通知记录，健身卡提醒/每日训练提醒触发时同步写入

### 1.3 非目标（YAGNI）

- 不做通知分类筛选（按类型过滤）
- 不做通知推送策略智能化（SmartPushService 保持现状）
- 不做跨设备通知同步
- 不做通知点击跳转到具体页面（仅展示标题/正文）

## 二、架构设计

### 2.1 模块划分

```
┌─────────────────────────────────────────────────────────┐
│                    用户界面层                             │
│  reminder_settings_page  banner_notification_guide_page  │
│  profile_page._showNotifications  home_page._showNotif   │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    服务层                                 │
│  GymCardReminderService（改造）                           │
│  DailyReminderService（小改）                             │
│  NotificationStorageService（新增）                       │
│  OhosReminderService（扩展）                              │
└────────────────────────┬────────────────────────────────┘
                         │ MethodChannel
┌────────────────────────▼────────────────────────────────┐
│              OHOS 原生层 (EntryAbility.ets)              │
│  scheduleGymCardReminder（新增）                          │
│  scheduleTrainingReminder（已存在）                       │
│  scheduleRestReminder（已存在）                           │
└─────────────────────────────────────────────────────────┘
```

### 2.2 数据流

#### 健身卡到期提醒数据流

```
用户开启健身卡提醒 / 改阈值 / 增删健身卡
  ↓
GymCardReminderService.reschedule()
  ↓
扫描所有健身卡，计算最近需要提醒的日期（到期日 - N天 或 到期当天）
  ↓
OhosReminderService.scheduleGymCardReminder(date, title, content)
  ↓
EntryAbility.scheduleGymCardReminder()
  ↓
reminderAgentManager.publishReminder(ReminderRequestCalendar)
  ↓
到期日触发 → 系统通知 + MethodChannel 回调 Flutter
  ↓
Flutter 收到回调 → NotificationStorageService.addNotification()
```

#### App 内通知数据流

```
通知触发源（3种）
  ├─ 健身卡到期提醒（OHOS 代理提醒回调）
  ├─ 每日训练提醒（OHOS 代理提醒回调）
  └─ 休息结束提醒（OHOS 代理提醒回调，可选）
  ↓
NotificationStorageService.addNotification(type, title, body)
  ↓
Storage.saveNotifications() 持久化
  ↓
用户打开通知面板 → 读取 Storage.getNotifications() → 展示列表
```

## 三、详细设计

### 3.1 模块1：休息提醒设置 UI 优化

#### 3.1.1 休息提醒卡片重构

**文件**：[reminder_settings_page.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\pages\reminder_settings_page.dart)

**改造点**：

1. **主开关**：「休息结束提醒」（`restNotificationEnabled`）关闭时，整个卡片其他项禁用变灰
2. **子项独立控制**：
   - 提示音开关（`restSoundEnabled`，新 key，原 `soundEnabled` 保留兼容）
   - 振动开关（`restVibrationEnabled`，新 key，原 `vibrationEnabled` 保留兼容）
3. **新增横幅通知引导项**：点击跳转到引导页

**关键改动**：
- 新增 `_restNotificationEnabled` 控制子项禁用状态
- 子项 `onChanged` 在主开关关闭时忽略
- 横幅通知引导项显示当前状态（已开启/未开启），通过 `PermissionService.isNotificationGranted()` 检测

**注意**：原 `vibrationEnabled` / `soundEnabled` 设置项被训练完成逻辑使用，为避免破坏现有功能，新增 `restVibrationEnabled` / `restSoundEnabled` 专用于休息提醒，原设置项保留。

#### 3.1.2 横幅通知引导页

**新增文件**：`lib/pages/banner_notification_guide_page.dart`

**页面结构**：
```
PageHeader（标题：横幅通知引导）
  ↓
说明卡片：解释横幅通知的作用
  "休息结束时，横幅通知会在屏幕顶部弹出提醒，类似微信消息通知。
   由于系统限制，横幅通知需要您手动开启。"
  ↓
步骤卡片（3步）：
  步骤1：打开手机「设置」
  步骤2：进入「通知管理」> 找到「FitTrack」
  步骤3：开启「横幅通知」开关
  ↓
状态指示器：检测当前横幅通知是否已开启
  ↓
底部按钮：「去开启」→ 调用 RomAdaptationService.openAppSettings()
```

**跳转入口**：
- reminder_settings_page 的横幅通知引导项
- settings_page 的通知权限项（可选）

### 3.2 模块2：健身卡到期提醒后台准时触发

#### 3.2.1 GymCardReminderService 改造

**文件**：[gym_card_reminder_service.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\services\gym_card_reminder_service.dart)

**新增方法**：`reschedule()`

```dart
/// 重新调度健身卡到期提醒（开启/改阈值/增删卡时调用）
Future<void> reschedule() async {
  // 1. 取消现有调度
  await OhosReminderService.instance.cancelGymCardReminder();

  // 2. 检查开关
  final settings = Storage.getSettings();
  final enabled = settings['gymCardExpiryReminderEnabled'] as bool? ?? false;
  if (!enabled) return;

  // 3. 扫描所有卡，计算最近提醒日
  final daysThreshold = settings['gymCardExpiryDaysThreshold'] as int? ?? 7;
  final countThreshold = settings['gymCardLowCountThreshold'] as int? ?? 3;
  final cards = Storage.getGymCards();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  DateTime? nearestDate;
  String? alertContent;

  for (final card in cards) {
    final name = card['name'] as String? ?? '未命名卡';
    DateTime? candidateDate;
    String candidateContent = '';

    // 期限卡：到期日 - N天 作为提醒日
    final endDate = card['endDate'] as int? ?? 0;
    if (endDate > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final remindDate = DateTime(end.year, end.month, end.day)
          .subtract(Duration(days: daysThreshold));
      // 如果提醒日已过但卡未过期，改为今天提醒
      candidateDate = remindDate.isBefore(today) ? today : remindDate;
      final diff = end.difference(now).inDays;
      candidateContent = diff < 0
          ? '「$name」已过期 ${-diff} 天'
          : diff == 0
              ? '「$name」今天到期'
              : '「$name」还有 $diff 天到期';
    }

    // 次卡：剩余次数 ≤ 阈值时今天提醒
    final cardType = card['cardType'] as String? ?? '';
    final remaining = card['remainingCount'] as int? ?? -1;
    if (cardType == '次卡' && remaining >= 0 && remaining <= countThreshold) {
      final content = remaining == 0
          ? '「$name」已用完所有次数'
          : '「$name」仅剩 $remaining 次';
      // 次卡总是今天提醒，优先级高于期限卡
      candidateDate = today;
      candidateContent = content;
    }

    // 选最近的提醒日
    if (candidateDate != null) {
      if (nearestDate == null || candidateDate.isBefore(nearestDate!)) {
        nearestDate = candidateDate;
        alertContent = candidateContent;
      }
    }
  }

  if (nearestDate == null || alertContent == null) return;

  // 4. 格式化日期为 "YYYY-MM-DD"
  final dateStr = '${nearestDate.year}-'
      '${nearestDate.month.toString().padLeft(2, '0')}-'
      '${nearestDate.day.toString().padLeft(2, '0')}';

  // 5. 调度代理提醒
  await OhosReminderService.instance.scheduleGymCardReminder(
    title: '健身卡提醒',
    content: alertContent,
    dateStr: dateStr,
  );
}
```

**调度策略**：
- 期限卡：提醒日 = 到期日 - N天阈值；若提醒日已过但卡未过期，改为今天
- 次卡：剩余次数 ≤ 阈值时，今天立即提醒
- 只调度最近的一个提醒日（避免发布多个代理提醒），单次触发不重复
- 提醒时间固定为 10:00（避免深夜打扰）
- 提醒触发后用户点击通知拉起 App 时，`onNewWant` 回调写入 app 内通知系统（见模块4）

**触发时机**（调用 reschedule）：
- reminder_settings_page 开关变更
- reminder_settings_page 阈值滑块变更
- 增删健身卡时（需在健身卡管理页调用）

#### 3.2.2 OhosReminderService 扩展

**文件**：[ohos_reminder_service.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\services\ohos_reminder_service.dart)

**新增方法**：
```dart
/// 调度健身卡到期提醒
/// [dateStr] 格式 "YYYY-MM-DD"
Future<void> scheduleGymCardReminder({
  required String title,
  required String content,
  required String dateStr,
}) async {
  await _channel.invokeMethod<void>('scheduleGymCardReminder', {
    'title': title,
    'content': content,
    'dateStr': dateStr,
  });
}

Future<void> cancelGymCardReminder() async {
  await _channel.invokeMethod<void>('cancelGymCardReminder');
}
```

#### 3.2.3 EntryAbility 原生实现

**文件**：[EntryAbility.ets](file:///e:\Project\health_project\health_training\fittrack_flutter\ohos\entry\src\main\ets\entryability\EntryAbility.ets)

**新增**：`scheduleGymCardReminder` / `cancelGymCardReminder` 方法

使用 `ReminderRequestCalendar` 调度到指定日期 10:00 触发，使用 `SOCIAL_COMMUNICATION` 槽位。`wantAgent` 的 `wants[0].parameters` 增加 `notificationType: 'gym_card'`，供 `onNewWant` 识别并写入 app 内通知系统（见模块4）。

**关键代码结构**：
```typescript
private gymCardReminderId: number = -1;

scheduleGymCardReminder(title: string, content: string, dateStr: string): void {
  this.cancelGymCardReminder();
  // 解析 dateStr "YYYY-MM-DD"
  const parts = dateStr.split('-');
  const year = parseInt(parts[0], 10);
  const month = parseInt(parts[1], 10);
  const day = parseInt(parts[2], 10);

  const bundleInfo: bundleManager.BundleInfo =
    bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

  let reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
    reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
    dateTime: { year, month, day, hour: 10, minute: 0, second: 0 },
    repeatMonths: [],
    repeatDays: [],
    title: title,
    content: content,
    notificationId: 4001,
    slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
    wantAgent: {
      pkgName: bundleInfo.name,
      abilityName: 'EntryAbility',
    },
    actionButton: [{
      title: '查看',
      type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
    }],
  };
  // publishReminder(reminderRequest).then(id => this.gymCardReminderId = id)...
}
```

**保留前台兜底**：`checkAndPush()` 保留，App 启动时仍检查一次，作为代理提醒失败时的兜底。

### 3.3 模块3：App 内通知系统

#### 3.3.1 NotificationRecord 模型

**新增文件**：`lib/models/notification_record.dart`

```dart
class NotificationRecord {
  final String id;
  final String type;  // 'gym_card' | 'daily_training' | 'rest_end' | 'system'
  final String title;
  final String body;
  final int createdAt;  // millisecondsSinceEpoch
  final bool read;

  // toMap() / fromMap() 用于 Storage 序列化
}
```

#### 3.3.2 Storage 持久化方法

**文件**：[storage.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\data\storage.dart)

**新增方法**：
```dart
static List<Map<String, dynamic>> getNotifications();
static void addNotification(Map<String, dynamic> notification);
static void markNotificationRead(String id);
static void markAllNotificationsRead();
static void clearNotifications();
static void deleteNotification(String id);
```

**存储 key**：`notifications`（List<Map>）

**保留策略**：最多保留 50 条，超过时删除最旧的未读通知。

#### 3.3.3 NotificationStorageService

**新增文件**：`lib/services/notification_storage_service.dart`

封装通知记录的增删改查，供各提醒服务调用：

```dart
class NotificationStorageService {
  static final instance = NotificationStorageService._();

  void addGymCardNotification(String title, String body) {
    Storage.addNotification({
      'id': UUID,
      'type': 'gym_card',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }
  // addDailyTrainingNotification / addRestEndNotification ...
}
```

#### 3.3.4 通知面板改造

**文件**：[profile_page.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\pages\profile_page.dart#L151-L203) 和 [home_page.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\pages\home_page.dart#L1007-L1053)

**改造 `_showNotifications`**：
- 数据源从 mock 改为 `Storage.getNotifications()`
- 空列表时显示「暂无通知」
- 列表项显示：图标（按 type 区分）、标题、正文、时间（相对时间如「3分钟前」）
- 未读通知用红点标记
- 底部增加「全部已读」「清空」按钮

**图标映射**：
- `gym_card` → `Icons.card_membership_outlined`
- `daily_training` → `Icons.fitness_center`
- `rest_end` → `Icons.timer`
- `system` → `Icons.info`

### 3.4 模块4：每日训练提醒 + 通知系统联动

#### 3.4.1 原生回调写入通知

**问题**：OHOS 代理提醒触发时，App 可能在后台或已退出，无法直接调用 Flutter 写入通知。

**方案**：代理提醒触发后，用户点击通知拉起 App 时，在 `onNewWant` 中检测通知类型并写入 app 内通知系统。

**EntryAbility.ets 改造**：
- `wantAgent` 的 parameters 增加 `notificationType` 字段（需改用 `WantAgent` 而非 `MaxScreenWantAgent`，因为前者支持 parameters）
- `onNewWant` 解析 `notificationType`，通过 MethodChannel 回调 Flutter
- Flutter 端 `OhosReminderService` 收到回调后调用 `NotificationStorageService.addXxxNotification()`

**注意**：`MaxScreenWantAgent` 类型不支持 parameters 字段（已知约束），但 `wantAgent` 字段支持的 `WantAgent` 类型可以通过 `wantAgent.WantAgentInfo.wants[0].parameters` 传递。

#### 3.4.2 DailyReminderService 联动

**文件**：[daily_reminder_service.dart](file:///e:\Project\health_project\health_training\fittrack_flutter\lib\services\daily_reminder_service.dart)

`scheduleTrainingReminder` 调用时，在 `wantAgent.parameters` 中增加 `notificationType: 'daily_training'`，供 `onNewWant` 识别。

#### 3.4.3 GymCardReminderService 联动

`scheduleGymCardReminder` 的 `wantAgent.parameters` 增加 `notificationType: 'gym_card'`。

## 四、错误处理

| 场景 | 处理策略 |
|---|---|
| 代理提醒发布失败（权限未授予） | 记录日志，App 启动时 checkAndPush 兜底 |
| 代理提醒发布失败（模拟器不支持） | 记录日志，仅前台 checkAndPush 生效 |
| Storage 通知写入失败 | 记录日志，不影响系统通知展示 |
| 健身卡无到期项 | reschedule 时取消现有提醒，不发布新提醒 |
| 用户关闭提醒开关 | reschedule 时取消现有提醒 |

## 五、测试要点

### 5.1 手动测试场景

1. **休息提醒设置**：
   - 关闭主开关 → 子项禁用变灰
   - 开启横幅通知引导 → 跳转引导页 → 点击「去开启」跳转系统设置
2. **健身卡到期提醒**：
   - 添加一张期限卡，到期日为明天，阈值 7 天 → 开启提醒 → 应立即调度今天 10:00 提醒
   - 添加一张次卡，剩余次数 2，阈值 3 → 开启提醒 → 应调度今天 10:00 提醒
   - 删除所有健身卡 → reschedule 应取消现有提醒
3. **App 内通知系统**：
   - 健身卡提醒触发 → 通知面板能看到记录
   - 每日训练提醒触发 → 通知面板能看到记录
   - 标记已读 / 清空通知
4. **每日训练提醒**：
   - 设置 18:00 提醒 → 到时间应收到系统通知 + App 内通知记录

### 5.2 回归测试

- 训练完成时的振动/提示音不受影响（使用原 `vibrationEnabled` / `soundEnabled`）
- 桌面卡片状态切换不受影响
- 休息结束代理提醒不受影响

## 六、文件变更清单

### 新增文件

| 文件路径 | 用途 |
|---|---|
| `lib/pages/banner_notification_guide_page.dart` | 横幅通知引导页 |
| `lib/models/notification_record.dart` | 通知记录模型 |
| `lib/services/notification_storage_service.dart` | 通知存储服务 |

### 修改文件

| 文件路径 | 改动概要 |
|---|---|
| `lib/pages/reminder_settings_page.dart` | 休息提醒卡片重构 + 横幅引导入口 |
| `lib/pages/profile_page.dart` | `_showNotifications` 改为读取真实数据 |
| `lib/pages/home_page.dart` | `_showNotifications` 改为读取真实数据 |
| `lib/data/storage.dart` | 新增 notifications 持久化方法 |
| `lib/services/gym_card_reminder_service.dart` | 新增 reschedule() + 联动通知系统 |
| `lib/services/daily_reminder_service.dart` | wantAgent 增加 notificationType |
| `lib/services/ohos_reminder_service.dart` | 新增 scheduleGymCardReminder / cancelGymCardReminder |
| `ohos/entry/.../EntryAbility.ets` | 新增 scheduleGymCardReminder + onNewWant 通知回调 |
| `lib/main.dart` | 路由注册 banner_notification_guide_page |

## 七、实施顺序

1. **模块3：App 内通知系统**（基础设施，其他模块依赖）
   - NotificationRecord 模型
   - Storage 持久化方法
   - NotificationStorageService
   - 改造 profile_page / home_page 通知面板
2. **模块1：休息提醒设置 UI 优化**
   - reminder_settings_page 重构
   - banner_notification_guide_page 新增
3. **模块2：健身卡到期提醒后台调度**
   - OhosReminderService 扩展
   - EntryAbility 原生实现
   - GymCardReminderService.reschedule()
4. **模块4：每日训练提醒联动**
   - wantAgent 增加 notificationType
   - onNewWant 回调写入通知
