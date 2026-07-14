import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/iap_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('markPremiumLocally flips isPremiumNotifier and persists', () async {
    expect(IapService.instance.isPremium.value, false);
    await IapService.instance.markPremiumLocally('test');
    expect(IapService.instance.isPremium.value, true);
    expect(Storage.getSettings()['isPremium'], true);
    expect(Storage.getSettings()['premiumSource'], 'test');
  });
}
