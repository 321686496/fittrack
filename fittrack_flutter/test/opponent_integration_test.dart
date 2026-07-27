import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/virtual_opponent.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_renderer.dart';
import 'package:fittrack_flutter/widgets/virtual_opponent_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('VirtualOpponentCard renders OpponentRenderer instead of emoji',
      (tester) async {
    // 注入测试对手
    final opponent = VirtualOpponent(
      id: 'test',
      nickname: '测试对手',
      tier: OpponentTier.regular,
      avatarSeed: 'test',
      persona: '测试',
      weeklyTrainings: 3,
    );
    Storage.saveSettings({'virtualOpponentData': opponent.toJson()});

    // 注：VirtualOpponentCard 实际构造函数仅接受 onTap，
    // 数据从 Storage 读取（plan 中的 opponent/userWeeklyTrainings 参数不存在，
    // 按任务约束"如签名不同，调整测试代码以匹配实际签名"处理）
    // 使用 AppTheme 提供主题（含 FitTrackColors 扩展，否则 Theme.of(context).extension<FitTrackColors>()! 会 null）
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: const Scaffold(
          body: VirtualOpponentCard(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });
}
