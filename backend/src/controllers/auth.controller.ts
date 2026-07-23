import { Request, Response } from 'express';
import User from '../models/User.model';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import Gym from '../models/Gym.model';
import Session from '../models/Session.model';
import { AuthRequest } from '../middlewares/auth.middleware';
import speakeasy from 'speakeasy';
import qrcode from 'qrcode';
import fs from 'fs';
import path from 'path';
import { sendOTP, sendVerificationEmail, sendWelcomeEmail, sendPasswordResetEmail } from '../utils/email';

const generateToken = (id: string) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'super_secret_fallback', {
    expiresIn: '30d',
  });
};

export const getMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }
    const gym = await Gym.findOne({ ownerId: user._id });
    res.status(200).json({ user, gym });
  } catch (error: any) {
    console.error('Get Me Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const requestPasswordReset = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;
    if (!email) {
      res.status(400).json({ message: 'Please provide an email address' });
      return;
    }

    const user = await User.findOne({ email });
    if (!user || user.authProvider !== 'local') {
      res.status(404).json({ message: 'User not found or uses social login' });
      return;
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.passwordResetCode = await bcrypt.hash(otp, 10);
    user.passwordResetExpires = new Date(Date.now() + 15 * 60000); // 15 mins
    await user.save();

    await sendPasswordResetEmail(user.email, otp);

    res.status(200).json({ message: 'Password reset code sent to your email.' });
  } catch (error: any) {
    console.error('Request Password Reset Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      res.status(400).json({ message: 'Please provide email, code, and new password' });
      return;
    }

    const user = await User.findOne({ email });
    if (!user || user.authProvider !== 'local') {
      res.status(404).json({ message: 'User not found or uses social login' });
      return;
    }

    if (!user.passwordResetCode || !user.passwordResetExpires) {
      res.status(400).json({ message: 'No password reset requested' });
      return;
    }

    if (user.passwordResetExpires < new Date()) {
      res.status(400).json({ message: 'Password reset code has expired' });
      return;
    }

    const isMatch = await bcrypt.compare(code, user.passwordResetCode);
    if (!isMatch) {
      res.status(400).json({ message: 'Invalid reset code' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    
    // Clear reset fields
    user.passwordResetCode = undefined;
    user.passwordResetExpires = undefined;
    
    await user.save();

    res.status(200).json({ message: 'Password has been reset successfully.' });
  } catch (error: any) {
    console.error('Reset Password Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const { name, email, phone, gymName, address, contactPhone } = req.body;

    // Update User
    if (name || email || phone !== undefined) {
      const updateData: any = {};
      if (name) updateData.name = name;
      if (email) updateData.email = email;
      if (phone !== undefined) updateData.phone = phone;
      await User.findByIdAndUpdate(user._id, updateData);
    }

    // Update Gym
    let gym = await Gym.findOne({ ownerId: user._id });
    if (gym) {
      if (gymName) gym.name = gymName;
      if (address) gym.address = address;
      if (contactPhone) gym.contactPhone = contactPhone;
      await gym.save();
    }

    const updatedUser = await User.findById(user._id);
    res.status(200).json({ message: 'Profile updated successfully', user: updatedUser, gym });
  } catch (error: any) {
    console.error('Update Profile Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updateProfileImage = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    if (!req.file) {
      res.status(400).json({ message: 'Please upload an image file' });
      return;
    }

    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const profileImage = req.file.path;

    // Update user
    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage },
      { new: true }
    );

    res.status(200).json({ message: 'Profile image updated', profileImage: updatedUser?.profileImage });
  } catch (error: any) {
    console.error('Update Profile Image Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updateGymLogo = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    if (!req.file) {
      res.status(400).json({ message: 'No image provided' });
      return;
    }

    const logoUrl = req.file.path;

    let gym = await Gym.findOne({ ownerId: user._id });
    if (gym) {

      gym.logo = logoUrl;
      await gym.save();
    } else {
      res.status(404).json({ message: 'Gym not found' });
      return;
    }

    res.status(200).json({ message: 'Gym logo updated successfully', logo: logoUrl });
  } catch (error: any) {
    console.error('Update Gym Logo Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const registerUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, email, password } = req.body;
    let profileImage = '';

    if (req.file) {
      profileImage = req.file.path;
    }

    if (!name || !email || !password) {
      res.status(400).json({ message: 'Please provide name, email, and password' });
      return;
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
      res.status(400).json({ message: 'User already exists' });
      return;
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      profileImage,
      authProvider: 'local',
      role: 'gym_owner',
      isEmailVerified: false,
    });

    if (user) {
      // Generate 6 digit code for email verification
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      user.emailVerificationCode = await bcrypt.hash(otp, 10);
      await user.save();
      await sendVerificationEmail(user.email, otp);

      res.status(201).json({
        requiresEmailVerification: true,
        userId: user.id,
      });
    } else {
      res.status(400).json({ message: 'Invalid user data' });
    }
  } catch (error: any) {
    console.error('Register Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const verifyEmailRegistration = async (req: Request, res: Response): Promise<void> => {
  try {
    const { userId, code } = req.body;
    
    if (!userId || !code) {
      res.status(400).json({ message: 'Please provide user ID and verification code' });
      return;
    }

    const user = await User.findById(userId);
    if (!user || user.authProvider !== 'local') {
      res.status(404).json({ message: 'User not found or invalid auth provider' });
      return;
    }

    if (user.isEmailVerified) {
      res.status(400).json({ message: 'Email is already verified' });
      return;
    }

    if (!user.emailVerificationCode) {
      res.status(400).json({ message: 'No verification code found' });
      return;
    }

    const isMatch = await bcrypt.compare(code, user.emailVerificationCode);
    if (!isMatch) {
      res.status(400).json({ message: 'Invalid verification code' });
      return;
    }

    // Mark as verified
    user.isEmailVerified = true;
    user.emailVerificationCode = undefined;
    await user.save();

    await sendWelcomeEmail(user.email, user.name);

    res.status(200).json({
      _id: user.id,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage,
      role: user.role,
      token: generateToken(user.id),
    });
  } catch (error: any) {
    console.error('Verify Email Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const loginUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });

    if (user && user.password && (await bcrypt.compare(password, user.password))) {
      if (user.status === 'suspended') {
        res.status(403).json({ message: 'Account Suspended', isSuspended: true, suspensionId: user.suspensionId });
        return;
      }

      if (!user.isEmailVerified && user.authProvider === 'local') {
        // Resend code if they try to login without verifying
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        user.emailVerificationCode = await bcrypt.hash(otp, 10);
        await user.save();
        await sendVerificationEmail(user.email, otp);

        res.json({
          requiresEmailVerification: true,
          userId: user.id,
          message: 'Please verify your email address to continue.'
        });
        return;
      }

      if (user.settings?.twoFactorEnabled && user.twoFactorMethod !== 'none') {
        if (user.twoFactorMethod === 'email') {
          const otp = Math.floor(100000 + Math.random() * 900000).toString();
          user.twoFactorOTP = await bcrypt.hash(otp, 10);
          user.twoFactorOTPExpires = new Date(Date.now() + 10 * 60000); // 10 mins
          await user.save();
          await sendOTP(user.email, otp);
        }
        res.json({
          requires2FA: true,
          userId: user.id,
          method: user.twoFactorMethod,
        });
        return;
      }

      let isNewUser = false;
      if (user.role === 'gym_owner') {
        const gym = await Gym.findOne({ ownerId: user._id });
        if (!gym) {
          isNewUser = true;
        }
      }

      const token = generateToken(user.id);
      
      await Session.create({
        userId: user.id,
        token,
        userAgent: (req.headers['user-agent'] as string) || 'Unknown Device',
        ipAddress: (req.headers['x-forwarded-for'] as string)?.split(',')[0] || (req.socket.remoteAddress as string) || 'Unknown IP'
      });

      res.json({
        _id: user.id,
        name: user.name,
        email: user.email,
        profileImage: user.profileImage,
        role: user.role,
        isNewUser,
        token,
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error: any) {
    console.error('Login Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const googleLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    // In production, you would verify the idToken from Google using google-auth-library here.
    // For now, we trust the profile payload sent from the Flutter client after it verifies locally.
    const { name, email, profileImage, googleId } = req.body;

    if (!email) {
      res.status(400).json({ message: 'Email is required for Google Sign In' });
      return;
    }

    let isNewUser = false;
    let user = await User.findOne({ email });

    if (!user) {
      isNewUser = true;
      // Create user if they don't exist
      user = await User.create({
        name: name || 'Google User',
        email,
        profileImage: profileImage || '',
        authProvider: 'google',
        role: 'gym_owner',
        googleId,
        isEmailVerified: true, // Google emails are pre-verified
      });
      
      await sendWelcomeEmail(user.email, user.name);
    } else {
      if (user.status === 'suspended') {
        res.status(403).json({ message: 'Account Suspended', isSuspended: true, suspensionId: user.suspensionId });
        return;
      }

      // Sync profile avatar if it's missing or if a new one is sent
      if (profileImage && user.profileImage !== profileImage) {
        user.profileImage = profileImage;
        await user.save();
      }
    }
    // Check if user is a gym owner and actually has a gym
    if (!isNewUser && user.role === 'gym_owner') {
      const gym = await Gym.findOne({ ownerId: user._id });
      if (!gym) {
        isNewUser = true;
      }
    }

    const token = generateToken(user.id);
    
    await Session.create({
      userId: user.id,
      token,
      userAgent: (req.headers['user-agent'] as string) || 'Unknown Device',
      ipAddress: (req.headers['x-forwarded-for'] as string)?.split(',')[0] || (req.socket.remoteAddress as string) || 'Unknown IP'
    });

    res.status(200).json({
      _id: user.id,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage,
      role: user.role,
      isNewUser,
      token,
    });
  } catch (error: any) {
    console.error('Google Auth Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updateSettings = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.user;
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const { settings } = req.body;

    const updatedUser = await User.findByIdAndUpdate(
      user._id,
      { $set: { settings } },
      { new: true }
    );

    res.status(200).json(updatedUser?.settings);
  } catch (error: any) {
    console.error('Update Settings Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const updatePassword = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(userId);
    
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    if (user.authProvider === 'google') {
      res.status(400).json({ message: 'Google authenticated users cannot change their password here.' });
      return;
    }

    if (!user.password) {
      res.status(400).json({ message: 'No password set for this user.' });
      return;
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      res.status(400).json({ message: 'Incorrect current password' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error: any) {
    console.error('Update Password Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const setup2FA = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user?._id);
    if (!user) { res.status(404).json({ message: 'User not found' }); return; }

    const { method } = req.body;
    
    if (method === 'app') {
      const secret = speakeasy.generateSecret({ name: `GymManagement (${user.email})` });
      user.twoFactorSecret = secret.base32;
      user.twoFactorMethod = 'app';
      await user.save();

      qrcode.toDataURL(secret.otpauth_url!, (err, dataUrl) => {
        if (err) { res.status(500).json({ message: 'Error generating QR code' }); return; }
        res.json({ qrCodeUrl: dataUrl, secret: secret.base32 });
      });
    } else if (method === 'email') {
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      user.twoFactorOTP = await bcrypt.hash(otp, 10);
      user.twoFactorOTPExpires = new Date(Date.now() + 10 * 60000); // 10 mins
      user.twoFactorMethod = 'email';
      await user.save();
      await sendOTP(user.email, otp);
      res.json({ message: 'OTP sent to email' });
    } else {
      res.status(400).json({ message: 'Invalid method' });
    }
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const verify2FASetup = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user?._id);
    if (!user) { res.status(404).json({ message: 'User not found' }); return; }

    const { code } = req.body;

    if (user.twoFactorMethod === 'app') {
      const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret!,
        encoding: 'base32',
        token: code,
      });

      if (verified) {
        user.settings = { ...user.settings, twoFactorEnabled: true } as any;
        await user.save();
        res.json({ message: '2FA enabled successfully' });
      } else {
        res.status(400).json({ message: 'Invalid code' });
      }
    } else if (user.twoFactorMethod === 'email') {
      if (!user.twoFactorOTP || !user.twoFactorOTPExpires || user.twoFactorOTPExpires < new Date()) {
        res.status(400).json({ message: 'OTP expired or invalid' }); return;
      }
      
      const isMatch = await bcrypt.compare(code, user.twoFactorOTP);
      if (isMatch) {
        user.settings = { ...user.settings, twoFactorEnabled: true } as any;
        user.twoFactorOTP = undefined;
        user.twoFactorOTPExpires = undefined;
        await user.save();
        res.json({ message: '2FA enabled successfully' });
      } else {
        res.status(400).json({ message: 'Invalid code' });
      }
    }
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const verify2FALogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { userId, code } = req.body;
    const user = await User.findById(userId);

    if (!user || !user.settings?.twoFactorEnabled) {
      res.status(400).json({ message: '2FA not enabled or user not found' });
      return;
    }

    let isValid = false;

    if (user.twoFactorMethod === 'app' && user.twoFactorSecret) {
      isValid = speakeasy.totp.verify({
        secret: user.twoFactorSecret,
        encoding: 'base32',
        token: code,
        window: 1,
      });
      // Fallback to email OTP if authenticator code fails but email OTP exists
      if (!isValid && user.twoFactorOTP && user.twoFactorOTPExpires && user.twoFactorOTPExpires > new Date()) {
        isValid = await bcrypt.compare(code, user.twoFactorOTP);
      }
    } else if (user.twoFactorMethod === 'email' && user.twoFactorOTP) {
      if (user.twoFactorOTPExpires && user.twoFactorOTPExpires > new Date()) {
        isValid = await bcrypt.compare(code, user.twoFactorOTP);
      }
    }

    if (isValid) {
      // Clear OTP
      if (user.twoFactorMethod === 'email') {
        user.twoFactorOTP = undefined;
        user.twoFactorOTPExpires = undefined;
        await user.save();
      }
      
      const token = generateToken(user.id);

      await Session.create({
        userId: user.id,
        token,
        userAgent: (req.headers['user-agent'] as string) || 'Unknown Device',
        ipAddress: (req.headers['x-forwarded-for'] as string)?.split(',')[0] || (req.socket.remoteAddress as string) || 'Unknown IP'
      });

      res.json({
        _id: user.id,
        name: user.name,
        email: user.email,
        profileImage: user.profileImage,
        role: user.role,
        token,
      });
    } else {
      res.status(400).json({ message: 'Invalid or expired code' });
    }
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const sendFallback2FA = async (req: Request, res: Response): Promise<void> => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);

    if (!user || !user.settings?.twoFactorEnabled) {
      res.status(400).json({ message: '2FA not enabled or user not found' });
      return;
    }

    if (user.twoFactorMethod === 'app') {
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      user.twoFactorOTP = await bcrypt.hash(otp, 10);
      user.twoFactorOTPExpires = new Date(Date.now() + 10 * 60000); // 10 mins
      await user.save();
      
      const { sendOTP } = await import('../utils/email');
      await sendOTP(user.email, otp);
      
      res.json({ message: 'Fallback OTP sent to email' });
    } else {
      res.status(400).json({ message: 'Fallback not applicable' });
    }
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const checkEmail2FA = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;
    if (!email) {
      res.status(400).json({ message: 'Email is required' });
      return;
    }

    const user = await User.findOne({ email });
    if (!user) {
      // Return 200 with false instead of 404 to prevent user enumeration
      res.json({ is2FAEnabled: false });
      return;
    }

    if (user.settings?.twoFactorEnabled && user.twoFactorMethod !== 'none') {
      res.json({
        is2FAEnabled: true,
        userId: user.id,
        method: user.twoFactorMethod,
      });
    } else {
      res.json({
        is2FAEnabled: false,
      });
    }
  } catch (error: any) {
    console.error('Check Email 2FA Error:', error);
    res.status(500).json({ message: error.message });
  }
};

export const getActiveSessions = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    if (!userId) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    const sessions = await Session.find({ userId }).sort({ lastActive: -1 });
    res.status(200).json(sessions);
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};

export const revokeSession = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?._id;
    const sessionId = req.params.id as string;

    if (!userId || !sessionId) {
      res.status(404).json({ message: 'User or Session ID not found' });
      return;
    }

    const session = await Session.findOneAndDelete({ _id: sessionId, userId: userId as any });
    
    if (!session) {
      res.status(404).json({ message: 'Session not found or already revoked' });
      return;
    }

    res.status(200).json({ message: 'Session revoked successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message });
  }
};
