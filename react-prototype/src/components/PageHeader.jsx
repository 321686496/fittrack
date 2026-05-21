import React from 'react';
import { Icons } from './Icons';

export default function PageHeader({ title, subtitle, onBack }) {
  return (
    <div className="pg-hd">
      <div className="hd-row">
        {onBack ? (
          <div className="icon-btn" onClick={onBack}><Icons.ArrowLeft /></div>
        ) : (
          <div className="logo">FITPLAN</div>
        )}
        <div className="hd-actions">
          <div className="icon-btn"><Icons.Bell /></div>
          <div className="icon-btn"><Icons.Calendar /></div>
        </div>
      </div>
      <div className="greet">{title}</div>
      {subtitle && <div className="greet-date">{subtitle}</div>}
    </div>
  );
}
