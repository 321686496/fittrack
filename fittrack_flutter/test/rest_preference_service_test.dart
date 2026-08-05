import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/rest_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('isPreferenceAvailable returns false with no records', () {
    expect(RestPreferenceService.instance.isPreferenceAvailable(), false);
  });

  test('isPreferenceAvailable returns false within 7 days', () {
    final now = DateTime.now();
    Storage.addRecord({
      'name': 'test',
      'date': now.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
    });
    expect(RestPreferenceService.instance.isPreferenceAvailable(), false);
  });

  test('computeRecommendedRestSeconds returns null with insufficient data', () {
    expect(RestPreferenceService.instance.computeRecommendedRestSeconds(), null);
  });

  test('computeRecommendedRestSeconds returns value with sufficient data', () {
    final now = DateTime.now();
    final oldDate = now.subtract(const Duration(days: 10));
    // Create a record 10 days ago with rest log
    Storage.addRecord({
      'name': 'test',
      'date': oldDate.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
      'restLog': [
        {'exercise': 'bench', 'scheduledRestSeconds': 90, 'actualRestSeconds': 95, 'restEndReason': 'manual'},
        {'exercise': 'squat', 'scheduledRestSeconds': 90, 'actualRestSeconds': 100, 'restEndReason': 'manual'},
        {'exercise': 'row', 'scheduledRestSeconds': 90, 'actualRestSeconds': 85, 'restEndReason': 'manual'},
      ],
    });
    // Create a recent record
    Storage.addRecord({
      'name': 'test2',
      'date': now.millisecondsSinceEpoch,
      'duration': 30,
      'totalWeight': 500,
      'totalSets': 3,
      'muscles': [],
      'restLog': [
        {'exercise': 'bench', 'scheduledRestSeconds': 90, 'actualRestSeconds': 90, 'restEndReason': 'manual'},
      ],
    });

    final result = RestPreferenceService.instance.computeRecommendedRestSeconds();
    expect(result, isNotNull);
    expect(result! >= 15, true);
    expect(result <= 600, true);
  });
}
