import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import CheckIn from '../models/CheckIn.model';
import Gym from '../models/Gym.model';
import { getIO } from '../services/socket';

const getGymId = async (userId: string) => {
  const gym = await Gym.findOne({ ownerId: userId });
  if (!gym) throw new Error('Gym not found for this user');
  return gym._id;
};

export const getAttendance = async (req: AuthRequest, res: Response) => {
  try {
    const gymId = await getGymId(req.user._id);
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ message: 'Date query parameter is required (YYYY-MM-DD)' });
    }

    const queryDate = new Date(date as string);
    // Remove time components just to be safe
    queryDate.setUTCHours(0, 0, 0, 0);

    const checkIns = await CheckIn.find({
      gymId,
      date: queryDate,
    });

    res.json(checkIns);
  } catch (error) {
    console.error('Error fetching attendance:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

export const markAttendance = async (req: AuthRequest, res: Response) => {
  try {
    const gymId = await getGymId(req.user._id);
    const { personId, role, date, status } = req.body;

    if (!personId || !role || !date || !status) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const queryDate = new Date(date);
    queryDate.setUTCHours(0, 0, 0, 0);

    const checkInTime = status === 'Present' ? new Date() : undefined;

    // Use findOneAndUpdate with upsert to create or update the record for this specific day
    const updatedCheckIn = await CheckIn.findOneAndUpdate(
      { gymId, personId, date: queryDate },
      { 
        $set: {
          role,
          status,
          ...(checkInTime && { checkInTime }) // Only set checkInTime if Present
        },
        $unset: status === 'Absent' ? { checkInTime: "" } : {} // Remove checkInTime if Absent
      },
      { new: true, upsert: true }
    );

    // Emit real-time update
    getIO().to(personId.toString()).emit('attendance_updated', updatedCheckIn);

    res.json(updatedCheckIn);
  } catch (error) {
    console.error('Error marking attendance:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
