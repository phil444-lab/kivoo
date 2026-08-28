import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../api/client';
import type { AdminFeaturedOption } from '../api/types';
import { Badge, LoadingState, EmptyState, Modal, ConfirmDialog } from '../components/ui';
import { useToast } from '../context/ToastContext';
import { IconPlus, IconEdit, IconTrash } from '../components/icons';

interface OptionForm {
  title: string;
  subtitle: string;
  icon: string;
  borderColor: string;
  darkBg: string;
  lightBg: string;
  order: number;
  isActive: boolean;
}

const EMPTY_FORM: OptionForm = {
  title: '',
  subtitle: '',
  icon: 'star',
  borderColor: '#2563eb',
  darkBg: '#142035',
  lightBg: '#deeaff',
  order: 0,
  isActive: true,
};

export default function FeaturedOptionsPage() {
  const { showToast } = useToast();
  const [options, setOptions] = useState<AdminFeaturedOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [editor, setEditor] = useState<{ id: string | null; form: OptionForm } | null>(null);
  const [del, setDel] = useState<AdminFeaturedOption | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setOptions(await adminApi<AdminFeaturedOption[]>('/featured-options'));
    } catch {
      setOptions([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const openCreate = () => setEditor({ id: null, form: { ...EMPTY_FORM } });

  const openEdit = (opt: AdminFeaturedOption) =>
    setEditor({
      id: opt.id,
      form: {
        title: opt.title,
        subtitle: opt.subtitle,
        icon: opt.icon,
        borderColor: opt.borderColor,
        darkBg: opt.darkBg,
        lightBg: opt.lightBg,
        order: opt.order,
        isActive: opt.isActive,
      },
    });

  const save = async () => {
    if (!editor) return;
    setBusy(true);
    try {
      const body = { ...editor.form, order: Number(editor.form.order) || 0 };
      if (editor.id) {
        await adminApi(`/featured-options/${editor.id}`, { method: 'PATCH', body });
        showToast('success', 'Offre mise à jour', editor.form.title);
      } else {
        await adminApi('/featured-options', { method: 'POST', body });
        showToast('success', 'Offre créée', editor.form.title);
      }
      setEditor(null);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Enregistrement impossible');
    } finally {
      setBusy(false);
    }
  };

  const toggleActive = async (opt: AdminFeaturedOption) => {
    try {
      await adminApi(`/featured-options/${opt.id}`, {
        method: 'PATCH',
        body: { isActive: !opt.isActive },
      });
      showToast('success', 'Statut mis à jour', opt.title);
      void load();
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  const handleDelete = async () => {
    if (!del) return;
    setBusy(true);
    try {
      await adminApi(`/featured-options/${del.id}`, { method: 'DELETE' });
      showToast('success', 'Offre supprimée', del.title);
      setDel(null);
      void load();
    } catch (err) {
      showToast('error', 'Suppression impossible', err instanceof Error ? err.message : undefined);
    } finally {
      setBusy(false);
    }
  };

  const setField = <K extends keyof OptionForm>(key: K, value: OptionForm[K]) => {
    if (!editor) return;
    setEditor({ ...editor, form: { ...editor.form, [key]: value } });
  };

  return (
    <div>
      <div className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">Offres sponsorisées (FeaturedOption)</h3>
            <p className="card-subtitle">
              Les cartes « featured » affichées sur l'accueil de l'app — couleurs en accord avec le thème
            </p>
          </div>
          <button className="btn btn-primary" onClick={openCreate}>
            <IconPlus /> Nouvelle offre
          </button>
        </div>

        {loading ? (
          <LoadingState />
        ) : options.length === 0 ? (
          <EmptyState title="Aucune offre sponsorisée" text="Créez votre première offre" />
        ) : (
          <div className="card-body">
            {options.map((opt) => (
              <div
                key={opt.id}
                className="tree-row"
                style={{
                  borderLeft: `4px solid ${opt.borderColor || 'var(--primary)'}`,
                  marginBottom: 10,
                }}
              >
                <div
                  style={{
                    width: 38,
                    height: 38,
                    background: opt.darkBg,
                    borderRadius: 'var(--radius-md)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <span
                    style={{
                      fontSize: 18,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    {opt.icon === 'star' ? '★' : opt.icon === 'gift' ? '🎁' : opt.icon === 'bolt' ? '⚡' : '✔'}
                  </span>
                </div>
                <div className="tree-name" style={{ minWidth: 140 }}>
                  {opt.title}
                  <span className="tree-count">{opt.subtitle}</span>
                  {opt._count && opt._count.items > 0 && (
                    <span className="tree-count"> · {opt._count.items} annonce(s)</span>
                  )}
                </div>
                {opt.isActive ? (
                  <Badge color="success" dot>Active</Badge>
                ) : (
                  <Badge color="neutral">Inactive</Badge>
                )}
                <span className="detail-value small">Ordre : {opt.order}</span>
                <div className="tree-actions">
                  <button className="btn btn-sm btn-ghost" onClick={() => toggleActive(opt)}>
                    {opt.isActive ? 'Désactiver' : 'Activer'}
                  </button>
                  <button className="btn btn-sm btn-outline" onClick={() => openEdit(opt)}>
                    <IconEdit />
                  </button>
                  <button className="btn btn-sm btn-danger" onClick={() => setDel(opt)}>
                    <IconTrash />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {editor && (
        <Modal
          title={editor.id ? `Modifier « ${editor.form.title} »` : 'Nouvelle offre sponsorisée'}
          onClose={() => setEditor(null)}
          size="md"
          footer={
            <>
              <button className="btn btn-outline" onClick={() => setEditor(null)}>
                Annuler
              </button>
              <button
                className="btn btn-primary"
                onClick={save}
                disabled={busy || !editor.form.title.trim() || !editor.form.subtitle.trim()}
              >
                {busy ? '...' : 'Enregistrer'}
              </button>
            </>
          }
        >
          <div className="form-grid" style={{ marginBottom: 14 }}>
            <div className="form-field">
              <label className="form-label">Titre *</label>
              <input
                className="input"
                value={editor.form.title}
                onChange={(e) => setField('title', e.target.value)}
                placeholder="Offres Premium"
              />
            </div>
            <div className="form-field">
              <label className="form-label">Sous-titre *</label>
              <input
                className="input"
                value={editor.form.subtitle}
                onChange={(e) => setField('subtitle', e.target.value)}
                placeholder="Jusqu'à -60%"
              />
            </div>
          </div>

          <div className="form-grid" style={{ marginBottom: 14 }}>
            <div className="form-field">
              <label className="form-label">Icône</label>
              <select
                className="select"
                value={editor.form.icon}
                onChange={(e) => setField('icon', e.target.value)}
              >
                <option value="star">★ Étoile</option>
                <option value="gift">🎁 Cadeau</option>
                <option value="circle-check">✔ Vérifié</option>
                <option value="bolt">⚡ Éclair</option>
              </select>
            </div>
            <div className="form-field">
              <label className="form-label">Ordre d'affichage</label>
              <input
                className="input"
                type="number"
                value={editor.form.order}
                onChange={(e) => setField('order', Number(e.target.value))}
              />
            </div>
            <div className="form-field">
              <label className="form-label">Couleur de bordure</label>
              <input
                className="input"
                type="color"
                value={/^#[0-9a-fA-F]{6}$/.test(editor.form.borderColor) ? editor.form.borderColor : '#2563eb'}
                onChange={(e) => setField('borderColor', e.target.value)}
              />
            </div>
          </div>

          <div className="form-grid" style={{ marginBottom: 16 }}>
            <div className="form-field">
              <label className="form-label">Fond (thème clair)</label>
              <input
                className="input"
                type="color"
                value={/^#[0-9a-fA-F]{6}$/.test(editor.form.lightBg) ? editor.form.lightBg : '#deeaff'}
                onChange={(e) => setField('lightBg', e.target.value)}
              />
            </div>
            <div className="form-field">
              <label className="form-label">Fond (thème sombre)</label>
              <input
                className="input"
                type="color"
                value={/^#[0-9a-fA-F]{6}$/.test(editor.form.darkBg) ? editor.form.darkBg : '#142035'}
                onChange={(e) => setField('darkBg', e.target.value)}
              />
            </div>
          </div>

          <div className="form-field">
            <label className="form-label">Statut</label>
            <button
              className="btn"
              style={{ width: 'fit-content' }}
              onClick={() => setField('isActive', !editor.form.isActive)}
            >
              {editor.form.isActive ? 'Active' : 'Inactive'}
            </button>
          </div>
        </Modal>
      )}

      {del && (
        <ConfirmDialog
          title="Supprimer cette offre ?"
          message={
            del._count?.items
              ? `« ${del.title} » est utilisée par ${del._count.items} annonce(s). La suppression sera refusée par l'API — désactivez-la plutôt.`
              : `« ${del.title} » sera supprimée définitivement.`
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