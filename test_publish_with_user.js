const fetch = globalThis.fetch || require('node-fetch');
const FormData = require('form-data');
const fs = require('fs');

(async () => {
  try {
    const BASE = process.env.BASE_URL || 'https://proyectodegrado-90yf.onrender.com';
    // Allow passing token via env or as first CLI arg for convenience
    const token = process.env.TEST_TOKEN || process.argv[2];
    if (!token) return console.error('Provide TEST_TOKEN env var or pass token as first argument');

    console.log('Posting a small test publication...');
    const form = new FormData();
    form.append('titulo', 'Test publicación CI');
    form.append('texto', 'Prueba de publicación automática.');
    // attach a small dummy file
    fs.writeFileSync('tmp_test.txt', 'hello world');
    form.append('evidencias', fs.createReadStream('tmp_test.txt'));

    const headers = Object.assign({ Authorization: `Bearer ${token}` }, form.getHeaders());
    const res = await fetch(`${BASE}/api/posts`, {
      method: 'POST',
      headers,
      body: form,
    });

    const body = await res.json();
    console.log('Status:', res.status);
    console.log('Body:', body);

    fs.unlinkSync('tmp_test.txt');
  } catch (err) {
    console.error('Publish test error:', err);
  }
})();
