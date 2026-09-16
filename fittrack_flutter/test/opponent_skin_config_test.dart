// test/opponent_skin_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  group('OpponentSkinConfig', () {
    test('byId returns correct config for all 6 skins', () {
      expect(OpponentSkinConfig.byId('default_male').name, '默认男性角色');
      expect(OpponentSkinConfig.byId('default_female').name, '默认女性角色');
      expect(OpponentSkinConfig.byId('skin_beginner').name, '晨光起步者');
      expect(OpponentSkinConfig.byId('skin_iron_warrior').name, '熔铁匠人');
      expect(OpponentSkinConfig.byId('skin_cyber_ninja').name, '风行游侠');
      expect(OpponentSkinConfig.byId('skin_ambassador').name, '传承导师');
    });

    test('byId falls back to default_male for unknown id', () {
      expect(OpponentSkinConfig.byId('unknown').id, 'default_male');
    });

    test('kAllSkins contains exactly 6 skins', () {
      expect(OpponentSkinConfig.kAllSkins.length, 6);
    });

    test('each skin has non-empty signatureMove', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.signatureMove.isNotEmpty, true, reason: '${s.id} signatureMove empty');
      }
    });

    test('each skin has non-empty dialogStyle lists', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.dialogStyle.greetings.isNotEmpty, true);
        expect(s.dialogStyle.trainingTaunts.isNotEmpty, true);
        expect(s.dialogStyle.winQuotes.isNotEmpty, true);
        expect(s.dialogStyle.loseQuotes.isNotEmpty, true);
      }
    });

    test('each skin has faceAsset; non-default skins have full assets', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.faceAsset?.startsWith('assets/opponent/'), true, reason: '${s.id} face');
        if (s.id == 'default_male' || s.id == 'default_female') {
          // 默认角色仅含面部资产，服饰/道具由系统渲染
          expect(s.outfitAsset, isNull, reason: '${s.id} outfit');
          expect(s.propAsset, isNull, reason: '${s.id} prop');
        } else {
          expect(s.outfitAsset?.startsWith('assets/opponent/'), true, reason: '${s.id} outfit');
          expect(s.propAsset?.startsWith('assets/opponent/'), true, reason: '${s.id} prop');
        }
      }
    });

    test('trainBias weights are positive', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.trainBias.compoundWeight > 0, true);
        expect(s.trainBias.isolationWeight > 0, true);
        expect(s.trainBias.cardioWeight > 0, true);
        expect(s.trainBias.coreWeight > 0, true);
      }
    });

    test('skin_ambassador is limited', () {
      expect(OpponentSkinConfig.byId('skin_ambassador').isLimited, true);
    });

    test('non-ambassador skins are not limited', () {
      expect(OpponentSkinConfig.byId('default_male').isLimited, false);
      expect(OpponentSkinConfig.byId('default_female').isLimited, false);
      expect(OpponentSkinConfig.byId('skin_beginner').isLimited, false);
      expect(OpponentSkinConfig.byId('skin_iron_warrior').isLimited, false);
      expect(OpponentSkinConfig.byId('skin_cyber_ninja').isLimited, false);
    });

    test('idle and training motions have at least 2 frames', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.idleMotion.frames.length >= 2, true, reason: '${s.id} idle');
        expect(s.trainingMotion.frames.length >= 2, true, reason: '${s.id} training');
      }
    });
  });
}
