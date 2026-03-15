const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// Configuración de Cloudinary (Usa credenciales del .env)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'demo',
  api_key: process.env.CLOUDINARY_API_KEY || '1234567890',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'abcdefghijk'
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'musicapp_valledupar',
    allowed_formats: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'mp3', 'wav', 'aac', 'm4a'],
    resource_type: 'auto', // Permite subir imágenes, videos y audios
  },
});

const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 15 * 1024 * 1024, // Límite de 15 MB para permitir audios más largos
    files: 5 // Máximo 5 archivos
  }
});

module.exports = upload;
