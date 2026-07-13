import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('anonStatsOptIn defaults to false', () {
    final s = Storage.getSettings();
    expect(s['anonStatsOptIn'], false);
  });

  test('deviceId is generated on first init and stable across reads', () {
    final id1 = Storage.getSettings()['deviceId'];
    expect(id1, isNotEmpty);
    final id2 = Storage.getSettings()['deviceId'];
    expect(id2, equals(id1));
  });

  test('isPremiumNotifier starts false and updates via setPremium', () async {
    expect(Storage.isPremiumNotifier.value, false);
    await Storage.setPremium(true, source: 'test');
    expect(Storage.isPremiumNotifier.value, true);
    expect(Storage.getSettings()['isPremium'], true);
    expect(Storage.getSettings()['premiumSource'], 'test');
  });
}
