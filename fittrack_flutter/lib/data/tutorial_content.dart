import 'package:flutter/material.dart';
import 'content_block.dart';
import 'course_content.dart'; // 复用 Chapter 类
import '../services/points_service.dart';

/// v1 教学信息系统 —— 数据模型与基础内容
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2
/// 内容结构：
/// - 基础教学（免费）：50个基础动作·图文要点
/// - 进阶教学（裂变解锁）：每邀请1人激活→解锁3个进阶动作
/// - 专题教学包（裂变里程碑）：累计邀请3人→"卧推完全指南"
/// - 高手教学（裂变里程碑）：累计邀请5人→"渐进超负荷实操"

/// 教学难度等级
enum TutorialDifficulty {
  beginner, // 入门
  intermediate, // 进阶
  advanced, // 高手
}

extension TutorialDifficultyExt on TutorialDifficulty {
  String get label {
    switch (this) {
      case TutorialDifficulty.beginner:
        return '入门';
      case TutorialDifficulty.intermediate:
        return '进阶';
      case TutorialDifficulty.advanced:
        return '高手';
    }
  }
}

/// 目标肌群
enum MuscleGroup {
  chest, // 胸
  back, // 背
  leg, // 腿
  shoulder, // 肩
  arm, // 手臂
  core, // 核心
}

extension MuscleGroupExt on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return '胸部';
      case MuscleGroup.back:
        return '背部';
      case MuscleGroup.leg:
        return '腿部';
      case MuscleGroup.shoulder:
        return '肩部';
      case MuscleGroup.arm:
        return '手臂';
      case MuscleGroup.core:
        return '核心';
    }
  }
}

/// 教学内容类型
enum TutorialType {
  basic, // 基础教学（免费）
  advanced, // 进阶教学（裂变解锁）
  topic, // 专题教学包（裂变里程碑）
  master, // 高手教学（裂变里程碑）
}

extension TutorialTypeExt on TutorialType {
  String get label {
    switch (this) {
      case TutorialType.basic:
        return '基础';
      case TutorialType.advanced:
        return '进阶';
      case TutorialType.topic:
        return '专题';
      case TutorialType.master:
        return '高手';
    }
  }

  /// 该类型是否需要裂变解锁
  bool get requiresUnlock {
    switch (this) {
      case TutorialType.basic:
        return false;
      case TutorialType.advanced:
      case TutorialType.topic:
      case TutorialType.master:
        return true;
    }
  }
}

/// 训练目标分类
enum FitnessGoal { bulk, cut, maintain }
extension FitnessGoalExt on FitnessGoal {
  String get label {
    switch (this) {
      case FitnessGoal.bulk: return '增肌';
      case FitnessGoal.cut: return '减脂';
      case FitnessGoal.maintain: return '保持';
    }
  }
}

/// 教学内容类型
enum ContentType { exercise, warmUp, coolDown, diet, plan }
extension ContentTypeExt on ContentType {
  String get label {
    switch (this) {
      case ContentType.exercise: return '动作教学';
      case ContentType.warmUp: return '热身';
      case ContentType.coolDown: return '拉伸';
      case ContentType.diet: return '饮食';
      case ContentType.plan: return '计划';
    }
  }
}

/// 教学内容数据模型
class Tutorial {
  final String id;
  final String name; // 动作名称
  final TutorialType type;
  final TutorialDifficulty difficulty;
  final MuscleGroup primaryMuscle;
  final String? equipment; // 器械（杠铃/哑铃/绳索等）
  final String? avatarAsset; // 动图/图示资源路径

  /// 图文要点（4-6 条核心要领）
  final List<String> keyPoints;

  /// 常见错误（3-5 条，warningColor 标识）
  final List<String> commonMistakes;

  /// 替代动作（动作 id 列表，用于跳转）
  final List<String> alternativeExerciseIds;

  /// 虚拟教练署名
  final String coachName;

  /// 呼吸方法
  final String? breathingTip;

  /// 解锁条件描述（仅 type != basic 时有意义）
  final String? unlockRequirement;

  final FitnessGoal goal;
  final ContentType contentType;
  final List<Color> coverColors; // 封面渐变双色
  final List<String> recommendedExerciseIds; // 推荐动作ID列表（跳转动作库）
  final String? coverEmoji; // 封面Emoji图标
  final List<ContentBlock> blocks; // 富文本块（预留字段，当前未使用）

  const Tutorial({
    required this.id,
    required this.name,
    required this.type,
    required this.difficulty,
    required this.primaryMuscle,
    this.equipment,
    this.avatarAsset,
    required this.keyPoints,
    required this.commonMistakes,
    this.alternativeExerciseIds = const [],
    required this.coachName,
    this.breathingTip,
    this.unlockRequirement,
    this.goal = FitnessGoal.bulk,
    this.contentType = ContentType.exercise,
    this.coverColors = const [Color(0xFFFF6B35), Color(0xFFFFD700)],
    this.recommendedExerciseIds = const [],
    this.coverEmoji,
    this.blocks = const [],
  });

  /// 章节列表（getter，运行时由 TutorialLibrary.chaptersFor 生成）
  /// 章节内容来自现有 keyPoints/commonMistakes/breathingTip 字段
  List<Chapter> get chapters => TutorialLibrary.chaptersFor(this);

  /// 按章节积分解锁价格（basic=0，advanced=50，topic=80，master=120）
  int get chapterPointsCost {
    switch (type) {
      case TutorialType.basic:
        return 0;
      case TutorialType.advanced:
        return 50;
      case TutorialType.topic:
        return 80;
      case TutorialType.master:
        return 120;
    }
  }

  /// 单章 featureId
  String chapterFeatureId(String chapterId) {
    return 'tutorial_${id}_chapter_$chapterId';
  }

  /// 整套 featureId
  String get allChaptersFeatureId => 'tutorial_${id}_all';

  /// 章节是否已解锁
  bool isChapterUnlocked(String chapterId) {
    if (type == TutorialType.basic) return true;
    // 整套已解锁 → 所有章节免费
    if (PointsService.instance.isFeatureUnlocked(allChaptersFeatureId)) return true;
    return PointsService.instance.isFeatureUnlocked(chapterFeatureId(chapterId));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'difficulty': difficulty.name,
        'primaryMuscle': primaryMuscle.name,
        'equipment': equipment,
        'avatarAsset': avatarAsset,
        'keyPoints': keyPoints,
        'commonMistakes': commonMistakes,
        'alternativeExerciseIds': alternativeExerciseIds,
        'coachName': coachName,
        'breathingTip': breathingTip,
        'unlockRequirement': unlockRequirement,
        'goal': goal.name,
        'contentType': contentType.name,
        'coverColors': coverColors.map((c) => c.value).toList(),
        'recommendedExerciseIds': recommendedExerciseIds,
        'coverEmoji': coverEmoji,
        'blocks': blocks.map((b) => {'type': b.type.name, 'text': b.text}).toList(),
      };
}

/// 教学内容库（基础 30 动作 + 进阶 + 专题）
///
/// v1.2 调优：基础教学 30 个（每肌群 5 个），进阶 3 个，专题 1 个，高手 1 个
/// 后续完整版本可扩展到 50+ 基础 + N 个进阶 + 5+ 专题
class TutorialLibrary {
  TutorialLibrary._();

  /// 虚拟教练署名（统一品牌）
  static const String defaultCoach = '教练·凯文';

  /// 把现有 Tutorial 字段转换为 3 章节
  /// 第1章：动作要领（keyPoints）
  /// 第2章：常见错误（commonMistakes）
  /// 第3章：呼吸与变式（breathingTip + alternatives）
  static List<Chapter> chaptersFor(Tutorial t) {
    return [
      Chapter(
        id: 'keypoints',
        title: '动作要领',
        content: t.keyPoints.join('\n'),
        blocks: t.keyPoints.map((p) => ContentBlock.bulletList(p)).toList(),
      ),
      Chapter(
        id: 'mistakes',
        title: '常见错误',
        content: t.commonMistakes.join('\n'),
        blocks: t.commonMistakes.map((p) => ContentBlock.callout(p, 'warning')).toList(),
      ),
      Chapter(
        id: 'breathing',
        title: '呼吸与变式',
        content: t.breathingTip ?? '保持自然呼吸，发力时呼气，还原时吸气',
        blocks: [
          if (t.breathingTip != null)
            ContentBlock.paragraph(t.breathingTip!),
        ],
      ),
    ];
  }

  /// 所有教学合集
  static List<Tutorial> get allTutorials => [
    ...basicTutorials,
    ...advancedTutorials,
    ...topicTutorials,
    ...masterTutorials,
  ];

  /// 基础教学（免费开放，覆盖全肌群）
  static const List<Tutorial> basicTutorials = [
    Tutorial(
      id: 'tut_basic_bench_press',
      name: '杠铃卧推',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.chest,
      equipment: '杠铃',
      keyPoints: [
        '仰卧于卧推凳，双眼位于杠铃正下方',
        '肩胛骨后缩下沉，挺胸收腹，臀部紧贴凳面',
        '双手握距略宽于肩，全握杠铃（拇指环绕）',
        '下放至胸口轻触，肘部约45度外展',
        '推起时呼气，杠铃轨迹垂直向上',
      ],
      commonMistakes: [
        '臀部离开凳面借力',
        '手腕弯曲未保持中立位',
        '下放速度过快失去控制',
        '双脚悬空无支撑',
      ],
      alternativeExerciseIds: ['tut_basic_dumbbell_fly', 'tut_basic_incline_press'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，推起呼气',
    ),
    Tutorial(
      id: 'tut_basic_dumbbell_fly',
      name: '哑铃飞鸟',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.chest,
      equipment: '哑铃',
      keyPoints: [
        '仰卧凳上，双手持哑铃于胸口上方',
        '手肘微曲约20-30度，固定角度',
        '双臂弧形展开至与肩平齐',
        '感受胸大肌拉伸感',
        '原路径返回，专注于胸肌收缩',
      ],
      commonMistakes: [
        '手肘角度变化（变成推举）',
        '重量过大导致肩关节代偿',
        '下放过快无控制',
      ],
      alternativeExerciseIds: ['tut_basic_bench_press'],
      coachName: defaultCoach,
      breathingTip: '展开吸气，合拢呼气',
    ),
    Tutorial(
      id: 'tut_basic_incline_press',
      name: '上斜卧推',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      equipment: '杠铃/哑铃',
      keyPoints: [
        '调整凳面倾斜角至30-45度',
        '握距与平板卧推一致',
        '下放至上胸锁骨下方',
        '推起时杠铃轨迹略向前倾',
      ],
      commonMistakes: [
        '倾斜角过大（>45°）变成肩推',
        '臀部抬起借力',
      ],
      coachName: defaultCoach,
      breathingTip: '下放吸气，推起呼气',
    ),
    Tutorial(
      id: 'tut_basic_pull_up',
      name: '引体向上',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.back,
      equipment: '单杠',
      keyPoints: [
        '双手正握略宽于肩',
        '肩胛骨下沉后缩，启动背阔肌',
        '下巴过杠为一次',
        '下放至手臂完全伸展',
      ],
      commonMistakes: [
        '借力摆动身体',
        '下巴未过杠',
        '下放未完全伸展',
      ],
      coachName: defaultCoach,
      breathingTip: '上拉呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_squat',
      name: '杠铃深蹲',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      keyPoints: [
        '杠铃置于斜方肌上部（高杠）',
        '双脚与肩同宽，脚尖外展15-30°',
        '下蹲时膝盖跟踪脚尖方向',
        '大腿至少与地面平行',
        '保持脊柱中立位，挺胸',
      ],
      commonMistakes: [
        '膝盖内扣',
        '腰椎弯曲（龟背）',
        '脚跟离地',
        '下蹲深度不足',
      ],
      coachName: defaultCoach,
      breathingTip: '下蹲吸气，站起呼气',
    ),
    Tutorial(
      id: 'tut_basic_plank',
      name: '平板支撑',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.core,
      equipment: '无',
      keyPoints: [
        '前臂支撑，肘关节位于肩部正下方',
        '身体保持一条直线（头-肩-髋-踝）',
        '腹部收紧，臀部不塌陷不抬起',
        '保持正常呼吸，不憋气',
      ],
      commonMistakes: [
        '臀部塌陷',
        '臀部抬起过高',
        '低头或仰头',
        '憋气',
      ],
      coachName: defaultCoach,
      breathingTip: '保持均匀呼吸',
    ),

    // ── 胸部补充（2） ──
    Tutorial(
      id: 'tut_basic_push_up',
      name: '俯卧撑',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.chest,
      equipment: '无',
      keyPoints: [
        '双手略宽于肩，掌心与胸口平齐',
        '身体保持一条直线，核心收紧',
        '下放至胸口接近地面，肘部约45度外展',
        '推起时呼气，全程控制速度',
      ],
      commonMistakes: [
        '腰部塌陷或臀部抬起',
        '下放深度不足',
        '肘部完全外展（T字形）伤肩',
        '速度过快借力',
      ],
      alternativeExerciseIds: ['tut_basic_bench_press', 'tut_basic_dip'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，推起呼气',
    ),
    Tutorial(
      id: 'tut_basic_dip',
      name: '双杠臂屈伸',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      equipment: '双杠',
      keyPoints: [
        '双杠支撑，身体微前倾刺激胸肌',
        '下放至上臂与地面平行',
        '推起时不要完全锁死肘关节',
        '保持肩胛骨下沉稳定',
      ],
      commonMistakes: [
        '下放过深导致肩前侧不适',
        '身体垂直（变成三头主导）',
        '耸肩借力',
      ],
      alternativeExerciseIds: ['tut_basic_push_up', 'tut_basic_bench_press'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，推起呼气',
    ),

    // ── 背部补充（4） ──
    Tutorial(
      id: 'tut_basic_barbell_row',
      name: '杠铃划船',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.back,
      equipment: '杠铃',
      keyPoints: [
        '髋部铰链前倾约45度，背部保持中立',
        '握距略宽于肩，正握杠铃',
        '拉至下腹位置，肘部贴近身体',
        '顶峰收缩1秒，感受背阔肌发力',
      ],
      commonMistakes: [
        '腰椎弯曲（龟背）',
        '靠手臂发力而非背部',
        '躯干上下摆动借力',
        '拉到胸口而非下腹',
      ],
      alternativeExerciseIds: ['tut_basic_seated_row', 'tut_basic_lat_pulldown'],
      coachName: defaultCoach,
      breathingTip: '拉起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_lat_pulldown',
      name: '高位下拉',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.back,
      equipment: '绳索',
      keyPoints: [
        '正握略宽于肩，坐稳大腿固定',
        '肩胛骨下沉后缩启动',
        '拉至锁骨上方，肘部向下向后',
        '缓慢返回，全程保持张力',
      ],
      commonMistakes: [
        '靠手臂下拉而非背阔',
        '躯干过度后仰借力',
        '下放过快失去控制',
      ],
      alternativeExerciseIds: ['tut_basic_pull_up', 'tut_basic_barbell_row'],
      coachName: defaultCoach,
      breathingTip: '下拉呼气，回放吸气',
    ),
    Tutorial(
      id: 'tut_basic_deadlift',
      name: '罗马尼亚硬拉',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.back,
      equipment: '杠铃',
      keyPoints: [
        '站立与肩同宽，杠铃贴近大腿',
        '髋部铰链后推，膝盖微屈',
        '下放至杠铃过膝，感受腘绳肌拉伸',
        '挺胸收背，全程脊柱中立',
      ],
      commonMistakes: [
        '腰椎弯曲',
        '杠铃远离身体',
        '膝盖过度弯曲变成深蹲',
        '起身时臀部先抬起',
      ],
      alternativeExerciseIds: ['tut_basic_barbell_row', 'tut_basic_squat'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，起身呼气',
    ),
    Tutorial(
      id: 'tut_basic_seated_row',
      name: '坐姿划船',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.back,
      equipment: '绳索',
      keyPoints: [
        '坐稳双脚踩实踏板，膝盖微屈',
        '挺胸收腹，肩胛骨下沉',
        '拉至腹部，肘部贴近身体',
        '顶峰收缩1-2秒',
      ],
      commonMistakes: [
        '躯干前后摆动借力',
        '耸肩',
        '返回时完全放松失去张力',
      ],
      alternativeExerciseIds: ['tut_basic_barbell_row', 'tut_basic_lat_pulldown'],
      coachName: defaultCoach,
      breathingTip: '拉时呼气，放时吸气',
    ),

    // ── 腿部补充（4） ──
    Tutorial(
      id: 'tut_basic_lunge',
      name: '弓步蹲',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.leg,
      equipment: '哑铃/自重',
      keyPoints: [
        '一脚向前跨一大步，双脚与髋同宽',
        '下蹲至前腿大腿平行，后腿膝盖接近地面',
        '前膝跟踪脚尖方向，不内扣',
        '蹬起回到起始位置',
      ],
      commonMistakes: [
        '前膝内扣',
        '躯干前倾过度',
        '步幅过小（膝盖压力大）',
        '后腿膝盖猛撞地面',
      ],
      alternativeExerciseIds: ['tut_basic_squat', 'tut_basic_leg_press'],
      coachName: defaultCoach,
      breathingTip: '下蹲吸气，蹬起呼气',
    ),
    Tutorial(
      id: 'tut_basic_leg_press',
      name: '腿举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.leg,
      equipment: '器械',
      keyPoints: [
        '双脚与肩同宽置于踏板中上部',
        '脚尖略外展，膝盖跟踪方向',
        '下放至膝盖约90度',
        '推起时不完全锁死膝关节',
      ],
      commonMistakes: [
        '膝盖完全锁死',
        '下放深度不足',
        '脚尖过高（刺激腘绳）或过低（刺激股四头）',
        '推起过快借力',
      ],
      alternativeExerciseIds: ['tut_basic_squat', 'tut_basic_lunge'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，推起呼气',
    ),
    Tutorial(
      id: 'tut_basic_rdl',
      name: '哑铃罗马尼亚硬拉',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.leg,
      equipment: '哑铃',
      keyPoints: [
        '双手持哑铃于大腿前',
        '髋部铰链后推，膝盖微屈',
        '下放至哑铃过膝，感受腘绳肌拉伸',
        '挺胸保持脊柱中立',
      ],
      commonMistakes: [
        '腰椎弯曲',
        '膝盖过度弯曲',
        '下放过深导致背部代偿',
      ],
      alternativeExerciseIds: ['tut_basic_squat', 'tut_basic_deadlift'],
      coachName: defaultCoach,
      breathingTip: '下放吸气，起身呼气',
    ),
    Tutorial(
      id: 'tut_basic_calf_raise',
      name: '提踵',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.leg,
      equipment: '哑铃/器械',
      keyPoints: [
        '前脚掌立于台阶边缘',
        '缓慢起至最高点，顶峰收缩1-2秒',
        '缓慢下放至拉伸感',
        '全程控制速度',
      ],
      commonMistakes: [
        '速度过快借力弹跳',
        '下放不充分',
        '顶峰无停顿',
      ],
      coachName: defaultCoach,
      breathingTip: '起呼气，落吸气',
    ),

    // ── 肩部（5） ──
    Tutorial(
      id: 'tut_basic_overhead_press',
      name: '杠铃推举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.shoulder,
      equipment: '杠铃',
      keyPoints: [
        '杠铃置于锁骨前，握距略宽于肩',
        '挺胸收腹，核心收紧',
        '推至头顶上方，肘部伸展',
        '杠铃轨迹垂直向上',
      ],
      commonMistakes: [
        '腰部过度反弓',
        '推起时肘部外展过度',
        '重量过大借力',
      ],
      coachName: defaultCoach,
      breathingTip: '推起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_lateral_raise',
      name: '哑铃侧平举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.shoulder,
      equipment: '哑铃',
      keyPoints: [
        '双手持哑铃于身体两侧',
        '微曲肘部，抬至与肩平齐',
        '小臂略低于大臂（内旋）',
        '缓慢下放保持张力',
      ],
      commonMistakes: [
        '重量过大借力甩动',
        '抬过高（>90度）伤肩',
        '手腕高于肘部',
      ],
      coachName: defaultCoach,
      breathingTip: '抬起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_front_raise',
      name: '前平举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.shoulder,
      equipment: '哑铃',
      keyPoints: [
        '双手持哑铃于大腿前',
        '手臂伸直向前抬起至与肩平齐',
        '控制速度，不借力甩动',
        '缓慢下放',
      ],
      commonMistakes: [
        '借力摆动身体',
        '抬过高',
        '速度过快',
      ],
      coachName: defaultCoach,
      breathingTip: '抬起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_face_pull',
      name: '面拉',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.shoulder,
      equipment: '绳索',
      keyPoints: [
        '滑轮调至面部高度，绳索两端',
        '拉向额头位置，肘部外展',
        '顶峰收缩1-2秒，肩胛骨后缩',
        '轻重量高控制',
      ],
      commonMistakes: [
        '重量过大借力',
        '拉向胸口而非面部',
        '耸肩',
      ],
      coachName: defaultCoach,
      breathingTip: '拉时呼气，放时吸气',
    ),
    Tutorial(
      id: 'tut_basic_arnold_press',
      name: '阿诺德推举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.shoulder,
      equipment: '哑铃',
      keyPoints: [
        '哑铃起始位于肩前，掌心向内',
        '推起过程中外旋手腕',
        '顶点掌心向前，下放内旋回起始',
        '全程控制速度',
      ],
      commonMistakes: [
        '推起速度过快',
        '外旋不充分',
        '肘部外展过度',
      ],
      coachName: defaultCoach,
      breathingTip: '推起呼气，下放吸气',
    ),

    // ── 手臂（5） ──
    Tutorial(
      id: 'tut_basic_bicep_curl',
      name: '哑铃弯举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.arm,
      equipment: '哑铃',
      keyPoints: [
        '站姿持哑铃于身体两侧，掌心向前',
        '肘部固定贴近身体',
        '弯举至肩前，顶峰收缩1秒',
        '缓慢下放保持张力',
      ],
      commonMistakes: [
        '肘部前后移动借力',
        '躯干摆动',
        '下放过快失去张力',
      ],
      coachName: defaultCoach,
      breathingTip: '弯举呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_tricep_pushdown',
      name: '三头下压',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.arm,
      equipment: '绳索',
      keyPoints: [
        '正握直杆或绳索，肘部固定贴近身体',
        '下压至手臂完全伸展',
        '顶峰收缩1秒',
        '缓慢返回至上臂平行',
      ],
      commonMistakes: [
        '肘部前后移动',
        '躯干前倾借力',
        '返回过快',
      ],
      coachName: defaultCoach,
      breathingTip: '下压呼气，返回吸气',
    ),
    Tutorial(
      id: 'tut_basic_hammer_curl',
      name: '锤式弯举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.arm,
      equipment: '哑铃',
      keyPoints: [
        '站姿持哑铃，掌心相对（中立握）',
        '肘部固定，弯举至肩前',
        '顶峰收缩1秒',
        '缓慢下放',
      ],
      commonMistakes: [
        '肘部移动',
        '借力摆动',
        '速度过快',
      ],
      coachName: defaultCoach,
      breathingTip: '弯举呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_skull_crusher',
      name: '仰卧臂屈伸',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.arm,
      equipment: '哑铃/杠铃',
      keyPoints: [
        '仰卧凳上，手臂垂直于胸口',
        '屈肘下放至额头附近',
        '伸肘回到起始位置',
        '肘部固定不外展',
      ],
      commonMistakes: [
        '肘部外展',
        '下放过深伤肘',
        '重量过大',
      ],
      coachName: defaultCoach,
      breathingTip: '屈肘吸气，伸肘呼气',
    ),
    Tutorial(
      id: 'tut_basic_concentration_curl',
      name: '集中弯举',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.arm,
      equipment: '哑铃',
      keyPoints: [
        '坐姿，单手持哑铃',
        '肘部抵于大腿内侧固定',
        '弯举至肩前，顶峰收缩2秒',
        '缓慢下放',
      ],
      commonMistakes: [
        '肘部离开大腿',
        '借力摆动',
        '顶峰无停顿',
      ],
      coachName: defaultCoach,
      breathingTip: '弯举呼气，下放吸气',
    ),

    // ── 核心补充（4） ──
    Tutorial(
      id: 'tut_basic_crunch',
      name: '卷腹',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.core,
      equipment: '无',
      keyPoints: [
        '仰卧屈膝，双手轻扶头侧',
        '下腰部贴地，肩胛骨离地即可',
        '顶峰收缩1-2秒',
        '缓慢下放',
      ],
      commonMistakes: [
        '双手抱头用力拉颈部',
        '整个背部离地（变成仰卧起坐）',
        '速度过快',
      ],
      coachName: defaultCoach,
      breathingTip: '卷起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_leg_raise',
      name: '仰卧举腿',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.core,
      equipment: '无',
      keyPoints: [
        '仰卧双手置于臀部下方',
        '双腿并拢伸直',
        '抬起至与地面垂直',
        '缓慢下放至接近地面',
      ],
      commonMistakes: [
        '腰部离地',
        '下放过快',
        '双腿弯曲',
      ],
      coachName: defaultCoach,
      breathingTip: '抬起呼气，下放吸气',
    ),
    Tutorial(
      id: 'tut_basic_russian_twist',
      name: '俄式转体',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.core,
      equipment: '哑铃/药球',
      keyPoints: [
        '坐姿屈膝，上身后倾约45度',
        '双脚离地（进阶）或踩地（入门）',
        '持重物左右转体触地',
        '控制速度，感受腹斜肌发力',
      ],
      commonMistakes: [
        '只动手臂不转体',
        '速度过快',
        '弓背',
      ],
      coachName: defaultCoach,
      breathingTip: '转体呼气，回中吸气',
    ),
    Tutorial(
      id: 'tut_basic_mountain_climber',
      name: '登山跑',
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: MuscleGroup.core,
      equipment: '无',
      keyPoints: [
        '俯卧撑起始姿势',
        '交替提膝至胸口',
        '核心收紧，臀部不抬起',
        '保持均匀节奏',
      ],
      commonMistakes: [
        '臀部抬起过高',
        '腰部塌陷',
        '提膝不充分',
      ],
      coachName: defaultCoach,
      breathingTip: '保持均匀呼吸',
    ),
  ];

  /// 进阶教学（需裂变解锁，每邀请1人解锁3个）
  static const List<Tutorial> advancedTutorials = [
    Tutorial(
      id: 'tut_adv_cable_fly',
      name: '绳索夹胸变式',
      type: TutorialType.advanced,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      equipment: '绳索',
      keyPoints: [
        '调整滑轮至适当高度（高/中/低位刺激不同）',
        '微曲手肘，固定角度',
        '双手在胸前交叉，顶峰收缩1-2秒',
        '缓慢返回，保持张力',
      ],
      commonMistakes: [
        '手肘角度变化',
        '重量过大借力',
        '返回速度过快失去张力',
      ],
      coachName: defaultCoach,
      unlockRequirement: '邀请1人激活解锁',
    ),
    Tutorial(
      id: 'tut_adv_deadlift',
      name: '硬拉进阶技巧',
      type: TutorialType.advanced,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.back,
      equipment: '杠铃',
      keyPoints: [
        '起始位置：杠铃贴近胫骨',
        '髋部铰链启动，保持背部中立',
        '发力顺序：腿→臀→背',
        '顶峰时挺胸收肩，臀部充分收缩',
      ],
      commonMistakes: [
        '腰椎弯曲',
        '杠铃远离身体',
        '手臂主动发力',
      ],
      coachName: defaultCoach,
      unlockRequirement: '邀请1人激活解锁',
    ),
    Tutorial(
      id: 'tut_adv_front_squat',
      name: '前蹲进阶',
      type: TutorialType.advanced,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      keyPoints: [
        '杠铃置于前三角肌与锁骨之间',
        '肘部高抬，保持杠铃稳定',
        '躯干更直立，膝盖前移更多',
        '刺激股四头肌更充分',
      ],
      commonMistakes: [
        '肘部下沉导致杠铃滑落',
        '躯干前倾过度',
      ],
      coachName: defaultCoach,
      unlockRequirement: '邀请1人激活解锁',
    ),
  ];

  /// 专题教学包（累计邀请3人解锁）
  static const List<Tutorial> topicTutorials = [
    Tutorial(
      id: 'tut_topic_bench_master',
      name: '卧推完全指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.chest,
      equipment: '杠铃',
      keyPoints: [
        '8个卧推变式：平板/上斜/下斜/窄距/宽距/暂停/地板/链式',
        '突破瓶颈技巧：周期化训练/辅助动作/弱链补强',
        '呼吸与发力节奏',
        '保护与安全设置',
      ],
      commonMistakes: [
        '忽视辅助肌群训练',
        '过度训练导致肩伤',
        '忽视热身',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_3day_split_guide',
      name: '三分化训练完全指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      equipment: '多种器械',
      contentType: ContentType.plan,
      keyPoints: [
        '推拉腿（PPL）分化：推日（胸/肩/三头）、拉日（背/二头）、腿日（腿/核心），每肌群每周训练2次',
        '每周6天（PPL×2）或3天（单循环），单肌群周容量10-20组符合Schoenfeld肌肥大meta分析区间',
        '主项动作（卧推/引体/深蹲）取5×5末组AMRAP，辅助动作3×8-12次，组间休息复合3-5分钟、孤立1.5-2分钟',
        '进阶规则：主项AMRAP组完成规定次数则下次+2.5kg（上肢）/+5kg（下肢），辅助达区间上限则加重',
        'RPE控制：主项保留RPE 7-9（2-3 RIR），孤立动作可至RPE 9-10，复合动作避免绝对力竭降低神经疲劳',
        '优势：每肌群48-72小时恢复窗口，训练频率高，符合频率meta分析每周2次优于1次的肌肥大结论',
      ],
      commonMistakes: [
        '推日训练量过大（>12组胸/肩）导致肩部疲劳累积影响拉日表现',
        '腿日训练后24小时内进行高冲击有氧（跑步）影响恢复，应改用骑行或坡度走',
        '忽视核心训练，仅安排在腿日末尾草草了事，应每周独立2次8-12分钟核心训练',
        '每次训练使用相同重量，缺乏渐进超负荷，应记录AMRAP次数驱动下次加重决策',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_4day_split_guide',
      name: '四分化训练完全指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.chest,
      equipment: '多种器械',
      contentType: ContentType.plan,
      keyPoints: [
        '胸/背/腿/肩四分化，每肌群每周训练1次，单肌群周容量12-16组覆盖Pelland 2024 meta分析的递减回报区间',
        '适合训练经验3-12个月的中级训练者，5×5主项+3×10-15辅助的"力量+肌肥大"双轨结构',
        '主项5×6-8次取RPE 8（2 RIR），辅助3×10-15次取RPE 9（1 RIR），复合动作组间3分钟、孤立2分钟',
        '腿部日可拆分为股四头肌主导（后蹲5×5+前蹲3×8+腿屈伸3×12）与腘绳肌主导（RDL 4×6+腿弯举3×12+提踵4×15）',
        '肩部日应包含面拉3×15-20维护肩关节健康，激活斜方肌中下束与菱形肌',
        '优势：每肌群获得充分训练容量同时保留48-72小时恢复，避免高频率下的累积疲劳',
      ],
      commonMistakes: [
        '肩部日安排在胸部日后第二天，推力肌群（前束/三头）过度疲劳影响肩推表现',
        '背部日只做垂直拉（下拉/引体）忽视水平拉（划船），导致背部宽度有余而厚度不足，建议垂直拉:水平拉=4:6',
        '腿部日只做深蹲忽视硬拉，导致前后链肌力不平衡',
        '训练日之间缺乏主动恢复（拉伸/泡沫轴放松）',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_5day_split_guide',
      name: '五分化训练完全指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.chest,
      equipment: '多种器械',
      contentType: ContentType.plan,
      keyPoints: [
        '胸/背/腿/肩/臂五分化，每肌群每周专注训练1次，单肌群周容量16-20组处于Schoenfeld肌肥大上限区间',
        '适合训练经验1-2年的中高级训练者，5-7个动作覆盖主项+辅助+孤立三层结构',
        '次数区间无效论（Schoenfeld 2017 meta效应量0.03）：6-25次均可肌肥大，但负荷需≥30% 1RM且接近力竭',
        '手臂日采用二头+三头超级组（如杠铃弯举+绳索下压），延长TUT至40-60秒制造代谢压力',
        '动作节奏采用2-1-2-1（离心2秒-底部停1秒-向心2秒-顶峰1秒），强化离心收缩肌肉损伤机制',
        '优势：单次容量最大可专项强化薄弱肌群，配合FST-7（7组×10-12次组间拉伸30秒）作为收尾',
      ],
      commonMistakes: [
        '训练频率过低（每周仅1次）使肌蛋白合成窗口未被充分利用，可考虑将手臂拆分到推拉日',
        '肩部日与手臂日相邻，三头在肩推中已疲劳影响手臂日表现，应间隔至少48小时',
        '每个动作组数>6组产生"垃圾容量"（junk volume）降低训练质量，单动作4组即可',
        '忽视离心控制（下放过快<1秒），失去50%以上的肌肉机械张力刺激',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_arm_specialization',
      name: '手臂专项突破指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.arm,
      equipment: '杠铃/哑铃/绳索',
      contentType: ContentType.plan,
      keyPoints: [
        '手臂专项周期：每周2-3次（Schoenfeld频率meta分析优于每周1次），二头与三头每周各10-20组',
        '肱三头肌占上臂体积2/3，臂围突破应优先三头：先过头位（仰卧臂屈伸/绳索过头上拉）激活长头',
        '肱二头肌长头：上斜哑铃弯举（肩伸位拉伸长头）+ 集中弯举（短头峰收缩）；牧师凳弯举强调短头',
        '三头训练必须含过头上举动作（长头跨肩关节，仅下压会忽略长头激活）',
        '21响训练法：7下半程+7上半程+7全程，TUT延长至40-60秒，负重取10RM的50-60%，限孤立动作',
        '超级组搭配：杠铃弯举+绳索下压、哑铃锤式+仰卧臂屈伸，组间60-75秒维持代谢压力',
      ],
      commonMistakes: [
        '借力甩动身体靠惯性完成弯举，肘部前后移动使二头失去稳定发力',
        '三头训练只做下压类动作，忽视过顶动作对长头的拉伸刺激，导致三头发育不均衡',
        '训练频率过高（>3次/周）或单次容量过大（>10组/肌群）导致恢复不足反而影响生长',
        '忽视肱肌训练（锤式弯举/反握弯举），肱肌位于肱二头肌下方，增厚可推高二头视觉围度',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_back_specialization',
      name: '背部专项突破指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.back,
      equipment: '杠铃/哑铃/绳索/单杠',
      contentType: ContentType.plan,
      keyPoints: [
        '背部专项周期：每周2次，每次16-24组拉类容量，符合StrongerByScience背阔肌频率建议',
        '垂直拉与水平拉比例4:6：水平拉（划船类）对背部厚度（中斜方/菱形/背阔中部）贡献更大应略多',
        '背阔肌宽度vs厚度分化：宽握正手引体/下拉强调背阔上外侧与大圆肌（宽度），对握/反手强调下内侧（厚度）',
        '肩胛控制：所有拉类起始阶段先"沉肩+肩胛后缩"再拉，避免斜方上束代偿导致耸肩',
        '面拉3-4组×15-20次作为收尾：综合激活斜方中下束、菱形肌、三角肌后束与肩袖，维护肩关节健康',
        '直臂下压3-4组×12-15次：背阔肌孤立动作剔除二头借力，适合垂直拉后做"榨干组"',
      ],
      commonMistakes: [
        '只做下拉类动作忽视划船，背部宽度有余而厚度不足，划船类应占总拉类容量60%',
        '划船时手臂主导发力（二头/前臂代偿），背阔肌参与度不足，应先沉肩后缩再拉',
        '引体向上借力摆动（kipping），未做到肩胛骨先下沉后收缩，降低背阔激活',
        '忽视下背部（竖脊肌）训练，只练背阔肌导致上背发达下背薄弱，应加山羊挺身/硬拉变式',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_leg_specialization',
      name: '腿部专项突破指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃/哑铃/器械',
      contentType: ContentType.plan,
      keyPoints: [
        '腿部专项周期：每周2次，股四头肌日与腘绳肌日分离，单肌群周容量12-16组',
        '股四头肌三层结构：后蹲5×5（力量主导）+ 前蹲3×8-12（股直肌激活更高15-20%）+ 腿屈伸3×12-15（孤立力竭）',
        '腘绳肌髋主导vs膝主导分离：RDL 4×6-8（半腱肌/半膜肌+臀大肌）+ 腿弯举3×10-15（股二头肌短头）',
        '小腿分化：站姿提踵4×12-15（腓肠肌，伸膝位）+ 坐姿提踵3×15-20（比目鱼肌，屈膝位）',
        '小腿频率每周4-6次、每次8-12组（慢肌比例高），底端停1秒拉伸、顶端停1秒收缩杜绝弹震',
        '深蹲髋膝力矩分配：高杠位膝矩大（股四头主导），低杠位髋矩大（臀大肌/腘绳肌主导）',
      ],
      commonMistakes: [
        '深蹲深度不足（大腿未平行地面）使股四头肌刺激不充分，髋膝伸肌总需求不变只改变分配',
        '只练深蹲忽视硬拉，腘绳肌（双关节肌）深蹲中EMG激活有限，必须用RDL独立训练',
        '膝盖内扣（膝外翻）增加前交叉韧带损伤风险，需弹力带外展激活臀中肌纠正',
        '小腿训练被忽视或只做站姿，应区分站姿（腓肠肌）与坐姿（比目鱼肌）',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_fat_loss_guide',
      name: '高效减脂训练指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.core,
      equipment: '多种器械',
      contentType: ContentType.plan,
      goal: FitnessGoal.cut,
      keyPoints: [
        '减脂核心原理：热量缺口（饮食占70%）+ 力量训练（保留肌肉，容量保留至赤字前60-80%）+ 有氧（增加消耗）',
        '蛋白质提升至2.2-2.6 g/kg/天（Nunes 2022 meta：≥1.6 g/kg组FFM增量效应量g=0.30 vs 1.2-1.59组g=0.17）',
        '力量训练优先：保留赤字前训练强度（%1RM）+ 60-80%训练量，优先削减辅助量而非主项',
        '有氧选择：低冲击（骑行/坡度走）优于高冲击（跑步），Wilson 2012 meta高冲击使肌肥大效益降31%、力量降18%',
        '顺序与间隔：力量与有氧间隔≥6小时或分日进行，先力量后有氧，单次有氧≤45分钟避免干扰效应',
        'RPE自调节：减脂期能量不足神经驱动下降，维持RPE 7-9范围，避免盲目追求PR',
      ],
      commonMistakes: [
        '只做有氧忽视力量训练，导致肌肉流失、基础代谢下降，应力量为主（3-4次/周）+ 有氧为辅（2次/周LISS）',
        '减脂期重量过轻（<60% 1RM）无法给肌肉足够保留信号，应维持训练强度',
        '热量缺口过大（>500大卡/天）导致训练表现下降与肌肉流失，建议300-500大卡赤字',
        '空腹有氧时间过长（>60分钟）可能分解肌肉蛋白供能，应在力量训练后或进食后进行',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
    Tutorial(
      id: 'tut_topic_abs_sculpting',
      name: '腹肌雕刻完全指南',
      type: TutorialType.topic,
      difficulty: TutorialDifficulty.intermediate,
      primaryMuscle: MuscleGroup.core,
      equipment: '自重/器械',
      contentType: ContentType.plan,
      goal: FitnessGoal.cut,
      keyPoints: [
        '腹肌显现三要素：体脂率（男<15%/女<22%）+ 腹肌厚度训练 + 饮食控制（不可局部减脂）',
        '上腹部：卷腹类动作（标准卷腹/反向卷腹/绳索卷腹），每组15-25次，下腰部贴地肩胛离地即可',
        '下腹部：仰卧举腿/悬垂举腿/反向卷腹，每组12-20次，重点感受下腹收缩避免利用惯性',
        '腹斜肌：俄罗斯转体/侧平板/单车卷腹，每组20-30次，避免过大重量防止腹斜肌过度肥大粗腰',
        '腹横肌（深层核心）：平板支撑/死虫式/鸟狗式，每组30-60秒，提升核心稳定性维持腹内压',
        '训练频率：每周2-3次（腹直肌需48小时恢复），每次8-12分钟复合训练，DOMS属正常适应',
      ],
      commonMistakes: [
        '体脂率过高时过度训练腹肌，腹肌被脂肪覆盖无法显现，应优先热量赤字降体脂',
        '双手抱头用力拉颈部完成卷腹导致颈椎损伤，应轻扶头侧或交叉胸前',
        '只做卷腹忽视下腹与腹斜肌，腹肌发展不均衡，应分区训练上腹/下腹/腹斜/腹横',
        '每天练腹（>5次/周）忽视48小时恢复期，反而影响肌肥大与神经适应',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请3人激活解锁',
    ),
  ];

  /// 高手教学（累计邀请5人解锁）
  static const List<Tutorial> masterTutorials = [
    Tutorial(
      id: 'tut_master_overload',
      name: '渐进超负荷与RPE自调节',
      type: TutorialType.master,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      contentType: ContentType.plan,
      keyPoints: [
        '渐进超负荷四要素：重量×组数×次数×RPE，优先加重量→再加组数→最后调RPE',
        'RIR量表锚定RPE：RPE 10=力竭、RPE 9=还能1次、RPE 8=还能2次，预测偏差约±1次倾向低估',
        '主项力量训练：取RPE 7-9（保留1-3次）累积高质量组数；肌肥大辅助可至RPE 9-10',
        '复合动作停在技术力竭而非绝对力竭，避免神经系统过度疲劳影响下次训练',
        'RPE Stop自调节法：首组目标RPE后继续同重量做组，某组RPE比首组高2分即停止',
        '线性进阶（LP）→ 周期化（5/3/1）→ 自调节（RPE/DUP）三阶段切换时机：连续3次同重量失败',
      ],
      commonMistakes: [
        '盲目加重量（每次+5kg）超过神经适应速度导致技术变形与受伤',
        '忽视恢复（睡眠<7小时/蛋白质<1.6g/kg）使RPE虚高，误判为力量平台',
        '缺乏训练日记记录，无法识别停滞模式与制定减重决策',
        '所有组都做到绝对力竭（RPE 10），导致累积疲劳无法维持周训练频率',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请5人激活解锁',
    ),
    Tutorial(
      id: 'tut_master_big_three_biomechanics',
      name: '三大项生物力学深度解析',
      type: TutorialType.master,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      contentType: ContentType.plan,
      keyPoints: [
        '深蹲伸肌需求守恒：膝+髋伸肌力矩=负荷×股骨长度×cos(股骨角度)，杠位/站距/举重鞋只改变髋膝分配不变总需求',
        '低杠位（躯干前倾）髋矩大、膝矩小，适合髋强；高杠位反之，应根据个体强项选择',
        '腘绳肌在深蹲中EMG激活有限（双关节肌，髋膝同步伸展使其长度变化小），必须用RDL独立训练',
        '卧推握距1.5-2×肩宽，触胸位置在乳头至胸骨下端之间，触胸过高（锁骨位）增加肩峰下撞击风险',
        '硬拉起始髋位置决定背部需求：传统硬拉躯干前倾大→脊柱伸肌需求高；相扑硬拉髋外展使躯干直立→背部需求降',
        '脊柱中立位：维持腰椎自然前凸+胸椎微后凸，瓦式呼吸+腹内压加压稳定脊柱，屈曲使剪切力转移至椎间盘',
      ],
      commonMistakes: [
        '深蹲"膝盖不过脚尖"误区（源自1970s单一研究）：低杠/踝背屈受限者需适度过脚尖，应关注重心落足中',
        '卧推过度起桥（腰椎超伸）增加小关节负荷，应保持臀触凳、双脚踩地的合规起桥幅度',
        '硬拉起把时膝盖过杠铃前方导致髋后移、瞬时增加髋伸需求，应保持杠铃贴近胫骨',
        '深蹲底部"骨盆眨眼"（腰椎屈曲+骨盆后倾）增加椎间剪切力，需评估踝背屈与髋活动度',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请5人激活解锁',
    ),
    Tutorial(
      id: 'tut_master_periodization_systems',
      name: '经典周期化训练体系对比',
      type: TutorialType.master,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      contentType: ContentType.plan,
      keyPoints: [
        '线性进阶（LP）：Starting Strength 3×5/StrongLifts 5×5，每次+2.5-5kg，连续3次失败减重10%重爬，适合零基础',
        '周期化（5/3/1）：4周一循环（5/3/1+deload），FSL 5×5或BBB 5×10辅助，每周期TM+2.5-5kg，适合中级',
        '德州法（Texas Method）：周一5×5容量日/周三2×5恢复日/周五1×5新PR强度日，每周一次PR适合中级力量',
        'GZCLP三层结构：T1主项3×5+（力量）/T2辅助3×10（肌肥大）/T3孤立3×15+（弱项），失败后渐进降次（5→3→2→1）',
        '西岸交叉法（Westside）：ME日冲1-3RM变式+DE日速度训练12×2@50-60%组间60秒，每1-2周轮换主项变式',
        '体系切换时机：LP连续3次失败→5/3/1或Texas Method；GZCLP失败后重启T1测新5RM取85%重新爬升',
      ],
      commonMistakes: [
        '新手过早使用高级周期化（如Westside）导致技术未巩固即频繁更换动作变式',
        '中级训练者仍固守线性进阶（5×5）无法突破平台，应切换至周期化（5/3/1/Texas Method）',
        '忽视deload周设计，持续高强度训练导致过度训练综合征（睡眠差/表现退步/免疫力降）',
        '5/3/1 BBB辅助量过大（5×10取60% 1RM）与主项冲突，应取50-60% 1RM并保留2-3 RIR',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请5人激活解锁',
    ),
    Tutorial(
      id: 'tut_master_6day_split_guide',
      name: '六分化训练完全指南',
      type: TutorialType.master,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.chest,
      equipment: '多种器械',
      contentType: ContentType.plan,
      keyPoints: [
        '胸/背/腿/肩/臂/弱项六分化，每周6天训练1天休息，适合高级训练者追求极致发展',
        '第6天为"弱项强化日"，针对个人薄弱肌群进行专项突破（如小腿/前臂/腹肌/上胸）',
        '每个训练日5-7个动作，总组数18-25组，主项以6-10次为主，孤立动作12-15次',
        '周期化安排：每4周为一个微周期，第4周减量50%进行主动恢复',
        '高频率恢复管理：每日睡眠7-9小时，蛋白质摄入1.8-2.2g/kg体重，训练后及时补充碳水+蛋白',
        '优势：训练频率与容量最大化，可针对每个肌群进行深度精雕，适合备赛或极限突破',
      ],
      commonMistakes: [
        '训练频率过高导致中枢神经系统疲劳，表现为睡眠质量下降与训练表现退步',
        '弱项日安排与主项日相邻，影响大肌群恢复（如弱项手臂日紧接胸部日）',
        '忽视减量周（Deload），持续高强度训练导致过度训练综合征',
        '营养与睡眠跟不上训练频率，反而导致肌肉分解与免疫力下降',
      ],
      coachName: defaultCoach,
      unlockRequirement: '累计邀请5人激活解锁',
    ),
  ];

  /// 获取所有基础教学
  static List<Tutorial> getBasic() => basicTutorials;

  /// 根据解锁状态获取进阶教学
  ///
  /// [unlockedCount] 已解锁的进阶教学数量（来自 settings.unlockedAdvancedTutorials）
  static List<Tutorial> getAdvanced(int unlockedCount) {
    if (unlockedCount <= 0) return [];
    return advancedTutorials.take(unlockedCount).toList();
  }

  /// 是否解锁专题教学
  static List<Tutorial> getTopic(bool unlocked) =>
      unlocked ? topicTutorials : [];

  /// 是否解锁高手教学
  static List<Tutorial> getMaster(bool unlocked) =>
      unlocked ? masterTutorials : [];

  /// 按训练目标筛选所有教学（含锁定的，调用方自行处理解锁状态）
  static List<Tutorial> getByGoal(FitnessGoal goal) {
    final all = [...basicTutorials, ...advancedTutorials, ...topicTutorials, ...masterTutorials];
    return all.where((t) => t.goal == goal).toList();
  }

  /// 按教学类型查询（包含锁定项，调用方根据解锁状态渲染锁标识）
  static List<Tutorial> getByType(TutorialType type) {
    switch (type) {
      case TutorialType.basic:
        return basicTutorials;
      case TutorialType.advanced:
        return advancedTutorials;
      case TutorialType.topic:
        return topicTutorials;
      case TutorialType.master:
        return masterTutorials;
    }
  }

  /// 按"目标 + 类型"组合筛选（包含锁定项）
  static List<Tutorial> getByGoalAndType(FitnessGoal? goal, TutorialType type) {
    final list = getByType(type);
    if (goal == null) return list;
    return list.where((t) => t.goal == goal).toList();
  }

  /// 根据 ID 查询
  static Tutorial? getById(String id) {
    final all = [...basicTutorials, ...advancedTutorials, ...topicTutorials, ...masterTutorials];
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// 按肌群分组
  static Map<MuscleGroup, List<Tutorial>> groupByMuscle(List<Tutorial> tutorials) {
    final map = <MuscleGroup, List<Tutorial>>{};
    for (final t in tutorials) {
      map.putIfAbsent(t.primaryMuscle, () => []).add(t);
    }
    return map;
  }
}
