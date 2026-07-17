import { Response } from 'express';
import Payment from '../models/Payment.model';
import Gym from '../models/Gym.model';
import { AuthRequest } from '../middlewares/auth.middleware';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

export const getPaymentsByGym = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(200).json([]);
      return;
    }

    const payments = await Payment.find({ gymId }).sort({ date: -1 });
    res.status(200).json(payments);
  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).json({ message: 'Server error fetching payments' });
  }
};

export const createPayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }

    const { memberId, amount, currency, date, paymentMethod, status, description } = req.body;

    const newPayment = new Payment({
      gymId,
      memberId,
      amount,
      currency,
      date,
      paymentMethod,
      status,
      description,
    });

    await newPayment.save();
    res.status(201).json(newPayment);
  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({ message: 'Server error creating payment' });
  }
};

export const updatePaymentStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const gymId = await getGymId(req.user!._id);

    const payment = await Payment.findById(id);

    if (!payment || payment.gymId.toString() !== gymId?.toString()) {
      res.status(404).json({ message: 'Payment not found' });
      return;
    }

    const limitDays = payment.status === 'Pending' ? 10 : 2;
    const diffTime = Math.abs(new Date().getTime() - new Date(payment.createdAt).getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > limitDays) {
      res.status(400).json({ message: `Cannot update a record older than ${limitDays} days` });
      return;
    }

    payment.status = status;
    await payment.save();

    res.status(200).json(payment);
  } catch (error) {
    console.error('Error updating payment status:', error);
    res.status(500).json({ message: 'Server error updating payment status' });
  }
};

export const updatePayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }
    const { amount, date, paymentMethod, status } = req.body;

    const payment = await Payment.findById(id);

    if (!payment || payment.gymId.toString() !== gymId?.toString()) {
      res.status(404).json({ message: 'Payment not found' });
      return;
    }

    const limitDays = payment.status === 'Pending' ? 10 : 2;
    const diffTime = Math.abs(new Date().getTime() - new Date(payment.createdAt).getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > limitDays) {
      res.status(400).json({ message: `Cannot update a record older than ${limitDays} days` });
      return;
    }

    if (amount !== undefined) payment.amount = amount;
    if (date !== undefined) payment.date = date;
    if (paymentMethod !== undefined) payment.paymentMethod = paymentMethod;
    if (status !== undefined) payment.status = status;
    
    await payment.save();

    res.status(200).json(payment);
  } catch (error) {
    console.error('Error updating payment:', error);
    res.status(500).json({ message: 'Server error updating payment' });
  }
};

export const deletePayment = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    let gymId;
    try {
      gymId = await getGymId(req.user!._id);
    } catch (e) {
      res.status(403).json({ message: 'Gym ID not found for this user' });
      return;
    }

    const payment = await Payment.findById(id);

    if (!payment || payment.gymId.toString() !== gymId?.toString()) {
      res.status(404).json({ message: 'Payment not found' });
      return;
    }

    const limitDays = payment.status === 'Pending' ? 10 : 2;
    const diffTime = Math.abs(new Date().getTime() - new Date(payment.createdAt).getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays > limitDays) {
      res.status(400).json({ message: `Cannot delete a record older than ${limitDays} days` });
      return;
    }

    await payment.deleteOne();

    res.status(200).json({ message: 'Payment deleted successfully' });
  } catch (error) {
    console.error('Error deleting payment:', error);
    res.status(500).json({ message: 'Server error deleting payment' });
  }
};
