// Helper for Dart JS interop
window.subscribeToPushNotifications = async function(vapidPublicKey) {
  try {
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      throw new Error('Notification permission denied');
    }

    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
    });

    return JSON.stringify(subscription);
  } catch (e) {
    console.error('Error subscribing to push', e);
    throw e;
  }
};

window.unsubscribeFromPushNotifications = async function() {
  try {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.getSubscription();
    if (subscription) {
      await subscription.unsubscribe();
      return JSON.stringify({ endpoint: subscription.endpoint });
    }
    return null;
  } catch (e) {
    console.error('Error unsubscribing from push', e);
    throw e;
  }
};

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}
