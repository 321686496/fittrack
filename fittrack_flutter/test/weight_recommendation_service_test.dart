// 系统训练计划自动填充重量：动作分类与估算测试
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/system_plan_library.dart';
import 'package:fittrack_flutter/services/weight_recommendation_service.dart';

void main() {
  group('classifyExercise', () {
    test('复合动作分类正确', () {
      expect(classifyExercise('杠铃卧推'), ExerciseCategory.compoundPush);
      expect(classifyExercise('杠铃卧推（5×5）'), ExerciseCategory.compoundPush);
      expect(classifyExercise('哑铃推举'), ExerciseCategory.compoundPush);
      expect(classifyExercise('双杠臂屈伸'), ExerciseCategory.compoundPush);
      expect(classifyExercise('高位下拉'), ExerciseCategory.compoundPull);
      expect(classifyExercise('坐姿划船'), ExerciseCategory.compoundPull);
      expect(classifyExercise('杠铃划船'), ExerciseCategory.compoundPull);
      expect(classifyExercise('直臂下压'), ExerciseCategory.compoundPull);
      expect(classifyExercise('深蹲'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('硬拉'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('腿举'), ExerciseCategory.compoundLeg);
      expect(classifyExercise('箭步蹲'), ExerciseCategory.compoundLeg);
    });

    test('孤立动作分类正确', () {
      expect(classifyExercise('哑铃飞鸟'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('哑铃弯举'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('三头肌下压'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('侧平举'), ExerciseCategory.isolationUpper);
      expect(classifyExercise('腿弯举'), ExerciseCategory.isolationLower);
      expect(classifyExercise('腿屈伸'), ExerciseCategory.isolationLower);
      expect(classifyExercise('提踵'), ExerciseCategory.isolationLower);
      expect(classifyExercise('臀桥'), ExerciseCategory.isolationLower);
    });

    test('自重/有氧动作分类正确', () {
      expect(classifyExercise('俯卧撑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('引体向上'), ExerciseCategory.bodyweight);
      expect(classifyExercise('卷腹'), ExerciseCategory.bodyweight);
      expect(classifyExercise('平板支撑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('波比跳'), ExerciseCategory.bodyweight);
      expect(classifyExercise('慢跑'), ExerciseCategory.bodyweight);
      expect(classifyExercise('自重深蹲'), ExerciseCategory.bodyweight);
    });

    test('未命中回退孤立上肢', () {
      expect(classifyExercise('某未知动作'), ExerciseCategory.isolationUpper);
    });
  });

  group('estimateWeight', () {
    test('公式与取整：65kg 新手男性复合推', () {
      // 65 * 0.45 * 1.0 * 1.0 = 29.25 → 取整到 2.5 → 30.0
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '新手',
        gender: '男',
      ), 30.0);
    });

    test('性别系数：女性 0.70', () {
      // 65 * 0.70 * 1.0 * 0.70 = 31.85 → 32.5
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundLeg,
        fitnessLevel: '新手',
        gender: '女',
      ), 32.5);
    });

    test('水平系数：高级 1.45', () {
      // 65 * 0.45 * 1.45 * 1.0 = 42.41 → 42.5
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '高级',
        gender: '男',
      ), 42.5);
    });

    test('下限 2.5kg', () {
      expect(estimateWeight(
        bodyWeight: 20,
        category: ExerciseCategory.isolationUpper,
        fitnessLevel: '新手',
        gender: '男',
      ), 2.5);
    });

    test('孤立动作上限 50kg，复合动作上限 150kg', () {
      expect(estimateWeight(
        bodyWeight: 500,
        category: ExerciseCategory.isolationUpper,
        fitnessLevel: '高级',
        gender: '男',
      ), 50.0);
      expect(estimateWeight(
        bodyWeight: 500,
        category: ExerciseCategory.compoundLeg,
        fitnessLevel: '高级',
        gender: '男',
      ), 150.0);
    });

    test('未知水平/性别按 1.0 处理', () {
      expect(estimateWeight(
        bodyWeight: 65,
        category: ExerciseCategory.compoundPush,
        fitnessLevel: '未知',
        gender: '未知',
      ), 30.0);
    });
  });

  group('recommendForSystemPlan', () {
    test('无历史时按身体信息估算，来源为 estimate', () {
      final service = WeightRecommendationService.instance;
      final plan = _buildPlan([
        _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
      ]);
      final result = service.recommendForSystemPlan(
        plan,
        records: [],
        bodyData: {'height': 175, 'weight': 65},
        settings: {'fitnessLevel': '新手'},
      );
      final sug = result['ex_001']!;
      expect(sug.source, WeightSource.estimate);
      expect(sug.weight, 30.0); // 65*0.45=29.25 → 30
    });

    test('有历史记录时优先使用历史重量，来源为 history', () {
      final service = WeightRecommendationService.instance;
      final plan = _buildPlan([
        _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
      ]);
      // 模拟历史记录：planId 指向一个包含 ex_001(杠铃卧推, weight=60) 的旧计划
      final oldPlan = _buildUserPlan('user_old_1', [
        _day(1, '胸部日', [_ex('ex_001', '杠铃卧推', 4, 10)]),
      ]);
      final result = service.recommendForSystemPlan(
        plan,
        records: [
          {
            'planId': 'user_old_1',
            'setRecords': {
              'ex_001': [
                {'set': 1, 'weight': 60, 'reps': 10},
              ],
            },
          },
        ],
        bodyData: {'height': 175, 'weight': 65},
        settings: {'fitnessLevel': '新手'},
        userPlans: [oldPlan],
      );
      final sug = result['ex_001']!;
      expect(sug.source, WeightSource.history);
      expect(sug.weight, 60.0);
    });

    test('自重动作 weight 为 null，来源为 bodyweight', () {
      final service = WeightRecommendationService.instance;
      final plan = _buildPlan([
        _day(1, '腹部日', [_ex('ex_002', '卷腹', 3, 20)]),
      ]);
      final result = service.recommendForSystemPlan(
        plan,
        records: [],
        bodyData: {'height': 175, 'weight': 65},
        settings: {'fitnessLevel': '新手'},
      );
      final sug = result['ex_002']!;
      expect(sug.weight, isNull);
      expect(sug.source, WeightSource.bodyweight);
    });
  });
}

// ── 测试辅助 ──────────────────────────────────────────────────
Map<String, dynamic> _ex(String id, String name, int sets, int reps) {
  return {'id': id, 'name': name, 'sets': sets, 'reps': reps, 'restTime': 90};
}

Map<String, dynamic> _day(int day, String label, List<Map<String, dynamic>> exercises) {
  return {'day': day, 'label': label, 'muscle': label, 'exercises': exercises};
}

SystemPlan _buildPlan(List<Map<String, dynamic>> days) {
  return SystemPlan(
    id: 'plan_test',
    name: '测试计划',
    goal: 'bulk',
    difficulty: 'beginner',
    trainingType: '3day_split',
    isPremium: false,
    pointsCost: 0,
    totalWeeks: 4,
    defaultRestTime: 90,
    description: '',
    coverEmoji: '💪',
    coverColors: const ['#FF6B6B', '#C44D4D'],
    tags: const [],
    recommendedFrequency: 3,
    suitableFor: '',
    days: days.map((d) => SystemPlanDay(
      day: d['day'] as int,
      label: d['label'] as String,
      muscle: d['muscle'] as String,
      exercises: (d['exercises'] as List)
          .map((e) => SystemPlanExercise(
                id: e['id'] as String,
                name: e['name'] as String,
                sets: e['sets'] as int,
                reps: e['reps'] as int,
                restTime: e['restTime'] as int,
              ))
          .toList(),
    )).toList(),
  );
}

Map<String, dynamic> _buildUserPlan(String id, List<Map<String, dynamic>> days) {
  return {
    'id': id,
    'name': '旧计划',
    'type': '3day_split',
    'frequency': 3,
    'difficulty': 'beginner',
    'totalWeeks': 4,
    'defaultRestTime': 90,
    'days': days,
    'status': 'paused',
  };
}
