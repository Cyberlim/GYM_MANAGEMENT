import express from 'express';
import { setupGym, subscribePlan } from '../controllers/gym.controller';
import { protect } from '../middlewares/auth.middleware';
import { upload } from '../config/cloudinary';

const router = express.Router();

router.post('/setup', protect, upload.single('logo'), setupGym);
router.post('/subscribe', protect, subscribePlan);

export default router;
