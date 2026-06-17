import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// 休息结束提醒服务
///
/// 提供振动提醒 + 本地通知双重机制：
/// - 前台：Dart Timer 倒计时 → 振动 + show() 通知
/// - 后台恢复：由 training_page 的 wall-clock 机制检测并补发通知
///
/// OHOS 平台限制：
/// - zonedSchedule 底层使用 reminderAgentManager，需要 system_core 权限，
///   普通应用无法使用，因此 OHOS 上不使用 zonedSchedule
/// - Dart Timer 在后台被系统挂起，无法触发
/// - 后台场景依赖 training_page 恢复前台时的 wall-clock 检测
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

      const ohosSettings = OhosInitializationSettings('app_icon');

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        ohos: ohosSettings,
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

      _initialized = true;
      debugPrint('RestNotificationService initialized successfully');
    } catch (e) {
      debugPrint('RestNotificationService.init() error: $e');
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      if (Platform.isOhos) {
        final ohosPlugin = _plugin!.resolvePlatformSpecificImplementation<
            OhosFlutterLocalNotificationsPlugin>();
        if (ohosPlugin != null) {
          final result = await ohosPlugin.requestNotificationsPermission();
          debugPrint('OHOS notification permission: $result');
          return result ?? false;
        }
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
      if (Platform.isOhos) {
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
  /// - Android: 使用 zonedSchedule（系统级定时，后台也能触发）+ Dart Timer 保底
  /// - OHOS: 仅使用 Dart Timer（前台有效），后台恢复由 training_page wall-clock 补发
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

      // 所有平台：Dart Timer 保底（前台有效）
      _scheduleWithDartTimer(exerciseName: exerciseName, delaySeconds: delaySeconds);

      // Android：额外使用 zonedSchedule（后台也能触发）
      if (!Platform.isOhos) {
        final scheduledDate =
            tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

        const androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          fullScreenIntent: true,
        );
        const details = NotificationDetails(android: androidDetails);

        await _plugin!.zonedSchedule(
          _notificationId,
          '休息结束',
          '$exerciseName 的休息时间已结束，开始下一组训练吧！',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Android zonedSchedule set');
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
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    _dartScheduleTimer?.cancel();
    _dartScheduleTimer = null;
    try {
      await _plugin?.cancelAll();
    } catch (_) {}
  }
}
