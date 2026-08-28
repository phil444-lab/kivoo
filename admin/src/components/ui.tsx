import type { ReactNode, ChangeEvent, CSSProperties } from 'react';
import { IconX, IconSearch, IconInbox } from './icons';
import type { Pagination } from '../api/types';

/* ------------------------------ StatCard ------------------------------ */
interface StatCardProps {
  label: string;
  value: string | number;
  icon: ReactNode;
  color?: 'primary' | 'success' | 'warning' | 'danger' | 'info';
  extra?: ReactNode;
}

export function StatCard({ label, value, icon, color = 'primary', extra }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className={`stat-icon ${color}`}>{icon}</div>
      <div>
        <div className="stat-value">{value}</div>
        <div className="stat-label">{label}</div>
        {extra && <div className="stat-extra">{extra}</div>}
      </div>
    </div>
  );
}

/* ------------------------------ Badge ------------------------------ */
type BadgeColor = 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'neutral';

export function Badge({
  color = 'neutral',
  children,
  dot = false,
}: {
  color?: BadgeColor;
  children: ReactNode;
  dot?: boolean;
}) {
  return (
    <span className={`badge ${color}`}>
      {dot && <span className="badge-dot" />}
      {children}
    </span>
  );
}

/* ------------------------------ Avatar ------------------------------ */
export function Avatar({
  name,
  photo,
  size = 'md',
}: {
  name: string;
  photo?: string | null;
  size?: 'md' | 'lg';
}) {
  const initials = name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('');
  return (
    <div className={`avatar ${size === 'lg' ? 'lg' : ''}`}>
      {photo ? <img src={photo} alt={name} /> : initials || '?'}
    </div>
  );
}

/* ------------------------------ SearchInput ------------------------------ */
export function SearchInput({
  value,
  onChange,
  placeholder = 'Rechercher...',
  onEnter,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  onEnter?: () => void;
}) {
  return (
    <div className="search-input">
      <IconSearch />
      <input
        className="input"
        type="text"
        value={value}
        placeholder={placeholder}
        onChange={(e: ChangeEvent<HTMLInputElement>) => onChange(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && onEnter) onEnter();
        }}
      />
    </div>
  );
}

/* ------------------------------ Select ------------------------------ */
export function Select({
  value,
  onChange,
  options,
  style,
}: {
  value: string;
  onChange: (value: string) => void;
  options: { value: string; label: string }[];
  style?: CSSProperties;
}) {
  return (
    <span className="select-wrap">
      <select
        className="select"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={style}
      >
        {options.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
    </span>
  );
}

/* ------------------------------ Modal ------------------------------ */
export function Modal({
  title,
  onClose,
  children,
  footer,
  size = 'md',
}: {
  title: ReactNode;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  size?: 'sm' | 'md' | 'lg';
}) {
  return (
    <div
      className="modal-overlay"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className={`modal ${size === 'lg' ? 'modal-lg' : ''} ${size === 'sm' ? 'modal-sm' : ''}`}>
        <div className="modal-header">
          <h3 className="modal-title">{title}</h3>
          <button className="modal-close" onClick={onClose} aria-label="Fermer">
            <IconX />
          </button>
        </div>
        <div className="modal-body">{children}</div>
        {footer && <div className="modal-footer">{footer}</div>}
      </div>
    </div>
  );
}

/* ------------------------------ ConfirmDialog ------------------------------ */
export function ConfirmDialog({
  title,
  message,
  confirmLabel = 'Confirmer',
  danger = false,
  loading = false,
  onConfirm,
  onCancel,
}: {
  title: string;
  message: ReactNode;
  confirmLabel?: string;
  danger?: boolean;
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <Modal
      title={title}
      onClose={onCancel}
      size="sm"
      footer={
        <>
          <button className="btn btn-outline" onClick={onCancel} disabled={loading}>
            Annuler
          </button>
          <button
            className={`btn ${danger ? 'btn-danger' : 'btn-primary'}`}
            onClick={onConfirm}
            disabled={loading}
          >
            {loading ? '...' : confirmLabel}
          </button>
        </>
      }
    >
      <div style={{ fontSize: 13.5, color: 'var(--text-muted)' }}>{message}</div>
    </Modal>
  );
}

/* ------------------------------ Loading / Empty ------------------------------ */
export function LoadingState({ label = 'Chargement...' }: { label?: string }) {
  return (
    <div className="loading-state">
      <div className="spinner" />
      <span>{label}</span>
    </div>
  );
}

export function EmptyState({ title, text }: { title: string; text?: string }) {
  return (
    <div className="empty-state">
      <IconInbox />
      <div className="empty-state-title">{title}</div>
      {text && <div className="empty-state-text">{text}</div>}
    </div>
  );
}

/* ------------------------------ Pagination ------------------------------ */
export function PaginationBar({
  pagination,
  page,
  onPageChange,
}: {
  pagination?: Pagination;
  page: number;
  onPageChange: (page: number) => void;
}) {
  if (!pagination || pagination.totalPages <= 1) {
    if (pagination && pagination.totalItems > 0) {
      return (
        <div className="pagination">
          <span className="pagination-info">{pagination.totalItems} résultat(s)</span>
        </div>
      );
    }
    return null;
  }

  const pages: number[] = [];
  const start = Math.max(1, Math.min(page - 2, pagination.totalPages - 4));
  const end = Math.min(pagination.totalPages, start + 4);
  for (let i = start; i <= end; i++) pages.push(i);

  return (
    <div className="pagination">
      <span className="pagination-info">
        Page {pagination.currentPage} / {pagination.totalPages} — {pagination.totalItems} résultat(s)
      </span>
      <div className="pagination-controls">
        <button
          className="page-btn"
          disabled={!pagination.hasPrev}
          onClick={() => onPageChange(page - 1)}
        >
          ‹
        </button>
        {pages.map((p) => (
          <button
            key={p}
            className={`page-btn ${p === page ? 'active' : ''}`}
            onClick={() => onPageChange(p)}
          >
            {p}
          </button>
        ))}
        <button
          className="page-btn"
          disabled={!pagination.hasNext}
          onClick={() => onPageChange(page + 1)}
        >
          ›
        </button>
      </div>
    </div>
  );
}

/* ------------------------------ DetailItem ------------------------------ */
export function DetailItem({
  label,
  value,
  small = false,
}: {
  label: string;
  value: ReactNode;
  small?: boolean;
}) {
  return (
    <div className="detail-item">
      <div className="detail-label">{label}</div>
      <div className={`detail-value ${small ? 'small' : ''}`}>{value}</div>
    </div>
  );
}

