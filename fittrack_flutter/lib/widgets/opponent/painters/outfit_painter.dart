// lib/widgets/opponent/painters/outfit_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class OutfitPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? outfitImage;

  const OutfitPainter({required this.palette, required this.frame, required this.outfitImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, frame.bodyOffset.dy);

    if (outfitImage != null) {
      final src = Rect.fromLTWH(0, 0, outfitImage!.width.toDouble(), outfitImage!.height.toDouble());
      final dst = Rect.fromCenter(center: const Offset(120, 160), width: 90, height: 110);
      canvas.drawImageRect(outfitImage!, src, dst, Paint());
    } else {
      // fallback：在身体上覆盖一块服饰色块
      final outfitPaint = Paint()..color = palette.primary;
      final outfitRect = Rect.fromCenter(center: const Offset(120, 150), width: 70, height: 80);
      canvas.drawRRect(RRect.fromRectAndRadius(outfitRect, const Radius.circular(12)), outfitPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OutfitPainter old) {
    return old.frame != frame || old.outfitImage != outfitImage || old.palette != palette;
  }
}
