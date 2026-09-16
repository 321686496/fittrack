import 'package:flutter/material.dart';

import 'locale_controller.dart';
import 'strings_en.dart';

export 'locale_controller.dart' show AppLanguage, LocaleController;

/// 把语言控制器注入整棵 Widget 树。
///
/// 必须放在 MaterialApp **之上**，这样路由页、弹窗等所有子树都能读到当前语言，
/// 并在语言切换时收到依赖通知而重建。
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    // 未挂载 LocaleScope（如单元测试）时回落到全局单例，保证不崩
    return scope?.notifier ?? LocaleController.instance;
  }
}

/// 无 context 场景的翻译（数据层 / 服务层 / 静态常量等）。
///
/// 注意：调用处不会随语言切换自动重建，需由上层 Widget 自行重建后重新读取。
String trn(String text, [Map<String, Object?>? args]) {
  return _translate(LocaleController.instance.languageCode, text, args);
}

/// 带 context 的翻译：注册对 [LocaleScope] 的依赖，语言切换时自动重建。
String tr(BuildContext context, String text, [Map<String, Object?>? args]) {
  final controller = LocaleScope.of(context);
  return _translate(controller.languageCode, text, args);
}

String _translate(String languageCode, String text, Map<String, Object?>? args) {
  final translated = languageCode == 'zh' ? text : I18nStrings.translate(text);
  if (args == null || args.isEmpty) return translated;
  var result = translated;
  for (final entry in args.entries) {
    result = result.replaceAll('{${entry.key}}', '${entry.value}');
  }
  return result;
}

/// 按语言代次缓存的数据构造器，用来解决数据层文案被"冻结"的问题。
///
/// 背景：`lib/data/**` 里大量集合是 `static final List<X> xxx = [ trn('中文'), ... ]`。
/// `static final` 只初始化一次，所以里面 `trn()` 的结果会被永久冻结在**首次访问时**
/// 的语言——用户在设置页切到英文后，动作名、课程正文、教学文案仍然是中文。
///
/// 用法（把原来的 `static final` 声明改写成 memo + getter）：
///
/// ```dart
/// static List<Course> get courses => _coursesMemo.value;
/// static final LocaleMemo<List<Course>> _coursesMemo = LocaleMemo(() => [
///   Course(title: trn('新手增肌入门')),
/// ]);
/// ```
///
/// 这样：同一语言下只构造一次（不牺牲性能），语言切换后首次访问自动重建
/// （文案跟随语言），且同一语言内对象实例保持稳定（`identical` 判断不受影响）。
///
/// 注意：**用作身份标识（Map key / 相等判断 / 持久化字段）的中文字面量不要放进 memo**，
/// 它们必须与语言无关，直接写中文字面量即可。
class LocaleMemo<T> {
  LocaleMemo(this._builder);

  final T Function() _builder;
  T? _value;
  int _generation = -1;

  T get value {
    final generation = LocaleController.instance.generation;
    if (_generation != generation || _value == null) {
      _value = _builder();
      _generation = generation;
    }
    return _value as T;
  }
}
