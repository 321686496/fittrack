import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('returns notAvailable in no-op implementation', () async {
    final result = await AdService.instance.showRewardedVideo();
    expect(result, AdResult.notAvailable);
  });

  test('Pro users never see ads', () async {
    await Storage.setPremium(true, source: 'test');
    expect(AdService.instance.shouldShowRewarded(), false);
  });
}
