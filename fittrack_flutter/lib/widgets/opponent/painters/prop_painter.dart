// lib/widgets/opponent/painters/prop_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class PropPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? propImage;

  const PropPainter({required this.palette, required this.frame, required this.propImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);

    // 道具跟随右手位置 (150, 135) 旋转
    canvas.translate(150, 135);
    canvas.rotate(-frame.armAngle * pi / 180);

    if (propImage != null) {
      final src = Rect.fromLTWH(0, 0, propImage!.width.toDouble(), propImage!.height.toDouble());
      final dst = Rect.fromCenter(center: const Offset(20, 30), width: 50, height: 50);
      canvas.drawImageRect(propImage!, src, dst, Paint());
    } else {
      // fallback：绘制小哑铃
      final propPaint = Paint()..color = palette.accent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(20, 30), width: 8, height: 40), const Radius.circular(4)),
        propPaint,
      );
      canvas.drawCircle(const Offset(20, 8), 8, propPaint);
      canvas.drawCircle(const Offset(20, 52), 8, propPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PropPainter old) {
    return old.frame != frame || old.propImage != propImage || old.palette != palette;
  }
}
