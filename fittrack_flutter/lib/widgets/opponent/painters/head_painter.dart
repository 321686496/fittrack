// lib/widgets/opponent/painters/head_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class HeadPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? faceImage; // null → 纯代码绘制

  const HeadPainter({required this.palette, required this.frame, required this.faceImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(120, 80);
    canvas.rotate(frame.headTilt * pi / 180);

    if (faceImage != null) {
      // 贴图模式：绘制 80×80 面部贴图（中心对齐）
      final src = Rect.fromLTWH(0, 0, faceImage!.width.toDouble(), faceImage!.height.toDouble());
      final dst = Rect.fromCenter(center: Offset.zero, width: 80, height: 80);
      canvas.drawImageRect(faceImage!, src, dst, Paint());
    } else {
      // 纯代码 fallback
      final skinPaint = Paint()..color = palette.skinTone;
      final outlinePaint = Paint()
        ..color = palette.primary.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // 头部
      final headRect = Rect.fromCenter(center: Offset.zero, width: 80, height: 80);
      canvas.drawOval(headRect, skinPaint);
      canvas.drawOval(headRect, outlinePaint);

      // 眼睛
      final eyePaint = Paint()..color = palette.primary;
      canvas.drawCircle(const Offset(-12, -5), 4, eyePaint);
      canvas.drawCircle(const Offset(12, -5), 4, eyePaint);

      // 嘴
      final mouthPaint = Paint()
        ..color = palette.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(Rect.fromCenter(center: const Offset(0, 12), width: 16, height: 12), 0, pi, false, mouthPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeadPainter old) {
    return old.frame != frame || old.faceImage != faceImage || old.palette != palette;
  }
}
