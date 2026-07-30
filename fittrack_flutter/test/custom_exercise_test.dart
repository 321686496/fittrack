import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('addCustomExercise 持久化完整字段', () {
    final result = Storage.addCustomExercise({
      'name': '测试动作',
      'category': '胸部',
      'equip': '杠铃',
      'description': '这是一个测试动作的详细描述',
      'muscles': ['胸大肌', '三角肌前束'],
      'steps': [
        {
          'title': '准备姿势',
          'desc': '仰卧于平凳上',
          'keyPoses': ['肩胛后缩'],
        },
      ],
    });

    expect(result['id'], isNotNull);
    expect(result['isCustom'], true);
    expect(result['name'], '测试动作');
    expect(result['description'], '这是一个测试动作的详细描述');
    expect(result['muscles'], ['胸大肌', '三角肌前束']);
    expect((result['steps'] as List).length, 1);

    // 重新读取确认持久化
    final all = Storage.getAllExercises();
    final found = all.firstWhere((e) => e['id'] == result['id']);
    expect(found['description'], '这是一个测试动作的详细描述');
    expect(found['muscles'], ['胸大肌', '三角肌前束']);
    expect((found['steps'] as List).length, 1);
  });

  test('自定义动作与内置动作合并后可区分', () {
    Storage.addCustomExercise({
      'name': '自定义',
      'category': '背部',
      'equip': '哑铃',
      'description': 'desc',
      'muscles': ['背阔肌'],
      'steps': [],
    });
    final all = Storage.getAllExercises();
    final custom = all.where((e) => e['isCustom'] == true).toList();
    expect(custom.length, greaterThanOrEqualTo(1));
    expect(custom.any((e) => e['name'] == '自定义'), true);
  });
}
