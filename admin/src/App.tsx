import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import AdminLayout from './components/AdminLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ReportsPage from './pages/ReportsPage';
import ValidationPage from './pages/ValidationPage';
import ItemsPage from './pages/ItemsPage';
import UsersPage from './pages/UsersPage';
import CategoriesPage from './pages/CategoriesPage';
import LocationsPage from './pages/LocationsPage';
import FeaturedOptionsPage from './pages/FeaturedOptionsPage';
import NotificationsPage from './pages/NotificationsPage';
import type { ReactNode } from 'react';

function RequireAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={
            <RequireAuth>
              <AdminLayout>
                <DashboardPage />
              </AdminLayout>
            </RequireAuth>
          }
        />
        <Route path="/reports" element={<RequireAuth><AdminLayout><ReportsPage /></AdminLayout></RequireAuth>} />
        <Route path="/validation" element={<RequireAuth><AdminLayout><ValidationPage /></AdminLayout></RequireAuth>} />
        <Route path="/items" element={<RequireAuth><AdminLayout><ItemsPage /></AdminLayout></RequireAuth>} />
        <Route path="/users" element={<RequireAuth><AdminLayout><UsersPage /></AdminLayout></RequireAuth>} />
        <Route path="/categories" element={<RequireAuth><AdminLayout><CategoriesPage /></AdminLayout></RequireAuth>} />
        <Route path="/locations" element={<RequireAuth><AdminLayout><LocationsPage /></AdminLayout></RequireAuth>} />
        <Route path="/featured-options" element={<RequireAuth><AdminLayout><FeaturedOptionsPage /></AdminLayout></RequireAuth>} />
        <Route path="/notifications" element={<RequireAuth><AdminLayout><NotificationsPage /></AdminLayout></RequireAuth>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}