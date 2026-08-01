import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import Gym from '../models/Gym.model';
import Member from '../models/Member.model';
import Trainer from '../models/Trainer.model';
import Staff from '../models/Staff.model';
import Payment from '../models/Payment.model';
import CheckIn from '../models/CheckIn.model';

export const getDashboardStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const gym = await Gym.findOne({ ownerId: userId });
    if (!gym) {
      res.status(404).json({ message: 'Gym not found' });
      return;
    }

    const gymId = gym._id;

    // Stat Cards
    const totalMembers = await Member.countDocuments({ gymId });
    const activeMembers = await Member.countDocuments({ gymId, status: 'Active' });
    const totalTrainers = await Trainer.countDocuments({ gymId });
    
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    const endOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0);

    const monthlyPayments = await Payment.aggregate([
      { $match: { gymId, status: 'Completed', date: { $gte: startOfMonth, $lte: endOfMonth } } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    const monthlyRevenue = monthlyPayments.length > 0 ? monthlyPayments[0].total : 0;

    // Revenue Trend & Member Growth (Last 6 months)
    const revenueTrend = [];
    const memberGrowth = [];
    for (let i = 5; i >= 0; i--) {
      const start = new Date(new Date().getFullYear(), new Date().getMonth() - i, 1);
      const end = new Date(new Date().getFullYear(), new Date().getMonth() - i + 1, 0);
      const monthName = start.toLocaleString('default', { month: 'short' });

      // Revenue
      const rev = await Payment.aggregate([
        { $match: { gymId, status: 'Completed', date: { $gte: start, $lte: end } } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]);
      revenueTrend.push({ month: monthName, revenue: rev.length > 0 ? rev[0].total : 0 });

      // Members
      const newMembers = await Member.countDocuments({ gymId, joinDate: { $gte: start, $lte: end } });
      memberGrowth.push({ month: monthName, newMembers });
    }

    // Lists
    const recentMembers = await Member.find({ gymId })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('name joinDate status imageUrl');

    const upcomingRenewals = await Member.find({ gymId, expiryDate: { $gte: new Date() } })
      .sort({ expiryDate: 1 })
      .limit(5)
      .select('name expiryDate membershipPlan');

    const recentTransactions = await Payment.find({ gymId })
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('memberId', 'name')
      .select('amount date status description memberId');

    // Attendance Stats
    const totalStaff = await Staff.countDocuments({ gymId });

    const today = new Date();
    const todayUtc = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()));
    const yesterdayUtc = new Date(todayUtc);
    yesterdayUtc.setUTCDate(todayUtc.getUTCDate() - 1);
    const startOfWeekUtc = new Date(todayUtc);
    startOfWeekUtc.setUTCDate(todayUtc.getUTCDate() - todayUtc.getUTCDay());

    const [todayCheckins, yesterdayCheckins, thisWeekCheckins] = await Promise.all([
      CheckIn.aggregate([ { $match: { gymId, date: todayUtc, status: { $in: ['Present', 'Late'] } } }, { $group: { _id: '$role', count: { $sum: 1 }, late: { $sum: { $cond: [{ $eq: ['$status', 'Late'] }, 1, 0] } } } } ]),
      CheckIn.aggregate([ { $match: { gymId, date: yesterdayUtc, status: { $in: ['Present', 'Late'] } } }, { $group: { _id: '$role', count: { $sum: 1 }, late: { $sum: { $cond: [{ $eq: ['$status', 'Late'] }, 1, 0] } } } } ]),
      CheckIn.aggregate([ { $match: { gymId, date: { $gte: startOfWeekUtc }, status: { $in: ['Present', 'Late'] } } }, { $group: { _id: '$role', count: { $sum: 1 }, late: { $sum: { $cond: [{ $eq: ['$status', 'Late'] }, 1, 0] } } } } ])
    ]);

    const buildStatsForRole = (role: string, total: number) => {
      const todayStats = todayCheckins.find((c: any) => c._id === role) || { count: 0, late: 0 };
      const yesterdayStats = yesterdayCheckins.find((c: any) => c._id === role) || { count: 0, late: 0 };
      const thisWeekStats = thisWeekCheckins.find((c: any) => c._id === role) || { count: 0, late: 0 };

      return {
        Today: { present: todayStats.count, total, late: todayStats.late },
        Yesterday: { present: yesterdayStats.count, total, late: yesterdayStats.late },
        'This Week': { present: thisWeekStats.count, total, late: thisWeekStats.late }
      };
    };

    const attendanceStats = {
      Member: buildStatsForRole('Member', activeMembers),
      Staff: buildStatsForRole('Staff', totalStaff),
      Trainer: buildStatsForRole('Trainer', totalTrainers)
    };

    res.status(200).json({
      totalMembers,
      activeMembers,
      totalTrainers,
      monthlyRevenue,
      revenueTrend,
      memberGrowth,
      recentMembers,
      upcomingRenewals,
      recentTransactions,
      attendanceStats
    });

  } catch (error: any) {
    console.error('Get Dashboard Stats Error:', error);
    res.status(500).json({ message: error.message });
  }
};
