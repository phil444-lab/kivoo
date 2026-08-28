import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../api/client';
import type { AdminCountry } from '../api/types';
import { Badge, LoadingState, EmptyState, ConfirmDialog } from '../components/ui';
import { useToast } from '../context/ToastContext';
import { IconPlus, IconEdit, IconTrash, IconX } from '../components/icons';

type ZoneLevel = 'department' | 'city' | 'district';

const LEVEL_LABELS: Record<ZoneLevel, { singular: string; plural: string }> = {
  department: { singular: 'département', plural: 'Départements' },
  city: { singular: 'ville', plural: 'Villes' },
  district: { singular: 'quartier', plural: 'Quartiers' },
};

export default function LocationsPage() {
  const { showToast } = useToast();
  const [tree, setTree] = useState<AdminCountry[]>([]);
  const [loading, setLoading] = useState(true);
  const [openDept, setOpenDept] = useState<string | null>(null);
  const [openCity, setOpenCity] = useState<string | null>(null);
  const [newNames, setNewNames] = useState<Record<ZoneLevel, string>>({
    department: '',
    city: '',
    district: '',
  });
  const [edit, setEdit] = useState<{ level: ZoneLevel; id: string; name: string } | null>(null);
  const [del, setDel] = useState<{ level: ZoneLevel; id: string; name: string } | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setTree(await adminApi<AdminCountry[]>('/locations/tree'));
    } catch {
      setTree([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const country = tree[0];

  const create = async (level: ZoneLevel, parentId?: string) => {
    const name = newNames[level].trim();
    if (!name) return;
    setBusy(true);
    try {
      const body: Record<string, string> = { name };
      if (level === 'department') body.countryId = country?.id || '';
      if (level === 'city') body.departmentId = parentId || '';
      if (level === 'district') body.cityId = parentId || '';
      await adminApi(`/${level === 'department' ? 'departments' : level === 'city' ? 'cities' : 'districts'}`, {
        method: 'POST',
        body,
      });
      showToast('success', `${LEVEL_LABELS[level].singular} créé`, name);
      setNewNames((p) => ({ ...p, [level]: '' }));
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
      const path =
        edit.level === 'department' ? 'departments' : edit.level === 'city' ? 'cities' : 'districts';
      await adminApi(`/${path}/${edit.id}`, {
        method: 'PATCH',
        body: { name: edit.name.trim() },
      });
      showToast('success', 'Renommé', edit.name.trim());
      setEdit(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Renommage impossible');
    } finally {
      setBusy(false);
    }
  };

  const toggleActive = async (level: ZoneLevel, id: string, isActive: boolean) => {
    try {
      const path = level === 'department' ? 'departments' : level === 'city' ? 'cities' : 'districts';
      await adminApi(`/${path}/${id}`, { method: 'PATCH', body: { isActive: !isActive } });
      showToast('success', 'Statut mis à jour');
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  const handleDelete = async () => {
    if (!del) return;
    setBusy(true);
    try {
      const path = del.level === 'department' ? 'departments' : del.level === 'city' ? 'cities' : 'districts';
      await adminApi(`/${path}/${del.id}`, { method: 'DELETE' });
      showToast('success', `${LEVEL_LABELS[del.level].singular} supprimé`, del.name);
      setDel(null);
      void load();
    } catch (err) {
      showToast('error', 'Suppression impossible', err instanceof Error ? err.message : undefined);
    } finally {
      setBusy(false);
    }
  };

  const rowActions = (level: ZoneLevel, id: string, name: string, isActive: boolean) => (
    <div className="tree-actions">
      {!isActive && <Badge color="neutral">Inactive</Badge>}
      <button
        className="btn btn-sm btn-ghost"
        onClick={() => toggleActive(level, id, isActive)}
        title={isActive ? 'Désactiver' : 'Activer'}
      >
        {isActive ? <IconX width={13} height={13} /> : '+'}
      </button>
      <button
        className="btn btn-sm btn-outline"
        onClick={() => setEdit({ level, id, name })}
      >
        <IconEdit />
      </button>
      <button
        className="btn btn-sm btn-danger"
        onClick={() => setDel({ level, id, name })}
      >
        <IconTrash />
      </button>
    </div>
  );

  return (
    <div>
      <div className="card">
        <div className="card-body">
          <div className="ref-toolbar">
            <div>
              <h3 className="card-title">{country ? country.name : 'Zones'}</h3>
              <p className="card-subtitle">
                Départements › Villes › Quartiers — cliquez sur un département pour gérer ses villes
              </p>
            </div>
          </div>

          {loading ? (
            <LoadingState />
          ) : !country ? (
            <EmptyState title="Aucun pays configuré" text="Lancez le seed backend pour initialiser le Bénin" />
          ) : (
            <div>
              <form
                className="inline-form"
                onSubmit={(e) => {
                  e.preventDefault();
                  void create('department', country.id);
                }}
              >
                <input
                  className="input"
                  placeholder={`Nouveau ${LEVEL_LABELS.department.singular}...`}
                  value={newNames.department}
                  onChange={(e) => setNewNames((p) => ({ ...p, department: e.target.value }))}
                />
                <button
                  className="btn btn-primary"
                  type="submit"
                  disabled={busy || !newNames.department.trim()}
                >
                  <IconPlus /> Ajouter
                </button>
              </form>

              {country.departments.map((dept) => (
                <div key={dept.id} style={{ marginBottom: 14 }}>
                  <div className="tree-row parent">
                    <span
                      className="tree-name"
                      style={{ cursor: 'pointer' }}
                      onClick={() => setOpenDept(openDept === dept.id ? null : dept.id)}
                    >
                      {openDept === dept.id ? '▾' : '▸'} {dept.name}
                      <span className="tree-count">
                        {dept._count.cities} villes · {dept._count.items} annonces
                      </span>
                    </span>
                    {rowActions('department', dept.id, dept.name, dept.isActive)}
                  </div>

                  {openDept === dept.id && (
                    <div className="tree-children">
                      <form
                        className="inline-form"
                        onSubmit={(e) => {
                          e.preventDefault();
                          void create('city', dept.id);
                        }}
                      >
                        <input
                          className="input"
                          placeholder={`Nouvelle ${LEVEL_LABELS.city.singular} dans ${dept.name}...`}
                          value={newNames.city}
                          onChange={(e) => setNewNames((p) => ({ ...p, city: e.target.value }))}
                        />
                        <button
                          className="btn btn-sm btn-primary"
                          type="submit"
                          disabled={busy || !newNames.city.trim()}
                        >
                          <IconPlus /> Ajouter
                        </button>
                      </form>

                      {dept.cities.map((city) => (
                        <div key={city.id} style={{ marginBottom: 10 }}>
                          <div className="tree-row">
                            <span
                              className="tree-name"
                              style={{ cursor: 'pointer' }}
                              onClick={() => setOpenCity(openCity === city.id ? null : city.id)}
                            >
                              {openCity === city.id ? '▾' : '▸'} {city.name}
                              <span className="tree-count">
                                {city._count.districts} quartiers · {city._count.items} annonces
                              </span>
                            </span>
                            {rowActions('city', city.id, city.name, city.isActive)}
                          </div>

                          {openCity === city.id && (
                            <div className="tree-children">
                              <form
                                className="inline-form"
                                onSubmit={(e) => {
                                  e.preventDefault();
                                  void create('district', city.id);
                                }}
                              >
                                <input
                                  className="input"
                                  placeholder={`Nouveau ${LEVEL_LABELS.district.singular} dans ${city.name}...`}
                                  value={newNames.district}
                                  onChange={(e) => setNewNames((p) => ({ ...p, district: e.target.value }))}
                                />
                                <button
                                  className="btn btn-sm btn-primary"
                                  type="submit"
                                  disabled={busy || !newNames.district.trim()}
                                >
                                  <IconPlus /> Ajouter
                                </button>
                              </form>

                              {city.districts.map((district) => (
                                <div key={district.id} className="tree-row">
                                  <span className="tree-name">
                                    {district.name}
                                    <span className="tree-count">{district._count.items} annonces</span>
                                  </span>
                                  {rowActions('district', district.id, district.name, district.isActive)}
                                </div>
                              ))}
                              {city.districts.length === 0 && (
                                <div className="detail-value small">Aucun quartier</div>
                              )}
                            </div>
                          )}
                        </div>
                      ))}
                      {dept.cities.length === 0 && <div className="detail-value small">Aucune ville</div>}
                    </div>
                  )}
                </div>
              ))}

            </div>
          )}
        </div>
      </div>

      {edit && (
        <div
          className="modal-overlay"
          onClick={(e) => {
            if (e.target === e.currentTarget) setEdit(null);
          }}
        >
          <div className="modal modal-sm">
            <div className="modal-header">
              <h3 className="modal-title">Renommer « {edit.name} »</h3>
            </div>
            <div className="modal-body">
              <div className="form-field">
                <label className="form-label">Nouveau nom</label>
                <input
                  className="input"
                  value={edit.name}
                  onChange={(e) => setEdit({ ...edit, name: e.target.value })}
                  autoFocus
                />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-outline" onClick={() => setEdit(null)}>
                Annuler
              </button>
              <button className="btn btn-primary" onClick={saveEdit} disabled={busy || !edit.name.trim()}>
                Enregistrer
              </button>
            </div>
          </div>
        </div>
      )}

      {del && (
        <ConfirmDialog
          title={`Supprimer ce ${LEVEL_LABELS[del.level].singular} ?`}
          message={`« ${del.name} » sera supprimé définitivement. L'API refusera la suppression si des enfants ou des annonces y sont rattachés — désactivez-le plutôt dans ce cas.`}
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


