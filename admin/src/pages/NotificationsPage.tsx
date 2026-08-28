import { useEffect, useState } from 'react';
import { adminApi } from '../api/client';
import type { NotificationRecord } from '../api/types';
import { LoadingState, EmptyState, Avatar } from '../components/ui';
import { useToast } from '../context/ToastContext';
import { IconBell } from '../components/icons';
import { formatDateTime } from '../utils/format';

type Scope = 'all' | 'filter' | 'users';

export default function NotificationsPage() {
  const { showToast } = useToast();
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [scope, setScope] = useState<Scope>('all');
  const [cityId, setCityId] = useState('');
  const [verified, setVerified] = useState('');
  const [sendPush, setSendPush] = useState(true);
  const [userIds, setUserIds] = useState('');
  const [busy, setBusy] = useState(false);
  const [history, setHistory] = useState<NotificationRecord[]>([]);
  const [historyLoading, setHistoryLoading] = useState(true);

  useEffect(() => {
    void adminApi<NotificationRecord[]>('/notifications/history')
      .then(setHistory)
      .catch(() => {})
      .finally(() => setHistoryLoading(false));
  }, []);

  const send = async () => {
    if (!title.trim() || !message.trim()) return;
    setBusy(true);
    try {
      const parsedIds = userIds
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      const result = await adminApi<{ sent: number; pushSent?: number }>('/notifications/broadcast', {
        method: 'POST',
        body: {
          title: title.trim(),
          message: message.trim(),
          scope,
          sendPush,
          cityId: cityId || undefined,
          verified: verified === 'true' ? true : verified === 'false' ? false : undefined,
          userIds: parsedIds.length ? parsedIds : undefined,
        },
      });
      showToast('success', 'Notification envoyée', `${result.sent} utilisateur(s) notifié(s)`);
      setTitle('');
      setMessage('');
      setUserIds('');
      const h = await adminApi<NotificationRecord[]>('/notifications/history');
      setHistory(h);
    } catch (err) {
      showToast('error', 'Erreur', err instanceof Error ? err.message : 'Envoi impossible');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <div className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">Nouvelle notification</h3>
            <p className="card-subtitle">Envoi ciblé de notifications in-app et push (FCM)</p>
          </div>
        </div>
        <div className="card-body">
          <div className="form-field" style={{ marginBottom: 14 }}>
            <label className="form-label">Titre</label>
            <input
              className="input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Ex : Nouvelle fonctionnalité disponible"
            />
          </div>

          <div className="form-field" style={{ marginBottom: 14 }}>
            <label className="form-label">Message</label>
            <textarea
              className="textarea"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Votre message à destination des utilisateurs..."
            />
          </div>

          <div className="form-field" style={{ marginBottom: 14 }}>
            <label className="form-label">Destinataires</label>
            <div className="tabs" style={{ width: 'fit-content' }}>
              <button className={`tab ${scope === 'all' ? 'active' : ''}`} onClick={() => setScope('all')}>
                Tous les utilisateurs
              </button>
              <button className={`tab ${scope === 'filter' ? 'active' : ''}`} onClick={() => setScope('filter')}>
                Par critères
              </button>
              <button className={`tab ${scope === 'users' ? 'active' : ''}`} onClick={() => setScope('users')}>
                Par IDs
              </button>
            </div>
          </div>

          {scope === 'filter' && (
            <div className="form-grid" style={{ marginBottom: 14 }}>
              <div className="form-field">
                <label className="form-label">Statut de vérification</label>
                <select className="select" value={verified} onChange={(e) => setVerified(e.target.value)}>
                  <option value="">Tous</option>
                  <option value="true">Vérifiés uniquement</option>
                  <option value="false">Non vérifiés uniquement</option>
                </select>
              </div>
            </div>
          )}

          {scope === 'users' && (
            <div className="form-field" style={{ marginBottom: 14 }}>
              <label className="form-label">Identifiants utilisateurs (séparés par des virgules)</label>
              <input
                className="input"
                value={userIds}
                onChange={(e) => setUserIds(e.target.value)}
                placeholder="id1,id2,id3"
              />
            </div>
          )}

          <div className="form-field" style={{ marginBottom: 18 }}>
            <span className="detail-value small" style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }} onClick={() => setSendPush((v) => !v)}>
              <span className={`switch ${sendPush ? 'on' : ''}`} style={{ display: 'inline-block' }} />
              Envoyer aussi un push (FCM) si configuré
            </span>
          </div>

          <button className="btn btn-primary" onClick={send} disabled={busy || !title.trim() || !message.trim()}>
            <IconBell /> {busy ? 'Envoi...' : 'Envoyer la notification'}
          </button>
        </div>
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div className="card-header">
          <div>
            <h3 className="card-title">Historique des notifications système</h3>
            <p className="card-subtitle">50 dernières notifications envoyées</p>
          </div>
        </div>
        {historyLoading ? (
          <LoadingState />
        ) : history.length === 0 ? (
          <EmptyState title="Aucune notification envoyée" />
        ) : (
          <div className="table-wrapper">
            <table className="table">
              <thead>
                <tr>
                  <th>Utilisateur</th>
                  <th>Titre</th>
                  <th>Message</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {history.map((n) => (
                  <tr key={n.id}>
                    <td>
                      <div className="person-row">
                        <Avatar name={n.user?.name || '?'} photo={n.user?.photo} />
                        <span className="cell-sub">{n.user?.name || '?'}</span>
                      </div>
                    </td>
                    <td className="cell-main">{n.title}</td>
                    <td className="cell-sub" style={{ maxWidth: 280 }}>{n.message}</td>
                    <td className="cell-sub">{formatDateTime(n.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}