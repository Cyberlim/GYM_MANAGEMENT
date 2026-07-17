const { v2: cloudinary } = require('cloudinary');

cloudinary.config({
  cloud_name: 'dwsdxem8w',
  api_key: '267889955193276',
  api_secret: '0I99Rl6treRpLtk2TiqyhMRuVPA',
});

cloudinary.uploader.upload('test.jpg', { folder: 'gym_crm' }, function(error, result) {
  if (error) {
    console.error('Cloudinary Error:', error);
  } else {
    console.log('Upload successful:', result.secure_url);
  }
});
