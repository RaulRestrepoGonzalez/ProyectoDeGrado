async function testAuth() {
  const baseURL = 'http://localhost:3000/api';

  try {
    const email = `test${Date.now()}@example.com`;
    console.log('Registering...', email);
    const resReg = await fetch(`${baseURL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password: 'Password123!',
        nombre: 'Test User',
        rol: 'musico'
      })
    });
    console.log('Register Success:', await resReg.json());

    console.log('Logging in...');
    const resLog = await fetch(`${baseURL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password: 'Password123!'
      })
    });
    console.log('Login Success/Error Status:', resLog.status);
    console.log('Login Response:', await resLog.json());
  } catch (err) {
    console.error('Fetch Error:', err.message);
  }
}

testAuth();
