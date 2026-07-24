import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Member from '../models/Member.model';
import Payment from '../models/Payment.model';
import Plan from '../models/Plan.model';
import CheckIn from '../models/CheckIn.model';
import { MemberAuthRequest } from '../middlewares/member.auth.middleware';
import { getIO } from '../services/socket';
import { sendPasswordResetOTP } from '../utils/email';

const generateToken = (id: string) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'super_secret_fallback', {
    expiresIn: '30d',
  });
};

// @desc    Member Login
// @route   POST /api/member-app/login
// @access  Public
export const login = async (req: Request, res: Response) => {
  try {
    const { loginId, password } = req.body; // loginId can be email or phone
    
    // Find member by email or phone
    const member = await Member.findOne({ 
      $or: [{ email: loginId }, { phone: loginId }] 
    }).populate('gymId');

    if (!member) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (!member.password) {
       return res.status(401).json({ message: 'Password not set for this account. Contact your Gym Owner.' });
    }

    const isMatch = await bcrypt.compare(password, member.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    res.json({
      _id: member._id,
      name: member.name,
      email: member.email,
      phone: member.phone,
      isFirstLogin: member.isFirstLogin,
      gym: member.gymId,
      token: generateToken(member._id.toString()),
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Change Password (Forced on first login or manual)
// @route   POST /api/member-app/change-password
// @access  Private
export const changePassword = async (req: MemberAuthRequest, res: Response) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const memberId = req.member._id;

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const member = await Member.findById(memberId);
    if (!member) {
      return res.status(404).json({ message: 'Member not found' });
    }

    if (!currentPassword) {
      return res.status(400).json({ message: 'Current password is required' });
    }
    if (!member.password) {
      return res.status(400).json({ message: 'No password is set for this account. Please log out and use Forgot Password.' });
    }
    const isMatch = await bcrypt.compare(currentPassword, member.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid current password' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    member.password = hashedPassword;
    member.isFirstLogin = false;
    await member.save();

    res.json({ message: 'Password updated successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get Member Profile
// @route   GET /api/member-app/profile
// @access  Private
export const getProfile = async (req: MemberAuthRequest, res: Response) => {
  try {
    const member = await Member.findById(req.member._id).select('-password').populate('gymId').populate('trainerId');
    if (!member) {
      return res.status(404).json({ message: 'Member not found' });
    }
    res.json(member);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get Member Attendance
// @route   GET /api/member-app/attendance
// @access  Private
export const getAttendance = async (req: MemberAuthRequest, res: Response) => {
  try {
    const checkIns = await CheckIn.find({ personId: req.member._id }).sort({ checkInTime: -1 });
    res.json(checkIns);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get Available Plans for Gym
// @route   GET /api/member-app/plans
// @access  Private
export const getPlans = async (req: MemberAuthRequest, res: Response) => {
  try {
    const gymId = req.member.gymId;
    const plans = await Plan.find({ gymId });
    res.json(plans);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Purchase / Renew Plan (Mock Payment)
// @route   POST /api/member-app/purchase-plan
// @access  Private
export const purchasePlan = async (req: MemberAuthRequest, res: Response) => {
  try {
    const { planId } = req.body;
    const plan = await Plan.findById(planId);

    if (!plan) {
      return res.status(404).json({ message: 'Plan not found' });
    }

    // Calculate new expiry date based on plan duration
    // Parse duration like "1 Month", "6 Months", "1 Year", "Quarterly"
    let durationMonths = 1;
    const durStr = plan.duration.toLowerCase().trim();
    if (durStr.includes('year')) {
      durationMonths = (parseInt(durStr) || 1) * 12;
    } else if (durStr.includes('month')) {
      durationMonths = parseInt(durStr) || 1;
    } else if (durStr.includes('quarter')) {
      durationMonths = 3;
    } else {
      durationMonths = parseInt(durStr) || 1; // Fallback
    }

    const member = await Member.findById(req.member._id);
    if (!member) {
      return res.status(404).json({ message: 'Member not found' });
    }

    let baseDate = new Date();
    // If the member's current expiry date is in the future, add the new duration to it.
    if (member.expiryDate && member.expiryDate > new Date()) {
      baseDate = new Date(member.expiryDate);
    }
    baseDate.setMonth(baseDate.getMonth() + durationMonths);

    member.membershipPlan = plan.name;
    member.status = 'Active';
    member.expiryDate = baseDate;
    await member.save();

    // Create Payment Record
    const payment = await Payment.create({
      gymId: member.gymId,
      memberId: member._id,
      amount: plan.discountPrice && plan.discountPrice > 0 ? plan.discountPrice : plan.price,
      currency: plan.currencySymbol || '₹',
      paymentMethod: 'Card',
      status: 'Completed',
      description: `Purchased ${plan.name} plan`,
    });

    const updatedMember = await Member.findById(member._id).select('-password');

    // Emit real-time events to the Gym Owner
    try {
      const io = getIO();
      // Emitting to the room named after the gymId
      io.to(member.gymId.toString()).emit('member_updated', updatedMember);
      io.to(member.gymId.toString()).emit('new_payment', payment);
    } catch (socketErr) {
      console.error('Socket error on purchasePlan:', socketErr);
    }

    res.json({ message: 'Plan purchased successfully', member: updatedMember });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Forgot Password - Send OTP
// @route   POST /api/member-app/forgot-password
// @access  Public
export const forgotPassword = async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const member = await Member.findOne({ email });
    if (!member) {
      // Return 200 to prevent email enumeration attacks
      return res.json({ message: 'If an account with that email exists, an OTP has been sent.' });
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Set OTP and expiration (10 minutes)
    member.resetPasswordOtp = otp;
    member.resetPasswordExpires = new Date(Date.now() + 10 * 60 * 1000);
    await member.save();

    await sendPasswordResetOTP(member.email, otp);

    res.json({ message: 'If an account with that email exists, an OTP has been sent.' });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Error sending OTP' });
  }
};

// @desc    Verify OTP and Reset Password
// @route   POST /api/member-app/reset-password
// @access  Public
export const verifyOtpAndResetPassword = async (req: Request, res: Response) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: 'Email, OTP, and new password are required' });
    }

    const member = await Member.findOne({
      email,
      resetPasswordOtp: otp,
      resetPasswordExpires: { $gt: new Date() }
    });

    if (!member) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }

    // Hash the new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update member
    member.password = hashedPassword;
    member.isFirstLogin = false;
    member.resetPasswordOtp = undefined as any;
    member.resetPasswordExpires = undefined as any;
    await member.save();

    res.json({ message: 'Password has been reset successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Error resetting password' });
  }
};
