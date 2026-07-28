import 'dart:async';
import '../../form_kit_service.dart';
import '../live_view_service.dart';

class OhosLiveViewService implements LiveViewService {
  final FormKitService _formKit = FormKitService.instance;

  final StreamController<LiveViewEvent> _actionController =
      StreamController<LiveViewEvent>.broadcast();

  /// I2：补齐 PAL 契约。OHOS Live View 事件由 main.dart 通过
  /// handleCardClick 外部注入，不需要在 init() 中注册 MethodChannel。
  @override
  Future<void> init() async {}

  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {
    _formKit.startRest(
      exerciseName: exerciseName,
      restSeconds: restSeconds,
      restEndTime: restEndTime.millisecondsSinceEpoch,
      totalRestSeconds: restSeconds,
      currentSet: 0,
      totalSets: 0,
      exerciseIndex: 0,
      totalExercises: 0,
      completedSets: 0,
      totalPlanSets: 0,
    );
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
