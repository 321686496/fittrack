import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/storage.dart';
import '../utils/platform_utils.dart';
import 'ohos_reminder_service.dart';

class SmartPushService {
  static final SmartPushService instance = SmartPushService._();
  SmartPushService._();

  static const int _maxPushPer7Days = 2;
  static const int _notificationId = 2001;

  Future<void> init() async {
    // 调度每日 20:00 检查（Android/iOS 本地定时；OHOS 依赖前台触发）
    await scheduleDailyCheck();
  }

  bool shouldPushNow() {
    final s = Storage.getSettings();
    if (!(s['smartPushEnabled'] ?? true)) return false;
    // 7 天滚动窗口：若距上次推送已 ≥ 7 天，重置计数器
    final lastPushDateStr = s['lastPushDate'] as String? ?? '';
    if (lastPushDateStr.isNotEmpty) {
      try {
        final lastPush = DateTime.parse(lastPushDateStr);
        final daysSince = DateTime.now().difference(lastPush).inDays;
        if (daysSince >= 7 && (s['pushCountIn7Days'] ?? 0) > 0) {
          s['pushCountIn7Days'] = 0;
          Storage.saveSettings(s);
        }
      } catch (_) {
        // 解析失败：忽略（不影响其他检查）
      }
    }
    if ((s['pushCountIn7Days'] ?? 0) >= _maxPushPer7Days) return false;
    if (lastPushDateStr == Storage.getTodayStr()) return false;
    return true;
  }

  Future<void> scheduleDailyCheck() async {
    // 每天 20:00 推送一次"今日未训练"提醒：
    // - 开关关闭 / 7 天窗口已满 / 今天已训练 → 取消调度
    // - 一次性调度（不每日重复），App 每次启动/回前台/训练完成时重新评估下一天，
    //   从而保持"7 天最多 2 次"限频语义
    try {
      final s = Storage.getSettings();
      final enabled = s['smartPushEnabled'] ?? true;
      if (!enabled) {
        await _cancelScheduled();
        return;
      }
      if (_trainedToday(Storage.getRecords())) {
        await _cancelScheduled();
        return;
      }
      // 7 天窗口已满或今天已推送 → 取消本次调度
      if (!shouldPushNow()) {
        await _cancelScheduled();
        return;
      }

      if (isOhos) {
        // OHOS：原生倒计时代理提醒（20:00 触发一次，持续由 App 重新调度保证）
        await OhosReminderService.instance.scheduleSmartPushReminder(
          title: 'LiftTrack 提醒',
          content: '今天还没有训练，来一组保持节奏！',
          timeStr: '20:00',
        );
        return;
      }

      final now = DateTime.now();
      var target = DateTime(now.year, now.month, now.day, 20, 0);
      final lastPush = s['lastPushDate'] as String? ?? '';
      if (!now.isBefore(target) || lastPush == Storage.getTodayStr()) {
        target = target.add(const Duration(days: 1));
      }
      await _scheduleAt(target, '今天还没有训练，来一组保持节奏！');
    } catch (e) {
      debugPrint('[SmartPush] scheduleDailyCheck error: $e');
    }
  }

  bool _trainedToday(List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    final todayMidnight =
        DateTime(now.year, now.month, now.day);
    return records.any((r) {
      final ts = r['date'] as int? ?? 0;
      return ts >= todayMidnight.millisecondsSinceEpoch;
    });
  }

  /// Android/iOS：调度一次 20:00 提醒（inexact，兼容无精确闹钟权限）
  Future<void> _scheduleAt(DateTime target, String message) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'smart_push_channel',
        '智能训练提醒',
        channelDescription: '每日 20:00 的智能训练提醒',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final scheduled = tz.TZDateTime.from(target, tz.local);
    try {
      await plugin.zonedSchedule(
        _notificationId,
        'LiftTrack 提醒',
        message,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[SmartPush] scheduled at $target');
    } on PlatformException {
      debugPrint('[SmartPush] schedule failed, skip');
    }
  }

  Future<void> _cancelScheduled() async {
    try {
      if (isOhos) {
        await OhosReminderService.instance.cancelSmartPushReminder();
        return;
      }
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(_notificationId);
    } catch (e) {
      debugPrint('[SmartPush] cancel scheduled error: $e');
    }
  }

  Future<void> maybePushNow() async {
    if (!shouldPushNow()) return;
    final records = Storage.getRecords();
    final strategy = _decideStrategy(records);
    if (strategy == _PushStrategy.none) return;
    await _sendPush(strategy.message);
    final s = Storage.getSettings();
    s['lastPushDate'] = Storage.getTodayStr();
    s['pushCountIn7Days'] = (s['pushCountIn7Days'] ?? 0) + 1;
    await Storage.saveSettings(s);
  }

  _PushStrategy _decideStrategy(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return _PushStrategy.none;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final todayRecords = records.where((r) {
      final ts = r['date'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(ts)
              .isAfter(todayMidnight.subtract(const Duration(seconds: 1)));
    });
    if (todayRecords.isNotEmpty) return _PushStrategy.none; // already trained today

    // Check 3-day gap
    final lastTs = records.first['date'] as int? ?? 0;
    if (lastTs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastTs);
      if (today.difference(last).inDays >= 3) return _PushStrategy.none;
    }

    // Check streak >= 7
    final streak = _computeStreak(records);
    if (streak >= 7) {
      return _PushStrategy(
        message: '你的训练日历有 $streak 个连续方块，今天别断！',
      );
    }
    return _PushStrategy(message: '今天是你的训练日，准备好了吗？');
  }

  int _computeStreak(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final dates = records
        .map((r) => DateTime.fromMillisecondsSinceEpoch(r['date'] as int? ?? 0))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _sendPush(String message) async {
    if (isOhos) {
      // OHOS：前台兜底立即推送
      await OhosReminderService.instance.publishSmartPushNow(
        title: 'LiftTrack 提醒',
        content: message,
      );
      return;
    }
    // Android/iOS: use flutter_local_notifications directly
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      _notificationId,
      'LiftTrack 提醒',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_push_channel',
          '智能训练提醒',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> onTrainingCompleted() async {
    // Reset today's push avoidance
    final s = Storage.getSettings();
    s['lastPushDate'] = Storage.getTodayStr();
    await Storage.saveSettings(s);
    // 训练完成后重新评估每日调度（今天已训练 → 取消 20:00 提醒）
    await scheduleDailyCheck();
  }
}

class _PushStrategy {
  final String message;
  const _PushStrategy({required this.message});
  static const none = _PushStrategy(message: '');
  bool get shouldPush => message.isNotEmpty;
}
