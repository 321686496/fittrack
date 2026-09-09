import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/pages/record_detail_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/src/utils.dart' as sqflite_utils;

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.getTheme('vitality-sport'),
      home: child,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 禁用 sqflite 锁警告超时 Timer：Storage.addRecord 的 fire-and-forget
    // 持久化在 fake_async 环境下会留下 pending Timer，导致 testWidgets 失败
    sqflite_utils.lockWarningDuration = null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.savePlansAsync([]);
    await Storage.saveRecordsAsync([]);
    await Storage.getPlansAsync();
    await Storage.getRecordsAsync();
  });

  testWidgets('详情页显示自定义动作名称而非动作id', (tester) async {
    final custom = Storage.addCustomExercise({
      'name': '我的自定义动作',
      'category': '胸部',
      'equip': '哑铃',
    });
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 240,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        custom['id']: [
          {'weight': 30, 'reps': 4, 'rest': 90},
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('我的自定义动作'), findsOneWidget);
    expect(find.text('未知动作'), findsNothing);
  });

  testWidgets('id不在任何动作来源中时显示未知动作', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 1,
      'totalWeight': 120,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'nonexistent_id': [
          {'weight': 120, 'reps': 1, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('未知动作'), findsOneWidget);
  });
}
