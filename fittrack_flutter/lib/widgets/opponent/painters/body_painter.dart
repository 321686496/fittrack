// lib/widgets/opponent/painters/body_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

/// 绘制 Q 版身体轮廓（头身比 1:2，身体椭圆 + 四肢）
class BodyPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;

  const BodyPainter({required this.palette, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    // 按 240×240 基准坐标系绘制，按 size 缩放
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, frame.bodyOffset.dy);

    final skinPaint = Paint()..color = palette.skinTone;
    final outlinePaint = Paint()
      ..color = palette.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 身体椭圆
    final bodyRect = Rect.fromCenter(center: const Offset(120, 160), width: 80, height: 100);
    canvas.drawOval(bodyRect, skinPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // 四肢
    _drawArms(canvas, skinPaint, outlinePaint);
    _drawLegs(canvas, skinPaint, outlinePaint);

    canvas.restore();
  }

  void _drawArms(Canvas canvas, Paint fill, Paint outline) {
    final angleRad = frame.armAngle * pi / 180;
    // 左臂
    canvas.save();
    canvas.translate(90, 135);
    canvas.rotate(angleRad);
    final leftArm = Rect.fromCenter(center: Offset.zero, width: 14, height: 50);
    canvas.drawRRect(RRect.fromRectAndRadius(leftArm, const Radius.circular(7)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(leftArm, const Radius.circular(7)), outline);
    canvas.restore();

    // 右臂
    canvas.save();
    canvas.translate(150, 135);
    canvas.rotate(-angleRad);
    final rightArm = Rect.fromCenter(center: Offset.zero, width: 14, height: 50);
    canvas.drawRRect(RRect.fromRectAndRadius(rightArm, const Radius.circular(7)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rightArm, const Radius.circular(7)), outline);
    canvas.restore();
  }

  void _drawLegs(Canvas canvas, Paint fill, Paint outline) {
    // legBend 0-1 → 弯曲角度 0-30 度
    final bendAngle = frame.legBend * 30 * pi / 180;

    // 左腿
    canvas.save();
    canvas.translate(105, 210);
    canvas.rotate(bendAngle);
    final leftLeg = Rect.fromCenter(center: Offset.zero, width: 16, height: 50);
    canvas.drawRRect(RRect.fromRectAndRadius(leftLeg, const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(leftLeg, const Radius.circular(8)), outline);
    canvas.restore();

    // 右腿
    canvas.save();
    canvas.translate(135, 210);
    canvas.rotate(-bendAngle);
    final rightLeg = Rect.fromCenter(center: Offset.zero, width: 16, height: 50);
    canvas.drawRRect(RRect.fromRectAndRadius(rightLeg, const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(rightLeg, const Radius.circular(8)), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyPainter old) {
    return old.frame != frame || old.palette != palette;
  }
}
