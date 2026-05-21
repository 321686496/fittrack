import React from 'react';
import { ThemeProvider } from './context/ThemeContext';
import AppShell from './AppShell';

export default function App() {
  return (
    <ThemeProvider>
      <AppShell />
    </ThemeProvider>
  );
}
