const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://proyectodegrado-90yf.onrender.com';

async function testPublish() {
  try {
    // Step 1: Login to get fresh token
    console.log('1️⃣ Attempting login...');
    const loginRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'testbot+ci@example.com',
        password: 'T3st@1234'
      })
    });

    const loginData = await loginRes.json();
    if (!loginRes.ok || !loginData.token) {
      console.error('❌ Login failed:', loginData);
      return;
    }

    const token = loginData.token;
    console.log('✅ Login successful. Token:', token.substring(0, 50) + '...');

    // Step 2: Create a small test file
    console.log('\n2️⃣ Creating test file...');
    const testFilePath = path.join(__dirname, 'test_video.mp4');
    // Create a minimal fake MP4 (just for testing the upload endpoint)
    fs.writeFileSync(testFilePath, Buffer.from([
      0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ftyp header (minimal)
      0x69, 0x73, 0x6f, 0x6d, 0x00, 0x00, 0x00, 0x00,
      0x69, 0x73, 0x6f, 0x6d, 0x69, 0x73, 0x6f, 0x32,
      0x6d, 0x70, 0x34, 0x31, 0x69, 0x73, 0x6f, 0x32
    ]));
    console.log('✅ Test file created:', testFilePath);

    // Step 3: Create FormData and publish
    console.log('\n3️⃣ Attempting to publish with video...');


    // Use FormData with native Node fetch
    const formData = new FormData();
    const fileBuffer = fs.readFileSync(testFilePath);
    const blob = new Blob([fileBuffer], { type: 'video/mp4' });
    formData.append('contenido', 'Test publication from Node script');
    formData.append('tipoPost', 'GENERAL');
    formData.append('evidencias', blob, 'test_video.mp4');

    const publishRes = await fetch(`${BASE_URL}/api/posts`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    });

    const publishText = await publishRes.text();
    console.log(`\n📊 Response Status: ${publishRes.status}`);
    console.log('📄 Response Headers:', Object.fromEntries(publishRes.headers));
    console.log('📝 Response Body:', publishText.substring(0, 1000));

    if (publishRes.ok) {
      console.log('\n✅ Publication successful!');
      const publishData = JSON.parse(publishText);
      if (publishData.evidencias && publishData.evidencias.length > 0) {
        console.log('\n📹 Video URL:', publishData.evidencias[0].url);
        console.log('🔗 Full URL:', `${BASE_URL}${publishData.evidencias[0].url}`);
      }
    } else {
      console.log('\n❌ Publication failed!');
      console.log('Error details:', publishText);
    }

    // Cleanup
    fs.unlinkSync(testFilePath);

  } catch (err) {
    console.error('💥 Test error:', err.message);
    console.error(err);
  }
}

testPublish();
