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
    <div className="page on">
      <PageHeader title="数据统计" subtitle="追踪你的训练进步" />

      <div className="sec">
        <div className="st-g c4">
          {overview.map(({ value, label }) => (
            <div key={label} className="stat-card sm">
              <div className="stat-v">{value}</div>
              <div className="stat-l">{label}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="sec">
        <div className="ch-bx">
          <div className="ch-hd">
            <span className="ch-tt">训练频率</span>
            <div className="ch-tabs">
              {['weekly', 'monthly'].map(tab => (
                <button key={tab} className={`ch-tab${chartTab === tab ? ' sel' : ''}`} onClick={() => setChartTab(tab)}>
                  {tab === 'weekly' ? '周' : '月'}
                </button>
              ))}
            </div>
          </div>
          <div className="bar-ch">
            {MockData.chartData.weekly.map((item, i) => (
              <div key={i} className="bar-grp">
                <div className="bar" style={{ height: `${item.value}px` }} />
                <span className="bar-lbl">{item.label}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="sec">
        <div className="ch-bx">
          <div className="ch-hd"><span className="ch-tt">肌群训练分布</span></div>
          <div className="musc-rings">
            {MockData.muscleDistribution.map(item => (
              <div key={item.name} className="musc-it">
                <div className="ring" style={{
                  background: `conic-gradient(${item.color} 0% ${item.pct}%, var(--bg-elevated) ${item.pct}% 100%)`,
                }}>
                  <div className="ring-in">{item.pct}%</div>
                </div>
                <div className="ring-lbl">{item.name}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="sec">
        <div className="sec-hd"><span className="sec-tt">个人记录 (PR)</span></div>
        {MockData.personalRecords.map(pr => (
          <div key={pr.name} className="pr-card">
            <div className="pr-inf">
              <div className="pr-nm">{pr.name}</div>
              <div className="pr-dt">更新于 {pr.date}</div>
            </div>
            <div className={`pr-wt ${pr.clazz}`}>{pr.weight}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
