require('dotenv').config();
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function runTests() {
  console.log(`Testing Cloudinary with API Key: ${process.env.CLOUDINARY_API_KEY}`);
  console.log(`Cloud Name: ${process.env.CLOUDINARY_CLOUD_NAME}`);
  console.log('--------------------------------------------------');

  try {
    const pingResult = await cloudinary.api.ping();
    console.log('Ping Result (SUCCESS):', pingResult);
  } catch (err) {}

  try {
    console.log('Attempting upload()...');
    const uploadResult = await cloudinary.uploader.upload('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=', {
        folder: 'test_gym_crm'
    });
    console.log('Upload Result (SUCCESS):', uploadResult.public_id);
  } catch (err) {
    console.error('Upload Result (ERROR):', err);
    console.error('Full Error keys:', Object.keys(err));
    // Let's try to extract response headers if available
    if (err.response && err.response.headers) {
      console.error('Headers:', err.response.headers);
    }
  }
}

runTests();
