const mongoose = require('mongoose');
require('dotenv').config({ path: 'backend/.env' });

const Publicacion = require('./backend/src/models/Publicacion');
const Usuario = require('./backend/src/models/Usuario');

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
    }
    
    const users = await Usuario.countDocuments();
    console.log('Total users:', users);
    
    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

checkDB();
