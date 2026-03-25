const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// Configuración de Cloudinary (Usa credenciales del .env)
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'demo',
  api_key: process.env.CLOUDINARY_API_KEY || '1234567890',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'abcdefghijk'
});

// Configuración de almacenamiento optimizada para diferentes tipos de archivos
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    // Determinar el tipo de recurso basado en el archivo
    let resourceType = 'image';
    let folder = 'musicapp_valledupar/images';
    
    const fileExtension = file.originalname.toLowerCase().split('.').pop();
    
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(fileExtension)) {
      resourceType = 'video';
      folder = 'musicapp_valledupar/videos';
    } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].includes(fileExtension)) {
      resourceType = 'video'; // Cloudinary trata los audios como video
      folder = 'musicapp_valledupar/audios';
    }

    // Generar nombre de archivo único con timestamp y tipo
    const timestamp = Date.now();
    const originalName = file.originalname.split('.')[0].replace(/[^a-zA-Z0-9]/g, '_');
    const uniqueFilename = `${timestamp}_${originalName}`;

    return {
      folder,
      allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'avi', 'mkv', 'webm', 'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'],
      resource_type: resourceType,
      public_id: uniqueFilename,
      // Configuraciones específicas para cada tipo
      transformation: resourceType === 'image' ? [
        { width: 1200, height: 1200, crop: 'limit', quality: 'auto' },
        { fetch_format: 'auto' }
      ] : resourceType === 'video' ? [
        { quality: 'auto' }
      ] : [], // Para audios no aplicamos transformaciones
    };
  },
});

// Middleware de upload con configuraciones mejoradas
const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 100 * 1024 * 1024, // 100 MB para videos más largos
    files: 10 // Máximo 10 archivos (ajustable)
  },
  fileFilter: (req, file, cb) => {
    // Validar tipos de archivo permitidos
    const allowedTypes = [
      // Imágenes
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
      'image/svg+xml',
      // Videos
      'video/mp4',
      'video/quicktime',
      'video/x-msvideo',
      'video/x-matroska',
      'video/webm',
      'video/3gpp',
      'video/mpeg',
      'video/x-flv',
      // Audios
      'audio/mpeg',
      'audio/wav',
      'audio/aac',
      'audio/mp4',
      'audio/ogg',
      'audio/flac'
    ];

    const fileExtension = file.originalname.toLowerCase().split('.').pop();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'flv', 'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'];

    if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(fileExtension)) {
      cb(null, true);
    } else {
      cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}. Extensiones permitidas: ${allowedExtensions.join(', ')}`), false);
    }
  }
});

// Middleware para procesar metadatos después de la subida
const processUploadedFiles = (req, res, next) => {
  if (!req.files || req.files.length === 0) {
    return next();
  }

  // Agregar metadatos adicionales a cada archivo
  req.files = req.files.map((file, index) => {
    // Extraer información del filename de Cloudinary
    const filename = file.filename || file.public_id;
    const parts = filename.split('/');
    const nameWithExtension = parts[parts.length - 1];
    
    return {
      ...file,
      // Metadatos adicionales
      filename: nameWithExtension,
      public_id: file.public_id || nameWithExtension,
      // Intentar extraer dimensiones para imágenes (si Cloudinary las proporciona)
      width: file.width || null,
      height: file.height || null,
      duration: file.duration || null,
      size: file.size || 0,
      thumbnail: file.thumbnail || null,
      // Orden en el array
      order: index
    };
  });

  next();
};

module.exports = {
  upload,
  processUploadedFiles
};
