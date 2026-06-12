const cloudinary = require('cloudinary').v2;

// Configurar Cloudinary con variables de entorno
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Validar que las credenciales estén configuradas
if (!process.env.CLOUDINARY_CLOUD_NAME) {
  console.warn('⚠️  CLOUDINARY_CLOUD_NAME no está configurado. Los archivos se guardarán localmente.');
}

module.exports = cloudinary;
