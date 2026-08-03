import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';

/// 国产 ROM 适配引导服务
///
/// 所有设备信息和 ROM 检测都在原生侧完成，Dart 层只做 MethodChannel 封装，
/// 避免引入 device_info_plus 依赖（兼容 Dart 2.19.6 / SDK < 3.3.0 项目）。
class RomAdaptationService {
  RomAdaptationService._();

  static final RomAdaptationService instance = RomAdaptationService._();

  static const String _channelName = 'com.fp.fitplan/rom_adaptation';

  final MethodChannel? _channel =
      isOhos ? null : const MethodChannel(_channelName);

  bool? _cachedIsOemRom;
  bool? _cachedIgnoringBatteryOptimizations;

  /// 是否需要为该设备弹出 ROM 引导（仅国产 ROM 且未优化时返回 true）
  Future<bool> needsRomGuidance() async {
    if (isOhos) return false;
    final isOem = await isOemRom;
    if (!isOem) return false;
    final isIgnoring = await isIgnoringBatteryOptimizations();
    return !isIgnoring;
  }

  /// 是否为国产 ROM
  Future<bool> get isOemRom async {
    if (isOhos) return false;
    if (_cachedIsOemRom != null) return _cachedIsOemRom!;
    try {
      final result = await _channel?.invokeMethod<bool>('isOemRom');
      _cachedIsOemRom = result ?? false;
    } catch (e) {
      debugPrint('RomAdaptation: isOemRom error: $e');
      _cachedIsOemRom = false;
    }
    return _cachedIsOemRom!;
  }

  /// 获取引导标题（ROM 专属文案）
  Future<String> get guidanceTitle async {
    if (isOhos) return '';
    try {
      final result = await _channel?.invokeMethod<String>('getGuidanceTitle');
      return result ?? '请确保 LiftTrack 允许后台运行';
    } catch (e) {
      debugPrint('RomAdaptation: getGuidanceTitle error: $e');
      return '请确保 LiftTrack 允许后台运行';
    }
  }

  /// 获取引导步骤（ROM 专属操作说明）
  Future<String> get guidanceSteps async {
    if (isOhos) return '';
    try {
      final result = await _channel?.invokeMethod<String>('getGuidanceSteps');
      return result ?? '请确保 LiftTrack 允许后台运行和自启动';
    } catch (e) {
      debugPrint('RomAdaptation: getGuidanceSteps error: $e');
      return '请确保 LiftTrack 允许后台运行和自启动';
    }
  }

  /// 是否已忽略电池优化
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (isOhos) return true;
    if (_cachedIgnoringBatteryOptimizations != null) {
      return _cachedIgnoringBatteryOptimizations!;
    }
    try {
      final result = await _channel?.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      _cachedIgnoringBatteryOptimizations = result;
      return result ?? false;
    } catch (e) {
      debugPrint('RomAdaptation: isIgnoringBatteryOptimizations error: $e');
      return _cachedIgnoringBatteryOptimizations ?? true;
    }
  }

  /// 请求忽略电池优化（弹出系统对话框）
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (isOhos) return;
    try {
      await _channel?.invokeMethod<void>('requestIgnoreBatteryOptimizations');
      _cachedIgnoringBatteryOptimizations = true;
    } catch (e) {
      debugPrint('RomAdaptation: requestIgnoreBatteryOptimizations error: $e');
    }
  }

  ///跳转应用详情设置
  Future<void> openAppSettings() async {
    if (isOhos) return;
    try {
      await _channel?.invokeMethod<void>('openAppSettings');
    } catch (e) {
      debugPrint('RomAdaptation: openAppSettings error: $e');
    }
  }

  /// 跳转自启动设置（各品牌专属页面）
  Future<void> openAutoStartSettings() async {
    if (isOhos) return;
    try {
      await _channel?.invokeMethod<void>('openAutoStartSettings');
    } catch (e) {
      debugPrint('RomAdaptation: openAutoStartSettings error: $e');
    }
  }

  ///跳转电池优化设置
  Future<void> openBatteryOptimizationSettings() async {
    if (isOhos) return;
    try {
      await _channel?.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (e) {
      debugPrint('RomAdaptation: openBatteryOptimizationSettings error: $e');
    }
  }

  /// 清除缓存的状态（如用户手动更改了系统设置后需重新检测）
  void clearCache() {
    _cachedIsOemRom = null;
    _cachedIgnoringBatteryOptimizations = null;
  }
}
