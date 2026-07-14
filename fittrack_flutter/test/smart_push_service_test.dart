import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/smart_push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('does not push when pushCountIn7Days >= 2', () async {
    final s = Storage.getSettings();
    s['pushCountIn7Days'] = 2;
    await Storage.saveSettings(s);
    final should = SmartPushService.instance.shouldPushNow();
    expect(should, false);
  });

  test('does not push when user opted out', () async {
    final s = Storage.getSettings();
    s['smartPushEnabled'] = false;
    await Storage.saveSettings(s);
    final should = SmartPushService.instance.shouldPushNow();
    expect(should, false);
  });

  test('does not push on same day as last push', () async {
    final s = Storage.getSettings();
    s['lastPushDate'] = Storage.getTodayStr();
    s['pushCountIn7Days'] = 0;
    await Storage.saveSettings(s);
    final should = SmartPushService.instance.shouldPushNow();
    expect(should, false);
  });

  test('resets pushCountIn7Days when last push was 7+ days ago', () async {
    final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
    final lastPushDate =
        '${eightDaysAgo.year}-${eightDaysAgo.month.toString().padLeft(2, '0')}-${eightDaysAgo.day.toString().padLeft(2, '0')}';
    final s = Storage.getSettings();
    s['smartPushEnabled'] = true;
    s['lastPushDate'] = lastPushDate;
    s['pushCountIn7Days'] = 2;
    await Storage.saveSettings(s);
    SmartPushService.instance.shouldPushNow();
    expect(Storage.getSettings()['pushCountIn7Days'], 0);
  });
}
