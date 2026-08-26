const fetch = globalThis.fetch || require('node-fetch');
(async () => {
  try {
    const BASE = process.env.BASE_URL || 'https://proyectodegrado-90yf.onrender.com';
    const token = process.env.TEST_TOKEN || process.argv[2];
    if (!token) return console.error('Provide TEST_TOKEN env var or pass token as first argument');

    const res = await fetch(`${BASE}/api/posts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ contenido: 'Publicación simple de prueba (sin archivos).' }),
    });

    const body = await res.json();
    console.log('Status:', res.status);
    console.log('Body:', body);
  } catch (err) {
    console.error('Error:', err);
  }
})();
