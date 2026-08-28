import { useCallback, useEffect, useState } from 'react';
import { adminApi, apiList } from '../api/client';
import type { AdminItem, Pagination } from '../api/types';
import {
  Badge,
  LoadingState,
  EmptyState,
  PaginationBar,
  Avatar,
  ConfirmDialog,
} from '../components/ui';
import ItemDetailModal from '../components/ItemDetailModal';
import { formatDateTime, formatPrice } from '../utils/format';
import { useToast } from '../context/ToastContext';
import { IconEye, IconCheckCircle, IconX } from '../components/icons';

export default function ValidationPage() {
  const { showToast } = useToast();
  const [items, setItems] = useState<AdminItem[]>([]);
  const [pagination, setPagination] = useState<Pagination | undefined>();
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [viewItem, setViewItem] = useState<string | null>(null);
  const [review, setReview] = useState<{ item: AdminItem; approve: boolean } | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiList<AdminItem>('/moderation/items/pending', { page, limit: 20 });
      setItems((data.items as AdminItem[]) || []);
      setPagination(data.pagination as Pagination);
    } catch {
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    void load();
  }, [load]);

  const handleReview = async () => {
    if (!review) return;
    setBusy(true);
    try {
      await adminApi(`/moderation/items/${review.item.id}/review`, {
        method: 'PATCH',
        body: { approve: review.approve },
      });
      showToast(
        'success',
        review.approve ? 'Annonce approuvée' : 'Annonce rejetée',
        review.approve
          ? `"${review.item.title}" est maintenant visible par tous`
          : `"${review.item.title}" a été masquée et le vendeur notifié`
      );
      setReview(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <div className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">File de validation</h3>
            <p className="card-subtitle">
              Annonces en attente de modération — approuvez ou rejetez
            </p>
          </div>
        </div>

        {loading ? (
          <LoadingState />
        ) : items.length === 0 ? (
          <EmptyState title="Aucune annonce en attente" text="Toutes les annonces ont été traitées 🎉" />
        ) : (
          <>
            <div className="table-wrapper">
              <table className="table">
                <thead>
                  <tr>
                    <th>Annonce</th>
                    <th>Vendeur</th>
                    <th>Ville</th>
                    <th>Prix</th>
                    <th>Soumise le</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <tr key={item.id}>
                      <td>
                        <div className="cell-main">{item.title}</div>
                        <div className="cell-sub">
                          {item.category?.name}
                          {item.subcategory ? ` › ${item.subcategory.name}` : ''}
                        </div>
                      </td>
                      <td>
                        <div className="person-row">
                          <Avatar name={item.seller?.name || '?'} photo={item.seller?.photo} />
                          <div>
                            <div className="cell-main" style={{ fontSize: 13 }}>{item.seller?.name}</div>
                            <div className="cell-sub">{item.seller?.phone}</div>
                          </div>
                        </div>
                      </td>
                      <td className="cell-sub">{item.city?.name || '—'}</td>
                      <td className="cell-main">{formatPrice(item.price)}</td>
                      <td className="cell-sub">{formatDateTime(item.createdAt)}</td>
                      <td>
                        <div className="cell-actions">
                          <button
                            className="btn btn-sm btn-outline"
                            onClick={() => setViewItem(item.id)}
                            title="Examiner le contenu"
                          >
                            <IconEye /> Examiner
                          </button>
                          <button
                            className="btn btn-sm btn-success"
                            onClick={() => setReview({ item, approve: true })}
                          >
                            <IconCheckCircle /> Approuver
                          </button>
                          <button
                            className="btn btn-sm btn-danger"
                            onClick={() => setReview({ item, approve: false })}
                          >
                            <IconX /> Rejeter
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

      {viewItem && (
        <ItemDetailModal
          itemId={viewItem}
          onClose={() => setViewItem(null)}
          actions={(item) =>
            item.status === 'pending' ? (
              <>
                <button className="btn btn-success" onClick={() => setReview({ item, approve: true })}>
                  <IconCheckCircle /> Approuver
                </button>
                <button className="btn btn-danger" onClick={() => setReview({ item, approve: false })}>
                  <IconX /> Rejeter
                </button>
              </>
            ) : (
              <Badge color="primary" dot>
                {item.status}
              </Badge>
            )
          }
        />
      )}

      {review && (
        <ConfirmDialog
          title={review.approve ? 'Approuver cette annonce ?' : 'Rejeter cette annonce ?'}
          message={
            review.approve
              ? `"${review.item.title}" sera publiée et visible par tous les utilisateurs. Le vendeur sera notifié.`
              : `"${review.item.title}" sera masquée (statut expirée) et le vendeur sera notifié du rejet.`
          }
          confirmLabel={review.approve ? 'Approuver' : 'Rejeter'}
          danger={!review.approve}
          loading={busy}
          onConfirm={handleReview}
          onCancel={() => setReview(null)}
        />
      )}
    </div>
  );
}

