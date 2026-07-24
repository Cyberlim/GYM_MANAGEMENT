import webpush from 'web-push';
import dotenv from 'dotenv';
import User from '../models/User.model';
import Member from '../models/Member.model';

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
    let userOrMember: any = await User.findById(userId);
    let isMember = false;
    
    if (!userOrMember) {
      userOrMember = await Member.findById(userId);
      isMember = true;
    }

    if (!userOrMember || !userOrMember.pushSubscriptions || userOrMember.pushSubscriptions.length === 0) {
      return;
    }

    // Check if push notifications are enabled in user settings (only applies to Users right now)
    if (!isMember && userOrMember.settings && userOrMember.settings.pushNotifications === false) {
      return;
    }

    // Filter by type if provided and if it's a superadmin (checking settings structure)
    if (!isMember && payload.type && userOrMember.settings) {
      const type = payload.type;
      if (type === 'system' && userOrMember.settings.systemAlerts === false) return;
      if (type === 'registration' && userOrMember.settings.newGymSignups === false) return;
      if (type === 'payment') {
        const titleLower = payload.title.toLowerCase();
        const isFailure = titleLower.includes('fail') || titleLower.includes('error');
        if (isFailure && userOrMember.settings.paymentFailures === false) return;
        if (!isFailure && userOrMember.settings.paymentReceived === false) return;
      }
    }

    const stringifiedPayload = JSON.stringify(payload);
    const staleSubscriptions: any[] = [];

    // Send push to all registered devices for this user
    await Promise.all(
      userOrMember.pushSubscriptions.map(async (sub: any) => {
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
      if (isMember) {
        await Member.findByIdAndUpdate(userId, {
          $pullAll: { pushSubscriptions: staleSubscriptions }
        });
      } else {
        await User.findByIdAndUpdate(userId, {
          $pullAll: { pushSubscriptions: staleSubscriptions }
        });
      }
    }
  } catch (error) {
    console.error('Error in sendPushNotificationToUser:', error);
  }
};
