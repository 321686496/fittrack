import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/services/plan_recommendation_service.dart';
import 'package:fittrack_flutter/data/system_plan_library.dart';

/// 构造一个最小化的 SystemPlan，仅填充排序所需字段
SystemPlan _makePlan(String id, {bool isPremium = false}) {
  return SystemPlan(
    id: id,
    name: id,
    goal: 'bulk',
    difficulty: 'beginner',
    trainingType: '3day_split',
    isPremium: isPremium,
    pointsCost: isPremium ? 100 : 0,
    totalWeeks: 4,
    defaultRestTime: 90,
    description: '',
    coverEmoji: '💪',
    coverColors: ['#FF6B6B', '#C44D4D'],
    tags: [],
    recommendedFrequency: 3,
    suitableFor: '',
    days: const [],
  );
}

PlanRecommendation _makeRec(SystemPlan plan, double score) {
  return PlanRecommendation(plan: plan, score: score, reasons: []);
}

void main() {
  group('PlanRecommendationService.sortWithFreePriority', () {
    test('同段内免费计划应排在付费计划前', () {
      final recs = [
        _makeRec(_makePlan('paid_a', isPremium: true), 80.0),
        _makeRec(_makePlan('free_a', isPremium: false), 78.0),
        _makeRec(_makePlan('paid_b', isPremium: true), 95.0),
      ];

      final sorted = PlanRecommendationService.sortWithFreePriority(recs);

      // 95 远高于 80/78 段差 5，应在最前
      expect(sorted[0].plan.id, 'paid_b');
      // 80 和 78 段差 ≤ 5，同段内免费(78) 应在付费(80) 前
      expect(sorted[1].plan.id, 'free_a');
      expect(sorted[2].plan.id, 'paid_a');
    });

    test('两个免费计划同段差 ≤ 5 时按 score 降序', () {
      final recs = [
        _makeRec(_makePlan('free_low', isPremium: false), 70.0),
        _makeRec(_makePlan('free_high', isPremium: false), 73.0),
      ];

      final sorted = PlanRecommendationService.sortWithFreePriority(recs);

      expect(sorted[0].plan.id, 'free_high');
      expect(sorted[1].plan.id, 'free_low');
    });

    test('段差 > 5 时严格按 score 降序', () {
      final recs = [
        _makeRec(_makePlan('low', isPremium: false), 50.0),
        _makeRec(_makePlan('high_paid', isPremium: true), 90.0),
      ];

      final sorted = PlanRecommendationService.sortWithFreePriority(recs);

      // 段差 40 > 5，按 score 降序，付费高分在前
      expect(sorted[0].plan.id, 'high_paid');
      expect(sorted[1].plan.id, 'low');
    });

    test('空列表返回空列表', () {
      final sorted = PlanRecommendationService.sortWithFreePriority([]);
      expect(sorted, isEmpty);
    });
  });
}
