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
  const opts = { serverSelectionTimeoutMS: 5000, connectTimeoutMS: 5000, socketTimeoutMS: 45000 };

  for (let i = 0; i < candidates.length; i++) {
    const uri = candidates[i];
    let attempt = 0;
    const maxAttempts = 4;
    while (attempt < maxAttempts) {
      try {
        console.log(`Intentando conectar a MongoDB (candidato ${i + 1}/${candidates.length}, intento ${attempt + 1}/${maxAttempts}): ${uri}`);
        const connection = await tryConnect(uri, opts);
        const dbName = connection.connection.db.databaseName || DEFAULT_DB_NAME;

        try {
          await connection.connection.db.createCollection('usuarios');
          console.log(`Base de datos '${dbName}' inicializada correctamente (si no existía).`);
        } catch (e) {
          if (e && e.code === 48) {
            // colección ya existe
          } else if (e) {
            console.warn(`Aviso durante verificación de DB '${dbName}':`, e.message || e);
          }
        }

        console.log(`MongoDB conectada exitosamente: ${connection.connection.host} (DB: ${dbName})`);
        mongoose.connection.on('error', (err) => {
          console.error('Error post-conexión MongoDB:', err);
        });
        return; // conectado con éxito
      } catch (err) {
        console.warn(`No se pudo conectar a ${uri} (intento ${attempt + 1}): ${err.message}`);
        attempt += 1;
        // backoff exponencial con jitter
        const base = 500; // ms
        const delay = Math.min(8000, base * Math.pow(2, attempt)) + Math.floor(Math.random() * 200);
        await new Promise(res => setTimeout(res, delay));
      }
    }
  }

  console.error('Fallaron todas las tentativas de conexión a MongoDB. Revise MONGODB_URI / MONGO_HOST(S) y la accesibilidad de red.');
  process.exit(1);
};

module.exports = { connectDB };
