import React, { useState } from 'react';
import { useTheme, themes } from '../context/ThemeContext';
import { ArrowLeft, Palette, Bell, Shield, HelpCircle, ChevronRight, Moon, Smartphone, Download, Upload, Trash } from './Icons';
import Storage from '../data/storage.js';

export default function SettingsPage({ onNavigate }) {
  const { theme, switchTheme } = useTheme();
  const [toast, setToast] = useState('');

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(''), 2000);
  };

  const handleExport = () => {
    const data = Storage.exportAllData();
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `fitplan_backup_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('数据已导出');
  };

  const handleImport = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (ev) => {
        try {
          const data = JSON.parse(ev.target.result);
          if (Storage.importData(data)) {
            showToast('数据已导入');
          } else {
            showToast('导入失败：文件格式不正确');
          }
        } catch {
          showToast('导入失败：文件解析错误');
        }
      };
      reader.readAsText(file);
    };
    input.click();
  };

  const handleClear = () => {
    if (window.confirm('确定要清除所有数据吗？此操作不可恢复！')) {
      Storage.clearAll();
      showToast('数据已清除');
    }
  };

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

        <div className="card" style={{ marginBottom: 'var(--section-gap, 16px)' }}>
          <div style={{ fontSize: 'calc(13px * var(--font-size-scale))', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            训练设置
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 'calc(14px * var(--font-size-scale))', color: 'var(--text-primary)' }}>默认休息时间(秒)</span>
            <input
              type="number"
              min={10}
              max={600}
              value={Storage.getSettings().defaultRestTime || 90}
              onChange={e => {
                const val = parseInt(e.target.value) || 90;
                const settings = Storage.getSettings();
                Storage.saveSettings({ ...settings, defaultRestTime: val, restTime: val });
                showToast('休息时间已更新');
              }}
              style={{
                width: 80,
                padding: '8px 10px',
                border: '1px solid var(--border-color)',
                borderRadius: 'var(--radius-input)',
                background: 'var(--bg-elevated)',
                color: 'var(--text-primary)',
                fontSize: 'calc(14px * var(--font-size-scale))',
                outline: 'none',
                textAlign: 'center',
              }}
            />
          </div>
        </div>

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
          <button className="menu-it" onClick={handleExport}>
            <div className="menu-it-left">
              <div className="menu-it-icon"><Download /></div>
              <span>导出数据</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it" onClick={handleImport}>
            <div className="menu-it-left">
              <div className="menu-it-icon"><Upload /></div>
              <span>导入数据</span>
            </div>
            <div className="menu-it-arrow"><ChevronRight /></div>
          </button>
          <button className="menu-it" onClick={handleClear}>
            <div className="menu-it-left">
              <div className="menu-it-icon"><Trash /></div>
              <span style={{ color: 'var(--danger, #ef4444)' }}>清除数据</span>
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

      {toast && (
        <div style={{
          position: 'fixed',
          bottom: 100,
          left: '50%',
          transform: 'translateX(-50%)',
          background: 'var(--accent-primary)',
          color: '#fff',
          padding: '10px 24px',
          borderRadius: 'var(--radius-full, 999px)',
          fontSize: 14,
          zIndex: 9999,
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        }}>
          {toast}
        </div>
      )}
    </>
  );
}
