const MockData = {
  user: {
    name: '健身达人',
    level: 8,
    title: '进阶训练者',
    points: 1280,
    avatar: 'FP',
    totalTrainings: 30,
    totalDuration: '40h',
  },

  todayPlan: {
    name: '背部 + 二头肌训练',
    muscle: '背阔肌 / 肱二头肌',
    duration: 65,
    exerciseCount: 6,
    completed: 2,
    exercises: [
      { id: 'ex1', name: '引体向上', sets: 4, reps: '8-12', restTime: 90, completed: true },
      { id: 'ex2', name: '杠铃划船', sets: 4, reps: '8-12', restTime: 90, completed: true },
      { id: 'ex3', name: '高位下拉', sets: 4, reps: '12', restTime: 90, currentSet: 3, completed: false },
      { id: 'ex4', name: '坐姿划船', sets: 3, reps: '12', restTime: 75, completed: false },
      { id: 'ex5', name: '哑铃弯举', sets: 4, reps: '10-12', restTime: 60, completed: false },
      { id: 'ex6', name: '锤式弯举', sets: 3, reps: '12', restTime: 60, completed: false },
    ],
  },

  weeklyStats: {
    trainings: 4,
    duration: '6.5h',
    weight: '12.8t',
    calories: '1,850',
  },

  plans: [
    { id: 'plan1', name: '三分化增肌计划', status: 'active', frequency: '6天/周', difficulty: '进阶', week: 4, totalWeeks: 8, progress: 75, badge: '进行中', badgeClass: 'act-b' },
    { id: 'plan2', name: '新手入门计划', status: 'done', frequency: '3天/周', difficulty: '入门', week: 4, totalWeeks: 4, progress: 100, badge: '已完成', badgeClass: 'done-b' },
    { id: 'plan3', name: '推拉腿训练计划', status: 'pending', frequency: '6天/周', difficulty: '高级', week: 0, totalWeeks: 8, progress: 0, badge: '待开始', badgeClass: 'pend-b' },
  ],

  chartData: {
    weekly: [
      { label: '周一', value: 60 },
      { label: '周二', value: 80 },
      { label: '周三', value: 40 },
      { label: '周四', value: 100 },
      { label: '周五', value: 70 },
      { label: '周六', value: 90 },
      { label: '周日', value: 30 },
    ],
  },

  muscleDistribution: [
    { name: '背部', pct: 35, color: 'var(--accent-primary)' },
    { name: '胸部', pct: 28, color: 'var(--info)' },
    { name: '腿部', pct: 22, color: 'var(--success)' },
  ],

  personalRecords: [
    { name: '卧推', weight: '80kg', date: '2025-05-15', clazz: 'ac' },
    { name: '深蹲', weight: '100kg', date: '2025-05-12', clazz: 'bl' },
    { name: '硬拉', weight: '120kg', date: '2025-05-10', clazz: 'gr' },
  ],

  categories: ['全部', '胸部', '背部', '腿部', '肩部', '手臂', '核心'],

  exercises: [
    { id: 'e1', name: '杠铃卧推', category: '胸部', equip: '杠铃' },
    { id: 'e2', name: '哑铃飞鸟', category: '胸部', equip: '哑铃' },
    { id: 'e3', name: '上斜卧推', category: '胸部', equip: '杠铃' },
    { id: 'e4', name: '绳索夹胸', category: '胸部', equip: '器械' },
    { id: 'e5', name: '引体向上', category: '背部', equip: '自重' },
    { id: 'e6', name: '杠铃划船', category: '背部', equip: '杠铃' },
    { id: 'e7', name: '高位下拉', category: '背部', equip: '器械' },
    { id: 'e8', name: '坐姿划船', category: '背部', equip: '器械' },
    { id: 'e9', name: '杠铃深蹲', category: '腿部', equip: '杠铃' },
    { id: 'e10', name: '腿举', category: '腿部', equip: '器械' },
    { id: 'e11', name: '哑铃推举', category: '肩部', equip: '哑铃' },
    { id: 'e12', name: '侧平举', category: '肩部', equip: '哑铃' },
    { id: 'e13', name: '哑铃弯举', category: '手臂', equip: '哑铃' },
    { id: 'e14', name: '锤式弯举', category: '手臂', equip: '哑铃' },
    { id: 'e15', name: '平板支撑', category: '核心', equip: '自重' },
    { id: 'e16', name: '卷腹', category: '核心', equip: '自重' },
  ],

  getTodayDate() {
    const now = new Date();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 星期${weekdays[now.getDay()]}`;
  },
};

export default MockData;
