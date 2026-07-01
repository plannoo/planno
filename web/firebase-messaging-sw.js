// web/firebase-messaging-sw.js
//
// IMPORTANT: This file MUST live at web/firebase-messaging-sw.js
// It is registered automatically by the firebase_messaging Flutter plugin.
// Without it, background notifications on web are silently dropped.
//
// Keep the Firebase version in sync with your firebase_core package.

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// These values come from Firebase Console → Project Settings → Your web app
firebase.initializeApp({
  apiKey:            "REPLACE_WITH_YOUR_API_KEY",
  authDomain:        "REPLACE_WITH_YOUR_PROJECT.firebaseapp.com",
  projectId:         "REPLACE_WITH_YOUR_PROJECT_ID",
  storageBucket:     "REPLACE_WITH_YOUR_PROJECT.appspot.com",
  messagingSenderId: "REPLACE_WITH_YOUR_SENDER_ID",
  appId:             "REPLACE_WITH_YOUR_APP_ID",
});

const messaging = firebase.messaging();

// Handles messages received when the web app tab is NOT focused or is closed.
// When the tab IS focused, the Flutter app handles it via onMessage stream.
messaging.onBackgroundMessage((payload) => {
  console.log('[FCM SW] Background message received:', payload);

  const notification = payload.notification ?? {};
  const data         = payload.data         ?? {};

  // Map our backend's notification types to appropriate icons
  const iconMap = {
    SHIFT_ASSIGNED:   '/icons/icon-shift.png',
    SHIFT_UPDATED:    '/icons/icon-shift.png',
    SHIFT_CANCELLED:  '/icons/icon-shift.png',
    ABSENCE_APPROVED: '/icons/icon-absence.png',
    ABSENCE_REJECTED: '/icons/icon-absence.png',
    ANNOUNCEMENT:     '/icons/icon-announcement.png',
    TASK_ASSIGNED:    '/icons/icon-task.png',
  };

  const icon = iconMap[data.type] ?? '/icons/Icon-192.png';

  return self.registration.showNotification(notification.title ?? 'Planno', {
    body:  notification.body ?? '',
    icon,
    badge: '/icons/Icon-192.png',
    data,                           // passed to notificationclick handler
    // Tag groups notifications of the same type so they replace each other
    // instead of stacking up (e.g. 5 shift assignments → 1 notification)
    tag:   data.type ?? 'planno',
  });
});

// Handles the user clicking the web notification.
// Opens the app and focuses the correct tab if already open.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data ?? {};

  // Route to the relevant section based on notification type
  const routeMap = {
    SHIFT_ASSIGNED:   '/shifts',
    SHIFT_UPDATED:    '/shifts',
    SHIFT_CANCELLED:  '/shifts',
    ABSENCE_APPROVED: '/absences',
    ABSENCE_REJECTED: '/absences',
    ANNOUNCEMENT:     `/announcements/${data.announcementId ?? ''}`,
    TASK_ASSIGNED:    '/tasks',
  };

  const targetPath = routeMap[data.type] ?? '/notifications';
  const targetUrl  = self.location.origin + targetPath;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app tab already open, focus it and navigate
      for (const client of clientList) {
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          client.focus();
          client.navigate(targetUrl);
          return;
        }
      }
      // Otherwise open a new tab
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    }),
  );
});
