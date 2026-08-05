import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveInProgressTraining stores data and getInProgressTraining retrieves it', () async {
    await Storage.init();
    final data = {
      'version': 1,
      'planId': 'test_plan',
      'currentExIdx': 2,
      'currentSetIdx': 1,
    };
    await Storage.saveInProgressTraining(data);

    final retrieved = Storage.getInProgressTraining();
    expect(retrieved, isNotNull);
    expect(retrieved!['planId'], 'test_plan');
    expect(retrieved['currentExIdx'], 2);
    expect(retrieved['lastPersistedAt'], isNotNull);
  });

  test('getInProgressTraining returns null when no data', () async {
    await Storage.init();
    final result = Storage.getInProgressTraining();
    expect(result, isNull);
  });

  test('clearInProgressTraining removes data', () async {
    await Storage.init();
    await Storage.saveInProgressTraining({'planId': 'test'});
    await Storage.clearInProgressTraining();
    expect(Storage.getInProgressTraining(), isNull);
  });

  test('settings defaults include autoEndAfterRest and restOvertimeLimitMultiplier', () async {
    await Storage.init();
    final settings = Storage.getSettings();
    expect(settings['autoEndAfterRest'], false);
    expect(settings['restOvertimeLimitMultiplier'], 3.0);
  });
}
