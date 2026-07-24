import { Response } from 'express';
import Member from '../models/Member.model';
import Gym from '../models/Gym.model';
import Trainer from '../models/Trainer.model';
import { AuthRequest } from '../middlewares/auth.middleware';
import bcrypt from 'bcryptjs';
import { sendMemberWelcomeEmail } from '../utils/email';

// Helper to get gym ID for the current user
const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

// @desc    Get all members
// @route   GET /api/members
// @access  Private
export const getMembers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const members = await Member.find({ gymId }).sort({ createdAt: -1 });
    res.json(members);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add a new member
// @route   POST /api/members
// @access  Private
export const addMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const { name, email, phone, membershipPlan, status, joinDate, expiryDate, totalCheckIns, imageUrl, dob, address, documentUrl, trainerId } = req.body;

    if (!dob) {
      res.status(400).json({ message: 'Date of Birth is required' });
      return;
    }

    const dobDate = new Date(dob);
    const day = dobDate.getDate().toString().padStart(2, '0');
    const month = (dobDate.getMonth() + 1).toString().padStart(2, '0');
    const year = dobDate.getFullYear();
    const initialPassword = `${day}${month}${year}`;

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(initialPassword, salt);

    const member = await Member.create({
      gymId,
      name,
      email,
      phone,
      membershipPlan,
      status: status || 'Active',
      joinDate: joinDate || new Date(),
      expiryDate,
      totalCheckIns: totalCheckIns || 0,
      imageUrl: imageUrl || '',
      dob,
      address: address || '',
      documentUrl: documentUrl || '',
      trainerId: trainerId || undefined,
      password: hashedPassword,
      isFirstLogin: true,
    });

    if (trainerId) {
      await Trainer.findByIdAndUpdate(trainerId, { $inc: { assignedMembers: 1 } });
    }

    if (email) {
      sendMemberWelcomeEmail(email, name, email, phone || 'N/A', initialPassword).catch((err) => 
        console.error('Failed to send welcome email to member:', err)
      );
    }

    res.status(201).json(member);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a member
// @route   PUT /api/members/:id
// @access  Private
export const updateMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const member = await Member.findOne({ _id: req.params.id as string, gymId });

    if (!member) {
      res.status(404).json({ message: 'Member not found' });
      return;
    }

    const oldTrainerId = member.trainerId?.toString();
    const newTrainerId = req.body.trainerId;

    const updatedMember = await Member.findByIdAndUpdate(req.params.id, req.body, { new: true });

    if (oldTrainerId !== newTrainerId) {
      if (oldTrainerId) {
        await Trainer.findByIdAndUpdate(oldTrainerId, { $inc: { assignedMembers: -1 } });
      }
      if (newTrainerId) {
        await Trainer.findByIdAndUpdate(newTrainerId, { $inc: { assignedMembers: 1 } });
      }
    }

    res.json(updatedMember);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a member
// @route   DELETE /api/members/:id
// @access  Private
export const deleteMember = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const member = await Member.findOne({ _id: req.params.id as string, gymId });

    if (!member) {
      res.status(404).json({ message: 'Member not found' });
      return;
    }

    const trainerId = member.trainerId;

    await member.deleteOne();

    if (trainerId) {
      await Trainer.findByIdAndUpdate(trainerId, { $inc: { assignedMembers: -1 } });
    }

    res.json({ message: 'Member removed' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
