import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/virtual_opponent.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Storage._store is static and not cleared between tests (see rating_prompt_test.dart).
    // 重置 settings 至默认值以保证测试隔离
    Storage.saveSettings(<String, dynamic>{});
    await Storage.init();
  });

  group('VirtualOpponent.appliedSkinId', () {
    test('无解锁时返回空串', () {
      final opp = VirtualOpponent(
        id: 'test1',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_1',
        persona: '测试人设',
      );
      expect(opp.appliedSkinId, '');
    });

    test('unlockedOpponentSkin=true 时返回 skin_ambassador', () {
      final settings = Storage.getSettings();
      settings['unlockedOpponentSkin'] = true;
      Storage.saveSettings(settings);

      final opp = VirtualOpponent(
        id: 'test2',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_2',
        persona: '测试',
      );
      expect(opp.appliedSkinId, 'skin_ambassador');
    });

    test('已购精品皮肤应返回精品皮肤 id', () {
      final settings = Storage.getSettings();
      settings['unlockedFeatures'] = '["good_skin_cyber_ninja","good_skin_iron_warrior"]';
      Storage.saveSettings(settings);

      final opp = VirtualOpponent(
        id: 'test3',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_3',
        persona: '测试',
      );
      // 优先返回最贵的（精品款优先）
      expect(opp.appliedSkinId, 'skin_cyber_ninja');
    });
  });

  group('VirtualOpponentEngine.dailyAdvance', () {
    test('同一天重复调用不应重复推进', () {
      final opp = VirtualOpponent(
        id: 'test4',
        nickname: '测试',
        tier: OpponentTier.casual,
        avatarSeed: 'avatar_4',
        persona: '测试',
        weeklyTrainings: 1,
      );
      // 持久化对手数据
      final settings = Storage.getSettings();
      settings['virtualOpponentData'] = opp.toJson();
      Storage.saveSettings(settings);

      VirtualOpponentEngine.instance.dailyAdvance();
      final trainingsAfter1 = (Storage.getSettings()['virtualOpponentData']
          as Map<String, dynamic>)['weeklyTrainings'] as int;

      VirtualOpponentEngine.instance.dailyAdvance();
      final trainingsAfter2 = (Storage.getSettings()['virtualOpponentData']
          as Map<String, dynamic>)['weeklyTrainings'] as int;

      expect(trainingsAfter2, trainingsAfter1);
    });
  });
}
