import React from 'react';
import { Icons } from './Icons';

const navItems = [
  { key: 'home', icon: Icons.Home, label: '首页' },
  { key: 'plan', icon: Icons.Plan, label: '计划' },
  { key: 'stats', icon: Icons.Stats, label: '统计' },
  { key: 'exercise', icon: Icons.Exercises, label: '动作' },
  { key: 'profile', icon: Icons.Profile, label: '我的' },
];

export default function BottomNav({ current, onNavigate }) {
  return (
    <nav className="bnav">
      <div className="bnav-items">
        {navItems.map(({ key, icon: Icon, label }) => (
          <button
            key={key}
            className={`bnav-it${current === key ? ' sel' : ''}`}
            onClick={() => onNavigate(key)}
          >
            <span className="bnav-ic"><Icon /></span>
            <span className="bnav-lbl">{label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}
