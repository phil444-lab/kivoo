import { useCallback, useEffect, useState } from 'react';
import { adminApi, apiList } from '../api/client';
import type { AdminReport, Pagination } from '../api/types';
import {
  Badge,
  SearchInput,
  LoadingState,
  EmptyState,
  PaginationBar,
  Avatar,
  Modal,
  ConfirmDialog,
  DetailItem,
} from '../components/ui';
import ItemDetailModal from '../components/ItemDetailModal';
import { formatDateTime, formatPrice } from '../utils/format';
import { useToast } from '../context/ToastContext';
import { IconEye, IconTrash, IconWarn, IconBan } from '../components/icons';

const TABS = [
  { value: 'pending', label: 'En attente' },
  { value: 'reviewed', label: 'Revus' },
  { value: 'resolved', label: 'Résolus' },
  { value: 'dismissed', label: 'Rejetés' },
  { value: 'all', label: 'Tous' },
];

const STATUS_BADGES: Record<string, 'warning' | 'info' | 'success' | 'neutral'> = {
  pending: 'warning',
  reviewed: 'info',
  resolved: 'success',
  dismissed: 'neutral',
};

type ModerateAction = 'delete_item' | 'warn_user' | 'ban_user' | null;

export default function ReportsPage() {
  const { showToast } = useToast();
  const [reports, setReports] = useState<AdminReport[]>([]);
  const [pagination, setPagination] = useState<Pagination | undefined>();
  const [status, setStatus] = useState('pending');
  const [search, setSearch] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [detailReport, setDetailReport] = useState<AdminReport | null>(null);
  const [viewItem, setViewItem] = useState<string | null>(null);
  const [moderateAction, setModerateAction] = useState<{ report: AdminReport; action: ModerateAction } | null>(null);
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiList<AdminReport>('/reports', {
        status,
        page,
        limit: 20,
        search: searchQuery,
      });
      setReports((data.reports as AdminReport[]) || []);
      setPagination(data.pagination as Pagination);
    } catch {
      setReports([]);
    } finally {
      setLoading(false);
    }
  }, [status, page, searchQuery]);

  useEffect(() => {
    void load();
  }, [load]);

  const closeModerate = () => {
    setModerateAction(null);
    setNote('');
  };

  const handleModerate = async () => {
    if (!moderateAction || !moderateAction.action) return;
    setBusy(true);
    try {
      const result = await adminApi<{ message: string }>(`/reports/${moderateAction.report.id}/moderate`, {
        method: 'POST',
        body: { action: moderateAction.action, status: 'resolved', note: note || undefined },
      });
      showToast('success', 'Modération', result.message || 'Signalement traité');
      closeModerate();
      setDetailReport(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    } finally {
      setBusy(false);
    }
  };

  const handleDismiss = async (report: AdminReport) => {
    setBusy(true);
    try {
      await adminApi(`/reports/${report.id}/status`, {
        method: 'PATCH',
        body: { status: 'dismissed' },
      });
      showToast('success', 'Signalement rejeté', 'Le signalement a été classé sans suite');
      setDetailReport(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    } finally {
      setBusy(false);
    }
  };

  const renderActionButtons = (report: AdminReport) => (
    <>
      <button
        className="btn btn-sm btn-outline"
        title="Voir l'annonce signalée"
        onClick={() => setViewItem(report.reportedItemId)}
      >
        <IconEye /> Annonce
      </button>
      <button
        className="btn btn-sm btn-danger"
        title="Supprimer l'annonce signalée"
        onClick={() => setModerateAction({ report, action: 'delete_item' })}
      >
        <IconTrash /> Supprimer l'annonce
      </button>
      <button
        className="btn btn-sm btn-warning"
        title="Avertir l'utilisateur signalé"
        onClick={() => setModerateAction({ report, action: 'warn_user' })}
      >
        <IconWarn /> Avertir
      </button>
      <button
        className="btn btn-sm btn-danger"
        title="Bannir le compte"
        onClick={() => setModerateAction({ report, action: 'ban_user' })}
      >
        <IconBan /> Bannir
      </button>
      <button
        className="btn btn-sm btn-ghost"
        disabled={busy}
        onClick={() => handleDismiss(report)}
        title="Classer sans suite"
      >
        Rejeter
      </button>
    </>
  );

  const moderateLabels: Record<string, { title: string; confirm: string; danger: boolean; message: string }> = {
    delete_item: {
      title: 'Supprimer l\'annonce',
      confirm: 'Supprimer définitivement',
      danger: true,
      message:
        'L\'annonce et toutes ses données (favoris, conversations, signalements) seront supprimées. Cette action est irréversible.',
    },
    warn_user: {
      title: 'Avertir l\'utilisateur',
      confirm: 'Envoyer l\'avertissement',
      danger: false,
      message: 'Une notification système contenant votre message sera envoyée à l\'utilisateur signalé.',
    },
    ban_user: {
      title: 'Bannir le compte',
      confirm: 'Bannir le compte',
      danger: true,
      message:
        'Le compte sera désactivé, toutes ses sessions invalidées et l\'utilisateur sera notifié. Réversible via la gestion des utilisateurs.',
    },
  };

  return (
    <div>
      <div className="card">
        <div className="card-header" style={{ flexWrap: 'wrap' }}>
          <div className="tabs">
            {TABS.map((tab) => (
              <button
                key={tab.value}
                className={`tab ${status === tab.value ? 'active' : ''}`}
                onClick={() => {
                  setStatus(tab.value);
                  setPage(1);
                }}
              >
                {tab.label}
              </button>
            ))}
          </div>
          <SearchInput
            value={search}
            onChange={setSearch}
            onEnter={() => {
              setSearchQuery(search);
              setPage(1);
            }}
            placeholder="Rechercher un motif ou une annonce..."
          />
        </div>

        {loading ? (
          <LoadingState />
        ) : reports.length === 0 ? (
          <EmptyState
            title="Aucun signalement"
            text={status === 'pending' ? 'Tous les signalements ont été traités 🎉' : 'Aucun résultat pour ce filtre'}
          />
        ) : (
          <>
            <div className="table-wrapper">
              <table className="table">
                <thead>
                  <tr>
                    <th>Motif</th>
                    <th>Annonce signalée</th>
                    <th>Signaleur</th>
                    <th>Utilisateur signalé</th>
                    <th>Statut</th>
                    <th>Date</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((report) => (
                    <tr key={report.id}>
                      <td>
                        <div className="cell-main">{report.reason}</div>
                        {report.description && (
                          <div className="cell-sub" style={{ maxWidth: 220 }}>
                            {report.description}
                          </div>
                        )}
                      </td>
                      <td>
                        <div
                          className="cell-main"
                          style={{ cursor: 'pointer' }}
                          onClick={() => setViewItem(report.reportedItemId)}
                        >
                          {report.reportedItem?.title || 'Annonce supprimée'}
                        </div>
                        <div className="cell-sub">{formatPrice(report.reportedItem?.price || 0)}</div>
                      </td>
                      <td>
                        <div className="person-row">
                          <Avatar name={report.reporter?.name || '?'} photo={report.reporter?.photo} />
                          <div>
                            <div className="cell-main" style={{ fontSize: 13 }}>{report.reporter?.name}</div>
                            <div className="cell-sub">{report.reporter?.phone}</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="person-row">
                          <Avatar name={report.reportedUser?.name || '?'} photo={report.reportedUser?.photo} />
                          <div>
                            <div className="cell-main" style={{ fontSize: 13 }}>{report.reportedUser?.name}</div>
                            <div className="cell-sub">{report.reportedUser?.phone}</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <Badge color={STATUS_BADGES[report.status] || 'neutral'} dot>
                          {report.status}
                        </Badge>
                      </td>
                      <td className="cell-sub">{formatDateTime(report.createdAt)}</td>
                      <td>
                        <div className="cell-actions">
                          <button className="btn btn-sm btn-ghost" onClick={() => setDetailReport(report)}>
                            <IconEye /> Détail
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <PaginationBar pagination={pagination} page={page} onPageChange={setPage} />
          </>
        )}
      </div>

      {/* Modal détail du signalement */}
      {detailReport && (
        <Modal
          title={`Signalement : ${detailReport.reason}`}
          onClose={() => setDetailReport(null)}
          size="lg"
        >
          <div className="detail-grid">
            <DetailItem
              label="Statut"
              value={
                <Badge color={STATUS_BADGES[detailReport.status]} dot>
                  {detailReport.status}
                </Badge>
              }
              small
            />
            <DetailItem label="Motif" value={detailReport.reason} small />
            <DetailItem label="Créé le" value={formatDateTime(detailReport.createdAt)} small />
            <DetailItem
              label="Traité par"
              value={detailReport.reviewedBy?.name || (detailReport.reviewedAt ? formatDateTime(detailReport.reviewedAt) : '—')}
              small
            />
          </div>

          {detailReport.description && (
            <>
              <div className="section-title">Détails du signalement</div>
              <div
                style={{
                  background: 'var(--surface)',
                  border: '1px solid var(--outline)',
                  borderRadius: 'var(--radius-md)',
                  padding: '12px 14px',
                  fontSize: 13,
                  color: 'var(--text-muted)',
                }}
              >
                {detailReport.description}
              </div>
            </>
          )}

          <div className="section-title">Annonce signalée</div>
          <div className="detail-grid">
            <DetailItem
              label="Titre"
              value={
                <a
                  onClick={() => {
                    setViewItem(detailReport.reportedItemId);
                    setDetailReport(null);
                  }}
                  style={{ cursor: 'pointer' }}
                >
                  {detailReport.reportedItem?.title}
                </a>
              }
              small
            />
            <DetailItem label="Prix" value={formatPrice(detailReport.reportedItem?.price || 0)} small />
            <DetailItem label="Statut annonce" value={detailReport.reportedItem?.status} small />
            <DetailItem
              label="Signalements sur l'annonce"
              value={detailReport.reportedItem?._count?.reports ?? '—'}
              small
            />
          </div>

          <div className="section-title">Utilisateur signalé</div>
          <div className="person-row">
            <Avatar name={detailReport.reportedUser?.name || '?'} photo={detailReport.reportedUser?.photo} size="lg" />
            <div>
              <div className="detail-value">{detailReport.reportedUser?.name}</div>
              <div className="detail-value small">
                {detailReport.reportedUser?.email} · {detailReport.reportedUser?.phone}
              </div>
              <div className="detail-value small">
                Compte : {detailReport.reportedUser?.isActive ? 'actif' : 'banni'}
              </div>
            </div>
          </div>

          {detailReport.status === 'pending' && (
            <div style={{ marginTop: 18 }}>
              <div className="section-title">Actions de modération rapide</div>
              <div className="cell-actions" style={{ justifyContent: 'flex-start' }}>
                {renderActionButtons(detailReport)}
              </div>
            </div>
          )}
        </Modal>
      )}

      {/* Modal détail annonce (photos Cloudinary, vues, favoris) */}
      {viewItem && <ItemDetailModal itemId={viewItem} onClose={() => setViewItem(null)} />}

      {/* Confirmation d'action de modération */}
      {moderateAction?.action && moderateLabels[moderateAction.action] && (
        <ConfirmDialog
          title={moderateLabels[moderateAction.action].title}
          message={
            <div>
              <p style={{ marginTop: 0 }}>{moderateLabels[moderateAction.action].message}</p>
              {(moderateAction.action === 'warn_user' || moderateAction.action === 'ban_user') && (
                <textarea
                  className="textarea"
                  placeholder={
                    moderateAction.action === 'ban_user'
                      ? "Motif du bannissement (envoyé à l'utilisateur, optionnel)"
                      : "Message d'avertissement (optionnel)"
                  }
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                />
              )}
            </div>
          }
          confirmLabel={moderateLabels[moderateAction.action].confirm}
          danger={moderateLabels[moderateAction.action].danger}
          loading={busy}
          onConfirm={handleModerate}
          onCancel={closeModerate}
        />
      )}
    </div>
  );
}




