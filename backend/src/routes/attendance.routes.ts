import express from 'express';
import { getAttendance, markAttendance } from '../controllers/attendance.controller';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

// All attendance routes require authentication
router.use(protect);

router.get('/', getAttendance);
router.post('/', markAttendance);

export default router;
