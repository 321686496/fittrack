import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/storage.dart';
import '../utils/platform_utils.dart';

class SmartPushService {
  static final SmartPushService instance = SmartPushService._();
  SmartPushService._();

  static const int _maxPushPer7Days = 2;
  static const int _notificationId = 2001;

  Future<void> init() async {
    // Schedule daily 20:00 check (uses Android zonedSchedule or OHOS reminder)
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
    // For simplicity in Phase 2: rely on app foreground to trigger check.
    // Real scheduling would use Android AlarmManager or OHOS reminder.
    // Implementation: hook into app lifecycle resume event.
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
      // OHOS: rely on OhosReminderService.publishReminder
      return;
    }
    // Android/iOS: use flutter_local_notifications directly
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      _notificationId,
      'FitTrack 提醒',
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
  }
}

class _PushStrategy {
  final String message;
  const _PushStrategy({required this.message});
  static const none = _PushStrategy(message: '');
  bool get shouldPush => message.isNotEmpty;
}
