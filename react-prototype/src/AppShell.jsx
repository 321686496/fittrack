import React, { useState, useCallback } from 'react';
import BottomNav from './components/BottomNav';
import HomePage from './components/HomePage';
import PlanPage from './components/PlanPage';
import TrainingPage from './components/TrainingPage';
import StatsPage from './components/StatsPage';
import ExercisePage from './components/ExercisePage';
import ProfilePage from './components/ProfilePage';

export default function AppShell() {
  const [page, setPage] = useState('home');

  const handleNavigate = useCallback((target) => {
    setPage(target);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, []);

  return (
    <div className="app">
      {page === 'home' && <HomePage onNavigate={handleNavigate} />}
      {page === 'plan' && <PlanPage onNavigate={handleNavigate} />}
      {page === 'training' && <TrainingPage onNavigate={handleNavigate} />}
      {page === 'stats' && <StatsPage />}
      {page === 'exercise' && <ExercisePage />}
      {page === 'profile' && <ProfilePage />}
      <BottomNav current={page} onNavigate={handleNavigate} />
    </div>
  );
}
