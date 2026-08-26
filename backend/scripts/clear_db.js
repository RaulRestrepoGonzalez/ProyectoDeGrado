require('dotenv').config();
const mongoose = require('mongoose');

const Usuario = require('../src/models/Usuario');
const Publicacion = require('../src/models/Publicacion');

(async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/soundupar_db';
  console.log('🔌 Conectando a MongoDB:', mongoUri);
  try {
    await mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true });

    console.log('🧹 Eliminando colecciones de Usuario y Publicacion...');
    const usersResult = await Usuario.deleteMany({});
    const postsResult = await Publicacion.deleteMany({});

    console.log(`✅ Usuarios eliminados: ${usersResult.deletedCount}`);
    console.log(`✅ Publicaciones eliminadas: ${postsResult.deletedCount}`);

    if (process.env.DELETE_GRIDFS === 'true') {
      console.log('🗑️ DELETE_GRIDFS=true → Eliminando colecciones fs.files y fs.chunks (GridFS)');
      const db = mongoose.connection.db;
      try {
        await db.collection('fs.files').deleteMany({});
        await db.collection('fs.chunks').deleteMany({});
        console.log('✅ GridFS limpiado.');
      } catch (gerr) {
        console.warn('⚠️ Error limpiando GridFS:', gerr.message);
      }
    }

    await mongoose.disconnect();
    console.log('👋 Conexión cerrada. Operación completada.');
  } catch (err) {
    console.error('❌ Error durante la operación:', err);
    process.exit(1);
  }
})();
