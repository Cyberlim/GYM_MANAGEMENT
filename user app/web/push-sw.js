self.addEventListener('push', function(event) {
  if (event.data) {
    try {
      const data = event.data.json();
      const title = data.title || 'New Notification';
      const options = {
        body: data.body || data.message || '',
        icon: data.icon || '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: {
          url: data.url || '/'
        }
      };

      event.waitUntil(self.registration.showNotification(title, options));
    } catch (e) {
      console.error('Push payload is not JSON', e);
      event.waitUntil(self.registration.showNotification('New Notification', { body: event.data.text() }));
    }
  }
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      // Check if there is already a window/tab open with the target URL
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (client.url === event.notification.data.url && 'focus' in client) {
          return client.focus();
        }
      }
      // If not, open a new window
      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.url);
      }
    })
  );
});
