const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const fetch = require('node-fetch');

async function testUpload() {
  const form = new FormData();
  form.append('name', 'Test Gym');
  form.append('address', '123 Street');
  form.append('contactPhone', '1234567890');
  
  // create dummy image file
  const testImagePath = path.join(__dirname, 'test.jpg');
  fs.writeFileSync(testImagePath, 'fake image data');
  
  form.append('logo', fs.createReadStream(testImagePath));

  try {
    const res = await fetch('http://localhost:5000/api/gyms/setup', {
      method: 'POST',
      body: form,
      // No auth header for now to see what we get
    });
    
    const text = await res.text();
    console.log("Status:", res.status);
    console.log("Response:", text);
  } catch(e) {
    console.error(e);
  }
}

testUpload();
