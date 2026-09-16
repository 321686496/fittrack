import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:fittrack_flutter/pages/points_detail_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Storage.getSettings 依赖 SQLite，测试环境需初始化 ffi databaseFactory
  // （与 invitation_service_test.dart 等项目测试保持一致）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Storage.init/clearAll 涉及真实异步 I/O，须在 testWidgets 的
  // FakeAsync zone 之外完成（与 records_page_test.dart 做法一致），
  // 否则 await 会永久挂起导致测试超时
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.clearAll();
    Storage.saveSettings(<String, dynamic>{});
    await Storage.init();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // 页面回调使用 go_router（context.push/pop），用最小路由包装
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PointsDetailPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.getTheme('vitality-sport'),
      ),
    );
    await tester.pump();
  }

  testWidgets('邀请里程碑与被邀请奖励显示友好标签', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = Storage.getSettings();
    settings['pointsLog'] = jsonEncode([
      {'time': now, 'delta': 300, 'source': 'invite_milestone_3', 'balance': 400},
      {'time': now, 'delta': 50, 'source': 'invited', 'balance': 100},
    ]);
    Storage.saveSettings(settings);

    await pumpPage(tester);

    // 修复前：invite_milestone_3 显示原始字符串
    expect(find.text('邀请里程碑（第 3 人）'), findsOneWidget);
    // invited 显示为「邀请好友」（积分获取途径区段也含同名文案，≥2 处）
    expect(find.text('邀请好友'), findsNWidgets(2));
  });

  testWidgets('「邀请」筛选器匹配 invited 与 invite_milestone', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = Storage.getSettings();
    settings['pointsLog'] = jsonEncode([
      {'time': now, 'delta': 300, 'source': 'invite_milestone_3', 'balance': 400},
      {'time': now, 'delta': 50, 'source': 'invited', 'balance': 100},
      {'time': now, 'delta': 10, 'source': 'checkIn', 'balance': 10},
    ]);
    Storage.saveSettings(settings);

    await pumpPage(tester);

    // 切换到「邀请」筛选
    await tester.tap(find.text('邀请'));
    await tester.pump();

    // 修复前：invite 分支不匹配 invited/invite_milestone_* → 空列表
    expect(find.text('暂无该类型记录'), findsNothing);
    expect(find.text('邀请里程碑（第 3 人）'), findsOneWidget);
    expect(find.text('邀请好友'), findsNWidgets(2));
    // checkIn 条目被过滤（「每日签到」仅剩积分获取途径区段的同名文案 1 处）
    expect(find.text('每日签到'), findsOneWidget);
  });
}
