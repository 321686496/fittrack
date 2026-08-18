import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/widgets/rating_prompt_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('does not show when fewer than 2 trainings', () {
    // Default stats have totalTrainings = 0, which is < 2
    expect(RatingPromptSheet.shouldShow(), false);
  });

  test('does not show when neverAsk flag is set', () async {
    final s = Storage.getSettings();
    s['ratingPromptNeverAsk'] = true;
    Storage.saveSettings(s);
    expect(RatingPromptSheet.shouldShow(), false);
  });

  test('does not show within 30 days of last shown', () async {
    final s = Storage.getSettings();
    s['ratingPromptLastShown'] =
        DateTime.now().millisecondsSinceEpoch; // today
    Storage.saveSettings(s);
    expect(RatingPromptSheet.shouldShow(), false);
  });

  test('shows when 2+ trainings and no restrictions', () async {
    // Note: Storage prefixes keys with 'fittrack_' and JSON-encodes values
    // (storage.dart lines 25, 42, 177). The on-disk key for stats is
    // 'fittrack_fitplan_stats', not 'fitplan_stats'. Settings must also be
    // reset to prevent neverAsk/lastShown leakage from prior tests, because
    // Storage._store is static and not cleared between tests.
    SharedPreferences.setMockInitialValues({
      'fittrack_fitplan_stats': '{"totalTrainings":2}',
      'fittrack_fitplan_settings': '{}',
    });
    await Storage.init();
    expect(RatingPromptSheet.shouldShow(), true);
  });

  group('storeUriFor', () {
    test('Android uses market:// with the app package', () {
      final uri = RatingPromptSheet.storeUriFor(ohos: false, ios: false);
      expect(uri, 'market://details?id=com.lt.lifttrack');
    });

    test('OHOS uses store:// AppGallery detail link', () {
      final uri = RatingPromptSheet.storeUriFor(ohos: true, ios: false);
      expect(
        uri,
        'store://appgallery.huawei.com/app/detail?id=com.fp.fitplan',
      );
    });

    test('iOS returns null until App Store id is configured', () {
      // Apple ID 尚未上架填写，不应发起无效跳转
      expect(RatingPromptSheet.storeUriFor(ohos: false, ios: true), isNull);
    });
  });
}
