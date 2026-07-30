import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('activityColorMode 默认为 capacity', () {
    final s = Storage.getSettings();
    expect(s['activityColorMode'], 'capacity');
  });

  test('saveSettings 后 activityColorMode 可切换为 duration', () {
    final s = Storage.getSettings();
    s['activityColorMode'] = 'duration';
    Storage.saveSettings(s);
    final s2 = Storage.getSettings();
    expect(s2['activityColorMode'], 'duration');
  });
}
