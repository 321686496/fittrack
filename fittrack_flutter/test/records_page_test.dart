import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/pages/records_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/src/utils.dart' as sqflite_utils;

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

  testWidgets('记录卡片以2x2网格展示四个统计项且无查看详情提示', (tester) async {
    Storage.addRecord({
      'name': '胸部训练',
      'planName': '三分化计划',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 45,
      'totalSets': 12,
      'totalWeight': 2400,
      'exerciseCount': 4,
      'muscles': ['胸'],
      'setRecords': {
        'e1': [
          {'weight': 60, 'reps': 10, 'rest': 90},
        ],
        'e2': [
          {'weight': 20, 'reps': 12, 'rest': 60},
        ],
      },
      'restLog': [],
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.getTheme('vitality-sport'),
      home: const RecordsPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('时长'), findsOneWidget);
    expect(find.text('组数'), findsOneWidget);
    expect(find.text('重量'), findsOneWidget);
    expect(find.text('动作数'), findsOneWidget);
    expect(find.text('查看详情'), findsNothing);
  });
}
