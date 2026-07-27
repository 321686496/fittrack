// test/auxiliary_painters_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;
import 'package:fittrack_flutter/widgets/opponent/painters/head_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/outfit_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/prop_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  final palette = OpponentSkinConfig.kAllSkins.first.palette;
  const frame = MotionFrame(t: 0);

  group('HeadPainter', () {
    test('constructs with null image (fallback to code)', () {
      expect(() => HeadPainter(palette: palette, frame: frame, faceImage: null), returnsNormally);
    });

    test('paint does not throw on 240x240', () {
      final p = HeadPainter(palette: palette, frame: frame, faceImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('shouldRepaint true when frame changes', () {
      final p1 = HeadPainter(palette: palette, frame: const MotionFrame(t: 0, headTilt: 0), faceImage: null);
      final p2 = HeadPainter(palette: palette, frame: const MotionFrame(t: 0, headTilt: 10), faceImage: null);
      expect(p1.shouldRepaint(p2), true);
    });
  });

  group('OutfitPainter', () {
    test('constructs with null image', () {
      expect(() => OutfitPainter(palette: palette, frame: frame, outfitImage: null), returnsNormally);
    });

    test('paint does not throw', () {
      final p = OutfitPainter(palette: palette, frame: frame, outfitImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });

  group('PropPainter', () {
    test('constructs with null image', () {
      expect(() => PropPainter(palette: palette, frame: frame, propImage: null), returnsNormally);
    });

    test('paint does not throw', () {
      final p = PropPainter(palette: palette, frame: const MotionFrame(t: 0, armAngle: 30), propImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
