import { Response } from 'express';
import Inventory from '../models/Inventory.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

// Helper to get gym ID for the current user
const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

export const createInventory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);

    const newInventory = new Inventory({ ...req.body, gymId });
    await newInventory.save();
    res.status(201).json(newInventory);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const getInventory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);

    const inventory = await Inventory.find({ gymId }).sort({ createdAt: -1 });
    res.status(200).json(inventory);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const updateInventory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const gymId = await getGymId(req.user._id);

    const updatedInventory = await Inventory.findOneAndUpdate(
      { _id: id, gymId } as any,
      req.body,
      { new: true, runValidators: true }
    );

    if (!updatedInventory) {
      res.status(404).json({ message: 'Inventory item not found' });
      return;
    }

    res.status(200).json(updatedInventory);
  } catch (error: any) {
    res.status(400).json({ message: error.message });
  }
};

export const deleteInventory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const gymId = await getGymId(req.user._id);

    const deletedInventory = await Inventory.findOneAndDelete({ _id: id, gymId } as any);

    if (!deletedInventory) {
      res.status(404).json({ message: 'Inventory item not found' });
      return;
    }

    res.status(200).json({ message: 'Inventory item deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
