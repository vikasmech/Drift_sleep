const VERSION = 'drift-shell-v1';
const base = new URL('./', self.location.href).pathname;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(VERSION).then(cache => cache.add(base)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', event => {
  const req = event.request;
  const url = new URL(req.url);
  if (req.method !== 'GET' || url.origin !== self.location.origin ||
      url.pathname.includes('/api/') || url.pathname.includes('/offline-audio/') ||
      url.pathname.includes('/@vite/') || url.pathname.includes('/@react-refresh')) return;
  event.respondWith((async () => {
    const cache = await caches.open(VERSION);
    try {
      const res = await fetch(req);
      if (res.ok) await cache.put(req.mode === 'navigate' ? base : req, res.clone());
      return res;
    } catch (error) {
      const saved = await cache.match(req.mode === 'navigate' ? base : req);
      if (saved) return saved;
      throw error;
    }
  })());
});
