# 训练提醒设置优化与 App 内通知系统 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 优化休息提醒设置 UI 并新增横幅通知引导页；健身卡到期提醒改为 OHOS 代理提醒后台准时触发；从零搭建 App 内通知系统并联动各提醒服务。

**Architecture:** 分 4 个模块按依赖顺序实施：先建 App 内通知系统（基础设施），再优化休息提醒 UI，再实现健身卡后台调度，最后联动每日训练提醒。Flutter 侧通过 MethodChannel 调用 OHOS 原生 `reminderAgentManager`，原生回调通过 `onNewWant` 写入通知记录。

**Tech Stack:** Flutter 3.x / Dart / OHOS ArkTS / reminderAgentManager / SharedPreferences

## Global Constraints

- 项目无测试框架，验证方式：`flutter analyze` + 手动真机测试
- 代码注释使用中文（遵循用户语言要求）
- 原有 `vibrationEnabled` / `soundEnabled` 设置项被训练完成逻辑使用，不得删除，新增 `restVibrationEnabled` / `restSoundEnabled` 专用于休息提醒
- OHOS `MaxScreenWantAgent` 类型不支持 `parameters` 字段；传递参数需使用 `wantAgent` 字段的 `WantAgent` 类型，通过 `wantAgent.WantAgentInfo.wants[0].parameters` 传递
- 代理提醒使用 `notificationManager.SlotType.SOCIAL_COMMUNICATION` 槽位以支持横幅
- 文件路径根目录：`e:\Project\health_project\health_training\fittrack_flutter`

---

## 文件结构

### 新增文件

| 文件路径 | 职责 |
|---|---|
| `lib/models/notification_record.dart` | 通知记录数据模型，含 toMap/fromMap |
| `lib/services/notification_storage_service.dart` | 通知记录增删改查服务，封装 Storage 调用 |
| `lib/pages/banner_notification_guide_page.dart` | 横幅通知引导页，说明+步骤+跳转按钮 |
| `lib/widgets/notification_list_sheet.dart` | 通知列表底部弹窗组件（供 profile/home 复用） |

### 修改文件

| 文件路径 | 改动概要 |
|---|---|
| `lib/data/storage.dart` | 新增 notifications 持久化方法（6个）+ getGymCards 方法确认 |
| `lib/pages/reminder_settings_page.dart` | 休息提醒卡片重构（主开关+子项+横幅引导入口） |
| `lib/pages/profile_page.dart` | `_showNotifications` 改为读取真实数据并复用通知列表组件 |
| `lib/pages/home_page.dart` | `_showNotifications` 同上改造 |
| `lib/services/gym_card_reminder_service.dart` | 新增 reschedule() + 联动通知系统 |
| `lib/services/daily_reminder_service.dart` | wantAgent 增加 notificationType |
| `lib/services/ohos_reminder_service.dart` | 新增 scheduleGymCardReminder / cancelGymCardReminder |
| `ohos/entry/src/main/ets/entryability/EntryAbility.ets` | 新增 scheduleGymCardReminder + onNewWant 通知回调 |
| `lib/main.dart` | 路由注册 banner_notification_guide_page |

---

## Task 1: NotificationRecord 数据模型

**Files:**
- Create: `lib/models/notification_record.dart`

**Interfaces:**
- Produces: `NotificationRecord` 类，字段 `id`/`type`/`title`/`body`/`createdAt`/`read`，方法 `toMap()` / `NotificationRecord.fromMap()`

- [ ] **Step 1: 创建 NotificationRecord 模型**

```dart
/// lib/models/notification_record.dart

/// App 内通知记录模型
class NotificationRecord {
  final String id;
  final String type; // 'gym_card' | 'daily_training' | 'rest_end' | 'system'
  final String title;
  final String body;
  final int createdAt; // millisecondsSinceEpoch
  final bool read;

  const NotificationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'createdAt': createdAt,
        'read': read,
      };

  factory NotificationRecord.fromMap(Map<String, dynamic> map) =>
      NotificationRecord(
        id: map['id'] as String? ?? '',
        type: map['type'] as String? ?? 'system',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        createdAt: map['createdAt'] as int? ?? 0,
        read: map['read'] as bool? ?? false,
      );

  NotificationRecord copyWith({bool? read}) => NotificationRecord(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/models/notification_record.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/models/notification_record.dart
git commit -m "feat: 新增 NotificationRecord 通知记录数据模型"
```

---

## Task 2: Storage 通知持久化方法

**Files:**
- Modify: `lib/data/storage.dart`（在类末尾新增方法）

**Interfaces:**
- Consumes: `NotificationRecord.toMap()` 来自 Task 1
- Produces: `Storage.getNotifications()` / `Storage.addNotification()` / `Storage.markNotificationRead()` / `Storage.markAllNotificationsRead()` / `Storage.clearNotifications()` / `Storage.deleteNotification()`

- [ ] **Step 1: 在 Storage 类中新增 notifications 持久化方法**

先读取 `lib/data/storage.dart` 末尾，找到类结束的 `}` 之前的位置，新增以下方法。同时需要新增一个存储 key 常量。

在 `static const String _keyMigrated = 'fittrack_sqlite_migrated';` 下方新增：

```dart
  static const String _keyNotifications = 'fittrack_notifications';
```

在 Storage 类末尾（最后一个 `}` 之前）新增：

```dart
  // ============================================================
  // App 内通知记录
  // ============================================================

  /// 获取所有通知记录（按时间倒序）
  static List<Map<String, dynamic>> getNotifications() {
    final list = _safeGet(_keyNotifications, <dynamic>[]) as List<dynamic>;
    final result = list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    result.sort((a, b) {
      final ta = a['createdAt'] as int? ?? 0;
      final tb = b['createdAt'] as int? ?? 0;
      return tb.compareTo(ta);
    });
    return result;
  }

  /// 新增一条通知记录（最多保留 50 条，超出删除最旧的已读通知）
  static void addNotification(Map<String, dynamic> notification) {
    final list = getNotifications();
    list.insert(0, notification);
    // 超过 50 条时删除最旧的已读通知
    while (list.length > 50) {
      final idx = list.lastIndexWhere((n) => n['read'] == true);
      if (idx >= 0) {
        list.removeAt(idx);
      } else {
        // 没有已读通知，删除最后一条
        list.removeLast();
      }
    }
    _store[_keyNotifications] = list;
    _persistKey(_keyNotifications);
  }

  /// 标记单条通知为已读
  static void markNotificationRead(String id) {
    final list = getNotifications();
    for (final n in list) {
      if (n['id'] == id) {
        n['read'] = true;
        break;
      }
    }
    _store[_keyNotifications] = list;
    _persistKey(_keyNotifications);
  }

  /// 标记所有通知为已读
  static void markAllNotificationsRead() {
    final list = getNotifications();
    for (final n in list) {
      n['read'] = true;
    }
    _store[_keyNotifications] = list;
    _persistKey(_keyNotifications);
  }

  /// 清空所有通知记录
  static void clearNotifications() {
    _store[_keyNotifications] = <dynamic>[];
    _persistKey(_keyNotifications);
  }

  /// 删除单条通知记录
  static void deleteNotification(String id) {
    final list = getNotifications();
    list.removeWhere((n) => n['id'] == id);
    _store[_keyNotifications] = list;
    _persistKey(_keyNotifications);
  }
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/data/storage.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/data/storage.dart
git commit -m "feat: Storage 新增 App 内通知记录持久化方法"
```

---

## Task 3: NotificationStorageService 服务

**Files:**
- Create: `lib/services/notification_storage_service.dart`

**Interfaces:**
- Consumes: `Storage.addNotification()` 来自 Task 2
- Produces: `NotificationStorageService.instance.addGymCardNotification()` / `addDailyTrainingNotification()` / `addRestEndNotification()` / `addSystemNotification()`

- [ ] **Step 1: 创建 NotificationStorageService**

```dart
/// lib/services/notification_storage_service.dart

import 'dart:math';
import '../data/storage.dart';

/// 通知记录存储服务
///
/// 封装各提醒服务调用 Storage 持久化通知记录的逻辑。
/// 生成唯一 id 供 Storage.addNotification 使用。
class NotificationStorageService {
  NotificationStorageService._();
  static final NotificationStorageService instance =
      NotificationStorageService._();

  /// 生成简单唯一 id（时间戳 + 随机数）
  String _genId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    return '${ts}_$rand';
  }

  /// 新增健身卡到期通知
  void addGymCardNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'gym_card',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增每日训练提醒通知
  void addDailyTrainingNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'daily_training',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增休息结束通知
  void addRestEndNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'rest_end',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增系统通知
  void addSystemNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'system',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }
}
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/services/notification_storage_service.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/services/notification_storage_service.dart
git commit -m "feat: 新增 NotificationStorageService 通知记录服务"
```

---

## Task 4: 通知列表底部弹窗组件

**Files:**
- Create: `lib/widgets/notification_list_sheet.dart`

**Interfaces:**
- Consumes: `Storage.getNotifications()` / `Storage.markAllNotificationsRead()` / `Storage.clearNotifications()` 来自 Task 2
- Produces: `NotificationListSheet.show(context)` 静态方法

- [ ] **Step 1: 创建通知列表底部弹窗组件**

先读取项目中已有的 `FitBottomSheet` 组件以复用样式（查找 `lib/widgets/common_widgets.dart` 或 `lib/widgets/fit_bottom_sheet.dart`）。如果没有专用 BottomSheet 组件，使用 `showModalBottomSheet`。

创建文件 `lib/widgets/notification_list_sheet.dart`：

```dart
/// lib/widgets/notification_list_sheet.dart

import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';

/// 通知列表底部弹窗
///
/// 从 Storage 读取真实通知记录并展示。
/// 支持标记已读、清空操作。
/// profile_page 和 home_page 的通知入口复用此组件。
class NotificationListSheet {
  /// 展示通知列表
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationListContent(),
    );
  }
}

class _NotificationListContent extends StatefulWidget {
  const _NotificationListContent();

  @override
  State<_NotificationListContent> createState() =>
      _NotificationListContentState();
}

class _NotificationListContentState extends State<_NotificationListContent> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = Storage.getNotifications();
    });
  }

  /// 图标映射
  IconData _iconForType(String type) {
    switch (type) {
      case 'gym_card':
        return Icons.card_membership_outlined;
      case 'daily_training':
        return Icons.fitness_center;
      case 'rest_end':
        return Icons.timer;
      default:
        return Icons.info;
    }
  }

  /// 相对时间格式化
  String _formatTime(int createdAt) {
    final now = DateTime.now();
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('通知', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    if (_notifications.any((n) => n['read'] != true))
                      TextButton(
                        onPressed: () {
                          Storage.markAllNotificationsRead();
                          _loadNotifications();
                        },
                        child: const Text('全部已读'),
                      ),
                    if (_notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Storage.clearNotifications();
                          _loadNotifications();
                        },
                        child: const Text('清空'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 通知列表
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: colors.textTertiary),
                        const SizedBox(height: 12),
                        Text('暂无通知',
                            style: TextStyle(color: colors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 56, color: colors.divider),
                    itemBuilder: (ctx, idx) {
                      final n = _notifications[idx];
                      final isUnread = n['read'] != true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.bgSecondary,
                          child: Icon(_iconForType(n['type'] as String? ?? ''),
                              color: colors.accent),
                        ),
                        title: Row(
                          children: [
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(n['title'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          n['body'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        trailing: Text(
                          _formatTime(n['createdAt'] as int? ?? 0),
                          style: TextStyle(
                              color: colors.textTertiary, fontSize: 12),
                        ),
                        onTap: () {
                          if (isUnread) {
                            Storage.markNotificationRead(
                                n['id'] as String? ?? '');
                            _loadNotifications();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/widgets/notification_list_sheet.dart`
Expected: No issues（如 `FitTrackColors` 缺少某些字段，根据实际主题类调整）

- [ ] **Step 3: 提交**

```bash
git add lib/widgets/notification_list_sheet.dart
git commit -m "feat: 新增通知列表底部弹窗组件"
```

---

## Task 5: 改造 profile_page / home_page 通知入口

**Files:**
- Modify: `lib/pages/profile_page.dart`（`_showNotifications` 方法，约 L151-L203）
- Modify: `lib/pages/home_page.dart`（`_showNotifications` 方法，约 L1007-L1053）

**Interfaces:**
- Consumes: `NotificationListSheet.show()` 来自 Task 4

- [ ] **Step 1: 读取 profile_page.dart 的 _showNotifications 方法**

Run: 读取 `lib/pages/profile_page.dart` L151-L203

- [ ] **Step 2: 改造 profile_page.dart 的 _showNotifications**

将原有 mock 数据实现替换为调用 `NotificationListSheet.show(context)`。保留方法签名不变。

找到 `_showNotifications` 方法体，替换为：

```dart
void _showNotifications() {
  NotificationListSheet.show(context);
}
```

同时在文件顶部新增 import：

```dart
import '../widgets/notification_list_sheet.dart';
```

并移除不再使用的 MockData import（如果仅此处使用的话，需检查其他地方是否还引用 MockData）。

- [ ] **Step 3: 改造 home_page.dart 的 _showNotifications**

同样的改造方式。找到 `lib/pages/home_page.dart` 的 `_showNotifications` 方法（约 L1007-L1053），替换为：

```dart
void _showNotifications() {
  NotificationListSheet.show(context);
}
```

新增 import：

```dart
import '../widgets/notification_list_sheet.dart';
```

- [ ] **Step 4: 验证无分析错误**

Run: `flutter analyze lib/pages/profile_page.dart lib/pages/home_page.dart`
Expected: No issues

- [ ] **Step 5: 手动验证**

启动 App，进入「我的」页面和「首页」，点击通知图标/入口，应弹出通知列表底部弹窗，空列表时显示「暂无通知」。

- [ ] **Step 6: 提交**

```bash
git add lib/pages/profile_page.dart lib/pages/home_page.dart
git commit -m "refactor: 通知入口改为复用 NotificationListSheet 组件"
```

---

## Task 6: 横幅通知引导页

**Files:**
- Create: `lib/pages/banner_notification_guide_page.dart`
- Modify: `lib/main.dart`（路由注册）

**Interfaces:**
- Consumes: `PermissionService` 检测通知权限状态；跳转系统设置的方法

- [ ] **Step 1: 读取 PermissionService 检测现有方法**

Run: 读取 `lib/services/permission_service.dart`，查找是否有 `isNotificationGranted()` 和 `openAppSettings()` 方法。

- [ ] **Step 2: 创建横幅通知引导页**

```dart
/// lib/pages/banner_notification_guide_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';
import '../services/permission_service.dart';

/// 横幅通知引导页
///
/// 引导用户去系统设置开启横幅通知开关。
/// 横幅通知是用户级隐私设置，应用无法通过 API 强制开启。
class BannerNotificationGuidePage extends StatefulWidget {
  const BannerNotificationGuidePage({super.key});

  @override
  State<BannerNotificationGuidePage> createState() =>
      _BannerNotificationGuidePageState();
}

class _BannerNotificationGuidePageState
    extends State<BannerNotificationGuidePage> {
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionService.isNotificationGranted();
    if (mounted) {
      setState(() => _notificationGranted = granted);
    }
  }

  Future<void> _openSettings() async {
    await PermissionService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '横幅通知引导',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明卡片
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_active,
                            color: colors.accent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('为什么需要开启横幅通知？',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(
                                '休息结束时，横幅通知会在屏幕顶部弹出提醒，类似微信消息通知。\n\n'
                                '由于系统限制，横幅通知需要您手动开启，应用无法自动开启此开关。',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 步骤卡片
                  Text('开启步骤', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildStep(colors, 1, '打开手机「设置」'),
                  _buildStep(colors, 2, '进入「通知管理」> 找到「FitTrack」'),
                  _buildStep(colors, 3, '开启「横幅通知」开关'),
                  const SizedBox(height: 20),
                  // 状态指示器
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _notificationGranted
                          ? colors.accent.withOpacity(0.1)
                          : colors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _notificationGranted
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _notificationGranted
                              ? Colors.green
                              : colors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _notificationGranted
                                ? '通知权限已开启，请确认横幅通知开关也已开启'
                                : '通知权限未开启，请先开启通知权限',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 底部按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('去开启'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(FitTrackColors colors, int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$num',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 在 main.dart 注册路由**

读取 `lib/main.dart`，找到 GoRouter 配置，新增路由：

```dart
GoRoute(
  path: '/banner-notification-guide',
  builder: (context, state) => const BannerNotificationGuidePage(),
),
```

在 main.dart 顶部新增 import：

```dart
import 'pages/banner_notification_guide_page.dart';
```

- [ ] **Step 4: 验证 PermissionService 是否有需要的方法**

如果 `PermissionService` 没有 `isNotificationGranted()` 或 `openAppSettings()` 方法，需要在该服务中新增。读取 `lib/services/permission_service.dart` 确认。

- [ ] **Step 5: 验证无分析错误**

Run: `flutter analyze lib/pages/banner_notification_guide_page.dart lib/main.dart`
Expected: No issues

- [ ] **Step 6: 提交**

```bash
git add lib/pages/banner_notification_guide_page.dart lib/main.dart
git commit -m "feat: 新增横幅通知引导页"
```

---

## Task 7: 休息提醒设置 UI 重构

**Files:**
- Modify: `lib/pages/reminder_settings_page.dart`（L20-L55 state 字段 + L81-L123 休息提醒卡片）

**Interfaces:**
- Consumes: 横幅通知引导页路由 `/banner-notification-guide` 来自 Task 6
- Produces: 新增 `restSoundEnabled` / `restVibrationEnabled` 设置项；`vibrationEnabled` / `soundEnabled` 保留

- [ ] **Step 1: 修改 state 字段**

在 `_ReminderSettingsPageState` 中（L20-L30 区域），新增休息提醒专用开关字段：

```dart
  bool _restNotificationEnabled = true;
  bool _restVibrationEnabled = true;   // 新增：休息提醒专用振动
  bool _restSoundEnabled = true;        // 新增：休息提醒专用提示音
  bool _vibrationEnabled = true;        // 保留：训练完成振动
  bool _soundEnabled = true;            // 保留：训练完成提示音
```

- [ ] **Step 2: 修改 _loadSettings 加载新字段**

在 `_loadSettings` 方法中（L38-L55），新增读取 `restVibrationEnabled` / `restSoundEnabled`：

```dart
  void _loadSettings() {
    final settings = Storage.getSettings();
    setState(() {
      _restNotificationEnabled = settings['restNotificationEnabled'] as bool? ?? true;
      _restVibrationEnabled = settings['restVibrationEnabled'] as bool? ?? true;
      _restSoundEnabled = settings['restSoundEnabled'] as bool? ?? true;
      _vibrationEnabled = settings['vibrationEnabled'] as bool? ?? true;
      _soundEnabled = settings['soundEnabled'] as bool? ?? true;
      _defaultRestTime = settings['defaultRestTime'] as int? ?? 90;
      _dailyTrainingEnabled =
          settings['dailyTrainingReminderEnabled'] as bool? ?? false;
      _trainingTime = settings['trainingTime'] as String? ?? '';
      _gymCardExpiryEnabled =
          settings['gymCardExpiryReminderEnabled'] as bool? ?? false;
      _expiryDaysThreshold =
          settings['gymCardExpiryDaysThreshold'] as int? ?? 7;
      _lowCountThreshold =
          settings['gymCardLowCountThreshold'] as int? ?? 3;
    });
  }
```

- [ ] **Step 3: 重构休息提醒卡片**

将 L81-L123 的休息提醒卡片替换为以下内容（主开关控制子项禁用 + 新增横幅引导入口）：

```dart
                  SectionHeader(title: '休息提醒'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: [
                        // 主开关：休息结束提醒
                        _buildSwitchTile(
                          colors,
                          icon: Icons.notifications_active_outlined,
                          title: '休息结束提醒',
                          subtitle: '组间休息倒计时结束时发送通知',
                          value: _restNotificationEnabled,
                          onChanged: (v) {
                            setState(() => _restNotificationEnabled = v);
                            _saveSetting('restNotificationEnabled', v);
                          },
                        ),
                        DividerWidget(indent: 44),
                        // 横幅通知引导（点击跳转引导页）
                        _buildBannerGuideTile(colors),
                        DividerWidget(indent: 44),
                        // 提示音（受主开关控制）
                        _buildSwitchTile(
                          colors,
                          icon: Icons.volume_up_outlined,
                          title: '提示音',
                          subtitle: '休息结束时播放提示音',
                          value: _restSoundEnabled,
                          onChanged: _restNotificationEnabled
                              ? (v) {
                                  setState(() => _restSoundEnabled = v);
                                  _saveSetting('restSoundEnabled', v);
                                }
                              : null,
                        ),
                        DividerWidget(indent: 44),
                        // 振动（受主开关控制）
                        _buildSwitchTile(
                          colors,
                          icon: Icons.vibration,
                          title: '振动提醒',
                          subtitle: '休息结束时振动提醒',
                          value: _restVibrationEnabled,
                          onChanged: _restNotificationEnabled
                              ? (v) {
                                  setState(() => _restVibrationEnabled = v);
                                  _saveSetting('restVibrationEnabled', v);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
```

- [ ] **Step 4: 新增 _buildBannerGuideTile 方法**

在 `_ReminderSettingsPageState` 类中新增：

```dart
  /// 横幅通知引导项
  Widget _buildBannerGuideTile(FitTrackColors colors) {
    return InkWell(
      onTap: () => context.push('/banner-notification-guide'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.notification_important_outlined, color: colors.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('横幅通知', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    '点击查看如何开启顶部横幅提醒',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 5: 验证无分析错误**

Run: `flutter analyze lib/pages/reminder_settings_page.dart`
Expected: No issues

- [ ] **Step 6: 提交**

```bash
git add lib/pages/reminder_settings_page.dart
git commit -m "feat: 休息提醒设置 UI 重构 + 横幅通知引导入口"
```

---

## Task 8: OhosReminderService 扩展健身卡提醒方法

**Files:**
- Modify: `lib/services/ohos_reminder_service.dart`（类末尾新增方法）

**Interfaces:**
- Produces: `OhosReminderService.instance.scheduleGymCardReminder()` / `cancelGymCardReminder()`

- [ ] **Step 1: 在 OhosReminderService 类末尾新增方法**

在 `cancelTrainingReminder` 方法之后（L172 附近），新增：

```dart
  /// 调度健身卡到期提醒（后台代理提醒）
  /// [dateStr] 格式 "YYYY-MM-DD"，提醒时间固定为当天 10:00
  Future<void> scheduleGymCardReminder({
    required String title,
    required String content,
    required String dateStr,
  }) async {
    if (!isOhos) return;
    try {
      await _channel.invokeMethod<void>('scheduleGymCardReminder', {
        'title': title,
        'content': content,
        'dateStr': dateStr,
      });
      debugPrint('[OhosReminder] scheduleGymCardReminder: $dateStr');
    } catch (e) {
      debugPrint('[OhosReminder] scheduleGymCardReminder error: $e');
    }
  }

  /// 取消健身卡到期提醒
  Future<void> cancelGymCardReminder() async {
    if (!isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelGymCardReminder');
      debugPrint('[OhosReminder] cancelGymCardReminder success');
    } catch (e) {
      debugPrint('[OhosReminder] cancelGymCardReminder error: $e');
    }
  }
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/services/ohos_reminder_service.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/services/ohos_reminder_service.dart
git commit -m "feat: OhosReminderService 新增健身卡到期提醒调度方法"
```

---

## Task 9: GymCardReminderService 新增 reschedule 方法

**Files:**
- Modify: `lib/services/gym_card_reminder_service.dart`

**Interfaces:**
- Consumes: `OhosReminderService.scheduleGymCardReminder()` 来自 Task 8；`Storage.getGymCards()`
- Produces: `GymCardReminderService.instance.reschedule()`

- [ ] **Step 1: 在 GymCardReminderService 类中新增 reschedule 方法**

在 `checkAndPush` 方法之后（L143 附近）新增。需要先在文件顶部新增 import：

```dart
import 'ohos_reminder_service.dart';
import 'notification_storage_service.dart';
```

然后新增方法：

```dart
  /// 重新调度健身卡到期提醒（后台代理提醒）
  ///
  /// 在以下场景调用：
  /// - 用户开启/关闭健身卡提醒开关
  /// - 用户修改阈值
  /// - 增删健身卡
  ///
  /// 策略：扫描所有卡，找出最近需要提醒的日期，用 OHOS 代理提醒调度。
  /// 只调度最近的一个提醒日（避免发布多个代理提醒）。
  /// 提醒时间固定为 10:00。
  Future<void> reschedule() async {
    if (!isOhos) {
      // 非 OHOS 平台：保留前台 checkAndPush 兜底，不做后台调度
      return;
    }

    try {
      // 1. 取消现有调度
      await OhosReminderService.instance.cancelGymCardReminder();

      // 2. 检查开关
      final settings = Storage.getSettings();
      final enabled =
          settings['gymCardExpiryReminderEnabled'] as bool? ?? false;
      if (!enabled) {
        debugPrint('[GymCardReminder] reschedule: 开关关闭，不调度');
        return;
      }

      // 3. 扫描所有卡，计算最近提醒日
      final daysThreshold =
          settings['gymCardExpiryDaysThreshold'] as int? ?? 7;
      final countThreshold =
          settings['gymCardLowCountThreshold'] as int? ?? 3;
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
          // 次卡总是今天提醒
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

      if (nearestDate == null || alertContent == null) {
        debugPrint('[GymCardReminder] reschedule: 无符合条件的卡');
        return;
      }

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
      debugPrint('[GymCardReminder] reschedule: 已调度到 $dateStr 10:00');
    } catch (e) {
      debugPrint('[GymCardReminder] reschedule error: $e');
    }
  }
```

- [ ] **Step 2: 在 checkAndPush 推送成功后同步写入 App 内通知系统**

在 `checkAndPush` 方法中，找到 `await _sendNotification(title, content);`（约 L130），在其后新增：

```dart
      // 同步写入 App 内通知系统
      NotificationStorageService.instance.addGymCardNotification(title, content);
```

- [ ] **Step 3: 验证无分析错误**

Run: `flutter analyze lib/services/gym_card_reminder_service.dart`
Expected: No issues

- [ ] **Step 4: 提交**

```bash
git add lib/services/gym_card_reminder_service.dart
git commit -m "feat: GymCardReminderService 新增 reschedule 后台调度 + 通知系统联动"
```

---

## Task 10: reminder_settings_page 健身卡开关联动 reschedule

**Files:**
- Modify: `lib/pages/reminder_settings_page.dart`（健身卡开关/阈值变更处）

**Interfaces:**
- Consumes: `GymCardReminderService.instance.reschedule()` 来自 Task 9

- [ ] **Step 1: 在 reminder_settings_page 中找到健身卡开关变更逻辑**

读取 `lib/pages/reminder_settings_page.dart` 中健身卡提醒相关部分（搜索 `gymCardExpiryEnabled`），找到开关 `onChanged` 和阈值变更处。

- [ ] **Step 2: 在开关和阈值变更时调用 reschedule**

在文件顶部新增 import：

```dart
import '../services/gym_card_reminder_service.dart';
```

在健身卡开关 `onChanged` 中，保存设置后调用 reschedule：

```dart
onChanged: (v) {
  setState(() => _gymCardExpiryEnabled = v);
  _saveSetting('gymCardExpiryReminderEnabled', v);
  // 重新调度后台提醒
  GymCardReminderService.instance.reschedule();
},
```

同样在阈值变更（天数滑块/次数滑块）的 `onChanged` 中，保存后调用 `GymCardReminderService.instance.reschedule()`。

- [ ] **Step 3: 验证无分析错误**

Run: `flutter analyze lib/pages/reminder_settings_page.dart`
Expected: No issues

- [ ] **Step 4: 提交**

```bash
git add lib/pages/reminder_settings_page.dart
git commit -m "feat: 健身卡提醒设置联动 reschedule 后台调度"
```

---

## Task 11: EntryAbility 原生实现 scheduleGymCardReminder

**Files:**
- Modify: `ohos/entry/src/main/ets/entryability/EntryAbility.ets`

**Interfaces:**
- Consumes: MethodChannel `scheduleGymCardReminder` / `cancelGymCardReminder` 来自 Flutter 侧
- Produces: 原生代理提醒发布到指定日期 10:00

- [ ] **Step 1: 在 EntryAbility 中新增 gymCardReminderId 字段**

在类字段区域（约 L226-L239 附近），新增：

```typescript
  // 健身卡到期提醒（代理提醒）ID，-1 表示未发布
  private gymCardReminderId: number = -1;
```

- [ ] **Step 2: 在 ReminderCallHandler 中新增方法分发**

读取 `EntryAbility.ets` 中的 `ReminderCallHandler` 类（搜索 `class ReminderCallHandler`），在 `onMethodCall` 的 switch/if 中新增：

```typescript
    } else if (call.method === 'scheduleGymCardReminder') {
      const args = call.args as Record<string, Object>;
      const title: string = (args['title'] as string) ?? '';
      const content: string = (args['content'] as string) ?? '';
      const dateStr: string = (args['dateStr'] as string) ?? '';
      this.ability.scheduleGymCardReminder(title, content, dateStr);
      result.success(null);
    } else if (call.method === 'cancelGymCardReminder') {
      this.ability.cancelGymCardReminder();
      result.success(null);
    }
```

- [ ] **Step 3: 在 EntryAbility 类中新增 scheduleGymCardReminder / cancelGymCardReminder 方法**

参考现有 `scheduleTrainingReminder` 方法的实现模式，新增：

```typescript
  /// 调度健身卡到期提醒（后台代理提醒）
  /// [dateStr] 格式 "YYYY-MM-DD"，提醒时间固定为当天 10:00
  scheduleGymCardReminder(title: string, content: string, dateStr: string): void {
    this.cancelGymCardReminder();

    // 解析 dateStr "YYYY-MM-DD"
    const parts: string[] = dateStr.split('-');
    const year: number = parseInt(parts[0], 10);
    const month: number = parseInt(parts[1], 10);
    const day: number = parseInt(parts[2], 10);

    const bundleInfo: bundleManager.BundleInfo =
      bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );

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

    reminderAgentManager.publishReminder(reminderRequest)
      .then((reminderId: number) => {
        this.gymCardReminderId = reminderId;
        console.info(`[FitTrack] 健身卡代理提醒发布成功, id=${reminderId}, date=${dateStr}`);
      })
      .catch((err: BusinessError) => {
        console.error(`[FitTrack] 健身卡代理提醒发布失败: code=${err.code}, msg=${err.message}`);
      });
  }

  /// 取消健身卡到期提醒
  cancelGymCardReminder(): void {
    if (this.gymCardReminderId >= 0) {
      reminderAgentManager.cancelReminder(this.gymCardReminderId)
        .then(() => {
          console.info(`[FitTrack] 健身卡代理提醒已取消, id=${this.gymCardReminderId}`);
        })
        .catch((err: BusinessError) => {
          console.error(`[FitTrack] 取消健身卡代理提醒失败: code=${err.code}, msg=${err.message}`);
        });
      this.gymCardReminderId = -1;
    }
  }
```

- [ ] **Step 4: 验证无 ArkTS 编译错误**

在 DevEco Studio 中构建 OHOS 模块，确认无编译错误。

- [ ] **Step 5: 提交**

```bash
git add ohos/entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "feat: EntryAbility 新增健身卡到期提醒代理提醒实现"
```

---

## Task 12: onNewWant 通知类型回调写入 App 内通知

**Files:**
- Modify: `ohos/entry/src/main/ets/entryability/EntryAbility.ets`（onNewWant 方法）
- Modify: `lib/services/ohos_reminder_service.dart`（onNotificationClick 回调处理）
- Modify: `lib/services/daily_reminder_service.dart`（wantAgent 增加 notificationType）

**Interfaces:**
- Consumes: `NotificationStorageService` 来自 Task 3

- [ ] **Step 1: 修改 onNewWant 解析 notificationType**

读取 `EntryAbility.ets` 的 `onNewWant` 方法（约 L267-L288），在现有逻辑中增加 `notificationType` 解析：

```typescript
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    try {
      let params: Record<string, Object> = want.parameters as Record<string, Object>;
      if (params !== null && params !== undefined) {
        let targetPage: string = this.getStringParam(params, 'targetPage');
        let cardAction: string = this.getStringParam(params, 'cardAction');
        let notificationType: string = this.getStringParam(params, 'notificationType');
        console.info('[FitTrack] onNewWant: targetPage=' + targetPage + ', cardAction=' + cardAction + ', notificationType=' + notificationType);

        // 通知类型回调：写入 App 内通知系统
        if (notificationType !== '') {
          const callbackParams: Record<string, Object> = {
            'notificationType': notificationType,
            'title': this.getStringParam(params, 'title'),
            'body': this.getStringParam(params, 'body'),
          };
          this.invokeFlutterMethod('onNotificationType', callbackParams);
        }

        if (cardAction === 'skipRest' || cardAction === 'resume') {
          this.invokeFlutterMethod('onCardClick', params);
        }
      }

      this.checkRestExpiredAndRefresh();
    } catch (e) {
      console.error('[FitTrack] onNewWant error: ' + e);
    }
  }
```

- [ ] **Step 2: 在 scheduleTrainingReminder 的 wantAgent 中增加 notificationType**

读取 `EntryAbility.ets` 中 `scheduleTrainingReminder` 方法，找到 `wantAgent` 配置，在其中增加 parameters。

由于 `MaxScreenWantAgent` 不支持 parameters，需改用 `WantAgent` 类型的 `wantAgent` 字段。参考现有 `scheduleRestReminder` 中的 wantAgent 实现方式。

在 wantAgent 的 wants[0].parameters 中增加：

```typescript
parameters: {
  'notificationType': 'daily_training',
  'title': title,
  'body': content,
}
```

- [ ] **Step 3: 在 scheduleGymCardReminder 的 wantAgent 中增加 notificationType**

同样在 Task 11 新增的 `scheduleGymCardReminder` 方法中，wantAgent 的 wants[0].parameters 增加：

```typescript
parameters: {
  'notificationType': 'gym_card',
  'title': title,
  'body': content,
}
```

注意：需要将 wantAgent 从 `MaxScreenWantAgent` 改为完整 `WantAgent` 类型（使用 `wantAgent.getWantAgent`）。

- [ ] **Step 4: 在 OhosReminderService 中处理 onNotificationType 回调**

在 `ohos_reminder_service.dart` 的 `initListener` 方法中，新增 case：

```dart
        case 'onNotificationType':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          debugPrint('[OhosReminder] Notification type callback: $args');
          _handleNotificationTypeCallback(args);
          break;
```

新增方法：

```dart
  /// 处理通知类型回调，写入 App 内通知系统
  void _handleNotificationTypeCallback(Map<String, dynamic> args) {
    final type = args['notificationType'] as String? ?? '';
    final title = args['title'] as String? ?? '';
    final body = args['body'] as String? ?? '';
    switch (type) {
      case 'gym_card':
        NotificationStorageService.instance.addGymCardNotification(title, body);
        break;
      case 'daily_training':
        NotificationStorageService.instance
            .addDailyTrainingNotification(title, body);
        break;
      case 'rest_end':
        NotificationStorageService.instance.addRestEndNotification(title, body);
        break;
      default:
        NotificationStorageService.instance.addSystemNotification(title, body);
    }
  }
```

在文件顶部新增 import：

```dart
import 'notification_storage_service.dart';
```

- [ ] **Step 5: 验证无分析错误**

Run: `flutter analyze lib/services/ohos_reminder_service.dart lib/services/daily_reminder_service.dart`
Expected: No issues

- [ ] **Step 6: 提交**

```bash
git add ohos/entry/src/main/ets/entryability/EntryAbility.ets lib/services/ohos_reminder_service.dart lib/services/daily_reminder_service.dart
git commit -m "feat: 通知触发后通过 onNewWant 回调写入 App 内通知系统"
```

---

## Task 13: 健身卡增删时调用 reschedule

**Files:**
- Modify: 健身卡管理页（需查找具体文件）

**Interfaces:**
- Consumes: `GymCardReminderService.instance.reschedule()` 来自 Task 9

- [ ] **Step 1: 查找健身卡管理页文件**

Run: 搜索包含 `getGymCards` / `addGymCard` / `deleteGymCard` 的页面文件

- [ ] **Step 2: 在增删健身卡后调用 reschedule**

在健身卡新增/删除/编辑成功后，调用：

```dart
GymCardReminderService.instance.reschedule();
```

- [ ] **Step 3: 验证无分析错误**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 4: 提交**

```bash
git add <修改的文件>
git commit -m "feat: 健身卡增删时联动 reschedule 后台提醒"
```

---

## Task 14: App 启动时调用 reschedule 兜底

**Files:**
- Modify: `lib/main.dart`（初始化逻辑）

**Interfaces:**
- Consumes: `GymCardReminderService.instance.reschedule()` 来自 Task 9

- [ ] **Step 1: 在 main.dart 初始化中调用 reschedule**

读取 `lib/main.dart`，找到 `Storage.init()` 和各服务初始化的位置，在 `GymCardReminderService.instance.init()` 之后新增：

```dart
// App 启动时重新调度健身卡提醒（兜底，确保代理提醒最新）
GymCardReminderService.instance.reschedule();
```

- [ ] **Step 2: 验证无分析错误**

Run: `flutter analyze lib/main.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/main.dart
git commit -m "feat: App 启动时兜底重新调度健身卡提醒"
```

---

## Task 15: 最终集成验证

**Files:**
- 无新文件改动，仅验证

- [ ] **Step 1: 全量 flutter analyze**

Run: `flutter analyze`
Expected: 无 error / warning（info 级别可接受）

- [ ] **Step 2: 手动测试 - 休息提醒设置**

1. 进入「设置 > 训练提醒」
2. 关闭「休息结束提醒」主开关 → 子项应禁用变灰
3. 点击「横幅通知」项 → 应跳转到横幅通知引导页
4. 引导页点击「去开启」→ 应跳转系统设置

- [ ] **Step 3: 手动测试 - App 内通知系统**

1. 在「我的」/「首页」点击通知入口 → 应弹出通知列表
2. 空列表显示「暂无通知」
3. 触发一次健身卡 checkAndPush → 通知列表应出现记录
4. 点击通知项 → 标记已读，红点消失
5. 点击「全部已读」/「清空」→ 验证功能

- [ ] **Step 4: 手动测试 - 健身卡后台提醒（OHOS 真机）**

1. 添加一张期限卡，到期日为明天，阈值 7 天
2. 开启健身卡提醒 → 查看日志应出现 `reschedule: 已调度到 YYYY-MM-DD 10:00`
3. 添加一张次卡，剩余次数 2，阈值 3 → reschedule 应调度今天
4. 删除所有健身卡 → reschedule 应取消现有提醒
5. （可选）等待到 10:00 验证系统通知 + App 内通知记录

- [ ] **Step 5: 回归测试**

1. 训练完成时的振动/提示音不受影响
2. 桌面卡片状态切换不受影响
3. 休息结束代理提醒不受影响
4. 每日训练提醒正常触发

- [ ] **Step 6: 最终提交（如有修复）**

```bash
git add -A
git commit -m "test: 集成验证通过"
```
