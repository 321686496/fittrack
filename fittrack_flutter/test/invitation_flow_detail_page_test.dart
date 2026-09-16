import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:fittrack_flutter/pages/invitation_flow_detail_page.dart';

void main() {
  testWidgets('邀请流程详解页渲染双视角、奖励对照与规则说明', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: const Scaffold(body: InvitationFlowDetailPage()),
      ),
    );
    await tester.pump();

    // 双视角区段
    expect(find.text('邀请人视角'), findsOneWidget);
    expect(find.text('被邀请人视角'), findsOneWidget);

    // 邀请人 6 步标题
    expect(find.text('分享邀请码'), findsOneWidget);
    expect(find.text('好友激活邀请码'), findsOneWidget);
    expect(find.text('好友完成首次训练'), findsOneWidget);
    expect(find.text('好友出示激活凭证'), findsOneWidget);
    expect(find.text('你确认记录成果'), findsOneWidget);
    expect(find.text('奖励自动到账'), findsOneWidget);

    // 被邀请人 4 步标题
    expect(find.text('获取好友邀请码'), findsOneWidget);
    expect(find.text('输入激活'), findsOneWidget);
    expect(find.text('完成首次训练'), findsOneWidget);
    expect(find.text('出示激活凭证'), findsOneWidget);

    // 奖励对照与规则说明
    expect(find.text('奖励对照'), findsOneWidget);
    expect(find.text('规则说明'), findsOneWidget);
    expect(find.text('累计邀请 5 人'), findsOneWidget);
  });
}
