import { Response } from 'express';
import Plan from '../models/Plan.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

// @desc    Get all plans
// @route   GET /api/plans
// @access  Private
export const getPlans = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const plans = await Plan.find({ gymId }).sort({ createdAt: -1 });
    res.json(plans);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Add a new plan
// @route   POST /api/plans
// @access  Private
export const addPlan = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    
    const plan = await Plan.create({
      gymId,
      ...req.body
    });

    res.status(201).json(plan);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a plan
// @route   PUT /api/plans/:id
// @access  Private
export const updatePlan = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const plan = await Plan.findOne({ _id: req.params.id as string, gymId });

    if (!plan) {
      res.status(404).json({ message: 'Plan not found' });
      return;
    }

    const updatedPlan = await Plan.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updatedPlan);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a plan
// @route   DELETE /api/plans/:id
// @access  Private
export const deletePlan = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const gymId = await getGymId(req.user._id);
    const plan = await Plan.findOne({ _id: req.params.id as string, gymId });

    if (!plan) {
      res.status(404).json({ message: 'Plan not found' });
      return;
    }

    await plan.deleteOne();
    res.json({ message: 'Plan removed' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
