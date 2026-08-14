import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/storage.dart';
import '../utils/platform_utils.dart';
import 'notification_storage_service.dart';
import 'ohos_reminder_service.dart';
import 'reminder_schedule_calculator.dart';

/// 健身卡到期提醒服务
///
/// 在 App 启动 / 回到前台时检查所有健身卡，根据用户配置的阈值
/// （期限卡剩余天数、次卡剩余次数）判断是否需要推送提醒。
///
/// 推送策略：
/// - 同一 天最多推送一次（lastGymCardReminderDate 防重复）
/// - 多张卡同时满足条件时合并为一条通知
/// - 后台定时提醒：每张符合条件的卡各调度一个一次性提醒
///   （不再只取“最近的一张”，避免一次触发后后续提醒全部丢失）
///
/// 注意：后台定时提醒依赖系统级能力（OHOS 代理提醒 / Android 闹钟 / iOS 本地通知），
/// 若应用被强制停止，系统可能清除已调度的提醒；回到前台时会重新评估并补调度。
class GymCardReminderService {
  GymCardReminderService._();

  static final GymCardReminderService instance = GymCardReminderService._();

  static const String _channelId = 'gym_card_expiry_channel';
  static const String _channelName = '健身卡到期提醒';
  static const String _channelDesc = '健身卡即将到期或次数不足的提醒';
  static const int _notificationId = 4001; // checkAndPush 即时通知 ID
  static const int _scheduledBaseId = 5000; // 后台一次性提醒起始 ID
  static const int _maxScheduledCards = 20; // 上限，避免 ID 溢出 / 提醒数量超限

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// 当前已调度的后台一次性提醒 ID（用于统一取消）
  final Set<int> _scheduledIds = <int>{};

  /// 初始化（应用启动时调用一次，幂等）
  Future<void> init() async {
    if (_initialized) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();

      if (!isOhos) {
        // 必须同时提供 Android 与 iOS/macOS 初始化设置，否则在 iOS 上
        // initialize() 会抛 ArgumentError，导致本服务在 iOS 上完全无法调度。
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinSettings = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        );
        await _plugin!.initialize(initSettings);

        await _requestPermissions();
      }

      // OHOS 平台跳过渠道创建（由原生侧统一管理），仅 Android 创建
      if (!isOhos) {
        await _plugin
            ?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
              enableVibration: true,
            ));
      }

      _initialized = true;
      debugPrint('[GymCardReminder] initialized');
    } catch (e) {
      debugPrint('[GymCardReminder] init() error: $e');
    }
  }

  /// Android 13+ 通知权限、Android 12+ 精确闹钟权限、iOS alert/badge/sound 权限
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (_) {}
        return;
      }
      final iosPlugin = _plugin!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('[GymCardReminder] request permissions error: $e');
    }
  }

  /// 检查并推送（启动时 / 回到前台时调用）
  ///
  /// 返回 true 表示本次触发了推送，false 表示未推送
  /// （开关关闭 / 今天已推 / 无符合条件的卡）。
  Future<bool> checkAndPush() async {
    if (!_initialized) {
      await init();
    }
    try {
      final settings = Storage.getSettings();
      final enabled =
          settings['gymCardExpiryReminderEnabled'] as bool? ?? false;
      if (!enabled) {
        return false;
      }

      // 防同日重复
      final today = _todayStr();
      final lastPushed = settings['lastGymCardReminderDate'] as String? ?? '';
      if (lastPushed == today) {
        return false;
      }

      final daysThreshold =
          settings['gymCardExpiryDaysThreshold'] as int? ?? 7;
      final countThreshold =
          settings['gymCardLowCountThreshold'] as int? ?? 3;

      final cards = Storage.getGymCards();
      final alerts = <String>[];

      for (final card in cards) {
        final name = card['name'] as String? ?? '未命名卡';
        final cardType = card['cardType'] as String? ?? '';
        final endDate = card['endDate'] as int? ?? 0;
        final remaining = card['remainingCount'] as int? ?? -1;

        // 次卡：剩余次数 <= 阈值
        if (cardType == '次卡' &&
            remaining >= 0 &&
            remaining <= countThreshold) {
          if (remaining == 0) {
            alerts.add('「$name」已用完所有次数');
          } else {
            alerts.add('「$name」仅剩 $remaining 次');
          }
          continue;
        }

        // 期限卡：剩余天数 <= 阈值（含已过期）
        if (endDate > 0) {
          final end = DateTime.fromMillisecondsSinceEpoch(endDate);
          final now = DateTime.now();
          final diff = end.difference(now).inDays;
          if (diff < 0) {
            alerts.add('「$name」已过期 ${-diff} 天');
          } else if (diff == 0) {
            alerts.add('「$name」今天到期');
          } else if (diff <= daysThreshold) {
            alerts.add('「$name」还有 $diff 天到期');
          }
        }
      }

      if (alerts.isEmpty) {
        return false;
      }

      // 合并推送（最多展示前 3 条，避免通知过长）
      final display = alerts.take(3).join('，');
      final suffix = alerts.length > 3 ? ' 等 ${alerts.length} 张' : '';
      const title = '健身卡提醒';
      final content = '$display$suffix，请及时续卡';

      await _sendNotification(title, content);

      // 同步写入 App 内通知系统
      NotificationStorageService.instance
          .addGymCardNotification(title, content);

      // 记录今日已推送
      final s = Storage.getSettings();
      s['lastGymCardReminderDate'] = today;
      Storage.saveSettings(s);

      debugPrint('[GymCardReminder] pushed: $alerts');
      return true;
    } catch (e) {
      debugPrint('[GymCardReminder] checkAndPush() error: $e');
      return false;
    }
  }

  /// 重新调度健身卡到期提醒（后台定时提醒）
  ///
  /// 在以下场景调用：
  /// - 用户开启/关闭健身卡提醒开关
  /// - 用户修改阈值
  /// - 增删改健身卡、扣减次数
  /// - App 启动 / 回到前台（main.dart）
  ///
  /// 策略：扫描所有卡，为每张符合条件的卡各调度一个一次性提醒
  /// （期限卡 = 到期日 - 阈值天；次卡 = 今天），提醒时间固定为 10:00。
  /// - OHOS：使用代理提醒（reminderAgentManager，系统级调度，应用被杀也能触发）
  /// - Android：使用 flutter_local_notifications zonedSchedule 一次性调度
  /// - iOS：使用 flutter_local_notifications zonedSchedule 一次性调度
  Future<void> reschedule() async {
    if (!_initialized) {
      await init();
    }
    try {
      // 1. 取消现有调度
      await cancelScheduled();

      // 2. 检查开关
      final settings = Storage.getSettings();
      final enabled =
          settings['gymCardExpiryReminderEnabled'] as bool? ?? false;
      if (!enabled) {
        debugPrint('[GymCardReminder] reschedule: 开关关闭，不调度');
        return;
      }

      // 3. 扫描所有卡，生成每张卡的提醒候选
      final daysThreshold =
          settings['gymCardExpiryDaysThreshold'] as int? ?? 7;
      final countThreshold =
          settings['gymCardLowCountThreshold'] as int? ?? 3;
      final cards = Storage.getGymCards();
      final candidates = computeGymCardCandidates(
        cards: cards,
        daysThreshold: daysThreshold,
        countThreshold: countThreshold,
        now: DateTime.now(),
      );

      if (candidates.isEmpty) {
        debugPrint('[GymCardReminder] reschedule: 无符合条件的卡');
        return;
      }

      const title = '健身卡提醒';
      final limited = candidates.take(_maxScheduledCards).toList();

      if (isOhos) {
        // 4. OHOS：格式化日期为 "YYYY-MM-DD"，为每张卡调度代理提醒
        for (var i = 0; i < limited.length; i++) {
          final candidate = limited[i];
          final dateStr = '${candidate.remindDate.year}-'
              '${candidate.remindDate.month.toString().padLeft(2, '0')}-'
              '${candidate.remindDate.day.toString().padLeft(2, '0')}';
          final ok = await OhosReminderService.instance.scheduleGymCardReminder(
            title: title,
            content: candidate.content,
            dateStr: dateStr,
            notificationId: _scheduledBaseId + i,
          );
          debugPrint(
              '[GymCardReminder] reschedule: OHOS #$i -> $dateStr 10:00, ok=$ok');
        }
      } else {
        // 5. Android/iOS：为每张卡调度一次性 zonedSchedule
        for (var i = 0; i < limited.length; i++) {
          final candidate = limited[i];
          final notificationId = _scheduledBaseId + i;
          await _scheduleAndroidOneShot(
            title,
            candidate.content,
            candidate.remindDate,
            notificationId,
          );
          _scheduledIds.add(notificationId);
        }
      }
    } catch (e) {
      debugPrint('[GymCardReminder] reschedule error: $e');
    }
  }

  /// Android/iOS：调度一次性健身卡到期提醒（提醒日 10:00）
  ///
  /// 若目标时间已过（如提醒日=今天且已过 10:00），顺延到 1 分钟后提醒，
  /// 确保提醒日当天仍能收到提醒。
  Future<void> _scheduleAndroidOneShot(
    String title,
    String content,
    DateTime remindDate,
    int notificationId,
  ) async {
    if (_plugin == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      remindDate.year,
      remindDate.month,
      remindDate.day,
      10,
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = now.add(const Duration(minutes: 1));
      debugPrint('[GymCardReminder] 提醒日 10:00 已过，顺延到 1 分钟后提醒');
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin!.zonedSchedule(
        notificationId,
        title,
        content,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null, // 一次性提醒
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[GymCardReminder] Android #$notificationId 已调度到 $scheduled');
    } on PlatformException {
      // 精确闹钟权限不可用时降级为 inexact，避免静默失败
      debugPrint('[GymCardReminder] 精确闹钟不可用，降级为 inexactAllowWhileIdle');
      await _plugin!.zonedSchedule(
        notificationId,
        title,
        content,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 取消所有后台一次性提醒（含即时通知 ID）
  Future<void> cancel() async {
    await cancelScheduled();
    try {
      await _plugin?.cancel(_notificationId);
    } catch (e) {
      debugPrint('[GymCardReminder] cancel() error: $e');
    }
  }

  /// 取消已调度的后台一次性提醒
  Future<void> cancelScheduled() async {
    try {
      if (isOhos) {
        await OhosReminderService.instance.cancelGymCardReminder();
      } else if (_plugin != null) {
        // 取消本轮所有已调度 ID + 之前可能遗留的 ID 区间，保证幂等
        final ids = <int>{
          ..._scheduledIds,
          for (var i = 0; i < _maxScheduledCards; i++) _scheduledBaseId + i,
        };
        for (final id in ids) {
          try {
            await _plugin!.cancel(id);
          } catch (_) {}
        }
        _scheduledIds.clear();
      }
    } catch (e) {
      debugPrint('[GymCardReminder] cancelScheduled() error: $e');
    }
  }

  Future<void> _sendNotification(String title, String content) async {
    if (_plugin == null) return;
    try {
      if (isOhos) {
        // OHOS：使用 flutter_local_notifications（OHOS fork 版本支持 OhosNotificationDetails）
        const ohosDetails = OhosNotificationDetails(
          OhosNotificationSlotType.SOCIAL_COMMUNICATION,
          slotDesc: _channelDesc,
          importance: OhosImportance.high,
          enableVibration: true,
        );
        const details = NotificationDetails(ohos: ohosDetails);
        await _plugin!.show(_notificationId, title, content, details);
      } else {
        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        );
        const details = NotificationDetails(android: androidDetails);
        await _plugin!.show(_notificationId, title, content, details);
      }
    } catch (e) {
      debugPrint('[GymCardReminder] _sendNotification() error: $e');
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
