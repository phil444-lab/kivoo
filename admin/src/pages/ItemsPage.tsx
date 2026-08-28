import { useCallback, useEffect, useState } from 'react';
import { adminApi, apiList } from '../api/client';
import type { AdminItem, AdminCategory, AdminCountry, Pagination } from '../api/types';
import {
  Badge,
  SearchInput,
  Select,
  LoadingState,
  EmptyState,
  PaginationBar,
  ConfirmDialog,
} from '../components/ui';
import ItemDetailModal from '../components/ItemDetailModal';
import { formatDateTime, formatPrice } from '../utils/format';
import { useToast } from '../context/ToastContext';
import { IconEye, IconTrash, IconStar } from '../components/icons';

const STATUS_OPTIONS = [
  { value: 'all', label: 'Tous les statuts' },
  { value: 'active', label: 'Actives' },
  { value: 'pending', label: 'En attente' },
  { value: 'sold', label: 'Vendues' },
  { value: 'expired', label: 'Expirées / masquées' },
];

const STATUS_BADGES: Record<string, 'success' | 'warning' | 'primary' | 'neutral'> = {
  active: 'success',
  pending: 'warning',
  sold: 'primary',
  expired: 'neutral',
};

export default function ItemsPage() {
  const { showToast } = useToast();
  const [items, setItems] = useState<AdminItem[]>([]);
  const [pagination, setPagination] = useState<Pagination | undefined>();
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('all');
  const [categoryId, setCategoryId] = useState('');
  const [cityId, setCityId] = useState('');
  const [featured, setFeatured] = useState('all');
  const [search, setSearch] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState<AdminCategory[]>([]);
  const [cities, setCities] = useState<{ id: string; name: string }[]>([]);
  const [viewItem, setViewItem] = useState<string | null>(null);
  const [actionItem, setActionItem] = useState<AdminItem | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    void adminApi<AdminCategory[]>('/categories')
      .then(setCategories)
      .catch(() => {});
    void adminApi<AdminCountry[]>('/locations/tree')
      .then((countries) => {
        const list: { id: string; name: string }[] = [];
        countries.forEach((c) =>
          c.departments.forEach((d) => d.cities.forEach((v) => list.push({ id: v.id, name: v.name })))
        );
        setCities(list.sort((a, b) => a.name.localeCompare(b.name, 'fr')));
      })
      .catch(() => {});
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiList<AdminItem>('/items', {
        page,
        limit: 20,
        status,
        categoryId,
        cityId,
        featured: featured === 'all' ? '' : featured,
        search: searchQuery,
      });
      setItems((data.items as AdminItem[]) || []);
      setPagination(data.pagination as Pagination);
    } catch {
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [page, status, categoryId, cityId, featured, searchQuery]);

  useEffect(() => {
    void load();
  }, [load]);

  const handleDelete = async () => {
    if (!actionItem) return;
    setBusy(true);
    try {
      await adminApi(`/items/${actionItem.id}`, { method: 'DELETE' });
      showToast('success', 'Annonce supprimée', `"${actionItem.title}" a été supprimée définitivement`);
      setActionItem(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Suppression impossible');
    } finally {
      setBusy(false);
    }
  };

  const toggleFeatured = async (item: AdminItem) => {
    try {
      await adminApi(`/items/${item.id}`, {
        method: 'PATCH',
        body: { featured: !item.featured },
      });
      showToast(
        'success',
        'Mise en avant',
        !item.featured
          ? `"${item.title}" est maintenant mise en avant`
          : `"${item.title}" n'est plus mise en avant`
      );
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  const changeStatus = async (item: AdminItem, newStatus: string) => {
    try {
      await adminApi(`/items/${item.id}`, { method: 'PATCH', body: { status: newStatus } });
      showToast('success', 'Statut mis à jour', `"${item.title}" → ${newStatus}`);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  return (
    <div>
      <div className="card">
        <div className="card-header" style={{ flexWrap: 'wrap' }}>
          <SearchInput
            value={search}
            onChange={setSearch}
            onEnter={() => {
              setSearchQuery(search);
              setPage(1);
            }}
            placeholder="Titre, description ou vendeur..."
          />
          <Select value={status} onChange={(v) => { setStatus(v); setPage(1); }} options={STATUS_OPTIONS} />
          <Select
            value={categoryId}
            onChange={(v) => { setCategoryId(v); setPage(1); }}
            options={[{ value: '', label: 'Toutes catégories' }, ...categories.map((c) => ({ value: c.id, label: c.name }))]}
          />
          <Select
            value={cityId}
            onChange={(v) => { setCityId(v); setPage(1); }}
            options={[{ value: '', label: 'Toutes les villes' }, ...cities.map((c) => ({ value: c.id, label: c.name }))]}
          />
          <Select
            value={featured}
            onChange={(v) => { setFeatured(v); setPage(1); }}
            options={[
              { value: 'all', label: 'Toutes' },
              { value: 'true', label: 'En avant' },
              { value: 'false', label: 'Standard' },
            ]}
          />
        </div>

        {loading ? (
          <LoadingState />
        ) : items.length === 0 ? (
          <EmptyState title="Aucune annonce" text="Aucun résultat pour ces filtres" />
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
                    <th>Vues</th>
                    <th>Statut</th>
                    <th>Créée le</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <tr key={item.id}>
                      <td>
                        <div
                          className="cell-main"
                          style={{ cursor: 'pointer' }}
                          onClick={() => setViewItem(item.id)}
                        >
                          {item.title}
                          {item.featured && (
                            <Badge color="primary" dot>
                              En avant
                            </Badge>
                          )}
                        </div>
                        <div className="cell-sub">
                          {item.category?.name}
                          {item.subcategory ? ` › ${item.subcategory.name}` : ''}
                        </div>
                      </td>
                      <td className="cell-sub">{item.seller?.name || '—'}</td>
                      <td className="cell-sub">{item.city?.name || '—'}</td>
                      <td className="cell-main">{formatPrice(item.price)}</td>
                      <td className="cell-sub">{item.views}</td>
                      <td>
                        <Badge color={STATUS_BADGES[item.status] || 'neutral'} dot>
                          {item.status}
                        </Badge>
                      </td>
                      <td className="cell-sub">{formatDateTime(item.createdAt)}</td>
                      <td>
                        <div className="cell-actions">
                          <button className="btn btn-sm btn-ghost" onClick={() => setViewItem(item.id)}>
                            <IconEye />
                          </button>
                          <button
                            className={`btn btn-sm ${item.featured ? 'btn-warning' : 'btn-outline'}`}
                            title={item.featured ? 'Retirer la mise en avant' : 'Mettre en avant'}
                            onClick={() => toggleFeatured(item)}
                          >
                            <IconStar />
                          </button>
                          <button
                            className="btn btn-sm btn-danger"
                            title="Supprimer l'annonce"
                            onClick={() => setActionItem(item)}
                          >
                            <IconTrash />
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
          actions={(item) => (
            <>
              <Select
                value={item.status}
                onChange={(v) => changeStatus(item, v)}
                options={STATUS_OPTIONS.filter((o) => o.value !== 'all')}
              />
              <button
                className={`btn ${item.featured ? 'btn-warning' : 'btn-primary'}`}
                onClick={() => toggleFeatured(item)}
              >
                <IconStar /> {item.featured ? 'Retirer la mise en avant' : 'Mettre en avant'}
              </button>
              <button className="btn btn-danger" onClick={() => setActionItem(item)}>
                <IconTrash /> Supprimer
              </button>
            </>
          )}
        />
      )}

      {actionItem && (
        <ConfirmDialog
          title="Supprimer cette annonce ?"
          message={
            <>
              <p style={{ marginTop: 0 }}>
                « {actionItem.title} » et toutes ses données associées (favoris, conversations,
                signalements) seront supprimées définitivement. Les photos Cloudinary seront également
                effacées.
              </p>
              <p>Pour masquer temporairement une annonce, changez plutôt son statut en « expirée ».</p>
            </>
          }
          confirmLabel="Supprimer définitivement"
          danger
          loading={busy}
          onConfirm={handleDelete}
          onCancel={() => setActionItem(null)}
        />
      )}
    </div>
  );
}



