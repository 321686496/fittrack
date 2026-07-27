import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize flutter test binding for platform channels (SoundService/AudioPlayer)
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize sqflite ffi for desktop/test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await AchievementService.instance.resetForTest();
    await AchievementService.instance.init();
  });

  test('streak_7 unlocks after 7 consecutive training days', () async {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      await Storage.addRecord({
        'name': 'test',
        'date': date.millisecondsSinceEpoch,
        'duration': 1800,
        'totalWeight': 1000,
        'totalSets': 5,
        'muscles': [],
      });
    }
    final unlocked =
        await AchievementService.instance.checkAndUnlock(Storage.getRecords().first);
    expect(unlocked, contains('streak_7'));
  });

  test('weight_1t unlocks after total weight >= 1000kg', () async {
    await Storage.addRecord({
      'name': 'test',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': 1800,
      'totalWeight': 1500,
      'totalSets': 5,
      'muscles': ['胸'],
    });
    final unlocked =
        await AchievementService.instance.checkAndUnlock(
            Storage.getRecords().first);
    expect(unlocked, contains('weight_1t'));
  });
}
