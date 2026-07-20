importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCTvgkH0vRO-Ij5u10hh4jCvhCZ4-LhIFM',
  authDomain: 'unite-a-gamer.firebaseapp.com',
  projectId: 'unite-a-gamer',
  storageBucket: 'unite-a-gamer.firebasestorage.app',
  messagingSenderId: '1098283124220',
  appId: '1:1098283124220:web:d1447dcb1f977fcc0ade79',
  measurementId: 'G-9GJ2NSDB19',
});

const messaging = firebase.messaging();

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || data.title || 'UAG Arc Raiders Hub';
  const options = {
    body: notification.body || data.body || 'Open the app for details.',
    icon: notification.icon || '/icons/uag-hub-192.png',
    image: notification.image || data.imageUrl || undefined,
    badge: '/icons/uag-hub-192.png',
    data,
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const destination = data.deepLink || data.route || '/';
  const targetUrl = new URL(destination, self.location.origin).href;

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true,
    });

    for (const client of windows) {
      const clientUrl = new URL(client.url);
      if (clientUrl.origin === self.location.origin && 'focus' in client) {
        client.postMessage({ type: 'UAG_NOTIFICATION_CLICK', data });
        await client.focus();
        return;
      }
    }

    if (self.clients.openWindow) {
      await self.clients.openWindow(targetUrl);
    }
  })());
});
