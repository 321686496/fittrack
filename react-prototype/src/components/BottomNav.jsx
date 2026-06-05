import React from 'react';
import { Home, Plan, Stats, Exercises, Profile, Clipboard } from './Icons';

const navItems = [
  { key: 'home', icon: Home, label: '首页' },
  { key: 'plan', icon: Plan, label: '计划' },
  { key: 'records', icon: Clipboard, label: '记录' },
  { key: 'stats', icon: Stats, label: '统计' },
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
