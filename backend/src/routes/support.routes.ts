import express from 'express';
import { protect } from '../middlewares/auth.middleware';
import { getSuspensionMessages, sendSuspensionMessage, getAllSuspensions, getSuspensionMessagesPublic, sendSuspensionMessagePublic, clearSuspensionMessages, markMessagesAsRead } from '../controllers/support.controller';

const router = express.Router();

router.get('/suspensions/public/:suspensionId', getSuspensionMessagesPublic);
router.post('/suspensions/public/:suspensionId', sendSuspensionMessagePublic);

router.use(protect);

router.get('/suspensions', getAllSuspensions);
router.get('/suspensions/:suspensionId', getSuspensionMessages);
router.post('/suspensions/:suspensionId', sendSuspensionMessage);
router.put('/suspensions/:suspensionId/read', markMessagesAsRead);
router.delete('/suspensions/:suspensionId/messages', clearSuspensionMessages);

export default router;
