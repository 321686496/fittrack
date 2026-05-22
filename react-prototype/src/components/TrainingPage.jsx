import React, { useState, useEffect, useRef, useCallback } from 'react';
import { ArrowLeft, Check, Clock } from './Icons';
import MockData from '../data/mockData';

export default function TrainingPage({ onNavigate }) {
  const exercises = MockData.todayPlan.exercises;
  const [currentExIdx, setCurrentExIdx] = useState(2);
  const [completed, setCompleted] = useState(() => exercises.map(ex => ex.completed));
  const [weight, setWeight] = useState(55);
  const [reps, setReps] = useState(12);
  const [showRest, setShowRest] = useState(false);
  const [restSeconds, setRestSeconds] = useState(90);
  const [restLog, setRestLog] = useState([]);
  const [trainingStart] = useState(Date.now());
  const timerRef = useRef(null);

  const finishTraining = useCallback(() => {
    const mins = Math.round((Date.now() - trainingStart) / 60000);
    alert(`训练完成！\n\n训练时长: ${mins}分钟\n总组数: 24组\n总重量: 2.8吨\n消耗卡路里: 420千卡`);
    onNavigate('home');
  }, [onNavigate, trainingStart]);

  useEffect(() => {
    if (currentExIdx >= exercises.length) finishTraining();
  }, [currentExIdx, exercises.length, finishTraining]);

  useEffect(() => () => { if (timerRef.current) clearInterval(timerRef.current); }, []);

  const startRestTimer = useCallback((restTime) => {
    setShowRest(true);
    setRestSeconds(restTime);
    let sec = restTime;
    if (timerRef.current) clearInterval(timerRef.current);
    timerRef.current = setInterval(() => {
      sec -= 1;
      setRestSeconds(sec);
      if (sec <= 0) {
        clearInterval(timerRef.current);
        timerRef.current = null;
        setShowRest(false);
      }
    }, 1000);
  }, []);

  const handleCompleteSet = useCallback(() => {
    const ex = exercises[currentExIdx];
    startRestTimer(ex.restTime || 90);
  }, [currentExIdx, exercises, startRestTimer]);

  const advanceToNext = useCallback((actualRestSec) => {
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
    const ex = exercises[currentExIdx];
    setRestLog(prev => [...prev, { exName: ex.name, restPlanned: ex.restTime || 90, restActual: actualRestSec }]);
    const updated = [...completed];
    updated[currentExIdx] = true;
    setCompleted(updated);
    setShowRest(false);
    setCurrentExIdx(i => i + 1);
  }, [completed, currentExIdx, exercises]);

  const handleSkipRest = useCallback(() => {
    const planned = exercises[currentExIdx].restTime || 90;
    const actual = planned - restSeconds;
    advanceToNext(actual);
  }, [advanceToNext, currentExIdx, exercises, restSeconds]);

  useEffect(() => {
    if (!showRest && restSeconds === 0) {
      const planned = exercises[currentExIdx]?.restTime || 90;
      advanceToNext(planned);
    }
  }, [restSeconds, showRest, advanceToNext, currentExIdx, exercises]);

  const currentEx = exercises[currentExIdx];
  const totalDone = completed.filter(Boolean).length;

  if (!currentEx) return (
    <>
      <div className="page-hd">
        <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
        <div className="page-hd-title">完成</div>
        <div />
      </div>
      <div className="page-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 16 }}>
        <div style={{ width: 64, height: 64, borderRadius: 'var(--radius-xl)', background: 'var(--success-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Check size={28} style={{ color: 'var(--success)' }} />
        </div>
        <div className="today-title">训练完成</div>
        <div className="today-meta">所有动作已完成</div>
        <button className="btn-primary" onClick={() => onNavigate('home')}>返回首页</button>
      </div>
    </>
  );

  return (
    <>
      <div className="page-hd">
        <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
        <div className="page-hd-title">{currentEx.name}</div>
        <div />
      </div>

      <div className="page-body">
        <div className="card" style={{ marginBottom: 'var(--card-spacing)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="today-title" style={{ marginBottom: 2 }}>{currentEx.name}</div>
              <div className="today-meta">第{currentExIdx + 1}个动作 / 共{exercises.length}个</div>
            </div>
            <span className="badge badge-accent">{currentEx.sets}组 × {currentEx.reps}次</span>
          </div>

          <div className="train-input-row">
            <div className="train-input-group">
              <label className="train-input-label">重量</label>
              <div className="train-input-wrap">
                <input
                  type="number"
                  value={weight}
                  onChange={e => setWeight(Number(e.target.value))}
                  className="train-input"
                />
                <span className="train-input-unit">kg</span>
              </div>
            </div>
            <div className="train-input-group">
              <label className="train-input-label">次数</label>
              <div className="train-input-wrap">
                <input
                  type="number"
                  value={reps}
                  onChange={e => setReps(Number(e.target.value))}
                  className="train-input"
                />
                <span className="train-input-unit">次</span>
              </div>
            </div>
          </div>

          <button className="btn-complete w-full" onClick={handleCompleteSet}>完成本组</button>
        </div>

        {restLog.length > 0 && (
          <div style={{ marginBottom: 'var(--card-spacing)' }}>
            <div className="sec-hd">
              <span className="sec-title">休息记录</span>
            </div>
            <div className="rest-log-list">
              {restLog.map((log, idx) => (
                <div key={idx} className="rest-log-item">
                  <div className="rest-log-name">{log.exName}</div>
                  <div className="rest-log-time">
                    <Clock size={12} style={{ marginRight: 4 }} />
                    休息 {log.restActual}秒
                    {log.restActual < log.restPlanned && (
                      <span style={{ color: 'var(--warning)', marginLeft: 6 }}>
                        (提前{log.restPlanned - log.restActual}s)
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div>
          <div className="sec-hd">
            <span className="sec-title">动作列表</span>
            <span className="font-data" style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
              {totalDone}/{exercises.length}
            </span>
          </div>
          <div className="plan-ex-list">
            {exercises.map((ex, idx) => {
              const isDone = completed[idx];
              const isCurrent = idx === currentExIdx;
              return (
                <div key={ex.id} className="plan-ex-item" style={isCurrent ? { borderColor: 'var(--accent-primary)', background: 'var(--accent-glow)' } : {}}>
                  <div className="set-num" style={isDone ? { color: 'var(--success)' } : {}}>
                    {isDone ? <Check size={14} /> : (idx + 1)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="plan-ex-name">{ex.name}</div>
                    <div className="plan-ex-sets">{ex.sets}组 × {ex.reps}次</div>
                  </div>
                  {isDone && <span className="badge badge-success">完成</span>}
                  {isCurrent && !isDone && <span className="badge badge-accent">进行中</span>}
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {showRest && (
        <div className="rest-overlay">
          <div className="rest-modal">
            <div className="rest-modal-label">组间休息</div>
            <div className="rest-modal-timer font-data">{restSeconds}</div>
            <div className="rest-modal-sub">秒后继续</div>
            <div className="rest-modal-progress">
              <div
                className="rest-modal-progress-fill"
                style={{ width: `${((exercises[currentExIdx]?.restTime || 90 - restSeconds) / (exercises[currentExIdx]?.restTime || 90)) * 100}%` }}
              />
            </div>
            <button className="btn-primary" onClick={handleSkipRest}>跳过休息</button>
          </div>
        </div>
      )}
    </>
  );
}
