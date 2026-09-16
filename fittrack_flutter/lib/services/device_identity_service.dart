import 'package:flutter/services.dart';
import '../data/storage.dart';
import '../utils/platform_utils.dart';

/// 持久设备标识服务
///
/// 返回各平台**卸载重装后仍稳定**的设备标识，用于邀请码防刷身份：
/// - Android: Settings.Secure.ANDROID_ID（同签名+同用户+同设备稳定，无需权限）
/// - iOS: UIDevice.identifierForVendor（卸载重装稳定）
/// - OHOS: OAID（开放匿名设备标识符，identifier.getOAID）——设备级匿名标识，
///   卸载重装后不变（仅恢复出厂设置/用户手动重置才变）。
///   获取需 ohos.permission.APP_TRACKING_CONSENT（user_grant 动态权限）：
///   - 未授权 / 系统"跨应用关联访问权限"关闭 → 返回全 0 → 视为不可用，回退随机 deviceId
///   - 必须在用户同意隐私协议后才能获取（华为审核合规要求）
///
/// 单机版防刷的核心前提是"设备身份跨重装不变"；本服务负责把这个持久标识
/// 暴露给 Dart 侧，并由 Storage.init() 落地缓存。
class DeviceIdentityService {
  DeviceIdentityService._();
  static final DeviceIdentityService instance = DeviceIdentityService._();

  static const MethodChannel _channel =
      MethodChannel('com.lt.lifttrack/device_identity');

  /// OAID 全 0 值：未声明权限 / 未授权 / 跨应用关联被系统禁止时的返回值
  static const String _zeroOaid = '00000000-0000-0000-0000-000000000000';

  /// 获取持久设备标识；不可用或为空时返回空字符串，由调用方回退。
  ///
  /// OHOS 特殊处理：
  /// 1. 隐私合规：用户未同意隐私协议前不触发 getOAID 调用
  /// 2. 全 0 OAID（未授权/跨应用关联关闭）视为不可用，返回空串
  Future<String> getPersistentDeviceId() async {
    // OHOS 的 OAID 属于广告跟踪标识，按华为审核要求必须在用户同意隐私协议后获取；
    // 未同意前直接返回空串，不发起原生调用
    if (isOhos && Storage.getSettings()['privacyAgreed'] != true) {
      return '';
    }
    try {
      final id = await _channel.invokeMethod<String>('getPersistentDeviceId');
      if (id == null || id.isEmpty) return '';
      if (id == _zeroOaid) return '';
      // 兜底：任何形态的全 0（如去掉连字符后全 0）都视为无效
      if (id.replaceAll('-', '').replaceAll('0', '').isEmpty) return '';
      return id;
    } catch (e) {
      // 测试环境 / 通道未注册时回退到随机 deviceId
      return '';
    }
  }

  /// 确保持久设备标识就绪（邀请页/激活邀请码前调用）
  ///
  /// OHOS：先请求 APP_TRACKING_CONSENT 授权（已授权不重复弹窗），
  /// 授权成功后拉取 OAID 并缓存到 Storage（'persistentDeviceId'）。
  /// Android/iOS：授权已由 Storage.init 在启动时完成，此处仅幂等回读缓存。
  /// 返回是否已获得可用的持久设备标识；不可用（拒绝授权/全 0）时返回 false，
  /// 由调用方静默回退随机 deviceId，不阻塞流程。
  Future<bool> ensurePersistentDeviceId() async {
    try {
      if (isOhos) {
        final granted =
            await _channel.invokeMethod<bool>('requestTrackingPermission') ??
                false;
        if (!granted) return false;
      }
      final id = await getPersistentDeviceId();
      if (id.isEmpty) return false;
      final settings = Storage.getSettings();
      if (settings['persistentDeviceId'] != id) {
        settings['persistentDeviceId'] = id;
        Storage.saveSettings(settings);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
