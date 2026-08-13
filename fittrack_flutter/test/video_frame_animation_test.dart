import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/widgets/opponent/video_frame_animation.dart';

void main() {
  group('opponentAssetName', () {
    test('maps skin ids to asset folder names', () {
      expect(opponentAssetName('skin_beginner'), 'beginner');
      expect(opponentAssetName('skin_iron_warrior'), 'iron');
      expect(opponentAssetName('skin_cyber_ninja'), 'ninja');
      expect(opponentAssetName('skin_ambassador'), 'ambassador');
    });

    test('falls back to beginner for unknown skin', () {
      expect(opponentAssetName('skin_unknown'), 'beginner');
    });
  });

  group('frameLoopDuration', () {
    test('plays one full loop at 12fps', () {
      // 24 帧待机 = 2s；97 帧训练 = 8.08s
      expect(frameLoopDuration('skin_beginner', 'idle').inMilliseconds,
          closeTo(2000, 1));
      expect(frameLoopDuration('skin_beginner', 'train').inMilliseconds,
          closeTo(8083, 1));
      expect(frameLoopDuration('skin_iron_warrior', 'train').inMilliseconds,
          closeTo(3083, 1));
      expect(frameLoopDuration('skin_cyber_ninja', 'train').inMilliseconds,
          closeTo(9083, 1));
    });

    test('training loops are long enough for readable motion', () {
      // 旧实现把整套动作塞进 1.2~1.8s，导致动作过快；新实现应明显更慢
      for (final id in [
        'skin_beginner',
        'skin_iron_warrior',
        'skin_cyber_ninja',
        'skin_ambassador',
      ]) {
        expect(
          frameLoopDuration(id, 'train'),
          greaterThan(const Duration(seconds: 2)),
          reason: '$id 训练动画不应快于 2s 一圈',
        );
      }
    });
  });

  group('opponentFrameIndex', () {
    test('returns first frame at progress 0 and wraps at progress 1', () {
      expect(opponentFrameIndex('skin_beginner', false, 0.0), 0);
      expect(opponentFrameIndex('skin_beginner', false, 1.0), 0);
    });

    test('maps progress proportionally to frame count', () {
      // 24 帧待机：进度 0.5 -> 第 12 帧
      expect(opponentFrameIndex('skin_beginner', false, 0.5), 12);
      // 109 帧训练：进度 0.5 -> floor(54.5) = 54
      expect(opponentFrameIndex('skin_cyber_ninja', true, 0.5), 54);
    });

    test('never returns an out-of-range index', () {
      for (double p = 0.0; p <= 1.0; p += 0.01) {
        final idx = opponentFrameIndex('skin_beginner', false, p);
        expect(idx, inInclusiveRange(0, 23));
      }
    });
  });

  testWidgets('frame change reuses the same Image element (no key-swap flicker)',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    Widget build(double progress) => MaterialApp(
          home: Scaffold(
            body: VideoFrameAnimation(
              skinId: 'skin_beginner',
              isTraining: false,
              progress: progress,
            ),
          ),
        );

    await tester.pumpWidget(build(0.0));
    await tester.pump();
    final firstElement = tester.element(find.byType(Image));

    // 推进到下一帧
    await tester.pumpWidget(build(0.05));
    await tester.pump();
    final secondElement = tester.element(find.byType(Image));

    expect(
      secondElement,
      same(firstElement),
      reason: '帧切换不应重建 Image 组件（旧实现用 ValueKey 换 key 导致闪烁）',
    );
  });
}
