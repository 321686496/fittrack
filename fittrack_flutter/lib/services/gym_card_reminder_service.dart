import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/storage.dart';
import '../utils/platform_utils.dart';

/// 健身卡到期提醒服务
///
/// 在 App 启动 / 回到前台时检查所有健身卡，根据用户配置的阈值
/// （期限卡剩余天数、次卡剩余次数）判断是否需要推送提醒。
///
/// 推送策略：
/// - 同一天最多推送一次（lastGymCardReminderDate 防重复）
/// - 多张卡同时满足条件时合并为一条通知
/// - OHOS 平台使用 flutter_local_notifications 直接 show（OHOS fork 版本支持）
///
/// 注意：本服务只在应用启动或回到前台时触发，不做后台定时轮询。
/// 真正的后台定时推送需依赖系统级任务（OHOS 代理提醒 / Android WorkManager），
/// 当前版本以前台触发 + 通知展示覆盖大部分使用场景。
class GymCardReminderService {
  GymCardReminderService._();

  static final GymCardReminderService instance = GymCardReminderService._();

  static const String _channelId = 'gym_card_expiry_channel';
  static const String _channelName = '健身卡到期提醒';
  static const String _channelDesc = '健身卡即将到期或次数不足的提醒';
  static const int _notificationId = 4001;

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// 初始化（应用启动时调用一次，幂等）
  Future<void> init() async {
    if (_initialized) return;
    try {
      _plugin = FlutterLocalNotificationsPlugin();

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

  /// 检查并推送（启动时 / 回到前台时调用）
  ///
  /// 返回 true 表示本次触发了推送，false 表示未推送（开关关闭 / 今天已推 / 无符合条件的卡）
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

        // 次卡：剩余次数 ≤ 阈值
        if (cardType == '次卡' && remaining >= 0 && remaining <= countThreshold) {
          if (remaining == 0) {
            alerts.add('「$name」已用完所有次数');
          } else {
            alerts.add('「$name」仅剩 $remaining 次');
          }
          continue;
        }

        // 期限卡：剩余天数 ≤ 阈值（含已过期）
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
      final display = alerts.take(3).join('；');
      final suffix = alerts.length > 3 ? ' 等 ${alerts.length} 张' : '';
      const title = '健身卡提醒';
      final content = '$display$suffix，请及时续卡';

      await _sendNotification(title, content);

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
