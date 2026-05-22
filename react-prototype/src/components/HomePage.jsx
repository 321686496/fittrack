import React from 'react';
import PageHeader from './PageHeader';
import { Clock, Dumbbell, Flame, Target, Zap, TrendingUp, Trophy, ChevronRight, Calendar } from './Icons';
import MockData from '../data/mockData';

export default function HomePage({ onNavigate }) {
  const { todayPlan, weeklyStats, weeklyCalendar, streak, user, recentTrainings, dailyTip, personalRecords, plans } = MockData;
  const todayDate = MockData.getTodayDate();
  const pct = Math.round((todayPlan.completed / todayPlan.exerciseCount) * 100);
  const activePlan = plans.find(p => p.status === 'active');

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

          <button className="btn-primary w-full" onClick={() => onNavigate('training')}>
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
            <span className="sec-more" onClick={() => onNavigate('stats')}>更多</span>
          </div>
          <div className="recent-list">
            {recentTrainings.map(rt => (
              <div key={rt.id} className="recent-item card" onClick={() => onNavigate('stats')}>
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
                <div className="pr-weight font-data">{pr.weight}</div>
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
