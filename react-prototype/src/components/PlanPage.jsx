import React, { useState, useEffect, useCallback } from 'react';
import PageHeader from './PageHeader';
import { Plus, Edit, Trash, Check, X, ArrowLeft } from './Icons';
import Storage from '../data/storage.js';
import MockData from '../data/mockData';

const TYPE_OPTIONS = ['三分化', '四分化', '五分化', '全身训练', '自定义'];
const DIFFICULTY_OPTIONS = ['入门', '进阶', '高级'];

const QUICK_SETUP = {
  '三分化': [
    { day: 1, label: '胸部 + 三头肌', muscle: '胸', exerciseCategories: ['胸部', '手臂'] },
    { day: 2, label: '背部 + 二头肌', muscle: '背', exerciseCategories: ['背部', '手臂'] },
    { day: 3, label: '腿部 + 肩部', muscle: '腿', exerciseCategories: ['腿部', '肩部'] },
  ],
  '四分化': [
    { day: 1, label: '胸部', muscle: '胸', exerciseCategories: ['胸部'] },
    { day: 2, label: '背部', muscle: '背', exerciseCategories: ['背部'] },
    { day: 3, label: '腿部', muscle: '腿', exerciseCategories: ['腿部'] },
    { day: 4, label: '肩部 + 手臂', muscle: '肩', exerciseCategories: ['肩部', '手臂'] },
  ],
  '五分化': [
    { day: 1, label: '胸部', muscle: '胸', exerciseCategories: ['胸部'] },
    { day: 2, label: '背部', muscle: '背', exerciseCategories: ['背部'] },
    { day: 3, label: '腿部', muscle: '腿', exerciseCategories: ['腿部'] },
    { day: 4, label: '肩部', muscle: '肩', exerciseCategories: ['肩部'] },
    { day: 5, label: '手臂 + 核心', muscle: '手臂', exerciseCategories: ['手臂', '核心'] },
  ],
  '全身训练': [
    { day: 1, label: '全身训练A', muscle: '全身', exerciseCategories: ['胸部', '背部', '腿部'] },
    { day: 2, label: '全身训练B', muscle: '全身', exerciseCategories: ['肩部', '手臂', '核心'] },
    { day: 3, label: '全身训练C', muscle: '全身', exerciseCategories: ['腿部', '胸部', '背部'] },
  ],
};

function buildDaysFromType(type) {
  const template = QUICK_SETUP[type];
  if (!template) return [];
  return template.map(d => {
    const exercises = MockData.exercises
      .filter(e => d.exerciseCategories.includes(e.category))
      .slice(0, 4)
      .map(e => ({ id: e.id, name: e.name, sets: 3, reps: '8-12', restTime: 90 }));
    return { day: d.day, label: d.label, muscle: d.muscle, exercises };
  });
}

function getFrequencyFromType(type) {
  const map = { '三分化': '6天/周', '四分化': '4天/周', '五分化': '5天/周', '全身训练': '3天/周', '自定义': '3天/周' };
  return map[type] || '3天/周';
}

const defaultForm = {
  name: '',
  type: '三分化',
  difficulty: '进阶',
  totalWeeks: 8,
  days: buildDaysFromType('三分化'),
};

function PlanCard({ plan, onClick, onEdit, onDelete }) {
  const badgeClass = plan.status === 'active'
    ? 'badge badge-accent'
    : plan.status === 'done'
      ? 'badge badge-success'
      : 'badge badge-info';

  const badgeText = plan.status === 'active'
    ? '进行中'
    : plan.status === 'done'
      ? '已完成'
      : '待开始';

  return (
    <div className="plan-card" onClick={onClick} style={{ cursor: 'pointer' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <span className="plan-ex-name" style={{ flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{plan.name}</span>
        <span className={badgeClass}>{badgeText}</span>
      </div>
      <div style={{ display: 'flex', gap: 12, marginBottom: plan.status !== 'pending' ? 12 : 0 }}>
        <span className="plan-ex-sets">{plan.frequency}</span>
        <span className="plan-ex-sets">{plan.difficulty}难度</span>
        <span className="plan-ex-sets">
          {plan.status === 'pending' ? `${plan.totalWeeks}周周期` : `第${plan.week || 1}周 / ${plan.totalWeeks}周`}
        </span>
      </div>
      {plan.status !== 'pending' && (
        <div className="progress-track">
          <div className="progress-fill" style={{ width: `${plan.progress || 0}%` }} />
        </div>
      )}
      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 4, marginTop: 8, paddingTop: 8, borderTop: '1px solid var(--border-color)' }}>
        <button
          className="icon-btn"
          style={{ width: 32, height: 32 }}
          onClick={e => { e.stopPropagation(); onEdit(plan); }}
        >
          <Edit size={16} />
        </button>
        <button
          className="icon-btn"
          style={{ width: 32, height: 32, color: 'var(--text-muted)' }}
          onClick={e => { e.stopPropagation(); onDelete(plan); }}
        >
          <Trash size={16} />
        </button>
      </div>
    </div>
  );
}

function DayEditor({ day, dayIndex, onChange, onRemove, defaultRestTime }) {
  const [showExercisePicker, setShowExercisePicker] = useState(false);
  const [editingRestId, setEditingRestId] = useState(null);

  const toggleExercise = (exercise) => {
    const exists = day.exercises.find(e => e.id === exercise.id);
    let updated;
    if (exists) {
      updated = day.exercises.filter(e => e.id !== exercise.id);
    } else {
      updated = [...day.exercises, { id: exercise.id, name: exercise.name, sets: 3, reps: '8-12', restTime: defaultRestTime || 90 }];
    }
    onChange({ ...day, exercises: updated });
  };

  const updateExerciseRestTime = (exerciseId, restTime) => {
    const updated = day.exercises.map(ex =>
      ex.id === exerciseId ? { ...ex, restTime } : ex
    );
    onChange({ ...day, exercises: updated });
  };

  return (
    <div style={{
      background: 'var(--bg-elevated)',
      border: '1px solid var(--border-color)',
      borderRadius: 'var(--radius-md)',
      padding: 12,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <span style={{ fontSize: 'calc(13px * var(--font-size-scale))', fontWeight: 700, color: 'var(--accent-primary)' }}>
          第{dayIndex + 1}天
        </span>
        <button className="icon-btn" style={{ width: 28, height: 28 }} onClick={onRemove}>
          <X size={14} />
        </button>
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 8 }}>
        <input
          style={{
            flex: 1,
            padding: '8px 10px',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-input)',
            background: 'var(--bg-card)',
            color: 'var(--text-primary)',
            fontSize: 'calc(13px * var(--font-size-scale))',
            outline: 'none',
          }}
          placeholder="训练标签，如：胸部+三头肌"
          value={day.label}
          onChange={e => onChange({ ...day, label: e.target.value })}
        />
        <select
          style={{
            padding: '8px 10px',
            border: '1px solid var(--border-color)',
            borderRadius: 'var(--radius-input)',
            background: 'var(--bg-card)',
            color: 'var(--text-primary)',
            fontSize: 'calc(13px * var(--font-size-scale))',
            outline: 'none',
          }}
          value={day.muscle}
          onChange={e => onChange({ ...day, muscle: e.target.value })}
        >
          {MockData.categories.filter(c => c !== '全部').map(c => (
            <option key={c} value={c}>{c}</option>
          ))}
          <option value="全身">全身</option>
        </select>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 8 }}>
        {day.exercises.map(ex => (
          <span
            key={ex.id}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 4,
              padding: '4px 8px',
              borderRadius: 'var(--radius-badge)',
              background: 'var(--accent-glow)',
              color: 'var(--accent-primary)',
              fontSize: 'calc(11px * var(--font-size-scale))',
              fontWeight: 600,
            }}
          >
            {ex.name}
            {editingRestId === ex.id ? (
              <input
                type="number"
                min={5}
                max={600}
                value={ex.restTime}
                autoFocus
                style={{
                  width: 40,
                  padding: '1px 3px',
                  border: '1px solid var(--accent-primary)',
                  borderRadius: 3,
                  background: 'var(--bg-card)',
                  color: 'var(--accent-primary)',
                  fontSize: 'calc(11px * var(--font-size-scale))',
                  fontWeight: 600,
                  outline: 'none',
                  textAlign: 'center',
                }}
                onClick={e => e.stopPropagation()}
                onChange={e => updateExerciseRestTime(ex.id, parseInt(e.target.value) || 90)}
                onBlur={() => setEditingRestId(null)}
                onKeyDown={e => { if (e.key === 'Enter') setEditingRestId(null); }}
              />
            ) : (
              <span
                style={{ cursor: 'pointer', opacity: 0.8 }}
                onClick={e => { e.stopPropagation(); setEditingRestId(ex.id); }}
              >
                {ex.restTime}s
              </span>
            )}
            <X size={12} style={{ cursor: 'pointer' }} onClick={() => toggleExercise(ex)} />
          </span>
        ))}
      </div>
      <button
        style={{
          background: 'none',
          border: '1px dashed var(--border-color)',
          borderRadius: 'var(--radius-input)',
          color: 'var(--text-secondary)',
          padding: '6px 12px',
          fontSize: 'calc(12px * var(--font-size-scale))',
          cursor: 'pointer',
          width: '100%',
        }}
        onClick={() => setShowExercisePicker(!showExercisePicker)}
      >
        + 添加动作
      </button>
      {showExercisePicker && (
        <div style={{
          marginTop: 8,
          maxHeight: 160,
          overflowY: 'auto',
          border: '1px solid var(--border-color)',
          borderRadius: 'var(--radius-md)',
          background: 'var(--bg-card)',
        }}>
          {MockData.exercises.map(ex => {
            const selected = day.exercises.find(e => e.id === ex.id);
            return (
              <div
                key={ex.id}
                onClick={() => toggleExercise(ex)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '8px 12px',
                  cursor: 'pointer',
                  background: selected ? 'var(--accent-glow)' : 'transparent',
                  borderBottom: '1px solid var(--border-color)',
                  fontSize: 'calc(12px * var(--font-size-scale))',
                  color: selected ? 'var(--accent-primary)' : 'var(--text-primary)',
                }}
              >
                <span>{ex.name}</span>
                <span style={{ fontSize: 'calc(10px * var(--font-size-scale))', color: 'var(--text-muted)' }}>{ex.category}</span>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function PlanModal({ editingPlan, onSave, onClose }) {
  const [form, setForm] = useState(() => {
    const settingsDefaultRestTime = Storage.getSettings().defaultRestTime || 90;
    if (editingPlan) {
      return {
        name: editingPlan.name,
        type: editingPlan.type || '自定义',
        difficulty: editingPlan.difficulty,
        totalWeeks: editingPlan.totalWeeks,
        defaultRestTime: editingPlan.defaultRestTime || settingsDefaultRestTime,
        days: editingPlan.days ? [...editingPlan.days.map(d => ({ ...d, exercises: [...d.exercises] }))] : [],
      };
    }
    return { ...defaultForm, defaultRestTime: settingsDefaultRestTime, days: buildDaysFromType('三分化') };
  });

  const handleTypeChange = (newType) => {
    const newDays = buildDaysFromType(newType);
    setForm(prev => ({
      ...prev,
      type: newType,
      frequency: getFrequencyFromType(newType),
      days: newDays,
    }));
  };

  const handleDefaultRestTimeChange = (newRestTime) => {
    setForm(prev => {
      const oldRestTime = prev.defaultRestTime;
      const updatedDays = prev.days.map(d => ({
        ...d,
        exercises: d.exercises.map(ex => ({
          ...ex,
          restTime: ex.restTime === oldRestTime ? newRestTime : ex.restTime,
        })),
      }));
      return { ...prev, defaultRestTime: newRestTime, days: updatedDays };
    });
  };

  const handleDayChange = (index, updatedDay) => {
    setForm(prev => {
      const days = [...prev.days];
      days[index] = updatedDay;
      return { ...prev, days };
    });
  };

  const handleDayRemove = (index) => {
    setForm(prev => {
      const days = prev.days.filter((_, i) => i !== index);
      return { ...prev, days };
    });
  };

  const handleAddDay = () => {
    setForm(prev => ({
      ...prev,
      days: [...prev.days, { day: prev.days.length + 1, label: '', muscle: '胸', exercises: [] }],
    }));
  };

  const handleSubmit = () => {
    if (!form.name.trim()) return;
    onSave({
      ...form,
      defaultRestTime: form.defaultRestTime,
      frequency: form.frequency || getFrequencyFromType(form.type),
      week: editingPlan ? editingPlan.week || 1 : 1,
      status: editingPlan ? editingPlan.status : 'active',
      progress: editingPlan ? editingPlan.progress || 0 : 0,
    });
  };

  const inputStyle = {
    width: '100%',
    padding: '10px 12px',
    border: '1px solid var(--border-color)',
    borderRadius: 'var(--radius-input)',
    background: 'var(--bg-elevated)',
    color: 'var(--text-primary)',
    fontSize: 'calc(14px * var(--font-size-scale))',
    outline: 'none',
  };

  const labelStyle = {
    display: 'block',
    fontSize: 'calc(12px * var(--font-size-scale))',
    color: 'var(--text-secondary)',
    marginBottom: 4,
    fontWeight: 600,
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'var(--bg-overlay)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        display: 'flex',
        alignItems: 'flex-end',
        justifyContent: 'center',
        zIndex: 300,
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: 'var(--bg-card)',
          border: 'var(--border-width) var(--border-style) var(--border-color)',
          borderRadius: 'var(--radius-xl) var(--radius-xl) 0 0',
          width: '100%',
          maxWidth: 480,
          maxHeight: '90vh',
          display: 'flex',
          flexDirection: 'column',
          boxShadow: 'var(--shadow-lg)',
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px 20px',
          borderBottom: '1px solid var(--border-color)',
          flexShrink: 0,
        }}>
          <span style={{
            fontFamily: 'var(--font-display)',
            fontWeight: 'var(--font-weight-display)',
            textTransform: 'var(--text-transform)',
            letterSpacing: 'var(--letter-spacing-display)',
            fontSize: 'calc(16px * var(--font-size-scale))',
            color: 'var(--text-primary)',
          }}>
            {editingPlan ? '编辑计划' : '创建新计划'}
          </span>
          <button className="icon-btn" style={{ width: 36, height: 36 }} onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <div style={{ padding: '16px 20px', overflowY: 'auto', flex: 1, display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div>
            <label style={labelStyle}>计划名称</label>
            <input
              style={inputStyle}
              placeholder="如：三分化增肌计划"
              value={form.name}
              onChange={e => setForm(prev => ({ ...prev, name: e.target.value }))}
            />
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ flex: 1 }}>
              <label style={labelStyle}>训练类型</label>
              <select
                style={inputStyle}
                value={form.type}
                onChange={e => handleTypeChange(e.target.value)}
              >
                {TYPE_OPTIONS.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div style={{ flex: 1 }}>
              <label style={labelStyle}>难度</label>
              <select
                style={inputStyle}
                value={form.difficulty}
                onChange={e => setForm(prev => ({ ...prev, difficulty: e.target.value }))}
              >
                {DIFFICULTY_OPTIONS.map(d => <option key={d} value={d}>{d}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label style={labelStyle}>总周数</label>
            <input
              style={{ ...inputStyle, width: 120 }}
              type="number"
              min={1}
              max={52}
              value={form.totalWeeks}
              onChange={e => setForm(prev => ({ ...prev, totalWeeks: parseInt(e.target.value) || 1 }))}
            />
          </div>

          <div>
            <label style={labelStyle}>默认休息时间(秒)</label>
            <input
              style={{ ...inputStyle, width: 120 }}
              type="number"
              min={10}
              max={600}
              value={form.defaultRestTime}
              onChange={e => handleDefaultRestTimeChange(parseInt(e.target.value) || 90)}
            />
          </div>

          <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
              <label style={{ ...labelStyle, marginBottom: 0 }}>训练日配置</label>
              <button
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--accent-primary)',
                  fontSize: 'calc(12px * var(--font-size-scale))',
                  cursor: 'pointer',
                  fontWeight: 600,
                }}
                onClick={handleAddDay}
              >
                + 添加训练日
              </button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {form.days.map((day, i) => (
                <DayEditor
                  key={i}
                  day={day}
                  dayIndex={i}
                  defaultRestTime={form.defaultRestTime}
                  onChange={updated => handleDayChange(i, updated)}
                  onRemove={() => handleDayRemove(i)}
                />
              ))}
              {form.days.length === 0 && (
                <div style={{
                  padding: 20,
                  textAlign: 'center',
                  color: 'var(--text-muted)',
                  fontSize: 'calc(13px * var(--font-size-scale))',
                  border: '1px dashed var(--border-color)',
                  borderRadius: 'var(--radius-md)',
                }}>
                  选择训练类型自动生成，或手动添加训练日
                </div>
              )}
            </div>
          </div>
        </div>

        <div style={{
          display: 'flex',
          gap: 12,
          padding: '16px 20px',
          borderTop: '1px solid var(--border-color)',
          flexShrink: 0,
        }}>
          <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>取消</button>
          <button className="btn-primary" style={{ flex: 1 }} onClick={handleSubmit} disabled={!form.name.trim()}>
            <Check size={16} />
            {editingPlan ? '保存修改' : '创建计划'}
          </button>
        </div>
      </div>
    </div>
  );
}

function DeleteConfirmModal({ plan, onConfirm, onClose }) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'var(--bg-overlay)',
        backdropFilter: 'blur(16px)',
        WebkitBackdropFilter: 'blur(16px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 300,
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: 'var(--bg-card)',
          border: 'var(--border-width) var(--border-style) var(--border-color)',
          borderRadius: 'var(--radius-xl)',
          padding: 24,
          width: 300,
          textAlign: 'center',
          boxShadow: 'var(--shadow-lg)',
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{
          width: 48,
          height: 48,
          borderRadius: 'var(--radius-lg)',
          background: 'rgba(239, 68, 68, 0.12)',
          color: '#ef4444',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 16px',
        }}>
          <Trash size={24} />
        </div>
        <div style={{
          fontFamily: 'var(--font-display)',
          fontWeight: 'var(--font-weight-display)',
          textTransform: 'var(--text-transform)',
          letterSpacing: 'var(--letter-spacing-display)',
          fontSize: 'calc(16px * var(--font-size-scale))',
          color: 'var(--text-primary)',
          marginBottom: 8,
        }}>
          删除计划
        </div>
        <div style={{
          fontSize: 'calc(13px * var(--font-size-scale))',
          color: 'var(--text-secondary)',
          marginBottom: 20,
          lineHeight: 1.6,
        }}>
          确定要删除「{plan.name}」吗？此操作不可撤销。
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>取消</button>
          <button
            style={{
              flex: 1,
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 6,
              padding: 'var(--btn-padding) 24px',
              background: '#ef4444',
              color: '#fff',
              border: 'none',
              borderRadius: 'var(--radius-btn)',
              fontFamily: 'var(--font-display)',
              fontWeight: 700,
              fontSize: 'calc(14px * var(--font-size-scale))',
              cursor: 'pointer',
              transition: 'all 0.25s ease',
            }}
            onClick={() => onConfirm(plan.id)}
          >
            确认删除
          </button>
        </div>
      </div>
    </div>
  );
}

export default function PlanPage({ onNavigate }) {
  const [plans, setPlans] = useState([]);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingPlan, setEditingPlan] = useState(null);
  const [deletingPlan, setDeletingPlan] = useState(null);

  const [selectedPlanId, setSelectedPlanId] = useState(null);

  const loadPlans = useCallback(() => {
    let data = Storage.getPlans();
    if (data.length === 0) {
      Storage.initDemoData();
      data = Storage.getPlans();
    }
    setPlans(data);
  }, []);

  useEffect(() => {
    loadPlans();
  }, [loadPlans]);

  const handleSave = (formData) => {
    if (editingPlan) {
      Storage.updatePlan(editingPlan.id, {
        name: formData.name,
        type: formData.type,
        difficulty: formData.difficulty,
        totalWeeks: formData.totalWeeks,
        defaultRestTime: formData.defaultRestTime,
        frequency: formData.frequency,
        days: formData.days,
      });
    } else {
      Storage.addPlan({
        name: formData.name,
        type: formData.type,
        difficulty: formData.difficulty,
        totalWeeks: formData.totalWeeks,
        defaultRestTime: formData.defaultRestTime,
        frequency: formData.frequency,
        week: 1,
        status: 'active',
        progress: 0,
        days: formData.days,
      });
    }
    loadPlans();
    setShowCreateModal(false);
    setEditingPlan(null);
  };

  const handleEdit = (plan) => {
    setEditingPlan(plan);
    setShowCreateModal(true);
  };

  const handleDelete = (plan) => {
    setDeletingPlan(plan);
  };

  const confirmDelete = (planId) => {
    Storage.deletePlan(planId);
    loadPlans();
    setDeletingPlan(null);
  };

  const handleCloseModal = () => {
    setShowCreateModal(false);
    setEditingPlan(null);
  };

  const activePlans = plans.filter(p => p.status === 'active');
  const otherPlans = plans.filter(p => p.status !== 'active');

  const selectedPlan = selectedPlanId ? plans.find(p => p.id === selectedPlanId) : null;

  if (selectedPlan) {
    return (
      <>
        <div className="page-hd">
          <button className="icon-btn" onClick={() => setSelectedPlanId(null)}><ArrowLeft /></button>
          <div className="page-hd-title">{selectedPlan.name}</div>
          <div />
        </div>
        <div className="page-body">
          <div className="card" style={{ marginBottom: 'var(--section-gap)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <span className={selectedPlan.status === 'active' ? 'badge badge-accent' : selectedPlan.status === 'done' ? 'badge badge-success' : 'badge badge-info'}>
                {selectedPlan.status === 'active' ? '进行中' : selectedPlan.status === 'done' ? '已完成' : '待开始'}
              </span>
              <div style={{ display: 'flex', gap: 4 }}>
                <button className="icon-btn" style={{ width: 32, height: 32 }} onClick={() => { setEditingPlan(selectedPlan); setShowCreateModal(true); }}>
                  <Edit size={16} />
                </button>
                <button className="icon-btn" style={{ width: 32, height: 32, color: 'var(--text-muted)' }} onClick={() => { setDeletingPlan(selectedPlan); }}>
                  <Trash size={16} />
                </button>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 16, marginBottom: 12 }}>
              <div><span style={{ color: 'var(--text-secondary)', fontSize: 'calc(12px * var(--font-size-scale))' }}>类型</span><div style={{ fontWeight: 600, fontSize: 'calc(14px * var(--font-size-scale))' }}>{selectedPlan.type}</div></div>
              <div><span style={{ color: 'var(--text-secondary)', fontSize: 'calc(12px * var(--font-size-scale))' }}>频率</span><div style={{ fontWeight: 600, fontSize: 'calc(14px * var(--font-size-scale))' }}>{selectedPlan.frequency}</div></div>
              <div><span style={{ color: 'var(--text-secondary)', fontSize: 'calc(12px * var(--font-size-scale))' }}>难度</span><div style={{ fontWeight: 600, fontSize: 'calc(14px * var(--font-size-scale))' }}>{selectedPlan.difficulty}</div></div>
              <div><span style={{ color: 'var(--text-secondary)', fontSize: 'calc(12px * var(--font-size-scale))' }}>进度</span><div style={{ fontWeight: 600, fontSize: 'calc(14px * var(--font-size-scale))' }}>第{selectedPlan.week || 1}/{selectedPlan.totalWeeks}周</div></div>
            </div>
            {selectedPlan.status !== 'pending' && (
              <div className="progress-track">
                <div className="progress-fill" style={{ width: `${selectedPlan.progress || 0}%` }} />
              </div>
            )}
          </div>

          <div className="sec-hd" style={{ marginBottom: 12 }}>
            <span className="sec-title">训练日</span>
            <span className="plan-ex-sets">{(selectedPlan.days || []).length} 天</span>
          </div>

          {(selectedPlan.days || []).map((day, dayIdx) => (
            <div key={dayIdx} className="card" style={{ marginBottom: 'var(--card-spacing)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 'calc(15px * var(--font-size-scale))', color: 'var(--text-primary)', marginBottom: 2 }}>
                    第{day.day || dayIdx + 1}天 · {day.label}
                  </div>
                  <span className="badge badge-accent" style={{ fontSize: 'calc(11px * var(--font-size-scale))' }}>{day.muscle}</span>
                </div>
                {selectedPlan.status === 'active' && (day.exercises || []).length > 0 && (
                  <button
                    className="btn-primary"
                    style={{ padding: '8px 16px', fontSize: 'calc(13px * var(--font-size-scale))' }}
                    onClick={() => {
                      window.__trainingParams = { planId: selectedPlan.id, dayIndex: dayIdx };
                      onNavigate('training');
                    }}
                  >
                    开始训练
                  </button>
                )}
              </div>
              {(day.exercises || []).length > 0 ? (
                <div className="plan-ex-list">
                  {day.exercises.map((ex, exIdx) => (
                    <div key={exIdx} className="plan-ex-item">
                      <div className="set-num">{exIdx + 1}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div className="plan-ex-name">{ex.name}</div>
                        <div className="plan-ex-sets">{ex.sets}组 × {ex.reps}次 · 休息{ex.restTime || 90}秒</div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ padding: '12px 0', color: 'var(--text-muted)', fontSize: 'calc(13px * var(--font-size-scale))', textAlign: 'center' }}>
                  暂未安排动作
                </div>
              )}
            </div>
          ))}
        </div>

        {showCreateModal && (
          <PlanModal editingPlan={editingPlan} onSave={handleSave} onClose={handleCloseModal} />
        )}
        {deletingPlan && (
          <DeleteConfirmModal plan={deletingPlan} onConfirm={(id) => { confirmDelete(id); setSelectedPlanId(null); }} onClose={() => setDeletingPlan(null)} />
        )}
      </>
    );
  }

  return (
    <>
      <PageHeader title="训练计划" subtitle="管理你的专属训练方案" />

      <div className="page-body">
        {activePlans.length > 0 && (
          <>
            <div className="sec-hd">
              <span className="sec-title">进行中</span>
              <span className="plan-ex-sets">{activePlans.length} 个计划</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--card-spacing)' }}>
              {activePlans.map(plan => (
                <PlanCard
                  key={plan.id}
                  plan={plan}
                  onClick={() => setSelectedPlanId(plan.id)}
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                />
              ))}
            </div>
          </>
        )}

        {otherPlans.length > 0 && (
          <>
            <div className="sec-hd" style={{ marginTop: activePlans.length > 0 ? 'var(--section-gap)' : 0 }}>
              <span className="sec-title">其他计划</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--card-spacing)' }}>
              {otherPlans.map(plan => (
                <PlanCard
                  key={plan.id}
                  plan={plan}
                  onClick={() => setSelectedPlanId(plan.id)}
                  onEdit={handleEdit}
                  onDelete={handleDelete}
                />
              ))}
            </div>
          </>
        )}

        {plans.length === 0 && (
          <div style={{
            textAlign: 'center',
            padding: '60px 20px',
            color: 'var(--text-muted)',
          }}>
            <div style={{ fontSize: 'calc(16px * var(--font-size-scale))', marginBottom: 8 }}>暂无训练计划</div>
            <div style={{ fontSize: 'calc(13px * var(--font-size-scale))' }}>点击右下角按钮创建你的第一个计划</div>
          </div>
        )}
      </div>

      <button className="fab" title="创建新计划" onClick={() => { setEditingPlan(null); setShowCreateModal(true); }}>
        <Plus />
      </button>

      {showCreateModal && (
        <PlanModal
          editingPlan={editingPlan}
          onSave={handleSave}
          onClose={handleCloseModal}
        />
      )}

      {deletingPlan && (
        <DeleteConfirmModal
          plan={deletingPlan}
          onConfirm={confirmDelete}
          onClose={() => setDeletingPlan(null)}
        />
      )}
    </>
  );
}
