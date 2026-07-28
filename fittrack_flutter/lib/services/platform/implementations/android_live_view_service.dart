import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../live_view_service.dart';

/// Android 实况窗服务（前台服务通知 + Chronometer）
class AndroidLiveViewService implements LiveViewService {
  static const _channel = MethodChannel('com.fp.fitplan/liveview');

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  /// I2 修复：补齐 PAL 契约——注册 liveview MethodChannel 的 onUserAction 监听，
  /// 将原生侧（未来的实况窗按钮回调）转发为 LiveViewEvent 注入事件流。
  /// 当前 C2 路由 skipRest 走 alarm channel（onCardClick），不会触发此处；
  /// 此处用于未来扩展（如其他 LiveViewAction 走 liveview channel）。
  @override
  Future<void> init() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onUserAction') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final action = args['action'] as String?;
        if (action == 'skipRest') {
          _actionController.add(LiveViewEvent(
            action: LiveViewAction.skipRest,
            payload: const <String, dynamic>{},
          ));
        }
      }
    });
  }

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
