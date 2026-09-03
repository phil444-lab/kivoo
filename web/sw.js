// Service worker PWA pour Kivoo (shell offline).
//
// Le service worker auto-généré par Flutter est déprécié (généré vide dans
// les versions récentes). Celui-ci fournit :
//  - le cache du "shell" de l'app (démarrage hors-ligne),
//  - un cache progressif des assets (fonts, icônes, images),
//  - un fallback index.html pour les navigations hors-ligne.
//
// ⚠️ Fix "Icon Font Loading Failure / Missing Material Icons Asset" :
//  1. Le nom du cache est VERSIONNÉ À CHAQUE BUILD : deploy-web.ps1 réécrit
//     la constante CACHE ci-dessous avec l'ID unique du build Flutter. À
//     l'activation, tous les caches des anciennes versions sont purgés.
//     (Avant : nom de cache fixe + cache-first => les clients servaient
//     indéfiniment main.dart.js / FontManifest.json périmés, mélangés aux
//     assets du nouveau déploiement => échecs de chargement de polices.)
//  2. Stratégie "network-first" avec repli sur le cache : le JS, le moteur
//     (canvaskit/skwasm) et les manifestes sont revalidés sur le réseau à
//     chaque fois ; le cache n'est servi qu'en cas d'échec réseau (offline).
// Les appels API (kivoo-api.vercel.app) et le CDN CanvasKit sont cross-origin
// et ne sont PAS interceptés : toujours réseau direct.

const CACHE = 'kivoo-pwa-dev'; // <-- réécrit à chaque build par deploy-web.ps1
const CORE = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/manifest.json',
  '/favicon.png',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(CORE))
      .catch(() => {}) // ne pas bloquer l'installation si un fichier manque
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return; // API / CDN : réseau direct

  // Navigations : réseau d'abord, fallback sur le shell en cache (offline)
  if (req.mode === 'navigate') {
    event.respondWith(fetch(req).catch(() => caches.match('/index.html')));
    return;
  }

  // Assets : réseau d'abord (revalidation systématique => jamais d'assets
  // périmés après un déploiement), repli sur le cache uniquement hors-ligne.
  // La réponse fraîche met le cache à jour au fil de l'eau.
  //
  // ⚠️ `cache: 'no-cache'` : force la REVALIDATION serveur (If-None-Match →
  // 304 si inchangé). Sans cela, `fetch(req)` (mode `default`) serait servi
  // depuis le cache HTTP du navigateur tant que `max-age` est valide — ce qui
  // contourne complètement le network-first et servait du JS périmé pendant
  // 1 h après chaque déploiement (Cache-Control: max-age=3600).
  event.respondWith(
    fetch(req, { cache: 'no-cache' })
      .then((res) => {
        const cacheable =
          res.ok &&
          (url.pathname.startsWith('/assets/') ||
            url.pathname.endsWith('.js') ||
            url.pathname.endsWith('.wasm') ||
            url.pathname.endsWith('.png') ||
            url.pathname.endsWith('.jpg'));
        if (cacheable) {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(req, copy));
        }
        return res;
      })
      .catch(() =>
        caches.match(req).then(
          (cached) =>
            cached ||
            new Response('', { status: 504, statusText: 'Offline' })
        )
      )
  );
});
