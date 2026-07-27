// test/opponent_skin_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart'; // for Color, Offset
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  group('OpponentSkinConfig', () {
    test('byId returns correct config for 4 known ids', () {
      expect(OpponentSkinConfig.byId('skin_beginner').name, '健身小白');
      expect(OpponentSkinConfig.byId('skin_iron_warrior').name, '钢铁战士');
      expect(OpponentSkinConfig.byId('skin_cyber_ninja').name, '赛博忍者');
      expect(OpponentSkinConfig.byId('skin_ambassador').name, '燃力大使');
    });

    test('byId falls back to beginner for unknown id', () {
      expect(OpponentSkinConfig.byId('unknown').id, 'skin_beginner');
    });

    test('kAllSkins contains exactly 4 skins', () {
      expect(OpponentSkinConfig.kAllSkins.length, 4);
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

    test('each skin has asset paths', () {
      for (final s in OpponentSkinConfig.kAllSkins) {
        expect(s.faceAsset?.startsWith('assets/opponent/'), true);
        expect(s.outfitAsset?.startsWith('assets/opponent/'), true);
        expect(s.propAsset?.startsWith('assets/opponent/'), true);
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
