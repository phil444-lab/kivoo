import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import { tokenStore, setUnauthorizedHandler, logoutApi } from '../api/client';

interface AdminAccount {
  id: string;
  name: string;
  email: string;
  role: string;
}

interface AuthContextValue {
  admin: AdminAccount | null;
  isAuthenticated: boolean;
  login: (account: AdminAccount) => void;
  logout: () => void;
}

const AUTH_KEY = 'kivoo_admin_account';

const AuthContext = createContext<AuthContextValue>({
  admin: null,
  isAuthenticated: false,
  login: () => {},
  logout: () => {},
});

function readStoredAccount(): AdminAccount | null {
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as AdminAccount;
    // Pas de token = session morte
    if (!tokenStore.token) return null;
    if (parsed?.role !== 'admin') return null;
    return parsed;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<AdminAccount | null>(() => readStoredAccount());

  useEffect(() => {
    // Logout forcé quand le client API détecte une session invalide
    setUnauthorizedHandler(() => {
      setAdmin(null);
      localStorage.removeItem(AUTH_KEY);
    });
  }, []);

  const login = useCallback((account: AdminAccount) => {
    localStorage.setItem(AUTH_KEY, JSON.stringify(account));
    setAdmin(account);
  }, []);

  const logout = useCallback(() => {
    void logoutApi();
    localStorage.removeItem(AUTH_KEY);
    setAdmin(null);
  }, []);

  return (
    <AuthContext.Provider
      value={{ admin, isAuthenticated: admin !== null, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  return useContext(AuthContext);
}
