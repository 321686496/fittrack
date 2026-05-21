import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

export const themes = [
  {
    id: 'deep-sport',
    name: '深邃运动',
    desc: '健身硬核玩家',
    colors: ['#080c14', '#ff5722', '#10b981'],
  },
  {
    id: 'arctic-frost',
    name: '冰霜白',
    desc: '职场白领女性',
    colors: ['#f8fafc', '#0891b2', '#e2e8f0'],
  },
  {
    id: 'forest-vital',
    name: '森林活力',
    desc: '户外自然爱好者',
    colors: ['#0a1f14', '#84cc16', '#22c55e'],
  },
  {
    id: 'neon-cyber',
    name: '赛博霓虹',
    desc: 'Z世代潮流玩家',
    colors: ['#0a0015', '#d946ef', '#22d3ee'],
  },
  {
    id: 'gold-elite',
    name: '黑金奢华',
    desc: '精英商务人士',
    colors: ['#0c0a09', '#f59e0b', '#fbbf24'],
  },
  {
    id: 'midnight-blue',
    name: '午夜蓝调',
    desc: 'IT极客程序员',
    colors: ['#0a1020', '#38bdf8', '#818cf8'],
  },
];

const STORAGE_KEY = 'fitplan-theme';
const DEFAULT_THEME = 'deep-sport';

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
