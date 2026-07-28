// fittrack_flutter/lib/services/platform/implementations/ios_live_view_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../live_view_service.dart';

/// iOS 实况窗服务（通过 ActivityKit 实现 Live Activities）
class IosLiveViewService implements LiveViewService {
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
    } on PlatformException catch (e) {
      // iOS 低于 16.1 会返回 UNAVAILABLE，降级为普通通知
      debugPrint('[IosLiveView] startRestLiveView failed: ${e.code} - ${e.message}');
    }
  }

  @override
  Future<void> stopRestLiveView() async {
    try {
      await _channel.invokeMethod<bool>('stopRestLiveView');
    } catch (e) {
      debugPrint('[IosLiveView] stopRestLiveView error: $e');
    }
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;
}
