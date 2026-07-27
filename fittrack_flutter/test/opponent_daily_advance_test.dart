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
    // 验证平均每次训练 weight 被 0.5x 减半（hardcore tier 单次 7000-15000，减半后 3500-7500）
    if (newOpp.weeklyTrainings > 0) {
      final avgWeight = newOpp.weeklyWeight / newOpp.weeklyTrainings;
      expect(avgWeight < 8000, true,
          reason: 'ninja avg weight/session should be halved (<8000), got $avgWeight');
      expect(avgWeight > 3000, true,
          reason: 'ninja avg weight/session should be > 3000, got $avgWeight');
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
    // 验证平均每次训练 weight 被 1.3x 放大（hardcore tier 单次 7000-15000，放大后 9100-19500）
    if (newOpp.weeklyTrainings > 0) {
      final avgWeight = newOpp.weeklyWeight / newOpp.weeklyTrainings;
      expect(avgWeight > 8500, true,
          reason: 'iron_warrior avg weight/session should be 1.3x (>8500), got $avgWeight');
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
