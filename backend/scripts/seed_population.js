require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const Usuario = require('../src/models/Usuario');
const Publicacion = require('../src/models/Publicacion');

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomText(i) {
  const samples = [
    'Busco músicos para banda nueva, ensayos fines de semana.',
    'Se busca tecladista para sesión en estudio.',
    'Ofrezco servicios de producción musical, contacto por DM.',
    'Busco vocalista para proyecto pop/indie.',
    'Necesito percusionista para presentación local.',
    'Publicación de prueba para poblamiento inicial.',
    'Busco alianzas y colaboraciones en producción.'
  ];
  return `${randomChoice(samples)} (#${i})`;
}

(async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/soundupar_db';
  const NUM_USERS = parseInt(process.env.NUM_USERS || '20', 10);
  const POSTS_PER_USER = parseInt(process.env.POSTS_PER_USER || '5', 10);
  console.log(`🔌 Conectando a MongoDB: ${mongoUri}`);

  try {
    await mongoose.connect(mongoUri);
    console.log('✅ MongoDB conectado para seed');

    const createdUsers = [];

    for (let i = 0; i < NUM_USERS; i++) {
      const email = `user_seed_${i}@example.com`;
      const nombre = `Seed User ${i}`;
      const password = await bcrypt.hash('SeedPass123!', 10);
      const rol = randomChoice(['artista', 'independiente', 'compañia']);

      const user = await Usuario.create({
        nombre,
        email,
        password,
        rol,
        tokens: 5,
        publicacionesGratuitas: 0,
      });
      createdUsers.push(user);
    }

    console.log(`✅ Usuarios creados: ${createdUsers.length}`);

    let totalPosts = 0;
    for (let u = 0; u < createdUsers.length; u++) {
      const user = createdUsers[u];
      for (let p = 0; p < POSTS_PER_USER; p++) {
        const contenido = randomText(totalPosts + 1);
        await Publicacion.create({
          autor: user._id,
          contenido,
          tipoPost: 'GENERAL',
          evidencias: [],
        });
        totalPosts++;
      }
    }

    console.log(`✅ Publicaciones creadas: ${totalPosts}`);

    await mongoose.disconnect();
    console.log('👋 Seed completado. Conexión cerrada.');
  } catch (err) {
    console.error('❌ Error en seed:', err);
    process.exit(1);
  }
})();
