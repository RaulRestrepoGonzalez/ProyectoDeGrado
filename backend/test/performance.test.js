process.env.JWT_SECRET = process.env.JWT_SECRET || 'testsecret';

const bcrypt = require('bcryptjs');
const { connectDB } = require('../src/config/database');
const Usuario = require('../src/models/Usuario');
const request = require('supertest');
const app = require('../src/app');

const LOGIN_CREDENTIALS = {
  email: 'perf@musico.com',
  password: 'Perf1234',
};

describe('Backend performance & stress tests', () => {
  beforeAll(async () => {
    await connectDB();
    await Usuario.deleteMany({ email: LOGIN_CREDENTIALS.email });
    const hashed = await bcrypt.hash(LOGIN_CREDENTIALS.password, 10);
    await Usuario.create({
      email: LOGIN_CREDENTIALS.email,
      password: hashed,
      nombre: 'Performance User',
      rol: 'musico',
    });
  });

  afterAll(async () => {
    await Usuario.deleteMany({ email: LOGIN_CREDENTIALS.email });
    await require('mongoose').connection.close();
  });

  it('should handle a short burst of login requests', async () => {
    const requests = Array.from({ length: 30 }, () =>
      request(app)
        .post('/api/auth/login')
        .send(LOGIN_CREDENTIALS)
        .timeout({ deadline: 15000, response: 15000 }),
    );

    const results = await Promise.all(requests);
    const successCount = results.filter((res) => res.status === 200).length;

    // Al menos 90% de respuestas deben ser exitosas incluso bajo carga.
    expect(successCount / results.length).toBeGreaterThanOrEqual(0.9);
  }, 30000);
});
