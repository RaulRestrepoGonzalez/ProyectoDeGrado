const fetch = globalThis.fetch || require('node-fetch');
(async () => {
  try {
    const BASE = process.env.BASE_URL || 'http://localhost:3000';
    const email = 'user_seed_0@example.com';
    const password = 'SeedPass123!';

    const loginRes = await fetch(`${BASE}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const loginJson = await loginRes.json();
    console.log('Login status:', loginRes.status);
    if (!loginRes.ok) return console.error('Login failed', loginJson);

    const token = loginJson.token;
    const feedRes = await fetch(`${BASE}/api/posts/feed`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const feedJson = await feedRes.json();
    console.log('Feed status:', feedRes.status);
    console.log('Feed items:', Array.isArray(feedJson) ? feedJson.length : (feedJson.data ? feedJson.data.length : 'unknown'));
  } catch (err) {
    console.error('Error:', err);
  }
})();
