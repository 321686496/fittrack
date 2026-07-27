// lib/widgets/opponent/opponent_skin_config.dart
import 'dart:ui';
import 'package:flutter/animation.dart'; // Curve, Curves
import 'motion/motion_player.dart';

/// 皮肤配色方案
class SkinPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color skinTone;
  final Color auraColor;
  const SkinPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.skinTone,
    required this.auraColor,
  });
}

/// 训练偏好（影响 dailyAdvance 的 weight 范围）
class TrainBias {
  final double compoundWeight;
  final double isolationWeight;
  final double cardioWeight;
  final double coreWeight;
  const TrainBias({
    this.compoundWeight = 0.4,
    this.isolationWeight = 0.3,
    this.cardioWeight = 0.2,
    this.coreWeight = 0.1,
  });
}

/// 单帧姿势描述
class MotionFrame {
  final double t;
  final Offset bodyOffset;
  final double armAngle;
  final double legBend;
  final double headTilt;
  const MotionFrame({
    required this.t,
    this.bodyOffset = Offset.zero,
    this.armAngle = 0,
    this.legBend = 0,
    this.headTilt = 0,
  });
}

/// 动作规范（待机 / 训练循环）
class MotionSpec {
  final List<MotionFrame> frames;
  final Duration duration;
  final Curve curve;
  const MotionSpec({
    required this.frames,
    required this.duration,
    this.curve = Curves.easeInOut,
  });

  /// 按 progress (0-1) 插值出当前帧参数
  /// 实现见 motion_player.dart（Task 3）
  MotionFrame interpolate(double progress) {
    return interpolateMotion(this, progress);
  }
}

/// 文案风格
class DialogStyle {
  final List<String> greetings;
  final List<String> trainingTaunts;
  final List<String> winQuotes;
  final List<String> loseQuotes;
  const DialogStyle({
    required this.greetings,
    required this.trainingTaunts,
    required this.winQuotes,
    required this.loseQuotes,
  });
}

/// 皮肤完整配置
class OpponentSkinConfig {
  final String id;
  final String name;
  final String pointsCost;
  final bool isLimited;
  final SkinPalette palette;
  final TrainBias trainBias;
  final String? faceAsset;
  final String? outfitAsset;
  final String? propAsset;
  final MotionSpec idleMotion;
  final MotionSpec trainingMotion;
  final DialogStyle dialogStyle;
  final String signatureMove;

  const OpponentSkinConfig({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.isLimited,
    required this.palette,
    required this.trainBias,
    required this.faceAsset,
    required this.outfitAsset,
    required this.propAsset,
    required this.idleMotion,
    required this.trainingMotion,
    required this.dialogStyle,
    required this.signatureMove,
  });

  static OpponentSkinConfig byId(String id) {
    for (final s in kAllSkins) {
      if (s.id == id) return s;
    }
    return kAllSkins.first;
  }

  static const List<OpponentSkinConfig> kAllSkins = [
    skinBeginner,
    skinIronWarrior,
    skinCyberNinja,
    skinAmbassador,
  ];

  // ── skin_beginner（健身小白）──
  static const skinBeginner = OpponentSkinConfig(
    id: 'skin_beginner',
    name: '健身小白',
    pointsCost: '100 积分',
    isLimited: false,
    palette: SkinPalette(
      primary: Color(0xFFFFB87A),
      secondary: Color(0xFFFFE3C2),
      accent: Color(0xFFFF6B35),
      skinTone: Color(0xFFFDE3C7),
      auraColor: Color(0xFFFF8C5A),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.3,
      isolationWeight: 0.5,
      cardioWeight: 0.1,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/face_beginner.png',
    outfitAsset: 'assets/opponent/outfit_beginner.png',
    propAsset: 'assets/opponent/prop_beginner.png',
    idleMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: Duration(milliseconds: 2400),
    ),
    trainingMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: -20),
        MotionFrame(t: 0.5, armAngle: 20),
        MotionFrame(t: 1.0, armAngle: -20),
      ],
      duration: Duration(milliseconds: 1200),
    ),
    dialogStyle: DialogStyle(
      greetings: ['今天也要加油哦！', '一起开始训练吧~'],
      trainingTaunts: ['跟着我一起学动作', '坚持就是胜利！'],
      winQuotes: ['哇我赢了，下次你也加油', '运气好啦~'],
      loseQuotes: ['你太厉害了，向你学习', '下次我也要更努力'],
    ),
    signatureMove: '活力弯举',
  );

  // ── skin_iron_warrior（钢铁战士）──
  static const skinIronWarrior = OpponentSkinConfig(
    id: 'skin_iron_warrior',
    name: '钢铁战士',
    pointsCost: '300 积分',
    isLimited: false,
    palette: SkinPalette(
      primary: Color(0xFF9B2C2C),
      secondary: Color(0xFF4A5568),
      accent: Color(0xFFF56565),
      skinTone: Color(0xFFE8B894),
      auraColor: Color(0xFFFF4E50),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.6,
      isolationWeight: 0.2,
      cardioWeight: 0.1,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/face_iron.png',
    outfitAsset: 'assets/opponent/outfit_iron.png',
    propAsset: 'assets/opponent/prop_iron.png',
    idleMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, bodyOffset: Offset(0, 0), armAngle: 0),
        MotionFrame(t: 0.5, bodyOffset: Offset(0, -1), armAngle: 5),
        MotionFrame(t: 1.0, bodyOffset: Offset(0, 0), armAngle: 0),
      ],
      duration: Duration(milliseconds: 2800),
    ),
    trainingMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, legBend: 0),
        MotionFrame(t: 0.5, legBend: 0.6),
        MotionFrame(t: 1.0, legBend: 0),
      ],
      duration: Duration(milliseconds: 1600),
    ),
    dialogStyle: DialogStyle(
      greetings: ['今天也要炸裂重量！', '复合动作才是王道'],
      trainingTaunts: ['扛上去！', '别让我失望'],
      winQuotes: ['这就是力量的差距', '下一组加重'],
      loseQuotes: ['你确实强', '我还要再练'],
    ),
    signatureMove: '裂地深蹲',
  );

  // ── skin_cyber_ninja（赛博忍者）──
  static const skinCyberNinja = OpponentSkinConfig(
    id: 'skin_cyber_ninja',
    name: '赛博忍者',
    pointsCost: '600 积分',
    isLimited: false,
    palette: SkinPalette(
      primary: Color(0xFF9B5DE5),
      secondary: Color(0xFF00F5FF),
      accent: Color(0xFFF15BB5),
      skinTone: Color(0xFFF5DEB3),
      auraColor: Color(0xFF9B5DE5),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.2,
      isolationWeight: 0.2,
      cardioWeight: 0.5,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/face_ninja.png',
    outfitAsset: 'assets/opponent/outfit_ninja.png',
    propAsset: 'assets/opponent/prop_ninja.png',
    idleMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, bodyOffset: Offset(0, 0), headTilt: -10),
        MotionFrame(t: 0.5, bodyOffset: Offset(0, -2), headTilt: 10),
        MotionFrame(t: 1.0, bodyOffset: Offset(0, 0), headTilt: -10),
      ],
      duration: Duration(milliseconds: 2000),
    ),
    trainingMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: -45),
        MotionFrame(t: 0.33, armAngle: 45),
        MotionFrame(t: 0.66, armAngle: 90),
        MotionFrame(t: 1.0, armAngle: -45),
      ],
      duration: Duration(milliseconds: 1400),
    ),
    dialogStyle: DialogStyle(
      greetings: ['敏捷训练上线', '影从黑暗来'],
      trainingTaunts: ['我的速度你跟不上', '看招'],
      winQuotes: ['胜负已分', '影遁'],
      loseQuotes: ['下次见', '你快了一步'],
    ),
    signatureMove: '闪影连斩',
  );

  // ── skin_ambassador（燃力大使，限定款）──
  static const skinAmbassador = OpponentSkinConfig(
    id: 'skin_ambassador',
    name: '燃力大使',
    pointsCost: '邀请 5 人解锁',
    isLimited: true,
    palette: SkinPalette(
      primary: Color(0xFF1A1A1A),
      secondary: Color(0xFFFFD700),
      accent: Color(0xFFFFA500),
      skinTone: Color(0xFFFDE3C7),
      auraColor: Color(0xFFFFD700),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.4,
      isolationWeight: 0.3,
      cardioWeight: 0.2,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/face_ambassador.png',
    outfitAsset: 'assets/opponent/outfit_ambassador.png',
    propAsset: 'assets/opponent/prop_ambassador.png',
    idleMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: Duration(milliseconds: 3000),
    ),
    trainingMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: 0),
        MotionFrame(t: 0.33, armAngle: 120),
        MotionFrame(t: 0.66, armAngle: 240),
        MotionFrame(t: 1.0, armAngle: 0),
      ],
      duration: Duration(milliseconds: 1800),
    ),
    dialogStyle: DialogStyle(
      greetings: ['以身作则，引领大家', '感谢你的邀请，让我来到这里'],
      trainingTaunts: ['跟我一起', '示范一下'],
      winQuotes: ['皇者归来', '理所当然'],
      loseQuotes: ['后生可畏', '我心服口服'],
    ),
    signatureMove: '王者裁决',
  );
}
