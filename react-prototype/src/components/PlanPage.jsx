import React from 'react';
import PageHeader from './PageHeader';
import { Plus } from './Icons';
import MockData from '../data/mockData';

export default function PlanPage({ onNavigate }) {
  return (
    <>
      <PageHeader title="训练计划" subtitle="管理你的专属训练方案" />

      <div className="page-body">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--card-spacing)' }}>
          {MockData.plans.map(plan => (
            <div
              key={plan.id}
              className="plan-card"
              onClick={() => plan.status === 'active' && onNavigate('training')}
              style={{ cursor: plan.status === 'active' ? 'pointer' : 'default' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <span className="plan-ex-name">{plan.name}</span>
                <span className={`badge ${plan.status === 'active' ? 'badge-accent' : plan.status === 'done' ? 'badge-success' : 'badge-info'}`}>
                  {plan.badge}
                </span>
              </div>
              <div style={{ display: 'flex', gap: 12, marginBottom: plan.status !== 'pending' ? 12 : 0 }}>
                <span className="plan-ex-sets">{plan.frequency}</span>
                <span className="plan-ex-sets">{plan.difficulty}难度</span>
                <span className="plan-ex-sets">
                  {plan.status === 'pending' ? `${plan.totalWeeks}周周期` : `第${plan.week}周`}
                </span>
              </div>
              {plan.status !== 'pending' && (
                <div className="progress-track">
                  <div className="progress-fill" style={{ width: `${plan.progress}%` }} />
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      <button className="fab" title="创建新计划"><Plus /></button>
    </>
  );
}
