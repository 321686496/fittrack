import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'platform/platform_services.dart';
import 'platform/implementations/ohos_rest_reminder_service.dart';
import 'sound_service.dart';

/// 休息结束提醒服务
///
/// 提供振动提醒 + 本地通知 + 后台代理提醒 三重机制：
/// - 前台：Dart Timer 倒计时 → 振动 + show() 通知
/// - OHOS后台：reminderAgentManager 代理提醒（系统级定时，后台也能触发）
/// - Android后台：AlarmManager + BroadcastReceiver（系统级定时，应用被杀后仍能触发）
/// - 后台恢复兜底：由 training_page 的 wall-clock 机制检测并补发通知
class RestNotificationService {
  RestNotificationService._();

  static final RestNotificationService instance = RestNotificationService._();

  static const String _channelId = 'rest_channel';
  static const String _channelName = '训练休息提醒';
  static const String _channelDesc = '组间休息结束时的提醒通知';
  static const int _notificationId = 1001;

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// Dart 侧定时器（OHOS 和 Android 通用，前台倒计时用）
  Timer? _dartScheduleTimer;

  /// 获取插件实例（用于测试）
  FlutterLocalNotificationsPlugin? get plugin => _plugin;

  /// 检查是否已初始化
  bool get isInitialized => _initialized;

  /// 初始化通知渠道（应用启动时调用一次）
  Future<void> init() async {
    if (_initialized) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // OHOS 平台：不初始化 flutter_local_notifications，避免插件自动创建带进度条的通知
      // OHOS 的通知由 EntryAbility 原生侧的 LiveView 和 reminderAgentManager 处理
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 创建 Android 通知渠道
      await _plugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            enableVibration: true,
          ));

      await _configureLocalTimeZone();
      await _requestNotificationPermission();

      // 平台服务由 PlatformServices.init() 统一初始化，此处不再重复

      _initialized = true;
      debugPrint('RestNotificationService initialized successfully');
    } catch (e) {
      debugPrint('RestNotificationService.init() error: $e');
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      // OHOS 平台：跳过 flutter_local_notifications 权限请求，避免触发系统通知
      // OHOS 的通知权限由原生 EntryAbility 处理
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
    } catch (e) {
      debugPrint('Request notification permission error: $e');
    }
    return false;
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    try {
      if (PlatformServices.restReminder is OhosRestReminderService) {
        final String timeZoneName = await _plugin!.getLocalTimezone();
        debugPrint('OHOS timezone: $timeZoneName');
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Timezone config error: $e, using Asia/Shanghai');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } catch (_) {}
    }
  }

  /// 休息结束时的增强振动提醒
  static Future<void> vibrate() async {
    try {
      for (int i = 0; i < 3; i++) {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (_) {}
    try {
      await SystemChannels.platform.invokeMethod<void>('HapticFeedback.vibrate');
    } catch (_) {}
  }

  /// 预约定时通知：在 [delaySeconds] 秒后发送休息结束通知
  ///
  /// - Android: 使用原生 AlarmManager + BroadcastReceiver（应用被杀后仍能触发）+ Dart Timer 保底
  /// - OHOS: 使用 reminderAgentManager 代理提醒（后台也能触发）+ Dart Timer 保底
  Future<void> scheduleRestEndNotification({
    required String exerciseName,
    required int delaySeconds,
  }) async {
    if (!_initialized || _plugin == null) {
      debugPrint('Cannot schedule: not initialized');
      return;
    }
    try {
      await cancelScheduledNotification();

      final title = '休息结束';
      final content = '$exerciseName 的休息时间已结束，开始下一组训练吧！';

      // 所有平台：Dart Timer 保底（前台有效）
      _scheduleWithDartTimer(exerciseName: exerciseName, delaySeconds: delaySeconds);

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
    } catch (e) {
      debugPrint('scheduleRestEndNotification() error: $e');
    }
  }

  /// Dart Timer 延迟后调用 show()
  void _scheduleWithDartTimer({
    required String exerciseName,
    required int delaySeconds,
  }) {
    _dartScheduleTimer?.cancel();
    debugPrint('Dart Timer scheduled: ${delaySeconds}s');
    _dartScheduleTimer = Timer(Duration(seconds: delaySeconds), () async {
      debugPrint('Dart Timer fired');
      await showRestEndNotification(exerciseName: exerciseName);
      _dartScheduleTimer = null;
    });
  }

  /// 立即显示休息结束通知
  Future<void> showRestEndNotification({required String exerciseName}) async {
    if (!_initialized || _plugin == null) return;
    SoundService.instance.play(SoundType.restEnd);
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        fullScreenIntent: true,
      );
      const ohosDetails = OhosNotificationDetails(
        OhosNotificationSlotType.SOCIAL_COMMUNICATION,
        slotDesc: _channelDesc,
        importance: OhosImportance.high,
        enableVibration: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        ohos: ohosDetails,
      );

      await _plugin!.show(
        _notificationId,
        '休息结束',
        '$exerciseName 的休息时间已结束，开始下一组训练吧！',
        details,
      );
      debugPrint('showRestEndNotification() success');
    } catch (e) {
      debugPrint('showRestEndNotification() error: $e');
    }
  }

  /// 取消预约的定时通知
  Future<void> cancelScheduledNotification() async {
    _dartScheduleTimer?.cancel();
    _dartScheduleTimer = null;
    try {
      await _plugin?.cancel(_notificationId);
    } catch (_) {}
    // 同时取消 OHOS 代理提醒 或 Android 原生闹钟
    await PlatformServices.restReminder.cancelCurrentReminder();
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    _dartScheduleTimer?.cancel();
    _dartScheduleTimer = null;
    try {
      await _plugin?.cancelAll();
    } catch (_) {}
    // 同时取消 OHOS 所有代理提醒 或 Android 原生闹钟
    await PlatformServices.restReminder.cancelAllReminders();
  }
}
