// 隔离验证：currentDayIndex 列是否在 plans 表中缺失
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // 清空 plans 表，保证测试隔离
    await Storage.savePlansAsync([]);
    await Storage.getPlansAsync();
  });

  test('addPlanAsync 仅带 currentDayIndex（模拟 add_plan_page）应成功持久化', () async {
    // 模拟 add_plan_page._save() 的 planData —— 包含 currentDayIndex 但无 bool 字段
    final planData = <String, dynamic>{
      'name': '自定义计划',
      'type': '三分化',
      'frequency': '6天/周',
      'difficulty': '初级',
      'totalWeeks': 8,
      'defaultRestTime': 90,
      'days': <Map<String, dynamic>>[],
      'currentDayIndex': 0,
      'week': 0,
      'progress': 0,
      'status': 'active',
      'badge': '进行中',
    };

    try {
      await Storage.addPlanAsync(planData);
      final plans = Storage.getPlans();
      expect(plans, hasLength(1));
      expect(plans.first['currentDayIndex'], 0);
    } catch (e) {
      fail('addPlanAsync 不应抛出异常: $e');
    }
  });

  test('updatePlanAsync 写入 currentDayIndex 应成功持久化', () async {
    // 先创建一个计划
    final planData = <String, dynamic>{
      'name': '测试计划',
      'type': '三分化',
      'difficulty': '初级',
      'totalWeeks': 8,
      'defaultRestTime': 90,
      'days': <Map<String, dynamic>>[],
    };
    final added = await Storage.addPlanAsync(planData);
    final planId = added['id'] as String;

    // 模拟 training_page.dart:524 — 训练完成后推进 currentDayIndex
    try {
      await Storage.updatePlanAsync(planId, {'currentDayIndex': 1});
      final updated = Storage.getPlanById(planId);
      expect(updated?['currentDayIndex'], 1);
    } catch (e) {
      fail('updatePlanAsync 写 currentDayIndex 不应抛出异常: $e');
    }
  });
}
