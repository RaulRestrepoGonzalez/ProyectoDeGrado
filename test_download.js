const fetch = globalThis.fetch || require('node-fetch');

const BASE = 'https://proyectodegrado-90yf.onrender.com';
const FILE_ID = '6a56bac306b858fd0edc38e1';

async function run() {
  try {
    console.log('HEAD request...');
    const head = await fetch(`${BASE}/api/files/download/${FILE_ID}`, { method: 'HEAD' });
    console.log('HEAD status:', head.status);
    console.log('HEAD headers:', Object.fromEntries(head.headers));

    console.log('\nRange request (bytes=0-9)...');
    const range = await fetch(`${BASE}/api/files/download/${FILE_ID}`, { method: 'GET', headers: { Range: 'bytes=0-9' } });
    console.log('Range status:', range.status);
    console.log('Range headers:', Object.fromEntries(range.headers));
    const buf = await range.arrayBuffer();
    console.log('Range bytes received:', buf.byteLength);
  } catch (err) {
    console.error('Error:', err.message);
  }
}

run();
