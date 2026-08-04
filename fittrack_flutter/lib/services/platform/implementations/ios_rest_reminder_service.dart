import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../rest_reminder_service.dart';

/// iOS 休息提醒服务（通过 MethodChannel 调用 UNUserNotificationCenter）
class IosRestReminderService implements RestReminderService {
  static const _channel = MethodChannel('com.lt.lifttrack/reminder');

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCardClick':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          _clickController.add(RestReminderEvent.fromMap(args));
          break;
        default:
          debugPrint('[IosReminder] Unknown method: ${call.method}');
      }
    });
  }

  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async {
    try {
      final result = await _channel.invokeMethod<int>('scheduleRestReminder', {
        'title': title,
        'content': content,
        'triggerTimeInSeconds': triggerTimeInSeconds,
        'notificationId': notificationId,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('[IosReminder] scheduleRestReminder failed: ${e.code} - ${e.message}');
      return null;
    }
  }

  @override
  Future<void> cancelCurrentReminder() async {
    try {
      await _channel.invokeMethod<void>('cancelRestReminder');
    } catch (e) {
      debugPrint('[IosReminder] cancelRestReminder error: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _channel.invokeMethod<void>('cancelAllReminders');
    } catch (e) {
      debugPrint('[IosReminder] cancelAllReminders error: $e');
    }
  }

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
