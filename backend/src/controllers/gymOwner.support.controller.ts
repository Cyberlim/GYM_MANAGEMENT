import { Response } from 'express';
import MemberMessage from '../models/MemberMessage.model';
import { AuthRequest } from '../middlewares/auth.middleware';
import { getIO } from '../services/socket';
import Member from '../models/Member.model';
import Gym from '../models/Gym.model';

export const getMembersWithMessages = async (req: AuthRequest, res: Response) => {
  try {
    const ownerId = req.user?._id;
    if (!ownerId) return res.status(401).json({ message: 'Unauthorized' });

    const gym = await Gym.findOne({ ownerId });
    if (!gym) return res.status(404).json({ message: 'Gym not found' });
    const gymId = gym._id;

    // Find all distinct members who have messages with this gym owner
    const memberIds = await MemberMessage.distinct('memberId', { gymId });
    const members = await Member.find({ _id: { $in: memberIds } }).select('name email imageUrl status');
    
    res.json(members);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const getGymOwnerMemberMessages = async (req: AuthRequest, res: Response) => {
  try {
    const ownerId = req.user?._id;
    const memberId = req.params.memberId as string;
    if (!ownerId) return res.status(401).json({ message: 'Unauthorized' });

    const gym = await Gym.findOne({ ownerId });
    if (!gym) return res.status(404).json({ message: 'Gym not found' });
    const gymId = gym._id;

    const messages = await MemberMessage.find({ gymId, memberId }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const sendGymOwnerMemberMessage = async (req: AuthRequest, res: Response) => {
  try {
    const ownerId = req.user?._id;
    const memberId = req.params.memberId as string;
    const { message } = req.body;

    if (!ownerId) return res.status(401).json({ message: 'Unauthorized' });
    
    const gym = await Gym.findOne({ ownerId });
    if (!gym) return res.status(404).json({ message: 'Gym not found' });
    const gymId = gym._id;

    if (!memberId) return res.status(400).json({ message: 'Member ID is required' });
    if (!message) return res.status(400).json({ message: 'Message is required' });

    const newMessage = await MemberMessage.create({
      memberId,
      gymId,
      message,
      senderRole: 'gym_owner',
    });

    const io = getIO();
    // Emit to member's personal room and the gym owner's room
    io.to(memberId.toString()).emit('new_member_support_message', newMessage);
    io.to(gymId.toString()).emit('new_member_support_message', newMessage);

    res.status(201).json(newMessage);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const markGymOwnerMemberMessagesAsRead = async (req: AuthRequest, res: Response) => {
  try {
    const ownerId = req.user?._id;
    const memberId = req.params.memberId as string;
    if (!ownerId) return res.status(401).json({ message: 'Unauthorized' });

    const gym = await Gym.findOne({ ownerId });
    if (!gym) return res.status(404).json({ message: 'Gym not found' });
    const gymId = gym._id;

    await MemberMessage.updateMany(
      { gymId, memberId, senderRole: 'member', isRead: false },
      { isRead: true }
    );
    res.json({ message: 'Messages marked as read' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
