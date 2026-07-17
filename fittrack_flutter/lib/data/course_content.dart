import 'package:flutter/material.dart';
import 'tutorial_content.dart';
import 'content_block.dart';

/// 课程章节
class Chapter {
  final String id;
  final String title;
  final String content; // 旧字段，保留作为 fallback
  final List<String> imageEmojis; // 旧字段
  final List<ContentBlock> blocks; // 新字段：富文本块
  final List<String> recommendedExerciseIds;
  final int? pointsReward;

  const Chapter({
    required this.id,
    required this.title,
    required this.content,
    this.imageEmojis = const [],
    this.blocks = const [],
    this.recommendedExerciseIds = const [],
    this.pointsReward = 10,
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
          blocks: [
            ContentBlock.heading('为什么走进健身房是第一步'),
            ContentBlock.paragraph('很多人在开始健身之旅时，会在家用器械和去健身房之间犹豫。事实上，健身房提供了家用无法替代的优势：完整的器械配置让你能刺激每一块肌肉；训练氛围让你更容易进入状态；更重要的是，镜子里的自己和身旁的训练者，会成为你坚持的动力。本章将带你认识健身房的区域划分、器材分类与基础礼仪，让你第一次走进健身房就能从容不迫。'),
            ContentBlock.heading('健身房区域划分'),
            ContentBlock.paragraph('现代健身房通常划分为四大区域。器械区（固定器械）轨迹固定、安全性高，适合新手建立基础发力感，是入门前两周的主要训练区域。自由重量区（杠铃、哑铃）活动范围自由、对稳定肌要求更高，是增肌训练的核心区域，适合掌握基础动作模式后使用。有氧区（跑步机、椭圆机、划船机）主要用于热身和减脂，建议训练前做 5-10 分钟轻度有氧提升体温。力量区（深蹲架、卧推架、硬拉台）是大重量复合动作的专属区域，使用时务必有保护杠或搭档保护。'),
            ContentBlock.callout('新手第一次去健身房，建议先在器械区完成 2-3 次训练，熟悉发力感后再尝试自由重量', 'tip'),
            ContentBlock.heading('器材选择：杠铃、哑铃与固定器械'),
            ContentBlock.paragraph('杠铃适合大重量复合动作（深蹲、卧推、硬拉），能加载更大重量，对神经肌肉系统的刺激最强，是力量和围度增长的首选工具。哑铃适合单侧训练和修正左右不平衡，活动范围更自由，对关节更友好，适合作为杠铃动作的补充或替代。固定器械轨迹固定、安全性高，适合新手建立基础发力模式、康复期训练或力竭后的 drop set。三者并非互相替代，而是根据训练阶段和目标灵活组合。'),
            ContentBlock.heading('健身房基础礼仪'),
            ContentBlock.bulletList('用完器械归位，杠铃片卸下放回架\n自带毛巾，擦干留在器械上的汗水\n不长时间占用热门器械，组间休息时让别人插空\n训练时不大声呼喊或摔砸器械\n使用更衣室保持整洁，淋浴后清理排水口'),
            ContentBlock.callout('健身房是一个共享空间，良好的礼仪会让你受欢迎，也更容易结交训练伙伴', 'tip'),
            ContentBlock.heading('新手第一次训练建议'),
            ContentBlock.paragraph('第一次走进健身房，不必急于上大重量。建议先在跑步机上快走 5 分钟热身，然后选择 2-3 台固定器械（如坐姿推胸、高位下拉、腿举），每台做 2 组、每组 12-15 次、用较轻的重量，感受目标肌群的发力。训练总时长控制在 30-40 分钟，避免过度疲劳影响后续坚持。训练后做 5 分钟静态拉伸，重点拉伸胸、背、腿。回家后记录今天的训练内容，这是建立训练习惯的第一步。'),
            ContentBlock.quote('增肌是马拉松不是短跑，第一次训练的目标不是练趴下，而是让你愿意来第二次。'),
          ],
        ),
        Chapter(
          id: 'ch2_equipment',
          title: '第2章：健身器材使用基础',
          content: '杠铃与哑铃的区别与选择。\n\n杠铃：适合大重量复合动作（深蹲、卧推、硬拉），能加载更大重量。\n\n哑铃：适合单侧训练和修正不平衡，活动范围更自由。\n\n固定器械：轨迹固定，安全性高，适合新手建立基础发力模式。\n\n安全提示：杠铃训练必须有保护杠或搭档保护，使用安全锁扣固定杠铃片。',
          imageEmojis: ['🔒', '⚖️', '🛡️'],
          recommendedExerciseIds: ['tut_basic_bench_press', 'tut_basic_squat'],
          blocks: [
            ContentBlock.heading('杠铃与哑铃的本质区别'),
            ContentBlock.paragraph('杠铃和哑铃是自由重量训练的两大核心工具，但它们各有侧重。杠铃采用双手握持的对称结构，能加载极大重量，对神经肌肉系统的募集刺激最强，特别适合深蹲、卧推、硬拉这类多关节复合动作，是力量和围度增长的首选工具。哑铃则活动范围更自由，允许手腕和肘部自然转动，对关节更友好，能单侧训练以修正左右不平衡，适合作为杠铃动作的补充或某些动作的替代。两者并非替代关系，而是互补——好的训练计划会同时使用杠铃和哑铃。'),
            ContentBlock.heading('固定器械的角色定位'),
            ContentBlock.paragraph('固定器械通过滑轮和导轨固定运动轨迹，使用者不需要控制平衡，能更专注地感受目标肌群发力。对新手来说，这是建立基础发力模式、熟悉动作路径的极佳工具；对康复期训练者，固定器械提供了低风险环境；对老手而言，固定器械常用于力竭后的 drop set，在杠铃力竭后再切到器械继续榨干目标肌群。但要注意，长期只做固定器械会导致稳定肌发展不足，过渡到自由重量时容易出现代偿或损伤。'),
            ContentBlock.callout('杠铃训练必须有保护杠或搭档保护，使用安全锁扣固定杠铃片，避免脱手或一侧滑落造成严重伤害', 'warning'),
            ContentBlock.heading('安全使用规范'),
            ContentBlock.bulletList('训练前检查杠铃片是否锁紧，锁扣是否到位\n深蹲时将保护杠调至略低于最低下蹲位置的高度\n卧推大重量时必须有人保护，保护者熟悉起杠与助力技巧\n不在力竭时勉强尝试大重量，宁可降重量保动作质量\n使用深蹲架、卧推架前确认销孔销紧，避免器械移位'),
            ContentBlock.heading('推荐入门动作'),
            ContentBlock.paragraph('杠铃卧推和杠铃深蹲是增肌训练的两大基础复合动作：卧推发展胸、肩、三头，深蹲发展股四头、臀、核心。建议在专业教练指导下先用空杆学习标准动作模式，重点掌握握距、站距、脊柱中立、呼吸与发力路径，再逐步加重量。空杆阶段不要觉得没面子——许多顶尖力量举运动员每周依然会用空杆做技术热身。每周 1-2 次、每次 4-6 组、每组 5-8 次，是力量与围度的经典安排。除卧推和深蹲外，硬拉、划船、推举也值得长期打磨，覆盖全身主要肌群构成完整训练骨架。下方是卧推和深蹲两个动作的详细教程卡，点击查看完整要点。'),
            ContentBlock.exerciseCard('tut_basic_bench_press'),
            ContentBlock.exerciseCard('tut_basic_squat'),
          ],
        ),
        Chapter(
          id: 'ch3_plan',
          title: '第3章：制定你的第一个训练计划',
          content: '训练频率：新手建议每周3次，全身训练或上下肢分化。\n\n训练容量：每个动作3-4组，每组8-12次，组间休息60-90秒。\n\n渐进超负荷：每周尝试增加重量或次数，记录训练日志追踪进步。\n\n动作选择：以复合动作（深蹲、卧推、硬拉、引体）为主，孤立动作为辅。\n\n热身：5分钟轻度有氧 + 动态拉伸；放松：5分钟静态拉伸。',
          imageEmojis: ['📋', '📈', '🔥'],
          recommendedExerciseIds: ['tut_basic_pull_up'],
          blocks: [
            ContentBlock.heading('训练频率与分化'),
            ContentBlock.paragraph('训练频率不是越多越好，而是要匹配身体的恢复能力。新手建议每周 3 次全身训练（如周一三五），每次覆盖大肌群；进阶者可选上下肢分化每周 4 次，给每个肌群更高容量刺激。频率比单次容量更重要——肌肉蛋白合成信号在训练后 24-48 小时达到峰值，规律刺激才能持续增长。两次训练同一肌群的间隔不应超过 72 小时，否则合成信号衰减，影响长期进步。'),
            ContentBlock.heading('训练容量与强度'),
            ContentBlock.paragraph('每个动作 3-4 组、每组 8-12 次、组间休息 60-90 秒是增肌黄金区间。重量选择应以最后 2-3 次感到吃力但能保持标准动作为准——也就是 RIR（保留次数）在 1-2 次之间。如果第 12 次还能轻松完成，说明重量太轻；如果第 8 次动作就开始变形，说明重量太重。每个肌群每周总组数建议 10-20 组，过多反而抑制恢复、增加受伤风险。'),
            ContentBlock.callout('记录训练日志是进步的关键——没有记录就没有渐进超负荷。记下每次的重量、组数、次数与感受，下次训练才能有方向地突破', 'tip'),
            ContentBlock.heading('渐进超负荷'),
            ContentBlock.paragraph('肌肉只在被迫适应新刺激时才会增长。每周尝试增加重量（1-2.5kg）或次数或组数，是渐进超负荷的三大手段。进步不会线性发生，但长期趋势应向上。遇到停滞时优先检查睡眠（是否 7 小时以上）、饮食（蛋白和总热量是否达标）、恢复（是否训练过度），而不是盲目加量。一段时间的退步往往是恢复不足的信号，主动减量一周胜过死磕。'),
            ContentBlock.heading('动作选择原则'),
            ContentBlock.bulletList('复合动作优先（深蹲/卧推/硬拉/引体/划船），占训练 70% 以上\n孤立动作补充（弯举/三头下压/侧平举），补足弱区\n不追求动作数量，做精每个动作比堆数量更重要\n热身 5 分钟有氧 + 动态拉伸，激活目标肌群\n放松 5 分钟静态拉伸，重点拉伸训练过的肌群'),
            ContentBlock.heading('推荐掌握的动作'),
            ContentBlock.paragraph('引体向上是衡量上肢拉力（背阔肌、二头、小臂）的黄金动作，能同时发展背部宽度和力量。但很多新手一开始做不到完整引体，可从弹力带辅助或高位下拉开始过渡，逐步建立拉力基础。当能做 3 组、每组 6 个标准引体时，你的上肢拉力已经超过健身房 80% 的人。下方是引体向上的详细教程卡。'),
            ContentBlock.exerciseCard('tut_basic_pull_up'),
          ],
        ),
        Chapter(
          id: 'ch4_diet',
          title: '第4章：增肌期饮食管理',
          content: '热量盈余：每日摄入比消耗多300-500大卡，体重每周增0.25-0.5kg为宜。\n\n蛋白质：每公斤体重1.6-2.2克，分散到4-5餐摄入。\n\n碳水：训练前后补充碳水，提供训练能量并促进恢复。\n\n脂肪：占总热量20-30%，优选不饱和脂肪。\n\n补水：每日2-3升水，训练时少量多次补充。',
          imageEmojis: ['🍗', '🍚', '💧'],
          blocks: [
            ContentBlock.heading('热量盈余的核心原理'),
            ContentBlock.paragraph('增肌的本质是肌肉蛋白质合成速率大于分解速率，这需要两个条件：足够的训练刺激和热量盈余。每日摄入比消耗多 300-500 大卡是合理范围，体重每周增 0.25-0.5kg 为宜——增重过快主要是脂肪堆积，反而影响胰岛素敏感性。肌肉合成的速率有上限，自然训练者每月最多增加 0.5-1kg 纯肌肉，超出的体重都是脂肪。急于求成只会让你后期花更多时间减脂。'),
            ContentBlock.heading('蛋白质摄入策略'),
            ContentBlock.paragraph('每公斤体重 1.6-2.2 克蛋白质是增肌期的标准摄入量，70kg 的人每天需要 112-154 克。将总量分散到 4-5 餐摄入，单次 20-40 克蛋白质可最大化肌肉蛋白合成反应——一次性吃太多反而利用率下降。优质来源包括鸡胸肉、鱼虾、鸡蛋清、瘦牛肉、希腊酸奶、乳清蛋白粉。补剂是补充而不是替代，食物优先的原则不能丢。'),
            ContentBlock.callout('训练后 30 分钟内摄入 20-30 克快速吸收的蛋白质（如乳清蛋白粉）+ 一份碳水（如香蕉），能加速肌肉修复与糖原补充', 'tip'),
            ContentBlock.paragraph('很多新手误以为增肌就是多吃肉，实际上单一营养素过量反而增加肝肾负担、降低吸收效率。一份完整的增肌餐应同时包含蛋白质（鸡胸肉/鱼/蛋）、碳水（米饭/燕麦/红薯）和蔬菜（西兰花/菠菜），三者协同才能让营养真正进入肌肉。优质食物的多样化比单一营养素堆量更重要——饮食越多样，微量元素摄入越均衡，长期训练状态越稳定。'),
            ContentBlock.heading('碳水与脂肪的平衡'),
            ContentBlock.paragraph('碳水是训练的主要能量来源，长期低碳会显著降低训练表现与肌肉饱满度。训练前后补充碳水（如燕麦、米饭、红薯）能提升训练表现并促进恢复，每公斤体重 3-5 克是基础范围。脂肪占总热量的 20-30%，优选不饱和脂肪（坚果、鱼油、橄榄油、牛油果），饱和脂肪适度即可。脂肪摄入不足会直接降低睾酮水平，影响增肌效率。'),
            ContentBlock.heading('补水与营养时机'),
            ContentBlock.bulletList('每日 2-3 升水，训练时少量多次补充，避免一次大量饮水\n训练前 1-2 小时摄入碳水餐，提供训练能量\n训练后 30 分钟内补充蛋白 + 碳水，启动恢复\n睡前可摄入酪蛋白（牛奶/希腊酸奶），缓慢释放氨基酸\n不必过度纠结补剂，食物永远是基础，蛋白粉和肌酸是补充'),
          ],
        ),
        Chapter(
          id: 'ch5_recovery',
          title: '第5章：恢复与后续进阶',
          content: '睡眠：每晚7-9小时，肌肉在睡眠中修复生长。\n\n主动恢复：休息日做轻度有氧或拉伸，促进血液循环。\n\n deload周：每4-6周安排一次减量周，重量降至平时的60%，让身体充分恢复。\n\n进阶方向：完成本课程后，可学习分化训练（推拉腿）、力量计划（5x5）等进阶内容。\n\n记住：增肌是马拉松不是短跑，坚持比完美计划更重要。',
          imageEmojis: ['😴', '🧘', '🎯'],
          blocks: [
            ContentBlock.heading('睡眠是最重要的恢复手段'),
            ContentBlock.paragraph('训练只是给肌肉一个生长的信号，真正的修复和生长发生在睡眠中。生长激素的分泌在深睡眠期达到峰值，肌肉蛋白合成速率也显著提升。每晚 7-9 小时是增肌者的底线，少于 6 小时直接削弱训练收益。睡眠不足会降低睾酮、提升皮质醇、影响食欲调控激素（瘦素下降、饥饿素上升），让你更容易暴食、训练无力、肌肉流失。'),
            ContentBlock.callout('连续睡眠不足 6 小时一周，睾酮水平可下降 10-15%，相当于衰老 10 岁。睡眠是不可替代的恢复手段', 'warning'),
            ContentBlock.heading('主动恢复与休息日'),
            ContentBlock.paragraph('休息日不是躺平。做 20-30 分钟轻度有氧（快走、骑车、游泳）或全身拉伸、瑜伽，能促进血液循环、加速代谢废物清除、缓解延迟性肌肉酸痛。完全不动的休息日反而让你感觉更僵硬、第二天训练状态更差。但要注意控制强度——主动恢复的目的是促进循环，不是再加一次训练。'),
            ContentBlock.heading('deload 减量周'),
            ContentBlock.paragraph('每 4-6 周安排一次减量周，重量降至平时的 60%，组数减半，让神经系统和结缔组织充分恢复。这是预防过度训练、突破平台期的关键策略。很多训练者在 deload 后迎来了力量跳升——之前的停滞不是因为练得不够，而是恢复不足。如果你最近 2 周训练表现下降、睡眠变差、心率上升，可能就是身体在呼喊 deload。'),
            ContentBlock.heading('识别过度训练的信号'),
            ContentBlock.paragraph('训练者常见的过度训练信号包括：晨起静息心率上升 5-10 次、握力下降、训练动力降低、睡眠质量变差、小伤口恢复变慢、易感冒。出现这些信号时不要硬撑，主动减量一周胜过死磕一个月。记录每日晨起心率是简单有效的监测手段——长期趋势上升意味着恢复不足，需要立即安排 deload 或彻底休息。营养和睡眠的同步优化，比加练更能突破瓶颈。'),
            ContentBlock.heading('进阶方向'),
            ContentBlock.bulletList('推拉腿分化（每周 6 次），适合中阶训练者追求肌肥大\n力量计划 5x5（每周 3 次），专注大重量复合动作\n上下肢分化（每周 4 次），平衡频率与恢复\n功能训练或专项运动迁移，提升运动表现\n持续学习新动作与技术，避免训练单调'),
            ContentBlock.quote('增肌是马拉松不是短跑，坚持比完美计划更重要。'),
          ],
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
          blocks: [
            ContentBlock.heading('减脂的唯一真理：热量缺口'),
            ContentBlock.paragraph('不管什么饮食法——低碳、低脂、间歇禁食、生酮——减脂的本质都是热量消耗大于摄入。理解这一点，你就不会被各种花哨的饮食概念迷惑，也不会被某些所谓的神奇减脂食物误导。缺口大小决定减脂速度，但过大的缺口会带来肌肉流失、代谢下降、内分泌紊乱，最终引发暴食反弹。减脂不是越快越好，而是越可持续越好。'),
            ContentBlock.heading('合理缺口范围'),
            ContentBlock.paragraph('每日 300-500 大卡缺口，每周减 0.5-1 磅（约 0.25-0.5kg）脂肪为宜。体重下降过快（每周超过 1% 体重）意味着肌肉大量流失，后期反弹风险极高。减脂期必须配合力量训练保肌肉，否则减下来的体重中有相当比例是肌肉，导致代谢进一步下降、体型松垮。蛋白质摄入要提高到每公斤体重 2 克以上，给身体保留肌肉的明确信号。'),
            ContentBlock.callout('缺口超过 1000 大卡会导致代谢适应、内分泌紊乱、暴食反弹。极低热量饮食不是减脂的捷径，而是反弹的起点', 'warning'),
            ContentBlock.heading('计算 TDEE'),
            ContentBlock.paragraph('TDEE（每日总能量消耗）= BMR（基础代谢）× 活动系数。用 Mifflin-St Jeor 公式估算 BMR：男性为 10×体重+6.25×身高-5×年龄+5，女性为 10×体重+6.25×身高-5×年龄-161。再根据训练频率选择活动系数（久坐 1.2、轻度 1.375、中度 1.55、高强度 1.725）。目标摄入 = TDEE - 缺口值。建议每减 3-5kg 体重重新计算一次，因为代谢会随体重下降而降低。'),
            ContentBlock.heading('记录饮食的重要性'),
            ContentBlock.bulletList('前 2 周记录所有入口食物，包括小零食和调料\n使用薄荷健康/MyFitnessPal 等 App 扫码录入\n厨房秤估算食物重量，避免差不多的误差\n特别注意调料、酱汁、饮品的热量，往往被低估\n建立热量直觉后可放松记录，但建议每月回顾一周'),
            ContentBlock.quote('不是吃得更少，而是吃得更准。减脂不是饥饿游戏，而是用科学方法让身体在热量缺口中稳定燃烧脂肪。记录和计算是减脂期的两只眼睛——前者告诉你正在吃什么，后者告诉你应该吃什么。'),
          ],
        ),
        Chapter(
          id: 'cut_ch2_macros',
          title: '第2章：宏量营养素分配',
          content: '蛋白质：每公斤体重1.8-2.4克，减脂期保肌肉的关键。\n\n脂肪：占总热量25-30%，不低于每公斤0.8克，维持激素水平。\n\n碳水：剩余热量分配，训练日多碳水、休息日少碳水。\n\n纤维：每日25-30克，蔬菜为主，增加饱腹感。\n\n水分：每日2-3升，饭前喝水可增加饱腹感。',
          imageEmojis: ['🥩', '🥑', '🍞', '🥦'],
          blocks: [
            ContentBlock.heading('蛋白质——减脂期的守护神'),
            ContentBlock.paragraph('减脂期蛋白质比增肌期更重要。每公斤体重 1.8-2.4 克是合理范围，高蛋白饮食能保肌肉、增饱腹、提升食物热效应——消化蛋白质消耗的热量是碳水的 3 倍。优质来源包括鸡胸肉、鱼虾、鸡蛋清、希腊酸奶、低脂牛奶、瘦牛肉、乳清蛋白粉。每餐保证 25-40 克蛋白质摄入，能在减脂期最大化保留肌肉量，让你减下去的是脂肪而不是肌肉。'),
            ContentBlock.heading('脂肪——不要害怕它'),
            ContentBlock.paragraph('减脂期脂肪摄入不是越低越好。脂肪占总热量的 25-30%，不低于每公斤体重 0.8 克。脂肪过低会导致睾酮下降、皮肤干燥、关节不适、激素紊乱，反而阻碍减脂进程。优选不饱和脂肪：牛油果、坚果（杏仁/核桃）、橄榄油、鱼油。坚决避免反式脂肪（人造奶油、植脂末、部分氢化油），它不仅促进脂肪堆积还危害心血管健康。'),
            ContentBlock.callout('减脂期脂肪降到总热量 20% 以下是常见错误，会损害激素水平。脂肪是睾酮的前体，睾酮低则肌肉流失、代谢下降', 'tip'),
            ContentBlock.heading('碳水的灵活分配'),
            ContentBlock.paragraph('碳水是剩余热量的分配对象。训练日多碳水（提供训练能量、补充糖原）、休息日少碳水（降低总热量）的碳水循环策略，能在保肌肉的同时加速减脂。优质碳水来源包括燕麦、糙米、红薯、全麦面包、藜麦、土豆。避免精制糖和精制碳水（白面包、糕点、含糖饮料），它们 GI 高、饱腹感差、容易引起血糖波动和暴食。'),
            ContentBlock.heading('纤维与水分'),
            ContentBlock.bulletList('每日 25-30 克纤维，蔬菜为主（绿叶菜、西兰花、蘑菇）\n蔬菜热量极低可大量吃，是减脂期的饱腹神器\n每日 2-3 升水，水分参与脂肪代谢\n饭前 500ml 水可增加饱腹感、减少进食量\n坚决避免含糖饮料和果汁，液体热量是减脂最大的陷阱'),
            ContentBlock.heading('营养时机的实战建议'),
            ContentBlock.paragraph('早餐吃足蛋白质启动肌肉合成，训练前 1-2 小时摄入碳水提供能量，训练后 30 分钟内补充快吸收蛋白 + 碳水启动恢复，睡前可摄入酪蛋白（牛奶/希腊酸奶）缓慢释放氨基酸。这些细节不是必须严格遵守的法则，但在减脂后期低热量状态下，优化时机能让有限的营养发挥最大效果。在热量缺口中，每一次营养摄入都值得被认真对待。'),
          ],
        ),
        Chapter(
          id: 'cut_ch3_food',
          title: '第3章：食材选择与替代',
          content: '优质蛋白：鸡胸肉、鱼虾、蛋白、瘦牛肉、希腊酸奶。\n\n优质碳水：燕麦、糙米、红薯、全麦面包。\n\n优质脂肪：牛油果、坚果、橄榄油、鱼油。\n\n避坑食物：含糖饮料、深加工食品、油炸食品、精制碳水。\n\n外食技巧：选烤/蒸/煮而非炸，酱料分开蘸，先吃菜再吃肉最后吃主食。',
          imageEmojis: ['🍗', '🐟', '🥑', '⚠️'],
          blocks: [
            ContentBlock.heading('优质蛋白清单'),
            ContentBlock.paragraph('鸡胸肉（每 100g 31g 蛋白、165 大卡）是减脂期性价比之王，便宜、易得、好烹饪。鱼虾低脂高蛋白，三文鱼虽脂肪略高但富含 Omega-3，能降低炎症、改善胰岛素敏感性。鸡蛋清是纯蛋白质零碳水的代表，一个蛋清约 3.6g 蛋白。瘦牛肉富含肌酸和铁，适合训练量大的人。希腊酸奶是加餐首选，蛋白含量是普通酸奶的 2-3 倍。'),
            ContentBlock.heading('优质碳水清单'),
            ContentBlock.paragraph('燕麦饱腹感强、GI 低，β-葡聚糖有助于控制血糖。糙米比白米多 3 倍纤维和 B 族维生素。红薯富含 β-胡萝卜素和膳食纤维，甜度适中。全麦面包比白面包 GI 低，但要警惕伪全麦产品（看配料表第一位是否是全麦粉）。土豆饱腹感指数最高，蒸煮方式最佳，油炸或做成土豆泥会显著提升热量与 GI。'),
            ContentBlock.heading('优质脂肪清单'),
            ContentBlock.bulletList('牛油果（每半个 15g 脂肪、160 大卡），单不饱和脂肪丰富\n坚果（杏仁/核桃每天 30g），富含镁和维生素 E\n橄榄油（凉拌或低温烹饪），避免高温破坏营养\n鱼油（EPA+DHA 每日 2-3g），降低炎症、保护心血管\n亚麻籽（富含 ALA），研磨后食用更易吸收'),
            ContentBlock.callout('避坑：含糖饮料、深加工食品、油炸食品、精制碳水是减脂杀手。一罐可乐含 35g 糖，相当于一块蛋糕的热量', 'warning'),
            ContentBlock.heading('外食技巧'),
            ContentBlock.paragraph('外食时选烤/蒸/煮而非炸，酱料分开蘸能少一半热量。先吃菜再吃肉最后吃主食，可降低血糖波动、增加饱腹感。火锅选清汤锅底，避开丸子类加工食品（多数是淀粉和肥肉）。日料比中餐更适合减脂期——刺身、寿司（少饭）、味噌汤都是不错的选择。聚餐前先吃个鸡蛋或喝杯酸奶垫底，能显著减少外食时的暴食概率。'),
            ContentBlock.heading('日常采购与备餐'),
            ContentBlock.paragraph('减脂期的食材管理同样关键。建议每周固定一天集中采购，按 meal prep（备餐）思路批量烹饪 3-4 天的份量，分装冷藏。这样能避免临时决策导致的外卖和暴食，也让你对每天摄入的热量和宏量营养素更有掌控。备餐的核心是蛋白质 + 复杂碳水 + 蔬菜的固定组合，再通过调料和烹饪方式变化保持新鲜感，让减脂期饮食既科学又不乏味。'),
          ],
        ),
        Chapter(
          id: 'cut_ch4_plateau',
          title: '第4章：平台期突破与维持',
          content: '平台期原因：代谢适应、水分波动、热量计算误差。\n\n突破策略：重新计算TDEE、增加非运动消耗（NEAT）、安排饮食休息日（refeed）。\n\n不要：盲目继续削减热量至极低水平，会导致暴食反弹。\n\n达到目标后：用2-4周反向饮食，每周增加100大卡直至维持热量。\n\n长期维持：建立可持续的饮食习惯，允许20%的灵活食物，避免非黑即白思维。',
          imageEmojis: ['🔄', '📈', '⚖️'],
          blocks: [
            ContentBlock.heading('为什么会遇到平台期'),
            ContentBlock.paragraph('体重下降后基础代谢随之降低——每减 1kg 体重约减少 15-20 大卡 TDEE，10kg 就是 150-200 大卡。同时身体会进入节能模式主动降低 NEAT（非运动消耗），你下意识少动、少抖腿、少走动。再加上水分波动和热量计算误差（多数人会低估 20-30%），平台期是减脂的必然阶段，遇到它不意味着失败，而是身体在适应新体重。'),
            ContentBlock.heading('突破平台期的策略'),
            ContentBlock.bulletList('重新计算 TDEE（体重已下降，原公式已过时）\n增加非运动消耗（多走路、站立办公、爬楼梯）\n安排饮食休息日 refeed（每周 1 天吃维持热量）\n增加训练容量（每动作多 1 组）或强度（重量）\n检查是否有隐藏热量摄入（坚果、橄榄油、酱料）'),
            ContentBlock.callout('不要盲目继续削减热量至极低水平（低于 BMR），会导致暴食反弹、代谢进一步下降、内分泌紊乱', 'warning'),
            ContentBlock.heading('达到目标后的反向饮食'),
            ContentBlock.paragraph('减脂结束后不要立即恢复原饮食，用 2-4 周反向饮食——每周增加 100 大卡直至维持热量。这能让代谢缓慢适应，避免脂肪快速反弹。反向饮食期间体重可能微增，但大部分是水分和糖原，不是脂肪。这是减脂成功的最后一公里，跳过它等于把前面 12 周的成果拱手送回。'),
            ContentBlock.paragraph('反向饮食期间建议同时增加训练容量（每动作多 1-2 组），将多出的热量用于肌肉合成而非脂肪储存。配合力量训练，反向饮食甚至可能带来小幅肌肉增长，让体型在维持期进一步紧致。这是减脂成功后从瘦到壮的关键过渡期，跳过它直接进入维持期，代谢会卡在低点数月难以恢复，反弹风险显著上升。'),
            ContentBlock.heading('长期维持的理念'),
            ContentBlock.paragraph('建立可持续的饮食习惯比追求完美更重要。允许 20% 的灵活食物（每周 3-4 餐自由吃），避免非黑即白的思维——一次暴食不代表失败，关键是长期趋势。坚持力量训练维持肌肉量，肌肉是代谢的引擎——同样体重的肌肉比脂肪每天多消耗 6-10 大卡，肌肉量高的人维持期更容易。把减脂视为生活方式的转变，而非一次性的战役。'),
            ContentBlock.quote('减脂不是一场战役，而是一种生活方式的转变。'),
          ],
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
