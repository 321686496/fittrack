import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/themes/app_themes.dart';

void main() {
  group('LiftTrackTheme.isTimedDarkNow', () {
    test('默认 18:00，18:00 时为深色', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 18, 18, 0)), isTrue);
    });

    test('默认 18:00，17:59 时为浅色', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 18, 17, 59)), isFalse);
    });

    test('窗口跨零点：次日 05:59 仍为深色', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 19, 5, 59)), isTrue);
    });

    test('窗口长度 12 小时：次日 06:00 回到浅色', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00', testNow: DateTime(2026, 8, 19, 6, 0)), isFalse);
    });

    test('深色窗口从 00:30 开始（不跨零点），11:59 时仍深色、12:00 仍深色、12:30 变浅色', () {
      expect(LiftTrackTheme.isTimedDarkNow('00:30', testNow: DateTime(2026, 8, 18, 11, 59)), isTrue);
      expect(LiftTrackTheme.isTimedDarkNow('00:30', testNow: DateTime(2026, 8, 18, 12, 0)), isTrue);
      expect(LiftTrackTheme.isTimedDarkNow('00:30', testNow: DateTime(2026, 8, 18, 12, 30)), isFalse);
    });

    test('非法格式回退到 18:00', () {
      expect(LiftTrackTheme.isTimedDarkNow('invalid', testNow: DateTime(2026, 8, 18, 18, 30)), isTrue);
      expect(LiftTrackTheme.isTimedDarkNow('invalid', testNow: DateTime(2026, 8, 18, 17, 30)), isFalse);
    });

    test('不传 testNow 时用当前时间，不抛异常', () {
      expect(LiftTrackTheme.isTimedDarkNow('18:00'), isA<bool>());
    });
  });
}