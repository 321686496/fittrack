import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/pages/data_privacy_page.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('DataPrivacyPage shows clear-data confirmation twice',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DataPrivacyPage()));
    await tester.pump();

    // Tap clear data
    await tester.tap(find.text('清除全部数据'));
    await tester.pumpAndSettle();
    expect(find.textContaining('确认清除'), findsOneWidget);

    // First confirm — tap the 继续 button (NOT the title text 确认清除)
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    // Second confirmation requires text input
    expect(find.byType(TextField), findsOneWidget);
  });
}
