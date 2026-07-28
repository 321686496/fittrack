import 'dart:async';

enum WidgetCardMode { idle, training, rest }

class WidgetCardClickEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;

  WidgetCardClickEvent({this.targetPage, this.cardAction, required this.payload});

  factory WidgetCardClickEvent.fromMap(Map<String, dynamic> map) =>
      WidgetCardClickEvent(
        targetPage: map['targetPage'] as String?,
        cardAction: map['cardAction'] as String?,
        payload: map,
      );
}

class WidgetCardData {
  final WidgetCardMode mode;
  final String? exerciseName;
  final int? currentSet;
  final int? totalSets;
  final int? exerciseIndex;
  final int? totalExercises;
  final int? completedSets;
  final int? totalPlanSets;
  final DateTime? restEndTime;
  final int? restTotalSeconds;
  final int todayTrainingCount;
  final int todayTrainingMinutes;
  final int todayTotalWeight;
  final int consecutiveDays;
  final String? lastTrainingName;
  final String? lastTrainingDate;
  final String? reminderTime;
  final String accentColor;
  final String bgColor;
  final String textPrimaryColor;
  final String textSecondaryColor;

  const WidgetCardData({
    this.mode = WidgetCardMode.idle,
    this.exerciseName,
    this.currentSet,
    this.totalSets,
    this.exerciseIndex,
    this.totalExercises,
    this.completedSets,
    this.totalPlanSets,
    this.restEndTime,
    this.restTotalSeconds,
    this.todayTrainingCount = 0,
    this.todayTrainingMinutes = 0,
    this.todayTotalWeight = 0,
    this.consecutiveDays = 0,
    this.lastTrainingName,
    this.lastTrainingDate,
    this.reminderTime,
    this.accentColor = '#FF6B35',
    this.bgColor = '#FFFFFF',
    this.textPrimaryColor = '#222222',
    this.textSecondaryColor = '#999999',
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      if (exerciseName != null) 'exerciseName': exerciseName,
      if (currentSet != null) 'currentSet': currentSet,
      if (totalSets != null) 'totalSets': totalSets,
      if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
      if (totalExercises != null) 'totalExercises': totalExercises,
      if (completedSets != null) 'completedSets': completedSets,
      if (totalPlanSets != null) 'totalPlanSets': totalPlanSets,
      if (restEndTime != null) 'restEndTime': restEndTime!.millisecondsSinceEpoch,
      if (restTotalSeconds != null) 'restTotalSeconds': restTotalSeconds,
      'todayTrainings': todayTrainingCount,
      'todayDuration': todayTrainingMinutes,
      'todayWeight': todayTotalWeight,
      'streak': consecutiveDays,
      'lastTraining': lastTrainingName ?? '',
      'lastDate': lastTrainingDate ?? '',
      'accentColor': accentColor,
      'bgColor': bgColor,
      'textPrimaryColor': textPrimaryColor,
      'textSecondaryColor': textSecondaryColor,
      'trainingTime': reminderTime ?? '',
    };
  }
}

abstract class WidgetCardService {
  Future<void> init();
  Future<void> pushCardData(WidgetCardData data);
  Future<void> clearCardData();
  Stream<WidgetCardClickEvent> get onCardClick;
}
