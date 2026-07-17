import { Request, Response } from 'express';
import SuspensionMessage from '../models/SuspensionMessage.model';
import User from '../models/User.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';
import { getIO } from '../services/socket';

export const getSuspensionMessagesPublic = async (req: Request, res: Response): Promise<void> => {
  try {
    const suspensionId = req.params.suspensionId as string;
    const messages = await SuspensionMessage.find({ suspensionId }).sort({ createdAt: 1 });
    res.status(200).json(messages);
  } catch (error: any) {
    console.error('Get Suspension Messages Public Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const sendSuspensionMessagePublic = async (req: Request, res: Response): Promise<void> => {
  try {
    const suspensionId = req.params.suspensionId as string;
    const { message } = req.body;

    if (!message) {
      res.status(400).json({ message: 'Message is required' });
      return;
    }

    const user = await User.findOne({ suspensionId });
    if (!user) {
      res.status(404).json({ message: 'Suspended user not found' });
      return;
    }

    const newMessage = await SuspensionMessage.create({
      suspensionId,
      senderRole: user.role,
      senderId: user._id,
      message
    });

    const io = getIO();
    io.to(`suspension_${suspensionId}`).emit('new_suspension_message', newMessage);

    res.status(201).json(newMessage);
  } catch (error: any) {
    console.error('Send Suspension Message Public Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getSuspensionMessages = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const suspensionId = req.params.suspensionId as string;

    // Optional: Verify permission. 
    // Superadmin can view any. Gym Owner must be the owner of the suspensionId.
    if (req.user?.role !== 'superadmin' && req.user?.suspensionId !== suspensionId) {
      res.status(403).json({ message: 'Forbidden' });
      return;
    }

    const messages = await SuspensionMessage.find({ suspensionId }).sort({ createdAt: 1 });
    res.status(200).json(messages);
  } catch (error: any) {
    console.error('Get Suspension Messages Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const sendSuspensionMessage = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const suspensionId = req.params.suspensionId as string;
    const { message } = req.body;

    if (!message) {
      res.status(400).json({ message: 'Message is required' });
      return;
    }

    if (req.user?.role !== 'superadmin' && req.user?.suspensionId !== suspensionId) {
      res.status(403).json({ message: 'Forbidden' });
      return;
    }

    const newMessage = await SuspensionMessage.create({
      suspensionId,
      senderRole: req.user.role,
      senderId: req.user._id,
      message
    });

    const io = getIO();
    // Emit to superadmins and the specific gym owner
    io.to(`suspension_${suspensionId}`).emit('new_suspension_message', newMessage);

    res.status(201).json(newMessage);
  } catch (error: any) {
    console.error('Send Suspension Message Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getAllSuspensions = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'superadmin') {
      res.status(403).json({ message: 'Forbidden' });
      return;
    }
    
    // Find all users who have a suspension chat history
    const suspendedUsers = await User.find({ suspensionId: { $exists: true, $ne: null } }).select('name email suspensionId updatedAt profileImage status');
    
    const usersWithGyms = await Promise.all(suspendedUsers.map(async (u) => {
       const gym = await Gym.findOne({ ownerId: u._id }).select('_id name');
       return {
         ...u.toObject(),
         gymId: gym?._id,
         gymName: gym?.name || 'No Gym'
       };
    }));
    
    res.status(200).json(usersWithGyms);
  } catch (error: any) {
    console.error('Get All Suspensions Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const clearSuspensionMessages = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (req.user?.role !== 'superadmin') {
      res.status(403).json({ message: 'Forbidden' });
      return;
    }
    
    const suspensionId = req.params.suspensionId as string;
    await SuspensionMessage.deleteMany({ suspensionId });
    
    res.status(200).json({ message: 'Messages cleared' });
  } catch (error: any) {
    console.error('Clear Suspension Messages Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const markMessagesAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const suspensionId = req.params.suspensionId as string;
    
    // We only want to mark messages from the other party as read.
    // If superadmin, mark gym_owner messages as read.
    const senderRoleToMark = req.user?.role === 'superadmin' ? 'gym_owner' : 'superadmin';

    await SuspensionMessage.updateMany(
      { suspensionId, senderRole: senderRoleToMark, isRead: false },
      { isRead: true }
    );
    
    res.status(200).json({ message: 'Messages marked as read' });
  } catch (error: any) {
    console.error('Mark Messages As Read Error:', error);
    res.status(500).json({ message: error.message });
  }
};
