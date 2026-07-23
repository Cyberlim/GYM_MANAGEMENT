import { Response } from 'express';
import Notification from '../models/Notification.model';
import { AuthRequest } from '../middlewares/auth.middleware';
import { getIO } from '../services/socket';

export const getNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    // Delete read notifications older than 1 day
    const oneDayAgo = new Date();
    oneDayAgo.setDate(oneDayAgo.getDate() - 1);
    await Notification.deleteMany({
      userId: req.user._id,
      isRead: true,
      updatedAt: { $lt: oneDayAgo }
    });

    const notifications = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 }).limit(50);
    res.status(200).json(notifications);
  } catch (error: any) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ message: error.message });
  }
};

export const markAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId: req.user._id } as any,
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      res.status(404).json({ message: 'Notification not found' });
      return;
    }

    if (notification.type === 'broadcast' && notification.broadcastId) {
      try {
        const io = getIO();
        io.to('superadmin_room').emit('broadcast_read', {
          broadcastId: notification.broadcastId,
          userId: req.user._id,
          readAt: notification.updatedAt,
        });
      } catch (err) {
        console.error('Socket error emitting broadcast_read', err);
      }
    }

    res.status(200).json(notification);
  } catch (error: any) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ message: error.message });
  }
};

export const markAllAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await Notification.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (error: any) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ message: error.message });
  }
};

import User from '../models/User.model';

export const subscribeToPush = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const { subscription } = req.body;
    if (!subscription || !subscription.endpoint) {
      res.status(400).json({ message: 'Invalid subscription object' });
      return;
    }

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const existingSubs = user.pushSubscriptions || [];
    const exists = existingSubs.some((sub: any) => sub.endpoint === subscription.endpoint);

    if (!exists) {
      await User.findByIdAndUpdate(userId, {
        $push: { pushSubscriptions: subscription }
      });
    }

    res.status(200).json({ message: 'Subscription saved successfully' });
  } catch (error) {
    console.error('Error saving push subscription:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const unsubscribeFromPush = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const { endpoint } = req.body;
    if (!endpoint) {
      res.status(400).json({ message: 'Endpoint is required' });
      return;
    }

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const existingSubs = user.pushSubscriptions || [];
    const remainingSubs = existingSubs.filter((sub: any) => sub.endpoint !== endpoint);

    await User.findByIdAndUpdate(userId, {
      pushSubscriptions: remainingSubs
    });

    res.status(200).json({ message: 'Unsubscribed successfully' });
  } catch (error) {
    console.error('Error removing push subscription:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getVapidPublicKey = async (req: AuthRequest, res: Response): Promise<void> => {
  res.status(200).json({ publicKey: process.env.VAPID_PUBLIC_KEY || '' });
};
