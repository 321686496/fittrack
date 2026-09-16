import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/widgets/first_training_feedback_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('does not show before any training completed', () {
    // 默认 stats totalTrainings = 0，未完成首训，不应弹出
    expect(FirstTrainingFeedbackSheet.shouldShow(), false);
  });

  test('shows after the first training completes (totalTrainings >= 1)', () async {
    SharedPreferences.setMockInitialValues({
      'fittrack_fitplan_stats': '{"totalTrainings":1}',
      'fittrack_fitplan_settings': '{}',
    });
    await Storage.init();
    expect(FirstTrainingFeedbackSheet.shouldShow(), true);
  });

  test('does not show again once the flag is set', () async {
    final s = Storage.getSettings();
    s['firstFeedbackShown'] = true;
    Storage.saveSettings(s);
    expect(FirstTrainingFeedbackSheet.shouldShow(), false);
  });
}