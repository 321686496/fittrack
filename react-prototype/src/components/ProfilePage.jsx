import React from 'react';
import { User, Settings, Bell, Shield, HelpCircle, ChevronRight, LogOut, Smartphone, Trophy, Target } from './Icons';
import MockData from '../data/mockData';

export default function ProfilePage({ onNavigate }) {
  const { achievements, bodyData } = MockData;
  const unlocked = achievements.filter(a => a.unlocked).length;

  return (
    <div className="page-body">
      <div className="profile-header">
        <div className="av-border">
          <User />
        </div>
        <div className="profile-name">健身达人</div>
        <div className="profile-email">user@fitplan.pro</div>
      </div>

      <div style={{ marginBottom: 'var(--section-gap)' }}>
        <div className="sec-hd">
          <span className="sec-title">训练成就</span>
          <span className="sec-more">{unlocked}/{achievements.length} 已解锁</span>
        </div>
        <div className="achieve-grid">
          {achievements.map(a => (
            <div key={a.id} className={`achieve-item${a.unlocked ? ' unlocked' : ''}`}>
              <div className="achieve-icon">{a.icon}</div>
              <div className="achieve-name">{a.name}</div>
              <div className="achieve-desc">{a.desc}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ marginBottom: 'var(--section-gap)' }}>
        <div className="sec-hd">
          <span className="sec-title">身体数据</span>
          <span className="today-meta">更新于 {bodyData.lastUpdate}</span>
        </div>
        <div className="card">
          <div className="body-grid">
            <div className="body-item">
              <div className="body-val font-data">{bodyData.height}</div>
              <div className="body-lbl">身高cm</div>
            </div>
            <div className="body-item">
              <div className="body-val font-data">{bodyData.weight}</div>
              <div className="body-lbl">体重kg</div>
            </div>
            <div className="body-item">
              <div className="body-val font-data">{bodyData.bmi}</div>
              <div className="body-lbl">BMI</div>
            </div>
            <div className="body-item">
              <div className="body-val font-data">{bodyData.bodyFat}</div>
              <div className="body-lbl">体脂率%</div>
            </div>
          </div>
          <div className="divider" />
          <div className="body-detail-grid">
            <div className="body-detail-item">
              <span className="body-detail-lbl">胸围</span>
              <span className="body-detail-val font-data">{bodyData.chest}cm</span>
            </div>
            <div className="body-detail-item">
              <span className="body-detail-lbl">腰围</span>
              <span className="body-detail-val font-data">{bodyData.waist}cm</span>
            </div>
            <div className="body-detail-item">
              <span className="body-detail-lbl">臀围</span>
              <span className="body-detail-val font-data">{bodyData.hip}cm</span>
            </div>
          </div>
        </div>
      </div>

      <div className="divider" />

      <div className="menu-list">
        <button className="menu-it" onClick={() => onNavigate('settings')}>
          <div className="menu-it-left">
            <div className="menu-it-icon"><Settings /></div>
            <span>设置</span>
          </div>
          <div className="menu-it-arrow"><ChevronRight /></div>
        </button>
        <button className="menu-it">
          <div className="menu-it-left">
            <div className="menu-it-icon"><Bell /></div>
            <span>提醒设置</span>
          </div>
          <div className="menu-it-arrow"><ChevronRight /></div>
        </button>
        <button className="menu-it">
          <div className="menu-it-left">
            <div className="menu-it-icon"><Smartphone /></div>
            <span>设备连接</span>
          </div>
          <div className="menu-it-arrow"><ChevronRight /></div>
        </button>
        <button className="menu-it">
          <div className="menu-it-left">
            <div className="menu-it-icon"><Shield /></div>
            <span>隐私与安全</span>
          </div>
          <div className="menu-it-arrow"><ChevronRight /></div>
        </button>
        <button className="menu-it">
          <div className="menu-it-left">
            <div className="menu-it-icon"><HelpCircle /></div>
            <span>帮助与反馈</span>
          </div>
          <div className="menu-it-arrow"><ChevronRight /></div>
        </button>
      </div>

      <div className="divider" />

      <button className="menu-it" style={{ color: 'var(--accent-primary)' }}>
        <div className="menu-it-left">
          <div className="menu-it-icon" style={{ color: 'var(--accent-primary)' }}><LogOut /></div>
          <span>退出登录</span>
        </div>
      </button>
    </div>
  );
}
