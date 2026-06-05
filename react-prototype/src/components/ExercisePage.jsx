import React, { useState } from 'react';
import Storage from '../data/storage.js';
import MockData from '../data/mockData';
import PageHeader from './PageHeader';
import { Search, Dumbbell, ArrowLeft, Plus } from './Icons';

const EXERCISE_DESCRIPTIONS = {
  e1: '平板杠铃卧推是胸部训练的王牌动作，主要刺激胸大肌中部，同时锻炼三角肌前束和肱三头肌。',
  e2: '哑铃飞鸟重点拉伸胸大肌，增加胸部肌肉的伸展范围，适合作为卧推的辅助动作。',
  e3: '上斜卧推主要针对胸大肌上部，帮助塑造饱满的上胸线条。',
  e4: '绳索夹胸提供持续张力，有效孤立胸大肌，适合作为收尾动作。',
  e5: '引体向上是背部训练的黄金动作，主要锻炼背阔肌和肱二头肌。',
  e6: '杠铃划船全面刺激背部肌群，特别是背阔肌中下部和菱形肌。',
  e7: '高位下拉模拟引体向上动作，适合无法完成引体向上的训练者。',
  e8: '坐姿划船重点锻炼背部中部肌群，改善体态和背部厚度。',
  e9: '深蹲是腿部训练之王，全面刺激股四头肌、臀大肌和核心肌群。',
  e10: '腿举机可以安全地使用大重量训练腿部，主要锻炼股四头肌和臀大肌。',
  e11: '哑铃推举主要锻炼三角肌中束和前束，是肩部训练的核心动作。',
  e12: '侧平举孤立刺激三角肌中束，帮助打造宽阔的肩膀。',
  e13: '哑铃弯举是肱二头肌的经典训练动作，简单有效。',
  e14: '锤式弯举同时锻炼肱二头肌和肱桡肌，增加手臂整体围度。',
  e15: '平板支撑是核心训练的基础动作，锻炼腹横肌和深层稳定肌群。',
  e16: '卷腹重点刺激腹直肌上部，是腹部训练的最基本动作。',
};

const EXERCISE_MUSCLES = {
  e1: ['胸大肌', '三角肌前束', '肱三头肌'],
  e2: ['胸大肌', '三角肌前束'],
  e3: ['胸大肌上部', '三角肌前束', '肱三头肌'],
  e4: ['胸大肌', '三角肌前束'],
  e5: ['背阔肌', '肱二头肌', '前臂'],
  e6: ['背阔肌', '菱形肌', '肱二头肌'],
  e7: ['背阔肌', '肱二头肌'],
  e8: ['背阔肌中部', '菱形肌', '斜方肌'],
  e9: ['股四头肌', '臀大肌', '核心肌群'],
  e10: ['股四头肌', '臀大肌'],
  e11: ['三角肌中束', '三角肌前束', '肱三头肌'],
  e12: ['三角肌中束', '斜方肌上部'],
  e13: ['肱二头肌', '前臂'],
  e14: ['肱二头肌', '肱桡肌', '前臂'],
  e15: ['腹横肌', '深层稳定肌群', '竖脊肌'],
  e16: ['腹直肌', '腹斜肌'],
};

const EXERCISE_IMAGES = {
  e1: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20bench%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e2: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20fly%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e3: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20incline%20bench%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e4: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20cable%20crossover%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e5: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20pull-up%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e6: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20row%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e7: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20lat%20pulldown%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e8: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20seated%20row%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e9: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20squat%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e10: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20leg%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e11: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20shoulder%20press%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e12: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20lateral%20raise%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e13: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20curl%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e14: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20hammer%20curl%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e15: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20plank%20hold%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
  e16: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20crunch%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style%2C%20professional%20exercise%20guide&image_size=square',
};

export default function ExercisePage() {
  const [cat, setCat] = useState('全部');
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState(null);
  const [showPlanPicker, setShowPlanPicker] = useState(false);
  const [addedPlan, setAddedPlan] = useState(null);
  const [imgLoaded, setImgLoaded] = useState(false);

  const filtered = MockData.exercises.filter(e => {
    const matchCat = cat === '全部' || e.category === cat;
    const matchQuery = !query || e.name.includes(query);
    return matchCat && matchQuery;
  });

  const handleSelect = (ex) => {
    setSelected(ex);
    setShowPlanPicker(false);
    setAddedPlan(null);
    setImgLoaded(false);
  };

  const handleBack = () => {
    setSelected(null);
    setShowPlanPicker(false);
    setAddedPlan(null);
  };

  const handleAddToPlan = (plan) => {
    const plans = Storage.getPlans();
    const idx = plans.findIndex(p => p.id === plan.id);
    if (idx === -1) return;
    const targetPlan = plans[idx];
    if (!targetPlan.days || targetPlan.days.length === 0) return;
    const day = targetPlan.days[0];
    if (!day.exercises) day.exercises = [];
    day.exercises.push({
      id: selected.id,
      name: selected.name,
      sets: 3,
      reps: '10-12',
      restTime: 90,
    });
    Storage.savePlans(plans);
    setAddedPlan(plan.id);
    setTimeout(() => setAddedPlan(null), 1500);
  };

  const activePlans = Storage.getPlans().filter(p => p.status === 'active');

  if (selected) {
    const desc = EXERCISE_DESCRIPTIONS[selected.id] || '';
    const muscles = EXERCISE_MUSCLES[selected.id] || [];

    return (
      <>
        <PageHeader title={selected.name} onBack={handleBack} />

        <div className="page-body">
          <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
            <div className="sec-hd">
              <Dumbbell size={20} />
              <span className="sec-title">{selected.name}</span>
            </div>

            <div style={{ display: 'flex', gap: 8, marginBottom: 'var(--section-gap, 16px)' }}>
              <span className="badge badge-accent">{selected.category}</span>
              <span className="badge">{selected.equip}</span>
            </div>

            {EXERCISE_IMAGES[selected.id] && (
              <div style={{
                width: '100%',
                aspectRatio: '4/3',
                borderRadius: 'var(--radius-lg, 12px)',
                overflow: 'hidden',
                marginBottom: 'var(--section-gap, 16px)',
                background: 'var(--bg-elevated)',
                position: 'relative',
              }}>
                {!imgLoaded && (
                  <div style={{
                    position: 'absolute',
                    inset: 0,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'var(--text-muted)',
                    fontSize: 'calc(14px * var(--font-size-scale))',
                  }}>
                    加载中...
                  </div>
                )}
                <img
                  src={EXERCISE_IMAGES[selected.id]}
                  alt={selected.name}
                  onLoad={() => setImgLoaded(true)}
                  onError={() => setImgLoaded(true)}
                  style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                    display: imgLoaded ? 'block' : 'none',
                  }}
                />
              </div>
            )}

            <p style={{
              fontSize: 'calc(14px * var(--font-size-scale))',
              lineHeight: 1.7,
              color: 'var(--text-secondary)',
              marginBottom: 'var(--section-gap, 16px)',
            }}>
              {desc}
            </p>

            <div className="sec-hd" style={{ marginBottom: 8 }}>
              <span className="sec-title">目标肌群</span>
            </div>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {muscles.map(m => (
                <span key={m} className="badge">{m}</span>
              ))}
            </div>
          </div>

          <button
            className="btn-primary"
            style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
            onClick={() => { setShowPlanPicker(true); setAddedPlan(null); }}
          >
            <Plus size={18} />
            添加到计划
          </button>

          {showPlanPicker && (
            <div className="card" style={{ marginTop: 'var(--section-gap)' }}>
              <div className="sec-hd" style={{ marginBottom: 12 }}>
                <span className="sec-title">选择计划</span>
              </div>
              {activePlans.length === 0 ? (
                <p style={{ color: 'var(--text-secondary)', fontSize: 'calc(14px * var(--font-size-scale))' }}>
                  暂无进行中的计划
                </p>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                  {activePlans.map(plan => (
                    <button
                      key={plan.id}
                      className="btn-secondary"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        width: '100%',
                        padding: '12px 16px',
                        borderColor: addedPlan === plan.id ? 'var(--success)' : undefined,
                        color: addedPlan === plan.id ? 'var(--success)' : undefined,
                      }}
                      onClick={() => handleAddToPlan(plan)}
                    >
                      <span>{plan.name}</span>
                      {addedPlan === plan.id && <span style={{ fontSize: 'calc(12px * var(--font-size-scale))' }}>已添加 ✓</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader title="动作库" subtitle={`${MockData.exercises.length}个专业训练动作`} />

      <div className="page-body">
        <div style={{
          display: 'flex',
          gap: 8,
          overflowX: 'auto',
          marginBottom: 'var(--section-gap)',
          paddingBottom: 4,
          WebkitOverflowScrolling: 'touch',
          scrollbarWidth: 'none',
        }}>
          {MockData.categories.map(c => (
            <button
              key={c}
              className={`btn-secondary${cat === c ? ' active' : ''}`}
              style={{
                padding: '8px 16px',
                fontSize: 'calc(12px * var(--font-size-scale))',
                whiteSpace: 'nowrap',
                flexShrink: 0,
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

        <div className="train-input-wrap" style={{ marginBottom: 'var(--section-gap)' }}>
          <Search size={18} />
          <input
            className="train-input"
            type="text"
            placeholder="搜索动作..."
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
        </div>

        <div className="ex-grid">
          {filtered.map(ex => (
            <div key={ex.id} className="ex-tile" onClick={() => handleSelect(ex)} style={{ position: 'relative', overflow: 'hidden' }}>
              {EXERCISE_IMAGES[ex.id] && (
                <img
                  src={EXERCISE_IMAGES[ex.id]}
                  alt=""
                  style={{
                    position: 'absolute',
                    top: 0,
                    right: 0,
                    width: 48,
                    height: 48,
                    objectFit: 'cover',
                    borderRadius: '0 var(--radius-lg, 12px) 0 var(--radius-lg, 12px)',
                    opacity: 0.5,
                  }}
                />
              )}
              <div className="ex-tile-icon"><Dumbbell size={24} /></div>
              <div className="ex-tile-name">{ex.name}</div>
              <div className="ex-tile-count">{ex.category} · {ex.equip}</div>
            </div>
          ))}
        </div>

        {filtered.length === 0 && (
          <div style={{
            textAlign: 'center',
            padding: '48px 0',
            color: 'var(--text-secondary)',
            fontSize: 'calc(14px * var(--font-size-scale))',
          }}>
            未找到匹配的动作
          </div>
        )}
      </div>
    </>
  );
}
