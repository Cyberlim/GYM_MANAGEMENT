import { Response } from 'express';
import MemberMessage from '../models/MemberMessage.model';
import { MemberAuthRequest } from '../middlewares/member.auth.middleware';
import { getIO } from '../services/socket';
import Gym from '../models/Gym.model';
import Notification from '../models/Notification.model';

export const getMemberMessages = async (req: MemberAuthRequest, res: Response) => {
  try {
    const memberId = req.member?._id;
    if (!memberId) return res.status(401).json({ message: 'Unauthorized' });

    const messages = await MemberMessage.find({ memberId }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const sendMemberMessage = async (req: MemberAuthRequest, res: Response) => {
  try {
    const memberId = req.member?._id;
    const gymId = req.member?.gymId;
    const { message } = req.body;

    if (!memberId || !gymId) return res.status(401).json({ message: 'Unauthorized' });
    if (!message) return res.status(400).json({ message: 'Message is required' });

    const newMessage = await MemberMessage.create({
      memberId,
      gymId,
      message,
      senderRole: 'member',
    });

    const io = getIO();
    // Emit to member's personal room and the gym owner's room
    io.to(memberId.toString()).emit('new_member_support_message', newMessage);
    io.to(gymId.toString()).emit('new_member_support_message', newMessage);

    // Notify the Gym Owner
    const gym = await Gym.findById(gymId);
    if (gym) {
      await Notification.create({
        userId: gym.ownerId,
        title: 'New Support Message',
        message: `You have a new message from ${req.member?.name || 'a member'}.`,
        type: 'support',
        route: '/support'
      });
    }

    res.status(201).json(newMessage);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const markMemberMessagesAsRead = async (req: MemberAuthRequest, res: Response) => {
  try {
    const memberId = req.member?._id;
    if (!memberId) return res.status(401).json({ message: 'Unauthorized' });

    await MemberMessage.updateMany(
      { memberId, senderRole: 'gym_owner', isRead: false },
      { isRead: true }
    );
    res.json({ message: 'Messages marked as read' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
