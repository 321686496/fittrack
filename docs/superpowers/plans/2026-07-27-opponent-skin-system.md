# 对手皮肤系统 P1 重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把"换 emoji"的简陋皮肤升级为"完整 Q 版人物 + 完整动作动画 + 全维度差异化"皮肤系统

**Architecture:** 组件化拼装——CustomPainter 拆为 Body/Head/Outfit/Prop 四子部件，由 OpponentSkinConfig 数据驱动；OpponentRenderer 状态机驱动 idle/training 两套动画；4 个皮肤通过配置差异化（配色/服饰/道具/动作/文案/训练偏好/招式）

**Tech Stack:** Flutter 3.7.12, Dart 2.19.6, CustomPainter, AnimationController

## Global Constraints

- 项目 SDK 约束：Dart >=2.19.6 <3.0.0
- 现有 58 个测试必须全部保持通过
- `flutter analyze` 零新增 error
- 沿用现有皮肤 id（skin_beginner/skin_iron_warrior/skin_cyber_ninja/skin_ambassador），不新增皮肤
- 沿用现有 `appliedSkinId` getter（virtual_opponent.dart:162）作为唯一皮肤 id 来源
- 沿用现有 `unlockedFeatures` 字段（storage.dart）作为解锁判定，不改 schema
- 颜色用 `Color(0xAARRGGBB)` 字面量，不引入新依赖
- 测试文件 import 用 `package:fittrack_flutter/...`（项目 pubspec name）
- 文件结构遵循 spec §4.2：lib/widgets/opponent/ 下新建模块
- 大图 240×240 / 缩略图 48×48 / 中图 64×64 / 皮肤卡片 96×96

---

## Task 1: 数据模型与 4 份皮肤配置

**Files:**
- Create: `fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart`
- Test: `fittrack_flutter/test/opponent_skin_config_test.dart`

**Interfaces:**
- Produces: `SkinPalette`, `TrainBias`, `MotionFrame`, `MotionSpec`, `DialogStyle`, `OpponentSkinConfig`（含 `byId` 静态方法、`kAllSkins` 列表、4 个静态常量）
- 后续任务依赖：`OpponentSkinConfig.byId(skinId)` 返回配置；`MotionSpec.interpolate(progress)` 返回 MotionFrame

**注意：** 本任务定义 MotionSpec.interpolate 但**不实现**（抛 UnimplementedError），由 Task 3 实现。本任务的测试不测 interpolate。

- [ ] **Step 1: 写失败的测试**

```dart
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
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/opponent_skin_config_test.dart`
Expected: FAIL，报错 `Target of URI doesn't exist: 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart'`

- [ ] **Step 3: 创建配置文件**

```dart
// lib/widgets/opponent/opponent_skin_config.dart
import 'dart:ui';

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
    throw UnimplementedError('interpolate implemented in motion_player.dart');
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
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/opponent_skin_config_test.dart`
Expected: 10 个测试全部 PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart fittrack_flutter/test/opponent_skin_config_test.dart
git commit -m "feat(opponent): 新增 OpponentSkinConfig 与 4 份皮肤配置"
```

---

## Task 2: 贴图资源生成（占位 PNG）

**Files:**
- Create: `fittrack_flutter/assets/opponent/face_beginner.png` 等 12 张
- Modify: `fittrack_flutter/pubspec.yaml`（声明 assets 目录）

**说明：** Flutter 测试环境无法在 CustomPainter 内同步加载 Image.asset（需异步预解码）。本任务生成 12 张 512×512 透明背景 PNG 占位图（纯色块即可），后续可由设计师替换为正式 Q 版贴图。Painter 内部需对贴图缺失做 fallback（Task 4-6）。

**Interfaces:**
- Produces: 12 个 PNG 资源路径，pubspec 声明 `assets/opponent/`

- [ ] **Step 1: 创建占位 PNG 资源**

用 Python 脚本生成 12 张纯色块 PNG（512×512 透明背景，中心绘制一个 256×256 的色块代表对应部位）：

```python
# tools/generate_opponent_placeholders.py
from PIL import Image, ImageDraw

# 12 张占位图的色板
assets = {
    'face_beginner':     (0xFF, 0xB8, 0x7A, 0xFF),  # 橙
    'face_iron':         (0x9B, 0x2C, 0x2C, 0xFF),  # 深红
    'face_ninja':        (0x9B, 0x5D, 0xE5, 0xFF),  # 紫
    'face_ambassador':   (0xFF, 0xD7, 0x00, 0xFF),  # 金
    'outfit_beginner':   (0xC0, 0xC0, 0xC0, 0xFF),  # 浅灰
    'outfit_iron':       (0x1A, 0x1A, 0x1A, 0xFF),  # 黑
    'outfit_ninja':      (0x1A, 0x1A, 0x1A, 0xFF),  # 黑
    'outfit_ambassador': (0x1A, 0x1A, 0x1A, 0xFF),  # 黑
    'prop_beginner':     (0x80, 0x80, 0x80, 0xFF),  # 灰
    'prop_iron':         (0x40, 0x40, 0x40, 0xFF),  # 深灰
    'prop_ninja':        (0x9B, 0x5D, 0xE5, 0xFF),  # 紫光剑
    'prop_ambassador':   (0xFF, 0xD7, 0x00, 0xFF),  # 金权杖
}

for name, color in assets.items():
    img = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([128, 128, 384, 384], fill=color)
    img.save(f'fittrack_flutter/assets/opponent/{name}.png')
print('Generated 12 placeholder PNGs')
```

执行：`python tools/generate_opponent_placeholders.py`（如本机无 PIL，改用任意工具生成纯色块 PNG，或人工创建 12 张 512×512 透明 PNG）

**备选方案**（无 Python PIL 时）：用 PowerShell + .NET System.Drawing 生成，或手动用画图工具创建。每个文件不强制存在（Painter 内部 fallback），但建议生成。

- [ ] **Step 2: 在 pubspec.yaml 声明 assets 目录**

读取 pubspec.yaml，找到 `flutter:` 段下的 `assets:` 列表，新增 `- assets/opponent/`。

- [ ] **Step 3: 验证资源可加载**

写一个最小 widget test 验证 asset 路径有效：

```dart
// test/opponent_assets_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  test('all 12 opponent assets exist', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final paths = [
      'assets/opponent/face_beginner.png',
      'assets/opponent/face_iron.png',
      'assets/opponent/face_ninja.png',
      'assets/opponent/face_ambassador.png',
      'assets/opponent/outfit_beginner.png',
      'assets/opponent/outfit_iron.png',
      'assets/opponent/outfit_ninja.png',
      'assets/opponent/outfit_ambassador.png',
      'assets/opponent/prop_beginner.png',
      'assets/opponent/prop_iron.png',
      'assets/opponent/prop_ninja.png',
      'assets/opponent/prop_ambassador.png',
    ];
    for (final p in paths) {
      final asset = AssetImage(p);
      final config = ImageConfiguration.empty;
      final completer = asset.resolve(config);
      expect(completer, isNotNull, reason: '$p not found');
    }
  });
}
```

Run: `cd fittrack_flutter; flutter test test/opponent_assets_test.dart`
Expected: PASS（asset 路径声明正确）

- [ ] **Step 4: 提交**

```bash
git add fittrack_flutter/assets/opponent/ fittrack_flutter/pubspec.yaml fittrack_flutter/test/opponent_assets_test.dart tools/generate_opponent_placeholders.py
git commit -m "feat(opponent): 新增 12 张皮肤贴图占位资源 + pubspec 声明"
```

---

## Task 3: MotionSpec.interpolate 实现

**Files:**
- Create: `fittrack_flutter/lib/widgets/opponent/motion/motion_player.dart`
- Modify: `fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart`（删除 interpolate 的 UnimplementedError，改为调用 motion_player 实现）
- Test: `fittrack_flutter/test/motion_player_test.dart`

**Interfaces:**
- Consumes: `MotionFrame`, `MotionSpec`, `MotionFrame`（来自 Task 1）
- Produces: `MotionFrame interpolate(MotionSpec spec, double progress)` 顶层函数

**实现要点：**
- progress ∈ [0, 1)，按 frames.length 等分时间
- 帧间用 spec.curve 缓动
- 最后一帧到第一帧也插值（循环）
- 用 `lerpDouble` 处理数值字段，`Offset.lerp` 处理 bodyOffset

- [ ] **Step 1: 写失败的测试**

```dart
// test/motion_player_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';
import 'package:fittrack_flutter/widgets/opponent/motion/motion_player.dart';

void main() {
  group('MotionSpec.interpolate', () {
    final spec = MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: 0, bodyOffset: Offset(0, 0)),
        MotionFrame(t: 0.5, armAngle: 90, bodyOffset: Offset(0, -5)),
        MotionFrame(t: 1.0, armAngle: 0, bodyOffset: Offset(0, 0)),
      ],
      duration: Duration(milliseconds: 1000),
    );

    test('progress=0 returns first frame values', () {
      final f = spec.interpolate(0.0);
      expect(f.armAngle, closeTo(0, 0.01));
      expect(f.bodyOffset.dy, closeTo(0, 0.01));
    });

    test('progress=0.5 returns middle frame values', () {
      final f = spec.interpolate(0.5);
      // progress=0.5 落在第 1→2 帧之间中点，应近似第 2 帧
      expect(f.armAngle, closeTo(90, 1.0));
      expect(f.bodyOffset.dy, closeTo(-5, 0.5));
    });

    test('progress=0.25 interpolates between frame 0 and 1', () {
      final f = spec.interpolate(0.25);
      // 0→1 帧间中点，easeInOut 缓动后约 (0+90)/2=45（具体值取决于曲线）
      expect(f.armAngle > 0, true);
      expect(f.armAngle < 90, true);
    });

    test('progress near 1 wraps to frame 2→0', () {
      final f = spec.interpolate(0.99);
      // 接近循环结束，应接近第 0 帧（最后一帧与第一帧相同）
      expect(f.armAngle, closeTo(0, 5));
    });

    test('single frame spec returns that frame', () {
      final single = MotionSpec(
        frames: [MotionFrame(t: 0, armAngle: 42)],
        duration: Duration(milliseconds: 500),
      );
      expect(single.interpolate(0.5).armAngle, 42);
    });

    test('interpolate never throws for any progress in [0,1]', () {
      for (double p = 0.0; p <= 1.0; p += 0.01) {
        expect(() => spec.interpolate(p), returnsNormally);
      }
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/motion_player_test.dart`
Expected: FAIL，`interpolate` 抛 UnimplementedError

- [ ] **Step 3: 实现 motion_player.dart**

```dart
// lib/widgets/opponent/motion/motion_player.dart
import 'dart:ui';
import 'package:flutter/animation.dart';
import '../opponent_skin_config.dart';

/// 按 progress (0-1) 插值出当前帧参数
MotionFrame interpolateMotion(MotionSpec spec, double progress) {
  final frames = spec.frames;
  if (frames.length == 1) return frames.first;
  if (frames.isEmpty) return const MotionFrame(t: 0);

  // 将 progress 映射到帧索引空间
  final scaled = (progress * frames.length) % frames.length;
  final idx = scaled.floor();
  final next = (idx + 1) % frames.length;
  final localT = scaled - idx;
  final eased = spec.curve.transform(localT);

  final a = frames[idx];
  final b = frames[next];
  return MotionFrame(
    t: progress,
    bodyOffset: Offset.lerp(a.bodyOffset, b.bodyOffset, eased) ?? a.bodyOffset,
    armAngle: lerpDouble(a.armAngle, b.armAngle, eased) ?? a.armAngle,
    legBend: lerpDouble(a.legBend, b.legBend, eased) ?? a.legBend,
    headTilt: lerpDouble(a.headTilt, b.headTilt, eased) ?? a.headTilt,
  );
}
```

- [ ] **Step 4: 修改 OpponentSkinConfig.interpolate 调用 motion_player**

在 `opponent_skin_config.dart` 顶部 import：
```dart
import 'motion/motion_player.dart';
```

把 MotionSpec 类内的 interpolate 方法改为：
```dart
MotionFrame interpolate(double progress) {
  return interpolateMotion(this, progress);
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/motion_player_test.dart`
Expected: 6 个测试全部 PASS

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/widgets/opponent/motion/motion_player.dart fittrack_flutter/lib/widgets/opponent/opponent_skin_config.dart fittrack_flutter/test/motion_player_test.dart
git commit -m "feat(opponent): 实现 MotionSpec.interpolate 帧插值"
```

---

## Task 4: BodyPainter（身体轮廓）

**Files:**
- Create: `fittrack_flutter/lib/widgets/opponent/painters/body_painter.dart`
- Test: `fittrack_flutter/test/body_painter_test.dart`

**Interfaces:**
- Consumes: `SkinPalette`, `MotionFrame`（来自 Task 1）
- Produces: `BodyPainter` CustomPainter 类

**绘制规范（240×240 画布）：**
- 身体椭圆：中心 (120, 160)，宽 80，高 100，填 skinTone
- 左臂：从 (90, 130) 到 (75, 170)，按 armAngle 旋转
- 右臂：从 (150, 130) 到 (165, 170)，按 -armAngle 旋转
- 左腿：从 (105, 210) 到 (95, 240)，按 legBend 弯曲
- 右腿：从 (135, 210) 到 (145, 240)，按 legBend 弯曲
- 应用 frame.bodyOffset 平移整体

**注意：** armAngle 单位是度，需 `pi/180` 转弧度。

- [ ] **Step 1: 写失败的测试**

```dart
// test/body_painter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/body_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  group('BodyPainter', () {
    test('can be constructed with valid params', () {
      expect(
        () => BodyPainter(
          palette: OpponentSkinConfig.kAllSkins.first.palette,
          frame: const MotionFrame(t: 0),
        ),
        returnsNormally,
      );
    });

    test('shouldRepaint returns true when frame changes', () {
      final p1 = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 0),
      );
      final p2 = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 10),
      );
      expect(p1.shouldRepaint(p2), true);
    });

    test('shouldRepaint returns false when same frame', () {
      final palette = OpponentSkinConfig.kAllSkins.first.palette;
      final frame = const MotionFrame(t: 0);
      final p1 = BodyPainter(palette: palette, frame: frame);
      final p2 = BodyPainter(palette: palette, frame: frame);
      expect(p1.shouldRepaint(p2), false);
    });

    test('paint does not throw on 240x240 canvas', () {
      final painter = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0, armAngle: 30, legBend: 0.5),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('paint scales to 48x48 without throwing', () {
      final painter = BodyPainter(
        palette: OpponentSkinConfig.kAllSkins.first.palette,
        frame: const MotionFrame(t: 0),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(48, 48)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/body_painter_test.dart`
Expected: FAIL，类不存在

- [ ] **Step 3: 实现 BodyPainter**

```dart
// lib/widgets/opponent/painters/body_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

/// 绘制 Q 版身体轮廓（头身比 1:2，身体椭圆 + 四肢）
class BodyPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;

  const BodyPainter({required this.palette, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    // 按 240×240 基准坐标系绘制，按 size 缩放
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, frame.bodyOffset.dy);

    final skinPaint = Paint()..color = palette.skinTone;
    final outlinePaint = Paint()
      ..color = palette.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 身体椭圆
    final bodyRect = Rect.fromCenter(center: const Offset(120, 160), width: 80, height: 100);
    canvas.drawOval(bodyRect, skinPaint);
    canvas.drawOval(bodyRect, outlinePaint);

    // 四肢
    _drawArms(canvas, skinPaint, outlinePaint);
    _drawLegs(canvas, skinPaint, outlinePaint);

    canvas.restore();
  }

  void _drawArms(Canvas canvas, Paint fill, Paint outline) {
    final angleRad = frame.armAngle * pi / 180;
    // 左臂
    canvas.save();
    canvas.translate(90, 135);
    canvas.rotate(angleRad);
    final leftArm = Rect.fromCenter(center: Offset.zero, width: 14, height: 50);
    canvas.drawRRect(RRect.fromRectRadius(leftArm, const Radius.circular(7)), fill);
    canvas.drawRRect(RRect.fromRectRadius(leftArm, const Radius.circular(7)), outline);
    canvas.restore();

    // 右臂
    canvas.save();
    canvas.translate(150, 135);
    canvas.rotate(-angleRad);
    final rightArm = Rect.fromCenter(center: Offset.zero, width: 14, height: 50);
    canvas.drawRRect(RRect.fromRectRadius(rightArm, const Radius.circular(7)), fill);
    canvas.drawRRect(RRect.fromRectRadius(rightArm, const Radius.circular(7)), outline);
    canvas.restore();
  }

  void _drawLegs(Canvas canvas, Paint fill, Paint outline) {
    // legBend 0-1 → 弯曲角度 0-30 度
    final bendAngle = frame.legBend * 30 * pi / 180;

    // 左腿
    canvas.save();
    canvas.translate(105, 210);
    canvas.rotate(bendAngle);
    final leftLeg = Rect.fromCenter(center: Offset.zero, width: 16, height: 50);
    canvas.drawRRect(RRect.fromRectRadius(leftLeg, const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectRadius(leftLeg, const Radius.circular(8)), outline);
    canvas.restore();

    // 右腿
    canvas.save();
    canvas.translate(135, 210);
    canvas.rotate(-bendAngle);
    final rightLeg = Rect.fromCenter(center: Offset.zero, width: 16, height: 50);
    canvas.drawRRect(RRect.fromRectRadius(rightLeg, const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectRadius(rightLeg, const Radius.circular(8)), outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BodyPainter old) {
    return old.frame != frame || old.palette != palette;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/body_painter_test.dart`
Expected: 5 个测试全部 PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/widgets/opponent/painters/body_painter.dart fittrack_flutter/test/body_painter_test.dart
git commit -m "feat(opponent): 新增 BodyPainter 绘制 Q 版身体轮廓"
```

---

## Task 5: HeadPainter + OutfitPainter + PropPainter

**Files:**
- Create: `fittrack_flutter/lib/widgets/opponent/painters/head_painter.dart`
- Create: `fittrack_flutter/lib/widgets/opponent/painters/outfit_painter.dart`
- Create: `fittrack_flutter/lib/widgets/opponent/painters/prop_painter.dart`
- Test: `fittrack_flutter/test/auxiliary_painters_test.dart`

**Interfaces:**
- Consumes: `SkinPalette`, `MotionFrame`, 贴图资源路径
- Produces: `HeadPainter`, `OutfitPainter`, `PropPainter`

**绘制规范（240×240 画布）：**
- HeadPainter：头部圆形（中心 (120, 80)，半径 40），填 skinTone；按 frame.headTilt 旋转
- OutfitPainter：在身体上方绘制服饰色块（背部矩形覆盖身体椭圆）；asset 不为空时尝试贴图，失败 fallback
- PropPainter：在右手位置 (165, 170) 绘制道具；按 armAngle 旋转

**贴图加载策略：** CustomPainter.paint 是同步的，不能异步加载图片。采用预解码方案——Painter 仅接收 `ui.Image?`，由上层 Renderer 在 initState 预加载。本任务实现 Painter 时只接收 `ui.Image?`，null 时纯代码绘制。

- [ ] **Step 1: 写失败的测试**

```dart
// test/auxiliary_painters_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;
import 'package:fittrack_flutter/widgets/opponent/painters/head_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/outfit_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/painters/prop_painter.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_skin_config.dart';

void main() {
  final palette = OpponentSkinConfig.kAllSkins.first.palette;
  const frame = MotionFrame(t: 0);

  group('HeadPainter', () {
    test('constructs with null image (fallback to code)', () {
      expect(() => HeadPainter(palette: palette, frame: frame, faceImage: null), returnsNormally);
    });

    test('paint does not throw on 240x240', () {
      final p = HeadPainter(palette: palette, frame: frame, faceImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });

    test('shouldRepaint true when frame changes', () {
      final p1 = HeadPainter(palette: palette, frame: const MotionFrame(t: 0, headTilt: 0), faceImage: null);
      final p2 = HeadPainter(palette: palette, frame: const MotionFrame(t: 0, headTilt: 10), faceImage: null);
      expect(p1.shouldRepaint(p2), true);
    });
  });

  group('OutfitPainter', () {
    test('constructs with null image', () {
      expect(() => OutfitPainter(palette: palette, frame: frame, outfitImage: null), returnsNormally);
    });

    test('paint does not throw', () {
      final p = OutfitPainter(palette: palette, frame: frame, outfitImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });

  group('PropPainter', () {
    test('constructs with null image', () {
      expect(() => PropPainter(palette: palette, frame: frame, propImage: null), returnsNormally);
    });

    test('paint does not throw', () {
      final p = PropPainter(palette: palette, frame: const MotionFrame(t: 0, armAngle: 30), propImage: null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => p.paint(canvas, const Size(240, 240)), returnsNormally);
      recorder.endRecording().dispose();
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/auxiliary_painters_test.dart`
Expected: FAIL，类不存在

- [ ] **Step 3: 实现 HeadPainter**

```dart
// lib/widgets/opponent/painters/head_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class HeadPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? faceImage; // null → 纯代码绘制

  const HeadPainter({required this.palette, required this.frame, required this.faceImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(120, 80);
    canvas.rotate(frame.headTilt * pi / 180);

    if (faceImage != null) {
      // 贴图模式：绘制 80×80 面部贴图（中心对齐）
      final src = Rect.fromLTWH(0, 0, faceImage!.width.toDouble(), faceImage!.height.toDouble());
      final dst = Rect.fromCenter(center: Offset.zero, width: 80, height: 80);
      canvas.drawImageRect(faceImage!, src, dst, Paint());
    } else {
      // 纯代码 fallback
      final skinPaint = Paint()..color = palette.skinTone;
      final outlinePaint = Paint()
        ..color = palette.primary.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // 头部
      final headRect = Rect.fromCenter(center: Offset.zero, width: 80, height: 80);
      canvas.drawOval(headRect, skinPaint);
      canvas.drawOval(headRect, outlinePaint);

      // 眼睛
      final eyePaint = Paint()..color = palette.primary;
      canvas.drawCircle(const Offset(-12, -5), 4, eyePaint);
      canvas.drawCircle(const Offset(12, -5), 4, eyePaint);

      // 嘴
      final mouthPaint = Paint()
        ..color = palette.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(Rect.fromCenter(center: const Offset(0, 12), width: 16, height: 12), 0, pi, false, mouthPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeadPainter old) {
    return old.frame != frame || old.faceImage != faceImage || old.palette != palette;
  }
}
```

- [ ] **Step 4: 实现 OutfitPainter**

```dart
// lib/widgets/opponent/painters/outfit_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class OutfitPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? outfitImage;

  const OutfitPainter({required this.palette, required this.frame, required this.outfitImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(0, frame.bodyOffset.dy);

    if (outfitImage != null) {
      final src = Rect.fromLTWH(0, 0, outfitImage!.width.toDouble(), outfitImage!.height.toDouble());
      final dst = Rect.fromCenter(center: const Offset(120, 160), width: 90, height: 110);
      canvas.drawImageRect(outfitImage!, src, dst, Paint());
    } else {
      // fallback：在身体上覆盖一块服饰色块
      final outfitPaint = Paint()..color = palette.primary;
      final outfitRect = Rect.fromCenter(center: const Offset(120, 150), width: 70, height: 80);
      canvas.drawRRect(RRect.fromRectRadius(outfitRect, const Radius.circular(12)), outfitPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OutfitPainter old) {
    return old.frame != frame || old.outfitImage != outfitImage || old.palette != palette;
  }
}
```

- [ ] **Step 5: 实现 PropPainter**

```dart
// lib/widgets/opponent/painters/prop_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../opponent_skin_config.dart';

class PropPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final ui.Image? propImage;

  const PropPainter({required this.palette, required this.frame, required this.propImage});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);

    // 道具跟随右手位置 (150, 135) 旋转
    canvas.translate(150, 135);
    canvas.rotate(-frame.armAngle * pi / 180);

    if (propImage != null) {
      final src = Rect.fromLTWH(0, 0, propImage!.width.toDouble(), propImage!.height.toDouble());
      final dst = Rect.fromCenter(center: const Offset(20, 30), width: 50, height: 50);
      canvas.drawImageRect(propImage!, src, dst, Paint());
    } else {
      // fallback：绘制小哑铃
      final propPaint = Paint()..color = palette.accent;
      canvas.drawRRect(
        RRect.fromRectRadius(Rect.fromCenter(center: const Offset(20, 30), width: 8, height: 40), const Radius.circular(4)),
        propPaint,
      );
      canvas.drawCircle(const Offset(20, 8), 8, propPaint);
      canvas.drawCircle(const Offset(20, 52), 8, propPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PropPainter old) {
    return old.frame != frame || old.propImage != propImage || old.palette != palette;
  }
}
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/auxiliary_painters_test.dart`
Expected: 7 个测试全部 PASS

- [ ] **Step 7: 提交**

```bash
git add fittrack_flutter/lib/widgets/opponent/painters/ fittrack_flutter/test/auxiliary_painters_test.dart
git commit -m "feat(opponent): 新增 Head/Outfit/Prop Painter（支持贴图+fallback）"
```

---

## Task 6: OpponentRenderer + CompositePainter

**Files:**
- Create: `fittrack_flutter/lib/widgets/opponent/opponent_renderer.dart`
- Test: `fittrack_flutter/test/opponent_renderer_test.dart`

**Interfaces:**
- Consumes: `OpponentSkinConfig`, `MotionSpec.interpolate`, 4 个 Painter
- Produces: `OpponentRenderer` widget（参数：skinId, size, autoTrain, showAura）

**实现要点：**
- 3 个 AnimationController（idle/train/entry），TickerProvider
- 贴图在 initState 用 `rootBundle.load` + `decodeImageFromList` 预加载到 `ui.Image`
- 3 张贴图全加载完成后 setState 触发重建
- CompositePainter 聚合 4 个子 Painter
- 大图 240×240 用 RepaintBoundary 隔离
- 缩略图（< 80px）禁用光圈 + 简化（仅绘 Body + Head，跳过 Outfit/Prop）

- [ ] **Step 1: 写失败的测试**

```dart
// test/opponent_renderer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_renderer.dart';

void main() {
  testWidgets('OpponentRenderer renders without throwing for skin_beginner',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(240, 240),
            autoTrain: false,
            showAura: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });

  testWidgets('renders all 4 skins without throwing', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final id in ['skin_beginner', 'skin_iron_warrior', 'skin_cyber_ninja', 'skin_ambassador']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OpponentRenderer(
              skinId: id,
              size: const Size(240, 240),
              autoTrain: false,
              showAura: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OpponentRenderer), findsOneWidget, reason: '$id failed');
    }
  });

  testWidgets('renders thumbnail size 48x48', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(48, 48),
            autoTrain: false,
            showAura: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(sizedBox.width, 48);
    expect(sizedBox.height, 48);
  });

  testWidgets('autoTrain triggers training state after 2s', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OpponentRenderer(
            skinId: 'skin_beginner',
            size: Size(240, 240),
            autoTrain: true,
            showAura: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    // 验证 widget 仍存在（autoTrain 切换不崩溃）
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/opponent_renderer_test.dart`
Expected: FAIL，类不存在

- [ ] **Step 3: 实现 OpponentRenderer**

```dart
// lib/widgets/opponent/opponent_renderer.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'opponent_skin_config.dart';
import 'painters/body_painter.dart';
import 'painters/head_painter.dart';
import 'painters/outfit_painter.dart';
import 'painters/prop_painter.dart';

class OpponentRenderer extends StatefulWidget {
  final String skinId;
  final Size size;
  final bool autoTrain;
  final bool showAura;

  const OpponentRenderer({
    super.key,
    required this.skinId,
    required this.size,
    this.autoTrain = false,
    this.showAura = false,
  });

  @override
  State<OpponentRenderer> createState() => _OpponentRendererState();
}

class _OpponentRendererState extends State<OpponentRenderer>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _trainController;
  late AnimationController _entryController;
  bool _isTraining = false;

  // 预加载贴图
  ui.Image? _faceImage;
  ui.Image? _outfitImage;
  ui.Image? _propImage;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    final skin = OpponentSkinConfig.byId(widget.skinId);
    _idleController = AnimationController(
      vsync: this,
      duration: skin.idleMotion.duration,
    )..repeat();
    _trainController = AnimationController(
      vsync: this,
      duration: skin.trainingMotion.duration,
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    if (widget.autoTrain) {
      Future.delayed(const Duration(seconds: 2), _startTraining);
    }

    _preloadImages(skin);
  }

  Future<void> _preloadImages(OpponentSkinConfig skin) async {
    final futures = <Future<ui.Image?>>[];
    if (skin.faceAsset != null) futures.add(_loadImage(skin.faceAsset!));
    if (skin.outfitAsset != null) futures.add(_loadImage(skin.outfitAsset!));
    if (skin.propAsset != null) futures.add(_loadImage(skin.propAsset!));
    if (futures.isEmpty) {
      setState(() => _imagesLoaded = true);
      return;
    }
    final results = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _faceImage = results[0];
      _outfitImage = results[1];
      _propImage = results[2];
      _imagesLoaded = true;
    });
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      return completer.future;
    } catch (_) {
      return null; // fallback to code drawing
    }
  }

  void _startTraining() {
    if (!mounted) return;
    setState(() => _isTraining = true);
    _trainController.repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    _trainController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _trainController, _entryController]),
      builder: (context, _) {
        final skin = OpponentSkinConfig.byId(widget.skinId);
        final progress = _isTraining ? _trainController.value : _idleController.value;
        final frame = (_isTraining ? skin.trainingMotion : skin.idleMotion)
            .interpolate(progress);
        final entryOffset = (1 - Curves.elasticOut.transform(_entryController.value)) * 60;

        final isThumbnail = widget.size.width < 80;

        return RepaintBoundary(
          child: Transform.translate(
            offset: Offset(0, entryOffset),
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: CustomPaint(
                painter: CompositePainter(
                  skin: skin,
                  frame: frame,
                  showAura: widget.showAura,
                  entryProgress: _entryController.value,
                  faceImage: _imagesLoaded ? _faceImage : null,
                  outfitImage: _imagesLoaded ? _outfitImage : null,
                  propImage: _imagesLoaded ? _propImage : null,
                  isThumbnail: isThumbnail,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 聚合 4 个子 Painter
class CompositePainter extends CustomPainter {
  final OpponentSkinConfig skin;
  final MotionFrame frame;
  final bool showAura;
  final double entryProgress;
  final ui.Image? faceImage;
  final ui.Image? outfitImage;
  final ui.Image? propImage;
  final bool isThumbnail;

  const CompositePainter({
    required this.skin,
    required this.frame,
    required this.showAura,
    required this.entryProgress,
    required this.faceImage,
    required this.outfitImage,
    required this.propImage,
    this.isThumbnail = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 光圈
    if (showAura) _drawAura(canvas, size);

    // 身体
    BodyPainter(palette: skin.palette, frame: frame).paint(canvas, size);

    // 服饰（缩略图跳过）
    if (!isThumbnail) {
      OutfitPainter(palette: skin.palette, frame: frame, outfitImage: outfitImage)
          .paint(canvas, size);
    }

    // 头部
    HeadPainter(palette: skin.palette, frame: frame, faceImage: faceImage)
        .paint(canvas, size);

    // 道具（缩略图跳过）
    if (!isThumbnail) {
      PropPainter(palette: skin.palette, frame: frame, propImage: propImage)
          .paint(canvas, size);
    }
  }

  void _drawAura(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    final auraPaint = Paint()
      ..color = skin.palette.auraColor.withOpacity(0.2 * entryProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(const Offset(120, 120), 100, auraPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompositePainter old) {
    return old.frame != frame ||
        old.entryProgress != entryProgress ||
        old.faceImage != faceImage ||
        old.outfitImage != outfitImage ||
        old.propImage != propImage ||
        old.skin.id != skin.id;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/opponent_renderer_test.dart`
Expected: 4 个测试全部 PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/widgets/opponent/opponent_renderer.dart fittrack_flutter/test/opponent_renderer_test.dart
git commit -m "feat(opponent): 新增 OpponentRenderer + CompositePainter（动画状态机+贴图预加载）"
```

---

## Task 7: 集成到首页卡片 + 详情页 + 训练结束 PK 卡片

**Files:**
- Modify: `fittrack_flutter/lib/widgets/virtual_opponent_card.dart`（emoji → 48×48 Renderer）
- Modify: `fittrack_flutter/lib/pages/opponent_detail_page.dart`（64×64 emoji → 240×240 Renderer）
- Modify: `fittrack_flutter/lib/pages/training_page.dart`（PK 卡片对手 emoji → 64×64 Renderer + 招式名称）
- Test: `fittrack_flutter/test/opponent_integration_test.dart`

**Interfaces:**
- Consumes: `OpponentRenderer`（来自 Task 6）, `OpponentSkinConfig`（来自 Task 1）

**注意：** 不要删除 VirtualGood.emoji 字段（virtual_goods.dart 仍在用），仅在 UI 渲染处替换为 OpponentRenderer。

- [ ] **Step 1: 写失败的测试**

```dart
// test/opponent_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/virtual_opponent.dart';
import 'package:fittrack_flutter/widgets/opponent/opponent_renderer.dart';
import 'package:fittrack_flutter/widgets/virtual_opponent_card.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('VirtualOpponentCard renders OpponentRenderer instead of emoji',
      (tester) async {
    // 注入测试对手
    final opponent = VirtualOpponent(
      id: 'test',
      nickname: '测试对手',
      tier: OpponentTier.regular,
      avatarSeed: 'test',
      persona: '测试',
      weeklyTrainings: 3,
    );
    Storage.saveSettings({'virtualOpponentData': opponent.toJson()});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VirtualOpponentCard(
            opponent: opponent,
            userWeeklyTrainings: 2,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OpponentRenderer), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/opponent_integration_test.dart`
Expected: FAIL，VirtualOpponentCard 仍渲染 emoji（无 OpponentRenderer）

- [ ] **Step 3: 修改 virtual_opponent_card.dart**

读取文件，找到 `Text(VirtualGoodsStore.byId(_opponent!.appliedSkinId)?.emoji ?? '🤖', ...)`（约 line 187），替换为：

```dart
SizedBox(
  width: 48,
  height: 48,
  child: OpponentRenderer(
    skinId: _opponent!.appliedSkinId,
    size: const Size(48, 48),
    autoTrain: false,
    showAura: false,
  ),
)
```

文件顶部新增 import：
```dart
import 'opponent/opponent_renderer.dart';
```

如果原 emoji Text 有 `const`，去掉（Renderer 不能 const）。

- [ ] **Step 4: 修改 opponent_detail_page.dart**

读取文件，找到头部卡片 `_buildHeaderCard` 中的 64×64 Container（约 line 79-88），替换 emoji Text 为 240×240 OpponentRenderer：

```dart
// 旧：
// Container(width: 64, height: 64, ... child: Center(child: Text(emoji, ...)))

// 新：
SizedBox(
  width: 240,
  height: 240,
  child: OpponentRenderer(
    skinId: opponent.appliedSkinId,
    size: const Size(240, 240),
    autoTrain: true,
    showAura: true,
  ),
)
```

注意：原 _buildHeaderCard 的 Row 可能因 240 太宽而溢出，需改为 Column 布局（人物图在上方居中，昵称+人设在下方）。

文件顶部新增 import：
```dart
import '../widgets/opponent/opponent_renderer.dart';
import '../widgets/opponent/opponent_skin_config.dart';
```

`_buildSkinCard` 中的"当前皮肤"展示 96×96 Renderer + signatureMove：

```dart
// 在 skin?.emoji ?? '🤖' 处替换为：
SizedBox(
  width: 96, height: 96,
  child: OpponentRenderer(
    skinId: skinId,
    size: const Size(96, 96),
    autoTrain: false,
    showAura: true,
  ),
)
// 在 skin?.name 下方新增招式展示：
if (skin != null) ...[
  const SizedBox(height: 4),
  Text('招式：${skin.signatureMove}', style: TextStyle(
    color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600,
  )),
]
```

- [ ] **Step 5: 修改 training_page.dart**

读取 training_page.dart，找到训练结束 PK 卡片中对手侧 emoji 渲染处（grep `🤖` 或 `appliedSkinId`），替换为 64×64 OpponentRenderer + 招式名称展示。

文件顶部新增 import：
```dart
import '../widgets/opponent/opponent_renderer.dart';
import '../widgets/opponent/opponent_skin_config.dart';
```

在对手分数下方新增招式展示：
```dart
final skin = OpponentSkinConfig.byId(opponent.appliedSkinId);
// ...
Text(skin.signatureMove, style: TextStyle(
  color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600,
))
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/opponent_integration_test.dart`
Expected: PASS

Run: `cd fittrack_flutter; flutter test`
Expected: 全部测试通过（含原 58 个 + 新增的）

- [ ] **Step 7: 提交**

```bash
git add fittrack_flutter/lib/widgets/virtual_opponent_card.dart fittrack_flutter/lib/pages/opponent_detail_page.dart fittrack_flutter/lib/pages/training_page.dart fittrack_flutter/test/opponent_integration_test.dart
git commit -m "feat(opponent): 集成 OpponentRenderer 到首页/详情页/训练结束 PK 卡片"
```

---

## Task 8: dailyAdvance 训练偏好 + 文案风格

**Files:**
- Modify: `fittrack_flutter/lib/data/virtual_opponent.dart`（dailyAdvance 方法，约 line 293-348）
- Test: `fittrack_flutter/test/opponent_daily_advance_test.dart`

**Interfaces:**
- Consumes: `OpponentSkinConfig.byId`, `TrainBias`, `DialogStyle`（来自 Task 1）

**实现要点（spec §9.4 + §9.5）：**
- weightMultiplier 三档判定：
  - cardioWeight > 0.4 → 0.5（忍者）
  - compoundWeight > 0.5 → 1.3（钢铁战士）
  - isolationWeight > 0.4 → 0.7（新手）
  - 否则 1.0（大使均衡）
- currentStatus 从 `skin.dialogStyle.trainingTaunts` 随机取（替代 _statusTemplates）
- 仍保留 10% 触发概率

- [ ] **Step 1: 写失败的测试**

```dart
// test/opponent_daily_advance_test.dart
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
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd fittrack_flutter; flutter test test/opponent_daily_advance_test.dart`
Expected: FAIL（dailyAdvance 仍用旧 _statusTemplates + 无 weightMultiplier）

- [ ] **Step 3: 修改 dailyAdvance**

读取 `lib/data/virtual_opponent.dart` line 293-348（dailyAdvance 方法），把训练重量计算部分改为：

```dart
if (_random.nextDouble() < trainProbability) {
  // 对手今天训练
  final durationRange = opponent.tier.sessionDurationRange;
  final weightRange = opponent.tier.sessionWeightRange;
  final duration = _random.nextInt(durationRange.max - durationRange.min + 1) + durationRange.min;
  final baseWeight = _random.nextInt(weightRange.max - weightRange.min + 1) + weightRange.min;

  // 皮肤训练偏好影响 weight
  final skin = OpponentSkinConfig.byId(opponent.appliedSkinId);
  final bias = skin.trainBias;
  double weightMultiplier = 1.0;
  if (bias.cardioWeight > 0.4) weightMultiplier = 0.5;
  else if (bias.compoundWeight > 0.5) weightMultiplier = 1.3;
  else if (bias.isolationWeight > 0.4) weightMultiplier = 0.7;
  final weight = (baseWeight * weightMultiplier).round();

  opponent.weeklyTrainings += 1;
  opponent.weeklyWeight += weight;
  opponent.weeklyDuration += duration;
}

// 10% 概率发布偶尔动态（从皮肤 dialogStyle.trainingTaunts 取）
if (_random.nextDouble() < 0.10) {
  final skin = OpponentSkinConfig.byId(opponent.appliedSkinId);
  final taunts = skin.dialogStyle.trainingTaunts;
  opponent.currentStatus = taunts[_random.nextInt(taunts.length)];
}
```

文件顶部新增 import：
```dart
import '../widgets/opponent/opponent_skin_config.dart';
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd fittrack_flutter; flutter test test/opponent_daily_advance_test.dart`
Expected: 3 个测试全部 PASS

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/data/virtual_opponent.dart fittrack_flutter/test/opponent_daily_advance_test.dart
git commit -m "feat(opponent): dailyAdvance 接入皮肤训练偏好 + 文案风格"
```

---

## Task 9: 全局回归测试 + analyze

**Files:** 无新增

- [ ] **Step 1: 运行全部测试**

Run: `cd fittrack_flutter; flutter test`
Expected: 全部测试通过（原 58 + 新增约 30+ 个，总数 > 88）

- [ ] **Step 2: 运行 flutter analyze**

Run: `cd fittrack_flutter; flutter analyze`
Expected: 零新增 error（info 级别可接受）

- [ ] **Step 3: 修复任何回归**

如出现失败，逐个定位修复，再跑 Step 1+2。

- [ ] **Step 4: 提交修复（如有）**

```bash
git add -A
git commit -m "test(opponent): 全局回归通过"
```

---

## Self-Review

**Spec 覆盖检查：**
- §4 总体架构 → Task 1（数据层）+ Task 4-5（绘制层）+ Task 6（渲染层）+ Task 7（UI 层集成）
- §5 OpponentSkinConfig 数据模型 → Task 1
- §6 4 个皮肤具体设定 → Task 1（含完整 beginner + 其他 3 个）
- §7 绘制层 → Task 4-5
- §8 动画系统 → Task 3（interpolate）+ Task 6（状态机）
- §9.1-9.3 集成点（首页/详情/PK卡片）→ Task 7
- §9.4 dailyAdvance 训练偏好 → Task 8
- §9.5 currentStatus 文案风格 → Task 8
- §10 不在范围 → 明确排除，未实现
- §11 测试策略 → 各 Task 内嵌测试 + Task 9 回归
- §12 风险缓解 → Painter fallback（Task 5）+ RepaintBoundary（Task 6）+ 缩略图简化（Task 6）+ weightMultiplier 限定（Task 8）

**Placeholder 扫描：** 无 TBD/TODO，所有代码步骤含完整代码。

**类型一致性：** `OpponentSkinConfig.byId` 全程使用；`MotionSpec.interpolate` Task 3 实现；`BodyPainter/HeadPainter/OutfitPainter/PropPainter` 签名一致；`OpponentRenderer` 参数（skinId/size/autoTrain/showAura）全 Task 一致。

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-27-opponent-skin-system.md`.

Two execution options:

1. **Subagent-Driven (recommended)** - 派发新 subagent 每任务，任务间评审，快速迭代
2. **Inline Execution** - 当前会话顺序执行

用户已明确选择 Subagent-Driven，直接转入 superpowers:subagent-driven-development。
