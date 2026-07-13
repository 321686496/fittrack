import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/pages/privacy_policy_page.dart';

void main() {
  testWidgets('PrivacyPolicyPage renders 7 PIPL sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    expect(find.text('FitTrack 隐私政策'), findsOneWidget);
    const sections = [
      '一、我们收集的信息',
      '二、信息使用方式',
      '三、信息存储位置',
      '四、第三方 SDK 信息共享',
      '五、未成年人保护',
      '六、用户权利',
      '七、联系方式',
    ];
    for (final section in sections) {
      expect(find.text(section), findsOneWidget, reason: 'missing section: $section');
    }
  });
}
