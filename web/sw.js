// Service worker PWA minimal pour Kivoo (shell offline).
//
// Le service worker auto-généré par Flutter est déprécié (généré vide dans
// les versions récentes). Celui-ci fournit :
//  - le cache du "shell" de l'app (démarrage hors-ligne),
//  - un cache progressif des assets (fonts, icônes, images),
//  - un fallback index.html pour les navigations hors-ligne.
// Les appels API (kivoo-api.vercel.app) et le CDN CanvasKit sont cross-origin
// et ne sont PAS interceptés : toujours réseau direct.

const CACHE = 'kivoo-pwa-v1';
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

  // Assets : cache d'abord, puis réseau (mise en cache au fil de l'eau)
  event.respondWith(
    caches.match(req).then(
      (cached) =>
        cached ||
        fetch(req).then((res) => {
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
    )
  );
});
