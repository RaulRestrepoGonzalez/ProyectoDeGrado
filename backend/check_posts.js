const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const Publicacion = require('./src/models/Publicacion');
const Usuario = require('./src/models/Usuario');

async function checkDB() {
  try {
    const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/musicapp_valledupar';
    console.log('Connecting to:', uri);
    await mongoose.connect(uri);
    
    const count = await Publicacion.countDocuments();
    console.log('Total publications:', count);
    
    if (count > 0) {
      const sample = await Publicacion.findOne().populate('autor', 'nombre');
      console.log('Sample publication:', JSON.stringify(sample, null, 2));
    } else {
      console.log('No publications found.');
    }
    
    const users = await Usuario.countDocuments();
    console.log('Total users:', users);
    
    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

checkDB();
