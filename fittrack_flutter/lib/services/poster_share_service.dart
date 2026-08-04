import 'package:flutter/services.dart';

/// 海报保存/分享服务（OHOS 平台专用）
///
/// OHOS 平台没有 share_plus 和 image_gallery_saver 的原生实现，
/// 通过 MethodChannel 调用 OHOS 原生代码实现：
/// - 保存：photoAccessHelper.createAsset → 复制文件到系统相册
/// - 分享：系统 Want 拉起分享面板
/// - 权限：检查/申请 WRITE_IMAGEVIDEO 权限
class PosterShareService {
  PosterShareService._();

  static const _channel = MethodChannel('com.lt.lifttrack/poster');

  /// 保存图片到系统相册
  ///
  /// [imagePath] PNG 文件绝对路径
  /// 返回相册中的资产 URI
  ///
  /// 注意：调用方需先通过 [checkWritePermission] / [requestWritePermission]
  /// 确保已获得存储权限，否则原生侧会返回 PERMISSION_DENIED 错误。
  static Future<String> saveToGallery(String imagePath) async {
    final result = await _channel.invokeMethod('saveToGallery', imagePath);
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: '保存返回 null',
      );
    }
    return result.toString();
  }

  /// 拉起系统分享面板
  ///
  /// [imagePath] PNG 文件绝对路径
  static Future<void> share(String imagePath) async {
    await _channel.invokeMethod('share', imagePath);
  }

  /// 检查是否已授予写入图片/视频权限（OHOS 专用）
  ///
  /// 返回 true 表示已授权，可直接调用 [saveToGallery]。
  static Future<bool> checkWritePermission() async {
    final result = await _channel.invokeMethod<bool>('checkWritePermission');
    return result ?? false;
  }

  /// 请求写入图片/视频权限（OHOS 专用）
  ///
  /// 首次调用会弹出系统授权弹窗；用户拒绝后再次调用会直接返回 false。
  /// 返回 true 表示授权成功，可继续保存；返回 false 表示用户拒绝。
  static Future<bool> requestWritePermission() async {
    final result = await _channel.invokeMethod<bool>('requestWritePermission');
    return result ?? false;
  }
}
