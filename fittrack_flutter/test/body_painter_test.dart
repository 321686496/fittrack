// test/body_painter_test.dart
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/body_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  group('BodyPainter', () {
    test('can be constructed with valid params', () {
      expect(
        () => BodyPainter(
          palette: OpponentSkinConfig.kAllSkins.first.palette,
          frame: const MotionFrame(t: 0),
        ),
        returnsNormally,
      );
    });

    test('shouldRepaint returns true when frame changes', () {
      final p1 = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 0),
      );
      final p2 = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 10),
      );
      expect(p1.shouldRepaint(p2), true);
    });

    test('shouldRepaint returns false when same frame', () {
      final palette = OpponentSkinConfig.kAllSkins.first.palette;
      final frame = const MotionFrame(t: 0);
      final p1 = BodyPainter(palette: palette, frame: frame);
      final p2 = BodyPainter(palette: palette, frame: frame);
      expect(p1.shouldRepaint(p2), false);
    });

    test('paint does not throw on 240x240 canvas', () {
      final painter = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 30, legBend: 0.5),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('paint scales to 48x48 without throwing', () {
      final painter = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(48, 48)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
