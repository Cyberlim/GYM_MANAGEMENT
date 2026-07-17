import { Response } from 'express';
import Equipment from '../models/Equipment.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

// Helper to get gym ID for the current user
const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

export const createEquipment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);

    const newEquipment = new Equipment({ ...req.body, gymId });
    await newEquipment.save();
    res.status(201).json(newEquipment);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const getEquipment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);

    const equipment = await Equipment.find({ gymId }).sort({ createdAt: -1 });
    res.status(200).json(equipment);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateEquipment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const gymId = await getGymId(req.user._id);

    const updatedEquipment = await Equipment.findOneAndUpdate(
      { _id: id, gymId } as any,
      req.body,
      { new: true, runValidators: true }
    );

    if (!updatedEquipment) {
      res.status(404).json({ message: 'Equipment not found' });
      return;
    }

    res.status(200).json(updatedEquipment);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteEquipment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const gymId = await getGymId(req.user._id);

    const deletedEquipment = await Equipment.findOneAndDelete({ _id: id, gymId } as any);

    if (!deletedEquipment) {
      res.status(404).json({ message: 'Equipment not found' });
      return;
    }

    res.status(200).json({ message: 'Equipment deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
