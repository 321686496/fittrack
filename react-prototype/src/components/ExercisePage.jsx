import React from 'react';
import PageHeader from './PageHeader';
import { Dumbbell } from './Icons';
import MockData from '../data/mockData';

export default function ExercisePage() {
  const [cat, setCat] = React.useState('全部');

  const filtered = cat === '全部'
    ? MockData.exercises
    : MockData.exercises.filter(e => e.category === cat);

  return (
    <>
      <PageHeader title="动作库" subtitle={`${MockData.exercises.length}个专业训练动作`} />

      <div className="page-body">
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 'var(--section-gap)' }}>
          {MockData.categories.map(c => (
            <button
              key={c}
              className={`btn-secondary${cat === c ? ' active' : ''}`}
              style={{
                padding: '8px 16px',
                fontSize: 'calc(12px * var(--font-size-scale))',
                background: cat === c ? 'var(--accent-gradient)' : undefined,
                color: cat === c ? 'var(--accent-text-color)' : undefined,
                borderColor: cat === c ? 'transparent' : undefined,
              }}
              onClick={() => setCat(c)}
            >
              {c}
            </button>
          ))}
        </div>

        <div className="ex-grid">
          {filtered.map(ex => (
            <div key={ex.id} className="ex-tile">
              <div className="ex-tile-icon"><Dumbbell size={24} /></div>
              <div className="ex-tile-name">{ex.name}</div>
              <div className="ex-tile-count">{ex.category} · {ex.equip}</div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
