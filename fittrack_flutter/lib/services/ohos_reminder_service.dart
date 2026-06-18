import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// OHOS 后台代理提醒服务
///
/// 通过 MethodChannel 调用原生 reminderAgentManager，
/// 实现应用退到后台后仍能发送定时通知。
///
/// 使用 Background Tasks Kit 的代理提醒能力：
/// - ReminderRequestTimer：一次性定时提醒
/// - 需要 ohos.permission.PUBLISH_AGENT_REMINDER 权限
class OhosReminderService {
  OhosReminderService._();

  static final OhosReminderService instance = OhosReminderService._();

  static const String _channelName = 'com.example.fittrack_flutter/reminder';

  final MethodChannel _channel = const MethodChannel(_channelName);

  /// 当前已发布的提醒 ID（用于取消）
  int? _currentReminderId;

  /// 通知点击回调
  Function(Map<String, dynamic>)? onNotificationClick;

  /// 卡片点击回调
  Function(Map<String, dynamic>)? onCardClick;

  bool _listenerInitialized = false;

  /// 初始化监听器（应用启动时调用一次）
  void initListener() {
    if (_listenerInitialized) return;
    _listenerInitialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onNotificationClick':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          debugPrint('[OhosReminder] Notification clicked: $args');
          onNotificationClick?.call(args);
          break;
        case 'onCardClick':
          // EntryAbility 发送的是 JSON 字符串，需要解析
          try {
            final jsonStr = call.arguments as String;
            final args = jsonDecode(jsonStr) as Map<String, dynamic>;
            debugPrint('[OhosReminder] Card clicked: $args');
            onCardClick?.call(args);
          } catch (e) {
            debugPrint('[OhosReminder] Card click parse error: $e');
          }
          break;
        default:
          debugPrint('[OhosReminder] Unknown method: ${call.method}');
      }
    });
  }

  /// 发布后台代理提醒
  ///
  /// [title] 通知标题
  /// [content] 通知内容
  /// [triggerTimeInSeconds] 延迟秒数
  /// [notificationId] 通知 ID
  ///
  /// 返回 reminderId，失败返回 null
  Future<int?> publishReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async {
    if (!Platform.isOhos) {
      debugPrint('[OhosReminder] Not on OHOS platform, skip');
      return null;
    }

    try {
      // 先取消之前的提醒
      await cancelCurrentReminder();

      final result = await _channel.invokeMethod<int>('publishReminder', {
        'title': title,
        'content': content,
        'triggerTimeInSeconds': triggerTimeInSeconds,
        'notificationId': notificationId,
      });

      _currentReminderId = result;
      debugPrint(
          '[OhosReminder] publishReminder success, id: $result, '
          'trigger: ${triggerTimeInSeconds}s');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[OhosReminder] publishReminder failed: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[OhosReminder] publishReminder exception: $e');
      return null;
    }
  }

  /// 取消当前提醒
  Future<void> cancelCurrentReminder() async {
    if (_currentReminderId != null && _currentReminderId! >= 0) {
      try {
        await _channel.invokeMethod<void>('cancelReminder', {
          'reminderId': _currentReminderId,
        });
        debugPrint('[OhosReminder] cancelReminder success, id: $_currentReminderId');
      } on PlatformException catch (e) {
        debugPrint('[OhosReminder] cancelReminder failed: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('[OhosReminder] cancelReminder exception: $e');
      }
      _currentReminderId = null;
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    try {
      await _channel.invokeMethod<void>('cancelAllReminders');
      _currentReminderId = null;
      debugPrint('[OhosReminder] cancelAllReminders success');
    } on PlatformException catch (e) {
      debugPrint('[OhosReminder] cancelAllReminders failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[OhosReminder] cancelAllReminders exception: $e');
    }
  }

  /// 发布每日训练提醒
  /// [timeStr] 格式 "HH:mm"，如 "18:00"
  Future<void> scheduleTrainingReminder({
    required String title,
    required String content,
    required String timeStr,
  }) async {
    if (!Platform.isOhos) return;
    try {
      await _channel.invokeMethod<void>('scheduleTrainingReminder', {
        'title': title,
        'content': content,
        'timeStr': timeStr,
      });
      debugPrint('[OhosReminder] scheduleTrainingReminder: $timeStr');
    } catch (e) {
      debugPrint('[OhosReminder] scheduleTrainingReminder error: $e');
    }
  }

  /// 取消每日训练提醒
  Future<void> cancelTrainingReminder() async {
    if (!Platform.isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelTrainingReminder');
      debugPrint('[OhosReminder] cancelTrainingReminder success');
    } catch (e) {
      debugPrint('[OhosReminder] cancelTrainingReminder error: $e');
    }
  }
}
