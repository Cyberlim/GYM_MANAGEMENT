import { Response } from 'express';
import Expense from '../models/Expense.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

export const getExpensesByGym = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(200).json([]);
      return;
    }

    const expenses = await Expense.find({ gymId }).sort({ date: -1 });
    res.status(200).json(expenses);
  } catch (error) {
    console.error('Error fetching expenses:', error);
    res.status(500).json({ message: 'Server error fetching expenses' });
  }
};

export const createExpense = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }

    const { title, amount, date, category, status } = req.body;

    const newExpense = new Expense({
      gymId,
      title,
      amount,
      date,
      category,
      status,
    });

    await newExpense.save();
    res.status(201).json(newExpense);
  } catch (error) {
    console.error('Error creating expense:', error);
    res.status(500).json({ message: 'Server error creating expense' });
  }
};

export const updateExpense = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }
    const { title, amount, date, category, status } = req.body;

    const expense = await Expense.findById(id);

    if (!expense || expense.gymId.toString() !== gymId?.toString()) {
      res.status(404).json({ message: 'Expense not found' });
      return;
    }

    const limitDays = expense.status === 'Pending' ? 10 : 2;
    const diffTime = Math.abs(new Date().getTime() - new Date(expense.createdAt).getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > limitDays) {
      res.status(400).json({ message: `Cannot update a record older than ${limitDays} days` });
      return;
    }

    expense.title = title;
    expense.amount = amount;
    expense.date = date;
    expense.category = category;
    expense.status = status;
    
    await expense.save();

    res.status(200).json(expense);
  } catch (error) {
    console.error('Error updating expense:', error);
    res.status(500).json({ message: 'Server error updating expense' });
  }
};

export const deleteExpense = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }

    const expense = await Expense.findById(id);

    if (!expense || expense.gymId.toString() !== gymId?.toString()) {
      res.status(404).json({ message: 'Expense not found' });
      return;
    }

    const limitDays = expense.status === 'Pending' ? 10 : 2;
    const diffTime = Math.abs(new Date().getTime() - new Date(expense.createdAt).getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > limitDays) {
      res.status(400).json({ message: `Cannot delete a record older than ${limitDays} days` });
      return;
    }

    await expense.deleteOne();

    res.status(200).json({ message: 'Expense deleted successfully' });
  } catch (error) {
    console.error('Error deleting expense:', error);
    res.status(500).json({ message: 'Server error deleting expense' });
  }
};
