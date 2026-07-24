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
      userId: (req.user || (req as any).member)._id,
      isRead: true,
      updatedAt: { $lt: oneDayAgo }
    });

    const notifications = await Notification.find({ userId: (req.user || (req as any).member)._id }).sort({ createdAt: -1 }).limit(50);
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
      { _id: id, userId: (req.user || (req as any).member)._id } as any,
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
          userId: (req.user || (req as any).member)._id,
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
    await Notification.updateMany({ userId: (req.user || (req as any).member)._id, isRead: false }, { isRead: true });
    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (error: any) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ message: error.message });
  }
};

import User from '../models/User.model';
import Member from '../models/Member.model';
import Broadcast from '../models/Broadcast.model';
import Gym from '../models/Gym.model';

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

    let userOrMember: any = await User.findById(userId);
    let isMember = false;
    
    if (!userOrMember) {
      userOrMember = await Member.findById(userId);
      isMember = true;
    }

    if (!userOrMember) {
      res.status(404).json({ message: 'User or Member not found' });
      return;
    }

    const existingSubs = userOrMember.pushSubscriptions || [];
    const exists = existingSubs.some((sub: any) => sub.endpoint === subscription.endpoint);

    if (!exists) {
      if (isMember) {
        await Member.findByIdAndUpdate(userId, {
          $push: { pushSubscriptions: subscription }
        });
      } else {
        await User.findByIdAndUpdate(userId, {
          $push: { pushSubscriptions: subscription }
        });
      }
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

    let userOrMember: any = await User.findById(userId);
    let isMember = false;
    
    if (!userOrMember) {
      userOrMember = await Member.findById(userId);
      isMember = true;
    }

    if (!userOrMember) {
      res.status(404).json({ message: 'User or Member not found' });
      return;
    }

    const existingSubs = userOrMember.pushSubscriptions || [];
    const remainingSubs = existingSubs.filter((sub: any) => sub.endpoint !== endpoint);

    if (isMember) {
      await Member.findByIdAndUpdate(userId, {
        pushSubscriptions: remainingSubs
      });
    } else {
      await User.findByIdAndUpdate(userId, {
        pushSubscriptions: remainingSubs
      });
    }

    res.status(200).json({ message: 'Unsubscribed successfully' });
  } catch (error) {
    console.error('Error removing push subscription:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getVapidPublicKey = (req: AuthRequest, res: Response) => {
  res.status(200).json({ publicKey: process.env.VAPID_PUBLIC_KEY });
};

export const sendBroadcastToMembers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await (async () => {
      const gym = await Gym.findOne({ ownerId: (req.user || (req as any).member)._id });
      return gym?._id;
    })();

    if (!gymId) {
      res.status(400).json({ message: 'Gym not found for this user' });
      return;
    }

    const { subject, message, memberIds } = req.body;
    if (!subject || !message) {
      res.status(400).json({ message: 'Subject and message are required' });
      return;
    }

    let query: any = { gymId, status: 'Active' };
    if (memberIds && Array.isArray(memberIds) && memberIds.length > 0) {
      query._id = { $in: memberIds };
    }
    
    const members = await Member.find(query);
    const recipientIds = members.map(m => m._id);

    if (recipientIds.length === 0) {
      res.status(400).json({ message: 'No active members found to broadcast to.' });
      return;
    }

    const broadcast = new Broadcast({ gymId, subject, message, recipients: recipientIds });
    await broadcast.save();

    const notifications = recipientIds.map(userId => ({
      userId,
      title: subject,
      message,
      type: 'broadcast',
      broadcastId: broadcast._id,
      isRead: false
    }));

    await Notification.insertMany(notifications);

    const io = getIO();
    members.forEach(member => {
      io.to(member._id.toString()).emit('new_notification', {
        title: subject,
        message,
        type: 'broadcast',
      });
      
      // push.service hook will not run for insertMany automatically
      // Trigger push manually for each member
      import('../services/push.service').then(({ sendPushNotificationToUser }) => {
        sendPushNotificationToUser(member._id.toString(), {
          title: subject,
          body: message,
          type: 'broadcast'
        }).catch(err => console.error('Push error:', err));
      });
    });

    res.status(201).json({ message: `Broadcast sent to ${recipientIds.length} members.`, broadcast });
  } catch (error: any) {
    console.error('Send Broadcast to Members Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getBroadcasts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await (async () => {
      const gym = await Gym.findOne({ ownerId: (req.user || (req as any).member)._id });
      return gym?._id;
    })();

    if (!gymId) {
      res.status(400).json({ message: 'Gym not found for this user' });
      return;
    }

    const broadcasts = await Broadcast.find({ gymId }).sort({ createdAt: -1 });
    res.status(200).json(broadcasts);
  } catch (error: any) {
    console.error('Get Broadcasts Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getBroadcastDetails = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    const broadcast = await Broadcast.findById(id);
    if (!broadcast) {
      res.status(404).json({ message: 'Broadcast not found' });
      return;
    }

    // Get read receipts by querying the Notifications collection
    const notifications = await Notification.find({ broadcastId: id }).populate({
      path: 'userId',
      model: 'Member',
      select: 'name imageUrl'
    });
    
    const receipts = notifications.map(n => ({
      member: n.userId, // This is the populated member object
      isRead: n.isRead,
      readAt: n.isRead ? n.updatedAt : null
    }));

    res.status(200).json({
      broadcast,
      receipts
    });
  } catch (error: any) {
    console.error('Get Broadcast Details Error:', error);
    res.status(500).json({ message: error.message });
  }
};
