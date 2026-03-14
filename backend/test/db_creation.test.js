process.env.MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/musicapp_valledupar_test';

const { connectDB } = require('../src/config/database');
const mongoose = require('mongoose');

describe('Database creation', () => {
  beforeAll(async () => {
    // connect using our connection helper (it will attempt candidates / retries)
    await connectDB();
  });

  afterAll(async () => {
    try {
      // clean up test database
      await mongoose.connection.db.dropDatabase();
    } catch (_) {}
    await mongoose.connection.close();
  });

  it('creates the `usuarios` collection or allows a write to the DB', async () => {
    const cols = await mongoose.connection.db.listCollections({ name: 'usuarios' }).toArray();

    if (cols.length === 0) {
      // If migrate/initialization did not create the collection, try writing a document
      const res = await mongoose.connection.db.collection('usuarios').insertOne({ _test: true });
      expect(res.acknowledged).toBe(true);
      // cleanup inserted doc
      await mongoose.connection.db.collection('usuarios').deleteMany({ _test: true });
    } else {
      expect(cols[0].name).toBe('usuarios');
    }
  });
});
