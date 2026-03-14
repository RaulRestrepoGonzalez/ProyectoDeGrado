const mongoose = require('mongoose');

async function checkDB() {
  await mongoose.connect('mongodb://localhost:27017/musicapp_valledupar');
  const dbs = await mongoose.connection.db.collection('usuarios').find({}).toArray();
  console.log("Usuarios en la BD:");
  dbs.forEach(d => console.log(`Email: ${d.email}, Rol: ${d.rol}, Password Hash: ${d.password}`));
  process.exit(0);
}

checkDB();
