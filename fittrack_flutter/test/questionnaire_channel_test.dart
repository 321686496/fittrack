import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('channelSource defaults to empty', () {
    expect(Storage.getSettings()['channelSource'], '');
  });

  test('channelSource is persisted when saved', () async {
    final s = Storage.getSettings();
    s['channelSource'] = '小红书';
    await Storage.saveSettings(s);
    // Re-read from Storage
    expect(Storage.getSettings()['channelSource'], '小红书');
  });
}
