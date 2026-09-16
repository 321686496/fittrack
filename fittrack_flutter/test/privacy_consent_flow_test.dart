import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/legal/legal_content.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/pages/splash_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';

void main() {
  setUp(() {
    // 重置设置内存态，模拟全新安装（首次启动未同意协议）
    Storage.saveSettings(<String, dynamic>{});
  });

  Future<void> pumpSplash(
    WidgetTester tester, {
    required VoidCallback onReady,
    required VoidCallback onShowOnboarding,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: SplashPage(onReady: onReady, onShowOnboarding: onShowOnboarding),
      ),
    );
  }

  testWidgets('首次启动：完整动画（2s）后弹出同意弹窗，不自动跳转', (tester) async {
    var ready = false;
    var onboarding = false;
    await pumpSplash(
      tester,
      onReady: () => ready = true,
      onShowOnboarding: () => onboarding = true,
    );

    // 2s 前：只有 splash，无弹窗
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('同意并继续'), findsNothing);

    // 2s 后：弹出同意弹窗，且未自动跳转
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('同意并继续'), findsOneWidget);
    expect(find.text('不同意并退出'), findsOneWidget);
    expect(find.text('《用户协议》'), findsOneWidget);
    expect(find.text('《隐私政策》'), findsOneWidget);
    expect(ready, isFalse);
    expect(onboarding, isFalse);
  });

  testWidgets('点击「同意并继续」：保存协议版本并进入引导页', (tester) async {
    var ready = false;
    var onboarding = false;
    await pumpSplash(
      tester,
      onReady: () => ready = true,
      onShowOnboarding: () => onboarding = true,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('同意并继续'));
    await tester.pump();
    await tester.pump();

    final settings = Storage.getSettings();
    expect(settings['privacyAgreed'], isTrue);
    expect(settings['privacyAgreedVersion'], privacyPolicyVersion);
    expect(onboarding, isTrue);
    expect(ready, isFalse);
  });

  testWidgets('老用户（已同意当前版本）：约 0.4s 快速进入，无弹窗', (tester) async {
    Storage.saveSettings(<String, dynamic>{
      'privacyAgreed': true,
      'privacyAgreedVersion': privacyPolicyVersion,
      'onboardingDone': true,
    });
    var ready = false;
    var onboarding = false;
    await pumpSplash(
      tester,
      onReady: () => ready = true,
      onShowOnboarding: () => onboarding = true,
    );

    // 0.4s 前：不跳转、无弹窗
    await tester.pump(const Duration(milliseconds: 300));
    expect(ready, isFalse);
    expect(find.text('同意并继续'), findsNothing);

    // 0.4s 后：直接进入主页，全程无弹窗
    await tester.pump(const Duration(milliseconds: 200));
    expect(ready, isTrue);
    expect(find.text('同意并继续'), findsNothing);
  });

  testWidgets('协议版本升级：老用户需重新同意', (tester) async {
    Storage.saveSettings(<String, dynamic>{
      'privacyAgreed': true,
      'privacyAgreedVersion': 'v2.0',
      'onboardingDone': true,
    });
    var ready = false;
    await pumpSplash(
      tester,
      onReady: () => ready = true,
      onShowOnboarding: () {},
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('同意并继续'), findsOneWidget);
    expect(ready, isFalse);
  });
}
