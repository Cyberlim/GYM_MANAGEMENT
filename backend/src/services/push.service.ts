import webpush from 'web-push';
import dotenv from 'dotenv';
import User from '../models/User.model';

dotenv.config();

const publicKey = process.env.VAPID_PUBLIC_KEY || '';
const privateKey = process.env.VAPID_PRIVATE_KEY || '';

if (publicKey && privateKey) {
  webpush.setVapidDetails(
    'mailto:gymcrm.noreply@gmail.com', // Using the email from .env
    publicKey,
    privateKey
  );
} else {
  console.warn('VAPID keys not configured in .env. Web Push will not work.');
}

/**
 * Sends a push notification to a specific user.
 * It loops through all stored subscriptions for that user.
 */
export const sendPushNotificationToUser = async (userId: string, payload: { title: string; body?: string; url?: string; icon?: string, type?: string }) => {
  try {
    const user = await User.findById(userId);
    if (!user || !user.pushSubscriptions || user.pushSubscriptions.length === 0) {
      return;
    }

    // Check if push notifications are enabled in user settings
    if (user.settings && user.settings.pushNotifications === false) {
      return;
    }

    // Filter by type if provided and if it's a superadmin (checking settings structure)
    if (payload.type && user.settings) {
      const type = payload.type;
      if (type === 'system' && user.settings.systemAlerts === false) return;
      if (type === 'registration' && user.settings.newGymSignups === false) return;
      if (type === 'payment') {
        const titleLower = payload.title.toLowerCase();
        const isFailure = titleLower.includes('fail') || titleLower.includes('error');
        if (isFailure && user.settings.paymentFailures === false) return;
        if (!isFailure && user.settings.paymentReceived === false) return;
      }
    }

    const stringifiedPayload = JSON.stringify(payload);
    const staleSubscriptions: any[] = [];

    // Send push to all registered devices for this user
    await Promise.all(
      user.pushSubscriptions.map(async (sub) => {
        try {
          await webpush.sendNotification(sub, stringifiedPayload);
        } catch (error: any) {
          // If subscription is gone or expired, we should remove it
          if (error.statusCode === 404 || error.statusCode === 410) {
            staleSubscriptions.push(sub);
          } else {
            console.error('Error sending push notification to subscription:', error);
          }
        }
      })
    );

    // Clean up stale subscriptions
    if (staleSubscriptions.length > 0) {
      await User.findByIdAndUpdate(userId, {
        $pullAll: { pushSubscriptions: staleSubscriptions }
      });
    }
  } catch (error) {
    console.error('Error in sendPushNotificationToUser:', error);
  }
};
