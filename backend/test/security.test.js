process.env.JWT_SECRET = process.env.JWT_SECRET || 'testsecret';

const request = require('supertest');
const { connectDB } = require('../src/config/database');
const app = require('../src/app');
const mongoose = require('mongoose');
const Usuario = require('../src/models/Usuario');

const testUser = {
  email: 'security@musico.com',
  password: 'Segura1234!',
  nombre: 'Seguridad Test',
};

describe('Security checks', () => {
  beforeAll(async () => {
    await connectDB();
    await Usuario.deleteMany({ email: testUser.email });

    await request(app).post('/api/auth/register').send({
      email: testUser.email,
      password: testUser.password,
      nombre: testUser.nombre,
      rol: 'musico',
    });
  });

  afterAll(async () => {
    await Usuario.deleteMany({ email: testUser.email });
    await mongoose.connection.close();
  });

  it('should reject /api/auth/me without token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });

  it('should enforce CORS for allowed origin', async () => {
    const res = await request(app)
      .options('/api/auth/login')
      .set('Origin', 'http://localhost:3000');

    expect(res.headers).toHaveProperty('access-control-allow-origin', 'http://localhost:3000');
  });

  it('should sanitize suspicious payloads to prevent NoSQL injection', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: { $gt: '' },
      password: 'cualquier',
    });

    // Debe fallar porque el usuario no existe, aun si el payload es manipulado.
    // Puede fallar con 400 (validación) o 401 (credenciales inválidas).
    expect([400, 401]).toContain(res.status);
  });
});
