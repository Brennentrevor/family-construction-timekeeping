const CACHE_NAME = 'timekeeping-v1';
const ASSETS = ['./index.html', './manifest.json', './icon-192.png', './icon-512.png'];
self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)));
  self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);
  // Cross-origin (Supabase API, CDN) or non-GET: always go to network, never cache.
  if (req.method !== 'GET' || url.origin !== self.location.origin) return;
  event.respondWith(caches.match(req).then((response) => response || fetch(req)));
});
