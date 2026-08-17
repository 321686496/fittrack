import 'dart:io';

/// 检测当前平台是否为 OHOS (HarmonyOS)
///
/// 注意:不能直接使用 Platform.isOhos。OHOS fork 版本 Flutter SDK 中,
/// Platform.isOhos 静态字段在 Android 平台上会导致 JIT 编译错误
/// "Unimplemented handling of missing static target"。
/// 使用 Platform.operatingSystem == 'ohos' 可避免此问题。
bool get isOhos => Platform.operatingSystem == 'ohos';

/// 是否为 iOS 平台（OHOS 上恒为 false）
bool get isIos => Platform.isIOS;
