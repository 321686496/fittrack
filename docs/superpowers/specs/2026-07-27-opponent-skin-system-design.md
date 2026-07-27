# 对手皮肤系统 P1 重构设计

- **作者**：AI 协作
- **日期**：2026-07-27
- **状态**：Approved（用户已授权直接执行）
- **覆盖**：将"换 emoji"的简陋皮肤系统升级为"完整人物形象 + 完整动作动画 + 全维度差异化"

---

## 1. 背景

当前皮肤实现（[virtual_goods.dart](file:///d:/app/projects/health_training/fittrack_flutter/lib/data/virtual_goods.dart)）只把对手 emoji 从 🤖 换成 🐣/🥷/👑，4 档价格 100/300/600/1200 积分但视觉差异几乎为零。全代码库仅 2 处消费（首页卡片标题前 emoji + 详情页头像 emoji），用户付费购买毫无价值感。

## 2. 设计目标

- 让 4 档皮肤具备**显著可感知差异**：视觉（人物形象/动作/配色）+ 文案（动态话术风格）+ 训练偏好（影响 dailyAdvance）+ 招式名称（PK 卡片展示）
- 工程可扩展：新增皮肤通过配置数据驱动，不改核心类
- 与现有 app 的 Morandi 圆润设计语言一致

## 3. 用户决策摘要

| 维度 | 选择 |
|---|---|
| 人物风格 | Q 版萌系（头身比 1:2） |
| 资源方式 | 代码 + 贴图混合（CustomPainter 绘制身体轮廓 + PNG 贴图面部/服饰/道具） |
| 动画等级 | 完整动作动画（入场 + 待机 + 训练动作循环） |
| 差异化维度 | 全维度（视觉+文案+训练偏好+招式） |
| 皮肤数量 | 4 个（沿用现有 skin_beginner/iron_warrior/cyber_ninja/ambassador） |

## 4. 总体架构

### 4.1 分层

```
┌─────────────────────────────────────────────────────────────┐
│  UI 层（widget）                                             │
│  ┌──────────────────────┐ ┌────────────────────────────────┐│
│  │ OpponentFigureWidget │ │ OpponentCardWidget (改造)      ││
│  │（详情页 240×240 大图）│ │（首页/结束页 48×48 缩略图）     ││
│  └──────────┬───────────┘ └─────────────┬──────────────────┘│
│             └─────────────┬─────────────┘                   │
│                           ▼                                  │
│  渲染层                                                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ OpponentRenderer (StatefulWidget)                       ││
│  │  - 持有 AnimationController（idle / training 状态机）    ││
│  │  - 入场 Spring 动画                                      ││
│  │  - 调用各部件 Painter + 贴图合成                          ││
│  └─────────────────────────────────────────────────────────┘│
│                           ▼                                  │
│  绘制层（CustomPainter）                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐ │
│  │ Body     │ │ Head     │ │ Outfit   │ │ Prop           │ │
│  │ Painter  │ │ Painter  │ │ Painter  │ │ Painter        │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────────────┘ │
│                           ▲                                  │
│  数据层                                                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ OpponentSkinConfig（每个皮肤一份配置）                   ││
│  │  - palette / trainBias                                  ││
│  │  - faceAsset / outfitAsset / propAsset                  ││
│  │  - idleMotion / trainingMotion                          ││
│  │  - dialogStyle / signatureMove                          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 4.2 文件结构

```
lib/widgets/opponent/
├── opponent_figure_widget.dart       # 详情页大图入口
├── opponent_renderer.dart            # 渲染状态机（动画驱动）
├── opponent_skin_config.dart         # OpponentSkinConfig 数据类 + 4 份配置
├── painters/
│   ├── body_painter.dart             # 身体轮廓（CustomPainter）
│   ├── head_painter.dart             # 头部+面部（CustomPainter，可贴图替换）
│   ├── outfit_painter.dart           # 服饰装饰（CustomPainter，可贴图替换）
│   └── prop_painter.dart             # 道具（哑铃/剑/光剑/权杖）
└── motion/
    ├── motion_spec.dart              # 动作帧定义（关键帧 + 缓动）
    └── motion_player.dart            # 帧插值器（驱动各部件 transform）
```

## 5. 数据模型：OpponentSkinConfig

新建 `lib/widgets/opponent/opponent_skin_config.dart`：

```dart
import 'dart:ui';

/// 皮肤配色方案
class SkinPalette {
  final Color primary;       // 主色（服饰/装饰主色）
  final Color secondary;     // 副色（阴影/纹样）
  final Color accent;        // 点缀色（高光/光晕）
  final Color skinTone;      // 肤色
  final Color auraColor;     // 头像光圈色（与 primary 区分，体现"能量"）
  const SkinPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.skinTone,
    required this.auraColor,
  });
}

/// 训练偏好（影响 dailyAdvance）
class TrainBias {
  /// 训练类型权重：复合动作 / 孤立动作 / 有氧 / 核心
  /// 4 个权重之和无需归一，引擎内部归一化
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

/// 单个训练动作的关键帧描述
class MotionFrame {
  final double t;                    // 0.0 - 1.0 时间点
  final Offset bodyOffset;           // 身体相对偏移
  final double armAngle;             // 手臂摆角（度）
  final double legBend;              // 腿部弯曲度（0-1）
  final double headTilt;             // 头部倾斜（度）
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
  final List<MotionFrame> frames;    // 关键帧序列（首尾相接循环）
  final Duration duration;           // 单循环时长
  final Curve curve;                 // 帧间缓动
  const MotionSpec({
    required this.frames,
    required this.duration,
    this.curve = Curves.easeInOut,
  });

  /// 按 progress (0-1) 插值出当前帧参数
  MotionFrame interpolate(double progress) {
    // 实现见 motion_player.dart
    throw UnimplementedError();
  }
}

/// 皮肤完整配置
class OpponentSkinConfig {
  final String id;
  final String name;
  final String pointsCost;          // "100 积分" 或 "邀请5人解锁"
  final bool isLimited;
  final SkinPalette palette;
  final TrainBias trainBias;

  /// 贴图资源路径（null 表示用 Painter 纯代码绘制）
  final String? faceAsset;          // 如 'assets/opponent/face_cyber.png'
  final String? outfitAsset;
  final String? propAsset;

  /// 动作规范
  final MotionSpec idleMotion;      // 待机（呼吸+眨眼+轻微摇摆）
  final MotionSpec trainingMotion;  // 训练（举哑铃/挥剑/深蹲循环）

  /// 文案风格
  final DialogStyle dialogStyle;    // 动态话术模板

  /// 招式名称（PK 卡片展示）
  final String signatureMove;       // 如 "闪影拳"

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
    return kAllSkins.first; // fallback 到入门款
  }

  static const List<OpponentSkinConfig> kAllSkins = [
    skinBeginner,
    skinIronWarrior,
    skinCyberNinja,
    skinAmbassador,
  ];

  // ── 4 个皮肤配置见 §6，此处仅展示 beginner 完整示例 ──
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
        MotionFrame(t: 0.5, bodyOffset: Offset(0, -2)),    // 呼吸起伏
        MotionFrame(t: 1.0, bodyOffset: Offset(0, 0)),
      ],
      duration: Duration(milliseconds: 2400),
    ),
    trainingMotion: MotionSpec(
      frames: [
        MotionFrame(t: 0.0, armAngle: -20),                // 二头弯举下
        MotionFrame(t: 0.5, armAngle: 20),                 // 二头弯举上
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
  // skinIronWarrior / skinCyberNinja / skinAmbassador 按 §6 表格配置，结构同上
  static const skinIronWarrior = OpponentSkinConfig(/* 见 §6.2 */);
  static const skinCyberNinja = OpponentSkinConfig(/* 见 §6.3 */);
  static const skinAmbassador = OpponentSkinConfig(/* 见 §6.4 */);
}

/// 文案风格（动态话术模板池）
class DialogStyle {
  final List<String> greetings;       // 打招呼
  final List<String> trainingTaunts;  // 训练挑衅
  final List<String> winQuotes;       // 胜利台词
  final List<String> loseQuotes;      // 失败台词
  const DialogStyle({
    required this.greetings,
    required this.trainingTaunts,
    required this.winQuotes,
    required this.loseQuotes,
  });
}
```

## 6. 4 个皮肤的具体设定

### 6.1 skin_beginner（健身小白）

| 字段 | 值 |
|---|---|
| 价格 | 100 积分 |
| 定位 | 入门款，新用户首购 |
| 配色 | 浅橙系（#FFB87A primary / #FFE3C2 secondary / #FF6B35 accent），健康温暖 |
| 肤色 | #FDE3C7（白皙） |
| 光圈色 | 暖橙色（#FF8C5A） |
| 服饰 | 浅灰短袖 + 蓝色运动裤（贴图：outfit_beginner.png） |
| 道具 | 小哑铃（2kg，prop_beginner.png） |
| 待机动作 | 呼吸起伏（身体 1.5% 缩放）+ 8 秒眨眼一次 |
| 训练动作 | 二头弯举循环（双臂同步上下摆动 ±20°），8 帧循环 1.2s |
| 训练偏好 | compound: 0.3 / isolation: 0.5 / cardio: 0.1 / core: 0.1（孤立动作偏多，新手爱练手臂） |
| 招式 | "活力弯举" |
| 文案风格 | 鼓励型："今天也要加油哦！" / "跟着我一起学动作吧" |

### 6.2 skin_iron_warrior（钢铁战士）

| 字段 | 值 |
|---|---|
| 价格 | 300 积分 |
| 定位 | 标准款，力量派用户首选 |
| 配色 | 深红+金属灰（#9B2C2C primary / #4A5568 secondary / #F56565 accent），硬核力量感 |
| 肤色 | #E8B894（小麦） |
| 光圈色 | 火红色（#FF4E50） |
| 服饰 | 黑色无袖背心 + 战术腰带（贴图：outfit_iron.png） |
| 道具 | 20kg 大杠铃（prop_iron.png） |
| 待机动作 | 呼吸 + 双臂抱胸微晃（小幅 ±5°） |
| 训练动作 | 杠铃深蹲循环（下蹲 + 起立，膝盖弯曲 0→0.6→0），10 帧循环 1.6s |
| 训练偏好 | compound: 0.6 / isolation: 0.2 / cardio: 0.1 / core: 0.1（复合动作至上） |
| 招式 | "裂地深蹲" |
| 文案风格 | 力量派："今天也要炸裂重量！" / "复合动作才是王道" |

### 6.3 skin_cyber_ninja（赛博忍者）

| 字段 | 值 |
|---|---|
| 价格 | 600 积分 |
| 定位 | 精品款，敏捷派用户首选 |
| 配色 | 紫青双色霓虹（#9B5DE5 primary / #00F5FF secondary / #F15BB5 accent），赛博朋克 |
| 肤色 | #F5DEB3（浅黄） |
| 光圈色 | 霓虹紫（#9B5DE5） |
| 服饰 | 黑色忍者面罩 + 紧身作战服 + 紫色光带（贴图：outfit_ninja.png） |
| 道具 | 双光剑（紫色光刃，prop_ninja.png） |
| 待机动作 | 呼吸 + 头部左右环视（±10° 倾斜），快速眨眼 |
| 训练动作 | 光剑挥砍循环（左砍 + 右砍 + 旋转斩），12 帧循环 1.4s |
| 训练偏好 | compound: 0.2 / isolation: 0.2 / cardio: 0.5 / core: 0.1（有氧偏多，忍者敏捷） |
| 招式 | "闪影连斩" |
| 文案风格 | 神秘型："敏捷训练上线" / "我的速度你跟不上" |

### 6.4 skin_ambassador（燃力大使，限定款）

| 字段 | 值 |
|---|---|
| 价格 | 1200 积分（仅邀请 5 人解锁） |
| 定位 | 典藏款，社交贡献者的勋章 |
| 配色 | 黑金奢华（#1A1A1A primary / #FFD700 secondary / #FFA500 accent），尊贵 |
| 肤色 | #FDE3C7（白皙） |
| 光圈色 | 金色（#FFD700，带光晕脉动） |
| 服饰 | 黑色金线礼服 + 金色披风（贴图：outfit_ambassador.png） |
| 道具 | 金色权杖（顶端钻石，prop_ambassador.png） |
| 待机动作 | 呼吸 + 披风飘动（用正弦波模拟）+ 金色光晕脉动 |
| 训练动作 | 权杖挥舞循环（高举 + 旋转 + 落下），10 帧循环 1.8s |
| 训练偏好 | compound: 0.4 / isolation: 0.3 / cardio: 0.2 / core: 0.1（均衡） |
| 招式 | "王者裁决" |
| 文案风格 | 王者型："以身作则，引领大家" / "感谢你的邀请，让我来到这里" |

## 7. 绘制层设计

### 7.1 BodyPainter

绘制 Q 版身体轮廓（头身比 1:2，身体椭圆 + 头部圆形），按 MotionFrame 应用 transform：

```dart
class BodyPainter extends CustomPainter {
  final SkinPalette palette;
  final MotionFrame frame;
  final String? outfitAsset; // null 时纯代码绘制

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 平移 + 缩放（呼吸）
    canvas.save();
    canvas.translate(0, frame.bodyOffset.dy);
    // 2. 绘制身体椭圆（240×240 画布，身体中心 (120, 160)）
    final bodyPaint = Paint()..color = palette.skinTone;
    canvas.drawOval(Rect.fromCenter(center: Offset(120, 160), width: 80, height: 100), bodyPaint);
    // 3. 绘制四肢（按 armAngle/legBend 旋转）
    _drawArms(canvas, frame.armAngle);
    _drawLegs(canvas, frame.legBend);
    canvas.restore();
  }
}
```

### 7.2 HeadPainter

绘制头部 + 面部贴图。faceAsset != null 时用 Image.asset 贴图替代手绘五官。

### 7.3 OutfitPainter / PropPainter

服饰与道具，支持贴图或纯代码绘制。

### 7.4 贴图资源清单

需 AI 生成 12 张 PNG（透明背景，512×512）：

```
assets/opponent/
├── face_beginner.png       # 浅橙系萌系面部
├── face_iron.png           # 钢铁战士面部（带护额）
├── face_ninja.png          # 忍者面罩
├── face_ambassador.png     # 金色王冠面部
├── outfit_beginner.png     # 浅灰短袖
├── outfit_iron.png         # 黑色无袖背心
├── outfit_ninja.png        # 紧身作战服
├── outfit_ambassador.png   # 黑色金线礼服
├── prop_beginner.png       # 小哑铃
├── prop_iron.png           # 大杠铃
├── prop_ninja.png          # 双光剑
└── prop_ambassador.png     # 金色权杖
```

**贴图生成策略**（在实施时由 AI 调用 imagegen 工具生成）：
- 统一画布 512×512，透明背景
- 中心对齐，预留 20% 边距
- 风格：Q 版萌系，圆润线条，柔和阴影
- 色板：按 §6 各皮肤的 palette 严格执行

## 8. 动画系统

### 8.1 状态机

```
[入场] ──spring──> [待机] ──用户触发训练──> [训练循环]
                       ^                          │
                       └────松开触发──────────────┘
```

### 8.2 OpponentRenderer

```dart
class OpponentRenderer extends StatefulWidget {
  final String skinId;
  final Size size;                  // 大图 240×240 / 缩略图 48×48
  final bool autoTrain;             // 是否自动循环训练动作（详情页 true）
  final bool showAura;              // 是否显示光圈（详情页 true）
  const OpponentRenderer({...});
  @override State<OpponentRenderer> createState() => _OpponentRendererState();
}

class _OpponentRendererState extends State<OpponentRenderer>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _trainController;
  late AnimationController _entryController;
  bool _isTraining = false;

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
  }

  void _startTraining() {
    setState(() => _isTraining = true);
    _trainController.repeat();
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
        // 入场 spring：从下方 60px 弹入
        final entryOffset = (1 - Curves.elasticOut.transform(_entryController.value)) * 60;
        return Transform.translate(
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
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### 8.3 CompositePainter

聚合 4 个子 Painter + 3 个贴图，统一绘制：

```dart
class CompositePainter extends CustomPainter {
  final OpponentSkinConfig skin;
  final MotionFrame frame;
  final bool showAura;
  final double entryProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 光圈（仅详情页显示，按 entryProgress 渐入）
    if (showAura) _drawAura(canvas, size);
    // 2. 身体（应用 frame transform）
    BodyPainter(palette: skin.palette, frame: frame).paint(canvas, size);
    // 3. 服饰
    OutfitPainter(palette: skin.palette, asset: skin.outfitAsset, frame: frame).paint(canvas, size);
    // 4. 头部 + 面部贴图
    HeadPainter(palette: skin.palette, asset: skin.faceAsset, frame: frame).paint(canvas, size);
    // 5. 道具
    PropPainter(palette: skin.palette, asset: skin.propAsset, frame: frame).paint(canvas, size);
  }
}
```

### 8.4 MotionSpec.interpolate

```dart
MotionFrame interpolate(double progress) {
  if (frames.length < 2) return frames.first;
  final scaled = (progress * frames.length) % frames.length;
  final idx = scaled.floor();
  final next = (idx + 1) % frames.length;
  final t = scaled - idx;
  final eased = curve.transform(t);
  final a = frames[idx], b = frames[next];
  return MotionFrame(
    t: progress,
    bodyOffset: Offset.lerp(a.bodyOffset, b.bodyOffset, eased)!,
    armAngle: lerpDouble(a.armAngle, b.armAngle, eased)!,
    legBend: lerpDouble(a.legBend, b.legBend, eased)!,
    headTilt: lerpDouble(a.headTilt, b.headTilt, eased)!,
  );
}
```

## 9. 集成点

### 9.1 改造 virtual_opponent_card.dart

首页卡片标题前的 emoji 替换为 48×48 OpponentRenderer：

```dart
// 旧：
Text(VirtualGoodsStore.byId(_opponent!.appliedSkinId)?.emoji ?? '🤖', style: TextStyle(fontSize: 18))

// 新：
SizedBox(
  width: 48, height: 48,
  child: OpponentRenderer(
    skinId: _opponent!.appliedSkinId,
    size: const Size(48, 48),
    autoTrain: false,
    showAura: false,
  ),
)
```

### 9.2 改造 opponent_detail_page.dart

详情页头部 64×64 emoji 替换为 240×240 大图：

```dart
// 旧：Container(width: 64, height: 64, child: Text(emoji, ...))
// 新：
SizedBox(
  width: 240, height: 240,
  child: OpponentRenderer(
    skinId: opponent.appliedSkinId,
    size: const Size(240, 240),
    autoTrain: true,
    showAura: true,
  ),
)
```

详情页皮肤卡片的"当前皮肤"区域展示 96×96 渲染图 + 招式名称。

### 9.3 改造 training_page.dart（训练结束 PK 卡片）

PK 卡片中对手侧 emoji 替换为 64×64 渲染图，并展示招式名称：

```dart
// 在对手分数下方新增招式展示
Text(skin.signatureMove, style: TextStyle(color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600))
```

### 9.4 改造 virtual_opponent.dart（dailyAdvance 训练偏好）

```dart
void dailyAdvance() {
  // ...现有逻辑
  if (_random.nextDouble() < trainProbability) {
    final skin = OpponentSkinConfig.byId(opponent.appliedSkinId);
    final bias = skin.trainBias;
    // 训练偏好影响 weight 范围（有氧 → 重量减半，复合 → 重量增加）
    final baseWeight = _random.nextInt(weightRange.max - weightRange.min + 1) + weightRange.min;
    double weightMultiplier = 1.0;
    if (bias.cardioWeight > 0.4) weightMultiplier = 0.5;        // 忍者：有氧偏多
    else if (bias.compoundWeight > 0.5) weightMultiplier = 1.3; // 钢铁战士：复合动作偏多
    else if (bias.isolationWeight > 0.4) weightMultiplier = 0.7; // 新手：孤立动作重量较小
    final weight = (baseWeight * weightMultiplier).round();
    // ...
  }
}
```

### 9.5 改造 currentStatus 文案

```dart
// dailyAdvance 中发布动态时，从皮肤 DialogStyle 取
if (_random.nextDouble() < 0.10) {
  final skin = OpponentSkinConfig.byId(opponent.appliedSkinId);
  final taunts = skin.dialogStyle.trainingTaunts;
  opponent.currentStatus = taunts[_random.nextInt(taunts.length)];
}
```

## 10. 不在范围（明确排除）

- 用户自己的形象（仅影响对手）
- 皮肤切换动画过渡（切换瞬间直接换）
- 皮肤商店独立页（本次仅完善渲染，商店页下版本）
- 皮肤音效（不同皮肤不同音效）
- 皮肤等级/熟练度（解锁即可用，无升级系统）
- 新增皮肤（仍保持 4 个）

## 11. 测试策略

### 11.1 单元测试

- `OpponentSkinConfig.byId` 4 个已知 id + 1 个未知 id fallback
- `MotionSpec.interpolate` 边界值（progress=0/0.5/1）+ 帧间插值正确性
- `TrainBias` 归一化逻辑
- `dailyAdvance` 训练偏好影响 weight 范围（cyber_ninja 应减半，iron_warrior 应 1.3 倍）
- `dailyAdvance` 动态文案从皮肤 DialogStyle 取（每个皮肤至少 1 次命中）

### 11.2 Widget 测试

- `OpponentRenderer` 大图渲染（240×240）+ 缩略图渲染（48×48）不抛异常
- 入场动画完成后 widget 仍存在
- autoTrain=true 时 2 秒后 _isTraining 为 true

### 11.3 集成测试

- `opponent_detail_page.dart` 加载时 OpponentRenderer 渲染正确（用 golden test 或 widget count 验证）
- 首页卡片渲染 OpponentRenderer（不抛异常）

### 11.4 回归测试

- `flutter analyze` 零新增 error
- 现有 58 个测试仍全部通过
- `flutter test` 新增约 8-12 个测试用例

## 12. 风险与缓解

| 风险 | 缓解 |
|---|---|
| CustomPainter 代码量大，单文件膨胀 | 拆 4 个子 Painter，每个文件 < 200 行 |
| 贴图资源缺失导致渲染失败 | Painter 内部 fallback：贴图加载失败时用纯代码绘制 |
| 动画卡顿（每帧 4 个 Painter + 3 张贴图） | 缩略图禁用光圈 + 简化绘制（48×48 仅绘身体轮廓）；大图用 RepaintBoundary 隔离 |
| MotionSpec.interpolate 实现错误导致动作诡异 | 单元测试覆盖边界值 |
| 12 张贴图风格不一致 | 用统一 prompt 模板生成，仅替换配色与道具 |
| dailyAdvance 训练偏好导致数据漂移 | weightMultiplier 限定在 [0.5, 1.3]，避免极端值 |

## 13. 验收标准

- [ ] `flutter analyze` 零新增 error
- [ ] 新增约 8-12 个测试用例全部通过
- [ ] 现有 58 个测试仍全部通过
- [ ] 首页对手卡片渲染 48×48 OpponentRenderer（替代 emoji）
- [ ] 对手详情页渲染 240×240 OpponentRenderer（带光圈 + 入场动画 + 自动训练循环）
- [ ] 训练结束 PK 卡片显示 64×64 渲染图 + 招式名称
- [ ] dailyAdvance 训练偏好生效：cyber_ninja weight 减半，iron_warrior weight ×1.3
- [ ] dailyAdvance 动态文案从皮肤 DialogStyle 取
- [ ] 4 个皮肤视觉差异显著（不同配色 + 不同服饰 + 不同道具 + 不同动作）
- [ ] 切换皮肤后渲染即时更新（无残留）
