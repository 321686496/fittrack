import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/l10n/locale_controller.dart';

/// flutter_test 会自动加载 test/flutter_test_config.dart 中的 testExecutable。
///
/// 这里做两件全局准备工作：
///
/// 1. **把测试语言锁定为简体中文**
///    flutter_test 的默认 locale 是 en_US，而本项目既有的 widget / service 用例
///    断言的都是中文文案。接入多语言后若跟随系统语言，这些断言会全部失败。
///
/// 2. **给原生 MethodChannel 兜底 mock**
///    本项目的原生通道（device_identity / reminder / permission 等）在测试环境
///    没有实现端，调用后 Future 永不完成，会把用例拖到 10 分钟超时
///    （典型受害者：`onboarding_coach_test` 的 `Storage.init()`）。
///    这里统一注册返回空值的 mock，避免整条用例被挂死。
///
/// 若某个用例需要验证英文，可在用例内部调用：
/// ```dart
/// LocaleController.instance.debugOverrideLanguage(AppLanguage.en);
/// ```
/// 并在 tearDown 里改回 AppLanguage.zh。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LocaleController.instance.debugOverrideLanguage(AppLanguage.zh);
  _mockNativeChannels();
  await testMain();
}

/// 项目用到的全部原生通道。
const List<String> _nativeChannels = [
  'com.lt.lifttrack/device_identity',
  'com.lt.lifttrack/invite',
  'com.lt.lifttrack/liveview',
  'com.lt.lifttrack/permission',
  'com.lt.lifttrack/poster',
  'com.lt.lifttrack/reminder',
  'com.lt.lifttrack/widget',
];

void _mockNativeChannels() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in _nativeChannels) {
    MethodChannel(name).setMockMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'requestTrackingPermission':
          return false;
        case 'getPersistentDeviceId':
          return null;
        default:
          return null;
      }
    });
  }
}
