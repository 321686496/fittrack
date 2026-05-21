import React from 'react';
import PageHeader from './PageHeader';
import { Icons } from './Icons';
import MockData from '../data/mockData';

export default function PlanPage({ onNavigate }) {
  return (
    <div className="page on">
      <PageHeader title="训练计划" subtitle="管理你的专属训练方案" />

      <div className="sec">
        <div className="pl">
          {MockData.plans.map(plan => (
            <div
              key={plan.id}
              className={`pl-card${plan.status === 'active' ? ' act' : ''}`}
              onClick={() => plan.status === 'active' && onNavigate('training')}
            >
              <div className="pl-row">
                <span className="pl-name">{plan.name}</span>
                <span className={`pl-badge ${plan.badgeClass}`}>{plan.badge}</span>
              </div>
              <div className="pl-meta">
                <span className="pl-meta-it">{plan.frequency}</span>
                <span className="pl-meta-it">{plan.difficulty}难度</span>
                <span className="pl-meta-it">
                  {plan.status === 'pending' ? `${plan.totalWeeks}周周期` : `第${plan.week}周`}
                </span>
              </div>
              {plan.status !== 'pending' && (
                <div className="pl-pg-track">
                  <div className="pl-pg-fill" style={{ width: `${plan.progress}%` }} />
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <button className="fab" title="创建新计划"><Icons.Plus /></button>
    </div>
  );
}
