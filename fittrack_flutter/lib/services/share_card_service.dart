import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/share_card_frame.dart';

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
    // Render offscreen via Overlay. An OverflowBox decouples the card's
    // fixed 1080x1920 size from the Overlay's screen-sized constraints so
    // the captured image is always the full card regardless of device size.
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Material(
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
    );
    overlay.insert(entry);
    // Wait for next frame so the offscreen widget is laid out
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 50));

    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    late Uint8List bytes;
    try {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      bytes = byteData!.buffer.asUint8List();
    } finally {
      // 确保 OverlayEntry 在 toImage/toByteData 抛异常时也能被移除，
      // 避免残留遮罩层。
      entry.remove();
    }

    // OHOS: getTemporaryDirectory() throws MissingPluginException.
    // Fall back to system temp dir.
    Directory tempDir;
    if (Platform.isOhos) {
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = Directory(Directory.systemTemp.path);
      }
    } else {
      tempDir = await getTemporaryDirectory();
    }
    final path =
        '${tempDir.path}/share_card_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  static Future<void> shareImage(String imagePath) async {
    // OHOS: share_plus has no OHOS platform implementation.
    // Skip the Share call; caller should show a SnackBar fallback.
    if (Platform.isOhos) {
      return;
    }
    await Share.shareXFiles([XFile(imagePath)], text: '我用 FitTrack 完成了今日训练');
  }
}
