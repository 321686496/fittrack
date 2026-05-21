import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Icons } from './Icons';
import MockData from '../data/mockData';

export default function TrainingPage({ onNavigate }) {
  const exercises = MockData.todayPlan.exercises;
  const [currentExIdx, setCurrentExIdx] = useState(2);
  const [completed, setCompleted] = useState(() => exercises.map(ex => ex.completed));
  const [weight, setWeight] = useState(55);
  const [weightInput, setWeightInput] = useState('');
  const [reps, setReps] = useState(12);
  const [repsInput, setRepsInput] = useState('');
  const [showRest, setShowRest] = useState(false);
  const [restSeconds, setRestSeconds] = useState(90);
  const timerRef = useRef(null);

  const finishTraining = useCallback(() => {
    alert('训练完成！\n\n训练时长: 58分钟\n总组数: 24组\n总重量: 2.8吨\n消耗卡路里: 420千卡');
    onNavigate('home');
  }, [onNavigate]);

  useEffect(() => {
    if (currentExIdx >= exercises.length) {
      finishTraining();
    }
  }, [currentExIdx, exercises.length, finishTraining]);

  useEffect(() => {
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  const startRestTimer = useCallback(() => {
    setShowRest(true);
    setRestSeconds(90);
    let sec = 90;
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

  const handleCompleteSet = () => {
    const w = weightInput ? parseInt(weightInput) : weight;
    const r = repsInput ? parseInt(repsInput) : reps;
    if (w) setWeight(w);
    if (r) setReps(r);
    setWeightInput('');
    setRepsInput('');
    startRestTimer();
  };

  const handleSkipRest = () => {
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
    const updated = [...completed];
    updated[currentExIdx] = true;
    setCompleted(updated);
    setShowRest(false);
    setCurrentExIdx(i => i + 1);
  };

  useEffect(() => {
    if (!showRest && restSeconds === 0) {
      const updated = [...completed];
      updated[currentExIdx] = true;
      setCompleted(updated);
      setCurrentExIdx(i => i + 1);
    }
  }, [restSeconds, showRest, completed, currentExIdx]);

  const currentEx = exercises[currentExIdx];
  const totalDone = completed.filter(Boolean).length;

  if (!currentEx) return (
    <div className="page on">
      <div className="pg-hd">
        <div className="hd-row">
          <div className="icon-btn" onClick={() => onNavigate('home')}><Icons.ArrowLeft /></div>
          <div className="logo" style={{ fontSize: 17 }}>训练完成</div>
          <div />
        </div>
      </div>
      <div className="sec">
        <div className="empty">
          <div className="empty-ic"><Icons.Check size={32} /></div>
          <div className="empty-tt">训练完成！</div>
          <div className="empty-ds">所有动作已完成，返回首页查看总结</div>
          <button className="btn-start" onClick={() => onNavigate('home')}>返回首页</button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="page on">
      <div className="pg-hd">
        <div className="hd-row">
          <div className="icon-btn" onClick={() => onNavigate('home')}><Icons.ArrowLeft /></div>
          <div className="logo" style={{ fontSize: 17 }}>{currentEx.name}</div>
          <div className="icon-btn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} width={20} height={20}>
              <circle cx={12} cy={12} r={1} /><circle cx={19} cy={12} r={1} /><circle cx={5} cy={12} r={1} />
            </svg>
          </div>
        </div>
      </div>

      <div className="tr-pnl">
        <div className="tr-pnl-hd">
          <div className="tr-pnl-tt">{currentEx.name}</div>
          <div className="tr-pnl-sub">第{currentExIdx + 1}个动作 · 目标：{currentEx.reps}次</div>
        </div>
        <div className="tr-pnl-bd">
          <div className="cur-ex-nm">第 3 组</div>
          <div className="cur-ex-tgt">目标：{currentEx.reps}次 · 建议50-60kg</div>
          <div className="set-ipt-row">
            <div className="ipt-grp">
              <div className="ipt-lbl">重量</div>
              <input
                className="ipt-fld" type="number"
                value={weightInput || weight}
                onChange={e => setWeightInput(e.target.value)}
                placeholder={String(weight)}
              />
              <div className="ipt-unit">kg</div>
            </div>
            <div className="ipt-grp">
              <div className="ipt-lbl">次数</div>
              <input
                className="ipt-fld" type="number"
                value={repsInput || reps}
                onChange={e => setRepsInput(e.target.value)}
                placeholder={String(reps)}
              />
              <div className="ipt-unit">次</div>
            </div>
          </div>
          <button className="btn-cs" onClick={handleCompleteSet}>完成本组</button>
        </div>
      </div>

      <div className="sec" style={{ marginTop: 20 }}>
        <div className="sec-hd">
          <span className="sec-tt">动作列表</span>
          <span className="sec-lk">{totalDone}/{exercises.length} 完成</span>
        </div>
        <div className="ex-l">
          {exercises.map((ex, idx) => {
            const isDone = completed[idx];
            const isCurrent = idx === currentExIdx;
            return (
              <div key={ex.id} className={`ex-card${isCurrent ? ' cur' : ''}`}>
                <div className={`ex-num${isDone ? ' done' : ''}${isCurrent ? ' now' : ''}`}>
                  {isDone ? <Icons.Check size={14} /> : (idx + 1)}
                </div>
                <div className="ex-ct">
                  <div className="ex-nm">{ex.name}</div>
                  <div className="ex-dt">{ex.sets}组 × {ex.reps}次</div>
                </div>
                {isDone && <div className="ex-st done"><Icons.Check size={12} />已完成</div>}
                {isCurrent && !isDone && <div className="ex-st doing">进行中</div>}
              </div>
            );
          })}
        </div>
      </div>

      {showRest && (
        <div className="rest-ol">
          <div className="rest-ct">
            <div className="rest-tm">{restSeconds}</div>
            <div className="rest-lbl">组间休息</div>
            <button className="rest-skip" onClick={handleSkipRest}>跳过休息</button>
          </div>
        </div>
      )}
    </div>
  );
}
