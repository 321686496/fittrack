import '../l10n/i18n.dart';
class MockData {
  // ============================================================
  // User
  // ============================================================
  static Map<String, dynamic> get user => _userMemo.value;
  static final LocaleMemo<Map<String, dynamic>> _userMemo = LocaleMemo(() => {
    'name': trn('健身达人'),
    'level': 8,
    'title': trn('进阶训练者'),
    'points': 1280,
    'avatar': 'FP',
    'totalTrainings': 30,
    'totalDuration': '40h',
  });

  // ============================================================
  // TodayPlan
  // ============================================================
  static Map<String, dynamic> get todayPlan => _todayPlanMemo.value;
  static final LocaleMemo<Map<String, dynamic>> _todayPlanMemo = LocaleMemo(() => {
    'name': trn('背部 + 二头肌训练'),
    'muscle': trn('背阔肌 / 肱二头肌'),
    'duration': 65,
    'exerciseCount': 6,
    'completed': 2,
    'exercises': [
      {'id': 'ex1', 'name': trn('引体向上'), 'sets': 4, 'reps': '8-12', 'restTime': 90, 'completed': true},
      {'id': 'ex2', 'name': trn('杠铃划船'), 'sets': 4, 'reps': '8-12', 'restTime': 90, 'completed': true},
      {'id': 'ex3', 'name': trn('高位下拉'), 'sets': 4, 'reps': '12', 'restTime': 90, 'currentSet': 3, 'completed': false},
      {'id': 'ex4', 'name': trn('坐姿划船'), 'sets': 3, 'reps': '12', 'restTime': 75, 'completed': false},
      {'id': 'ex5', 'name': trn('哑铃弯举'), 'sets': 4, 'reps': '10-12', 'restTime': 60, 'completed': false},
      {'id': 'ex6', 'name': trn('锤式弯举'), 'sets': 3, 'reps': '12', 'restTime': 60, 'completed': false},
    ],
  });

  // ============================================================
  // WeeklyStats
  // ============================================================
  static final Map<String, dynamic> weeklyStats = {
    'trainings': 4,
    'duration': '6.5h',
    'weight': '12.8t',
    'calories': '1,850',
  };

  // ============================================================
  // WeeklyCalendar
  // ============================================================
  static List<Map<String, dynamic>> get weeklyCalendar => _weeklyCalendarMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _weeklyCalendarMemo = LocaleMemo(() => [
    {'day': trn('一'), 'label': trn('胸+三头'), 'done': true},
    {'day': trn('二'), 'label': trn('背+二头'), 'done': true},
    {'day': trn('三'), 'label': trn('休息日'), 'done': true, 'rest': true},
    {'day': trn('四'), 'label': trn('肩+核心'), 'done': true},
    {'day': trn('五'), 'label': trn('腿部'), 'done': false, 'today': true},
    {'day': trn('六'), 'label': trn('胸+背'), 'done': false},
    {'day': trn('日'), 'label': trn('休息日'), 'done': false, 'rest': true},
  ]);

  // ============================================================
  // Streak
  // ============================================================
  static final Map<String, dynamic> streak = {
    'current': 12,
    'longest': 21,
    'thisMonth': 14,
    'monthTotal': 20,
  };

  // ============================================================
  // Achievements
  // ============================================================
  static List<Map<String, dynamic>> get achievements => _achievementsMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _achievementsMemo = LocaleMemo(() => [
    {'id': 'a1', 'name': trn('初出茅庐'), 'desc': trn('完成第一次训练'), 'icon': '🎯', 'unlocked': true},
    {'id': 'a2', 'name': trn('铁人意志'), 'desc': trn('连续打卡7天'), 'icon': '🔥', 'unlocked': true},
    {'id': 'a3', 'name': trn('百吨俱乐部'), 'desc': trn('累计举起100吨'), 'icon': '💪', 'unlocked': true},
    {'id': 'a4', 'name': trn('马拉松选手'), 'desc': trn('累计训练100小时'), 'icon': '⏱️', 'unlocked': false},
    {'id': 'a5', 'name': trn('千次达人'), 'desc': trn('累计完成1000次动作'), 'icon': '🏆', 'unlocked': false},
    {'id': 'a6', 'name': trn('不倒翁'), 'desc': trn('连续打卡30天'), 'icon': '🛡️', 'unlocked': false},
  ]);

  // ============================================================
  // BodyData
  // ============================================================
  static Map<String, dynamic> get bodyData => _bodyDataMemo.value;
  static final LocaleMemo<Map<String, dynamic>> _bodyDataMemo = LocaleMemo(() => {
    'height': 175,
    'weight': 72.5,
    'bmi': 23.7,
    'bodyFat': 18.5,
    'chest': 98,
    'waist': 80,
    'hip': 96,
    'lastUpdate': trn('3天前'),
  });

  // ============================================================
  // Plans
  // ============================================================
  static List<Map<String, dynamic>> get plans => _plansMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _plansMemo = LocaleMemo(() => [
    {
      'id': 'plan1',
      'name': trn('三分化增肌计划'),
      'status': 'active',
      'frequency': trn('6天/周'),
      'difficulty': trn('进阶'),
      'week': 4,
      'totalWeeks': 8,
      'progress': 75,
      'badge': trn('进行中'),
    },
    {
      'id': 'plan2',
      'name': trn('新手入门计划'),
      'status': 'done',
      'frequency': trn('3天/周'),
      'difficulty': trn('入门'),
      'week': 4,
      'totalWeeks': 4,
      'progress': 100,
      'badge': trn('已完成'),
    },
    {
      'id': 'plan3',
      'name': trn('推拉腿训练计划'),
      'status': 'pending',
      'frequency': trn('6天/周'),
      'difficulty': trn('高级'),
      'week': 0,
      'totalWeeks': 8,
      'progress': 0,
      'badge': trn('待开始'),
    },
  ]);

  // ============================================================
  // ChartData
  // ============================================================
  static Map<String, dynamic> get chartData => _chartDataMemo.value;
  static final LocaleMemo<Map<String, dynamic>> _chartDataMemo = LocaleMemo(() => {
    'weekly': [
      {'label': trn('周一'), 'value': 60},
      {'label': trn('周二'), 'value': 80},
      {'label': trn('周三'), 'value': 40},
      {'label': trn('周四'), 'value': 100},
      {'label': trn('周五'), 'value': 70},
      {'label': trn('周六'), 'value': 90},
      {'label': trn('周日'), 'value': 30},
    ],
  });

  // ============================================================
  // MuscleDistribution
  // ============================================================
  static List<Map<String, dynamic>> get muscleDistribution => _muscleDistributionMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _muscleDistributionMemo = LocaleMemo(() => [
    {'name': trn('背部'), 'pct': 35, 'color': 'accent'},
    {'name': trn('胸部'), 'pct': 28, 'color': 'info'},
    {'name': trn('腿部'), 'pct': 22, 'color': 'success'},
  ]);

  // ============================================================
  // RecentTrainings
  // ============================================================
  static List<Map<String, dynamic>> get recentTrainings => _recentTrainingsMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _recentTrainingsMemo = LocaleMemo(() => [
    {'id': 'rt1', 'name': trn('胸部 + 三头肌'), 'date': trn('昨天'), 'duration': '55min', 'calories': 420, 'exercises': 5, 'completed': true},
    {'id': 'rt2', 'name': trn('背部 + 二头肌'), 'date': trn('2天前'), 'duration': '65min', 'calories': 480, 'exercises': 6, 'completed': true},
    {'id': 'rt3', 'name': trn('肩部 + 核心'), 'date': trn('3天前'), 'duration': '45min', 'calories': 350, 'exercises': 5, 'completed': true},
  ]);

  // ============================================================
  // DailyTip
  // ============================================================
  static Map<String, dynamic> get dailyTip => _dailyTipMemo.value;
  static final LocaleMemo<Map<String, dynamic>> _dailyTipMemo = LocaleMemo(() => {
    'text': trn('训练后30分钟内补充蛋白质，能最大化肌肉修复与生长效果。'),
    'category': trn('营养建议'),
  });

  // ============================================================
  // PersonalRecords
  // ============================================================
  static List<Map<String, dynamic>> get personalRecords => _personalRecordsMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _personalRecordsMemo = LocaleMemo(() => [
    {'name': trn('卧推'), 'weight': '80kg', 'date': '2025-05-15'},
    {'name': trn('深蹲'), 'weight': '100kg', 'date': '2025-05-12'},
    {'name': trn('硬拉'), 'weight': '120kg', 'date': '2025-05-10'},
  ]);

  // ============================================================
  // Categories
  // ============================================================
  static List<String> get categories => _categoriesMemo.value;
  static final LocaleMemo<List<String>> _categoriesMemo = LocaleMemo(() => [
    trn('全部'),
    trn('胸部'),
    trn('背部'),
    trn('腿部'),
    trn('肩部'),
    trn('手臂'),
    trn('核心'),
    trn('跑步'),
  ]);

  // ============================================================
  // Exercises (16 exercises)
  // ============================================================
  static List<Map<String, dynamic>> get exercises => _exercisesMemo.value;
  static final LocaleMemo<List<Map<String, dynamic>>> _exercisesMemo = LocaleMemo(() => [
    {'id': 'e1', 'name': trn('杠铃卧推'), 'category': trn('胸部'), 'equip': trn('杠铃'), 'image': 'assets/images/exercises/e1_barbell_bench_press_preview.png'},
    {'id': 'e2', 'name': trn('哑铃飞鸟'), 'category': trn('胸部'), 'equip': trn('哑铃'), 'image': 'assets/images/exercises/e2_dumbbell_fly_preview.png'},
    {'id': 'e3', 'name': trn('上斜卧推'), 'category': trn('胸部'), 'equip': trn('杠铃'), 'image': 'assets/images/exercises/e3_incline_bench_press_preview.png'},
    {'id': 'e4', 'name': trn('绳索夹胸'), 'category': trn('胸部'), 'equip': trn('器械'), 'image': 'assets/images/exercises/e4_cable_crossover_preview.png'},
    {'id': 'e5', 'name': trn('引体向上'), 'category': trn('背部'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e5_pull-up_preview.png'},
    {'id': 'e6', 'name': trn('杠铃划船'), 'category': trn('背部'), 'equip': trn('杠铃'), 'image': 'assets/images/exercises/e6_barbell_row_preview.png'},
    {'id': 'e7', 'name': trn('高位下拉'), 'category': trn('背部'), 'equip': trn('器械'), 'image': 'assets/images/exercises/e7_lat_pulldown_preview.png'},
    {'id': 'e8', 'name': trn('坐姿划船'), 'category': trn('背部'), 'equip': trn('器械'), 'image': 'assets/images/exercises/e8_seated_cable_row_preview.png'},
    {'id': 'e9', 'name': trn('杠铃深蹰'), 'category': trn('腿部'), 'equip': trn('杠铃'), 'image': 'assets/images/exercises/e9_barbell_squat_preview.png'},
    {'id': 'e10', 'name': trn('腿举'), 'category': trn('腿部'), 'equip': trn('器械'), 'image': 'assets/images/exercises/e10_leg_press_preview.png'},
    {'id': 'e11', 'name': trn('哑铃推举'), 'category': trn('肩膀'), 'equip': trn('哑铃'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_preview.png'},
    {'id': 'e12', 'name': trn('侧平举'), 'category': trn('肩膀'), 'equip': trn('哑铃'), 'image': 'assets/images/exercises/e12_lateral_raise_preview.png'},
    {'id': 'e13', 'name': trn('哑铃弯举'), 'category': trn('手臂'), 'equip': trn('哑铃'), 'image': 'assets/images/exercises/e13_dumbbell_curl_preview.png'},
    {'id': 'e14', 'name': trn('锤式弯举'), 'category': trn('手臂'), 'equip': trn('哑铃'), 'image': 'assets/images/exercises/e14_hammer_curl_preview.png'},
    {'id': 'e15', 'name': trn('平板支撑'), 'category': trn('核心'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e15_plank_preview.png'},
    {'id': 'e16', 'name': trn('卷腹'), 'category': trn('核心'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e16_crunch_preview.png'},
    {'id': 'e17', 'name': trn('慢跑'), 'category': trn('跑步'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e17_jogging_preview.png'},
    {'id': 'e18', 'name': trn('间歇跑'), 'category': trn('跑步'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e18_interval_run_preview.png'},
    {'id': 'e19', 'name': trn('长距离跑'), 'category': trn('跑步'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e19_long_distance_run_preview.png'},
    {'id': 'e20', 'name': trn('冲刺跑'), 'category': trn('跑步'), 'equip': trn('自重'), 'image': 'assets/images/exercises/e20_sprint_preview.png'},
    {'id': 'e21', 'name': trn('坡度跑'), 'category': trn('跑步'), 'equip': trn('跑步机'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_preview.png'},
  ]);

  // ============================================================
  // Exercise descriptions
  // ============================================================
  static Map<String, String> get exerciseDescriptions => _exerciseDescriptionsMemo.value;
  static final LocaleMemo<Map<String, String>> _exerciseDescriptionsMemo = LocaleMemo(() => {
    'e1': trn('平板杠铃卧推是胸部训练的王牌动作，主要刺激胸大肌中部，同时锻炼三角肌前束和肱三头肌。'),
    'e2': trn('哑铃飞鸟重点拉伸胸大肌，增加胸部肌肉的伸展范围，适合作为卧推的辅助动作。'),
    'e3': trn('上斜卧推主要针对胸大肌上部，帮助塑造饱满的上胸线条。'),
    'e4': trn('绳索夹胸提供持续张力，有效孤立胸大肌，适合作为收尾动作。'),
    'e5': trn('引体向上是背部训练的黄金动作，主要锻炼背阔肌和肱二头肌。'),
    'e6': trn('杠铃划船全面刺激背部肌群，特别是背阔肌中下部和菱形肌。'),
    'e7': trn('高位下拉模拟引体向上动作，适合无法完成引体向上的训练者。'),
    'e8': trn('坐姿划船重点锻炼背部中部肌群，改善体态和背部厚度。'),
    'e9': trn('深蹲是腿部训练之王，全面刺激股四头肌、臀大肌和核心肌群。'),
    'e10': trn('腿举机可以安全地使用大重量训练腿部，主要锻炼股四头肌和臀大肌。'),
    'e11': trn('哑铃推举主要锻炼三角肌中束和前束，是肩部训练的核心动作。'),
    'e12': trn('侧平举孤立刺激三角肌中束，帮助打造宽阔的肩膀。'),
    'e13': trn('哑铃弯举是肱二头肌的经典训练动作，简单有效。'),
    'e14': trn('锤式弯举同时锻炼肱二头肌和肱桡肌，增加手臂整体围度。'),
    'e15': trn('平板支撑是核心训练的基础动作，锻炼腹横肌和深层稳定肌群。'),
    'e16': trn('卷腹重点刺激腹直肌上部，是腹部训练的最基本动作。'),
    'e17': trn('慢跑是低强度有氧运动，适合热身、恢复和燃脂，能有效提升心肺功能。'),
    'e18': trn('间歇跑通过高低强度交替，提升心肺耐力和燃脂效率，适合进阶训练者。'),
    'e19': trn('长距离跑培养持久耐力，锻炼心肺功能和下肢肌肉耐力，适合马拉松备战。'),
    'e20': trn('冲刺跑发展爆发力和速度，全面刺激快肌纤维，提升无氧能力。'),
    'e21': trn('坡度跑模拟上坡跑步，强化臀部和股四头肌，同时提升心肺负荷。'),
  });

  // ============================================================
  // Exercise muscles
  // ============================================================
  static Map<String, List<String>> get exerciseMuscles => _exerciseMusclesMemo.value;
  static final LocaleMemo<Map<String, List<String>>> _exerciseMusclesMemo = LocaleMemo(() => {
    'e1': [trn('胸大肌'), trn('三角肌前束'), trn('肱三头肌')],
    'e2': [trn('胸大肌'), trn('三角肌前束')],
    'e3': [trn('胸大肌上部'), trn('三角肌前束'), trn('肱三头肌')],
    'e4': [trn('胸大肌'), trn('三角肌前束')],
    'e5': [trn('背阔肌'), trn('肱二头肌'), trn('前臂')],
    'e6': [trn('背阔肌'), trn('菱形肌'), trn('肱二头肌')],
    'e7': [trn('背阔肌'), trn('肱二头肌')],
    'e8': [trn('背阔肌中部'), trn('菱形肌'), trn('斜方肌')],
    'e9': [trn('股四头肌'), trn('臀大肌'), trn('核心肌群')],
    'e10': [trn('股四头肌'), trn('臀大肌')],
    'e11': [trn('三角肌中束'), trn('三角肌前束'), trn('肱三头肌')],
    'e12': [trn('三角肌中束'), trn('斜方肌上部')],
    'e13': [trn('肱二头肌'), trn('前臂')],
    'e14': [trn('肱二头肌'), trn('肱桡肌'), trn('前臂')],
    'e15': [trn('腹横肌'), trn('深层稳定肌群'), trn('竖脊肌')],
    'e16': [trn('腹直肌'), trn('腹斜肌')],
    'e17': [trn('股四头肌'), trn('小腿肌群'), trn('心肺')],
    'e18': [trn('股四头肌'), trn('臀大肌'), trn('心肺')],
    'e19': [trn('股四头肌'), trn('小腿肌群'), trn('心肺')],
    'e20': [trn('股四头肌'), trn('臀大肌'), trn('心肺')],
    'e21': [trn('臀大肌'), trn('股四头肌'), trn('小腿肌群')],
  });

  // ============================================================
  // Exercise training steps (with images)
  // ============================================================
  static Map<String, List<Map<String, dynamic>>> get exerciseSteps => _exerciseStepsMemo.value;
  static final LocaleMemo<Map<String, List<Map<String, dynamic>>>> _exerciseStepsMemo = LocaleMemo(() => {
    'e1': [
      {'title': trn('准备姿势'), 'desc': trn('仰卧于平凳上，双脚踩实地面，肩胛骨后缩下沉，挺胸收腹。双手正握杠铃，握距略宽于肩，腕关节保持中立位，肘关节微屈。'), 'image': 'assets/images/exercises/e1_barbell_bench_press_step1.png', 'keyPoses': [trn('肩胛骨始终保持后缩下沉，不塌肩'), trn('双脚踩实地面，臀部贴紧凳面'), trn('腕关节保持中立，不后翻')]},
      {'title': trn('离心下放'), 'desc': trn('控制杠铃沿垂直轨迹缓慢下放至胸大肌下缘（乳头连线），肘关节与躯干约呈75度角，下放过程吸气，全程保持张力。'), 'image': 'assets/images/exercises/e1_barbell_bench_press_step2.png', 'keyPoses': [trn('杠铃轨迹垂直于肩关节正上方'), trn('肘关节约75度，不外展过大'), trn('离心过程2-3秒控制')]},
      {'title': trn('底端触胸'), 'desc': trn('杠铃轻触胸部后停顿0.5-1秒，不反弹借力，臀部不离凳，双脚不挪动，保持肩胛稳定，准备发力推起。'), 'image': 'assets/images/exercises/e1_barbell_bench_press_step3.png', 'keyPoses': [trn('轻触胸部不反弹借力'), trn('臀部贴紧凳面不离开')]},
      {'title': trn('向心推起'), 'desc': trn('胸大肌主动发力，沿原轨迹垂直上推，肘部同步伸直，推起过程呼气，避免肩胛前引，保持挺胸。'), 'image': 'assets/images/exercises/e1_barbell_bench_press_step4.png', 'keyPoses': [trn('胸肌主动发力推起'), trn('肩胛保持后缩不前引')]},
      {'title': trn('顶端锁定'), 'desc': trn('推至手臂自然伸直（不锁死肘关节），杠铃位于肩关节正上方，肩胛保持后缩下沉，完成一次重复，准备下次下放。'), 'image': 'assets/images/exercises/e1_barbell_bench_press_step5.png', 'keyPoses': [trn('肘关节不锁死'), trn('杠铃锁定于肩关节正上方')]},
    ],
    'e2': [
      {'title': trn('准备姿势'), 'desc': trn('仰卧于平凳上，双脚踩实地面，肩胛骨后缩下沉贴凳。双手持哑铃于胸部正上方伸直，掌心相对，肘关节微屈约20-30度并固定角度。'), 'image': 'assets/images/exercises/e2_dumbbell_fly_step1.png', 'keyPoses': [trn('肩胛贴凳不耸肩'), trn('肘关节微屈角度全程固定')]},
      {'title': trn('离心展开'), 'desc': trn('保持肘关节固定角度，沿弧线缓慢向两侧打开哑铃，感受胸大肌拉伸，下放至与肩同高或略低，下放过程吸气。'), 'image': 'assets/images/exercises/e2_dumbbell_fly_step2.png', 'keyPoses': [trn('肘关节角度全程固定'), trn('弧线轨迹下放')]},
      {'title': trn('底端拉伸'), 'desc': trn('哑铃下放至与肩同高，胸大肌充分拉伸，停顿1秒感受拉伸感，不追求过大活动度以免肩关节受伤，保持肩胛贴凳。'), 'image': 'assets/images/exercises/e2_dumbbell_fly_step3.png', 'keyPoses': [trn('底端停顿感受拉伸'), trn('不超肩关节活动度')]},
      {'title': trn('向心合拢'), 'desc': trn('胸大肌发力沿弧线将哑铃合拢至起始位置，呼气，顶峰收缩1-2秒，想象抱住一棵大树，肩胛保持稳定。'), 'image': 'assets/images/exercises/e2_dumbbell_fly_step4.png', 'keyPoses': [trn('胸肌发力弧线合拢'), trn('顶峰收缩1-2秒')]},
      {'title': trn('顶端收拢'), 'desc': trn('哑铃回到胸部正上方，掌心相对，肘关节保持微屈，肩胛稳定贴凳，完成一次重复，注意哑铃不互相碰撞。'), 'image': 'assets/images/exercises/e2_dumbbell_fly_step5.png', 'keyPoses': [trn('顶端哑铃不触碰碰撞'), trn('肩胛贴凳稳定')]},
    ],
    'e3': [
      {'title': trn('准备姿势'), 'desc': trn('调节上斜凳至30-45度，仰卧于凳上，双脚踩实地面，肩胛后缩下沉，挺胸。双手正握杠铃，握距略宽于肩，腕关节中立。'), 'image': 'assets/images/exercises/e3_incline_bench_press_step1.png', 'keyPoses': [trn('凳面角度30-45度'), trn('肩胛后缩下沉贴凳')]},
      {'title': trn('起始位置'), 'desc': trn('双手将杠铃从架上取出，控制杠铃位于锁骨正上方，手臂伸直不锁死，核心收紧稳定，准备下放。'), 'image': 'assets/images/exercises/e3_incline_bench_press_step2.png', 'keyPoses': [trn('杠铃位于锁骨正上方'), trn('核心收紧稳定')]},
      {'title': trn('离心下放'), 'desc': trn('控制杠铃沿斜上方轨迹下放至上胸部（锁骨下缘），肘关节约呈60-75度，吸气，保持张力不自由落体。'), 'image': 'assets/images/exercises/e3_incline_bench_press_step3.png', 'keyPoses': [trn('杠铃下放至上胸部'), trn('肘关节约60-75度')]},
      {'title': trn('向心推起'), 'desc': trn('上胸大肌发力将杠铃沿原轨迹斜上推起，呼气，肘部同步伸直，肩胛保持稳定不前引，挺胸收腹。'), 'image': 'assets/images/exercises/e3_incline_bench_press_step4.png', 'keyPoses': [trn('上胸主动发力'), trn('肩胛稳定不前引')]},
      {'title': trn('顶端锁定'), 'desc': trn('推至手臂自然伸直（不锁死），杠铃回到锁骨正上方，完成一次重复，注意角度过大会变平板卧推。'), 'image': 'assets/images/exercises/e3_incline_bench_press_step5.png', 'keyPoses': [trn('顶端不锁死'), trn('角度保持30-45度')]},
    ],
    'e4': [
      {'title': trn('准备姿势'), 'desc': trn('站于绳索机双侧滑轮之间，双脚前后弓步站立稳定重心，双手握住D型把手，身体微前倾，挺胸收腹，核心收紧。'), 'image': 'assets/images/exercises/e4_cable_crossover_step1.png', 'keyPoses': [trn('弓步站位稳定重心'), trn('挺胸收腹身体微前倾')]},
      {'title': trn('起始位置'), 'desc': trn('双臂展开略低于肩，肘关节微屈固定角度，掌心朝前，肩胛后缩下沉，核心收紧准备发力夹胸。'), 'image': 'assets/images/exercises/e4_cable_crossover_step2.png', 'keyPoses': [trn('肘关节微屈角度固定'), trn('肩胛后缩下沉')]},
      {'title': trn('离心上送'), 'desc': trn('控制把手缓慢回放至双臂展开位，胸大肌充分拉伸，肘关节角度不变，吸气，保持张力不甩动。'), 'image': 'assets/images/exercises/e4_cable_crossover_step3.png', 'keyPoses': [trn('控制回放保持张力'), trn('肘关节角度不变')]},
      {'title': trn('向心夹胸'), 'desc': trn('胸大肌发力将把手向胸前下方弧线夹拢，肘部引导，呼气，在胸前交汇处顶峰收缩2秒，感受胸肌挤压。'), 'image': 'assets/images/exercises/e4_cable_crossover_step4.png', 'keyPoses': [trn('弧线夹拢肘部引导'), trn('胸前交汇顶峰收缩2秒')]},
      {'title': trn('顶端收拢'), 'desc': trn('双手在胸前交汇后保持收缩1-2秒，肩胛充分后缩，缓慢回放至起始位置，完成一次重复，全程控制。'), 'image': 'assets/images/exercises/e4_cable_crossover_step5.png', 'keyPoses': [trn('交汇处保持收缩'), trn('肩胛充分后缩')]},
    ],
    'e5': [
      {'title': trn('准备姿势'), 'desc': trn('双手正握单杠，握距略宽于肩，身体自然悬垂，核心收紧，肩胛下沉激活背阔肌，避免死悬挂拉伤肩关节。'), 'image': 'assets/images/exercises/e5_pull-up_step1.png', 'keyPoses': [trn('肩胛下沉先激活'), trn('核心收紧避免死悬挂')]},
      {'title': trn('离心下放'), 'desc': trn('从顶端位置控制身体缓慢下放至完全伸展，背阔肌充分拉伸，下放过程2-3秒，保持张力不松手。'), 'image': 'assets/images/exercises/e5_pull-up_step2.png', 'keyPoses': [trn('离心2-3秒控制'), trn('保持张力不松手')]},
      {'title': trn('底端悬挂'), 'desc': trn('身体完全伸展悬垂，肩胛保持下沉不松弛，核心持续收紧，避免惯性摆动，准备背阔肌发力上拉。'), 'image': 'assets/images/exercises/e5_pull-up_step3.png', 'keyPoses': [trn('底端肩胛不松弛'), trn('避免惯性摆动')]},
      {'title': trn('向心上拉'), 'desc': trn('背阔肌发力，肘部向下向后引导，将身体向上拉起，呼气，肘部不外展，避免二头肌过度代偿。'), 'image': 'assets/images/exercises/e5_pull-up_step4.png', 'keyPoses': [trn('背阔肌发力肘部引导'), trn('肘部不外展')]},
      {'title': trn('顶端过杠'), 'desc': trn('拉至下巴超过杠面，背阔肌顶峰收缩1秒，不后仰过多，肩胛充分下回旋后缩，完成一次重复。'), 'image': 'assets/images/exercises/e5_pull-up_step5.png', 'keyPoses': [trn('下巴过杠'), trn('肩胛充分下回旋')]},
    ],
    'e6': [
      {'title': trn('准备姿势'), 'desc': trn('双脚与肩同宽，微屈膝，髋部铰链俯身至上半身接近平行地面，背部保持中立，双手正握杠铃，握距略宽于肩。'), 'image': 'assets/images/exercises/e6_barbell_row_step1.png', 'keyPoses': [trn('背部中立不弓背'), trn('髋部铰链俯身')]},
      {'title': trn('离心下放'), 'desc': trn('控制杠铃沿大腿前侧缓慢下放至手臂自然伸直，背阔肌充分拉伸，下放过程保持背部中立，吸气。'), 'image': 'assets/images/exercises/e6_barbell_row_step2.png', 'keyPoses': [trn('杠铃贴大腿前侧'), trn('背部中立保持')]},
      {'title': trn('起始位置'), 'desc': trn('杠铃悬垂于膝盖下方，手臂自然伸直，肩胛放松下沉，背部平直，重心在足中，准备背部发力上拉。'), 'image': 'assets/images/exercises/e6_barbell_row_step3.png', 'keyPoses': [trn('杠铃位于膝盖下方'), trn('重心在足中')]},
      {'title': trn('向心上拉'), 'desc': trn('背阔肌发力，肘部贴身向后上方拉起杠铃至下腹/肚脐位置，肩胛后缩，呼气，肘部不外展。'), 'image': 'assets/images/exercises/e6_barbell_row_step4.png', 'keyPoses': [trn('杠铃贴身拉至下腹'), trn('肘部贴身不外展')]},
      {'title': trn('顶端收缩'), 'desc': trn('杠铃拉至下腹位置，肩胛充分后缩，背阔肌顶峰收缩1秒，控制下放，完成一次重复，保持背部平直。'), 'image': 'assets/images/exercises/e6_barbell_row_step5.png', 'keyPoses': [trn('肩胛充分后缩'), trn('顶峰收缩1秒')]},
    ],
    'e7': [
      {'title': trn('准备姿势'), 'desc': trn('坐于高位下拉机，双腿固定压板，双手宽握把手（宽于肩），挺胸收腹，躯干微后倾15度，核心收紧。'), 'image': 'assets/images/exercises/e7_lat_pulldown_step1.png', 'keyPoses': [trn('挺胸收腹微后倾'), trn('双腿固定压板')]},
      {'title': trn('离心上送'), 'desc': trn('控制把手缓慢上送至双臂完全伸直，背阔肌充分拉伸，肩胛上回旋放松，上送过程吸气，保持张力。'), 'image': 'assets/images/exercises/e7_lat_pulldown_step2.png', 'keyPoses': [trn('控制上送保持张力'), trn('肩胛上回旋放松')]},
      {'title': trn('起始位置'), 'desc': trn('双臂完全伸直，肩胛上回旋，躯干微后倾，挺胸，核心收紧，准备背阔肌发力下拉把手。'), 'image': 'assets/images/exercises/e7_lat_pulldown_step3.png', 'keyPoses': [trn('双臂完全伸直'), trn('挺胸核心收紧')]},
      {'title': trn('向心下拉'), 'desc': trn('背阔肌发力，肘部引导向下后方压，将把手拉至锁骨/上胸位置，呼气，肩胛下回旋后缩。'), 'image': 'assets/images/exercises/e7_lat_pulldown_step4.png', 'keyPoses': [trn('肘部引导下压'), trn('肩胛下回旋后缩')]},
      {'title': trn('底端收缩'), 'desc': trn('把手拉至锁骨位置，肩胛充分后缩，背阔肌顶峰收缩1秒，不后仰过多，控制还原，完成一次重复。'), 'image': 'assets/images/exercises/e7_lat_pulldown_step5.png', 'keyPoses': [trn('把手拉至锁骨'), trn('肩胛充分后缩')]},
    ],
    'e8': [
      {'title': trn('准备姿势'), 'desc': trn('坐于划船机上，双脚踩实踏板，膝盖微屈，双手握把手，挺胸收腹，脊柱保持中立位，核心收紧稳定。'), 'image': 'assets/images/exercises/e8_seated_cable_row_step1.png', 'keyPoses': [trn('脊柱中立位'), trn('双脚踩实踏板')]},
      {'title': trn('离心前送'), 'desc': trn('控制把手缓慢前送至手臂自然伸直，背阔肌充分拉伸，肩胛前引放松，背部保持平直不弓背，吸气。'), 'image': 'assets/images/exercises/e8_seated_cable_row_step2.png', 'keyPoses': [trn('前送保持背部平直'), trn('肩胛前引放松')]},
      {'title': trn('起始位置'), 'desc': trn('双臂自然伸直，肩胛前引，背部平直，躯干稳定不前后晃动，准备背阔肌发力后拉把手。'), 'image': 'assets/images/exercises/e8_seated_cable_row_step3.png', 'keyPoses': [trn('躯干稳定不晃动'), trn('双臂自然伸直')]},
      {'title': trn('向心后拉'), 'desc': trn('背阔肌发力，肘部贴身向后拉把手至腹部，肩胛后缩，呼气，肘部不外展，躯干不后仰借力。'), 'image': 'assets/images/exercises/e8_seated_cable_row_step4.png', 'keyPoses': [trn('肘部贴身拉至腹部'), trn('躯干不后仰借力')]},
      {'title': trn('顶端收缩'), 'desc': trn('把手拉至腹部，肩胛充分后缩，背阔肌顶峰收缩1秒，控制还原，完成一次重复，保持脊柱中立。'), 'image': 'assets/images/exercises/e8_seated_cable_row_step5.png', 'keyPoses': [trn('肩胛充分后缩'), trn('顶峰收缩1秒')]},
    ],
    'e9': [
      {'title': trn('准备姿势'), 'desc': trn('杠铃置于斜方肌上沿（高杠位），双脚与肩同宽，脚尖略外展15-30度，挺胸收腹，核心收紧，肘部下压。'), 'image': 'assets/images/exercises/e9_barbell_squat_step1.png', 'keyPoses': [trn('杠铃置于斜方肌上沿'), trn('脚尖外展15-30度')]},
      {'title': trn('离心下蹲'), 'desc': trn('髋部后坐同时屈膝下蹲，膝盖沿脚尖方向，背部保持中立，下蹲过程吸气，重心保持在足中位置。'), 'image': 'assets/images/exercises/e9_barbell_squat_step2.png', 'keyPoses': [trn('髋部后坐屈膝'), trn('重心在足中')]},
      {'title': trn('底端平行'), 'desc': trn('下蹲至大腿与地面平行或略低于平行，髋部低于膝盖，保持核心紧绷，背部不圆，膝盖不内扣。'), 'image': 'assets/images/exercises/e9_barbell_squat_step3.png', 'keyPoses': [trn('大腿至少与地面平行'), trn('背部中立不圆')]},
      {'title': trn('向心起立'), 'desc': trn('足中发力，臀部和股四头肌同步发力站起，呼气，膝盖不内扣，保持外展与脚尖方向一致。'), 'image': 'assets/images/exercises/e9_barbell_squat_step4.png', 'keyPoses': [trn('足中发力站起'), trn('膝盖不内扣')]},
      {'title': trn('顶端锁定'), 'desc': trn('站起至髋膝完全伸展（不锁死膝关节），核心收紧，挺胸，完成一次重复，注意全程背部中立。'), 'image': 'assets/images/exercises/e9_barbell_squat_step5.png', 'keyPoses': [trn('膝关节不锁死'), trn('核心收紧挺胸')]},
    ],
    'e10': [
      {'title': trn('准备姿势'), 'desc': trn('坐于腿举机，背部紧贴靠垫，双脚与肩同宽放在踏板中上部，脚尖略外展，双手握两侧把手稳定身体。'), 'image': 'assets/images/exercises/e10_leg_press_step1.png', 'keyPoses': [trn('双脚与肩宽踏板中上部'), trn('背部紧贴靠垫')]},
      {'title': trn('离心下放'), 'desc': trn('控制踏板缓慢下放至大腿贴近胸部（膝关节约90度），下放过程吸气，核心收紧，膝盖不内扣。'), 'image': 'assets/images/exercises/e10_leg_press_step2.png', 'keyPoses': [trn('下放至膝关节约90度'), trn('膝盖不内扣')]},
      {'title': trn('底端停顿'), 'desc': trn('大腿贴近胸部时停顿0.5-1秒，不弹回，保持核心紧绷，臀部不离靠垫，膝关节不超脚尖。'), 'image': 'assets/images/exercises/e10_leg_press_step3.png', 'keyPoses': [trn('底端停顿不弹回'), trn('臀部不离靠垫')]},
      {'title': trn('向心蹬起'), 'desc': trn('足跟发力蹬起踏板，股四头肌和臀大肌同步发力，呼气，保持膝盖与脚尖方向一致不内扣。'), 'image': 'assets/images/exercises/e10_leg_press_step4.png', 'keyPoses': [trn('足跟发力蹬起'), trn('膝盖沿脚尖方向')]},
      {'title': trn('顶端锁定'), 'desc': trn('蹬至腿部接近伸直但不锁死膝关节，保持张力，完成一次重复，注意全程控制不甩动借力。'), 'image': 'assets/images/exercises/e10_leg_press_step5.png', 'keyPoses': [trn('不锁死膝关节'), trn('保持张力不甩动')]},
    ],
    'e11': [
      {'title': trn('准备姿势'), 'desc': trn('坐于哑铃凳（有靠背），双脚踩实，背部贴靠垫，双手持哑铃于肩部两侧，掌心朝前，肘关节略前于躯干。'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_step1.png', 'keyPoses': [trn('背部贴靠垫'), trn('肘关节略前于躯干')]},
      {'title': trn('起始位置'), 'desc': trn('哑铃位于肩部两侧，掌心朝前，肘关节约呈90度，腕关节中立，核心收紧不塌腰，准备三角肌发力。'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_step2.png', 'keyPoses': [trn('腕关节中立'), trn('核心收紧不塌腰')]},
      {'title': trn('离心下放'), 'desc': trn('控制哑铃缓慢下放至肩部两侧，肘关节约90度，三角肌充分拉伸，下放过程吸气，保持核心稳定。'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_step3.png', 'keyPoses': [trn('下放至肘关节90度'), trn('核心稳定不塌腰')]},
      {'title': trn('向心推起'), 'desc': trn('三角肌发力将哑铃沿弧线推过头顶，呼气，肘部同步伸直，腕关节保持中立，不借力晃动。'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_step4.png', 'keyPoses': [trn('三角肌发力推起'), trn('腕关节中立')]},
      {'title': trn('顶端锁定'), 'desc': trn('推至手臂自然伸直（不锁死），哑铃在头顶上方靠近但不触碰，肩胛稳定，完成一次重复。'), 'image': 'assets/images/exercises/e11_dumbbell_shoulder_press_step5.png', 'keyPoses': [trn('肘关节不锁死'), trn('哑铃顶端不碰撞')]},
    ],
    'e12': [
      {'title': trn('准备姿势'), 'desc': trn('站姿，双脚与肩同宽，双手各持哑铃于体侧，掌心朝向大腿，肘关节微屈约10-20度，挺胸收腹，核心收紧。'), 'image': 'assets/images/exercises/e12_lateral_raise_step1.png', 'keyPoses': [trn('肘关节微屈10-20度'), trn('挺胸收腹核心收紧')]},
      {'title': trn('离心下放'), 'desc': trn('控制哑铃从顶端位置缓慢下放至体侧，三角肌中束保持张力，下放过程吸气，不自由落体。'), 'image': 'assets/images/exercises/e12_lateral_raise_step2.png', 'keyPoses': [trn('控制下放保持张力'), trn('不自由落体')]},
      {'title': trn('向心侧举'), 'desc': trn('三角肌中束发力，肘部微屈引导，将哑铃沿弧线向两侧举起，呼气，不耸肩不借力晃动身体。'), 'image': 'assets/images/exercises/e12_lateral_raise_step3.png', 'keyPoses': [trn('肘部引导侧举'), trn('不耸肩不借力')]},
      {'title': trn('顶端停顿'), 'desc': trn('哑铃举至与肩同高（肘部与肩平齐），停顿1秒感受中束收缩，不高于肩避免斜方肌过度代偿。'), 'image': 'assets/images/exercises/e12_lateral_raise_step4.png', 'keyPoses': [trn('顶端与肩平齐'), trn('停顿1秒感受收缩')]},
      {'title': trn('离心还原'), 'desc': trn('控制哑铃缓慢下放至起始位置，下放过程3秒，保持张力，完成一次重复，全程不晃动借力。'), 'image': 'assets/images/exercises/e12_lateral_raise_step5.png', 'keyPoses': [trn('下放3秒控制'), trn('全程不晃动借力')]},
    ],
    'e13': [
      {'title': trn('准备姿势'), 'desc': trn('站姿，双脚与肩同宽，双手各持哑铃自然下垂于体侧，掌心朝前，肘关节微屈并贴紧躯干，挺胸收腹。'), 'image': 'assets/images/exercises/e13_dumbbell_curl_step1.png', 'keyPoses': [trn('肘部贴紧躯干'), trn('挺胸收腹站姿稳定')]},
      {'title': trn('起始位置'), 'desc': trn('哑铃自然下垂于体侧，掌心朝前，肘关节固定贴身，肩胛下沉，核心收紧，准备肱二头肌发力上弯。'), 'image': 'assets/images/exercises/e13_dumbbell_curl_step2.png', 'keyPoses': [trn('肘关节固定贴身'), trn('肩胛下沉')]},
      {'title': trn('向心上弯'), 'desc': trn('肱二头肌发力，将哑铃沿弧线弯举至肩部，呼气，肘关节保持固定不前后移动，腕关节中立。'), 'image': 'assets/images/exercises/e13_dumbbell_curl_step3.png', 'keyPoses': [trn('肘关节固定不移动'), trn('腕关节中立')]},
      {'title': trn('顶端收缩'), 'desc': trn('哑铃弯举至肩部，肱二头肌顶峰收缩1秒，肘部保持贴身，不耸肩，小指可微外旋强化收缩。'), 'image': 'assets/images/exercises/e13_dumbbell_curl_step4.png', 'keyPoses': [trn('顶峰收缩1秒'), trn('肘部贴身不耸肩')]},
      {'title': trn('离心下放'), 'desc': trn('控制哑铃缓慢下放至起始位置，下放过程2-3秒，肱二头肌保持张力，不甩动借力，完成一次重复。'), 'image': 'assets/images/exercises/e13_dumbbell_curl_step5.png', 'keyPoses': [trn('下放2-3秒控制'), trn('不甩动借力')]},
    ],
    'e14': [
      {'title': trn('准备姿势'), 'desc': trn('站姿，双脚与肩同宽，双手各持哑铃自然下垂于体侧，掌心相对（中立握），肘关节微屈贴身，挺胸收腹。'), 'image': 'assets/images/exercises/e14_hammer_curl_step1.png', 'keyPoses': [trn('掌心相对中立握'), trn('肘部贴身微屈')]},
      {'title': trn('起始位置'), 'desc': trn('哑铃自然下垂，掌心相对，肘关节固定贴身，肩胛下沉，核心收紧，准备肱二头肌和肱桡肌发力。'), 'image': 'assets/images/exercises/e14_hammer_curl_step2.png', 'keyPoses': [trn('肘关节固定贴身'), trn('肩胛下沉')]},
      {'title': trn('向心上弯'), 'desc': trn('肱二头肌和肱桡肌发力，保持掌心相对，将哑铃沿弧线弯举至肩部，呼气，肘部固定不晃动。'), 'image': 'assets/images/exercises/e14_hammer_curl_step3.png', 'keyPoses': [trn('保持掌心相对'), trn('肘部固定不晃动')]},
      {'title': trn('顶端收缩'), 'desc': trn('哑铃弯举至肩部，肱桡肌顶峰收缩1秒，掌心保持相对，肘部贴身不前移，不耸肩借力。'), 'image': 'assets/images/exercises/e14_hammer_curl_step4.png', 'keyPoses': [trn('肱桡肌顶峰收缩1秒'), trn('肘部贴身不前移')]},
      {'title': trn('离心下放'), 'desc': trn('控制哑铃缓慢下放至起始位置，下放过程2-3秒，保持张力，不借力甩动，完成一次重复。'), 'image': 'assets/images/exercises/e14_hammer_curl_step5.png', 'keyPoses': [trn('下放2-3秒控制'), trn('不借力甩动')]},
    ],
    'e15': [
      {'title': trn('准备姿势'), 'desc': trn('俯卧于垫上，双肘弯曲支撑于肩部正下方，前臂平行贴地，双脚并拢脚尖撑地，身体呈一条直线准备。'), 'image': 'assets/images/exercises/e15_plank_step1.png', 'keyPoses': [trn('肘部位于肩部正下方'), trn('双脚并拢脚尖撑地')]},
      {'title': trn('起始位置'), 'desc': trn('核心收紧抬起骨盆，身体从头部到脚跟呈一条直线，臀部不撅起不塌陷，颈部中立不抬头。'), 'image': 'assets/images/exercises/e15_plank_step2.png', 'keyPoses': [trn('身体一条直线'), trn('臀部不撅不塌')]},
      {'title': trn('保持稳定'), 'desc': trn('核心持续收紧，腹部激活，骨盆中立位，肩部远离耳朵，保持均匀呼吸不憋气，维持身体平直。'), 'image': 'assets/images/exercises/e15_plank_step3.png', 'keyPoses': [trn('核心持续收紧'), trn('均匀呼吸不憋气')]},
      {'title': trn('呼吸节奏'), 'desc': trn('保持自然腹式呼吸，吸气时腹部扩张，呼气时腹部收紧，避免憋气导致血压升高，维持稳定。'), 'image': 'assets/images/exercises/e15_plank_step4.png', 'keyPoses': [trn('腹式呼吸节奏'), trn('不憋气')]},
      {'title': trn('结束'), 'desc': trn('缓慢下放膝盖至地面，休息放松，避免突然塌腰，逐步增加保持时间，完成一组训练。'), 'image': 'assets/images/exercises/e15_plank_step5.png', 'keyPoses': [trn('缓慢下放不塌腰'), trn('逐步增加时间')]},
    ],
    'e16': [
      {'title': trn('准备姿势'), 'desc': trn('仰卧于垫上，双腿屈膝约90度，双脚掌着地（或抬腿），双手轻放耳侧，下背部贴紧地面。'), 'image': 'assets/images/exercises/e16_crunch_step1.png', 'keyPoses': [trn('下背部贴紧地面'), trn('双手轻放耳侧不拽头')]},
      {'title': trn('起始位置'), 'desc': trn('骨盆中立，下背贴地，肩胛微离地准备，核心激活，颈部放松不紧张，目视上方方向。'), 'image': 'assets/images/exercises/e16_crunch_step2.png', 'keyPoses': [trn('下背贴地骨盆中立'), trn('颈部放松目视上方')]},
      {'title': trn('向心卷起'), 'desc': trn('腹直肌发力将肩胛骨抬离地面，呼气，脊柱逐节卷起，下背保持贴地，不拽头颈借力。'), 'image': 'assets/images/exercises/e16_crunch_step3.png', 'keyPoses': [trn('腹直肌发力卷起'), trn('下背贴地不拽头颈')]},
      {'title': trn('顶端收缩'), 'desc': trn('肩胛完全离地，腹直肌上部顶峰收缩1-2秒，下背不离开地面，目视膝盖方向，保持呼吸。'), 'image': 'assets/images/exercises/e16_crunch_step4.png', 'keyPoses': [trn('顶峰收缩1-2秒'), trn('下背不离地')]},
      {'title': trn('离心还原'), 'desc': trn('控制肩胛缓慢下放至离地约1厘米（不贴地完全放松），吸气，保持张力，完成一次重复。'), 'image': 'assets/images/exercises/e16_crunch_step5.png', 'keyPoses': [trn('控制下放保持张力'), trn('下放不完全放松')]},
    ],
    'e17': [
      {'title': trn('热身准备'), 'desc': trn('先进行5分钟快走或动态拉伸热身，活动脚踝、膝关节和髋关节，逐步提升心率至目标区间。'), 'image': 'assets/images/exercises/e17_jogging_step1.png', 'keyPoses': [trn('动态热身5分钟'), trn('活动踝膝髋关节')]},
      {'title': trn('起始配速'), 'desc': trn('从快走过渡到慢跑，速度以能正常对话为宜（约60-70%最大心率），身体微前倾，目视前方。'), 'image': 'assets/images/exercises/e17_jogging_step2.png', 'keyPoses': [trn('配速能正常对话'), trn('身体微前倾目视前方')]},
      {'title': trn('保持节奏'), 'desc': trn('保持均匀呼吸（三步一吸两步一呼）和稳定步伐，前脚掌或全脚掌着地，摆臂自然放松，核心收紧。'), 'image': 'assets/images/exercises/e17_jogging_step3.png', 'keyPoses': [trn('呼吸节奏均匀'), trn('核心收紧摆臂放松')]},
      {'title': trn('中段补水'), 'desc': trn('每15-20分钟适量补水（每次100-150ml），保持电解质平衡，注意心率不超过70%最大值。'), 'image': 'assets/images/exercises/e17_jogging_step4.png', 'keyPoses': [trn('定时少量补水'), trn('心率不超70%')]},
      {'title': trn('放松收尾'), 'desc': trn('结束前逐步减速至快走3-5分钟，最后进行下肢静态拉伸（股四头、腘绳、小腿），帮助恢复。'), 'image': 'assets/images/exercises/e17_jogging_step5.png', 'keyPoses': [trn('逐步减速冷身'), trn('下肢静态拉伸')]},
    ],
    'e18': [
      {'title': trn('热身准备'), 'desc': trn('先慢跑5-10分钟热身，动态拉伸下肢，激活臀部和核心，预防拉伤，逐步提升心率准备冲刺。'), 'image': 'assets/images/exercises/e18_interval_run_step1.png', 'keyPoses': [trn('慢跑热身5-10分钟'), trn('动态拉伸激活核心')]},
      {'title': trn('高强度冲刺'), 'desc': trn('以接近全力（85-95%最大心率）冲刺跑30-60秒，摆臂有力，前脚掌着地，保持正确跑姿。'), 'image': 'assets/images/exercises/e18_interval_run_step2.png', 'keyPoses': [trn('85-95%最大心率'), trn('摆臂有力前脚掌着地')]},
      {'title': trn('低强度恢复'), 'desc': trn('冲刺后转入慢跑或快走1-2分钟恢复，心率降至60-70%，保持轻微活动不静止站立。'), 'image': 'assets/images/exercises/e18_interval_run_step3.png', 'keyPoses': [trn('恢复1-2分钟'), trn('心率降至60-70%')]},
      {'title': trn('循环重复'), 'desc': trn('重复冲刺-恢复循环6-8组，全程保持核心稳定，注意跑姿不变形，组间适量补水。'), 'image': 'assets/images/exercises/e18_interval_run_step4.png', 'keyPoses': [trn('6-8组循环'), trn('跑姿不变形')]},
      {'title': trn('放松收尾'), 'desc': trn('完成全部组数后慢走3-5分钟冷身，进行下肢静态拉伸，补充水分和蛋白质，帮助恢复。'), 'image': 'assets/images/exercises/e18_interval_run_step5.png', 'keyPoses': [trn('慢走冷身3-5分钟'), trn('下肢静态拉伸')]},
    ],
    'e19': [
      {'title': trn('充分热身'), 'desc': trn('进行10分钟动态热身，重点活动髋关节、膝关节和踝关节，慢跑过渡激活心肺，避免冷启动受伤。'), 'image': 'assets/images/exercises/e19_long_distance_run_step1.png', 'keyPoses': [trn('动态热身10分钟'), trn('慢跑过渡激活心肺')]},
      {'title': trn('起始配速'), 'desc': trn('以低于目标配速1分钟的速度起步2-3公里，逐步进入匀速区间，避免起跑过快导致后程掉速。'), 'image': 'assets/images/exercises/e19_long_distance_run_step2.png', 'keyPoses': [trn('低于目标配速起步'), trn('逐步进入匀速')]},
      {'title': trn('匀速跑'), 'desc': trn('保持稳定的中等配速，呼吸节奏三步一吸两步一呼，核心稳定，步频170-180步/分钟。'), 'image': 'assets/images/exercises/e19_long_distance_run_step3.png', 'keyPoses': [trn('呼吸节奏稳定'), trn('步频170-180')]},
      {'title': trn('补充水分能量'), 'desc': trn('每15-20分钟补水100-150ml，每45分钟补充能量胶或电解质，防止脱水和糖原耗尽。'), 'image': 'assets/images/exercises/e19_long_distance_run_step4.png', 'keyPoses': [trn('定时补水补能量'), trn('防止糖原耗尽')]},
      {'title': trn('放松收尾'), 'desc': trn('结束前1公里逐步减速，慢走3-5分钟冷身，充分拉伸下肢和髋部，补充碳水蛋白质恢复。'), 'image': 'assets/images/exercises/e19_long_distance_run_step5.png', 'keyPoses': [trn('逐步减速冷身'), trn('充分拉伸恢复')]},
    ],
    'e20': [
      {'title': trn('充分热身'), 'desc': trn('进行充分热身，包括慢跑和动态拉伸，激活臀部和腘绳肌，预防肌肉拉伤，提升神经兴奋性。'), 'image': 'assets/images/exercises/e20_sprint_step1.png', 'keyPoses': [trn('慢跑动态拉伸热身'), trn('激活臀部腘绳肌')]},
      {'title': trn('起跑加速'), 'desc': trn('起跑后前10-20米逐步加速，身体前倾，前脚掌着地，摆臂有力，重心前移保持推进。'), 'image': 'assets/images/exercises/e20_sprint_step2.png', 'keyPoses': [trn('逐步加速身体前倾'), trn('前脚掌着地摆臂有力')]},
      {'title': trn('全力冲刺'), 'desc': trn('加速至最大速度，保持正确跑姿，摆臂幅度大，步频快，前脚掌着地，目视前方不低头。'), 'image': 'assets/images/exercises/e20_sprint_step3.png', 'keyPoses': [trn('最大速度保持跑姿'), trn('步频快摆臂幅度大')]},
      {'title': trn('完全恢复'), 'desc': trn('每组冲刺间充分休息2-3分钟，心率降至60%以下，进行4-6组，确保每组保持最大速度。'), 'image': 'assets/images/exercises/e20_sprint_step4.png', 'keyPoses': [trn('休息2-3分钟'), trn('4-6组保持最大速度')]},
      {'title': trn('放松收尾'), 'desc': trn('完成全部组数后慢跑或慢走5分钟冷身，进行下肢和髋部静态拉伸，防止肌肉僵硬。'), 'image': 'assets/images/exercises/e20_sprint_step5.png', 'keyPoses': [trn('慢走冷身5分钟'), trn('下肢静态拉伸')]},
    ],
    'e21': [
      {'title': trn('调整坡度'), 'desc': trn('将跑步机坡度调整至5-8%，先慢走2分钟适应坡度，身体微前倾，激活臀部准备坡度跑。'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_step1.png', 'keyPoses': [trn('坡度5-8%'), trn('慢走2分钟适应')]},
      {'title': trn('起始配速'), 'desc': trn('从慢走过渡到慢跑，坡度保持5-8%，步伐缩小，前脚掌着地，臀部发力蹬地推进。'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_step2.png', 'keyPoses': [trn('步伐缩小前脚掌着地'), trn('臀部发力蹬地')]},
      {'title': trn('坡度跑'), 'desc': trn('身体微前倾，保持稳定节奏，核心收紧，摆臂幅度略大，呼吸节奏均匀，臀部持续发力。'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_step3.png', 'keyPoses': [trn('身体微前倾'), trn('核心收紧臀部发力')]},
      {'title': trn('平坡恢复'), 'desc': trn('坡度跑1-2分钟后，降低坡度慢跑恢复30-60秒，心率下降后再次提升坡度，交替5-6组。'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_step4.png', 'keyPoses': [trn('交替5-6组'), trn('恢复30-60秒')]},
      {'title': trn('放松收尾'), 'desc': trn('完成全部组数后，坡度归零慢走3-5分钟冷身，拉伸小腿、股四头和臀部，恢复肌肉弹性。'), 'image': 'assets/images/exercises/e21_incline_treadmill_run_step5.png', 'keyPoses': [trn('坡度归零慢走冷身'), trn('拉伸小腿臀部')]},
    ],
  });

  // ============================================================
  // getTodayDate
  // ============================================================
  static String getTodayDate() {
    final now = DateTime.now();
    final weekdays = [trn('日'), trn('一'), trn('二'), trn('三'), trn('四'), trn('五'), trn('六')];
    return trn('${now.year}年${now.month}月${now.day}日 星期${weekdays[now.weekday % 7]}');
  }
}
