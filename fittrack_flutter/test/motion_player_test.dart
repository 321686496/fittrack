// test/motion_player_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';
import 'package:fittrack_flutter/widgets/opponent/motion/motion_player.dart';

void main() {
  group('MotionSpec.interpolate', () {
    final spec = MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: 0, bodyOffset: Offset(0, 0)),
        MotionFrame(t: 0.5, armAngle: 90, bodyOffset: Offset(0, -5)),
        MotionFrame(t: 1.0, armAngle: 0, bodyOffset: Offset(0, 0)),
      ],
      duration: Duration(milliseconds: 1000),
    );

    test('progress=0 returns first frame values', () {
      final f = spec.interpolate(0.0);
      expect(f.armAngle, closeTo(0, 0.01));
      expect(f.bodyOffset.dy, closeTo(0, 0.01));
    });

    test('progress=0.5 returns middle frame values', () {
      final f = spec.interpolate(0.5);
      // progress=0.5 落在 frames[1]→frames[2] 中点
      expect(f.armAngle, closeTo(45, 1.0));
      expect(f.bodyOffset.dy, closeTo(-2.5, 0.5));
    });

    test('progress=0.25 interpolates between frame 0 and 1', () {
      final f = spec.interpolate(0.25);
      // 0→1 帧间中点，easeInOut 缓动后约 (0+90)/2=45（具体值取决于曲线）
      expect(f.armAngle > 0, true);
      expect(f.armAngle < 90, true);
    });

    test('progress near 1 wraps to frame 2→0', () {
      final f = spec.interpolate(0.99);
      // 接近循环结束，应接近第 0 帧（最后一帧与第一帧相同）
      expect(f.armAngle, closeTo(0, 5));
    });

    test('single frame spec returns that frame', () {
      final single = MotionSpec(
        frames: [MotionFrame(t: 0, armAngle: 42)],
        duration: Duration(milliseconds: 500),
      );
      expect(single.interpolate(0.5).armAngle, 42);
    });

    test('interpolate never throws for any progress in [0,1]', () {
      for (double p = 0.0; p <= 1.0; p += 0.01) {
        expect(() => spec.interpolate(p), returnsNormally);
      }
    });
  });
}
