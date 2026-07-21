import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

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
    double pixelRatio = 3.0,
    String fileNamePrefix = 'fittrack_poster',
  }) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('PosterGenerator: toByteData returned null');
    }
    final pngBytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/${fileNamePrefix}_$timestamp.png');
    await file.writeAsBytes(pngBytes);
    return file.path;
  }
}
