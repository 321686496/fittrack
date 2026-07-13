import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/pages/user_agreement_page.dart';

void main() {
  testWidgets('UserAgreementPage renders 7 agreement sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UserAgreementPage()));
    await tester.pumpAndSettle();

    expect(find.text('FitTrack 用户协议'), findsOneWidget);
    const sections = [
      '一、服务说明',
      '二、虚拟商品不退换',
      '三、用户行为规范',
      '四、个人开发者免责声明',
      '五、账号注销',
      '六、知识产权',
      '七、争议解决',
    ];
    for (final section in sections) {
      expect(find.text(section), findsOneWidget, reason: 'missing section: $section');
    }
  });
}
