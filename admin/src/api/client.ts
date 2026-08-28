import type { Pagination } from './types';

/**
 * En mode "preview/déploiement" du dashboard, on peut viser directement une API distante
 * (ex. déployée sur Vercel) via VITE_API_URL. En développement, on garde '/api'
 * que Vite proxifie vers le backend (voir vite.config.ts).
 */
const remoteApiUrl = import.meta.env.VITE_API_URL as string | undefined;
export const resolvedApiBase: string =
  remoteApiUrl && remoteApiUrl.trim() !== ''
    ? remoteApiUrl.replace(/\/+$/, '')
    : '/api';

export interface AuthSession {
  token: string;
  refreshToken: string;
}

export class ApiError extends Error {
  statusCode: number;
  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
  }
}

const STORAGE_KEYS = {
  token: 'kivoo_admin_token',
  refresh: 'kivoo_admin_refresh',
};

export const tokenStore = {
  get token(): string | null {
    return localStorage.getItem(STORAGE_KEYS.token);
  },
  get refreshToken(): string | null {
    return localStorage.getItem(STORAGE_KEYS.refresh);
  },
  set(session: AuthSession): void {
    localStorage.setItem(STORAGE_KEYS.token, session.token);
    localStorage.setItem(STORAGE_KEYS.refresh, session.refreshToken);
  },
  clear(): void {
    localStorage.removeItem(STORAGE_KEYS.token);
    localStorage.removeItem(STORAGE_KEYS.refresh);
  },
};

let onUnauthorized: (() => void) | null = null;

/** Callback appelé quand la session est définitivement invalide (logout forcé) */
export function setUnauthorizedHandler(handler: () => void): void {
  onUnauthorized = handler;
}

interface RequestOptions {
  method?: string;
  body?: unknown;
}

let refreshPromise: Promise<boolean> | null = null;

async function tryRefreshToken(): Promise<boolean> {
  const refresh = tokenStore.refreshToken;
  if (!refresh) return false;

  if (!refreshPromise) {
    refreshPromise = (async () => {
      try {
        const res = await fetch(`${resolvedApiBase}/auth/refresh-token`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${refresh}`, 'Content-Type': 'application/json' },
        });
        if (!res.ok) return false;
        const json = await res.json();
        if (json?.data?.token && json?.data?.refreshToken) {
          tokenStore.set({ token: json.data.token, refreshToken: json.data.refreshToken });
          return true;
        }
        return false;
      } catch {
        return false;
      } finally {
        setTimeout(() => { refreshPromise = null; }, 0);
      }
    })();
  }
  return refreshPromise;
}

/**
 * Client HTTP vers l'API Kivoo avec gestion du refresh token automatique.
 */
export async function api<T = unknown>(
  path: string,
  options: RequestOptions = {}
): Promise<T> {
  const doFetch = async (): Promise<Response> => {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    const token = tokenStore.token;
    if (token) headers.Authorization = `Bearer ${token}`;
    return fetch(`${resolvedApiBase}${path}`, {
      method: options.method || 'GET',
      headers,
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    });
  };

  let res = await doFetch();

  // Token expiré → tentative de refresh puis rejeu de la requête
  if (res.status === 401) {
    const refreshed = await tryRefreshToken();
    if (refreshed) {
      res = await doFetch();
    }
  }

  let json: any = null;
  try {
    json = await res.json();
  } catch {
    json = null;
  }

  if (!res.ok) {
    if (res.status === 401 && onUnauthorized) {
      tokenStore.clear();
      onUnauthorized();
    }
    throw new ApiError(
      res.status,
      json?.message || `Erreur ${res.status} lors de l'appel à ${path}`
    );
  }

  return (json?.data !== undefined ? json.data : json) as T;
}

/** Requête dont la réponse contient une liste paginée */
export async function apiList<T>(
  path: string,
  params: Record<string, string | number | undefined | null>
): Promise<{ [key: string]: T[] | Pagination }> {
  const qs = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      qs.set(key, String(value));
    }
  });
  const suffix = qs.toString() ? `?${qs.toString()}` : '';
  return api(`/admin${path}${suffix}`);
}

/** Requête simple sous /admin */
export function adminApi<T = unknown>(path: string, options: RequestOptions = {}): Promise<T> {
  return api<T>(`/admin${path}`, options);
}

/** Connexion administrateur (vérifie le rôle) */
export async function loginAdmin(
  identifier: string,
  password: string
): Promise<{ id: string; name: string; email: string; role: string }> {
  const data = await api<{
    user: { id: string; name: string; email: string; role: string };
    token: string;
    refreshToken: string;
  }>('/auth/login', { method: 'POST', body: { identifier, password } });

  if (data.user.role !== 'admin') {
    throw new ApiError(403, "Ce compte n'est pas administrateur");
  }
  tokenStore.set({ token: data.token, refreshToken: data.refreshToken });
  return data.user;
}

/** Déconnexion (invalide la session côté serveur) */
export async function logoutApi(): Promise<void> {
  try {
    await api('/auth/logout', { method: 'POST' });
  } catch {
    // best-effort
  }
  tokenStore.clear();
}
