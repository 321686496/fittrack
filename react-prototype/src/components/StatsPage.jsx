import React, { useState, useEffect, useMemo } from 'react';
import Storage from '../data/storage.js';
import PageHeader from './PageHeader';
import { Clock, Dumbbell, Flame, Target, Zap } from './Icons';

const MUSCLE_COLORS = {
  '胸': '#3b82f6',
  '背': '#0ea5e9',
  '腿': '#22c55e',
  '肩': '#f59e0b',
  '手臂': '#a855f7',
  '核心': '#ef4444',
};

function formatDuration(mins) {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  if (h === 0) return `${m}m`;
  if (m === 0) return `${h}h`;
  return `${h}h ${m}m`;
}

function formatWeight(g) {
  if (g >= 1000000) return `${(g / 1000000).toFixed(1)}kt`;
  if (g >= 1000) return `${(g / 1000).toFixed(1)}t`;
  return `${g}kg`;
}

function formatCalories(duration) {
  const cal = duration * 7;
  if (cal >= 10000) return `${(cal / 1000).toFixed(1)}k`;
  if (cal >= 1000) return `${(cal / 1000).toFixed(1)}k`;
  return `${cal}`;
}

export default function StatsPage() {
  const [chartTab, setChartTab] = useState('week');
  const [stats, setStats] = useState(null);
  const [records, setRecords] = useState([]);

  useEffect(() => {
    setStats(Storage.getStats());
    setRecords(Storage.getRecords());
  }, []);

  const hasData = stats && stats.totalTrainings > 0;

  const overviewCards = useMemo(() => {
    if (!stats) return [];
    return [
      { value: String(stats.totalTrainings), label: '总训练', icon: Target, color: 'blue' },
      { value: formatDuration(stats.totalDuration), label: '总时长', icon: Clock, color: 'green' },
      { value: formatWeight(stats.totalWeight), label: '总重量', icon: Dumbbell, color: 'purple' },
      { value: formatCalories(stats.totalDuration), label: '卡路里', icon: Flame, color: 'red' },
    ];
  }, [stats]);

  const chartData = useMemo(() => {
    if (!stats || !stats.weeklyData || stats.weeklyData.length === 0) return [];
    if (chartTab === 'week') {
      return stats.weeklyData.map(w => ({
        label: w.week.replace(/^\d{4}-/, ''),
        value: w.trainings,
      }));
    }
    const monthMap = {};
    for (const w of stats.weeklyData) {
      const monthKey = w.week.substring(0, 7);
      if (!monthMap[monthKey]) monthMap[monthKey] = { label: monthKey, value: 0 };
      monthMap[monthKey].value += w.trainings;
    }
    return Object.values(monthMap).sort((a, b) => a.label.localeCompare(b.label));
  }, [stats, chartTab]);

  const muscleItems = useMemo(() => {
    if (!stats || !stats.muscleData) return [];
    const entries = Object.entries(stats.muscleData);
    const total = entries.reduce((s, [, v]) => s + v, 0);
    if (total === 0) return [];
    return entries
      .map(([name, count]) => ({
        name,
        pct: Math.round((count / total) * 100),
        color: MUSCLE_COLORS[name] || 'var(--accent-primary)',
      }))
      .sort((a, b) => b.pct - a.pct);
  }, [stats]);

  const personalRecords = useMemo(() => {
    if (!records || records.length === 0) return [];
    const maxMap = {};
    for (const rec of records) {
      if (!rec.exercises) continue;
      for (const ex of rec.exercises) {
        if (!ex.sets) continue;
        for (const s of ex.sets) {
          const w = s.weight || 0;
          if (w > 0) {
            if (!maxMap[ex.exerciseName] || w > maxMap[ex.exerciseName].weight) {
              maxMap[ex.exerciseName] = {
                name: ex.exerciseName,
                weight: w,
                date: rec.date ? new Date(rec.date).toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' }) : '',
              };
            }
          }
        }
      }
    }
    return Object.values(maxMap).sort((a, b) => b.weight - a.weight).slice(0, 3);
  }, [records]);

  if (!stats) return null;

  if (!hasData) {
    return (
      <>
        <PageHeader title="数据统计" subtitle="追踪你的训练进步" />
        <div className="page-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
          <Zap size={48} style={{ color: 'var(--text-muted)', marginBottom: 16 }} />
          <div style={{ color: 'var(--text-secondary)', fontSize: 'calc(14px * var(--font-size-scale))', textAlign: 'center' }}>
            完成训练后这里将展示你的数据
          </div>
        </div>
      </>
    );
  }

  const maxChartVal = Math.max(...chartData.map(d => d.value), 1);

  return (
    <>
      <PageHeader title="数据统计" subtitle="追踪你的训练进步" />

      <div className="page-body">
        <div className="stats-grid" style={{ marginBottom: 'var(--section-gap)' }}>
          {overviewCards.map(({ value, label, icon: Icon, color }) => (
            <div key={label} className="stat-card" style={{ textAlign: 'center' }}>
              <div className={`stat-icon ${color}`} style={{ margin: '0 auto 6px' }}>
                <Icon size={16} />
              </div>
              <div className="stat-val font-data" style={{ fontSize: 'calc(20px * var(--font-size-scale))' }}>{value}</div>
              <div className="stat-lbl">{label}</div>
            </div>
          ))}
        </div>

        <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">训练频率</span>
            <div style={{ display: 'flex', gap: 4 }}>
              {['week', 'month'].map(tab => (
                <button
                  key={tab}
                  className="btn-secondary"
                  style={{
                    padding: '6px 14px',
                    fontSize: 'calc(12px * var(--font-size-scale))',
                    background: chartTab === tab ? 'var(--accent-gradient)' : undefined,
                    color: chartTab === tab ? 'var(--accent-text-color)' : undefined,
                    borderColor: chartTab === tab ? 'transparent' : undefined,
                  }}
                  onClick={() => setChartTab(tab)}
                >
                  {tab === 'week' ? '周' : '月'}
                </button>
              ))}
            </div>
          </div>
          {chartData.length === 0 ? (
            <div className="chart-placeholder">暂无数据</div>
          ) : (
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 140, padding: '8px 0' }}>
              {chartData.map((d, i) => {
                const h = Math.max((d.value / maxChartVal) * 110, 4);
                return (
                  <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                    <div style={{ fontSize: 'calc(10px * var(--font-size-scale))', color: 'var(--text-secondary)', fontFamily: 'var(--font-data)' }}>{d.value}</div>
                    <div style={{
                      width: '100%',
                      maxWidth: 32,
                      height: h,
                      borderRadius: 'var(--radius-sm)',
                      background: 'var(--accent-gradient)',
                      transition: 'height 0.3s ease',
                    }} />
                    <div style={{ fontSize: 'calc(10px * var(--font-size-scale))', color: 'var(--text-muted)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: 40 }}>{d.label}</div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {muscleItems.length > 0 && (
          <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
            <div className="sec-hd">
              <span className="sec-title">肌群训练分布</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-around', padding: '16px 0', flexWrap: 'wrap', gap: 12 }}>
              {muscleItems.map(item => (
                <div key={item.name} style={{ textAlign: 'center' }}>
                  <div style={{
                    width: 56, height: 56, borderRadius: 'var(--radius-xl)',
                    border: `3px solid ${item.color}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    margin: '0 auto 6px',
                    fontFamily: 'var(--font-data)',
                    fontWeight: 700,
                    fontSize: 'calc(13px * var(--font-size-scale))',
                    color: item.color,
                  }}>
                    {item.pct}%
                  </div>
                  <div style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>{item.name}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {personalRecords.length > 0 && (
          <div style={{ marginBottom: 'var(--section-gap)' }}>
            <div className="sec-hd">
              <span className="sec-title">个人记录</span>
              <span className="badge badge-accent">TOP 3</span>
            </div>
            <div className="card">
              {personalRecords.map(pr => (
                <div key={pr.name} className="stat-row">
                  <div>
                    <div className="stat-row-lbl">{pr.name}</div>
                    <div style={{ fontSize: 'calc(11px * var(--font-size-scale))', color: 'var(--text-muted)' }}>
                      {pr.date ? `更新于 ${pr.date}` : ''}
                    </div>
                  </div>
                  <div className="stat-row-val font-data" style={{ color: 'var(--accent-primary)' }}>{pr.weight}kg</div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </>
  );
}
