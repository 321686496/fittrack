const STORAGE_KEYS = {
  PLANS: 'fitplan_plans',
  RECORDS: 'fitplan_records',
  SETTINGS: 'fitplan_settings',
  STATS: 'fitplan_stats',
};

function safeGet(key, defaultValue) {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null || raw === '') return defaultValue;
    return JSON.parse(raw);
  } catch {
    return defaultValue;
  }
}

function safeSet(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
    return true;
  } catch {
    return false;
  }
}

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function getTodayStr() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function getWeekKey(timestamp) {
  const d = new Date(timestamp);
  const dayNum = d.getDay() || 7;
  d.setDate(d.getDate() + 4 - dayNum);
  const yearStart = new Date(d.getFullYear(), 0, 1);
  const weekNo = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getFullYear()}-W${String(weekNo).padStart(2, '0')}`;
}

const Storage = {
  getPlans() {
    return safeGet(STORAGE_KEYS.PLANS, []);
  },

  savePlans(plans) {
    return safeSet(STORAGE_KEYS.PLANS, plans);
  },

  addPlan(plan) {
    const plans = this.getPlans();
    const newPlan = {
      ...plan,
      id: generateId('plan'),
      createTime: Date.now(),
      updateTime: Date.now(),
      status: plan.status || 'active',
      progress: 0,
    };
    plans.push(newPlan);
    this.savePlans(plans);
    return newPlan;
  },

  updatePlan(planId, updates) {
    const plans = this.getPlans();
    const idx = plans.findIndex(p => p.id === planId);
    if (idx === -1) return null;
    plans[idx] = { ...plans[idx], ...updates, updateTime: Date.now() };
    this.savePlans(plans);
    return plans[idx];
  },

  deletePlan(planId) {
    const plans = this.getPlans().filter(p => p.id !== planId);
    this.savePlans(plans);
    return true;
  },

  getPlanById(planId) {
    return this.getPlans().find(p => p.id === planId) || null;
  },

  getRecords() {
    return safeGet(STORAGE_KEYS.RECORDS, []);
  },

  saveRecords(records) {
    return safeSet(STORAGE_KEYS.RECORDS, records);
  },

  addRecord(record) {
    const records = this.getRecords();
    const newRecord = {
      ...record,
      id: generateId('record'),
      createTime: Date.now(),
    };
    records.unshift(newRecord);
    if (records.length > 500) records.splice(500);
    this.saveRecords(records);
    this.updateStats(newRecord);
    return newRecord;
  },

  deleteRecord(recordId) {
    const records = this.getRecords().filter(r => r.id !== recordId);
    this.saveRecords(records);
    return true;
  },

  getRecordById(recordId) {
    return this.getRecords().find(r => r.id === recordId) || null;
  },

  getSettings() {
    return safeGet(STORAGE_KEYS.SETTINGS, {
      unit: 'kg',
      restTime: 90,
      defaultRestTime: 90,
      theme: 'iron-forge',
    });
  },

  saveSettings(settings) {
    return safeSet(STORAGE_KEYS.SETTINGS, settings);
  },

  getStats() {
    return safeGet(STORAGE_KEYS.STATS, {
      totalTrainings: 0,
      totalDuration: 0,
      totalWeight: 0,
      totalSets: 0,
      weeklyData: [],
      muscleData: {},
    });
  },

  updateStats(newRecord) {
    const stats = this.getStats();
    stats.totalTrainings += 1;
    stats.totalDuration += newRecord.duration || 0;
    stats.totalWeight += newRecord.totalWeight || 0;
    stats.totalSets += newRecord.totalSets || 0;

    const weekKey = getWeekKey(newRecord.date || Date.now());
    let weekData = stats.weeklyData.find(w => w.week === weekKey);
    if (!weekData) {
      weekData = { week: weekKey, trainings: 0, duration: 0, weight: 0 };
      stats.weeklyData.push(weekData);
    }
    weekData.trainings += 1;
    weekData.duration += newRecord.duration || 0;
    weekData.weight += newRecord.totalWeight || 0;
    if (stats.weeklyData.length > 12) {
      stats.weeklyData.splice(0, stats.weeklyData.length - 12);
    }

    if (newRecord.muscles && newRecord.muscles.length > 0) {
      for (const m of newRecord.muscles) {
        stats.muscleData[m] = (stats.muscleData[m] || 0) + 1;
      }
    }

    safeSet(STORAGE_KEYS.STATS, stats);
    return stats;
  },

  recalcStats() {
    const records = this.getRecords();
    const stats = {
      totalTrainings: 0,
      totalDuration: 0,
      totalWeight: 0,
      totalSets: 0,
      weeklyData: [],
      muscleData: {},
    };
    for (const r of records) {
      stats.totalTrainings += 1;
      stats.totalDuration += r.duration || 0;
      stats.totalWeight += r.totalWeight || 0;
      stats.totalSets += r.totalSets || 0;

      const weekKey = getWeekKey(r.date || Date.now());
      let weekData = stats.weeklyData.find(w => w.week === weekKey);
      if (!weekData) {
        weekData = { week: weekKey, trainings: 0, duration: 0, weight: 0 };
        stats.weeklyData.push(weekData);
      }
      weekData.trainings += 1;
      weekData.duration += r.duration || 0;
      weekData.weight += r.totalWeight || 0;

      if (r.muscles && r.muscles.length > 0) {
        for (const m of r.muscles) {
          stats.muscleData[m] = (stats.muscleData[m] || 0) + 1;
        }
      }
    }
    safeSet(STORAGE_KEYS.STATS, stats);
    return stats;
  },

  exportAllData() {
    return {
      plans: this.getPlans(),
      records: this.getRecords(),
      settings: this.getSettings(),
      stats: this.getStats(),
      exportTime: Date.now(),
    };
  },

  importData(data) {
    if (!data.plans || !data.records) return false;
    this.savePlans(data.plans);
    this.saveRecords(data.records);
    if (data.settings) this.saveSettings(data.settings);
    if (data.stats) safeSet(STORAGE_KEYS.STATS, data.stats);
    return true;
  },

  clearAll() {
    localStorage.removeItem(STORAGE_KEYS.PLANS);
    localStorage.removeItem(STORAGE_KEYS.RECORDS);
    localStorage.removeItem(STORAGE_KEYS.SETTINGS);
    localStorage.removeItem(STORAGE_KEYS.STATS);
  },

  hasData() {
    return this.getPlans().length > 0 || this.getRecords().length > 0;
  },

  initDemoData() {
    if (this.hasData()) return;
    const demoPlan = this.addPlan({
      name: '三分化增肌计划',
      type: '三分化',
      frequency: '6天/周',
      difficulty: '进阶',
      totalWeeks: 8,
      week: 4,
      badge: '进行中',
      days: [
        {
          day: 1, label: '胸部 + 三头肌', muscle: '胸',
          exercises: [
            { id: 'e1', name: '杠铃卧推', sets: 4, reps: '8-12', restTime: 90 },
            { id: 'e2', name: '哑铃飞鸟', sets: 3, reps: '12', restTime: 60 },
            { id: 'e3', name: '上斜卧推', sets: 4, reps: '8-12', restTime: 90 },
            { id: 'e4', name: '绳索夹胸', sets: 3, reps: '15', restTime: 60 },
          ],
        },
        {
          day: 2, label: '背部 + 二头肌', muscle: '背',
          exercises: [
            { id: 'e5', name: '引体向上', sets: 4, reps: '8-12', restTime: 90 },
            { id: 'e6', name: '杠铃划船', sets: 4, reps: '8-12', restTime: 90 },
            { id: 'e7', name: '高位下拉', sets: 4, reps: '12', restTime: 75 },
            { id: 'e8', name: '坐姿划船', sets: 3, reps: '12', restTime: 60 },
            { id: 'e13', name: '哑铃弯举', sets: 4, reps: '10-12', restTime: 60 },
            { id: 'e14', name: '锤式弯举', sets: 3, reps: '12', restTime: 60 },
          ],
        },
        {
          day: 3, label: '腿部', muscle: '腿',
          exercises: [
            { id: 'e9', name: '杠铃深蹲', sets: 5, reps: '5-8', restTime: 120 },
            { id: 'e10', name: '腿举', sets: 4, reps: '10-12', restTime: 90 },
          ],
        },
        {
          day: 4, label: '肩部 + 核心', muscle: '肩',
          exercises: [
            { id: 'e11', name: '哑铃推举', sets: 4, reps: '8-12', restTime: 90 },
            { id: 'e12', name: '侧平举', sets: 4, reps: '12-15', restTime: 60 },
            { id: 'e15', name: '平板支撑', sets: 3, reps: '60秒', restTime: 45 },
            { id: 'e16', name: '卷腹', sets: 3, reps: '20', restTime: 45 },
          ],
        },
        { day: 5, label: '胸部 + 背部', muscle: '胸/背', exercises: [] },
        { day: 6, label: '腿部 + 手臂', muscle: '腿/手臂', exercises: [] },
      ],
    });
    this.addPlan({
      name: '新手入门计划',
      type: '全身训练',
      frequency: '3天/周',
      difficulty: '入门',
      totalWeeks: 4,
      week: 4,
      status: 'done',
      progress: 100,
      badge: '已完成',
      days: [
        {
          day: 1, label: '全身训练A', muscle: '全身',
          exercises: [
            { id: 'e9', name: '杠铃深蹲', sets: 3, reps: '10-12', restTime: 90 },
            { id: 'e1', name: '杠铃卧推', sets: 3, reps: '10-12', restTime: 90 },
            { id: 'e5', name: '引体向上', sets: 3, reps: '8-10', restTime: 90 },
          ],
        },
        {
          day: 2, label: '全身训练B', muscle: '全身',
          exercises: [
            { id: 'e10', name: '腿举', sets: 3, reps: '10-12', restTime: 90 },
            { id: 'e6', name: '杠铃划船', sets: 3, reps: '10-12', restTime: 90 },
            { id: 'e11', name: '哑铃推举', sets: 3, reps: '10-12', restTime: 90 },
          ],
        },
        {
          day: 3, label: '全身训练C', muscle: '全身',
          exercises: [
            { id: 'e2', name: '哑铃飞鸟', sets: 3, reps: '12', restTime: 60 },
            { id: 'e7', name: '高位下拉', sets: 3, reps: '12', restTime: 75 },
            { id: 'e15', name: '平板支撑', sets: 3, reps: '30秒', restTime: 30 },
          ],
        },
      ],
    });
    return demoPlan;
  },
};

export default Storage;
export { generateId, getTodayStr, getWeekKey };
