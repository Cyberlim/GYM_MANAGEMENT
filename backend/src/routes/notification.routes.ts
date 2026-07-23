import express from 'express';
import { protect } from '../middlewares/auth.middleware';
import { getNotifications, markAsRead, markAllAsRead, subscribeToPush, unsubscribeFromPush, getVapidPublicKey } from '../controllers/notification.controller';

const router = express.Router();

router.use(protect);

router.get('/', getNotifications);
router.put('/read-all', markAllAsRead);
router.put('/:id/read', markAsRead);

router.post('/subscribe', subscribeToPush);
router.post('/unsubscribe', unsubscribeFromPush);
router.get('/vapid-public-key', getVapidPublicKey);

export default router;
