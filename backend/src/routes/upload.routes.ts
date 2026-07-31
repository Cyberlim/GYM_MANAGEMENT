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

    // Extract public_id from a Cloudinary URL.
    // Format: https://res.cloudinary.com/<cloud>/image/upload/v<version>/<folder/public_id>.<ext>
    // We need everything after /upload/ (and skip the version segment v12345) without the extension.
    let publicId: string | null = null;

    const uploadIndex = url.indexOf('/upload/');
    if (uploadIndex !== -1) {
      let afterUpload = url.substring(uploadIndex + '/upload/'.length);
      // Remove version segment if present (e.g. "v1234567890/")
      afterUpload = afterUpload.replace(/^v\d+\//, '');
      // Remove file extension
      const dotIndex = afterUpload.lastIndexOf('.');
      publicId = dotIndex !== -1 ? afterUpload.substring(0, dotIndex) : afterUpload;
    }

    if (!publicId) {
      res.status(400).json({ message: 'Invalid Cloudinary URL' });
      return;
    }

    const result = await cloudinary.uploader.destroy(publicId);
    console.log('Cloudinary destroy result:', result);
    res.status(200).json({ message: 'File deleted successfully', result });
  } catch (error) {
    console.error('Error deleting file:', error);
    res.status(500).json({ message: 'Server error deleting file' });
  }
});
export default router;
