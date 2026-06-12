const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { MongoClient, GridFSBucket, ObjectId } = require('mongodb');

// Configuración con fallback a almacenamiento local
let gridFSBucket = null;
let mongoClient = null;

// Inicializar GridFS cuando el servidor inicia
async function initializeGridFS() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/soundupar_db';
    mongoClient = new MongoClient(mongoUri);
    await mongoClient.connect();
    
    const db = mongoClient.db();
    gridFSBucket = new GridFSBucket(db);
    console.log('✅ GridFS inicializado correctamente con MongoDB');
  } catch (error) {
    console.warn('⚠️  No se pudo inicializar GridFS. Usando almacenamiento local:', error.message);
    gridFSBucket = null;
  }
}

// Exportar función de inicialización para llamar en server.js
module.exports.initializeGridFS = initializeGridFS;

// Configurar multer con almacenamiento en memoria
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB para videos
    files: 10
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
      'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska', 'video/webm', 'video/3gpp', 'video/mpeg', 'video/x-flv',
      'audio/mpeg', 'audio/wav', 'audio/aac', 'audio/mp4', 'audio/ogg', 'audio/flac'
    ];

    const fileExtension = file.originalname.toLowerCase().split('.').pop();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'flv', 'mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'];

    if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(fileExtension)) {
      cb(null, true);
    } else {
      cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}`), false);
    }
  }
});

// Middleware para guardar archivos en GridFS o almacenamiento local
const processUploadedFiles = async (req, res, next) => {
  const host = req.get('host');
  const protocol = req.headers['x-forwarded-proto'] || req.protocol;

  const validateFile = (file) => {
    if (!file || !file.originalname || !file.buffer) {
      throw new Error('Archivo subido inválido.');
    }

    if (file.size === undefined || file.size === null || file.size <= 0) {
      throw new Error('El archivo subido está vacío.');
    }

    const extension = file.originalname.toLowerCase().split('.').pop();
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'flv'];

    if (file.mimetype && file.mimetype.startsWith('video/') && !videoExtensions.includes(extension)) {
      throw new Error(`Formato de video no válido: .${extension}`);
    }
  };

  try {
    // Procesar archivo único
    if (req.file) {
      validateFile(req.file);
      
      if (gridFSBucket) {
        // Guardar en GridFS
        const fileId = new ObjectId();
        const uploadStream = gridFSBucket.openUploadStream(req.file.originalname, {
          metadata: {
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
            uploadedAt: new Date(),
          }
        });

        return new Promise((resolve, reject) => {
          uploadStream.on('error', reject);
          uploadStream.on('finish', () => {
            req.file.fileId = fileId;
            req.file.url = `${protocol}://${host}/api/files/download/${fileId}`;
            req.file.public_id = fileId.toString();
            next();
            resolve();
          });
          uploadStream.end(req.file.buffer);
        });
      } else {
        // Fallback: almacenamiento local
        const uploadPath = path.join(__dirname, '../../uploads');
        if (!fs.existsSync(uploadPath)) {
          fs.mkdirSync(uploadPath, { recursive: true });
        }

        const timestamp = Date.now();
        const fileName = `${timestamp}_${req.file.originalname}`;
        const filePath = path.join(uploadPath, fileName);

        fs.writeFileSync(filePath, req.file.buffer);

        req.file.filename = fileName;
        req.file.url = `${protocol}://${host}/uploads/${fileName}`;
        req.file.public_id = fileName;
        next();
      }
    } else if (req.files && req.files.length > 0) {
      // Procesar múltiples archivos
      if (gridFSBucket) {
        // Guardar todos en GridFS
        const filePromises = req.files.map((file, index) => {
          validateFile(file);
          return new Promise((resolve, reject) => {
            const fileId = new ObjectId();
            const uploadStream = gridFSBucket.openUploadStream(file.originalname, {
              metadata: {
                originalname: file.originalname,
                mimetype: file.mimetype,
                size: file.size,
                uploadedAt: new Date(),
              }
            });

            uploadStream.on('error', reject);
            uploadStream.on('finish', () => {
              resolve({
                ...file,
                fileId: fileId,
                url: `${protocol}://${host}/api/files/download/${fileId}`,
                public_id: fileId.toString(),
                size: file.size,
                order: index,
              });
            });
            uploadStream.end(file.buffer);
          });
        });

        Promise.all(filePromises)
          .then(processedFiles => {
            req.files = processedFiles;
            next();
          })
          .catch(error => {
            throw error;
          });
      } else {
        // Fallback: almacenamiento local
        const uploadPath = path.join(__dirname, '../../uploads');
        if (!fs.existsSync(uploadPath)) {
          fs.mkdirSync(uploadPath, { recursive: true });
        }

        req.files = req.files.map((file, index) => {
          validateFile(file);

          const timestamp = Date.now();
          const fileName = `${timestamp}_${index}_${file.originalname}`;
          const filePath = path.join(uploadPath, fileName);

          fs.writeFileSync(filePath, file.buffer);

          return {
            ...file,
            filename: fileName,
            url: `${protocol}://${host}/uploads/${fileName}`,
            public_id: fileName,
            size: file.size,
            order: index,
          };
        });
        next();
      }
    } else {
      next();
    }
  } catch (error) {
    res.status(400).json({
      status: 'error',
      message: error.message || 'Error al procesar el archivo subido.',
    });
  }
};

module.exports = {
  upload,
  processUploadedFiles,
  initializeGridFS,
  gridFSBucket: () => gridFSBucket,
};

