import express from 'express';
import { upload } from '../config/cloudinary';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.post('/', protect, upload.single('file'), (req, res) => {
  if (!req.file) {
    res.status(400).json({ message: 'No file uploaded' });
    return;
  }
  res.status(200).json({ url: req.file.path });
});

export default router;
