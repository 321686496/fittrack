import React, { useState } from 'react';
import PageHeader from './PageHeader';
import MockData from '../data/mockData';

export default function StatsPage() {
  const [chartTab, setChartTab] = useState('weekly');

  const overview = [
    { value: '30', label: '总训练' },
    { value: '40h', label: '总时长' },
    { value: '48t', label: '总重量' },
    { value: '7.2k', label: '卡路里' },
  ];

  return (
    <>
      <PageHeader title="数据统计" subtitle="追踪你的训练进步" />

      <div className="page-body">
        <div className="stats-grid" style={{ marginBottom: 'var(--section-gap)' }}>
          {overview.map(({ value, label }) => (
            <div key={label} className="stat-card" style={{ textAlign: 'center' }}>
              <div className="stat-val" style={{ fontSize: 'calc(22px * var(--font-size-scale))' }}>{value}</div>
              <div className="stat-lbl">{label}</div>
            </div>
          ))}
        </div>

        <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">训练频率</span>
            <div style={{ display: 'flex', gap: 4 }}>
              {['weekly', 'monthly'].map(tab => (
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
                  {tab === 'weekly' ? '周' : '月'}
                </button>
              ))}
            </div>
          </div>
          <div className="chart-placeholder">
            训练频率图表
          </div>
        </div>

        <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">肌群训练分布</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-around', padding: '16px 0' }}>
            {MockData.muscleDistribution.map(item => (
              <div key={item.name} style={{ textAlign: 'center' }}>
                <div style={{
                  width: 60, height: 60, borderRadius: 'var(--radius-xl)',
                  border: '3px solid ' + item.color,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  margin: '0 auto 8px',
                  fontFamily: 'var(--font-data)',
                  fontWeight: 700,
                  fontSize: 'calc(14px * var(--font-size-scale))',
                  color: item.color,
                }}>
                  {item.pct}%
                </div>
                <div style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>{item.name}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 'var(--section-gap)' }}>
          <div className="sec-hd">
            <span className="sec-title">个人记录</span>
          </div>
          <div className="card">
            {MockData.personalRecords.map(pr => (
              <div key={pr.name} className="stat-row">
                <div>
                  <div className="stat-row-lbl">{pr.name}</div>
                  <div style={{ fontSize: 'calc(11px * var(--font-size-scale))', color: 'var(--text-muted)' }}>更新于 {pr.date}</div>
                </div>
                <div className="stat-row-val text-accent">{pr.weight}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
