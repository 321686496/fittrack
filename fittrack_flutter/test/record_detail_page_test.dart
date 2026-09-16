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

  testWidgets('动作卡片展示汇总信息', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 500,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
          {'weight': 35, 'reps': 2, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    // 总容量 30×4 + 35×2 = 190
    expect(find.text('190kg'), findsOneWidget);
    // 最重组 35kg×2
    expect(find.text('35kg×2'), findsOneWidget);
    // 总次数 4 + 2 = 6
    expect(find.text('6次'), findsOneWidget);
  });

  testWidgets('多动作记录显示容量分析图表卡片', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 2,
      'totalWeight': 220,
      'exerciseCount': 2,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
        'e2': [
          {'weight': 20, 'reps': 5, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('容量分析'), findsOneWidget);
    // 30×4 + 20×5 = 220
    expect(find.text('合计 220kg'), findsOneWidget);
  });

  testWidgets('单动作记录不显示容量分析图表卡片', (tester) async {
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
        'e1': [
          {'weight': 30, 'reps': 4, 'rest': 90},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    expect(find.text('容量分析'), findsNothing);
  });

  testWidgets('畸形setRecords值不导致详情页崩溃', (tester) async {
    final record = Storage.addRecord({
      'name': '测试训练',
      'planName': '测试计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 30,
      'totalSets': 1,
      'totalWeight': 100,
      'exerciseCount': 1,
      'muscles': ['胸'],
      'setRecords': {
        'e1': 'oops',
      },
      'restLog': [],
    });

    await tester.pumpWidget(
        _wrap(RecordDetailPage(recordId: record['id'] as String)));
    await tester.pumpAndSettle();

    // 页面正常渲染，不崩溃
    expect(find.text('测试计划'), findsOneWidget);
  });
}
