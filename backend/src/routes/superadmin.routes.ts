import express from 'express';
import { 
  getDashboardStats, getAllGyms, getFinanceStats, getGymDetails, getPersonDetails, 
  suspendGymOwner, reactivateGymOwner, getReportData, updateSettings, 
  simulatePaymentReceived, simulatePaymentFailed, simulateSystemAlert,
  getGymOwnersList, sendBroadcast, getBroadcastHistory, getBroadcastStatus,
  getAdmins, createAdmin, revokeAdmin
} from '../controllers/superadmin.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.use(protect);

router.get('/dashboard', getDashboardStats);
router.get('/gyms', getAllGyms);
router.get('/gyms/:id', getGymDetails);
router.get('/person/:role/:id', getPersonDetails);
router.get('/finance', getFinanceStats);
router.get('/reports', getReportData);
router.put('/gyms/:id/suspend', suspendGymOwner);
router.put('/gyms/:id/reactivate', reactivateGymOwner);
router.put('/settings', updateSettings);
router.post('/simulate-payment-received', simulatePaymentReceived);
router.post('/simulate-payment-failed', simulatePaymentFailed);
router.post('/simulate-system-alert', simulateSystemAlert);
router.get('/gym-owners', getGymOwnersList);
router.post('/broadcast', sendBroadcast);
router.get('/broadcasts', getBroadcastHistory);
router.get('/broadcasts/:broadcastId/status', getBroadcastStatus);

// Admins Management
router.get('/admins', getAdmins);
router.post('/admins', createAdmin);
router.delete('/admins/:id', revokeAdmin);

export default router;
