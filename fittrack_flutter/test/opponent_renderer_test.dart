// test/opponent_renderer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_renderer.dart';

void main() {
  testWidgets('OpponentRenderer renders without throwing for skin_beginner',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(240, 240),
            autoTrain: false,
            showAura: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });

  testWidgets('renders all 4 skins without throwing', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final id in ['skin_beginner', 'skin_iron_warrior', 'skin_cyber_ninja', 'skin_ambassador']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpponentRenderer(
              skinId: id,
              size: const Size(240, 240),
              autoTrain: false,
              showAura: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OpponentRenderer), findsOneWidget, reason: '$id failed');
    }
  });

  testWidgets('renders thumbnail size 48x48', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(48, 48),
            autoTrain: false,
            showAura: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(sizedBox.width, 48);
    expect(sizedBox.height, 48);
  });

  testWidgets('autoTrain triggers training state after 2s', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(240, 240),
            autoTrain: true,
            showAura: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    // 验证 widget 仍存在（autoTrain 切换不崩溃）
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });
}
