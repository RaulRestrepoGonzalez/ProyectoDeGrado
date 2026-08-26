const fetch = globalThis.fetch || require('node-fetch');
const crypto = require('crypto');

(async () => {
  try {
    const BASE = process.env.BASE_URL || 'https://proyectodegrado-90yf.onrender.com';
    const random = crypto.randomBytes(4).toString('hex');
    const email = `ci_test_${random}@example.com`;
    const password = `T3st@${random}A`;

    console.log('🔎 Registering new user:', email);

    const registerRes = await fetch(`${BASE}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, nombre: 'CI Test Bot', rol: 'artista' }),
    });

    const regJson = await registerRes.json();
    console.log('Register status:', registerRes.status);
    console.log('Register body:', regJson);

    if (!registerRes.ok) {
      console.error('Registration failed — stopping test.');
      return;
    }

    // Then login
    console.log('🔐 Logging in with new user...');
    const loginRes = await fetch(`${BASE}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const loginJson = await loginRes.json();
    console.log('Login status:', loginRes.status);
    console.log('Login body:', loginJson);

    if (!loginRes.ok) {
      console.error('Login failed after registration — investigate.');
      return;
    }

    console.log('✅ Registration + login successful. Token received length:', (loginJson.token || '').length);
  } catch (err) {
    console.error('Error during test:', err);
  }
})();
