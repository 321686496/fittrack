class MockData {
  // ============================================================
  // User
  // ============================================================
  static const Map<String, dynamic> user = {
    'name': '健身达人',
    'level': 8,
    'title': '进阶训练者',
    'points': 1280,
    'avatar': 'FP',
    'totalTrainings': 30,
    'totalDuration': '40h',
  };

  // ============================================================
  // TodayPlan
  // ============================================================
  static const Map<String, dynamic> todayPlan = {
    'name': '背部 + 二头肌训练',
    'muscle': '背阔肌 / 肱二头肌',
    'duration': 65,
    'exerciseCount': 6,
    'completed': 2,
    'exercises': [
      {'id': 'ex1', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90, 'completed': true},
      {'id': 'ex2', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90, 'completed': true},
      {'id': 'ex3', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 90, 'currentSet': 3, 'completed': false},
      {'id': 'ex4', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 75, 'completed': false},
      {'id': 'ex5', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60, 'completed': false},
      {'id': 'ex6', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 60, 'completed': false},
    ],
  };

  // ============================================================
  // WeeklyStats
  // ============================================================
  static const Map<String, dynamic> weeklyStats = {
    'trainings': 4,
    'duration': '6.5h',
    'weight': '12.8t',
    'calories': '1,850',
  };

  // ============================================================
  // WeeklyCalendar
  // ============================================================
  static const List<Map<String, dynamic>> weeklyCalendar = [
    {'day': '一', 'label': '胸+三头', 'done': true},
    {'day': '二', 'label': '背+二头', 'done': true},
    {'day': '三', 'label': '休息日', 'done': true, 'rest': true},
    {'day': '四', 'label': '肩+核心', 'done': true},
    {'day': '五', 'label': '腿部', 'done': false, 'today': true},
    {'day': '六', 'label': '胸+背', 'done': false},
    {'day': '日', 'label': '休息日', 'done': false, 'rest': true},
  ];

  // ============================================================
  // Streak
  // ============================================================
  static const Map<String, dynamic> streak = {
    'current': 12,
    'longest': 21,
    'thisMonth': 14,
    'monthTotal': 20,
  };

  // ============================================================
  // Achievements
  // ============================================================
  static const List<Map<String, dynamic>> achievements = [
    {'id': 'a1', 'name': '初出茅庐', 'desc': '完成第一次训练', 'icon': '🎯', 'unlocked': true},
    {'id': 'a2', 'name': '铁人意志', 'desc': '连续打卡7天', 'icon': '🔥', 'unlocked': true},
    {'id': 'a3', 'name': '百吨俱乐部', 'desc': '累计举起100吨', 'icon': '💪', 'unlocked': true},
    {'id': 'a4', 'name': '马拉松选手', 'desc': '累计训练100小时', 'icon': '⏱️', 'unlocked': false},
    {'id': 'a5', 'name': '千次达人', 'desc': '累计完成1000次动作', 'icon': '🏆', 'unlocked': false},
    {'id': 'a6', 'name': '不倒翁', 'desc': '连续打卡30天', 'icon': '🛡️', 'unlocked': false},
  ];

  // ============================================================
  // BodyData
  // ============================================================
  static const Map<String, dynamic> bodyData = {
    'height': 175,
    'weight': 72.5,
    'bmi': 23.7,
    'bodyFat': 18.5,
    'chest': 98,
    'waist': 80,
    'hip': 96,
    'lastUpdate': '3天前',
  };

  // ============================================================
  // Plans
  // ============================================================
  static const List<Map<String, dynamic>> plans = [
    {
      'id': 'plan1',
      'name': '三分化增肌计划',
      'status': 'active',
      'frequency': '6天/周',
      'difficulty': '进阶',
      'week': 4,
      'totalWeeks': 8,
      'progress': 75,
      'badge': '进行中',
    },
    {
      'id': 'plan2',
      'name': '新手入门计划',
      'status': 'done',
      'frequency': '3天/周',
      'difficulty': '入门',
      'week': 4,
      'totalWeeks': 4,
      'progress': 100,
      'badge': '已完成',
    },
    {
      'id': 'plan3',
      'name': '推拉腿训练计划',
      'status': 'pending',
      'frequency': '6天/周',
      'difficulty': '高级',
      'week': 0,
      'totalWeeks': 8,
      'progress': 0,
      'badge': '待开始',
    },
  ];

  // ============================================================
  // ChartData
  // ============================================================
  static const Map<String, dynamic> chartData = {
    'weekly': [
      {'label': '周一', 'value': 60},
      {'label': '周二', 'value': 80},
      {'label': '周三', 'value': 40},
      {'label': '周四', 'value': 100},
      {'label': '周五', 'value': 70},
      {'label': '周六', 'value': 90},
      {'label': '周日', 'value': 30},
    ],
  };

  // ============================================================
  // MuscleDistribution
  // ============================================================
  static const List<Map<String, dynamic>> muscleDistribution = [
    {'name': '背部', 'pct': 35, 'color': 'accent'},
    {'name': '胸部', 'pct': 28, 'color': 'info'},
    {'name': '腿部', 'pct': 22, 'color': 'success'},
  ];

  // ============================================================
  // RecentTrainings
  // ============================================================
  static const List<Map<String, dynamic>> recentTrainings = [
    {'id': 'rt1', 'name': '胸部 + 三头肌', 'date': '昨天', 'duration': '55min', 'calories': 420, 'exercises': 5, 'completed': true},
    {'id': 'rt2', 'name': '背部 + 二头肌', 'date': '2天前', 'duration': '65min', 'calories': 480, 'exercises': 6, 'completed': true},
    {'id': 'rt3', 'name': '肩部 + 核心', 'date': '3天前', 'duration': '45min', 'calories': 350, 'exercises': 5, 'completed': true},
  ];

  // ============================================================
  // DailyTip
  // ============================================================
  static const Map<String, dynamic> dailyTip = {
    'text': '训练后30分钟内补充蛋白质，能最大化肌肉修复与生长效果。',
    'category': '营养建议',
  };

  // ============================================================
  // PersonalRecords
  // ============================================================
  static const List<Map<String, dynamic>> personalRecords = [
    {'name': '卧推', 'weight': '80kg', 'date': '2025-05-15'},
    {'name': '深蹲', 'weight': '100kg', 'date': '2025-05-12'},
    {'name': '硬拉', 'weight': '120kg', 'date': '2025-05-10'},
  ];

  // ============================================================
  // Categories
  // ============================================================
  static const List<String> categories = [
    '全部',
    '胸部',
    '背部',
    '腿部',
    '肩部',
    '手臂',
    '核心',
  ];

  // ============================================================
  // Exercises (16 exercises)
  // ============================================================
  static const List<Map<String, dynamic>> exercises = [
    {'id': 'e1', 'name': '杠铃卧推', 'category': '胸部', 'equip': '杠铃'},
    {'id': 'e2', 'name': '哑铃飞鸟', 'category': '胸部', 'equip': '哑铃'},
    {'id': 'e3', 'name': '上斜卧推', 'category': '胸部', 'equip': '杠铃'},
    {'id': 'e4', 'name': '绳索夹胸', 'category': '胸部', 'equip': '器械'},
    {'id': 'e5', 'name': '引体向上', 'category': '背部', 'equip': '自重'},
    {'id': 'e6', 'name': '杠铃划船', 'category': '背部', 'equip': '杠铃'},
    {'id': 'e7', 'name': '高位下拉', 'category': '背部', 'equip': '器械'},
    {'id': 'e8', 'name': '坐姿划船', 'category': '背部', 'equip': '器械'},
    {'id': 'e9', 'name': '杠铃深蹲', 'category': '腿部', 'equip': '杠铃'},
    {'id': 'e10', 'name': '腿举', 'category': '腿部', 'equip': '器械'},
    {'id': 'e11', 'name': '哑铃推举', 'category': '肩部', 'equip': '哑铃'},
    {'id': 'e12', 'name': '侧平举', 'category': '肩部', 'equip': '哑铃'},
    {'id': 'e13', 'name': '哑铃弯举', 'category': '手臂', 'equip': '哑铃'},
    {'id': 'e14', 'name': '锤式弯举', 'category': '手臂', 'equip': '哑铃'},
    {'id': 'e15', 'name': '平板支撑', 'category': '核心', 'equip': '自重'},
    {'id': 'e16', 'name': '卷腹', 'category': '核心', 'equip': '自重'},
  ];

  // ============================================================
  // Exercise descriptions
  // ============================================================
  static const Map<String, String> exerciseDescriptions = {
    'e1': '平板杠铃卧推是胸部训练的王牌动作，主要刺激胸大肌中部，同时锻炼三角肌前束和肱三头肌。',
    'e2': '哑铃飞鸟重点拉伸胸大肌，增加胸部肌肉的伸展范围，适合作为卧推的辅助动作。',
    'e3': '上斜卧推主要针对胸大肌上部，帮助塑造饱满的上胸线条。',
    'e4': '绳索夹胸提供持续张力，有效孤立胸大肌，适合作为收尾动作。',
    'e5': '引体向上是背部训练的黄金动作，主要锻炼背阔肌和肱二头肌。',
    'e6': '杠铃划船全面刺激背部肌群，特别是背阔肌中下部和菱形肌。',
    'e7': '高位下拉模拟引体向上动作，适合无法完成引体向上的训练者。',
    'e8': '坐姿划船重点锻炼背部中部肌群，改善体态和背部厚度。',
    'e9': '深蹲是腿部训练之王，全面刺激股四头肌、臀大肌和核心肌群。',
    'e10': '腿举机可以安全地使用大重量训练腿部，主要锻炼股四头肌和臀大肌。',
    'e11': '哑铃推举主要锻炼三角肌中束和前束，是肩部训练的核心动作。',
    'e12': '侧平举孤立刺激三角肌中束，帮助打造宽阔的肩膀。',
    'e13': '哑铃弯举是肱二头肌的经典训练动作，简单有效。',
    'e14': '锤式弯举同时锻炼肱二头肌和肱桡肌，增加手臂整体围度。',
    'e15': '平板支撑是核心训练的基础动作，锻炼腹横肌和深层稳定肌群。',
    'e16': '卷腹重点刺激腹直肌上部，是腹部训练的最基本动作。',
  };

  // ============================================================
  // Exercise muscles
  // ============================================================
  static const Map<String, List<String>> exerciseMuscles = {
    'e1': ['胸大肌', '三角肌前束', '肱三头肌'],
    'e2': ['胸大肌', '三角肌前束'],
    'e3': ['胸大肌上部', '三角肌前束', '肱三头肌'],
    'e4': ['胸大肌', '三角肌前束'],
    'e5': ['背阔肌', '肱二头肌', '前臂'],
    'e6': ['背阔肌', '菱形肌', '肱二头肌'],
    'e7': ['背阔肌', '肱二头肌'],
    'e8': ['背阔肌中部', '菱形肌', '斜方肌'],
    'e9': ['股四头肌', '臀大肌', '核心肌群'],
    'e10': ['股四头肌', '臀大肌'],
    'e11': ['三角肌中束', '三角肌前束', '肱三头肌'],
    'e12': ['三角肌中束', '斜方肌上部'],
    'e13': ['肱二头肌', '前臂'],
    'e14': ['肱二头肌', '肱桡肌', '前臂'],
    'e15': ['腹横肌', '深层稳定肌群', '竖脊肌'],
    'e16': ['腹直肌', '腹斜肌'],
  };

  // ============================================================
  // getTodayDate
  // ============================================================
  static String getTodayDate() {
    final now = DateTime.now();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '${now.year}年${now.month}月${now.day}日 星期${weekdays[now.weekday % 7]}';
  }
}
