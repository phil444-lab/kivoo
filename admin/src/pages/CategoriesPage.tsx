import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { adminApi } from '../api/client';
import type { AdminCategory } from '../api/types';
import { Badge, LoadingState, EmptyState, Modal, ConfirmDialog, Select } from '../components/ui';
import { useToast } from '../context/ToastContext';
import { IconPlus, IconEdit, IconTrash } from '../components/icons';

export default function CategoriesPage() {
  const { showToast } = useToast();
  const [categories, setCategories] = useState<AdminCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [newParent, setNewParent] = useState('');
  const [newSub, setNewSub] = useState('');
  const [newSubParentId, setNewSubParentId] = useState('');
  const [edit, setEdit] = useState<{ category: AdminCategory; name: string } | null>(null);
  const [del, setDel] = useState<AdminCategory | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setCategories(await adminApi<AdminCategory[]>('/categories'));
    } catch {
      setCategories([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const totalCount = (c: AdminCategory): number =>
    (c._count?.items ?? 0) +
    (c.subcategories?.reduce((acc, s) => acc + (s._count?.items ?? 0), 0) ?? 0);

  const createParent = async (e: FormEvent) => {
    e.preventDefault();
    if (!newParent.trim()) return;
    setBusy(true);
    try {
      await adminApi('/categories', { method: 'POST', body: { name: newParent.trim() } });
      showToast('success', 'Catégorie créée', newParent.trim());
      setNewParent('');
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Création impossible');
    } finally {
      setBusy(false);
    }
  };

  const createSub = async (e: FormEvent) => {
    e.preventDefault();
    if (!newSub.trim() || !newSubParentId) return;
    setBusy(true);
    try {
      await adminApi('/categories', {
        method: 'POST',
        body: { name: newSub.trim(), parentCategoryId: newSubParentId },
      });
      showToast('success', 'Sous-catégorie créée', newSub.trim());
      setNewSub('');
      setNewSubParentId('');
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Création impossible');
    } finally {
      setBusy(false);
    }
  };

  const saveEdit = async () => {
    if (!edit || !edit.name.trim()) return;
    setBusy(true);
    try {
      await adminApi(`/categories/${edit.category.id}`, {
        method: 'PATCH',
        body: { name: edit.name.trim() },
      });
      showToast('success', 'Catégorie renommée', edit.name.trim());
      setEdit(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Renommage impossible');
    } finally {
      setBusy(false);
    }
  };

  const toggleActive = async (category: AdminCategory) => {
    try {
      await adminApi(`/categories/${category.id}`, {
        method: 'PATCH',
        body: { isActive: !category.isActive },
      });
      showToast('success', 'Statut mis à jour', category.name);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  const handleDelete = async () => {
    if (!del) return;
    setBusy(true);
    try {
      await adminApi(`/categories/${del.id}`, { method: 'DELETE' });
      showToast('success', 'Catégorie supprimée', del.name);
      setDel(null);
      void load();
    } catch (err) {
      showToast('error', 'Suppression impossible', err instanceof Error ? err.message : undefined);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <div className="card">
        <div className="card-body">
          <div className="ref-toolbar">
            <div>
              <h3 className="card-title">Arbre des catégories</h3>
              <p className="card-subtitle">
                Catégories racines et sous-catégories (2 niveaux max, comme dans l'app)
              </p>
            </div>
          </div>

          <form className="inline-form" onSubmit={createParent}>
            <input
              className="input"
              placeholder="Nouvelle catégorie racine (ex : Véhicules)"
              value={newParent}
              onChange={(e) => setNewParent(e.target.value)}
            />
            <button className="btn btn-primary" type="submit" disabled={busy || !newParent.trim()}>
              <IconPlus /> Ajouter
            </button>
          </form>

          <form className="inline-form" onSubmit={createSub}>
            <Select
              value={newSubParentId}
              onChange={(v) => setNewSubParentId(v)}
              options={[
                { value: '', label: 'Catégorie parente...' },
                ...categories.map((c) => ({ value: c.id, label: c.name })),
              ]}
              style={{ width: 'auto', minWidth: 200 }}
            />
            <input
              className="input"
              placeholder="Nouvelle sous-catégorie"
              value={newSub}
              onChange={(e) => setNewSub(e.target.value)}
              disabled={!newSubParentId}
            />
            <button
              className="btn btn-outline"
              type="submit"
              disabled={busy || !newSub.trim() || !newSubParentId}
            >
              <IconPlus /> Ajouter
            </button>
          </form>

          {loading ? (
            <LoadingState />
          ) : categories.length === 0 ? (
            <EmptyState title="Aucune catégorie" text="Créez votre première catégorie" />
          ) : (
            <div>
              {categories.map((parent) => (
                <div key={parent.id} style={{ marginBottom: 18 }}>
                  <div className="tree-row parent">
                    <span className="tree-name">
                      {parent.name}
                      <span className="tree-count">{totalCount(parent)} annonces</span>
                    </span>
                    {!parent.isActive && <Badge color="neutral">Inactive</Badge>}
                    <div className="tree-actions">
                      <button
                        className="btn btn-sm btn-ghost"
                        onClick={() => toggleActive(parent)}
                        title={parent.isActive ? 'Désactiver' : 'Activer'}
                      >
                        {parent.isActive ? 'Désactiver' : 'Activer'}
                      </button>
                      <button
                        className="btn btn-sm btn-outline"
                        onClick={() => setEdit({ category: parent, name: parent.name })}
                      >
                        <IconEdit />
                      </button>
                      <button className="btn btn-sm btn-danger" onClick={() => setDel(parent)}>
                        <IconTrash />
                      </button>
                    </div>
                  </div>
                  {parent.subcategories && parent.subcategories.length > 0 && (
                    <div className="tree-children">
                      {parent.subcategories.map((sub) => (
                        <div key={sub.id} className="tree-row">
                          <span className="tree-name">
                            {sub.name}
                            <span className="tree-count">{sub._count?.items ?? 0} annonces</span>
                          </span>
                          {!sub.isActive && <Badge color="neutral">Inactive</Badge>}
                          <div className="tree-actions">
                            <button className="btn btn-sm btn-ghost" onClick={() => toggleActive(sub)}>
                              {sub.isActive ? 'Désactiver' : 'Activer'}
                            </button>
                            <button
                              className="btn btn-sm btn-outline"
                              onClick={() => setEdit({ category: sub, name: sub.name })}
                            >
                              <IconEdit />
                            </button>
                            <button className="btn btn-sm btn-danger" onClick={() => setDel(sub)}>
                              <IconTrash />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {edit && (
        <Modal
          title={`Renommer « ${edit.category.name} »`}
          onClose={() => setEdit(null)}
          size="sm"
          footer={
            <>
              <button className="btn btn-outline" onClick={() => setEdit(null)}>
                Annuler
              </button>
              <button className="btn btn-primary" onClick={saveEdit} disabled={busy || !edit.name.trim()}>
                Enregistrer
              </button>
            </>
          }
        >
          <div className="form-field">
            <label className="form-label">Nouveau nom</label>
            <input
              className="input"
              value={edit.name}
              onChange={(e) => setEdit({ ...edit, name: e.target.value })}
              autoFocus
            />
          </div>
        </Modal>
      )}

      {del && (
        <ConfirmDialog
          title="Supprimer cette catégorie ?"
          message={
            del._count?.items
              ? `« ${del.name} » est utilisée par ${del._count.items} annonce(s). La suppression sera refusée par l'API — désactivez-la plutôt.`
              : `« ${del.name} » et ses sous-catégories vides seront supprimées définitivement.`
          }
          confirmLabel="Supprimer"
          danger
          loading={busy}
          onConfirm={handleDelete}
          onCancel={() => setDel(null)}
        />
      )}
    </div>
  );
}


