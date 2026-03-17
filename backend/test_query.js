const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const Publicacion = require('./src/models/Publicacion');

async function testQuery() {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/musicapp_valledupar';
    await mongoose.connect(uri);
    
    // Simulate a user ID that should see the post
    const userId = "69b9b4d9e1d1c63ed33c3bf8"; 
    
    const countAll = await Publicacion.countDocuments();
    console.log('Total publications:', countAll);
    
    const countVisible = await Publicacion.countDocuments({
      bloqueadaPor: { $ne: userId }
    });
    console.log('Visible publications for user:', countVisible);
    
    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

testQuery();
