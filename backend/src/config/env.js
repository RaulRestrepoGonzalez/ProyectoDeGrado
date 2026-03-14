const requiredEnvVars = [
  'MONGODB_URI',
  'JWT_SECRET',
  'PORT',
  'CLIENT_ORIGIN',
];

function validateEnv() {
  const missing = requiredEnvVars.filter((key) => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `Faltan variables de entorno obligatorias: ${missing.join(', ')}. ` +
        'Crea un archivo .env basado en .env.example y agrega los valores necesarios.',
    );
  }

  if ((process.env.NODE_ENV || 'development') === 'production' && !process.env.FORCE_INSECURE) {
    if (!process.env.ENABLE_HTTPS) {
      console.warn(
        'Advertencia: en producción se recomienda habilitar HTTPS y configurar correctamente los certificados. ' +
          'Establece ENABLE_HTTPS=1 y configura un proxy inverso seguro.',
      );
    }
  }
}

module.exports = { validateEnv };
