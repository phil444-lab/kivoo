import { useEffect, useState, type ReactNode } from 'react';
import { adminApi } from '../api/client';
import type { AdminItem } from '../api/types';
import { Modal, Badge, DetailItem, Avatar, LoadingState } from './ui';
import { formatDate, formatDateTime, formatPrice, extractImageUrls } from '../utils/format';

const STATUS_BADGES: Record<string, { color: 'primary' | 'success' | 'warning' | 'danger' | 'neutral'; label: string }> = {
  active: { color: 'success', label: 'Active' },
  sold: { color: 'primary', label: 'Vendue' },
  expired: { color: 'neutral', label: 'Expirée / masquée' },
  pending: { color: 'warning', label: 'En attente' },
};

export default function ItemDetailModal({
  itemId,
  onClose,
  actions,
}: {
  itemId: string;
  onClose: () => void;
  actions?: (item: AdminItem) => ReactNode;
}) {
  const [item, setItem] = useState<AdminItem | null>(null);
  const [zoom, setZoom] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    adminApi<AdminItem>(`/items/${itemId}`)
      .then((i) => {
        if (!cancelled) setItem(i);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [itemId]);

  const statusBadge = item ? STATUS_BADGES[item.status] : null;
  const images = item ? extractImageUrls(item.images) : [];

  return (
    <>
      <Modal
        title={item ? item.title : 'Détail de l\'annonce'}
        onClose={onClose}
        size="lg"
        footer={item && actions ? <>{actions(item)}</> : undefined}
      >
        {!item ? (
          <LoadingState />
        ) : (
          <div>
            {statusBadge && (
              <div style={{ marginBottom: 14 }}>
                <Badge color={statusBadge.color} dot>
                  {statusBadge.label}
                </Badge>
                {item.featured && (
                  <Badge color="primary" dot>
                    Mise en avant
                  </Badge>
                )}
                {item.boostLevel > 0 && (
                  <Badge color="info" dot>
                    Boost x{item.boostLevel}
                  </Badge>
                )}
              </div>
            )}

            {images.length > 0 ? (
              <div className="img-grid" style={{ marginBottom: 16 }}>
                {images.map((url, i) => (
                  <img key={i} src={url} alt={`${item.title} ${i + 1}`} onClick={() => setZoom(url)} />
                ))}
              </div>
            ) : (
              <div
                style={{
                  padding: 20,
                  textAlign: 'center',
                  color: 'var(--text-faint)',
                  border: '1px dashed var(--outline)',
                  borderRadius: 'var(--radius-md)',
                  marginBottom: 16,
                }}
              >
                Aucune photo
              </div>
            )}

            <div className="detail-grid">
              <DetailItem label="Prix" value={formatPrice(item.price)} />
              <DetailItem label="Type" value={item.priceType} small />
              <DetailItem label="État" value={item.condition} small />
              <DetailItem label="Vues" value={item.views} />
              <DetailItem label="Favoris" value={item._count.favorites} />
              <DetailItem label="Signalements" value={item._count.reports} />
            </div>

            <div className="section-title">Localisation & catégorie</div>
            <div className="detail-grid">
              <DetailItem label="Ville" value={item.city?.name || '—'} small />
              <DetailItem label="Département" value={item.department?.name || '—'} small />
              <DetailItem label="Quartier" value={item.district?.name || '—'} small />
              <DetailItem
                label="Catégorie"
                value={
                  item.category
                    ? `${item.category.name}${item.subcategory ? ` › ${item.subcategory.name}` : ''}`
                    : '—'
                }
                small
              />
            </div>

            <div className="section-title">Description</div>
            <div
              style={{
                background: 'var(--surface)',
                border: '1px solid var(--outline)',
                borderRadius: 'var(--radius-md)',
                padding: '12px 14px',
                fontSize: 13,
                color: 'var(--text-muted)',
                whiteSpace: 'pre-wrap',
              }}
            >
              {item.description}
            </div>

            <div className="section-title">Vendeur</div>
            <div className="person-row">
              <Avatar name={item.seller.name} photo={item.seller.photo} size="lg" />
              <div>
                <div className="detail-value">{item.seller.name}</div>
                <div className="detail-value small">
                  {item.seller.email} · {item.seller.phone}
                </div>
                <div className="detail-value small">
                  Note {item.seller.rating.toFixed(1)}
                </div>
              </div>
            </div>

            <div className="section-title">Dates</div>
            <div className="detail-grid">
              <DetailItem label="Créée le" value={formatDateTime(item.createdAt)} small />
              <DetailItem label="Expire le" value={formatDate(item.expiresAt)} small />
              {item.featuredUntil && (
                <DetailItem label="En avant jusqu'au" value={formatDate(item.featuredUntil)} small />
              )}
              {item.boostUntil && (
                <DetailItem label="Boost jusqu'au" value={formatDate(item.boostUntil)} small />
              )}
            </div>
          </div>
        )}
      </Modal>

      {zoom && (
        <div className="modal-overlay" style={{ zIndex: 200 }} onClick={() => setZoom(null)}>
          <img
            src={zoom}
            alt="Aperçu"
            style={{ maxWidth: '92vw', maxHeight: '90vh', borderRadius: 12, cursor: 'zoom-out' }}
          />
        </div>
      )}
    </>
  );
}

