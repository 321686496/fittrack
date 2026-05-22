import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

export const themes = [
  {
    id: 'iron-forge',
    name: '硬核铁馆',
    desc: '男性健身玩家',
    icon: '🏋️',
    colors: ['#0a0e14', '#ef4444', '#f97316'],
    preview: { radius: 0, border: 3, shadow: 'hard' },
  },
  {
    id: 'blossom',
    name: '柔美花语',
    desc: '女性优雅健身',
    icon: '🌸',
    colors: ['#fdf2f8', '#ec4899', '#f9a8d4'],
    preview: { radius: 20, border: 1, shadow: 'soft' },
  },
  {
    id: 'silver-care',
    name: '长者关怀',
    desc: '大字清晰易读',
    icon: '🛡️',
    colors: ['#ffffff', '#059669', '#34d399'],
    preview: { radius: 12, border: 2, shadow: 'medium' },
  },
  {
    id: 'fresh-minimal',
    name: '清新极简',
    desc: '简洁留白美学',
    icon: '🍃',
    colors: ['#f8fafc', '#0ea5e9', '#e0f2fe'],
    preview: { radius: 8, border: 1, shadow: 'subtle' },
  },
  {
    id: 'neon-cyber',
    name: '赛博霓虹',
    desc: 'Z世代潮流玩家',
    icon: '⚡',
    colors: ['#0a0015', '#d946ef', '#22d3ee'],
    preview: { radius: 2, border: 1, shadow: 'glow' },
  },
  {
    id: 'black-gold',
    name: '黑金尊享',
    desc: '商务精英品质',
    icon: '👑',
    colors: ['#0c0a09', '#f59e0b', '#fbbf24'],
    preview: { radius: 10, border: 1, shadow: 'gold' },
  },
];

const STORAGE_KEY = 'fitplan-theme';
const DEFAULT_THEME = 'iron-forge';

const ThemeContext = createContext(null);

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(() => {
    try {
      return localStorage.getItem(STORAGE_KEY) || DEFAULT_THEME;
    } catch {
      return DEFAULT_THEME;
    }
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch { /* noop */ }
  }, [theme]);

  const switchTheme = useCallback((id) => {
    setTheme(id);
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, switchTheme, themes }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
