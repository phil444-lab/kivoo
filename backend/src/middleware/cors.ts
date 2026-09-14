import config from '../config/index.js';

/** Convertit un motif d'origine (« https://*.vercel.app ») en RegExp. */
const wildcardToRegExp = (pattern: string): RegExp => {
  const escaped = pattern
    .replace(/[.+?^${}()|[\]\\]/g, '\\$&')
    .replace(/\*/g, '.*');
  return new RegExp(`^${escaped}$`);
};

/** Origines exactes déclarées dans FRONTEND_URLS (sans « * »). */
const exactOrigins = new Set(
  config.frontendUrls.filter((url) => !url.includes('*'))
);

/** Motifs déclarés dans FRONTEND_URLS contenant un « * ». */
const wildcardPatterns = config.frontendUrls
  .filter((url) => url.includes('*'))
  .map(wildcardToRegExp);

/** Origines locales de développement (Flutter web, Vite, dashboard…). */
const localhostPattern =
  /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/;

/**
 * Une origine est-elle autorisée à appeler l'API ?
 *
 * Les applis mobiles natives n'envoient pas d'en-tête `Origin` : elles sont
 * traitées directement dans [corsOriginHandler].
 */
export const isOriginAllowed = (origin: string): boolean => {
  if (exactOrigins.has(origin)) return true;
  if (wildcardPatterns.some((pattern) => pattern.test(origin))) return true;
  if (config.corsAllowLocalhost && localhostPattern.test(origin)) return true;
  return false;
};

/**
 * Gestionnaire d'origine pour le middleware CORS.
 *
 * ️ On répond `cb(null, false)` (et non `cb(new Error(...))`) pour une origine
 * non autorisée : le navigateur bloque bien la requête (aucun en-tête CORS
 * n'est renvoyé), mais le serveur répond proprement. Lever une erreur faisait
 * échouer le préflight `OPTIONS` en **500**, ce qui masquait la cause réelle :
 * depuis Flutter web, les requêtes authentifiées (dont les favoris) semblaient
 * simplement « ne pas passer », sans message exploitable.
 */
export const corsOriginHandler = (
  origin: string | undefined,
  cb: (err: Error | null, allow?: boolean) => void
): void => {
  // Requête sans en-tête Origin : app mobile native, curl, cron, webhook…
  if (!origin) return cb(null, true);

  if (isOriginAllowed(origin)) return cb(null, true);

  console.warn(
    `⚠️ CORS: origine refusée → ${origin}. ` +
      'Ajoutez-la à FRONTEND_URLS (backend) si c\'est légitime.'
  );
  return cb(null, false);
};