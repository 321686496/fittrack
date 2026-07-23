// 复现“采用系统训练计划无反应”bug 的回归测试
// 根因：toStoragePlan() 写入了 sourcePlanId / isFromSystemLibrary 字段，
// addPlanAsync 又写入 currentDayIndex 字段，但 plans 表 schema 没有这些列，
// 导致 INSERT 抛 no such column 异常，外层 _adoptPlan 没有 try/catch 静默失败。
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/system_plan_library.dart';
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

  test(
    '采用系统计划：toStoragePlan() + addPlanAsync 应成功持久化',
    () async {
      // 模拟 SystemPlanLibrary 中 SystemPlan 的 toStoragePlan() 输出
      // 注意：isFromSystemLibrary 必须是 int（SQLite 不支持 bool）
      final systemStoragePlan = <String, dynamic>{
        'id': 'user_test_${DateTime.now().millisecondsSinceEpoch}_bulk_beginner_4w',
        'name': '入门增肌 4 周',
        'type': '3day_split',
        'frequency': 3,
        'difficulty': 'beginner',
        'totalWeeks': 4,
        'defaultRestTime': 90,
        'days': <Map<String, dynamic>>[],
        'week': 1,
        'progress': 0,
        'status': 'active',
        'sourcePlanId': 'bulk_beginner_4w',
        'isFromSystemLibrary': 1,
        'createTime': DateTime.now().millisecondsSinceEpoch,
        'updateTime': DateTime.now().millisecondsSinceEpoch,
      };

      // 模拟 plan_library_detail_page._adoptPlan 流程
      await Storage.addPlanAsync(systemStoragePlan);

      // 验证计划已持久化（同步缓存应立即反映新计划）
      final plans = Storage.getPlans();
      expect(plans, hasLength(1));
      expect(plans.first['name'], '入门增肌 4 周');
      expect(plans.first['sourcePlanId'], 'bulk_beginner_4w');
      expect(plans.first['currentDayIndex'], 0);
    },
  );

  test(
    'SystemPlan.toStoragePlan 与数据库 schema 一致（无未知列）',
    () async {
      // 直接使用真实 toStoragePlan 输出测试
      final plan = SystemPlan(
        id: 'bulk_beginner_4w',
        name: '入门增肌 4 周',
        goal: 'bulk',
        difficulty: 'beginner',
        trainingType: '3day_split',
        isPremium: false,
        pointsCost: 0,
        totalWeeks: 4,
        defaultRestTime: 90,
        description: 'desc',
        coverEmoji: '💪',
        coverColors: const ['#FF6B6B', '#C44D4D'],
        tags: const [],
        recommendedFrequency: 3,
        suitableFor: '',
        days: const [],
      );
      final storagePlan = plan.toStoragePlan();

      // 不应抛出 no such column / bool type 异常
      await Storage.addPlanAsync(storagePlan);

      final plans = Storage.getPlans();
      expect(plans, hasLength(1));
      expect(plans.first['sourcePlanId'], 'bulk_beginner_4w');
      // isFromSystemLibrary 存为 int
      expect(plans.first['isFromSystemLibrary'], 1);
    },
  );

  test(
    '采用计划后，同步 getPlans() 应立即可见（缓存一致性）',
    () async {
      final plan = SystemPlan(
        id: 'cut_intermediate_8w',
        name: '减脂进阶 8 周',
        goal: 'cut',
        difficulty: 'intermediate',
        trainingType: '4day_split',
        isPremium: false,
        pointsCost: 0,
        totalWeeks: 8,
        defaultRestTime: 60,
        description: 'desc',
        coverEmoji: '🔥',
        coverColors: const ['#4ECDC4', '#44A3AA'],
        tags: const [],
        recommendedFrequency: 4,
        suitableFor: '',
        days: const [],
      );
      await Storage.addPlanAsync(plan.toStoragePlan());

      // 模拟 plan_page._loadPlans() 同步读取
      final plans = Storage.getPlans();
      expect(plans.any((p) => p['name'] == '减脂进阶 8 周'), isTrue,
          reason: '采用后 plan_page 应立即显示新计划');
    },
  );
}
