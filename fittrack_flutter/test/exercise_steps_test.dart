import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/mock_data.dart';

void main() {
  test('所有内置动作都有步骤数据', () {
    for (final ex in MockData.exercises) {
      final id = ex['id'] as String;
      final steps = MockData.exerciseSteps[id];
      expect(steps, isNotNull, reason: '$id 缺少步骤数据');
      expect(steps, isA<List>(), reason: '$id steps 不是 List');
      expect((steps as List).length, greaterThanOrEqualTo(4),
          reason: '$id 步骤数应 >= 4');
    }
  });

  test('每个步骤都含 title/desc/keyPoses 且 keyPoses 为非空 List<String>', () {
    for (final ex in MockData.exercises) {
      final id = ex['id'] as String;
      final steps = MockData.exerciseSteps[id] as List;
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i] as Map<String, dynamic>;
        expect(step['title'], isA<String>(), reason: '$id step[$i] title 缺失');
        expect((step['title'] as String).isNotEmpty, true,
            reason: '$id step[$i] title 为空');
        expect(step['desc'], isA<String>(), reason: '$id step[$i] desc 缺失');
        expect((step['desc'] as String).length, greaterThan(20),
            reason: '$id step[$i] desc 过短，需专业教学级别描述');
        expect(step['keyPoses'], isA<List>(), reason: '$id step[$i] keyPoses 缺失或非 List');
        final kp = step['keyPoses'] as List;
        expect(kp.length, greaterThanOrEqualTo(1),
            reason: '$id step[$i] keyPoses 至少 1 条');
        expect(kp.length, lessThanOrEqualTo(3),
            reason: '$id step[$i] keyPoses 最多 3 条');
        for (final k in kp) {
          expect(k, isA<String>(), reason: '$id step[$i] keyPose 非字符串');
          expect((k as String).isNotEmpty, true, reason: '$id step[$i] keyPose 为空');
        }
      }
    }
  });

  test('21 个内置动作覆盖全部 id', () {
    expect(MockData.exercises.length, 21);
  });
}
