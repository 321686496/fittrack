import 'dart:async';
import '../live_view_service.dart';

class OhosLiveViewService implements LiveViewService {
  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  /// I2：补齐 PAL 契约。OHOS Live View 事件由 main.dart 通过
  /// handleCardClick 外部注入，不需要在 init() 中注册 MethodChannel。
  @override
  Future<void> init() async {}

  /// OHOS 实况窗由 EntryAbility 在收到 mode=rest 的 form data 时自动启动，
  /// 不需要 Flutter 侧额外推送数据。
  /// 之前这里调用 _formKit.startRest 会导致卡片数据被重复推送：
  ///   1. widgetCard.pushCardData 推送完整数据（currentSet/totalSets 等有值）
  ///   2. 本方法再推送一次但字段全为 0，覆盖了正确数据，导致卡片显示 0/0
  ///   3. 同时触发 manageTrainingState 两次，代理提醒被发布两次
  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    // 无操作：实况窗启动由 EntryAbility 原生侧负责
  }

  @override
  Future<void> stopRestLiveView() async {
    // OHOS 实况窗由 EntryAbility 在 mode 切换时自动停止
  }

  @override
  Stream<LiveViewEvent> get onUserAction => _actionController.stream;

  void handleCardClick(Map<String, dynamic> args) {
    final cardAction = args['cardAction'] as String?;
    if (cardAction == 'skipRest') {
      _actionController.add(LiveViewEvent(
        action: LiveViewAction.skipRest,
        payload: args,
      ));
    } else if (cardAction == 'resume') {
      _actionController.add(LiveViewEvent(
        action: LiveViewAction.resume,
        payload: args,
      ));
    }
  }
}
