import express from 'express';
import { upload, cloudinary } from '../config/cloudinary';
import { protect } from '../middlewares/auth.middleware';

const router = express.Router();

router.post('/', protect, upload.single('file'), (req, res) => {
  if (!req.file) {
    res.status(400).json({ message: 'No file uploaded' });
    return;
  }
  res.status(200).json({ url: req.file.path });
});

router.delete('/', protect, async (req, res) => {
  try {
    const url = req.query.url as string;
    if (!url) {
      res.status(400).json({ message: 'URL is required' });
      return;
    }
    
    // Extract public_id from url. Example: http://.../file-1234.jpg -> file-1234
    const filename = url.split('/').pop();
    if (!filename) {
      res.status(400).json({ message: 'Invalid URL' });
      return;
    }
    const publicId = filename.split('.')[0];
    if (!publicId) {
      res.status(400).json({ message: 'Invalid URL format' });
      return;
    }
    
    await cloudinary.uploader.destroy(publicId);
    res.status(200).json({ message: 'File deleted successfully' });
  } catch (error) {
    console.error('Error deleting file:', error);
    res.status(500).json({ message: 'Server error deleting file' });
  }
});
export default router;
