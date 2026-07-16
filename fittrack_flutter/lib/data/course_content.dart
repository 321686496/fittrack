import 'package:flutter/material.dart';
import 'tutorial_content.dart';

/// 课程章节
class Chapter {
  final String id;
  final String title;
  final String content; // 图文内容（分段文本）
  final List<String> imageEmojis; // 每段配图Emoji
  final List<String> recommendedExerciseIds; // 推荐动作ID（跳转动作库）

  const Chapter({
    required this.id,
    required this.title,
    required this.content,
    this.imageEmojis = const [],
    this.recommendedExerciseIds = const [],
  });
}

/// 系统化课程
class Course {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final FitnessGoal goal;
  final TutorialDifficulty difficulty;
  final int pointsCost; // 积分解锁价格
  final List<Color> coverColors;
  final String coverEmoji;
  final List<Chapter> chapters;
  final String coachName;

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.goal,
    required this.difficulty,
    required this.pointsCost,
    this.coverColors = const [Color(0xFFFF6B35), Color(0xFFFFD700)],
    this.coverEmoji = '📚',
    required this.chapters,
    this.coachName = '教练·凯文',
  });
}

/// 系统化课程库
class CourseLibrary {
  CourseLibrary._();

  static const String defaultCoach = '教练·凯文';

  static const List<Course> courses = [
    Course(
      id: 'course_beginner_bulk',
      title: '新手零基础增肌入门',
      subtitle: '从器材使用到饮食计划，5章完整闭环',
      description: '系统化增肌入门课程，涵盖健身器材使用、训练计划制定、饮食管理与恢复策略，帮助零基础新手建立完整的训练认知。',
      goal: FitnessGoal.bulk,
      difficulty: TutorialDifficulty.beginner,
      pointsCost: 200,
      coverEmoji: '💪',
      coverColors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
      chapters: [
        Chapter(
          id: 'ch1_intro',
          title: '第1章：走进健身房',
          content: '认识健身房区域划分与基础礼仪。\n\n器械区：固定器械适合新手找到发力感，自由重量区（杠铃/哑铃）适合进阶训练。\n\n有氧区：跑步机、椭圆机、划船机，用于热身和减脂。\n\n力量区：深蹲架、卧推架、硬拉台，是增肌训练的核心区域。\n\n礼仪提示：用完器械归位、自带毛巾、不长时间占用热门器械。',
          imageEmojis: ['🏋️', '🏃', '🚴', '🤝'],
        ),
        Chapter(
          id: 'ch2_equipment',
          title: '第2章：健身器材使用基础',
          content: '杠铃与哑铃的区别与选择。\n\n杠铃：适合大重量复合动作（深蹲、卧推、硬拉），能加载更大重量。\n\n哑铃：适合单侧训练和修正不平衡，活动范围更自由。\n\n固定器械：轨迹固定，安全性高，适合新手建立基础发力模式。\n\n安全提示：杠铃训练必须有保护杠或搭档保护，使用安全锁扣固定杠铃片。',
          imageEmojis: ['🔒', '⚖️', '🛡️'],
          recommendedExerciseIds: ['tut_basic_bench_press', 'tut_basic_squat'],
        ),
        Chapter(
          id: 'ch3_plan',
          title: '第3章：制定你的第一个训练计划',
          content: '训练频率：新手建议每周3次，全身训练或上下肢分化。\n\n训练容量：每个动作3-4组，每组8-12次，组间休息60-90秒。\n\n渐进超负荷：每周尝试增加重量或次数，记录训练日志追踪进步。\n\n动作选择：以复合动作（深蹲、卧推、硬拉、引体）为主，孤立动作为辅。\n\n热身：5分钟轻度有氧 + 动态拉伸；放松：5分钟静态拉伸。',
          imageEmojis: ['📋', '📈', '🔥'],
          recommendedExerciseIds: ['tut_basic_pull_up'],
        ),
        Chapter(
          id: 'ch4_diet',
          title: '第4章：增肌期饮食管理',
          content: '热量盈余：每日摄入比消耗多300-500大卡，体重每周增0.25-0.5kg为宜。\n\n蛋白质：每公斤体重1.6-2.2克，分散到4-5餐摄入。\n\n碳水：训练前后补充碳水，提供训练能量并促进恢复。\n\n脂肪：占总热量20-30%，优选不饱和脂肪。\n\n补水：每日2-3升水，训练时少量多次补充。',
          imageEmojis: ['🍗', '🍚', '💧'],
        ),
        Chapter(
          id: 'ch5_recovery',
          title: '第5章：恢复与后续进阶',
          content: '睡眠：每晚7-9小时，肌肉在睡眠中修复生长。\n\n主动恢复：休息日做轻度有氧或拉伸，促进血液循环。\n\n deload周：每4-6周安排一次减量周，重量降至平时的60%，让身体充分恢复。\n\n进阶方向：完成本课程后，可学习分化训练（推拉腿）、力量计划（5x5）等进阶内容。\n\n记住：增肌是马拉松不是短跑，坚持比完美计划更重要。',
          imageEmojis: ['😴', '🧘', '🎯'],
        ),
      ],
    ),
    Course(
      id: 'course_cut_diet',
      title: '减脂饮食全攻略',
      subtitle: '科学减脂不反弹，4章掌握饮食核心',
      description: '从热量缺口到宏量营养素分配，从食材选择到平台期突破，系统化掌握减脂期饮食管理的所有关键点。',
      goal: FitnessGoal.cut,
      difficulty: TutorialDifficulty.beginner,
      pointsCost: 150,
      coverEmoji: '🥗',
      coverColors: [Color(0xFF22C55E), Color(0xFF86EFAC)],
      chapters: [
        Chapter(
          id: 'cut_ch1_deficit',
          title: '第1章：理解热量缺口',
          content: '减脂核心原理：热量消耗 > 热量摄入。\n\n合理缺口：每日300-500大卡缺口，每周减0.5-1磅脂肪。\n\n过大缺口的风险：肌肉流失、代谢下降、内分泌紊乱。\n\n计算TDEE：用公式或App估算每日总消耗，再减去缺口值得到目标摄入。\n\n记录饮食：前2周记录所有入口食物，建立热量直觉。',
          imageEmojis: ['📉', '🔢', '📝'],
        ),
        Chapter(
          id: 'cut_ch2_macros',
          title: '第2章：宏量营养素分配',
          content: '蛋白质：每公斤体重1.8-2.4克，减脂期保肌肉的关键。\n\n脂肪：占总热量25-30%，不低于每公斤0.8克，维持激素水平。\n\n碳水：剩余热量分配，训练日多碳水、休息日少碳水。\n\n纤维：每日25-30克，蔬菜为主，增加饱腹感。\n\n水分：每日2-3升，饭前喝水可增加饱腹感。',
          imageEmojis: ['🥩', '🥑', '🍞', '🥦'],
        ),
        Chapter(
          id: 'cut_ch3_food',
          title: '第3章：食材选择与替代',
          content: '优质蛋白：鸡胸肉、鱼虾、蛋白、瘦牛肉、希腊酸奶。\n\n优质碳水：燕麦、糙米、红薯、全麦面包。\n\n优质脂肪：牛油果、坚果、橄榄油、鱼油。\n\n避坑食物：含糖饮料、深加工食品、油炸食品、精制碳水。\n\n外食技巧：选烤/蒸/煮而非炸，酱料分开蘸，先吃菜再吃肉最后吃主食。',
          imageEmojis: ['🍗', '🐟', '🥑', '⚠️'],
        ),
        Chapter(
          id: 'cut_ch4_plateau',
          title: '第4章：平台期突破与维持',
          content: '平台期原因：代谢适应、水分波动、热量计算误差。\n\n突破策略：重新计算TDEE、增加非运动消耗（NEAT）、安排饮食休息日（refeed）。\n\n不要：盲目继续削减热量至极低水平，会导致暴食反弹。\n\n达到目标后：用2-4周反向饮食，每周增加100大卡直至维持热量。\n\n长期维持：建立可持续的饮食习惯，允许20%的灵活食物，避免非黑即白思维。',
          imageEmojis: ['🔄', '📈', '⚖️'],
        ),
      ],
    ),
  ];

  static Course? getById(String id) {
    for (final c in courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Course> getByGoal(FitnessGoal goal) {
    return courses.where((c) => c.goal == goal).toList();
  }
}
