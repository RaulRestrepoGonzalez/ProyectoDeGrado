const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists (backend/uploads)
const uploadPath = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

// Configuración de almacenamiento local
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    const originalName = file.originalname.split('.')[0].replace(/[^a-zA-Z0-9]/g, '_');
    const extension = file.originalname.split('.').pop();
    const uniqueFilename = `${timestamp}_${originalName}.${extension}`;
    cb(null, uniqueFilename);
  }
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
      'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
      // Videos
      'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska', 'video/webm', 'video/3gpp', 'video/mpeg', 'video/x-flv',
      // Audios
      'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/mp4', 'audio/ogg', 'audio/flac'
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
  const host = req.get('host');
  // req.protocol puede ser http o HTTPS. Detrás de un proxy/Render usa https si X-Forwarded-Proto está configurado (app.set('trust proxy', 1) ya lo maneja)
  const protocol = req.headers['x-forwarded-proto'] || req.protocol;

  if (req.file) {
    const filename = req.file.filename;
    req.file.url = `${protocol}://${host}/uploads/${filename}`;
  }

  if (req.files && req.files.length > 0) {
    req.files = req.files.map((file, index) => {
      const filename = file.filename;
      const url = `${protocol}://${host}/uploads/${filename}`;
      
      return {
        ...file,
        url,
        // Metadatos adicionales
        public_id: filename,
        size: file.size || 0,
        // Orden en el array
        order: index
      };
    });
  }

  next();
};

module.exports = {
  upload,
  processUploadedFiles
};
