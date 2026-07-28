import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../live_view_service.dart';

/// Android 实况窗服务（前台服务通知 + Chronometer）
class AndroidLiveViewService implements LiveViewService {
  static const _channel = MethodChannel('com.fp.fitplan/liveview');

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    try {
      await _channel.invokeMethod<bool>('startRestLiveView', {
        'exerciseName': exerciseName,
        'restSeconds': restSeconds,
        'restEndTimeMs': restEndTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[AndroidLiveView] startRestLiveView error: $e');
    }
  }

  @override
  Future<void> stopRestLiveView() async {
    try {
      await _channel.invokeMethod<bool>('stopRestLiveView');
    } catch (e) {
      debugPrint('[AndroidLiveView] stopRestLiveView error: $e');
    }
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;
}
