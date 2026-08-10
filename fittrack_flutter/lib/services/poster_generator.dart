import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/platform_utils.dart';

/// 海报截图通用服务
///
/// 通过 [RepaintBoundary] 的 [GlobalKey] 捕获 widget 为 PNG 图片，
/// 返回 PNG 文件的绝对路径。
///
/// 复用自 `lib/widgets/note_poster.dart` 的成熟截图模式：
/// `toImage(pixelRatio: 3.0)` + `toByteData(format: ui.ImageByteFormat.png)`
/// + 写入 `getTemporaryDirectory()`。
class PosterGenerator {
  PosterGenerator._();

  /// 通过 [RepaintBoundary] key 截取 widget 为 PNG。
  ///
  /// [boundaryKey] 必须已经挂载到 widget 树中且对应 [RenderRepaintBoundary]。
  /// [pixelRatio] 默认 3.0 以保证海报清晰度。
  /// [fileNamePrefix] 用于生成唯一文件名，默认 `fittrack_poster`。
  ///
  /// 返回 PNG 文件绝对路径。失败时抛出原始异常。
  static Future<String> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
    String fileNamePrefix = 'fittrack_poster',
  }) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    // 等待 paint 完成：
    // - showDialog 触发的新帧会让 debugNeedsPaint 重新变为 true
    // - QrImageView 等异步组件需要额外帧才能完成渲染
    // 此处通过轮询 debugNeedsPaint 状态，最多等待 30 次 × 30ms（≈900ms）。
    // 若仍为 true，再额外等待 3 帧（给 QR 码等异步组件更多时间），然后强制截图。
    for (int i = 0; i < 30; i++) {
      if (!boundary.debugNeedsPaint) break;
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (boundary.debugNeedsPaint) {
      // 额外等 3 帧，给异步组件（QR 码等）最后的机会
      for (int i = 0; i < 3; i++) {
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 50));
      }
      // 强制截图：toImage 内部会自行处理 paint 状态
      debugPrint('PosterGenerator: debugNeedsPaint 仍为 true，强制截图');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('PosterGenerator: toByteData returned null');
    }
    final pngBytes = byteData.buffer.asUint8List();
    // OHOS: getTemporaryDirectory() throws MissingPluginException.
    // Fall back to system temp dir (same pattern as share_card_service.dart).
    Directory dir;
    if (isOhos) {
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = Directory(Directory.systemTemp.path);
      }
    } else {
      dir = await getTemporaryDirectory();
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.png');
    await file.writeAsBytes(pngBytes);
    return file.path;
  }
}
