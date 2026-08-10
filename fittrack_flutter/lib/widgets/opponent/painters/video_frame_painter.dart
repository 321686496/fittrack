// lib/widgets/opponent/painters/video_frame_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 绘制视频帧序列中的当前帧（替代代码绘制的身体+服饰+道具）
class VideoFramePainter extends CustomPainter {
  final List<ui.Image> frames;
  final int currentFrameIndex;

  const VideoFramePainter({
    required this.frames,
    required this.currentFrameIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.isEmpty) return;
    final idx = currentFrameIndex % frames.length;
    final frame = frames[idx];

    // 将帧绘制到整个 canvas，保持宽高比居中
    final src = Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble());
    final scale = size.width / frame.width;
    final scaledH = frame.height * scale;
    final offsetY = (size.height - scaledH) / 2;
    final dst = Rect.fromLTWH(0, offsetY, size.width, scaledH);

    canvas.drawImageRect(frame, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant VideoFramePainter old) {
    return old.currentFrameIndex != currentFrameIndex || old.frames != frames;
  }
}
