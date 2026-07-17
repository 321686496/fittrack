import 'package:flutter/material.dart';
import 'content_block.dart';

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
  ];

  /// 高手教学（累计邀请5人解锁）
  static const List<Tutorial> masterTutorials = [
    Tutorial(
      id: 'tut_master_overload',
      name: '渐进超负荷实操',
      type: TutorialType.master,
      difficulty: TutorialDifficulty.advanced,
      primaryMuscle: MuscleGroup.leg,
      equipment: '杠铃',
      keyPoints: [
        '线性递增：每周加2.5kg',
        '周期化：积累/强度/减载',
        'RPE/RIR 量化强度',
        '训练日记记录与复盘',
      ],
      commonMistakes: [
        '盲目加重量导致受伤',
        '忽视恢复',
        '缺乏数据记录',
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
