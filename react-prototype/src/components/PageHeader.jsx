import React from 'react';
import { ArrowLeft, Bell, Calendar } from './Icons';

export default function PageHeader({ title, subtitle, onBack }) {
  return (
    <div className="page-hd">
      {onBack ? (
        <button className="icon-btn" onClick={onBack}><ArrowLeft /></button>
      ) : (
        <div className="page-hd-title">FITPLAN</div>
      )}
      {subtitle && !onBack && (
        <div style={{ fontSize: 'calc(12px * var(--font-size-scale))', color: 'var(--text-secondary)', marginLeft: 8 }}>{subtitle}</div>
      )}
      <div className="page-hd-actions">
        <button className="icon-btn"><Bell /></button>
        <button className="icon-btn"><Calendar /></button>
      </div>
    </div>
  );
}
