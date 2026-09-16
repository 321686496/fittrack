import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/storage.dart';

/// 应用语言选项。
///
/// - [system]：跟随系统语言（默认）
/// - [zh]：简体中文
/// - [en]：English
enum AppLanguage {
  system('system'),
  zh('zh'),
  en('en');

  final String code;

  const AppLanguage(this.code);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'zh':
        return AppLanguage.zh;
      case 'en':
        return AppLanguage.en;
      default:
        return AppLanguage.system;
    }
  }
}

/// 语言控制器：负责语言偏好的持久化、生效语言的计算与变更通知。
///
/// 通过 [LocaleScope]（InheritedNotifier）下发到整棵 Widget 树，
/// 任何调用过 `tr(context, ...)` 的组件都会在切换语言时自动重建。
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const Locale zhLocale = Locale('zh', 'CN');
  static const Locale enLocale = Locale('en');

  /// 支持的语言列表（传给 MaterialApp.supportedLocales）
  static const List<Locale> supportedLocales = [zhLocale, enLocale];

  AppLanguage _language = AppLanguage.system;

  /// 用户选择的语言（可能是 [AppLanguage.system]）
  AppLanguage get language => _language;

  int _generation = 0;

  /// 语言代次。每当生效语言可能发生变化时自增。
  ///
  /// 数据层（`lib/data/**`）里的文案集合用 [LocaleMemo] 按这个代次缓存：
  /// 切语言后首次访问会重新构造，从而让 `trn()` 的结果跟随语言变化，
  /// 而不是被 `static final` 冻结在首次访问时的语言。
  int get generation => _generation;

  void _notifyLanguageChanged() {
    _generation++;
    notifyListeners();
  }

  /// 从持久化设置中恢复语言偏好。在 `Storage.init()` 之后调用。
  Future<void> init() async {
    final settings = Storage.getSettings();
    _language = AppLanguage.fromCode(settings['languageCode'] as String?);
    _notifyLanguageChanged();
  }

  /// 切换语言并持久化。
  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    _notifyLanguageChanged();
    final settings = Storage.getSettings();
    settings['languageCode'] = language.code;
    Storage.saveSettings(settings);
  }

  /// 测试专用：强制设置语言，**不写持久化**。
  ///
  /// 背景：flutter_test 默认 locale 是 en_US，而既有的 widget / service 测试
  /// 断言的是中文文案（例如 `expect(find.text('胸部'), findsOneWidget)`）。
  /// 若放任跟随系统，这些断言会全部失败。因此在 `test/flutter_test_config.dart`
  /// 里统一锁定中文基线；需要验证英文的用例可在内部自行覆盖。
  void debugOverrideLanguage(AppLanguage language) {
    _language = language;
    _notifyLanguageChanged();
  }

  /// 测试专用：覆盖「系统语言」。
  ///
  /// `ui.PlatformDispatcher.instance.locale` 无法在测试中注入，而「跟随系统」
  /// 分支又需要被验证，因此留一个显式钩子。生产环境恒为 null。
  static ui.Locale? debugPlatformLocale;

  /// 当前生效的语言代码：'zh' 或 'en'。
  ///
  /// 选择「跟随系统」时，依据平台语言推断；非中文一律回落到英文。
  String get languageCode {
    switch (_language) {
      case AppLanguage.zh:
        return 'zh';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.system:
        final platformLocale =
            debugPlatformLocale ?? ui.PlatformDispatcher.instance.locale;
        // 部分平台 locale 可能携带 scriptCode（如 zh_Hans_CN），统一取 languageCode 判断
        return platformLocale.languageCode.toLowerCase().startsWith('zh')
            ? 'zh'
            : 'en';
    }
  }

  bool get isEnglish => languageCode == 'en';

  /// 传给 MaterialApp 的 locale。
  /// 返回 null 表示完全交给系统/框架解析（此时仍需 supportedLocales 兜底）。
  Locale? get locale {
    switch (_language) {
      case AppLanguage.zh:
        return zhLocale;
      case AppLanguage.en:
        return enLocale;
      case AppLanguage.system:
        return null;
    }
  }

  /// locale 解析回调：系统语言不在支持列表时回落到中文。
  static Locale localeResolutionCallback(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale != null) {
      for (final l in supportedLocales) {
        if (l.languageCode == deviceLocale.languageCode) return l;
      }
    }
    return zhLocale;
  }
}
