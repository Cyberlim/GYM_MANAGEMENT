import { Response } from 'express';
import Trainer from '../models/Trainer.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

// @desc    Get all trainers
// @route   GET /api/trainers
// @access  Private
export const getTrainers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const trainers = await Trainer.find({ gymId }).sort({ createdAt: -1 });
    res.json(trainers);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add a new trainer
// @route   POST /api/trainers
// @access  Private
export const addTrainer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const { name, specialization, assignedMembers, rating, dob, imageUrl, email, phone, experienceYears, about, certificates } = req.body;
    
    const trainer = await Trainer.create({
      gymId,
      name,
      specialization,
      assignedMembers,
      rating,
      dob,
      imageUrl,
      email,
      phone,
      experienceYears,
      about,
      certificates
    });

    res.status(201).json(trainer);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a trainer
// @route   PUT /api/trainers/:id
// @access  Private
export const updateTrainer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const trainer = await Trainer.findOne({ _id: req.params.id as string, gymId });

    if (!trainer) {
      res.status(404).json({ message: 'Trainer not found' });
      return;
    }

    const updatedTrainer = await Trainer.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedTrainer);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a trainer
// @route   DELETE /api/trainers/:id
// @access  Private
export const deleteTrainer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const trainer = await Trainer.findOne({ _id: req.params.id as string, gymId });

    if (!trainer) {
      res.status(404).json({ message: 'Trainer not found' });
      return;
    }

    await trainer.deleteOne();
    res.json({ message: 'Trainer removed' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
