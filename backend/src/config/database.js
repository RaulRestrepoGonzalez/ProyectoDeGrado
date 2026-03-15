const mongoose = require('mongoose');

/**
 * connectDB
 * - Usa `MONGODB_URI` si está definida.
 * - Si no, permite `MONGO_HOST` o `MONGO_HOSTS` (lista separada por comas).
 * - Intenta candidatos con reintentos exponenciales antes de fallar.
 */
const DEFAULT_DB_NAME = 'musicapp_valledupar';

const buildCandidates = () => {
  const candidates = [];
  if (process.env.MONGODB_URI) {
    candidates.push(process.env.MONGODB_URI);
  }

  // Support MONGO_HOSTS env var (comma separated list) or single MONGO_HOST
  const hostsEnv = process.env.MONGO_HOSTS || process.env.MONGO_HOST;
  if (hostsEnv) {
    const hosts = hostsEnv.split(',').map(h => h.trim()).filter(Boolean);
    for (const h of hosts) {
      // Allow host:port or just host
      if (h.includes('/')) {
        candidates.push(h);
      } else {
        candidates.push(`mongodb://${h}:27017/${DEFAULT_DB_NAME}`);
      }
    }
  }

  // Common fallbacks
  candidates.push(`mongodb://localhost:27017/${DEFAULT_DB_NAME}`);
  candidates.push(`mongodb://127.0.0.1:27017/${DEFAULT_DB_NAME}`);

  return Array.from(new Set(candidates));
};

const tryConnect = async (uri, opts) => {
  const connection = await mongoose.connect(uri, opts);
  return connection;
};

const connectDB = async () => {
  const candidates = buildCandidates();
  const opts = { 
    serverSelectionTimeoutMS: 10000, 
    connectTimeoutMS: 10000, 
    socketTimeoutMS: 60000,
    maxPoolSize: 10,
    minPoolSize: 1,
    maxIdleTimeMS: 30000,
    waitQueueTimeoutMS: 10000,
    retryWrites: true,
    w: 'majority',
    readPreference: 'primaryPreferred'
  };

  console.log(`🔍 Intentando conectar a MongoDB con ${candidates.length} candidatos...`);

  for (let i = 0; i < candidates.length; i++) {
    const uri = candidates[i];
    let attempt = 0;
    const maxAttempts = 6; // Aumentado a 6 intentos
    
    while (attempt < maxAttempts) {
      try {
        console.log(`📡 Intentando conectar a MongoDB (candidato ${i + 1}/${candidates.length}, intento ${attempt + 1}/${maxAttempts}): ${uri}`);
        
        // Limpiar conexión anterior si existe
        if (mongoose.connection.readyState !== 0) {
          await mongoose.connection.close();
        }
        
        const connection = await tryConnect(uri, opts);
        const dbName = connection.connection.db.databaseName || DEFAULT_DB_NAME;

        // Verificar y crear colecciones necesarias
        try {
          const db = connection.connection.db;
          
          // Lista de colecciones necesarias
          const collections = ['usuarios', 'posts', 'bandas', 'eventos', 'mensajes'];
          
          for (const collectionName of collections) {
            try {
              await db.createCollection(collectionName);
              console.log(`✅ Colección '${collectionName}' creada/verificada`);
            } catch (e) {
              if (e && e.code === 48) {
                console.log(`✅ Colección '${collectionName}' ya existe`);
              } else if (e) {
                console.warn(`⚠️  Aviso con colección '${collectionName}':`, e.message || e);
              }
            }
          }
          
          console.log(`🗄️  Base de datos '${dbName}' inicializada correctamente`);
        } catch (e) {
          console.warn(`⚠️  Aviso durante verificación de DB '${dbName}':`, e.message || e);
        }

        console.log(`🎉 MongoDB conectada exitosamente: ${connection.connection.host} (DB: ${dbName})`);
        
        // Configurar manejo de errores post-conexión
        mongoose.connection.on('error', (err) => {
          console.error('❌ Error post-conexión MongoDB:', err);
          // No salir del proceso, permitir reconexión automática
        });
        
        mongoose.connection.on('disconnected', () => {
          console.warn('⚠️  MongoDB desconectado, intentando reconexión...');
        });
        
        mongoose.connection.on('reconnected', () => {
          console.log('🔄 MongoDB reconectado exitosamente');
        });
        
        return; // conectado con éxito
      } catch (err) {
        console.warn(`❌ No se pudo conectar a ${uri} (intento ${attempt + 1}): ${err.message}`);
        attempt += 1;
        
        // Si es el último intento de este candidato, pasar al siguiente
        if (attempt >= maxAttempts) {
          console.log(`🚫 Agotados los intentos para ${uri}, probando siguiente candidato...`);
          break;
        }
        
        // Backoff exponencial con jitter
        const base = 1000; // Aumentado a 1 segundo base
        const delay = Math.min(15000, base * Math.pow(2, attempt)) + Math.floor(Math.random() * 500);
        console.log(`⏳ Esperando ${delay}ms antes del próximo intento...`);
        await new Promise(res => setTimeout(res, delay));
      }
    }
  }

  // Si llegamos aquí, todos los candidatos fallaron
  console.error('🔥 Fallaron todas las tentativas de conexión a MongoDB.');
  console.error('📋 Revise:');
  console.error('   • MONGODB_URI / MONGO_HOST(S) en el archivo .env');
  console.error('   • Que MongoDB esté instalado y corriendo');
  console.error('   • Que el firewall permita conexiones al puerto 27017');
  console.error('   • Que el servicio MongoDB esté iniciado');
  
  // En modo desarrollo, continuar sin MongoDB
  if (process.env.NODE_ENV === 'development') {
    console.warn('⚠️  Modo desarrollo: Continuando sin MongoDB (algunas funciones no estarán disponibles)');
    console.warn('⚠️  Para funcionalidad completa, inicie MongoDB y reinicie el servidor');
    return;
  }
  
  // En producción, salir
  process.exit(1);
};

module.exports = { connectDB };
