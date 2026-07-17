import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';

class AndroidAlarmService {
  AndroidAlarmService._();

  static final AndroidAlarmService instance = AndroidAlarmService._();

  static const String _channelName = 'com.fp.fitplan/alarm';

  final MethodChannel _channel = const MethodChannel(_channelName);

  bool _listenerInitialized = false;

  Function(Map<String, dynamic>)? onCardClick;

  void initListener() {
    if (_listenerInitialized || isOhos) return;
    _listenerInitialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCardClick':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          debugPrint('[AndroidAlarm] Card clicked: $args');
          onCardClick?.call(args);
          break;
        default:
          debugPrint('[AndroidAlarm] Unknown method: ${call.method}');
      }
    });
  }

  Future<int?> scheduleRestAlarm({
    required String title,
    required String content,
    required String exerciseName,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async {
    if (isOhos) {
      debugPrint('[AndroidAlarm] On OHOS platform, skip');
      return null;
    }

    try {
      final result = await _channel.invokeMethod<int>('scheduleRestAlarm', {
        'title': title,
        'content': content,
        'exerciseName': exerciseName,
        'triggerTimeInSeconds': triggerTimeInSeconds,
        'notificationId': notificationId,
      });

      debugPrint(
          '[AndroidAlarm] scheduleRestAlarm success, triggerAt: $result, '
          'delay: ${triggerTimeInSeconds}s');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[AndroidAlarm] scheduleRestAlarm failed: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[AndroidAlarm] scheduleRestAlarm exception: $e');
      return null;
    }
  }

  Future<void> cancelRestAlarm() async {
    if (isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelRestAlarm');
      debugPrint('[AndroidAlarm] cancelRestAlarm success');
    } on PlatformException catch (e) {
      debugPrint('[AndroidAlarm] cancelRestAlarm failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[AndroidAlarm] cancelRestAlarm exception: $e');
    }
  }

  Future<void> cancelAllAlarms() async {
    if (isOhos) return;
    try {
      await _channel.invokeMethod<void>('cancelAllAlarms');
      debugPrint('[AndroidAlarm] cancelAllAlarms success');
    } on PlatformException catch (e) {
      debugPrint('[AndroidAlarm] cancelAllAlarms failed: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('[AndroidAlarm] cancelAllAlarms exception: $e');
    }
  }
}
