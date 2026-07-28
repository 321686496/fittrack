import 'dart:async';
import '../../form_kit_service.dart';
import '../widget_card_service.dart';

class OhosWidgetCardService implements WidgetCardService {
  final FormKitService _formKit = FormKitService.instance;

  final StreamController<WidgetCardClickEvent> _clickController =
      StreamController<WidgetCardClickEvent>.broadcast();

  @override
  Future<void> init() async {
    _formKit.init();
  }

  @override
  Future<void> pushCardData(WidgetCardData data) async {
    if (data.mode == WidgetCardMode.idle) {
      _formKit.endTraining();
      return;
    }
    if (data.mode == WidgetCardMode.training) {
      _formKit.updateTrainingState(
        exerciseName: data.exerciseName ?? '',
        currentSet: data.currentSet ?? 0,
        totalSets: data.totalSets ?? 0,
        exerciseIndex: data.exerciseIndex ?? 0,
        totalExercises: data.totalExercises ?? 0,
        completedSets: data.completedSets ?? 0,
        totalPlanSets: data.totalPlanSets ?? 0,
      );
      return;
    }
    if (data.mode == WidgetCardMode.rest) {
      _formKit.startRest(
        exerciseName: data.exerciseName ?? '',
        restSeconds: data.restTotalSeconds ?? 0,
        restEndTime: data.restEndTime?.millisecondsSinceEpoch ?? 0,
        totalRestSeconds: data.restTotalSeconds ?? 0,
        currentSet: data.currentSet ?? 0,
        totalSets: data.totalSets ?? 0,
        exerciseIndex: data.exerciseIndex ?? 0,
        totalExercises: data.totalExercises ?? 0,
        completedSets: data.completedSets ?? 0,
        totalPlanSets: data.totalPlanSets ?? 0,
      );
    }
  }

  @override
  Future<void> clearCardData() async {
    _formKit.endTraining();
  }

  @override
  Stream<WidgetCardClickEvent> get onCardClick => _clickController.stream;

  void handleCardClick(Map<String, dynamic> args) {
    _clickController.add(WidgetCardClickEvent.fromMap(args));
  }
}
