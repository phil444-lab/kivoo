import { useEffect, useState } from 'react';
import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { adminApi } from '../api/client';
import type { Stats } from '../api/types';
import { Avatar } from './ui';
import {
  IconDashboard,
  IconShield,
  IconCheckCircle,
  IconBox,
  IconUsers,
  IconTag,
  IconMapPin,
  IconStar,
  IconBell,
  IconMoon,
  IconSun,
  IconLogout,
  IconMenu,
} from './icons';

const NAV_SECTIONS: {
  section: string;
  items: { to: string; label: string; icon: (p: any) => JSX.Element; badge?: 'reports' }[];
}[] = [
  {
    section: 'Pilotage',
    items: [{ to: '/', label: 'Tableau de bord', icon: IconDashboard }],
  },
  {
    section: 'Modération',
    items: [
      { to: '/reports', label: 'Signalements', icon: IconShield, badge: 'reports' },
      { to: '/validation', label: 'Validation annonces', icon: IconCheckCircle },
    ],
  },
  {
    section: 'Gestion',
    items: [
      { to: '/items', label: 'Annonces', icon: IconBox },
      { to: '/users', label: 'Utilisateurs', icon: IconUsers },
    ],
  },
  {
    section: 'Référentiel',
    items: [
      { to: '/categories', label: 'Catégories', icon: IconTag },
      { to: '/locations', label: 'Zones du Bénin', icon: IconMapPin },
      { to: '/featured-options', label: 'Offres sponsorisées', icon: IconStar },
    ],
  },
  {
    section: 'Système',
    items: [{ to: '/notifications', label: 'Notifications', icon: IconBell }],
  },
];

const TITLES: Record<string, string> = {
  '/': 'Tableau de bord',
  '/reports': 'Modération & Signalements',
  '/validation': 'Validation des annonces',
  '/items': 'Gestion des annonces',
  '/users': 'Gestion des utilisateurs',
  '/categories': 'Catégories',
  '/locations': 'Zones du Bénin',
  '/featured-options': 'Offres sponsorisées',
  '/notifications': 'Communications système',
};

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { admin, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    let cancelled = false;
    adminApi<Stats>('/stats')
      .then((s) => {
        if (!cancelled) setStats(s);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [location.pathname]);

  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

  const pendingReports = stats?.reports.pending ?? 0;
  const pendingItems = stats?.items.pending ?? 0;

  return (
    <div className="admin-shell">
      <div
        className={`mobile-overlay ${sidebarOpen ? 'show' : ''}`}
        onClick={() => setSidebarOpen(false)}
      />
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-brand">
          <div className="brand-logo">K</div>
          <div className="brand-name">
            Kivoo<span>Admin</span>
          </div>
          <span className="brand-badge">Pro</span>
        </div>

        <nav className="sidebar-nav">
          {NAV_SECTIONS.map((group) => (
            <div key={group.section}>
              <div className="nav-section">{group.section}</div>
              {group.items.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
                >
                  <item.icon />
                  <span>{item.label}</span>
                  {item.badge === 'reports' && pendingReports > 0 && (
                    <span className="nav-badge">{pendingReports > 99 ? '99+' : pendingReports}</span>
                  )}
                  {item.to === '/validation' && pendingItems > 0 && (
                    <span className="nav-badge" style={{ background: 'var(--warning)' }}>
                      {pendingItems > 99 ? '99+' : pendingItems}
                    </span>
                  )}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="admin-user">
            <Avatar name={admin?.name || 'Admin'} />
            <div className="admin-user-info">
              <div className="admin-user-name">{admin?.name}</div>
              <div className="admin-user-email">{admin?.email}</div>
            </div>
          </div>
        </div>
      </aside>

      <div className="main-content">
        <header className="topbar">
          <div className="topbar-title">
            <button className="menu-toggle" onClick={() => setSidebarOpen(true)} aria-label="Menu">
              <IconMenu />
            </button>
            {TITLES[location.pathname] || 'Kivoo Admin'}
          </div>
          <div className="topbar-actions">
            <button
              className="btn btn-ghost btn-icon"
              onClick={toggleTheme}
              aria-label="Changer de thème"
              title={theme === 'dark' ? 'Thème clair' : 'Thème sombre'}
            >
              {theme === 'dark' ? <IconSun /> : <IconMoon />}
            </button>
            <button
              className="btn btn-ghost btn-icon"
              onClick={() => {
                logout();
                navigate('/login');
              }}
              aria-label="Déconnexion"
              title="Déconnexion"
            >
              <IconLogout />
            </button>
          </div>
        </header>
        <div className="page-content">{children}</div>
      </div>
    </div>
  );
}
