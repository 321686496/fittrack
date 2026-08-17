// 隔离验证：gender 列是否在 plans 表中缺失（add_plan_page._save() 会写入 gender）
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

  test('addPlanAsync 带 gender（模拟 add_plan_page._save）应成功持久化', () async {
    // 模拟 add_plan_page._save() 的 planData —— 包含 gender 字段
    final planData = <String, dynamic>{
      'name': '自定义计划',
      'type': '三分化',
      'frequency': '6天/周',
      'difficulty': '初级',
      'gender': 'male',
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
      final added = await Storage.addPlanAsync(planData);
      final planId = added['id'] as String;
      final plan = Storage.getPlanById(planId);
      expect(plan?['gender'], 'male');
    } catch (e) {
      fail('addPlanAsync 带 gender 不应抛出异常: $e');
    }
  });

  test('updatePlanAsync 写入 gender 应成功持久化', () async {
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

    try {
      await Storage.updatePlanAsync(planId, {'gender': 'female'});
      final updated = Storage.getPlanById(planId);
      expect(updated?['gender'], 'female');
    } catch (e) {
      fail('updatePlanAsync 写 gender 不应抛出异常: $e');
    }
  });

  test('不提供 gender 时默认落库为 all', () async {
    final planData = <String, dynamic>{
      'name': '默认计划',
      'type': '全身训练',
      'difficulty': '入门',
      'totalWeeks': 8,
      'defaultRestTime': 90,
      'days': <Map<String, dynamic>>[],
    };
    final added = await Storage.addPlanAsync(planData);
    final planId = added['id'] as String;
    final plan = Storage.getPlanById(planId);
    expect(plan?['gender'], 'all');
  });
}
