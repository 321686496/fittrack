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
  // Exercise training steps (with images)
  // ============================================================
  static const Map<String, List<Map<String, dynamic>>> exerciseSteps = {
    'e1': [
      {'title': '准备姿势', 'desc': '平躺在卧推凳上，双脚踏实地面，双手握杠铃，握距略宽于肩，挺胸收肩胛骨。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20bench%20press%20setup%20position%20gym%20fitness%20illustration&image_size=landscape_4_3'},
      {'title': '下放杠铃', 'desc': '控制杠铃缓慢下放至胸部中段，肘部约呈75度角，保持挺胸。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20bench%20press%20lowering%20phase%20gym%20fitness&image_size=landscape_4_3'},
      {'title': '推起杠铃', 'desc': '胸肌发力将杠铃推起至起始位置，手臂伸直但不锁死，全程保持控制。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20bench%20press%20pushing%20up%20gym%20fitness&image_size=landscape_4_3'},
    ],
    'e2': [
      {'title': '准备姿势', 'desc': '平躺在哑铃凳上，双手各持一只哑铃，手臂伸直于胸部上方，掌心相对。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20fly%20setup%20position%20chest%20exercise&image_size=landscape_4_3'},
      {'title': '展开双臂', 'desc': '保持微弯肘，缓慢向两侧打开哑铃，感受胸肌拉伸，至与肩同高。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20fly%20opening%20arms%20chest%20stretch&image_size=landscape_4_3'},
      {'title': '合拢双臂', 'desc': '胸肌发力将哑铃沿弧线合拢至起始位置，顶峰收缩1-2秒。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20fly%20closing%20arms%20chest%20squeeze&image_size=landscape_4_3'},
    ],
    'e5': [
      {'title': '悬挂准备', 'desc': '双手正握单杠，握距略宽于肩，身体自然悬垂，核心收紧。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=pull%20up%20hanging%20position%20back%20exercise&image_size=landscape_4_3'},
      {'title': '向上拉起', 'desc': '背阔肌发力，将身体向上拉起，直到下巴超过杠面，避免借力摆动。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=pull%20up%20pulling%20up%20back%20muscles&image_size=landscape_4_3'},
      {'title': '缓慢下放', 'desc': '控制身体缓慢下放至起始位置，充分伸展背阔肌，不要直接松手。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=pull%20up%20lowering%20down%20controlled%20back&image_size=landscape_4_3'},
    ],
    'e9': [
      {'title': '准备姿势', 'desc': '将杠铃置于斜方肌上方，双脚与肩同宽，脚尖略外展，挺胸收腹。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20squat%20setup%20position%20leg%20exercise&image_size=landscape_4_3'},
      {'title': '下蹲', 'desc': '臀部后坐下蹲，膝盖沿脚尖方向，大腿至少与地面平行，保持背部挺直。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20squat%20descending%20leg%20exercise&image_size=landscape_4_3'},
      {'title': '站起', 'desc': '脚跟发力站起，臀部和股四头肌同时发力，回到起始位置。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20squat%20standing%20up%20leg%20power&image_size=landscape_4_3'},
    ],
    'e11': [
      {'title': '准备姿势', 'desc': '坐于哑铃凳上，双手各持哑铃于肩部两侧，掌心朝前，挺胸收腹。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20shoulder%20press%20setup%20position&image_size=landscape_4_3'},
      {'title': '上举哑铃', 'desc': '三角肌发力将哑铃举过头顶，手臂伸直但不锁死，保持核心稳定。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20shoulder%20press%20pushing%20up&image_size=landscape_4_3'},
      {'title': '下放哑铃', 'desc': '控制哑铃缓慢下放至肩部两侧，感受三角肌的拉伸。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20shoulder%20press%20lowering%20down&image_size=landscape_4_3'},
    ],
    'e13': [
      {'title': '准备姿势', 'desc': '站姿或坐姿，双手各持哑铃自然下垂于体侧，掌心朝前。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20bicep%20curl%20starting%20position&image_size=landscape_4_3'},
      {'title': '弯举哑铃', 'desc': '肱二头肌发力，将哑铃弯举至肩部，顶峰收缩1秒，避免身体摆动。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20bicep%20curl%20curling%20up&image_size=landscape_4_3'},
      {'title': '缓慢下放', 'desc': '控制哑铃缓慢下放至起始位置，充分伸展肱二头肌。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=dumbbell%20bicep%20curl%20lowering%20down&image_size=landscape_4_3'},
    ],
    'e15': [
      {'title': '准备姿势', 'desc': '俯卧于垫上，双肘弯曲支撑于肩部正下方，双脚并拢脚尖撑地。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=plank%20exercise%20starting%20position%20core&image_size=landscape_4_3'},
      {'title': '保持稳定', 'desc': '收紧核心，身体从头到脚呈一条直线，保持均匀呼吸，避免塌腰或拱背。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=plank%20exercise%20holding%20position%20core%20stability&image_size=landscape_4_3'},
    ],
    'e3': [
      {'title': '准备姿势', 'desc': '躺在上斜凳上（30-45度），双手握杠铃，握距略宽于肩。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=incline%20bench%20press%20setup%20upper%20chest&image_size=landscape_4_3'},
      {'title': '下放与推起', 'desc': '控制杠铃下放至上胸部，然后推起至起始位置，重点感受上胸发力。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=incline%20bench%20press%20pressing%20up%20chest&image_size=landscape_4_3'},
    ],
    'e4': [
      {'title': '准备姿势', 'desc': '站在绳索机前，双手握住绳索把手，身体微前倾。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=cable%20crossover%20fly%20setup%20chest&image_size=landscape_4_3'},
      {'title': '夹胸', 'desc': '胸肌发力将绳索向内夹拢，在胸前交叉，顶峰收缩2秒。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=cable%20crossover%20fly%20squeezing%20chest&image_size=landscape_4_3'},
    ],
    'e6': [
      {'title': '准备姿势', 'desc': '双脚与肩同宽，俯身约45度，双手正握杠铃，挺胸收腹。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20row%20setup%20back%20exercise&image_size=landscape_4_3'},
      {'title': '划船拉起', 'desc': '背部发力将杠铃拉至下胸位置，肩胛骨后缩，顶峰收缩1秒。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=barbell%20row%20pulling%20up%20back%20muscles&image_size=landscape_4_3'},
    ],
    'e7': [
      {'title': '准备姿势', 'desc': '坐于高位下拉机前，双手宽握把手，挺胸收腹。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=lat%20pulldown%20setup%20back%20exercise&image_size=landscape_4_3'},
      {'title': '下拉', 'desc': '背阔肌发力将把手拉至锁骨位置，避免后仰过多，控制还原。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=lat%20pulldown%20pulling%20down%20back&image_size=landscape_4_3'},
    ],
    'e8': [
      {'title': '准备姿势', 'desc': '坐于划船机上，双脚踩踏板，双手握把手，挺胸。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=seated%20cable%20row%20setup%20back&image_size=landscape_4_3'},
      {'title': '划船', 'desc': '背部发力将把手拉至腹部，肩胛骨后缩，缓慢还原。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=seated%20cable%20row%20pulling%20back&image_size=landscape_4_3'},
    ],
    'e10': [
      {'title': '准备姿势', 'desc': '坐于腿举机上，双脚与肩同宽放在踏板中上部，背部紧贴靠垫。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=leg%20press%20setup%20position%20machine&image_size=landscape_4_3'},
      {'title': '蹬起与下放', 'desc': '腿部发力蹬起重量，然后缓慢下放至大腿贴近胸部，膝盖不锁死。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=leg%20press%20pushing%20leg%20exercise&image_size=landscape_4_3'},
    ],
    'e12': [
      {'title': '准备姿势', 'desc': '站姿，双手各持哑铃于体侧，微弯肘。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=lateral%20raise%20setup%20shoulder%20exercise&image_size=landscape_4_3'},
      {'title': '侧平举', 'desc': '三角肌中束发力将哑铃举至与肩同高，缓慢下放，避免耸肩。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=lateral%20raise%20lifting%20shoulder%20deltoid&image_size=landscape_4_3'},
    ],
    'e14': [
      {'title': '准备姿势', 'desc': '站姿，双手各持哑铃于体侧，掌心相对（中立握）。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=hammer%20curl%20setup%20arm%20exercise&image_size=landscape_4_3'},
      {'title': '锤式弯举', 'desc': '保持掌心相对，弯举哑铃至肩部，感受肱桡肌和肱二头肌发力。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=hammer%20curl%20curling%20up%20bicep&image_size=landscape_4_3'},
    ],
    'e16': [
      {'title': '准备姿势', 'desc': '仰卧于垫上，双手轻放耳侧，双腿屈膝脚掌着地。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=crunch%20exercise%20setup%20abs%20core&image_size=landscape_4_3'},
      {'title': '卷腹', 'desc': '腹肌发力将肩胛骨抬离地面，顶峰收缩1秒，缓慢下放。', 'image': 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=crunch%20exercise%20curling%20up%20abs&image_size=landscape_4_3'},
    ],
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
