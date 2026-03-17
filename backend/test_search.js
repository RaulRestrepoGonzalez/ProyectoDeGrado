const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { searchAll } = require('./src/controllers/search.controller');

async function testSearch() {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/musicapp_valledupar';
    await mongoose.connect(uri);
    
    // Simular req/res para el controlador
    const req = { query: { q: 'prueba' } };
    const res = {
      status: (code) => ({
        json: (data) => console.log(`Response Code: ${code}\nData:`, JSON.stringify(data, null, 2))
      })
    };
    const next = (err) => console.error('Next called with error:', err);

    console.log('Testing Search for "prueba"...');
    await searchAll(req, res, next);
    
    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

testSearch();
