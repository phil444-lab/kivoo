/* Service worker Firebase Cloud Messaging — notifications push web (PWA).
 *
 * Il doit être servi à la racine du site : /firebase-messaging-sw.js
 * (Firebase Messaging cherche ce chemin par défaut pour gérer les
 * notifications quand l'application est en arrière-plan / fermée.)
 *
 * IMPORTANT : les valeurs ci-dessous doivent être IDENTIQUES à
 * _kFirebaseWebOptions dans lib/main.dart.
 */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD6GxVAUPIZqo0WKszbbq2cPeC2zpxNclQ',
  appId: 'VOTRE_APP_ID_WEB', // 1:694202781524:web:xxxx (console Firebase)
  messagingSenderId: '694202781524',
  projectId: 'kivoo-d8521',
  storageBucket: 'kivoo-d8521.firebasestorage.app',
  authDomain: 'kivoo-d8521.firebaseapp.com',
});

try {
  const messaging = firebase.messaging();

  // Notification affichée quand l'app est en arrière-plan / fermée.
  messaging.onBackgroundMessage((payload) => {
    const title = (payload.notification && payload.notification.title) || 'Kivoo';
    const options = {
      body: (payload.notification && payload.notification.body) || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      tag: payload.messageId || undefined,
      data: payload.data || {},
    };
    self.registration.showNotification(title, options);
  });

  // Clic sur la notification : ouvrir / focaliser l'application.
  self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    event.waitUntil(
      self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) return client.focus();
        }
        return self.clients.openWindow('/');
      })
    );
  });
} catch (e) {
  console.warn('[firebase-messaging-sw] Initialisation impossible :', e);
}
