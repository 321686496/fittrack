import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/storage.dart';
import '../utils/platform_utils.dart';
import 'ohos_reminder_service.dart';

/// 每日训练提醒调度服务
///
/// 根据用户设置（开关 + trainingTime "HH:mm"）调度每日重复提醒：
/// - Android/iOS：使用 flutter_local_notifications 的 zonedSchedule（每日重复）
/// - OHOS：调用 OhosReminderService.scheduleTrainingReminder()，由原生代理提醒实现
///
/// 调度时机：
/// - App 启动时（main.dart）
/// - 设置页开关/时间变更时（reminder_settings_page / profile_page）
class DailyReminderService {
  DailyReminderService._();

  static final DailyReminderService instance = DailyReminderService._();

  static const String _channelId = 'daily_training_channel';
  static const String _channelName = '每日训练提醒';
  static const String _channelDesc = '每日定时训练提醒通知';
  static const int _notificationId = 3001;

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// 初始化（应用启动时调用一次，幂等）
  Future<void> init() async {
    if (_initialized) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();

      // 创建 Android 通知渠道（独立于休息提醒渠道）
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

      _initialized = true;
      debugPrint('[DailyReminder] initialized');

      // 初始化完成后立即按当前设置调度
      await reschedule();
    } catch (e) {
      debugPrint('[DailyReminder] init() error: $e');
    }
  }

  /// 根据当前设置重新调度（开关或时间变更后调用）
  ///
  /// - 开关关闭或时间为空：取消所有已调度提醒
  /// - 开关打开且时间有效：取消旧提醒，按新时间调度
  Future<void> reschedule() async {
    if (!_initialized) {
      await init();
      return;
    }
    try {
      final settings = Storage.getSettings();
      final enabled =
          settings['dailyTrainingReminderEnabled'] as bool? ?? false;
      final timeStr = settings['trainingTime'] as String? ?? '';

      // 先取消现有调度
      await cancel();

      if (!enabled) {
        debugPrint('[DailyReminder] disabled, cancelled all');
        return;
      }
      if (timeStr.isEmpty || !timeStr.contains(':')) {
        debugPrint('[DailyReminder] enabled but no time set, skip scheduling');
        return;
      }

      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 18;
      final minute = int.tryParse(parts[1]) ?? 0;

      if (isOhos) {
        // OHOS：调用原生代理提醒（每日重复由原生侧实现）
        await OhosReminderService.instance.scheduleTrainingReminder(
          title: '训练时间到',
          content: '今天也要坚持训练哦，开始你的训练吧！',
          timeStr: timeStr,
        );
        debugPrint('[DailyReminder] OHOS scheduled at $timeStr');
      } else {
        // Android/iOS：使用 zonedSchedule 每日重复
        await _scheduleDailyAt(hour, minute);
        debugPrint('[DailyReminder] Android scheduled at $hour:$minute');
      }
    } catch (e) {
      debugPrint('[DailyReminder] reschedule() error: $e');
    }
  }

  /// Android/iOS：使用 flutter_local_notifications 调度每日重复通知
  Future<void> _scheduleDailyAt(int hour, int minute) async {
    if (_plugin == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // 若时间已过，推到明天
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
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

    await _plugin!.zonedSchedule(
      _notificationId,
      '训练时间到',
      '今天也要坚持训练哦，开始你的训练吧！',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 每日按时间重复
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 取消所有每日训练提醒
  Future<void> cancel() async {
    try {
      if (isOhos) {
        await OhosReminderService.instance.cancelTrainingReminder();
      } else {
        await _plugin?.cancel(_notificationId);
      }
    } catch (e) {
      debugPrint('[DailyReminder] cancel() error: $e');
    }
  }
}
