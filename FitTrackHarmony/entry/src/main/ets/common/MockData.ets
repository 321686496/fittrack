export class ExerciseItem {
  id: string = ''
  name: string = ''
  sets: number = 0
  reps: string = ''
  restTime: number = 0
  completed: boolean = false
  currentSet: number = -1
}

export class WeeklyCalendarItem {
  day: string = ''
  label: string = ''
  done: boolean = false
  rest: boolean = false
  today: boolean = false
}

export class AchievementItem {
  id: string = ''
  name: string = ''
  desc: string = ''
  icon: string = ''
  unlocked: boolean = false
}

export class PlanItem {
  id: string = ''
  name: string = ''
  status: string = ''
  frequency: string = ''
  difficulty: string = ''
  week: number = 0
  totalWeeks: number = 0
  progress: number = 0
  badge: string = ''
}

export class RecentTrainingItem {
  id: string = ''
  name: string = ''
  date: string = ''
  duration: string = ''
  calories: number = 0
  exercises: number = 0
  completed: boolean = false
}

export class PersonalRecordItem {
  name: string = ''
  weight: string = ''
  date: string = ''
}

export class ExerciseLibItem {
  id: string = ''
  name: string = ''
  category: string = ''
  equip: string = ''
}

export class MuscleDistributionItem {
  name: string = ''
  pct: number = 0
  color: string = ''
}

export class ChartDataItem {
  label: string = ''
  value: number = 0
}

export class UserInfo {
  name: string = ''
  level: number = 0
  title: string = ''
  points: number = 0
  avatar: string = ''
  totalTrainings: number = 0
  totalDuration: string = ''
}

export class TodayPlanInfo {
  name: string = ''
  muscle: string = ''
  duration: number = 0
  exerciseCount: number = 0
  completed: number = 0
  exercises: ExerciseItem[] = []
}

export class WeeklyStatsInfo {
  trainings: number = 0
  duration: string = ''
  weight: string = ''
  calories: string = ''
}

export class StreakInfo {
  current: number = 0
  longest: number = 0
  thisMonth: number = 0
  monthTotal: number = 0
}

export class BodyDataInfo {
  height: number = 0
  weight: number = 0
  bmi: number = 0
  bodyFat: number = 0
  chest: number = 0
  waist: number = 0
  hip: number = 0
  lastUpdate: string = ''
}

export class DailyTipInfo {
  text: string = ''
  category: string = ''
}

function createExerciseItems(): ExerciseItem[] {
  const items: ExerciseItem[] = []
  const data: string[][] = [
    ['ex1', '引体向上', '4', '8-12', '90', '1'],
    ['ex2', '杠铃划船', '4', '8-12', '90', '1'],
    ['ex3', '高位下拉', '4', '12', '90', '0'],
    ['ex4', '坐姿划船', '3', '12', '75', '0'],
    ['ex5', '哑铃弯举', '4', '10-12', '60', '0'],
    ['ex6', '锤式弯举', '3', '12', '60', '0'],
  ]
  for (const d of data) {
    const item = new ExerciseItem()
    item.id = d[0]
    item.name = d[1]
    item.sets = Number(d[2])
    item.reps = d[3]
    item.restTime = Number(d[4])
    item.completed = d[5] === '1'
    items.push(item)
  }
  return items
}

function createWeeklyCalendar(): WeeklyCalendarItem[] {
  const items: WeeklyCalendarItem[] = []
  const data: string[][] = [
    ['一', '胸+三头', '1', '0', '0'],
    ['二', '背+二头', '1', '0', '0'],
    ['三', '休息日', '1', '1', '0'],
    ['四', '肩+核心', '1', '0', '0'],
    ['五', '腿部', '0', '0', '1'],
    ['六', '胸+背', '0', '0', '0'],
    ['日', '休息日', '0', '1', '0'],
  ]
  for (const d of data) {
    const item = new WeeklyCalendarItem()
    item.day = d[0]
    item.label = d[1]
    item.done = d[2] === '1'
    item.rest = d[3] === '1'
    item.today = d[4] === '1'
    items.push(item)
  }
  return items
}

function createAchievements(): AchievementItem[] {
  const items: AchievementItem[] = []
  const data: string[][] = [
    ['a1', '初出茅庐', '完成第一次训练', '🎯', '1'],
    ['a2', '铁人意志', '连续打卡7天', '🔥', '1'],
    ['a3', '百吨俱乐部', '累计举起100吨', '💪', '1'],
    ['a4', '马拉松选手', '累计训练100小时', '⏱️', '0'],
    ['a5', '千次达人', '累计完成1000次动作', '🏆', '0'],
    ['a6', '不倒翁', '连续打卡30天', '🛡️', '0'],
  ]
  for (const d of data) {
    const item = new AchievementItem()
    item.id = d[0]
    item.name = d[1]
    item.desc = d[2]
    item.icon = d[3]
    item.unlocked = d[4] === '1'
    items.push(item)
  }
  return items
}

function createPlans(): PlanItem[] {
  const items: PlanItem[] = []
  const data: string[][] = [
    ['plan1', '三分化增肌计划', 'active', '6天/周', '进阶', '4', '8', '75', '进行中'],
    ['plan2', '新手入门计划', 'done', '3天/周', '入门', '4', '4', '100', '已完成'],
    ['plan3', '推拉腿训练计划', 'pending', '6天/周', '高级', '0', '8', '0', '待开始'],
  ]
  for (const d of data) {
    const item = new PlanItem()
    item.id = d[0]
    item.name = d[1]
    item.status = d[2]
    item.frequency = d[3]
    item.difficulty = d[4]
    item.week = Number(d[5])
    item.totalWeeks = Number(d[6])
    item.progress = Number(d[7])
    item.badge = d[8]
    items.push(item)
  }
  return items
}

function createChartData(): ChartDataItem[] {
  const items: ChartDataItem[] = []
  const data: string[][] = [
    ['周一', '60'], ['周二', '80'], ['周三', '40'], ['周四', '100'],
    ['周五', '70'], ['周六', '90'], ['周日', '30'],
  ]
  for (const d of data) {
    const item = new ChartDataItem()
    item.label = d[0]
    item.value = Number(d[1])
    items.push(item)
  }
  return items
}

function createMuscleDistribution(): MuscleDistributionItem[] {
  const items: MuscleDistributionItem[] = []
  const data: string[][] = [
    ['背部', '35', '#3b82f6'],
    ['胸部', '28', '#0ea5e9'],
    ['腿部', '22', '#22c55e'],
  ]
  for (const d of data) {
    const item = new MuscleDistributionItem()
    item.name = d[0]
    item.pct = Number(d[1])
    item.color = d[2]
    items.push(item)
  }
  return items
}

function createRecentTrainings(): RecentTrainingItem[] {
  const items: RecentTrainingItem[] = []
  const data: string[][] = [
    ['rt1', '胸部 + 三头肌', '昨天', '55min', '420', '5', '1'],
    ['rt2', '背部 + 二头肌', '2天前', '65min', '480', '6', '1'],
    ['rt3', '肩部 + 核心', '3天前', '45min', '350', '5', '1'],
  ]
  for (const d of data) {
    const item = new RecentTrainingItem()
    item.id = d[0]
    item.name = d[1]
    item.date = d[2]
    item.duration = d[3]
    item.calories = Number(d[4])
    item.exercises = Number(d[5])
    item.completed = d[6] === '1'
    items.push(item)
  }
  return items
}

function createPersonalRecords(): PersonalRecordItem[] {
  const items: PersonalRecordItem[] = []
  const data: string[][] = [
    ['卧推', '80kg', '2025-05-15'],
    ['深蹲', '100kg', '2025-05-12'],
    ['硬拉', '120kg', '2025-05-10'],
  ]
  for (const d of data) {
    const item = new PersonalRecordItem()
    item.name = d[0]
    item.weight = d[1]
    item.date = d[2]
    items.push(item)
  }
  return items
}

function createExercises(): ExerciseLibItem[] {
  const items: ExerciseLibItem[] = []
  const data: string[][] = [
    ['e1', '杠铃卧推', '胸部', '杠铃'], ['e2', '哑铃飞鸟', '胸部', '哑铃'],
    ['e3', '上斜卧推', '胸部', '杠铃'], ['e4', '绳索夹胸', '胸部', '器械'],
    ['e5', '引体向上', '背部', '自重'], ['e6', '杠铃划船', '背部', '杠铃'],
    ['e7', '高位下拉', '背部', '器械'], ['e8', '坐姿划船', '背部', '器械'],
    ['e9', '杠铃深蹲', '腿部', '杠铃'], ['e10', '腿举', '腿部', '器械'],
    ['e11', '哑铃推举', '肩部', '哑铃'], ['e12', '侧平举', '肩部', '哑铃'],
    ['e13', '哑铃弯举', '手臂', '哑铃'], ['e14', '锤式弯举', '手臂', '哑铃'],
    ['e15', '平板支撑', '核心', '自重'], ['e16', '卷腹', '核心', '自重'],
  ]
  for (const d of data) {
    const item = new ExerciseLibItem()
    item.id = d[0]
    item.name = d[1]
    item.category = d[2]
    item.equip = d[3]
    items.push(item)
  }
  return items
}

function createUser(): UserInfo {
  const u = new UserInfo()
  u.name = '健身达人'
  u.level = 8
  u.title = '进阶训练者'
  u.points = 1280
  u.avatar = 'FP'
  u.totalTrainings = 30
  u.totalDuration = '40h'
  return u
}

function createTodayPlan(): TodayPlanInfo {
  const p = new TodayPlanInfo()
  p.name = '背部 + 二头肌训练'
  p.muscle = '背阔肌 / 肱二头肌'
  p.duration = 65
  p.exerciseCount = 6
  p.completed = 2
  p.exercises = createExerciseItems()
  return p
}

function createWeeklyStats(): WeeklyStatsInfo {
  const w = new WeeklyStatsInfo()
  w.trainings = 4
  w.duration = '6.5h'
  w.weight = '12.8t'
  w.calories = '1,850'
  return w
}

function createStreak(): StreakInfo {
  const s = new StreakInfo()
  s.current = 12
  s.longest = 21
  s.thisMonth = 14
  s.monthTotal = 20
  return s
}

function createBodyData(): BodyDataInfo {
  const b = new BodyDataInfo()
  b.height = 175
  b.weight = 72.5
  b.bmi = 23.7
  b.bodyFat = 18.5
  b.chest = 98
  b.waist = 80
  b.hip = 96
  b.lastUpdate = '3天前'
  return b
}

function createDailyTip(): DailyTipInfo {
  const d = new DailyTipInfo()
  d.text = '训练后30分钟内补充蛋白质，能最大化肌肉修复与生长效果。'
  d.category = '营养建议'
  return d
}

export const USER: UserInfo = createUser()
export const TODAY_PLAN: TodayPlanInfo = createTodayPlan()
export const WEEKLY_STATS: WeeklyStatsInfo = createWeeklyStats()
export const WEEKLY_CALENDAR: WeeklyCalendarItem[] = createWeeklyCalendar()
export const STREAK: StreakInfo = createStreak()
export const ACHIEVEMENTS: AchievementItem[] = createAchievements()
export const BODY_DATA: BodyDataInfo = createBodyData()
export const PLANS: PlanItem[] = createPlans()
export const CHART_DATA: ChartDataItem[] = createChartData()
export const MUSCLE_DISTRIBUTION: MuscleDistributionItem[] = createMuscleDistribution()
export const RECENT_TRAININGS: RecentTrainingItem[] = createRecentTrainings()
export const DAILY_TIP: DailyTipInfo = createDailyTip()
export const PERSONAL_RECORDS: PersonalRecordItem[] = createPersonalRecords()
export const CATEGORIES: string[] = ['全部', '胸部', '背部', '腿部', '肩部', '手臂', '核心']
export const EXERCISES: ExerciseLibItem[] = createExercises()

export function getTodayDate(): string {
  const now = new Date()
  const weekdays: string[] = ['日', '一', '二', '三', '四', '五', '六']
  return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 星期${weekdays[now.getDay()]}`
}

export function findActivePlan(): PlanItem | undefined {
  for (const p of PLANS) {
    if (p.status === 'active') {
      return p
    }
  }
  return undefined
}

export function filterExercisesByCategory(cat: string): ExerciseLibItem[] {
  if (cat === '全部') {
    return EXERCISES
  }
  const result: ExerciseLibItem[] = []
  for (const e of EXERCISES) {
    if (e.category === cat) {
      result.push(e)
    }
  }
  return result
}
