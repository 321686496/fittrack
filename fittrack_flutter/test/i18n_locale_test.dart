import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// i18n.dart 已导出 AppLanguage / LocaleController，无需重复 import
import 'package:fittrack_flutter/l10n/i18n.dart';

/// 多语言能力的核心用例。
///
/// 注意：`test/flutter_test_config.dart` 会把语言锁定为中文基线，
/// 这里需要验证英文的用例自行 override，并在 tearDown 里改回。
void main() {
  tearDown(() {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
  });

  Widget host(Builder builder) => LocaleScope(
        controller: LocaleController.instance,
        child: MaterialApp(home: builder),
      );

  testWidgets('中文模式：tr 原样返回中文', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    late String actual;
    await tester.pumpWidget(host(Builder(builder: (context) {
      actual = tr(context, '首页');
      return const SizedBox();
    })));
    expect(actual, '首页');
  });

  testWidgets('英文模式：tr 返回英译', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    late String actual;
    await tester.pumpWidget(host(Builder(builder: (context) {
      actual = tr(context, '首页');
      return const SizedBox();
    })));
    expect(actual, 'Home');
  });

  testWidgets('英文模式：词典未命中时回落中文', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    late String actual;
    await tester.pumpWidget(host(Builder(builder: (context) {
      actual = tr(context, '这个串一定没有对应翻译XYZ');
      return const SizedBox();
    })));
    expect(actual, '这个串一定没有对应翻译XYZ');
  });

  testWidgets('带占位符的文案可翻译', (tester) async {
    late String zh;
    late String en;
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    await tester.pumpWidget(host(Builder(builder: (context) {
      zh = tr(context, '第{day}天', {'day': 3});
      return const SizedBox();
    })));
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    await tester.pumpWidget(host(Builder(builder: (context) {
      en = tr(context, '第{day}天', {'day': 3});
      return const SizedBox();
    })));
    expect(zh, '第3天');
    expect(en, isNot('第3天'));
  });

  testWidgets('切换语言后，调用过 tr 的组件自动重建', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    await tester.pumpWidget(host(Builder(
      builder: (context) => Text(tr(context, '训练')),
    )));
    expect(find.text('训练'), findsOneWidget);

    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    await tester.pump();
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('训练'), findsNothing);
  });

  testWidgets('trn 在无 context 场景生效', (tester) async {
    LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
    expect(trn('保存'), 'Save');
    LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
    expect(trn('保存'), '保存');
  });

  group('跟随系统', () {
    testWidgets('系统语言为中文 -> 中文；英文 -> 英文；其他 -> 回落中文', (tester) async {
      LocaleController.instance.debugOverrideLanguage(AppLanguage.system);
      addTearDown(() => LocaleController.debugPlatformLocale = null);

      LocaleController.debugPlatformLocale = const Locale('zh', 'CN');
      expect(LocaleController.instance.languageCode, 'zh');

      LocaleController.debugPlatformLocale = const Locale('en', 'US');
      expect(LocaleController.instance.languageCode, 'en');

      // 不支持的语言：languageCode 只对中文判 zh，其余一律 en；
      // 真正的回落由 localeResolutionCallback 兜到中文
      LocaleController.debugPlatformLocale = const Locale('ja', 'JP');
      expect(LocaleController.instance.languageCode, 'en');
      expect(
        LocaleController.localeResolutionCallback(
          const Locale('ja', 'JP'),
          LocaleController.supportedLocales,
        ),
        const Locale('zh', 'CN'),
      );
    });
  });

  group('LocaleController', () {
    test('语言代码与 Locale 映射', () {
      final c = LocaleController.instance;
      c.debugOverrideLanguage(AppLanguage.zh);
      expect(c.languageCode, 'zh');
      expect(c.locale, const Locale('zh', 'CN'));

      c.debugOverrideLanguage(AppLanguage.en);
      expect(c.languageCode, 'en');
      expect(c.locale, const Locale('en'));

      c.debugOverrideLanguage(AppLanguage.system);
      expect(c.locale, isNull);
      expect(['zh', 'en'], contains(c.languageCode));
    });

    test('不支持的系统语言回落到中文', () {
      final resolved = LocaleController.localeResolutionCallback(
        const Locale('ja'),
        LocaleController.supportedLocales,
      );
      expect(resolved, const Locale('zh', 'CN'));

      final enResolved = LocaleController.localeResolutionCallback(
        const Locale('en', 'US'),
        LocaleController.supportedLocales,
      );
      expect(enResolved, const Locale('en'));
    });

    test('AppLanguage.fromCode 解析', () {
      expect(AppLanguage.fromCode('zh'), AppLanguage.zh);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode(null), AppLanguage.system);
      expect(AppLanguage.fromCode('fr'), AppLanguage.system);
    });
  });
}
