import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('returns notAvailable when ads disabled', () async {
    // AdService.adsEnabled 为 false（开发者常量），showRewardedVideo 直接返回 notAvailable
    final result = await AdService.instance.showRewardedVideo();
    expect(result, AdResult.notAvailable);
  });

  test('Pro users never see ads', () async {
    await Storage.setPremium(true, source: 'test');
    expect(AdService.instance.shouldShowRewarded(), false);
  });
}
