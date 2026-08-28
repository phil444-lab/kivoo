export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return '—';
  const d = typeof value === 'string' ? new Date(value) : value;
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export function formatDateTime(value: string | Date | null | undefined): string {
  if (!value) return '—';
  const d = typeof value === 'string' ? new Date(value) : value;
  if (isNaN(d.getTime())) return '—';
  return d.toLocaleString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatPrice(price: number): string {
  return `${new Intl.NumberFormat('fr-FR').format(Math.round(price))} F`;
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat('fr-FR').format(value);
}

export function extractImageUrls(images: unknown): string[] {
  if (!images) return [];
  if (Array.isArray(images)) {
    return images
      .map((img) => {
        if (typeof img === 'string') return img;
        if (img && typeof img === 'object' && 'url' in (img as Record<string, unknown>)) {
          return String((img as Record<string, unknown>).url);
        }
        return null;
      })
      .filter((u): u is string => !!u);
  }
  return [];
}

export function getLocationLabel(location: unknown): string {
  if (!location || typeof location !== 'object') return '—';
  const loc = location as Record<string, unknown>;
  return String(loc.city || loc.address || loc.country || '—');
}

/** Récupère les initiales d'un nom pour l'avatar */
export function getInitials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}
