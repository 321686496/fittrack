import 'dart:async';

enum LiveViewAction { skipRest, resume }

class LiveViewEvent {
  final LiveViewAction action;
  final Map<String, dynamic> payload;

  LiveViewEvent({required this.action, required this.payload});
}

abstract class LiveViewService {
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  });
  Future<void> stopRestLiveView();
  Stream<LiveViewEvent> get onUserAction;

  /// 初始化实况窗服务（注册 MethodChannel 监听等）。
  /// 默认空实现，子类按需覆盖。
  /// I2 修复：补齐 PAL 契约——LiveViewService 与 RestReminderService/WidgetCardService
  /// 一样具备 init() 钩子，由 PlatformServices.init() 统一调用。
  Future<void> init() async {}
}
