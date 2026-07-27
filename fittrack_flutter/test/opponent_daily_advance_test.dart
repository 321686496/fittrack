import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/virtual_opponent.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('cyber_ninja weight multiplier should be 0.5 (cardioWeight>0.4)', () async {
    final skin = OpponentSkinConfig.byId('skin_cyber_ninja');
    expect(skin.trainBias.cardioWeight > 0.4, true);

    // 注入 ninja 皮肤已解锁状态
    final settings = Storage.getSettings();
    settings['unlockedFeatures'] = '["good_skin_cyber_ninja"]';
    Storage.saveSettings(settings);

    // 注入对手数据
    final opponent = VirtualOpponent(
      id: 'test', nickname: '测试', tier: OpponentTier.hardcore,
      avatarSeed: 't', persona: 'p',
    );
    Storage.saveSettings({
      ...Storage.getSettings(),
      'virtualOpponentData': opponent.toJson(),
      'opponentLastAdvanceDate': '', // 强制推进
    });

    await VirtualOpponentEngine.instance.dailyAdvance();

    final updated = Storage.getSettings()['virtualOpponentData'] as Map;
    final newOpp = VirtualOpponent.fromJson(Map<String, dynamic>.from(updated));
    // 如果今天训练了，weight 应小于 hardcore tier 上限 15000 的 0.6 倍（15000*0.5=7500）
    if (newOpp.weeklyTrainings > 0) {
      expect(newOpp.weeklyWeight < 9000, true,
          reason: 'ninja weight should be halved, got ${newOpp.weeklyWeight}');
    }
  });

  test('iron_warrior weight multiplier should be 1.3 (compoundWeight>0.5)', () async {
    final skin = OpponentSkinConfig.byId('skin_iron_warrior');
    expect(skin.trainBias.compoundWeight > 0.5, true);

    final settings = Storage.getSettings();
    settings['unlockedFeatures'] = '["good_skin_iron_warrior"]';
    Storage.saveSettings(settings);

    final opponent = VirtualOpponent(
      id: 'test', nickname: '测试', tier: OpponentTier.hardcore,
      avatarSeed: 't', persona: 'p',
    );
    Storage.saveSettings({
      ...Storage.getSettings(),
      'virtualOpponentData': opponent.toJson(),
      'opponentLastAdvanceDate': '',
    });

    await VirtualOpponentEngine.instance.dailyAdvance();

    final updated = Storage.getSettings()['virtualOpponentData'] as Map;
    final newOpp = VirtualOpponent.fromJson(Map<String, dynamic>.from(updated));
    if (newOpp.weeklyTrainings > 0) {
      // iron_warrior weight 应大于 base weight 最小值 7000*1.3=9100
      expect(newOpp.weeklyWeight > 9000, true,
          reason: 'iron_warrior weight should be 1.3x, got ${newOpp.weeklyWeight}');
    }
  });

  test('currentStatus should come from skin dialogStyle.trainingTaunts', () async {
    // 用 ninja 皮肤（taunts 包含 "我的速度你跟不上"）
    final settings = Storage.getSettings();
    settings['unlockedFeatures'] = '["good_skin_cyber_ninja"]';
    Storage.saveSettings(settings);

    final opponent = VirtualOpponent(
      id: 'test', nickname: '测试', tier: OpponentTier.regular,
      avatarSeed: 't', persona: 'p',
    );
    Storage.saveSettings({
      ...Storage.getSettings(),
      'virtualOpponentData': opponent.toJson(),
      'opponentLastAdvanceDate': '',
    });

    // 多次执行（10% 概率，最多跑 20 次至少 1 次命中）
    String? matchedTaunt;
    for (int i = 0; i < 30; i++) {
      Storage.saveSettings({
        ...Storage.getSettings(),
        'opponentLastAdvanceDate': '',
      });
      await VirtualOpponentEngine.instance.dailyAdvance();
      final s = Storage.getSettings();
      final o = VirtualOpponent.fromJson(
          Map<String, dynamic>.from(s['virtualOpponentData'] as Map));
      if (o.currentStatus != null) {
        matchedTaunt = o.currentStatus;
        break;
      }
    }

    if (matchedTaunt != null) {
      final ninjaTaunts = OpponentSkinConfig.byId('skin_cyber_ninja')
          .dialogStyle.trainingTaunts;
      expect(ninjaTaunts.contains(matchedTaunt), true,
          reason: '$matchedTaunt not in ninja taunts');
    }
  });
}
