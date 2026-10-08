import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/services/form_kit_service.dart';
import 'package:fittrack_flutter/services/platform/implementations/ohos_widget_card_service.dart';
import 'package:fittrack_flutter/services/platform/widget_card_service.dart';

/// 回归测试：用户主动结束休息（跳过休息）后，restSkipped 必须一路透传到
/// FormKitService，OHOS 原生侧才能取消尚未触发的"休息结束"代理提醒。
///
/// 背景：PAL 重构把 `FormKitService.updateTrainingState(restSkipped:)` 换成了
/// `PlatformServices.widgetCard.pushCardData(WidgetCardData(...))`，而
/// WidgetCardData 当时没有 restSkipped 字段，标记被静默丢弃，导致休息结束后
/// 通知照常发送。
void main() {
  const trainingCard = WidgetCardData(
    mode: WidgetCardMode.training,
    exerciseName: '深蹲',
    currentSet: 2,
    totalSets: 3,
    exerciseIndex: 1,
    totalExercises: 2,
    completedSets: 1,
    totalPlanSets: 6,
  );

  test('跳过休息：restSkipped 透传到 FormKitService 训练态数据', () async {
    await OhosWidgetCardService().pushCardData(
      const WidgetCardData(
        mode: WidgetCardMode.training,
        exerciseName: '深蹲',
        currentSet: 2,
        totalSets: 3,
        exerciseIndex: 1,
        totalExercises: 2,
        completedSets: 1,
        totalPlanSets: 6,
        restSkipped: true,
      ),
    );

    expect(
      FormKitService.instance.trainingStateForTest?['restSkipped'],
      isTrue,
      reason: 'restSkipped 必须透传，否则 OHOS 原生不会取消代理提醒',
    );
  });

  test('休息自然结束：不下发 restSkipped 标记，保留代理提醒', () async {
    await OhosWidgetCardService().pushCardData(trainingCard);

    expect(
      FormKitService.instance.trainingStateForTest?.containsKey('restSkipped'),
      isFalse,
      reason: '自然结束时应保留代理提醒，让"休息结束"通知正常触发',
    );
  });
}