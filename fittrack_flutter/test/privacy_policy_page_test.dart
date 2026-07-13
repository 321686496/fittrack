import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/pages/privacy_policy_page.dart';

void main() {
  testWidgets('PrivacyPolicyPage renders 7 PIPL sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    expect(find.text('FitTrack 隐私政策'), findsOneWidget);
    expect(find.text('一、我们收集的信息'), findsOneWidget);
    expect(find.text('七、联系方式'), findsOneWidget);
  });
}
