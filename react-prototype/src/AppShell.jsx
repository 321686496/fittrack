import React, { useState, useCallback } from 'react';
import BottomNav from './components/BottomNav';
import HomePage from './components/HomePage';
import PlanPage from './components/PlanPage';
import TrainingPage from './components/TrainingPage';
import StatsPage from './components/StatsPage';
import ExercisePage from './components/ExercisePage';
import ProfilePage from './components/ProfilePage';
import SettingsPage from './components/SettingsPage';
import RecordsPage from './components/RecordsPage';

export default function AppShell() {
  const [page, setPage] = useState('home');

  const handleNavigate = useCallback((target, params) => {
    if (target === 'training' && params) {
      window.__trainingParams = params;
    }
    setPage(target);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, []);

  const showNav = !['training', 'settings'].includes(page);

  return (
    <div className="app-shell" style={{ paddingBottom: showNav ? 'var(--nav-height)' : 0 }}>
      {page === 'home' && <HomePage onNavigate={handleNavigate} />}
      {page === 'plan' && <PlanPage onNavigate={handleNavigate} />}
      {page === 'training' && <TrainingPage onNavigate={handleNavigate} />}
      {page === 'stats' && <StatsPage />}
      {page === 'exercise' && <ExercisePage />}
      {page === 'profile' && <ProfilePage onNavigate={handleNavigate} />}
      {page === 'settings' && <SettingsPage onNavigate={handleNavigate} />}
      {page === 'records' && <RecordsPage onNavigate={handleNavigate} />}
      {showNav && <BottomNav current={page} onNavigate={handleNavigate} />}
    </div>
  );
}
