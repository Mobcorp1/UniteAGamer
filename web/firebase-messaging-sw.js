/* Web push is intentionally disabled for now.
   This placeholder prevents firebase_messaging from hitting a missing file route. */
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});
