import { useEffect, useState } from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  BarChart,
  Bar,
  Cell,
} from 'recharts';
import { adminApi } from '../api/client';
import type { Stats, Analytics } from '../api/types';
import { StatCard, EmptyState, LoadingState, Select } from '../components/ui';
import {
  IconUsers,
  IconBox,
  IconShield,
  IconEye,
  IconStar,
  IconCheckCircle,
} from '../components/icons';

const CHART_COLORS = [
  '#2563eb', '#22c55e', '#f59e0b', '#8b5cf6', '#ef4444',
  '#60a5fa', '#14b8a6', '#e879f9', '#84cc16', '#fb923c',
];

interface TooltipPayloadItem {
  name?: string;
  value?: number;
  color?: string;
}

function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="chart-tooltip">
      <div className="tt-label">{label}</div>
      {payload.map((entry, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span
            style={{ width: 8, height: 8, borderRadius: 4, background: entry.color, display: 'inline-block' }}
          />
          <span style={{ color: 'var(--text-muted)' }}>{entry.name} :</span>
          <b>{entry.value}</b>
        </div>
      ))}
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [days, setDays] = useState('30');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    Promise.all([adminApi<Stats>('/stats'), adminApi<Analytics>(`/analytics?days=${days}`)])
      .then(([s, a]) => {
        if (cancelled) return;
        setStats(s);
        setAnalytics(a);
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [days]);

  if (loading && !stats) return <LoadingState label="Chargement des indicateurs..." />;
  if (!stats) return <EmptyState title="Impossible de charger les statistiques" />;

  const tickColor = 'var(--text-faint)';
  const gridColor = 'var(--outline)';

  return (
    <div>
      <div className="stat-grid">
        <StatCard
          label="Utilisateurs inscrits"
          value={stats.users.total}
          icon={<IconUsers />}
          color="primary"
          extra={
            <>
              <b>+{stats.users.newLast30d}</b> sur 30 jours · {stats.users.verified} vérifiés
            </>
          }
        />
        <StatCard
          label="Annonces actives"
          value={stats.items.active}
          icon={<IconBox />}
          color="success"
          extra={
            <>
              {stats.items.sold} vendues · {stats.items.expired} expirées
            </>
          }
        />
        <StatCard
          label="Annonces en attente"
          value={stats.items.pending}
          icon={<IconCheckCircle />}
          color="warning"
          extra="File de validation"
        />
        <StatCard
          label="Signalements non traités"
          value={stats.reports.pending}
          icon={<IconShield />}
          color={stats.reports.pending > 0 ? 'danger' : 'success'}
          extra={`${stats.reports.reviewed} revus · ${stats.reports.resolved} résolus`}
        />
        <StatCard
          label="Sessions actives"
          value={stats.activeSessions}
          icon={<IconEye />}
          color="info"
        />
        <StatCard
          label="Annonces mises en avant"
          value={stats.items.featured}
          icon={<IconStar />}
          color="primary"
        />
      </div>

      <div style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))' }}>
        <div className="card" style={{ minHeight: 380 }}>
          <div className="card-header">
            <div>
              <h3 className="card-title">Évolution des inscriptions & annonces</h3>
              <p className="card-subtitle">Nouveaux comptes et nouvelles annonces par jour</p>
            </div>
            <Select
              value={days}
              onChange={setDays}
              options={[
                { value: '7', label: '7 jours' },
                { value: '30', label: '30 jours' },
                { value: '90', label: '90 jours' },
                { value: '365', label: '1 an' },
              ]}
              style={{ width: 'auto' }}
            />
          </div>
          <div className="card-body" style={{ height: 300 }}>
            {analytics && analytics.timeline.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={analytics.timeline} margin={{ top: 5, right: 10, left: -18, bottom: 0 }}>
                  <CartesianGrid stroke={gridColor} strokeDasharray="3 3" vertical={false} />
                  <XAxis
                    dataKey="label"
                    tick={{ fill: tickColor, fontSize: 11 }}
                    interval="preserveStartEnd"
                    minTickGap={28}
                    tickLine={false}
                  />
                  <YAxis tick={{ fill: tickColor, fontSize: 11 }} tickLine={false} allowDecimals={false} />
                  <Tooltip content={<ChartTooltip />} />
                  <Legend wrapperStyle={{ fontSize: 12.5 }} />
                  <Line
                    type="monotone"
                    dataKey="signups"
                    name="Inscriptions"
                    stroke="#2563eb"
                    strokeWidth={2.2}
                    dot={false}
                    activeDot={{ r: 4 }}
                  />
                  <Line
                    type="monotone"
                    dataKey="items"
                    name="Annonces"
                    stroke="#22c55e"
                    strokeWidth={2.2}
                    dot={false}
                    activeDot={{ r: 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState title="Pas encore de données" text="Aucune inscription ou annonce sur la période" />
            )}
          </div>
        </div>

        <div className="card" style={{ minHeight: 380 }}>
          <div className="card-header">
            <div>
              <h3 className="card-title">Répartition par localisation</h3>
              <p className="card-subtitle">Annonces par ville (Cotonou, Calavi, Parakou...)</p>
            </div>
          </div>
          <div className="card-body" style={{ height: 300 }}>
            {analytics && analytics.byCity.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={analytics.byCity}
                  layout="vertical"
                  margin={{ top: 0, right: 16, left: 20, bottom: 0 }}
                >
                  <CartesianGrid stroke={gridColor} strokeDasharray="3 3" horizontal={false} />
                  <XAxis type="number" tick={{ fill: tickColor, fontSize: 11 }} tickLine={false} allowDecimals={false} />
                  <YAxis
                    type="category"
                    dataKey="city"
                    width={86}
                    tick={{ fill: tickColor, fontSize: 11.5 }}
                    tickLine={false}
                  />
                  <Tooltip content={<ChartTooltip />} cursor={{ fill: 'var(--hover)' }} />
                  <Bar dataKey="count" name="Annonces" radius={[0, 6, 6, 0]} barSize={16}>
                    {analytics.byCity.map((_, index) => (
                      <Cell key={index} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <EmptyState title="Pas encore de données" text="Aucune annonce géolocalisée sur la période" />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

