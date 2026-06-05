import React, { useState, useEffect } from 'react';
import PageHeader from './PageHeader';
import { Clock, Dumbbell, Flame, Target, Zap, TrendingUp, Trophy, ChevronRight, Calendar } from './Icons';
import MockData from '../data/mockData';
import Storage from '../data/storage.js';

function computeStreak(records) {
  if (!records || records.length === 0) return { current: 0, longest: 0, thisMonth: 0, monthTotal: 0 };
  const dateSet = new Set();
  for (const r of records) {
    const ts = r.createTime || r.date || Date.now();
    const d = new Date(ts);
    dateSet.add(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`);
  }
  const sortedDates = [...dateSet].sort().reverse();
  let current = 0;
  const today = new Date();
  const todayStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  let checkDate = new Date(today);
  if (!dateSet.has(todayStr)) {
    checkDate.setDate(checkDate.getDate() - 1);
  }
  while (true) {
    const ds = `${checkDate.getFullYear()}-${String(checkDate.getMonth() + 1).padStart(2, '0')}-${String(checkDate.getDate()).padStart(2, '0')}`;
    if (dateSet.has(ds)) {
      current++;
      checkDate.setDate(checkDate.getDate() - 1);
    } else {
      break;
    }
  }
  let longest = 0;
  let run = 0;
  for (let i = 0; i < sortedDates.length; i++) {
    if (i === 0) { run = 1; }
    else {
      const prev = new Date(sortedDates[i - 1]);
      const curr = new Date(sortedDates[i]);
      const diff = (prev - curr) / 86400000;
      run = diff === 1 ? run + 1 : 1;
    }
    if (run > longest) longest = run;
  }
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  let thisMonth = 0;
  for (const ds of sortedDates) {
    const d = new Date(ds);
    if (d >= monthStart) thisMonth++;
  }
  return { current, longest, thisMonth, monthTotal: daysInMonth };
}

function computePersonalRecords(records) {
  const maxByExercise = {};
  for (const r of records) {
    const exercises = r.exercises || [];
    for (const ex of exercises) {
      const setsData = ex.setsData || [];
      for (const s of setsData) {
        const w = parseFloat(s.weight) || 0;
        if (!maxByExercise[ex.name] || w > maxByExercise[ex.name].weight) {
          const ts = r.createTime || r.date || Date.now();
          const d = new Date(ts);
          maxByExercise[ex.name] = {
            name: ex.name,
            weight: w,
            date: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`,
          };
        }
      }
    }
  }
  return Object.values(maxByExercise).sort((a, b) => b.weight - a.weight).slice(0, 3);
}

export default function HomePage({ onNavigate }) {
  const [plans, setPlans] = useState([]);
  const [records, setRecords] = useState([]);
  const [stats, setStats] = useState(null);

  useEffect(() => {
    if (!Storage.hasData()) {
      Storage.initDemoData();
    }
    setPlans(Storage.getPlans());
    setRecords(Storage.getRecords());
    setStats(Storage.getStats());
  }, []);

  const todayDate = MockData.getTodayDate();
  const user = MockData.user;
  const dailyTip = MockData.dailyTip;
  const categories = MockData.categories;
  const exercises = MockData.exercises;

  const activePlan = plans.find(p => p.status === 'active');

  const todayPlan = (() => {
    if (!activePlan || !activePlan.days || activePlan.days.length === 0) {
      return { name: '今日训练', muscle: '暂无计划', duration: 0, exerciseCount: 0, completed: 0 };
    }
    const firstIncomplete = activePlan.days.find(d => d.exercises && d.exercises.length > 0) || activePlan.days[0];
    const exCount = (firstIncomplete.exercises || []).length;
    const estDuration = exCount * 12;
    return {
      name: firstIncomplete.label || '今日训练',
      muscle: firstIncomplete.muscle || '',
      duration: estDuration,
      exerciseCount: exCount,
      completed: 0,
    };
  })();

  const pct = todayPlan.exerciseCount > 0 ? Math.round((todayPlan.completed / todayPlan.exerciseCount) * 100) : 0;

  const weeklyStats = (() => {
    if (!stats || !stats.weeklyData || stats.weeklyData.length === 0) {
      return { trainings: 0, duration: '0h', weight: '0kg', calories: 0 };
    }
    const latest = stats.weeklyData[stats.weeklyData.length - 1];
    return {
      trainings: latest.trainings || 0,
      duration: latest.duration ? `${(latest.duration / 60).toFixed(1)}h` : '0h',
      weight: latest.weight ? `${(latest.weight / 1000).toFixed(1)}t` : '0kg',
      calories: Math.round((latest.trainings || 0) * 110),
    };
  })();

  const weeklyCalendar = (() => {
    const dayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    const now = new Date();
    const todayDay = now.getDay() || 7;
    const todayDateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const recordDates = new Set();
    for (const r of records) {
      const ts = r.createTime || r.date || Date.now();
      const d = new Date(ts);
      recordDates.add(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`);
    }
    const planDays = activePlan && activePlan.days ? activePlan.days : [];
    return dayLabels.map((label, idx) => {
      const dayNum = idx + 1;
      const d = new Date(now);
      d.setDate(d.getDate() - todayDay + dayNum);
      const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      const isToday = dayNum === todayDay;
      const done = recordDates.has(dateStr);
      const planDay = planDays[dayNum - 1];
      const isRest = planDay && planDay.exercises && planDay.exercises.length === 0;
      return {
        day: label,
        label: planDay ? planDay.muscle || planDay.label : '',
        done: done && !isToday,
        today: isToday,
        rest: isRest,
      };
    });
  })();

  const streak = computeStreak(records);

  const recentTrainings = records.slice(0, 3).map(r => ({
    id: r.id,
    name: r.planName || '训练记录',
    date: (() => {
      const ts = r.createTime || r.date || Date.now();
      const d = new Date(ts);
      const now2 = new Date();
      const diff = Math.floor((now2 - d) / 86400000);
      if (diff === 0) return '今天';
      if (diff === 1) return '昨天';
      return `${diff}天前`;
    })(),
    duration: r.duration ? `${r.duration}min` : '-',
    calories: Math.round((r.duration || 0) * 7),
    exercises: (r.exercises || []).length,
    completed: true,
  }));

  const personalRecords = computePersonalRecords(records);

  const statItems = [
    { value: weeklyStats.trainings, label: '训练次数', colorClass: 'red', icon: Flame },
    { value: weeklyStats.duration, label: '训练时长', colorClass: 'blue', icon: Clock },
    { value: weeklyStats.weight, label: '总重量', colorClass: 'green', icon: Target },
    { value: weeklyStats.calories, label: '消耗', colorClass: 'purple', icon: Zap },
  ];

  return (
    <>
      <PageHeader title={`你好，${user.name}`} subtitle={todayDate} />

      <div className="page-body">
        <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="today-block">
            <div className="today-title">{todayPlan.name}</div>
            <div className="today-meta">{todayPlan.muscle}</div>
          </div>

          <div style={{ display: 'flex', gap: 20, margin: '12px 0' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Clock size={16} style={{ color: 'var(--accent-primary)' }} />
              <span className="font-data" style={{ fontSize: 'calc(13px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
                ~{todayPlan.duration}min
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Dumbbell size={16} style={{ color: 'var(--accent-primary)' }} />
              <span className="font-data" style={{ fontSize: 'calc(13px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
                {todayPlan.exerciseCount}个动作
              </span>
            </div>
          </div>

          <div style={{ marginBottom: 16 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
              <span style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>训练进度</span>
              <span className="font-data" style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--accent-primary)' }}>
                {todayPlan.completed}/{todayPlan.exerciseCount}
              </span>
            </div>
            <div className="progress-track">
              <div className="progress-fill" style={{ width: `${pct}%` }} />
            </div>
          </div>

          <button className="btn-primary w-full" onClick={() => {
            if (activePlan) {
              window.__trainingParams = { planId: activePlan.id, dayIndex: 0 };
            }
            onNavigate('training');
          }}>
            {todayPlan.completed > 0 ? '继续训练' : '开始训练'}
          </button>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">本周数据</span>
            <span className="sec-more" onClick={() => onNavigate('stats')}>全部数据</span>
          </div>
          <div className="stats-grid">
            {statItems.map(({ value, label, colorClass, icon: Icon }) => (
              <div key={label} className="stat-card">
                <div className={`stat-icon ${colorClass}`}><Icon size={18} /></div>
                <div className="stat-val">{value}</div>
                <div className="stat-lbl">{label}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">本周训练日历</span>
          </div>
          <div className="week-cal">
            {weeklyCalendar.map(item => (
              <div
                key={item.day}
                className={`week-cal-day${item.today ? ' today' : ''}${item.done ? ' done' : ''}${item.rest ? ' rest' : ''}`}
              >
                <div className="week-cal-label">{item.day}</div>
                <div className="week-cal-dot-wrap">
                  {item.done ? (
                    <div className="week-cal-dot done" />
                  ) : item.today ? (
                    <div className="week-cal-dot current" />
                  ) : (
                    <div className="week-cal-dot" />
                  )}
                </div>
                <div className="week-cal-text">{item.rest ? '休息' : item.done ? '已练' : item.label}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">连续打卡</span>
          </div>
          <div className="streak-card card">
            <div className="streak-main">
              <div className="streak-flame">🔥</div>
              <div className="streak-num font-data">{streak.current}</div>
              <div className="streak-unit">天连续训练</div>
            </div>
            <div className="streak-meta">
              <div className="streak-meta-item">
                <div className="streak-meta-val font-data">{streak.longest}</div>
                <div className="streak-meta-lbl">最长纪录</div>
              </div>
              <div className="streak-divider" />
              <div className="streak-meta-item">
                <div className="streak-meta-val font-data">{streak.thisMonth}/{streak.monthTotal}</div>
                <div className="streak-meta-lbl">本月训练</div>
              </div>
            </div>
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">最近训练</span>
            <span className="sec-more" onClick={() => onNavigate('records')}>更多</span>
          </div>
          <div className="recent-list">
            {recentTrainings.map(rt => (
              <div key={rt.id} className="recent-item card" onClick={() => onNavigate('records')}>
                <div className="recent-left">
                  <div className="recent-icon-wrap">
                    <Dumbbell size={16} />
                  </div>
                  <div className="recent-info">
                    <div className="recent-name">{rt.name}</div>
                    <div className="recent-meta">
                      <Clock size={11} style={{ marginRight: 3 }} />
                      {rt.duration}
                      <span style={{ margin: '0 6px' }}>·</span>
                      {rt.exercises}个动作
                    </div>
                  </div>
                </div>
                <div className="recent-right">
                  <div className="recent-cal font-data">{rt.calories}</div>
                  <div className="recent-cal-lbl">千卡</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">个人最佳</span>
            <span className="sec-more" onClick={() => onNavigate('stats')}>全部</span>
          </div>
          <div className="pr-grid">
            {personalRecords.map(pr => (
              <div key={pr.name} className="pr-item card">
                <div className="pr-icon-wrap">
                  <Trophy size={16} />
                </div>
                <div className="pr-name">{pr.name}</div>
                <div className="pr-weight font-data">{pr.weight}kg</div>
                <div className="pr-date">{pr.date}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">每日建议</span>
          </div>
          <div className="tip-card card">
            <div className="tip-badge">{dailyTip.category}</div>
            <div className="tip-text">{dailyTip.text}</div>
          </div>
        </div>

        {activePlan && (
          <div style={{ marginBottom: 'var(--section-gap)' }}>
            <div className="sec-hd">
              <span className="sec-title">当前计划</span>
              <span className="sec-more" onClick={() => onNavigate('plan')}>查看全部</span>
            </div>
            <div className="plan-home-card card" onClick={() => onNavigate('plan')}>
              <div className="plan-home-top">
                <div className="plan-home-info">
                  <div className="plan-home-name">{activePlan.name}</div>
                  <div className="plan-home-meta">
                    {activePlan.frequency} · {activePlan.difficulty}
                  </div>
                </div>
                <div className="plan-home-badge badge badge-accent">{activePlan.badge}</div>
              </div>
              <div className="plan-home-progress">
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
                    第{activePlan.week}周 / 共{activePlan.totalWeeks}周
                  </span>
                  <span className="font-data" style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--accent-primary)' }}>
                    {activePlan.progress}%
                  </span>
                </div>
                <div className="progress-track">
                  <div className="progress-fill" style={{ width: `${activePlan.progress}%` }} />
                </div>
              </div>
              <div className="plan-home-footer">
                <Calendar size={14} style={{ color: 'var(--text-muted)', marginRight: 4 }} />
                <span style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-muted)' }}>
                  预计还需{(activePlan.totalWeeks - activePlan.week)}周完成
                </span>
                <ChevronRight size={16} style={{ marginLeft: 'auto', color: 'var(--text-muted)' }} />
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
