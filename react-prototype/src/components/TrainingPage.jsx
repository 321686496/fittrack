import React, { useState, useEffect, useRef, useCallback } from 'react';
import Storage from '../data/storage.js';
import MockData from '../data/mockData';
import { ArrowLeft, Check, Clock, X } from './Icons';

const EXERCISE_IMAGES = {
  e1: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20bench%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e2: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20fly%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e3: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20incline%20bench%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e4: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20cable%20crossover%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e5: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20pull-up%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e6: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20row%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e7: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20lat%20pulldown%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e8: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20seated%20row%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e9: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20barbell%20squat%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e10: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20leg%20press%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e11: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20shoulder%20press%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e12: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20lateral%20raise%20form%2C%20front%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e13: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20dumbbell%20curl%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e14: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20hammer%20curl%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e15: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20plank%20hold%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
  e16: 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=fitness%20illustration%20showing%20correct%20crunch%20form%2C%20side%20view%2C%20gym%20setting%2C%20clean%20vector%20style&image_size=square',
};

export default function TrainingPage({ onNavigate }) {
  const [plan, setPlan] = useState(null);
  const [dayConfig, setDayConfig] = useState(null);
  const [exercises, setExercises] = useState([]);
  const [currentExIdx, setCurrentExIdx] = useState(0);
  const [currentSetIdx, setCurrentSetIdx] = useState(0);
  const [completed, setCompleted] = useState([]);
  const [setRecords, setSetRecords] = useState({});
  const [showRest, setShowRest] = useState(false);
  const [restSeconds, setRestSeconds] = useState(0);
  const [restPlannedTotal, setRestPlannedTotal] = useState(0);
  const [restLog, setRestLog] = useState([]);
  const [trainingDone, setTrainingDone] = useState(false);
  const [trainingStart] = useState(Date.now());
  const [weight, setWeight] = useState(0);
  const [reps, setReps] = useState(0);
  const [noExercises, setNoExercises] = useState(false);
  const timerRef = useRef(null);
  const restStartRef = useRef(null);
  const restTimeoutRef = useRef(null);
  const currentExIdxRef = useRef(0);
  const currentSetIdxRef = useRef(0);
  const exercisesRef = useRef([]);

  useEffect(() => {
    currentExIdxRef.current = currentExIdx;
  }, [currentExIdx]);

  useEffect(() => {
    currentSetIdxRef.current = currentSetIdx;
  }, [currentSetIdx]);

  useEffect(() => {
    exercisesRef.current = exercises;
  }, [exercises]);

  useEffect(() => {
    const params = window.__trainingParams || {};
    let loadedPlan = null;
    let dayIdx = params.dayIndex || 0;

    if (params.planId) {
      loadedPlan = Storage.getPlanById(params.planId);
    }

    if (!loadedPlan) {
      const plans = Storage.getPlans();
      loadedPlan = plans.find(p => p.status === 'active') || plans[0] || null;
    }

    if (!loadedPlan) {
      setNoExercises(true);
      return;
    }

    setPlan(loadedPlan);

    const days = loadedPlan.days || [];
    if (dayIdx >= days.length) dayIdx = 0;
    const day = days[dayIdx];
    setDayConfig(day || null);

    const exs = (day && day.exercises) || [];
    if (exs.length === 0) {
      setNoExercises(true);
      return;
    }

    setExercises(exs);
    setCompleted(exs.map(() => false));

    const initRecords = {};
    exs.forEach(ex => {
      initRecords[ex.id] = [];
    });
    setSetRecords(initRecords);

    const firstEx = exs[0];
    setWeight(0);
    setReps(parseInt(String(firstEx.reps).split('-').pop(), 10) || 0);
  }, []);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      if (restTimeoutRef.current) clearTimeout(restTimeoutRef.current);
    };
  }, []);

  const advanceToNext = useCallback(() => {
    const exIdx = currentExIdxRef.current;
    const setIdx = currentSetIdxRef.current;
    const exs = exercisesRef.current;
    const ex = exs[exIdx];
    if (!ex) return;

    const totalSets = typeof ex.sets === 'number' ? ex.sets : parseInt(ex.sets, 10) || 1;

    if (setIdx + 1 < totalSets) {
      setCurrentSetIdx(setIdx + 1);
      setReps(parseInt(String(ex.reps).split('-').pop(), 10) || 0);
    } else {
      setCompleted(prev => {
        const updated = [...prev];
        updated[exIdx] = true;
        return updated;
      });

      if (exIdx + 1 < exs.length) {
        setCurrentExIdx(exIdx + 1);
        setCurrentSetIdx(0);
        const nextEx = exs[exIdx + 1];
        if (nextEx) {
          setReps(parseInt(String(nextEx.reps).split('-').pop(), 10) || 0);
        }
      } else {
        setTrainingDone(true);
      }
    }
  }, []);

  const startRestTimer = useCallback((restTime, exName, plannedRest) => {
    setShowRest(true);
    setRestSeconds(restTime);
    setRestPlannedTotal(restTime);
    restStartRef.current = Date.now();

    if (timerRef.current) clearInterval(timerRef.current);
    if (restTimeoutRef.current) clearTimeout(restTimeoutRef.current);

    timerRef.current = setInterval(() => {
      setRestSeconds(prev => {
        if (prev <= 1) {
          clearInterval(timerRef.current);
          timerRef.current = null;
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    restTimeoutRef.current = setTimeout(() => {
      setShowRest(false);
      const actual = Math.round((Date.now() - restStartRef.current) / 1000);
      setRestLog(prev => [...prev, { exName, restPlanned: plannedRest, restActual: actual }]);
      setRestPlannedTotal(0);
      advanceToNext();
      restTimeoutRef.current = null;
    }, restTime * 1000);
  }, [advanceToNext]);

  const handleCompleteSet = useCallback(() => {
    const ex = exercises[currentExIdx];
    if (!ex) return;

    const totalSets = typeof ex.sets === 'number' ? ex.sets : parseInt(ex.sets, 10) || 1;

    setSetRecords(prev => {
      const updated = { ...prev };
      const records = [...(updated[ex.id] || [])];
      records[currentSetIdx] = { weight: weight || 0, reps: reps || 0 };
      updated[ex.id] = records;
      return updated;
    });

    const isLastSetOfLastEx = currentSetIdx + 1 >= totalSets && currentExIdx + 1 >= exercises.length;

    if (isLastSetOfLastEx) {
      setCompleted(prev => {
        const updated = [...prev];
        updated[currentExIdx] = true;
        return updated;
      });
      setTrainingDone(true);
    } else {
      startRestTimer(ex.restTime || 90, ex.name, ex.restTime || 90);
    }
  }, [currentExIdx, currentSetIdx, exercises, weight, reps, startRestTimer]);

  const handleSkipRest = useCallback(() => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (restTimeoutRef.current) {
      clearTimeout(restTimeoutRef.current);
      restTimeoutRef.current = null;
    }
    const actual = restStartRef.current ? Math.round((Date.now() - restStartRef.current) / 1000) : 0;
    restStartRef.current = null;
    setShowRest(false);
    setRestPlannedTotal(0);
    setRestSeconds(0);

    const ex = exercisesRef.current[currentExIdxRef.current];
    if (ex) {
      setRestLog(prev => [...prev, { exName: ex.name, restPlanned: ex.restTime || 90, restActual: actual }]);
    }
    advanceToNext();
  }, [advanceToNext]);

  const handleFinishTraining = useCallback(() => {
    const endTime = Date.now();
    const duration = Math.round((endTime - trainingStart) / 60000);
    let totalSets = 0;
    let totalWeight = 0;
    const exerciseDetails = [];

    exercises.forEach((ex, idx) => {
      const records = setRecords[ex.id] || [];
      const exSets = typeof ex.sets === 'number' ? ex.sets : parseInt(ex.sets, 10) || 1;
      totalSets += records.length;

      let exWeight = 0;
      const setDetails = records.map((r, si) => {
        const w = r.weight || 0;
        const rps = r.reps || 0;
        exWeight += w * rps;
        return { setIndex: si + 1, weight: w, reps: rps };
      });
      totalWeight += exWeight;

      exerciseDetails.push({
        exerciseId: ex.id,
        exerciseName: ex.name,
        plannedSets: exSets,
        plannedReps: ex.reps,
        sets: setDetails,
        completed: completed[idx],
      });
    });

    const muscles = dayConfig && dayConfig.muscle ? [dayConfig.muscle] : [];

    Storage.addRecord({
      planId: plan ? plan.id : '',
      planName: plan ? plan.name : '',
      date: trainingStart,
      startTime: trainingStart,
      endTime: endTime,
      duration: duration,
      totalSets: totalSets,
      totalWeight: totalWeight,
      muscles: muscles,
      exercises: exerciseDetails,
    });

    onNavigate('home');
  }, [exercises, setRecords, completed, dayConfig, plan, trainingStart, onNavigate]);

  if (noExercises) {
    return (
      <>
        <div className="page-hd">
          <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
          <div className="page-hd-title">训练</div>
          <div />
        </div>
        <div className="page-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 16 }}>
          <div style={{ width: 64, height: 64, borderRadius: 'var(--radius-xl)', background: 'var(--bg-elevated)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <X size={28} style={{ color: 'var(--text-muted)' }} />
          </div>
          <div className="today-title">暂无训练内容</div>
          <div className="today-meta">该训练日没有安排动作</div>
          <button className="btn-primary" onClick={() => onNavigate('home')}>返回首页</button>
        </div>
      </>
    );
  }

  if (trainingDone) {
    const endTime = Date.now();
    const duration = Math.round((endTime - trainingStart) / 60000);
    let totalSets = 0;
    let totalWeight = 0;

    exercises.forEach(ex => {
      const records = setRecords[ex.id] || [];
      totalSets += records.length;
      records.forEach(r => {
        totalWeight += (r.weight || 0) * (r.reps || 0);
      });
    });

    const totalWeightKg = totalWeight;
    const totalWeightTon = (totalWeight / 1000).toFixed(1);

    return (
      <>
        <div className="page-hd">
          <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
          <div className="page-hd-title">完成</div>
          <div />
        </div>
        <div className="page-body" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 20, paddingTop: 'var(--card-spacing)' }}>
          <div style={{ width: 72, height: 72, borderRadius: 'var(--radius-xl)', background: 'var(--success-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Check size={32} style={{ color: 'var(--success)' }} />
          </div>
          <div className="today-title" style={{ fontSize: 'calc(20px * var(--font-size-scale))' }}>训练完成</div>
          <div className="today-meta">{plan ? plan.name : ''}{dayConfig ? ` · ${dayConfig.label}` : ''}</div>

          <div className="stats-grid" style={{ width: '100%', marginTop: 8 }}>
            <div className="stat-card" style={{ textAlign: 'center' }}>
              <div className="stat-val font-data">{duration}</div>
              <div className="stat-lbl">训练时长(分钟)</div>
            </div>
            <div className="stat-card" style={{ textAlign: 'center' }}>
              <div className="stat-val font-data">{totalSets}</div>
              <div className="stat-lbl">总组数</div>
            </div>
            <div className="stat-card" style={{ textAlign: 'center' }}>
              <div className="stat-val font-data">{totalWeightKg >= 1000 ? totalWeightTon : totalWeightKg}</div>
              <div className="stat-lbl">{totalWeightKg >= 1000 ? '总重量(吨)' : '总重量(kg)'}</div>
            </div>
            <div className="stat-card" style={{ textAlign: 'center' }}>
              <div className="stat-val font-data">{exercises.length}</div>
              <div className="stat-lbl">动作数</div>
            </div>
          </div>

          {restLog.length > 0 && (
            <div style={{ width: '100%', marginTop: 8 }}>
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

          <button className="btn-primary w-full" style={{ marginTop: 16 }} onClick={handleFinishTraining}>
            保存并返回首页
          </button>
        </div>
      </>
    );
  }

  if (exercises.length === 0) return null;

  const currentEx = exercises[currentExIdx];
  if (!currentEx) return null;

  const totalSets = typeof currentEx.sets === 'number' ? currentEx.sets : parseInt(currentEx.sets, 10) || 1;
  const totalDone = completed.filter(Boolean).length;
  const currentExRecords = setRecords[currentEx.id] || [];
  const overallProgress = (() => {
    let done = 0;
    let total = 0;
    exercises.forEach((ex, idx) => {
      const s = typeof ex.sets === 'number' ? ex.sets : parseInt(ex.sets, 10) || 1;
      total += s;
      if (completed[idx]) {
        done += s;
      } else if (idx === currentExIdx) {
        done += currentSetIdx;
      }
    });
    return total > 0 ? Math.round((done / total) * 100) : 0;
  })();

  return (
    <>
      <div className="page-hd">
        <button className="icon-btn" onClick={() => onNavigate('home')}><ArrowLeft /></button>
        <div className="page-hd-title">{currentEx.name}</div>
        <div />
      </div>

      <div className="page-body">
        <div style={{ marginBottom: 'calc(var(--card-spacing) * 0.7)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
              整体进度
            </span>
            <span className="font-data" style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--accent-primary)' }}>
              {overallProgress}%
            </span>
          </div>
          <div className="progress-track">
            <div className="progress-fill" style={{ width: `${overallProgress}%` }} />
          </div>
        </div>

        <div className="card" style={{ marginBottom: 'var(--card-spacing)' }}>
          {EXERCISE_IMAGES[currentEx.id] && (
            <img
              src={EXERCISE_IMAGES[currentEx.id]}
              alt={currentEx.name}
              style={{
                width: '100%',
                maxHeight: 180,
                objectFit: 'cover',
                borderRadius: 'var(--radius-lg)',
                marginBottom: 12,
              }}
            />
          )}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="today-title" style={{ marginBottom: 2 }}>{currentEx.name}</div>
              <div className="today-meta">第{currentExIdx + 1}个动作 / 共{exercises.length}个</div>
            </div>
            <span className="badge badge-accent">第{currentSetIdx + 1}/{totalSets}组</span>
          </div>

          {currentExRecords.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              {currentExRecords.map((rec, si) => (
                <div key={si} className="set-row" style={{ marginBottom: 6 }}>
                  <div className="set-num" style={{ color: 'var(--success)' }}>
                    <Check size={14} />
                  </div>
                  <div className="set-info">第{si + 1}组</div>
                  <div className="font-data" style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)' }}>
                    {rec.weight}kg × {rec.reps}次
                  </div>
                </div>
              ))}
            </div>
          )}

          <div className="train-input-row">
            <div className="train-input-group">
              <label className="train-input-label">重量</label>
              <div className="train-input-wrap">
                <input
                  type="number"
                  value={weight || ''}
                  onChange={e => setWeight(Number(e.target.value))}
                  className="train-input"
                  placeholder="0"
                />
                <span className="train-input-unit">kg</span>
              </div>
            </div>
            <div className="train-input-group">
              <label className="train-input-label">次数</label>
              <div className="train-input-wrap">
                <input
                  type="number"
                  value={reps || ''}
                  onChange={e => setReps(Number(e.target.value))}
                  className="train-input"
                  placeholder="0"
                />
                <span className="train-input-unit">次</span>
              </div>
            </div>
          </div>

          <button className="btn-complete w-full" onClick={handleCompleteSet}>
            完成第{currentSetIdx + 1}组
          </button>
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
              const exTotalSets = typeof ex.sets === 'number' ? ex.sets : parseInt(ex.sets, 10) || 1;
              const exRecords = setRecords[ex.id] || [];
              const exDoneSets = exRecords.length;

              return (
                <div
                  key={ex.id}
                  className="plan-ex-item"
                  style={isCurrent ? { borderColor: 'var(--accent-primary)', background: 'var(--accent-glow)' } : {}}
                >
                  <div className="set-num" style={isDone ? { color: 'var(--success)' } : {}}>
                    {isDone ? <Check size={14} /> : (idx + 1)}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="plan-ex-name">{ex.name}</div>
                    <div className="plan-ex-sets">
                      {isCurrent && !isDone ? `${exDoneSets}/${exTotalSets}组` : `${exTotalSets}组 × ${ex.reps}次`}
                    </div>
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
                style={{ width: `${((restPlannedTotal - restSeconds) / restPlannedTotal) * 100}%` }}
              />
            </div>
            <button className="btn-primary" onClick={handleSkipRest}>跳过休息</button>
          </div>
        </div>
      )}
    </>
  );
}
