import 'package:flutter/services.dart';

/// 海报保存/分享服务（OHOS 平台专用）
///
/// OHOS 平台没有 share_plus 和 image_gallery_saver 的原生实现，
/// 通过 MethodChannel 调用 OHOS 原生代码实现：
/// - 保存：photoAccessHelper.createAsset → 复制文件到系统相册
/// - 分享：系统 Want 拉起分享面板
class PosterShareService {
  PosterShareService._();

  static const _channel = MethodChannel('com.fp.fitplan/poster');

  /// 保存图片到系统相册
  ///
  /// [imagePath] PNG 文件绝对路径
  /// 返回相册中的资产 URI
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
}
