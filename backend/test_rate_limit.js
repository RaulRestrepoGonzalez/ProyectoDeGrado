const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
};

const postData = JSON.stringify({
  email: 'test@example.com',
  password: 'wrongpassword'
});

async function runTest() {
  console.log('Iniciando simulación de fuerza bruta...');
  for (let i = 1; i <= 6; i++) {
    await new Promise((resolve) => {
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          console.log(`Intento ${i}: Status ${res.statusCode} - Response: ${data}`);
          resolve();
        });
      });
      req.on('error', (e) => {
        console.error(`Problema con intento ${i}: ${e.message}`);
        resolve();
      });
      req.write(postData);
      req.end();
    });
  }
}

runTest();
