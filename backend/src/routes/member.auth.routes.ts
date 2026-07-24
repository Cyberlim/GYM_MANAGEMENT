import express from 'express';
import {
  login,
  changePassword,
  getProfile,
  getAttendance,
  getPlans,
  purchasePlan,
  forgotPassword,
  verifyOtpAndResetPassword,
} from '../controllers/member.auth.controller';
import {
  getNotifications,
  markAsRead,
  markAllAsRead,
  subscribeToPush,
  unsubscribeFromPush,
  getVapidPublicKey,
} from '../controllers/notification.controller';
import {
  getMemberMessages,
  sendMemberMessage,
  markMemberMessagesAsRead,
} from '../controllers/member.support.controller';
import { protectMember } from '../middlewares/member.auth.middleware';

const router = express.Router();

router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', verifyOtpAndResetPassword);
router.post('/change-password', protectMember as any, changePassword as any);
router.get('/profile', protectMember as any, getProfile as any);
router.get('/attendance', protectMember as any, getAttendance as any);
router.get('/plans', protectMember as any, getPlans as any);
router.post('/purchase-plan', protectMember as any, purchasePlan as any);

// Notifications Routes
router.get('/notifications', protectMember as any, getNotifications as any);
router.put('/notifications/read-all', protectMember as any, markAllAsRead as any);
router.put('/notifications/:id/read', protectMember as any, markAsRead as any);
router.post('/notifications/subscribe', protectMember as any, subscribeToPush as any);
router.post('/notifications/unsubscribe', protectMember as any, unsubscribeFromPush as any);
router.get('/notifications/vapid-public-key', protectMember as any, getVapidPublicKey as any);

// Support Routes
router.get('/support', protectMember as any, getMemberMessages as any);
router.post('/support', protectMember as any, sendMemberMessage as any);
router.put('/support/read', protectMember as any, markMemberMessagesAsRead as any);

export default router;
