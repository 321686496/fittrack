import 'package:flutter/material.dart';
import '../widgets/share_card_frame.dart';
import 'achievement_service.dart';
import 'poster_generator.dart';

class ShareCardService {
  static final GlobalKey _boundaryKey = GlobalKey();

  static GlobalKey get boundaryKey => _boundaryKey;

  /// Renders the ShareCardFrame (wrapped in RepaintBoundary) to a PNG file.
  /// Returns the file path. Caller must have the ShareCardFrame mounted
  /// in the widget tree with [boundaryKey] assigned.
  static Future<String> generateShareCard(
    Map<String, dynamic> record,
    BuildContext context,
  ) async {
    final cardSize = const Size(1080, 1920);
    // Render offscreen via Overlay.
    // 修复：原实现将 1080x1920 蓝色卡片直接插入可见 Overlay，铺满屏幕呈现"透明蓝屏"，
    // 且 50ms 等待不足以让文本/图标完成 paint，导致截图无内容。
    // 改进：使用 Positioned 将卡片移出屏幕可视区域，用户不可见；
    // 等待多帧确保 layout + paint 完成后再截图。
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -cardSize.width, // 移出屏幕左侧，用户不可见
        top: -cardSize.height,
        width: cardSize.width,
        height: cardSize.height,
        child: Material(
          color: Colors.transparent,
          child: OverflowBox(
            minWidth: cardSize.width,
            maxWidth: cardSize.width,
            minHeight: cardSize.height,
            maxHeight: cardSize.height,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: ShareCardFrame(record: record, size: cardSize),
            ),
          ),
        ),
      ),
    );

    // OHOS 引擎 bug 修复：OHOS Flutter 引擎在帧绘制时会重入触发
    // MouseTracker.updateAllDevices，导致 !_debugDuringDeviceUpdate 断言失败。
    // 临时屏蔽该错误，确保帧绘制正常完成。
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorStr = details.exception.toString();
      if (errorStr.contains('_debugDuringDeviceUpdate') ||
          errorStr.contains('MouseTracker')) {
        return;
      }
      originalOnError?.call(details);
    };

    overlay.insert(entry);
    // 等待 OverlayEntry 完成挂载与首帧 build，否则 boundaryKey.currentContext
    // 为 null 会导致 PosterGenerator.capture 内 findRenderObject 抛异常。
    await WidgetsBinding.instance.endOfFrame;
    // paint 等待已统一收敛到 PosterGenerator.capture 内部，
    // 此处不再使用固定 30ms 等待（首帧 paint 未完成时调用 toByteData 会触发
    // '!debugNeedsPaint' 断言）。
    try {
      // 复用 PosterGenerator.capture 的统一安全路径（含 paint 等待循环、
      // toByteData、写文件、OHOS 临时目录兜底）。
      // 返回 PNG 文件绝对路径。
      final imagePath = await PosterGenerator.capture(
        _boundaryKey,
        pixelRatio: 2.0,
        fileNamePrefix: 'share_card',
      );
      // 分享成功：记录到成就系统（评估 share_first / share_3 / share_10）
      await AchievementService.instance.recordShare();
      return imagePath;
    } finally {
      // 确保 OverlayEntry 在 capture 抛异常时也能被移除，避免残留遮罩层。
      entry.remove();
      // 恢复原始错误处理
      FlutterError.onError = originalOnError;
    }
  }
}
