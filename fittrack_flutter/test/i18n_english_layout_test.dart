import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/l10n/i18n.dart';
import 'package:fittrack_flutter/pages/settings_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';
import 'package:fittrack_flutter/widgets/onboarding_coach.dart';
import 'package:fittrack_flutter/widgets/recommendation_banner.dart';

/// 多语言布局冒烟：英文文案普遍比中文长 30%~50%，紧凑布局容易溢出。
///
/// 这里在真实手机尺寸下渲染页面并断言没有抛异常（含 RenderFlex overflow）。
/// 注意 flutter_test 用的是等宽测试字体，拉丁字母按 1em 计宽，比真机更宽，
/// 所以这是一条**悲观**断言：能过，真机一定不溢出。
void main() {
  // iPhone 14 逻辑尺寸
  const phone = Size(390, 844);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  tearDown(() {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
  });

  Future<void> pumpWithLocale(
    WidgetTester tester,
    Widget child, {
    required String languageCode,
  }) async {
    LocaleController.instance.debugOverrideLanguage(
      languageCode == 'en' ? AppLanguage.en : AppLanguage.zh,
    );
    await tester.binding.setSurfaceSize(phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(LocaleScope(
      controller: LocaleController.instance,
      child: MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: child,
      ),
    ));
    await tester.pump();
  }

  Widget settings() => SettingsPage(
        onThemeChanged: (String themeId,
            {bool? followSystem, String? lightThemeId, String? darkThemeId}) {},
      );

  for (final code in ['zh', 'en']) {
    testWidgets('设置页（$code）无布局溢出', (tester) async {
      await pumpWithLocale(tester, settings(), languageCode: code);
      expect(tester.takeException(), isNull, reason: '$code 设置页出现布局异常');
    });

    testWidgets('引导页（$code）无布局溢出', (tester) async {
      await pumpWithLocale(
        tester,
        Scaffold(body: OnboardingCoach(onComplete: (_) {}, onSkip: () {})),
        languageCode: code,
      );
      expect(tester.takeException(), isNull, reason: '$code 引导页出现布局异常');
    });

    testWidgets('推荐横幅（$code）无布局溢出', (tester) async {
      await pumpWithLocale(
        tester,
        Scaffold(body: RecommendationBanner()),
        languageCode: code,
      );
      expect(tester.takeException(), isNull, reason: '$code 推荐横幅出现布局异常');
      // 卸载以取消轮播 Timer
      await tester.pumpWidget(const SizedBox());
    });
  }
}
