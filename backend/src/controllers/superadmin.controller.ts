import { Response } from 'express';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { AuthRequest } from '../middlewares/auth.middleware';
import Gym from '../models/Gym.model';
import User from '../models/User.model';
import Member from '../models/Member.model';
import Trainer from '../models/Trainer.model';
import Staff from '../models/Staff.model';
import SuspensionMessage from '../models/SuspensionMessage.model';
import Payment from '../models/Payment.model';
import Broadcast from '../models/Broadcast.model';
import Notification from '../models/Notification.model';
import { sendSuspensionEmail, sendReactivationEmail } from '../utils/email';
import { getIO } from '../services/socket';

// Utility to check superadmin role
const checkSuperadmin = (req: AuthRequest, res: Response) => {
  if (req.user?.role !== 'superadmin') {
    res.status(403).json({ message: 'Forbidden. Superadmin only.' });
    return false;
  }
  return true;
};

export const getDashboardStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    const totalGyms = await Gym.countDocuments();
    const trialGyms = await Gym.countDocuments({ trialActive: true });
    
    // Gyms with active subscription (not in trial, and plan exists)
    const activeGyms = await Gym.countDocuments({ 
      trialActive: false, 
      subscriptionPlan: { $exists: true, $ne: null } 
    });

    const pendingGyms = await Gym.countDocuments({ 
      trialActive: false, 
      $or: [ { subscriptionPlan: null }, { subscriptionPlan: { $exists: false } } ] 
    });
    
    // We can count suspended users who are gym owners
    const suspendedUsers = await User.countDocuments({ role: 'gym_owner', status: 'suspended' });

    const totalUsers = await User.countDocuments();

    // Fetch recent 5 gyms for the list
    const recentGymDocs = await Gym.find().sort({ createdAt: -1 }).limit(5).populate('ownerId', 'name email');
    const recentGyms = recentGymDocs.map(g => ({
      name: (g.ownerId as any)?.name || g.name,
      plan: g.subscriptionPlan || (g.trialActive ? 'Trial' : 'Pending'),
      status: g.trialActive ? 'Trial' : (g.subscriptionPlan ? 'Active' : 'Pending'),
      date: g.createdAt.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    }));

    // Fetch recent payments for invoices list
    const recentPayments = await Payment.find().sort({ date: -1 }).limit(5).populate('gymId', 'name').lean();
    const recentInvoices = recentPayments.map((p: any) => ({
      id: p._id.toString().substring(0, 8).toUpperCase(),
      gymName: p.gymId?.name || 'Unknown Gym',
      ownerName: 'Gym Owner', // simplified
      amount: p.amount,
      status: p.status,
    }));

    // Generate Activity Feed from recent gyms and payments
    const activities = [];
    for (const g of recentGymDocs) {
      activities.push({
        title: 'New gym added',
        desc: `${(g.ownerId as any)?.name || g.name} registered a gym`,
        time: g.createdAt,
        type: 'gym'
      });
    }
    for (const p of recentPayments) {
      activities.push({
        title: 'Payment received',
        desc: `$${p.amount} from ${(p.gymId as any)?.name || 'Unknown'}`,
        time: p.date,
        type: 'payment'
      });
    }
    
    // Sort descending and format time
    activities.sort((a, b) => new Date(b.time).getTime() - new Date(a.time).getTime());
    const formattedActivities = activities.slice(0, 5).map(a => {
      const diffMs = Date.now() - new Date(a.time).getTime();
      const diffMins = Math.floor(diffMs / 60000);
      const diffHrs = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHrs / 24);
      let timeStr = `${diffMins}m ago`;
      if (diffDays > 0) timeStr = `${diffDays}d ago`;
      else if (diffHrs > 0) timeStr = `${diffHrs}h ago`;
      
      return {
        title: a.title,
        desc: a.desc,
        time: timeStr,
        type: a.type
      };
    });

    // Since we don't track platform subscriptions as payments yet, we estimate MRR from active gyms
    // We assume an average MRR of $149/gym for demo purposes if there are no real subscription records
    const mrr = activeGyms * 149;

    // Calculate plan distribution and signups
    const gymDocs = await Gym.find({}, 'subscriptionPlan createdAt').lean();
    const planDistribution = { basic: 0, pro: 0, enterprise: 0 };
    const signups = [0, 0, 0, 0, 0, 0]; // Last 6 weeks

    const now = Date.now();
    gymDocs.forEach(g => {
      const plan = (g.subscriptionPlan || 'basic').toLowerCase();
      if (plan.includes('pro')) planDistribution.pro++;
      else if (plan.includes('enterprise')) planDistribution.enterprise++;
      else planDistribution.basic++;

      const diffWeeks = Math.floor((now - new Date(g.createdAt).getTime()) / (7 * 24 * 60 * 60 * 1000));
      if (diffWeeks >= 0 && diffWeeks < 6) {
        signups[5 - diffWeeks] = (signups[5 - diffWeeks] || 0) + 1; // 5 is current week
      }
    });

    res.status(200).json({
      totalGyms,
      activeGyms,
      totalUsers,
      mrr,
      revenueTrend: [
        { month: 'Jan', revenue: mrr * 0.5 },
        { month: 'Feb', revenue: mrr * 0.7 },
        { month: 'Mar', revenue: mrr * 0.8 },
        { month: 'Apr', revenue: mrr * 0.9 },
        { month: 'May', revenue: mrr * 0.95 },
        { month: 'Jun', revenue: mrr },
      ],
      gymStatus: {
        active: activeGyms,
        trial: trialGyms,
        suspended: suspendedUsers,
        pending: pendingGyms
      },
      recentGyms,
      recentInvoices,
      activities: formattedActivities,
      planDistribution,
      signups,
      platformHealth: {
        uptime: 99.9,
        warnings: 0,
        errors: 0
      },
      // Provide zeroes/defaults for missing features so UI can display them dynamically
      costs: 0,
      profit: mrr,
      renewals: 0,
    });
  } catch (error: any) {
    console.error('Superadmin Dashboard Stats Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getAllGyms = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    const gyms = await Gym.find().populate('ownerId', 'name email phone createdAt');
    
    const formattedGyms = await Promise.all(gyms.map(async (gym: any) => {
      const owner = gym.ownerId;
      
      const activeMembersCount = await Member.countDocuments({ 
        gymId: gym._id, 
        status: 'Active' 
      });

      return {
        id: gym._id,
        initials: gym.name.substring(0, 2).toUpperCase(),
        gymName: gym.name,
        location: gym.address,
        ownerName: owner?.name || 'Unknown',
        email: owner?.email || 'No email',
        phone: owner?.phone || 'No phone',
        plan: gym.subscriptionPlan || 'Free Trial',
        status: gym.trialActive ? 'Trial' : (gym.subscriptionPlan ? 'Active' : 'Pending'),
        activeMembers: activeMembersCount,
        revenue: '0',
        registeredAt: owner?.createdAt || gym.createdAt,
      };
    }));

    res.status(200).json(formattedGyms);
  } catch (error: any) {
    console.error('Superadmin Get All Gyms Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getGymDetails = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { id } = req.params;

    const gym = await Gym.findById(id).populate('ownerId', 'name email phone createdAt status');
    if (!gym) {
      res.status(404).json({ message: 'Gym not found' });
      return;
    }

    const owner = gym.ownerId as any;
    
    // Fetch related data
    const objectId = new mongoose.Types.ObjectId(id as string);
    const members = await Member.find({ gymId: objectId }).select('name membershipPlan status joinDate expiryDate email').lean();
    const trainers = await Trainer.find({ gymId: objectId }).select('name specialization email status').lean();
    const staff = await Staff.find({ gymId: objectId }).select('name role email status').lean();

    res.status(200).json({
      id: gym._id,
      gymName: gym.name,
      location: gym.address,
      ownerName: owner?.name || 'Unknown',
      email: owner?.email || 'No email',
      phone: owner?.phone || 'No phone',
      userStatus: owner?.status || 'active',
      plan: gym.subscriptionPlan || 'Free Trial',
      status: gym.trialActive ? 'Trial' : (gym.subscriptionPlan ? 'Active' : 'Pending'),
      registeredAt: owner?.createdAt || gym.createdAt,
      stats: {
        totalMembers: members.length,
        monthlyRevenue: '$0', // Implement real revenue logic when available
        growth: '+0%',
      },
      members: members.map(m => ({
        id: m._id,
        name: m.name,
        plan: m.membershipPlan || 'Basic',
        date: m.joinDate ? new Date(m.joinDate).toLocaleDateString() : 'Unknown',
        status: m.status || 'Active'
      })),
      trainers: trainers.map(t => ({
        id: t._id,
        name: t.name,
        role: t.specialization || 'Trainer',
        email: t.email || 'N/A',
        status: (t as any).status || 'Active'
      })),
      staff: staff.map(s => ({
        id: s._id,
        name: s.name,
        role: s.role || 'Staff',
        email: s.email || 'N/A',
        status: (s as any).status || 'Active'
      }))
    });
  } catch (error: any) {
    console.error('Superadmin Get Gym Details Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getFinanceStats = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    const payments = await Payment.find().sort({ date: -1 }).limit(100).populate('gymId', 'name').lean();
    
    const formattedPayments = payments.map((p: any) => ({
      id: p._id.toString().substring(0, 8).toUpperCase(),
      gymName: p.gymId?.name || 'Unknown Gym',
      plan: p.description || 'Basic',
      amount: p.amount,
      date: new Date(p.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
      status: p.status,
      paymentMethod: p.paymentMethod,
      type: 'Subscription',
    }));

    res.status(200).json({
      recentPayments: formattedPayments,
      transactions: formattedPayments,
      invoices: formattedPayments.map(p => ({
        id: p.id,
        gymName: p.gymName,
        ownerName: 'Gym Owner',
        amount: p.amount,
        issueDate: p.date,
        dueDate: p.date,
        status: p.status
      }))
    });
  } catch (error: any) {
    console.error('Superadmin Get Finance Stats Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getPersonDetails = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { role, id } = req.params;

    let person: any = null;
    const objectId = new mongoose.Types.ObjectId(id as string);

    if (role === 'Member') {
      person = await Member.findById(objectId).lean();
    } else if (role === 'Trainer') {
      person = await Trainer.findById(objectId).lean();
    } else {
      person = await Staff.findById(objectId).lean();
    }

    if (!person) {
      res.status(404).json({ message: 'Person not found' });
      return;
    }

    res.status(200).json(person);
  } catch (error: any) {
    console.error('Superadmin Get Person Details Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const suspendGymOwner = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { id } = req.params;

    const gym = await Gym.findById(id).populate('ownerId');
    if (!gym) {
      res.status(404).json({ message: 'Gym not found' });
      return;
    }

    const owner = gym.ownerId as any;
    if (!owner) {
      res.status(404).json({ message: 'Gym owner not found' });
      return;
    }

    const user = await User.findById(owner._id);
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    user.status = 'suspended';
    if (!user.suspensionId) {
      user.suspensionId = 'SUSP-' + Math.random().toString(36).substring(2, 8).toUpperCase();
    }
    await user.save();

    await sendSuspensionEmail(user.email, user.name, user.suspensionId);

    const io = getIO();
    io.to(user._id.toString()).emit('account_suspended', { suspensionId: user.suspensionId });

    // Send an automated support message
    const newMessage = await SuspensionMessage.create({
      suspensionId: user.suspensionId,
      senderRole: 'superadmin',
      senderId: req.user._id,
      message: 'Your account has been suspended. Please use this chat to contact support.',
    });
    io.to(`suspension_${user.suspensionId}`).emit('new_suspension_message', newMessage);

    res.status(200).json({ message: 'Account suspended successfully', suspensionId: user.suspensionId });
  } catch (error: any) {
    console.error('Suspend Gym Owner Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getGymOwnersList = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const gymOwners = await User.find({ role: 'gym_owner' }).select('name email');
    const ownersWithGyms = await Promise.all(gymOwners.map(async (o) => {
      const gym = await Gym.findOne({ ownerId: o._id }).select('name');
      return { id: o._id, ownerName: o.name, gymName: gym?.name || 'No Gym' };
    }));
    res.status(200).json(ownersWithGyms);
  } catch (error: any) {
    console.error('Get Gym Owners List Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const sendBroadcast = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { subject, message, recipientIds } = req.body;
    
    if (!subject || !message || !recipientIds || !Array.isArray(recipientIds)) {
      res.status(400).json({ message: 'Missing subject, message, or recipientIds' });
      return;
    }

    const broadcast = new Broadcast({ subject, message, recipients: recipientIds });
    await broadcast.save();

    const notifications = recipientIds.map(id => ({
      userId: id,
      title: subject,
      message,
      type: 'broadcast',
      broadcastId: broadcast._id,
      isRead: false
    }));

    await Notification.insertMany(notifications);

    const io = getIO();
    recipientIds.forEach(id => {
      io.to(id.toString()).emit('new_notification', {
        title: subject,
        message,
        type: 'broadcast'
      });
    });

    res.status(201).json(broadcast);
  } catch (error: any) {
    console.error('Send Broadcast Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getBroadcastHistory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const broadcasts = await Broadcast.find().sort({ createdAt: -1 });
    res.status(200).json(broadcasts);
  } catch (error: any) {
    console.error('Get Broadcast History Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getBroadcastStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { broadcastId } = req.params;
    
    if (!broadcastId) {
      res.status(400).json({ message: 'Broadcast ID is required' });
      return;
    }

    const notifications = await Notification.find({ broadcastId: broadcastId as string }).populate('userId', 'name');
    const statusList = await Promise.all(notifications.map(async (n) => {
      const user = n.userId as any;
      const gym = await Gym.findOne({ ownerId: user._id }).select('name');
      return {
        userId: user._id,
        ownerName: user.name,
        gymName: gym?.name || 'No Gym',
        isRead: n.isRead
      };
    }));
    
    res.status(200).json(statusList);
  } catch (error: any) {
    console.error('Get Broadcast Status Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const reactivateGymOwner = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { id } = req.params;

    const gym = await Gym.findById(id).populate('ownerId');
    if (!gym) {
      res.status(404).json({ message: 'Gym not found' });
      return;
    }

    const owner = gym.ownerId as any;
    if (!owner) {
      res.status(404).json({ message: 'Gym owner not found' });
      return;
    }

    const user = await User.findById(owner._id);
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    user.status = 'active';
    await user.save();

    await sendReactivationEmail(user.email, user.name);

    const io = getIO();
    // Emit to both user id room and suspension id room for broad coverage
    io.to(user._id.toString()).emit('account_reactivated', { message: 'Your account has been reactivated' });
    if (user.suspensionId) {
      io.to(`suspension_${user.suspensionId}`).emit('account_reactivated', { message: 'Your account has been reactivated' });
      
      // Send an automated support message
      const newMessage = await SuspensionMessage.create({
        suspensionId: user.suspensionId,
        senderRole: 'superadmin',
        senderId: req.user._id, // Assuming req.user is the superadmin who is doing the reactivation
        message: 'Your account has been reactivated successfully.',
      });
      io.to(`suspension_${user.suspensionId}`).emit('new_suspension_message', newMessage);
    }

    res.status(200).json({ message: 'Account reactivated successfully' });
  } catch (error: any) {
    console.error('Reactivate Gym Owner Error:', error);
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get report data for CSV generation
// @route   GET /api/superadmin/reports
// @access  Private (Superadmin)
export const getReportData = async (req: AuthRequest, res: Response) => {
  try {
    if (!checkSuperadmin(req, res)) return;
    const { type, range } = req.query;
    
    let startDate = new Date(0);
    let endDate = new Date();
    const now = new Date();
    
    if (range === 'Last 7 Days') {
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    } else if (range === 'Last 30 Days') {
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    } else if (range === 'This Month') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    } else if (range === 'Last Month') {
      startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      endDate = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
    } else if (range === 'This Year') {
      startDate = new Date(now.getFullYear(), 0, 1);
    }

    const dateFilter = { $gte: startDate, $lte: endDate };

    let reportData: any[] = [];

    if (type === 'Financial Summary' || type === 'Payouts & Settlements') {
      const payments = await Payment.find({ date: dateFilter }).populate('gymId', 'name').sort({ date: -1 }).lean();
      
      reportData = payments.map(p => ({
        Date: new Date(p.date).toLocaleDateString(),
        Gym: (p.gymId as any)?.name || 'Unknown',
        Amount: p.amount,
        Method: p.paymentMethod,
        Status: p.status,
      }));
    } else if (type === 'Gym Growth & Signups' || type === 'Subscription Plan Churn') {
      const gyms = await Gym.find({ createdAt: dateFilter }).sort({ createdAt: -1 }).lean();
      
      reportData = gyms.map(g => ({
        Date: new Date(g.createdAt).toLocaleDateString(),
        Name: g.name,
        Status: g.trialActive ? 'Trial' : 'Active',
        Plan: g.subscriptionPlan || 'Basic',
        Contact: g.contactPhone || 'N/A',
      }));
    } else {
      reportData = [{ message: 'Unknown report type' }];
    }

    res.status(200).json(reportData);
  } catch (error: any) {
    console.error('Error generating report:', error);
    res.status(500).json({ message: error.message });
  }
};

// ==========================================
// Settings & Notifications Management
// ==========================================

export const updateSettings = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { systemAlerts, newGymSignups, paymentReceived, paymentFailures } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    user.settings = {
      ...user.settings,
      systemAlerts: systemAlerts ?? user.settings?.systemAlerts ?? true,
      newGymSignups: newGymSignups ?? user.settings?.newGymSignups ?? true,
      paymentReceived: paymentReceived ?? user.settings?.paymentReceived ?? true,
      paymentFailures: paymentFailures ?? user.settings?.paymentFailures ?? true,
      emailNotifications: user.settings?.emailNotifications ?? true,
      pushNotifications: user.settings?.pushNotifications ?? true,
      twoFactorEnabled: user.settings?.twoFactorEnabled ?? false,
    };

    await user.save();
    res.status(200).json(user.settings);
  } catch (error: any) {
    console.error('Error updating settings:', error);
    res.status(500).json({ message: error.message });
  }
};

// --- Notification Dispatch Helper ---
const dispatchNotificationToSuperadmins = async (
  type: 'registration' | 'payment' | 'system' | 'support',
  title: string,
  message: string,
  route: string,
  settingKey: 'systemAlerts' | 'newGymSignups' | 'paymentReceived' | 'paymentFailures'
) => {
  const superadmins = await User.find({ role: 'superadmin' });
  const io = require('../services/socket').getIO();

  for (const admin of superadmins) {
    // Check if this admin has the relevant notification setting enabled
    const settings = admin.settings as any;
    if (settings && settings[settingKey] === true) {
      // 1. Save to DB
      const Notification = require('../models/Notification.model').default;
      const notif = await Notification.create({
        userId: admin._id,
        title,
        message,
        type,
        route,
      });

      // 2. Emit via Socket
      io.to('superadmin').emit('notification', notif);
    }
  }
};

export const simulatePaymentReceived = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await dispatchNotificationToSuperadmins(
      'payment',
      'Payment Received',
      'Received $299 from Gold Gym for Pro Plan.',
      '/finance',
      'paymentReceived'
    );
    res.status(200).json({ message: 'Payment notification dispatched if enabled.' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const simulatePaymentFailed = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await dispatchNotificationToSuperadmins(
      'payment',
      'Payment Failed',
      'Subscription renewal failed for Iron Fitness.',
      '/finance',
      'paymentFailures'
    );
    res.status(200).json({ message: 'Payment failure notification dispatched if enabled.' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const simulateSystemAlert = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await dispatchNotificationToSuperadmins(
      'system',
      'System Update',
      'Server health check completed successfully.',
      '/settings',
      'systemAlerts'
    );
    res.status(200).json({ message: 'System alert dispatched if enabled.' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// --- Admins Management ---

export const getAdmins = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    // Get all users with role superadmin
    const admins = await User.find({ role: 'superadmin' }).select('-password');
    res.json(admins);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const createAdmin = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    // Only master admin (no createdBy) can create admins
    if (req.user?.createdBy) {
      res.status(403).json({ message: 'Forbidden. Only the master admin can add sub-admins.' });
      return;
    }

    const { name, email, password } = req.body;
    
    const existing = await User.findOne({ email });
    if (existing) {
      res.status(400).json({ message: 'User with this email already exists' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newAdmin = await User.create({
      name,
      email,
      password: hashedPassword,
      role: 'superadmin',
      isEmailVerified: true,
      createdBy: req.user._id,
    });

    res.status(201).json({ message: 'Admin created successfully', admin: { _id: newAdmin._id, name: newAdmin.name, email: newAdmin.email } });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const revokeAdmin = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!checkSuperadmin(req, res)) return;

    const { id } = req.params;

    const adminToRevoke = await User.findById(id);
    if (!adminToRevoke) {
      res.status(404).json({ message: 'Admin not found' });
      return;
    }

    if (adminToRevoke.role !== 'superadmin') {
      res.status(400).json({ message: 'User is not an admin' });
      return;
    }

    // Only master admin can revoke
    if (req.user?.createdBy) {
      res.status(403).json({ message: 'Forbidden. Only the master admin can revoke admins.' });
      return;
    }

    // Cannot revoke oneself
    if (req.user?._id.toString() === adminToRevoke._id.toString()) {
      res.status(400).json({ message: 'Cannot revoke your own account' });
      return;
    }

    await User.findByIdAndDelete(id);
    res.json({ message: 'Admin access revoked' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
