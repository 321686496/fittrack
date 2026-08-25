import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';

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

  static const String _channelName = 'com.lt.lifttrack/reminder';

  final MethodChannel _channel = const MethodChannel(_channelName);

  /// 当前已发布的提醒 ID（用于取消）
  int? _currentReminderId;

  /// 通知点击回调
  Function(Map<String, dynamic>)? onNotificationClick;

  /// 卡片点击回调
  Function(Map<String, dynamic>)? onCardClick;

  /// 训练卡片交互回调（由训练页在挂载时注册，用于原地处理 skipRest / resume，
  /// 避免卡片点击时跳转首页销毁训练页导致数据丢失）
  Function(Map<String, dynamic>)? onTrainingCardAction;

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
    if (!isOhos) {
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
  /// 返回 true 表示原生侧发布成功（原生侧会校验 publishReminder 结果并回调错误）。
  Future<bool> scheduleTrainingReminder({
    required String title,
    required String content,
    required String timeStr,
  }) async {
    if (!isOhos) return false;
    try {
      await _channel.invokeMethod<void>('scheduleTrainingReminder', {
        'title': title,
        'content': content,
        'timeStr': timeStr,
      });
      debugPrint('[OhosReminder] scheduleTrainingReminder: $timeStr');
      return true;
    } on PlatformException catch (e) {
      debugPrint(
          '[OhosReminder] scheduleTrainingReminder failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[OhosReminder] scheduleTrainingReminder error: $e');
      return false;
    }
  }

  /// 取消每日训练提醒
  Future<void> cancelTrainingReminder() async {
    if (!isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelTrainingReminder');
      debugPrint('[OhosReminder] cancelTrainingReminder success');
    } catch (e) {
      debugPrint('[OhosReminder] cancelTrainingReminder error: $e');
    }
  }

  /// 调度健身卡到期提醒（后台代理提醒）
  /// [dateStr] 格式 "YYYY-MM-DD"，提醒时间固定为当天 10:00
  /// [notificationId] 系统通知 ID，多张卡需传不同值避免互相覆盖
  /// 返回 true 表示原生侧发布成功。
  Future<bool> scheduleGymCardReminder({
    required String title,
    required String content,
    required String dateStr,
    required int notificationId,
  }) async {
    if (!isOhos) return false;
    try {
      await _channel.invokeMethod<void>('scheduleGymCardReminder', {
        'title': title,
        'content': content,
        'dateStr': dateStr,
        'notificationId': notificationId,
      });
      debugPrint(
          '[OhosReminder] scheduleGymCardReminder: $dateStr, id=$notificationId');
      return true;
    } on PlatformException catch (e) {
      debugPrint(
          '[OhosReminder] scheduleGymCardReminder failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[OhosReminder] scheduleGymCardReminder error: $e');
      return false;
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

  /// 调度智能推送提醒（每日 20:00 倒计时代理提醒）
  /// [timeStr] 格式 "HH:mm"，为下次触发时刻；每次调度会先清空旧调度。
  Future<bool> scheduleSmartPushReminder({
    required String title,
    required String content,
    required String timeStr,
  }) async {
    if (!isOhos) return false;
    try {
      await _channel.invokeMethod<void>('scheduleSmartPushReminder', {
        'title': title,
        'content': content,
        'timeStr': timeStr,
      });
      debugPrint('[OhosReminder] scheduleSmartPushReminder: $timeStr');
      return true;
    } on PlatformException catch (e) {
      debugPrint(
          '[OhosReminder] scheduleSmartPushReminder failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[OhosReminder] scheduleSmartPushReminder error: $e');
      return false;
    }
  }

  /// 取消智能推送提醒
  Future<void> cancelSmartPushReminder() async {
    if (!isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelSmartPushReminder');
      debugPrint('[OhosReminder] cancelSmartPushReminder success');
    } catch (e) {
      debugPrint('[OhosReminder] cancelSmartPushReminder error: $e');
    }
  }

  /// 立即发布智能推送通知（App 存活时兜底）
  Future<void> publishSmartPushNow({
    required String title,
    required String content,
  }) async {
    if (!isOhos) return;
    try {
      await _channel.invokeMethod<void>('publishSmartPushNow', {
        'title': title,
        'content': content,
      });
      debugPrint('[OhosReminder] publishSmartPushNow sent');
    } catch (e) {
      debugPrint('[OhosReminder] publishSmartPushNow error: $e');
    }
  }
}
