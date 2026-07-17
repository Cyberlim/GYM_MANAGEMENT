import express from 'express';
import { registerUser, loginUser, googleLogin, getMe, updateProfileImage, updateProfile, updateGymLogo, updateSettings, updatePassword, setup2FA, verify2FASetup, verify2FALogin, sendFallback2FA, verifyEmailRegistration, requestPasswordReset, resetPassword, getActiveSessions, revokeSession } from '../controllers/auth.controller';
import { upload } from '../config/cloudinary';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.post('/signup', upload.single('profileImage'), registerUser);
router.post('/verify-email', verifyEmailRegistration);
router.post('/login', loginUser);
router.post('/google-login', googleLogin);
router.post('/forgot-password', requestPasswordReset);
router.post('/reset-password', resetPassword);
router.get('/me', protect, getMe);
router.put('/profile', protect, updateProfile);
router.put('/profile-image', protect, upload.single('profileImage'), updateProfileImage);
router.put('/gym-logo', protect, upload.single('logo'), updateGymLogo);
router.put('/settings', protect, updateSettings);
router.put('/password', protect, updatePassword);

// 2FA Routes
router.post('/2fa/setup', protect, setup2FA);
router.post('/2fa/verify-setup', protect, verify2FASetup);
router.post('/verify-2fa', verify2FALogin);
router.post('/send-fallback-2fa', sendFallback2FA);

// Session Routes
router.get('/sessions', protect, getActiveSessions);
router.delete('/sessions/:id', protect, revokeSession);

export default router;
