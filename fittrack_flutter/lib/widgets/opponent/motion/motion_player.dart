// lib/widgets/opponent/motion/motion_player.dart
import 'dart:ui';
import 'package:flutter/animation.dart';
import '../opponent_skin_config.dart';

/// 按 progress (0-1) 插值出当前帧参数
MotionFrame interpolateMotion(MotionSpec spec, double progress) {
  final frames = spec.frames;
  if (frames.length == 1) return frames.first;
  if (frames.isEmpty) return const MotionFrame(t: 0);

  // 将 progress 映射到帧索引空间
  final scaled = (progress * frames.length) % frames.length;
  final idx = scaled.floor();
  final next = (idx + 1) % frames.length;
  final localT = scaled - idx;
  final eased = spec.curve.transform(localT);

  final a = frames[idx];
  final b = frames[next];
  return MotionFrame(
    t: progress,
    bodyOffset: Offset.lerp(a.bodyOffset, b.bodyOffset, eased) ?? a.bodyOffset,
    armAngle: lerpDouble(a.armAngle, b.armAngle, eased) ?? a.armAngle,
    legBend: lerpDouble(a.legBend, b.legBend, eased) ?? a.legBend,
    headTilt: lerpDouble(a.headTilt, b.headTilt, eased) ?? a.headTilt,
  );
}
