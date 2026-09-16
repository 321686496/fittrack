// 最大重量记录：验证 MaxWeightService 兼容训练页实际保存的 setRecords 格式
// （修复前：只扫描旧版 exercises[].sets 格式，训练后的最大重量永远不更新）
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/max_weight_service.dart';
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
    await Storage.savePlansAsync([]);
    await Storage.saveRecordsAsync([]);
    await Storage.getPlansAsync();
    await Storage.getRecordsAsync();
  });

  test('setRecords 新格式：训练完成后最大重量应被记录（getGlobalMax）', () {
    // 模拟 training_page._autoSaveTraining 保存的记录结构
    Storage.addRecord({
      'name': '胸部 + 三头肌',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 55,
      'totalWeight': 3000,
      'totalSets': 18,
      'exerciseCount': 5,
      'muscles': ['胸部'],
      'setRecords': {
        'e1': [
          {'set': 1, 'weight': 60.0, 'reps': 8, 'rest': 90},
          {'set': 2, 'weight': 62.5, 'reps': 6, 'rest': 90},
        ],
        'e2': [
          {'set': 1, 'weight': 12.0, 'reps': 12, 'rest': 60},
        ],
      },
      'planId': 'plan_test',
      'planName': '测试计划',
    });

    final globalMax = MaxWeightService.instance.getGlobalMax();
    expect(globalMax, isNotNull);
    // e1 = 杠铃卧推（MockData），两组中最大重量 62.5
    expect(globalMax!.exerciseName, '杠铃卧推');
    expect(globalMax.weight, 62.5);
    expect(globalMax.muscleGroup, '胸部');
  });

  test('setRecords 新格式：按部位分组的 Top N 应包含训练动作', () {
    Storage.addRecord({
      'name': '背部 + 二头肌',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 65,
      'totalWeight': 4000,
      'totalSets': 20,
      'exerciseCount': 6,
      'muscles': ['背部'],
      'setRecords': {
        'e6': [
          {'set': 1, 'weight': 70.0, 'reps': 8, 'rest': 90},
        ],
        'e13': [
          {'set': 1, 'weight': 15.0, 'reps': 12, 'rest': 60},
        ],
      },
    });

    final grouped = MaxWeightService.instance.getTopByMuscleGroup();
    expect(grouped['背部'], isNotNull);
    expect(grouped['背部']!.first.exerciseName, '杠铃划船');
    expect(grouped['背部']!.first.weight, 70.0);
    expect(grouped['手臂'], isNotNull);
    expect(grouped['手臂']!.first.exerciseName, '哑铃弯举');
    expect(grouped['手臂']!.first.weight, 15.0);

    final maxByGroup = MaxWeightService.instance.getMaxByMuscleGroup();
    expect(maxByGroup['背部'], 70.0);
  });

  test('自定义计划动作：id 不在 MockData 中时应从计划解析名称', () async {
    await Storage.addPlanAsync({
      'name': '自定义计划',
      'days': [
        {
          'day': 1,
          'label': '腿部',
          'muscle': '腿',
          'exercises': [
            {'id': 'custom_ex9', 'name': '自定义硬拉', 'sets': 3, 'reps': '5', 'weight': 100.0},
          ],
        },
      ],
    });

    Storage.addRecord({
      'name': '腿部',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 40,
      'totalWeight': 1000,
      'totalSets': 3,
      'exerciseCount': 1,
      'muscles': ['腿部'],
      'setRecords': {
        'custom_ex9': [
          {'set': 1, 'weight': 120.0, 'reps': 5, 'rest': 120},
        ],
      },
    });

    final globalMax = MaxWeightService.instance.getGlobalMax();
    expect(globalMax, isNotNull);
    expect(globalMax!.exerciseName, '自定义硬拉');
    expect(globalMax.weight, 120.0);
    // 计划动作无 category，按名称关键字推断：硬拉 → 背部
    expect(globalMax.muscleGroup, '背部');
  });

  test('多条记录：取全部记录中的全局最大重量', () {
    Storage.addRecord({
      'name': '训练1',
      'date': DateTime.now().millisecondsSinceEpoch,
      'setRecords': {
        'e9': [
          {'set': 1, 'weight': 90.0, 'reps': 5},
        ],
      },
    });
    Storage.addRecord({
      'name': '训练2',
      'date': DateTime.now().millisecondsSinceEpoch,
      'setRecords': {
        'e1': [
          {'set': 1, 'weight': 100.0, 'reps': 5},
        ],
      },
    });

    final globalMax = MaxWeightService.instance.getGlobalMax();
    expect(globalMax, isNotNull);
    expect(globalMax!.exerciseName, '杠铃卧推');
    expect(globalMax.weight, 100.0);
  });
}
