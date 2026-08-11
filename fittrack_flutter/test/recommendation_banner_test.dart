import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/data/storage.dart';
import '../lib/themes/app_themes.dart';
import '../lib/widgets/recommendation_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Storage.getSettings 依赖 SQLite，测试环境需初始化 ffi databaseFactory
  // （与 recommendation_service_test.dart 等项目测试保持一致）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    Storage.clearAll();
  });

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: const Scaffold(body: RecommendationBanner()),
      ),
    );
    await tester.pump();
  }

  group('RecommendationBanner 邀请进度会话内刷新', () {
    testWidgets('邀请入账后横幅自动更新进度（0→1）', (tester) async {
      await pumpBanner(tester);
      // 初始：无邀请 → 已邀请 0 / 1 人
      expect(find.textContaining('已邀请 0 / 1'), findsOneWidget);

      // 模拟邀请入账（第 1 人）：写入 myReferralCodes 并触发数据变更通知
      final settings = Storage.getSettings();
      final list = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
      list.add('FIT-ACT-TESTCODE00000');
      settings['myReferralCodes'] = list;
      Storage.saveSettings(settings);
      Storage.dataChanged.value = !Storage.dataChanged.value;
      await tester.pump();

      // 刷新后：已邀请 1 / 3 人
      expect(find.textContaining('已邀请 1 / 3'), findsOneWidget);

      // 收尾：卸载组件以取消轮播 Timer，避免 pending timer 报错
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('无关数据变更不改变邀请进度显示', (tester) async {
      await pumpBanner(tester);
      expect(find.textContaining('已邀请 0 / 1'), findsOneWidget);

      // 仅触发无关数据变更（不修改 myReferralCodes）
      Storage.dataChanged.value = !Storage.dataChanged.value;
      await tester.pump();

      // 进度应保持不变
      expect(find.textContaining('已邀请 0 / 1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
