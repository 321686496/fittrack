import React from 'react';
import { useTheme, themes } from '../context/ThemeContext';
import { ArrowLeft, Palette, Bell, Shield, HelpCircle, ChevronRight, Moon, Smartphone } from './Icons';

export default function SettingsPage({ onNavigate }) {
  const { theme, switchTheme } = useTheme();

  return (
    <>
      <div className="page-hd">
        <button className="icon-btn" onClick={() => onNavigate('profile')}><ArrowLeft /></button>
        <div className="page-hd-title">设置</div>
        <div />
      </div>

      <div className="page-body">
        <div className="theme-section">
          <div className="theme-section-title">
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
              <Palette style={{ width: 16, height: 16 }} /> 风格主题
            </span>
          </div>
          <div className="theme-grid">
            {themes.map((t) => (
              <div
                key={t.id}
                className={`theme-card ${theme === t.id ? 'active' : ''}`}
                onClick={() => switchTheme(t.id)}
              >
                <div className="theme-preview">
                  {t.colors.map((c, i) => (
                    <div
                      key={i}
                      className="theme-preview-block"
                      style={{
                        background: c,
                        borderRadius: i === 0
                          ? `${t.preview.radius}px 0 0 ${t.preview.radius}px`
                          : i === t.colors.length - 1
                          ? `0 ${t.preview.radius}px ${t.preview.radius}px 0`
                          : '0',
                      }}
                    />
                  ))}
                </div>
                <div className="theme-card-name">
                  {t.icon} {t.name}
                </div>
                <div className="theme-card-desc">{t.desc}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="divider" />

        <div className="menu-list">
          <button className="menu-it">
            <div className="menu-it-left">
              <div className="menu-it-icon"><Bell /></div>
              <span>训练提醒</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it">
            <div className="menu-it-left">
              <div className="menu-it-icon"><Moon /></div>
              <span>深色模式</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it">
            <div className="menu-it-left">
              <div className="menu-it-icon"><Smartphone /></div>
              <span>数据同步</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it">
            <div className="menu-it-left">
              <div className="menu-it-icon"><Shield /></div>
              <span>隐私设置</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it">
            <div className="menu-it-left">
              <div className="menu-it-icon"><HelpCircle /></div>
              <span>关于</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
        </div>
      </div>
    </>
  );
}
