// lib/widgets/opponent/opponent_skin_config.dart
import 'package:flutter/animation.dart'; // Curve, Curves
import 'motion/motion_player.dart';

import '../../l10n/i18n.dart';
/// 皮肤配色方案
class SkinPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color skinTone;
  final Color auraColor;
  SkinPalette({
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
  TrainBias({
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
  MotionSpec({
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
  DialogStyle({
    required this.greetings,
    required this.trainingTaunts,
    required this.winQuotes,
    required this.loseQuotes,
  });
}

/// 皮肤卡片主题（用于 PK 卡 / 详情页 / 邀请页等 UI 渗透）
/// 注：皮肤专属色固定，不随 LiftTrackColors 主题切换
class SkinCardTheme {
  final Color borderColor;
  final Color glowColor;
  final Color badgeColor;
  final String badgeEmoji;
  final List<Color> gradientColors;
  final bool showShimmer;
  SkinCardTheme({
    required this.borderColor,
    required this.glowColor,
    required this.badgeColor,
    required this.badgeEmoji,
    required this.gradientColors,
    this.showShimmer = false,
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
  final SkinCardTheme cardTheme;

  OpponentSkinConfig({
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
    required this.cardTheme,
  });

  static OpponentSkinConfig byId(String id) {
    for (final s in kAllSkins) {
      if (s.id == id) return s;
    }
    return kAllSkins.first;
  }

  static final List<OpponentSkinConfig> kAllSkins = [
    defaultMale,
    defaultFemale,
    skinBeginner,
    skinIronWarrior,
    skinCyberNinja,
    skinAmbassador,
  ];

  // ── skin_beginner（晨光起步者）── 方案A：训练哲学系列
  static final skinBeginner = OpponentSkinConfig(
    id: 'skin_beginner',
    name: trn( '晨光起步者'),
    pointsCost: trn( '100 积分'),
    isLimited: false,
    palette: SkinPalette(
      primary: const Color(0xFFA8D8B9),   // 薄荷绿
      secondary: const Color(0xFFF5EBDC),  // 米白
      accent: const Color(0xFFE8956D),     // 暖橙点缀
      skinTone: const Color(0xFFFDE3C7),
      auraColor: const Color(0xFFB5D8C2),  // 柔和薄荷光晕
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
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: const Duration(milliseconds: 2400),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, armAngle: -20),
        const MotionFrame(t: 0.5, armAngle: 20),
        const MotionFrame(t: 1.0, armAngle: -20),
      ],
      duration: const Duration(milliseconds: 1200),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '晨光初现，一起开始吧！'), trn( '今天也要元气满满~')],
      trainingTaunts: [trn( '跟着我学动作'), trn( '一步步来，不着急')],
      winQuotes: [trn( '晨光属于早起的人~'), trn( '运气不错，再来一局？')],
      loseQuotes: [trn( '你今天状态真好'), trn( '我还要多练习')],
    ),
    signatureMove: trn( '晨光弯举'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFFA8D8B9),
      glowColor: const Color(0xFFA8D8B9),
      badgeColor: const Color(0xFFA8D8B9),
      badgeEmoji: '🌱',
      gradientColors: [const Color(0xFFF0F9F2), const Color(0xFFD4ECDC)],
      showShimmer: false,
    ),
  );

  // ── skin_iron_warrior（熔铁匠人）── 方案A：训练哲学系列
  static final skinIronWarrior = OpponentSkinConfig(
    id: 'skin_iron_warrior',
    name: trn( '熔铁匠人'),
    pointsCost: trn( '300 积分'),
    isLimited: false,
    palette: SkinPalette(
      primary: const Color(0xFF4A5568),   // 石墨灰
      secondary: const Color(0xFF2D3748),  // 深炭黑
      accent: const Color(0xFFC05621),     // 熔岩橙（深）
      skinTone: const Color(0xFFE8B894),
      auraColor: const Color(0xFFFF6B35),  // 熔岩橙（亮）
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
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0), armAngle: 0),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -1), armAngle: 5),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0), armAngle: 0),
      ],
      duration: const Duration(milliseconds: 2800),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, legBend: 0),
        const MotionFrame(t: 0.5, legBend: 0.6),
        const MotionFrame(t: 1.0, legBend: 0),
      ],
      duration: const Duration(milliseconds: 1600),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '炉火已起，开工'), trn( '今天要淬炼什么？')],
      trainingTaunts: [trn( '重量再加一点'), trn( '复合动作不偷懒')],
      winQuotes: [trn( '百炼成钢'), trn( '重量说明一切')],
      loseQuotes: [trn( '后生可畏'), trn( '我回炉再造')],
    ),
    signatureMove: trn( '熔炉深蹲'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFF4A5568),
      glowColor: const Color(0xFFC05621),
      badgeColor: const Color(0xFF4A5568),
      badgeEmoji: '⚒',
      gradientColors: [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
      showShimmer: false,
    ),
  );

  // ── skin_cyber_ninja（风行游侠）── 方案A：训练哲学系列
  static final skinCyberNinja = OpponentSkinConfig(
    id: 'skin_cyber_ninja',
    name: trn( '风行游侠'),
    pointsCost: trn( '600 积分'),
    isLimited: false,
    palette: SkinPalette(
      primary: const Color(0xFF7BA7BC),   // 青瓷蓝
      secondary: const Color(0xFFD4DCE1),  // 银白
      accent: const Color(0xFF5A6B7C),     // 月灰
      skinTone: const Color(0xFFF5DEB3),
      auraColor: const Color(0xFF7BA7BC),  // 青瓷蓝光晕
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
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0), headTilt: -10),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -2), headTilt: 10),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0), headTilt: -10),
      ],
      duration: const Duration(milliseconds: 2000),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, armAngle: -45),
        const MotionFrame(t: 0.33, armAngle: 45),
        const MotionFrame(t: 0.66, armAngle: 90),
        const MotionFrame(t: 1.0, armAngle: -45),
      ],
      duration: const Duration(milliseconds: 1400),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '风起，行动'), trn( '今日风速宜训')],
      trainingTaunts: [trn( '跟上我的节奏'), trn( '看这招')],
      winQuotes: [trn( '风过无痕'), trn( '胜负已分')],
      loseQuotes: [trn( '你快了一步'), trn( '下次再战')],
    ),
    signatureMove: trn( '疾风连斩'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFF7BA7BC),
      glowColor: const Color(0xFF7BA7BC),
      badgeColor: const Color(0xFF7BA7BC),
      badgeEmoji: '🍃',
      gradientColors: [const Color(0xFFEBF2F5), const Color(0xFFD4E3EB)],
      showShimmer: true,
    ),
  );

  // ── skin_ambassador（传承导师，限定款）── 方案A：训练哲学系列
  static final skinAmbassador = OpponentSkinConfig(
    id: 'skin_ambassador',
    name: trn( '传承导师'),
    pointsCost: trn( '邀请 5 人解锁'),
    isLimited: true,
    palette: SkinPalette(
      primary: const Color(0xFF3D4F3F),   // 墨绿
      secondary: const Color(0xFFB08D57),  // 古铜金
      accent: const Color(0xFFD8C9A6),     // 米色
      skinTone: const Color(0xFFFDE3C7),
      auraColor: const Color(0xFFB08D57),  // 古铜金光晕
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
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: const Duration(milliseconds: 3000),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, armAngle: 0),
        const MotionFrame(t: 0.33, armAngle: 120),
        const MotionFrame(t: 0.66, armAngle: 240),
        const MotionFrame(t: 1.0, armAngle: 0),
      ],
      duration: const Duration(milliseconds: 1800),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '后生可畏，共勉之'), trn( '以身作则，今日开训')],
      trainingTaunts: [trn( '看示范'), trn( '动作要到位')],
      winQuotes: [trn( '传承不息'), trn( '理所当然')],
      loseQuotes: [trn( '后生可畏'), trn( '我心服口服')],
    ),
    signatureMove: trn( '传承裁决'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFFB08D57),
      glowColor: const Color(0xFFB08D57),
      badgeColor: const Color(0xFFB08D57),
      badgeEmoji: '📜',
      gradientColors: [const Color(0xFF3D4F3F), const Color(0xFF2A3830)],
      showShimmer: true,
    ),
  );

  // ── default_male（默认男性角色）── 新用户默认角色
  static final defaultMale = OpponentSkinConfig(
    id: 'default_male',
    name: trn( '默认男性角色'),
    pointsCost: trn( '免费'),
    isLimited: false,
    palette: SkinPalette(
      primary: const Color(0xFF7BA7BC),
      secondary: const Color(0xFFD4DCE1),
      accent: const Color(0xFF5A6B7C),
      skinTone: const Color(0xFFF5DEB3),
      auraColor: const Color(0xFF7BA7BC),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.4,
      isolationWeight: 0.3,
      cardioWeight: 0.2,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/default_male.png',
    outfitAsset: null,
    propAsset: null,
    idleMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: const Duration(milliseconds: 2400),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, armAngle: -20),
        const MotionFrame(t: 0.5, armAngle: 20),
        const MotionFrame(t: 1.0, armAngle: -20),
      ],
      duration: const Duration(milliseconds: 1200),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '一起开始训练吧！'), trn( '今天也要加油~')],
      trainingTaunts: [trn( '跟着节奏来'), trn( '动作要标准')],
      winQuotes: [trn( '不错嘛，再来一局？'), trn( '今天状态很好')],
      loseQuotes: [trn( '你进步很快'), trn( '下次再战')],
    ),
    signatureMove: trn( '标准弯举'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFF7BA7BC),
      glowColor: const Color(0xFF7BA7BC),
      badgeColor: const Color(0xFF7BA7BC),
      badgeEmoji: '💪',
      gradientColors: [const Color(0xFFEBF2F5), const Color(0xFFD4E3EB)],
      showShimmer: false,
    ),
  );

  // ── default_female（默认女性角色）── 新用户默认角色
  static final defaultFemale = OpponentSkinConfig(
    id: 'default_female',
    name: trn( '默认女性角色'),
    pointsCost: trn( '免费'),
    isLimited: false,
    palette: SkinPalette(
      primary: const Color(0xFFB8A9C9),
      secondary: const Color(0xFFE8E0F0),
      accent: const Color(0xFF9B8FB0),
      skinTone: const Color(0xFFFDE3C7),
      auraColor: const Color(0xFFB8A9C9),
    ),
    trainBias: TrainBias(
      compoundWeight: 0.3,
      isolationWeight: 0.4,
      cardioWeight: 0.2,
      coreWeight: 0.1,
    ),
    faceAsset: 'assets/opponent/default_female.png',
    outfitAsset: null,
    propAsset: null,
    idleMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, bodyOffset: Offset(0, 0)),
        const MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),
        const MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: const Duration(milliseconds: 2400),
    ),
    trainingMotion: MotionSpec(
      frames: [
        const MotionFrame(t: 0.0, armAngle: -20),
        const MotionFrame(t: 0.5, armAngle: 20),
        const MotionFrame(t: 1.0, armAngle: -20),
      ],
      duration: const Duration(milliseconds: 1200),
    ),
    dialogStyle: DialogStyle(
      greetings: [trn( '一起开始训练吧！'), trn( '今天也要元气满满~')],
      trainingTaunts: [trn( '跟着节奏来'), trn( '动作要标准')],
      winQuotes: [trn( '不错嘛，再来一局？'), trn( '今天状态很好')],
      loseQuotes: [trn( '你进步很快'), trn( '下次再战')],
    ),
    signatureMove: trn( '标准弯举'),
    cardTheme: SkinCardTheme(
      borderColor: const Color(0xFFB8A9C9),
      glowColor: const Color(0xFFB8A9C9),
      badgeColor: const Color(0xFFB8A9C9),
      badgeEmoji: '💪',
      gradientColors: [const Color(0xFFF0EBF5), const Color(0xFFE0D4EB)],
      showShimmer: false,
    ),
  );
}
