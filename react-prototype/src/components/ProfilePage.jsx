import React from 'react';
import { Icons } from './Icons';
import { useTheme } from '../context/ThemeContext';
import MockData from '../data/mockData';

const menuItems = [
  { icon: Icons.Profile, title: '个人资料', desc: '编辑头像、昵称等信息' },
  { icon: Icons.Clock, title: '训练提醒', desc: '设置训练时间和提醒' },
  { icon: Icons.Gift, title: '积分中心', desc: '查看积分和兑换奖励' },
  { icon: Icons.Invite, title: '邀请好友', desc: '邀请好友获得奖励' },
  { icon: Icons.Settings, title: '设置', desc: '应用设置和偏好' },
];

export default function ProfilePage() {
  const { user } = MockData;
  const { theme, switchTheme, themes } = useTheme();

  return (
    <div className="page on">
      <div className="pro-h">
        <div className="av-ring">
          <div className="av-in">{user.avatar}</div>
        </div>
        <div className="pro-nm">{user.name}</div>
        <div className="pro-lv">Lv.{user.level} {user.title}</div>
        <div className="pro-st-row">
          <div className="pro-st-it">
            <div className="pro-st-v">{user.totalTrainings}</div>
            <div className="pro-st-l">训练次数</div>
          </div>
          <div className="pro-st-it">
            <div className="pro-st-v">{user.totalDuration}</div>
            <div className="pro-st-l">训练时长</div>
          </div>
          <div className="pro-st-it">
            <div className="pro-st-v">{user.points.toLocaleString()}</div>
            <div className="pro-st-l">积分</div>
          </div>
        </div>
      </div>

      <div className="menu-l" style={{ marginTop: 20 }}>
        {menuItems.map(item => (
          <div key={item.title} className="menu-it">
            <div className="menu-ic-box"><item.icon size={18} /></div>
            <div className="menu-ct">
              <div className="menu-tt">{item.title}</div>
              <div className="menu-ds">{item.desc}</div>
            </div>
            <div className="menu-ar"><Icons.ArrowRight /></div>
          </div>
        ))}
      </div>

      <div className="theme-picker">
        <h3>主题风格</h3>
        <div className="theme-grid">
          {themes.map(t => (
            <div
              key={t.id}
              className={`theme-option${theme === t.id ? ' selected' : ''}`}
              onClick={() => switchTheme(t.id)}
            >
              <div className="theme-swatch">
                {t.colors.map((c, i) => (
                  <span key={i} className="theme-dot" style={{ background: c }} />
                ))}
              </div>
              <div className="theme-opt-name">{t.name}</div>
              <div className="theme-opt-desc">{t.desc}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
