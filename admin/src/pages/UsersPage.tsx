import { useCallback, useEffect, useState } from 'react';
import { adminApi, apiList } from '../api/client';
import type { AdminUser, AdminUserDetail, Pagination } from '../api/types';
import {
  Badge,
  SearchInput,
  Select,
  LoadingState,
  EmptyState,
  PaginationBar,
  Avatar,
  Modal,
  ConfirmDialog,
  DetailItem,
} from '../components/ui';
import { formatDate, formatDateTime, formatPrice } from '../utils/format';
import { useToast } from '../context/ToastContext';
import { IconEye, IconTrash, IconCheckCircle, IconBan, IconRefresh, IconWarn } from '../components/icons';

export default function UsersPage() {
  const { showToast } = useToast();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [pagination, setPagination] = useState<Pagination | undefined>();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [verified, setVerified] = useState('all');
  const [isActive, setIsActive] = useState('all');
  const [loading, setLoading] = useState(true);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [detail, setDetail] = useState<AdminUserDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [confirm, setConfirm] = useState<
    { user: AdminUser; type: 'ban' | 'unban' | 'verify' | 'unverify' } | null
  >(null);
  const [warnTarget, setWarnTarget] = useState<AdminUser | null>(null);
  const [warnMessage, setWarnMessage] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await apiList<AdminUser>('/users', {
        page,
        limit: 20,
        search: searchQuery,
        verified: verified === 'all' ? '' : verified,
        isActive: isActive === 'all' ? '' : isActive,
      });
      setUsers((data.users as AdminUser[]) || []);
      setPagination(data.pagination as Pagination);
    } catch {
      setUsers([]);
    } finally {
      setLoading(false);
    }
  }, [page, searchQuery, verified, isActive]);

  useEffect(() => {
    void load();
  }, [load]);

  const loadDetail = useCallback(async (userId: string) => {
    setDetailLoading(true);
    setDetail(null);
    try {
      const data = await adminApi<AdminUserDetail>(`/users/${userId}`);
      setDetail(data);
    } catch {
      // ignore
    } finally {
      setDetailLoading(false);
    }
  }, []);

  useEffect(() => {
    if (detailId) void loadDetail(detailId);
  }, [detailId, loadDetail]);

  const applyConfirm = async () => {
    if (!confirm) return;
    setBusy(true);
    try {
      const body: Record<string, boolean> = {};
      if (confirm.type === 'ban') body.isActive = false;
      if (confirm.type === 'unban') body.isActive = true;
      if (confirm.type === 'verify') body.verified = true;
      if (confirm.type === 'unverify') body.verified = false;
      await adminApi(`/users/${confirm.user.id}`, { method: 'PATCH', body });
      showToast('success', 'Utilisateur mis à jour', confirm.user.name);
      setConfirm(null);
      void load();
      if (detailId === confirm.user.id) void loadDetail(confirm.user.id);
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    } finally {
      setBusy(false);
    }
  };

  const invalidateSessions = async (user: AdminUser) => {
    try {
      const result = await adminApi<{ invalidated: number }>(`/users/${user.id}/invalidate-sessions`, {
        method: 'POST',
      });
      showToast('success', 'Sessions invalidées', `${result.invalidated} session(s) fermée(s) pour ${user.name}`);
      if (detailId === user.id) void loadDetail(user.id);
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    }
  };

  const sendWarning = async () => {
    if (!warnTarget || !warnMessage.trim()) return;
    setBusy(true);
    try {
      await adminApi(`/users/${warnTarget.id}/warn`, {
        method: 'POST',
        body: { message: warnMessage.trim() },
      });
      showToast('success', 'Avertissement envoyé', warnTarget.name);
      setWarnTarget(null);
      setWarnMessage('');
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Action impossible');
    } finally {
      setBusy(false);
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
            placeholder="Nom, téléphone ou email..."
          />
          <Select
            value={verified}
            onChange={(v) => { setVerified(v); setPage(1); }}
            options={[
              { value: 'all', label: 'Tous les badges' },
              { value: 'true', label: 'Vérifiés' },
              { value: 'false', label: 'Non vérifiés' },
            ]}
          />
          <Select
            value={isActive}
            onChange={(v) => { setIsActive(v); setPage(1); }}
            options={[
              { value: 'all', label: 'Tous les comptes' },
              { value: 'true', label: 'Actifs' },
              { value: 'false', label: 'Bannis' },
            ]}
          />
        </div>

        {loading ? (
          <LoadingState />
        ) : users.length === 0 ? (
          <EmptyState title="Aucun utilisateur" text="Aucun résultat pour ces filtres" />
        ) : (
          <>
            <div className="table-wrapper">
              <table className="table">
                <thead>
                  <tr>
                    <th>Utilisateur</th>
                    <th>Téléphone</th>
                    <th>Annonces</th>
                    <th>Note</th>
                    <th>Vérifié</th>
                    <th>Statut</th>
                    <th>Inscription</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.id}>
                      <td>
                        <div className="person-row">
                          <Avatar name={user.name} photo={user.photo} />
                          <div>
                            <div className="cell-main">{user.name}</div>
                            <div className="cell-sub">{user.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="cell-sub">{user.phone}</td>
                      <td className="cell-sub">{user._count?.items ?? 0}</td>
                      <td className="cell-sub">
                        {user.rating.toFixed(1)} ({user.ratingCount})
                      </td>
                      <td>
                        {user.verified ? (
                          <Badge color="primary" dot>Vérifié</Badge>
                        ) : (
                          <Badge color="neutral">—</Badge>
                        )}
                      </td>
                      <td>
                        {user.isActive ? (
                          <Badge color="success" dot>Actif</Badge>
                        ) : (
                          <Badge color="danger" dot>Banni</Badge>
                        )}
                      </td>
                      <td className="cell-sub">{formatDate(user.joinedAt)}</td>
                      <td>
                        <div className="cell-actions">
                          <button
                            className="btn btn-sm btn-outline"
                            onClick={() => setDetailId(user.id)}
                            title="Profil détaillé"
                          >
                            <IconEye />
                          </button>
                          {user.verified ? (
                            <button
                              className="btn btn-sm btn-ghost"
                              onClick={() => setConfirm({ user, type: 'unverify' })}
                              title="Retirer le badge vérifié"
                            >
                              <IconCheckCircle />
                            </button>
                          ) : (
                            <button
                              className="btn btn-sm btn-primary"
                              onClick={() => setConfirm({ user, type: 'verify' })}
                              title="Attribuer le badge vérifié"
                            >
                              <IconCheckCircle />
                            </button>
                          )}
                          {user.isActive ? (
                            <button
                              className="btn btn-sm btn-danger"
                              onClick={() => setConfirm({ user, type: 'ban' })}
                              title="Bannir le compte"
                            >
                              <IconBan />
                            </button>
                          ) : (
                            <button
                              className="btn btn-sm btn-success"
                              onClick={() => setConfirm({ user, type: 'unban' })}
                              title="Réactiver le compte"
                            >
                              <IconCheckCircle />
                            </button>
                          )}
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

      {/* Modal profil utilisateur détaillé */}
      {detailId && (
        <Modal title={detail?.user.name || 'Profil utilisateur'} onClose={() => setDetailId(null)} size="lg">
          {detailLoading || !detail ? (
            <LoadingState />
          ) : (
            <div>
              <div className="person-row" style={{ marginBottom: 16 }}>
                <Avatar name={detail.user.name} photo={detail.user.photo} size="lg" />
                <div style={{ flex: 1 }}>
                  <div className="detail-value" style={{ fontSize: 16 }}>{detail.user.name}</div>
                  <div className="detail-value small">
                    {detail.user.email} · {detail.user.phone}
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 6, flexWrap: 'wrap' }}>
                    {detail.user.verified && <Badge color="primary" dot>Vérifié</Badge>}
                    {detail.user.isActive ? (
                      <Badge color="success" dot>Actif</Badge>
                    ) : (
                      <Badge color="danger" dot>Banni</Badge>
                    )}
                    <Badge color="info">Note {detail.user.rating.toFixed(1)} ({detail.user.ratingCount})</Badge>
                  </div>
                </div>
              </div>

              <div className="detail-grid">
                <DetailItem label="Annonces" value={detail.user._count?.items ?? 0} />
                <DetailItem label="Favoris" value={detail.user._count?.favorites ?? 0} />
                <DetailItem label="Sessions actives" value={detail.activeSessions.length} />
                <DetailItem label="Inscrit le" value={formatDate(detail.user.joinedAt)} small />
                <DetailItem label="Dernière connexion" value={formatDateTime(detail.user.lastLogin)} small />
                <DetailItem label="Signalements reçus" value={detail.user._count?.reportedIn ?? '—'} small />
              </div>

              <div className="section-title">Actions</div>
              <div className="cell-actions" style={{ justifyContent: 'flex-start' }}>
                {detail.user.isActive ? (
                  <button className="btn btn-danger" onClick={() => setConfirm({ user: detail.user, type: 'ban' })}>
                    <IconBan /> Bannir le compte
                  </button>
                ) : (
                  <button className="btn btn-success" onClick={() => setConfirm({ user: detail.user, type: 'unban' })}>
                    <IconCheckCircle /> Réactiver le compte
                  </button>
                )}
                {detail.user.verified ? (
                  <button className="btn btn-outline" onClick={() => setConfirm({ user: detail.user, type: 'unverify' })}>
                    <IconCheckCircle /> Retirer le badge vérifié
                  </button>
                ) : (
                  <button className="btn btn-primary" onClick={() => setConfirm({ user: detail.user, type: 'verify' })}>
                    <IconCheckCircle /> Attribuer le badge vérifié
                  </button>
                )}
                <button className="btn btn-warning" onClick={() => setWarnTarget(detail.user)}>
                  <IconWarn /> Avertir
                </button>
                <button className="btn btn-outline" onClick={() => invalidateSessions(detail.user)}>
                  <IconRefresh /> Invalider les sessions
                </button>
              </div>

              <div className="section-title">Historique des annonces (10 dernières)</div>
              {detail.items.length === 0 ? (
                <div className="detail-value small">Aucune annonce publiée</div>
              ) : (
                <div className="table-wrapper" style={{ border: '1px solid var(--outline)', borderRadius: 'var(--radius-md)' }}>
                  <table className="table">
                    <tbody>
                      {detail.items.map((item) => (
                        <tr key={item.id}>
                          <td>
                            <div className="cell-main" style={{ fontSize: 13 }}>{item.title}</div>
                            <div className="cell-sub">{item.category?.name} · {item.city?.name || '—'}</div>
                          </td>
                          <td className="cell-sub">{formatPrice(item.price)}</td>
                          <td>
                            <Badge
                              color={item.status === 'active' ? 'success' : item.status === 'pending' ? 'warning' : 'neutral'}
                              dot
                            >
                              {item.status}
                            </Badge>
                          </td>
                          <td className="cell-sub">{formatDate(item.createdAt)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              <div className="section-title">Avis reçus</div>
              {detail.reviewsReceived.length === 0 ? (
                <div className="detail-value small">Aucun avis reçu</div>
              ) : (
                <div className="table-wrapper" style={{ border: '1px solid var(--outline)', borderRadius: 'var(--radius-md)' }}>
                  <table className="table">
                    <tbody>
                      {detail.reviewsReceived.map((review) => (
                        <tr key={review.id}>
                          <td>
                            <div className="person-row">
                              <Avatar name={review.reviewer?.name || '?'} photo={review.reviewer?.photo} />
                              <div>
                                <div className="cell-main" style={{ fontSize: 13 }}>{review.reviewer?.name}</div>
                                <div className="cell-sub">{review.item?.title || 'Annonce supprimée'}</div>
                              </div>
                            </div>
                          </td>
                          <td className="cell-main">
                            {'★'.repeat(review.rating)}
                            {'☆'.repeat(5 - review.rating)}
                          </td>
                          <td className="cell-sub" style={{ maxWidth: 260 }}>{review.comment || '—'}</td>
                          <td className="cell-sub">{formatDate(review.createdAt)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              <div className="section-title">Sessions actives</div>
              {detail.activeSessions.length === 0 ? (
                <div className="detail-value small">Aucune session active</div>
              ) : (
                <div className="table-wrapper" style={{ border: '1px solid var(--outline)', borderRadius: 'var(--radius-md)' }}>
                  <table className="table">
                    <tbody>
                      {detail.activeSessions.map((session) => (
                        <tr key={session.id}>
                          <td>
                            <div className="cell-main" style={{ fontSize: 13 }}>
                              {session.deviceInfo || 'Appareil inconnu'}
                            </div>
                            <div className="cell-sub">IP {session.ipAddress || '—'}</div>
                          </td>
                          <td className="cell-sub">Créée {formatDateTime(session.createdAt)}</td>
                          <td className="cell-sub">Expire {formatDateTime(session.expiresAt)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </Modal>
      )}

      {confirm && (
        <ConfirmDialog
          title={
            confirm.type === 'ban'
              ? 'Bannir ce compte ?'
              : confirm.type === 'unban'
                ? 'Réactiver ce compte ?'
                : confirm.type === 'verify'
                  ? 'Attribuer le badge vérifié ?'
                  : 'Retirer le badge vérifié ?'
          }
          message={
            confirm.type === 'ban'
              ? `${confirm.user.name} ne pourra plus se connecter, ses sessions actives seront invalidées et il sera notifié. Réversible.`
              : confirm.type === 'unban'
                ? `${confirm.user.name} pourra de nouveau accéder à son compte et sera notifié.`
                : confirm.type === 'verify'
                  ? `Le badge « vérifié » sera affiché sur le profil de ${confirm.user.name}.`
                  : `Le badge « vérifié » sera retiré du profil de ${confirm.user.name}.`
          }
          confirmLabel={
            confirm.type === 'ban'
              ? 'Bannir'
              : confirm.type === 'unban'
                ? 'Réactiver'
                : confirm.type === 'verify'
                  ? 'Attribuer'
                  : 'Retirer'
          }
          danger={confirm.type === 'ban'}
          loading={busy}
          onConfirm={applyConfirm}
          onCancel={() => setConfirm(null)}
        />
      )}

      {warnTarget && (
        <Modal
          title={`Avertir ${warnTarget.name}`}
          onClose={() => { setWarnTarget(null); setWarnMessage(''); }}
          size="sm"
          footer={
            <>
              <button className="btn btn-outline" onClick={() => { setWarnTarget(null); setWarnMessage(''); }}>
                Annuler
              </button>
              <button className="btn btn-primary" onClick={sendWarning} disabled={busy || !warnMessage.trim()}>
                Envoyer
              </button>
            </>
          }
        >
          <div className="form-field">
            <label className="form-label">Message d'avertissement</label>
            <textarea
              className="textarea"
              placeholder="Votre annonce ne respecte pas les règles de la communauté..."
              value={warnMessage}
              onChange={(e) => setWarnMessage(e.target.value)}
            />
          </div>
          <p className="detail-value small" style={{ marginTop: 10 }}>
            Le message sera envoyé en notification système (in-app + push).
          </p>
        </Modal>
      )}
    </div>
  );
}





