import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/storage.dart';
import '../utils/platform_utils.dart';
import 'notification_storage_service.dart';
import 'ohos_reminder_service.dart';
import 'reminder_schedule_calculator.dart';

/// 每日训练提醒调度服务
///
/// 根据用户设置（开关 + trainingTime "HH:mm"）调度每日重复提醒：
/// - Android/iOS：使用 flutter_local_notifications 的 zonedSchedule（每日重复）
/// - OHOS：调用 OhosReminderService.scheduleTrainingReminder()，由原生代理提醒实现
///
/// 调度时机：
/// - App 启动时（main.dart）
/// - 设置页开关/时间变更时（reminder_settings_page / profile_page / questionnaire_page）
/// - App 回到前台时（main.dart didChangeAppLifecycleState）
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

      if (!isOhos) {
        // 必须同时提供 Android 与 iOS/macOS 初始化设置，否则在 iOS 上
        // initialize() 会抛 ArgumentError，导致 _initialized 永远为 false，
        // 之后所有 reschedule() 都会静默失效（每日训练提醒在 iOS 上从不调度）。
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

  /// Android 13+ 通知权限、Android 12+ 精确闹钟权限、iOS alert/badge/sound 权限
  Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        // 精确闹钟权限拿不到时由 _scheduleDailyAt 自动降级为 inexact
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
      debugPrint('[DailyReminder] request permissions error: $e');
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
        final ok = await OhosReminderService.instance.scheduleTrainingReminder(
          title: '训练时间到',
          content: '今天也要坚持训练哦，开始你的训练吧！',
          timeStr: timeStr,
        );
        debugPrint('[DailyReminder] OHOS scheduled at $timeStr -> $ok');
      } else {
        // Android/iOS：使用 zonedSchedule 每日重复
        await _scheduleDailyAt(hour, minute);
        debugPrint('[DailyReminder] scheduled at $hour:$minute');
      }
    } catch (e) {
      debugPrint('[DailyReminder] reschedule() error: $e');
    }
  }

  /// Android/iOS：使用 flutter_local_notifications 调度每日重复通知
  Future<void> _scheduleDailyAt(int hour, int minute) async {
    if (_plugin == null) return;

    final now = DateTime.now();
    final next =
        nextDailyReminder(now, hour, minute);
    final scheduled = tz.TZDateTime(
      tz.local,
      next.year,
      next.month,
      next.day,
      next.hour,
      next.minute,
      next.second,
    );

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
    } on PlatformException {
      // Android 12+ 用户可能拒绝精确闹钟权限（exactAllowWhileIdle 会抛
      // ExactAlarmPermissionException）。降级为 inexactAllowWhileIdle，
      // 避免静默失败导致通知完全不触发。
      debugPrint(
          '[DailyReminder] 精确闹钟不可用，降级为 inexactAllowWhileIdle 调度');
      await _plugin!.zonedSchedule(
        _notificationId,
        '训练时间到',
        '今天也要坚持训练哦，开始你的训练吧！',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
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

  /// 检查今日训练提醒是否已触发，如已触发则写入 App 内通知系统
  ///
  /// 由于 MaxScreenWantAgent 不支持 parameters 字段，无法通过 wantAgent 传递
  /// notificationType，因此在 App 回到前台时检查今日训练时间是否已过，
  /// 若已过且当日尚未写入通知记录，则补写一条 App 内通知。
  Future<void> checkAndRecordNotification() async {
    try {
      final settings = Storage.getSettings();
      final enabled =
          settings['dailyTrainingReminderEnabled'] as bool? ?? false;
      if (!enabled) return;

      final trainingTime = settings['trainingTime'] as String? ?? '';
      if (trainingTime.isEmpty) return;

      // 防同日重复
      final today = _todayStr();
      final lastRecorded =
          settings['lastDailyNotificationDate'] as String? ?? '';
      if (lastRecorded == today) return;

      // 检查今日训练时间是否已过
      final parts = trainingTime.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final now = DateTime.now();
      final scheduledTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      if (now.isAfter(scheduledTime)) {
        // 训练时间已过，写入通知记录
        NotificationStorageService.instance.addDailyTrainingNotification(
          '训练提醒',
          '今天是你的训练日，准备好了吗？',
        );
        // 记录今日已写入
        final s = Storage.getSettings();
        s['lastDailyNotificationDate'] = today;
        Storage.saveSettings(s);
        debugPrint('[DailyReminder] 已写入 App 内通知记录');
      }
    } catch (e) {
      debugPrint('[DailyReminder] checkAndRecordNotification error: $e');
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
