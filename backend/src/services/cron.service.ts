import cron from 'node-cron';
import Member from '../models/Member.model';
import Notification from '../models/Notification.model';
import { getIO } from './socket';
import { sendPushNotificationToUser } from './push.service';

// Run every day at 08:00 AM
export const initCronJobs = () => {
  cron.schedule('0 8 * * *', async () => {
    console.log('Running daily cron job for plan expiry alerts...');
    try {
      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);

      const inTwoDays = new Date(today);
      inTwoDays.setDate(today.getDate() + 2);

      // Find members expiring exactly in 2 days
      const expiringSoon = await Member.find({
        status: 'Active',
        expiryDate: {
          $gte: inTwoDays,
          $lt: new Date(inTwoDays.getTime() + 24 * 60 * 60 * 1000)
        }
      });

      // Find members expiring today
      const expiringToday = await Member.find({
        status: 'Active',
        expiryDate: {
          $gte: today,
          $lt: new Date(today.getTime() + 24 * 60 * 60 * 1000)
        }
      });

      const notifyMembers = async (members: any[], message: string) => {
        if (members.length === 0) return;

        const notifications = members.map(m => ({
          userId: m._id,
          title: 'Plan Expiration Alert',
          message: message,
          type: 'system',
          isRead: false
        }));

        await Notification.insertMany(notifications);

        const io = getIO();
        members.forEach(member => {
          const payload = { title: 'Plan Expiration Alert', body: message, type: 'system' };
          
          // Socket
          io.to(member._id.toString()).emit('new_notification', payload);
          
          // Push
          sendPushNotificationToUser(member._id.toString(), payload).catch(err => console.error(err));
        });
      };

      await notifyMembers(expiringSoon, 'Your gym membership will expire in 2 days. Please renew to continue.');
      await notifyMembers(expiringToday, 'Your gym membership expires today! Please renew to avoid interruption.');

    } catch (error) {
      console.error('Error in cron job:', error);
    }
  });
};
