import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/l10n/i18n.dart';
import 'package:fittrack_flutter/pages/settings_page.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';

/// 设置页「语言」区块的端到端用例：点击 chip 后整页文案应立即切换。
void main() {
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(LocaleScope(
      controller: LocaleController.instance,
      child: MaterialApp(
        theme: AppTheme.getTheme('vitality-sport'),
        home: SettingsPage(
          onThemeChanged: (String themeId,
              {bool? followSystem, String? lightThemeId, String? darkThemeId}) {},
        ),
      ),
    ));
    await tester.pump();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  tearDown(() {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
  });

  testWidgets('语言区块渲染三个选项', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    await pumpSettings(tester);

    expect(find.text('语言'), findsWidgets);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('点击 English 后整页切换为英文', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    await pumpSettings(tester);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(LocaleController.instance.language, AppLanguage.en);
    expect(LocaleController.instance.languageCode, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('设置'), findsNothing);
  });

  testWidgets('英文模式下三个选项也显示英文', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    await pumpSettings(tester);

    expect(find.text('Language'), findsWidgets);
    expect(find.text('Follow System'), findsOneWidget);
    expect(find.text('Simplified Chinese'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('点击 Simplified Chinese 可切回中文', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    await pumpSettings(tester);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Simplified Chinese'));
    await tester.pump();

    expect(LocaleController.instance.language, AppLanguage.zh);
    expect(find.text('设置'), findsOneWidget);
  });
}
