import React, { useState, useEffect } from 'react';
import PageHeader from './PageHeader';
import { Clock, Dumbbell, Trash, ArrowLeft, Check } from './Icons';
import Storage from '../data/storage.js';

function getDateStr(timestamp) {
  const d = new Date(timestamp);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function getTodayStr() {
  return getDateStr(Date.now());
}

function getYesterdayStr() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return getDateStr(d);
}

function getWeekStart() {
  const d = new Date();
  const day = d.getDay() || 7;
  d.setDate(d.getDate() - day + 1);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

function formatDate(timestamp) {
  const d = new Date(timestamp);
  const now = new Date();
  const todayStr = getTodayStr();
  const yesterdayStr = getYesterdayStr();
  const recordStr = getDateStr(timestamp);

  if (recordStr === todayStr) {
    return `今天 ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
  if (recordStr === yesterdayStr) {
    return `昨天 ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
  if (now.getFullYear() === d.getFullYear()) {
    return `${d.getMonth() + 1}月${d.getDate()}日 ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`;
}

function groupRecords(records) {
  const todayStr = getTodayStr();
  const yesterdayStr = getYesterdayStr();
  const weekStart = getWeekStart();

  const groups = {
    today: { label: '今天', records: [] },
    yesterday: { label: '昨天', records: [] },
    thisWeek: { label: '本周', records: [] },
    earlier: { label: '更早', records: [] },
  };

  for (const r of records) {
    const ts = r.createTime || r.date || Date.now();
    const dateStr = getDateStr(ts);

    if (dateStr === todayStr) {
      groups.today.records.push(r);
    } else if (dateStr === yesterdayStr) {
      groups.yesterday.records.push(r);
    } else if (ts >= weekStart) {
      groups.thisWeek.records.push(r);
    } else {
      groups.earlier.records.push(r);
    }
  }

  return Object.entries(groups).filter(([, g]) => g.records.length > 0);
}

export default function RecordsPage({ onNavigate }) {
  const [records, setRecords] = useState([]);
  const [expandedId, setExpandedId] = useState(null);

  useEffect(() => {
    setRecords(Storage.getRecords());
  }, []);

  const handleDelete = (e, recordId) => {
    e.stopPropagation();
    if (!window.confirm('确定要删除这条训练记录吗？')) return;
    Storage.deleteRecord(recordId);
    Storage.recalcStats();
    setRecords(Storage.getRecords());
    if (expandedId === recordId) setExpandedId(null);
  };

  const toggleExpand = (recordId) => {
    setExpandedId(prev => (prev === recordId ? null : recordId));
  };

  if (records.length === 0) {
    return (
      <>
        <div className="page-hd">
          <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
          <div className="page-hd-title">训练记录</div>
          <div />
        </div>
        <div className="page-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 16 }}>
          <div style={{ width: 64, height: 64, borderRadius: 'var(--radius-xl)', background: 'var(--bg-card)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Dumbbell size={28} style={{ color: 'var(--text-muted)' }} />
          </div>
          <div className="today-title" style={{ color: 'var(--text-secondary)' }}>还没有训练记录</div>
          <div className="today-meta">完成训练后记录会出现在这里</div>
        </div>
      </>
    );
  }

  const grouped = groupRecords(records);

  return (
    <>
      <div className="page-hd">
        <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
        <div className="page-hd-title">训练记录</div>
        <div />
      </div>

      <div className="page-body">
        {grouped.map(([key, group]) => (
          <div key={key} style={{ marginBottom: 'var(--section-gap)' }}>
            <div className="sec-hd">
              <span className="sec-title">{group.label}</span>
              <span className="sec-more font-data">{group.records.length}条记录</span>
            </div>

            {group.records.map(record => {
              const ts = record.createTime || record.date || Date.now();
              const isExpanded = expandedId === record.id;
              const totalSets = record.totalSets || 0;
              const totalWeight = record.totalWeight || 0;
              const duration = record.duration || 0;
              const muscles = record.muscles || [];
              const exercises = record.exercises || [];
              const restLogs = record.restLogs || [];

              return (
                <div
                  key={record.id}
                  className="card"
                  style={{
                    marginBottom: 'var(--card-spacing)',
                    cursor: 'pointer',
                    borderColor: isExpanded ? 'var(--accent-primary)' : undefined,
                  }}
                  onClick={() => toggleExpand(record.id)}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="today-title" style={{ marginBottom: 2 }}>{record.planName || '未命名计划'}</div>
                      <div className="today-meta" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <Clock size={13} style={{ flexShrink: 0 }} />
                        {formatDate(ts)}
                      </div>
                    </div>
                    <button
                      className="icon-btn"
                      style={{ color: 'var(--text-muted)', flexShrink: 0 }}
                      onClick={(e) => handleDelete(e, record.id)}
                    >
                      <Trash size={16} />
                    </button>
                  </div>

                  <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 8 }}>
                    {muscles.map(m => (
                      <span key={m} className="badge badge-accent">{m}</span>
                    ))}
                  </div>

                  <div style={{ display: 'flex', gap: 16 }}>
                    <div className="stat-row" style={{ flex: 1, padding: '8px 0', borderBottom: 'none' }}>
                      <div className="stat-row-lbl" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Clock size={13} />时长
                      </div>
                      <div className="stat-row-val font-data">{duration}<span style={{ fontSize: 'calc(11px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>分钟</span></div>
                    </div>
                    <div className="stat-row" style={{ flex: 1, padding: '8px 0', borderBottom: 'none' }}>
                      <div className="stat-row-lbl" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Dumbbell size={13} />组数
                      </div>
                      <div className="stat-row-val font-data">{totalSets}<span style={{ fontSize: 'calc(11px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>组</span></div>
                    </div>
                    <div className="stat-row" style={{ flex: 1, padding: '8px 0', borderBottom: 'none' }}>
                      <div className="stat-row-lbl">重量</div>
                      <div className="stat-row-val font-data">{totalWeight}<span style={{ fontSize: 'calc(11px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>kg</span></div>
                    </div>
                  </div>

                  {isExpanded && (
                    <div style={{ marginTop: 12, borderTop: '1px solid var(--border-color)', paddingTop: 12 }}>
                      {exercises.length > 0 && (
                        <div className="plan-ex-list">
                          {exercises.map((ex, idx) => (
                            <div key={ex.id || idx} className="plan-ex-item">
                              <div className="set-num" style={{ color: 'var(--success)' }}>
                                <Check size={14} />
                              </div>
                              <div style={{ flex: 1, minWidth: 0 }}>
                                <div className="plan-ex-name">{ex.name}</div>
                                <div className="plan-ex-sets">
                                  {(ex.setsData || []).map((s, si) => (
                                    <span key={si} style={{ marginRight: 8 }}>
                                      {s.weight}×{s.reps}
                                    </span>
                                  ))}
                                  {(!ex.setsData || ex.setsData.length === 0) && (
                                    <span>{ex.sets}组 × {ex.reps}次</span>
                                  )}
                                </div>
                              </div>
                              <span className="badge badge-success">完成</span>
                            </div>
                          ))}
                        </div>
                      )}

                      {restLogs.length > 0 && (
                        <div style={{ marginTop: 12 }}>
                          <div className="sec-hd" style={{ marginBottom: 8 }}>
                            <span className="sec-title" style={{ fontSize: 'calc(13px * var(--font-size-scale))' }}>休息记录</span>
                          </div>
                          {restLogs.map((log, idx) => (
                            <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 0', fontSize: 'calc(12px * var(--font-size-scale))' }}>
                              <span style={{ color: 'var(--text-secondary)' }}>{log.exName}</span>
                              <span className="font-data" style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--text-secondary)' }}>
                                <Clock size={12} />
                                {log.restActual}秒
                                {log.restActual < log.restPlanned && (
                                  <span style={{ color: 'var(--warning)', marginLeft: 4 }}>
                                    (提前{log.restPlanned - log.restActual}s)
                                  </span>
                                )}
                              </span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </>
  );
}
