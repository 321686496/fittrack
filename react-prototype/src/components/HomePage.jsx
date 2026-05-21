import React from 'react';
import PageHeader from './PageHeader';
import { Icons } from './Icons';
import MockData from '../data/mockData';

export default function HomePage({ onNavigate }) {
  const { todayPlan, weeklyStats, user } = MockData;
  const todayDate = MockData.getTodayDate();
  const pct = Math.round((todayPlan.completed / todayPlan.exerciseCount) * 100);

  const quickActions = [
    { icon: Icons.Plan, label: '训练计划', key: 'plan' },
    { icon: Icons.Stats, label: '数据统计', key: 'stats' },
    { icon: Icons.Exercises, label: '动作库', key: 'exercise' },
    { icon: Icons.Invite, label: '邀请好友', key: 'profile' },
  ];

  const statItems = [
    { value: weeklyStats.trainings, label: '训练次数', ic: 'ac', icon: Icons.Dumbbell },
    { value: weeklyStats.duration, label: '训练时长', ic: 'bl', icon: Icons.Clock },
    { value: weeklyStats.weight, label: '总重量', ic: 'gr', icon: Icons.Cross },
    { value: weeklyStats.calories, label: '消耗卡路里', ic: 'pr', icon: Icons.Gift },
  ];

  return (
    <div className="page on">
      <PageHeader title={`你好，${user.name}`} subtitle={todayDate} />

      <div className="today-card">
        <div className="today-label">今日训练</div>
        <div className="today-title">{todayPlan.name}</div>
        <div className="today-meta">
          <div className="meta-it"><Icons.Clock />预计 {todayPlan.duration} 分钟</div>
          <div className="meta-it"><Icons.Dumbbell />{todayPlan.exerciseCount} 个动作</div>
        </div>
        <div className="pg-block">
          <div className="pg-h">
            <span className="pg-l">训练进度</span>
            <span className="pg-v">{todayPlan.completed}/{todayPlan.exerciseCount} 完成</span>
          </div>
          <div className="pg-track">
            <div className="pg-fill" style={{ width: `${pct}%` }} />
          </div>
        </div>
        <button className="btn-start" onClick={() => onNavigate('training')}>
          {todayPlan.completed > 0 ? '继续训练' : '开始训练'}
        </button>
      </div>

      <div className="sec">
        <div className="sec-hd">
          <span className="sec-tt">本周数据</span>
          <span className="sec-lk" onClick={() => onNavigate('stats')}>查看详情</span>
        </div>
        <div className="st-g c2">
          {statItems.map(({ value, label, ic, icon: Icon }) => (
            <div key={label} className="stat-card">
              <div className={`stat-ic ${ic}`}><Icon size={18} /></div>
              <div className="stat-v">{value}</div>
              <div className="stat-l">{label}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="sec">
        <div className="sec-hd"><span className="sec-tt">快速入口</span></div>
        <div className="qa">
          {quickActions.map(({ icon: Icon, label, key }) => (
            <div key={key} className="qa-it" onClick={() => onNavigate(key)}>
              <div className="qa-ic"><Icon size={20} /></div>
              <span className="qa-tx">{label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
