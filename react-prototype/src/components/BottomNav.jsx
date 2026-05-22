import React from 'react';
import { Home, Plan, Stats, Exercises, Profile } from './Icons';

const navItems = [
  { key: 'home', icon: Home, label: '首页' },
  { key: 'plan', icon: Plan, label: '计划' },
  { key: 'stats', icon: Stats, label: '统计' },
  { key: 'exercise', icon: Exercises, label: '动作' },
  { key: 'profile', icon: Profile, label: '我的' },
];

export default function BottomNav({ current, onNavigate }) {
  return (
    <nav className="bnav">
      {navItems.map(({ key, icon: Icon, label }) => (
        <button
          key={key}
          className={`bnav-it${current === key ? ' active' : ''}`}
          onClick={() => onNavigate(key)}
        >
          <span className="bnav-ic"><Icon /></span>
          <span className="bnav-lbl">{label}</span>
        </button>
      ))}
    </nav>
  );
}
