import { Response } from 'express';
import Staff from '../models/Staff.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

// @desc    Get all staff
// @route   GET /api/staff
// @access  Private
export const getStaff = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const staff = await Staff.find({ gymId }).sort({ createdAt: -1 });
    res.json(staff);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add a new staff member
// @route   POST /api/staff
// @access  Private
export const addStaff = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const { name, role, shift, phone, email, dob, imageUrl, idProofUrl } = req.body;
    
    const staff = await Staff.create({
      gymId,
      name,
      role,
      shift,
      phone,
      email,
      dob,
      imageUrl,
      idProofUrl
    });

    res.status(201).json(staff);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a staff member
// @route   PUT /api/staff/:id
// @access  Private
export const updateStaff = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const staff = await Staff.findOne({ _id: req.params.id as string, gymId });

    if (!staff) {
      res.status(404).json({ message: 'Staff member not found' });
      return;
    }

    const updatedStaff = await Staff.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedStaff);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a staff member
// @route   DELETE /api/staff/:id
// @access  Private
export const deleteStaff = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const staff = await Staff.findOne({ _id: req.params.id as string, gymId });

    if (!staff) {
      res.status(404).json({ message: 'Staff member not found' });
      return;
    }

    await staff.deleteOne();
    res.json({ message: 'Staff member removed' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
