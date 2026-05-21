import React, { useState } from 'react';
import PageHeader from './PageHeader';
import { Icons } from './Icons';
import MockData from '../data/mockData';

export default function ExercisePage() {
  const [cat, setCat] = useState('全部');

  const filtered = cat === '全部'
    ? MockData.exercises
    : MockData.exercises.filter(e => e.category === cat);

  return (
    <div className="page on">
      <PageHeader title="动作库" subtitle={`${MockData.exercises.length}个专业训练动作`} />

      <div className="sec">
        <div className="cat-scroll">
          {MockData.categories.map(c => (
            <button key={c} className={`cat-tab${cat === c ? ' sel' : ''}`} onClick={() => setCat(c)}>
              {c}
            </button>
          ))}
        </div>
      </div>

      <div className="sec">
        <div className="ex-grd">
          {filtered.map(ex => (
            <div key={ex.id} className="ex-grd-it">
              <div className="ex-grd-img"><Icons.Dumbbell size={32} /></div>
              <div className="ex-grd-tt">{ex.name}</div>
              <div className="ex-grd-meta">{ex.category} · {ex.equip}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
