process.env.JWT_SECRET = process.env.JWT_SECRET || 'testsecret';

const request = require('supertest');
const { connectDB } = require('../src/config/database');
const app = require('../src/app');
const mongoose = require('mongoose');
const Usuario = require('../src/models/Usuario');

const testUser = {
  email: 'test@musico.com',
  password: 'Test1234!',
  nombre: 'Test Musico',
};

describe('Auth integration tests', () => {
  beforeAll(async () => {
    await connectDB();
    await Usuario.deleteMany({ email: testUser.email });
  });

  afterAll(async () => {
    await Usuario.deleteMany({ email: testUser.email });
    await mongoose.connection.close();
  });

  it('should register a new user', async () => {
    const res = await request(app).post('/api/auth/register').send({
      email: testUser.email,
      password: testUser.password,
      nombre: testUser.nombre,
      rol: 'musico',
    });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty('message', 'Usuario registrado correctamente.');
    expect(res.body).toHaveProperty('user');
    expect(res.body.user).toHaveProperty('email', testUser.email);
  });

  it('should login and return a token', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: testUser.email,
      password: testUser.password,
    });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('token');
    expect(typeof res.body.token).toBe('string');

    const token = res.body.token;

    // Use token to access protected route
    const protectedRes = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${token}`);

    expect(protectedRes.status).toBe(200);
    expect(protectedRes.body).toHaveProperty('message', 'Acceso autorizado');
    expect(protectedRes.body).toHaveProperty('user');
    expect(protectedRes.body.user).toHaveProperty('email', testUser.email);

    // Validate /auth/me endpoint
    const meRes = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body).toHaveProperty('user');
    expect(meRes.body.user).toHaveProperty('email', testUser.email);

    // Validate /auth/refresh returns a new token (use refreshToken from login response)
    const refreshToken = res.body.refreshToken;
    // small delay to ensure new token has different `iat` claim
    await new Promise((r) => setTimeout(r, 1100));
    const refreshRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body).toHaveProperty('token');
    expect(refreshRes.body.token).not.toBe(token);

    // Use refreshed token for a protected call
    const protectedWithRefreshed = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${refreshRes.body.token}`);

    expect(protectedWithRefreshed.status).toBe(200);
    expect(protectedWithRefreshed.body.user).toHaveProperty('email', testUser.email);
  });

  it('should reject requests without token', async () => {
    const res = await request(app).get('/api/protected');
    expect(res.status).toBe(401);
  });
});
