const multer = require('multer');
const path = require('path');
const fs = require('fs');
const ffprobeStatic = require('ffprobe-static');
const ffmpeg = require('fluent-ffmpeg');
const { MongoClient, GridFSBucket, ObjectId } = require('mongodb');

ffmpeg.setFfprobePath(ffprobeStatic.path);

// Configuración con fallback a almacenamiento local
let gridFSBucket = null;
let mongoClient = null;

// Inicializar GridFS cuando el servidor inicia
async function initializeGridFS() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/soundupar_db';
    console.log('📡 Intentando conectar a MongoDB para GridFS...');
    console.log('   URI:', mongoUri.substring(0, 50) + '...');
    
    mongoClient = new MongoClient(mongoUri);
    await mongoClient.connect();
    
    const db = mongoClient.db();
    gridFSBucket = new GridFSBucket(db);
    
    console.log('✅ GridFS inicializado correctamente con MongoDB');
    console.log('   Bucket disponible para almacenamiento de archivos');
    return true;
  } catch (error) {
    console.error('❌ Error al inicializar GridFS:', error.message);
    console.warn('⚠️  ADVERTENCIA: GridFS no disponible. Usando almacenamiento local (efímero en Render)');
    gridFSBucket = null;
    mongoClient = null;
    return false;
  }
}

// Exportar función de inicialización para llamar en server.js
module.exports.initializeGridFS = initializeGridFS;

// Configurar multer con almacenamiento temporal en disco para archivos pesados
const tmpUploadDir = path.join(__dirname, '../../tmp');
if (!fs.existsSync(tmpUploadDir)) {
  fs.mkdirSync(tmpUploadDir, { recursive: true });
}

const VIDEO_DURATION_LIMIT_SECONDS = 10 * 60; // 10 minutos
const MAX_UPLOAD_SIZE_BYTES = 1024 * 1024 * 1024; // 1 GB

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, tmpUploadDir),
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${timestamp}_${Math.round(Math.random() * 1e9)}_${safeName}`);
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: MAX_UPLOAD_SIZE_BYTES,
    files: 5,
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

  const getFileStream = (file) => {
    if (file.path) {
      return fs.createReadStream(file.path);
    }
    if (file.buffer) {
      const { Readable } = require('stream');
      return Readable.from(file.buffer);
    }
    throw new Error('No se encontró el contenido del archivo subido.');
  };

  const cleanupTempFile = (file) => {
    if (file.path) {
      fs.unlink(file.path, () => {});
    }
  };

  const getVideoDuration = (file) => {
    return new Promise((resolve, reject) => {
      const filePath = file.path;
      if (!filePath) {
        return resolve(null);
      }

      ffmpeg.ffprobe(filePath, (err, metadata) => {
        if (err) {
          return reject(err);
        }

        const stream = metadata.streams.find((s) => s.codec_type === 'video');
        const duration = stream?.duration || metadata.format?.duration || 0;
        resolve(Number(duration));
      });
    });
  };

  const validateFile = async (file) => {
    if (!file || !file.originalname || (!file.buffer && !file.path)) {
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

    const shouldProbeDuration =
      (file.mimetype && file.mimetype.startsWith('video/')) ||
      (file.mimetype && file.mimetype.startsWith('audio/'));

    if (shouldProbeDuration) {
      const duration = await getVideoDuration(file);
      if (duration !== null && !Number.isNaN(duration)) {
        file.duration = Math.round(duration);
      }

      if (file.mimetype.startsWith('video/') && duration > VIDEO_DURATION_LIMIT_SECONDS) {
        const error = new Error(`El video excede el tiempo máximo de ${VIDEO_DURATION_LIMIT_SECONDS / 60} minutos.`);
        error.code = 'VIDEO_DURATION_EXCEEDED';
        throw error;
      }
    }
  };

  try {
    // Si no hay archivos, continuar
    if (!req.file && (!req.files || req.files.length === 0)) {
      return next();
    }

    // Verificar disponibilidad de GridFS con verificación más robusta
    const canUseGridFS = gridFSBucket && gridFSBucket.s && gridFSBucket.s.db && mongoClient && mongoClient.topology && mongoClient.topology.isConnected();
    
    console.log(`📁 Procesando archivos...`);
    console.log(`   Archivo(s): ${req.file ? '1' : (req.files ? req.files.length : 0)}`);
    console.log(`   GridFS disponible: ${canUseGridFS ? '✅ SI' : '❌ NO'}`);

    // Si se requiere almacenamiento en la nube, rechazar si GridFS no está disponible
    if (!canUseGridFS && process.env.REQUIRE_CLOUD_STORAGE === 'true') {
      console.error('❌ GridFS no disponible y REQUIRE_CLOUD_STORAGE=true — rechazando subida');
      return res.status(503).json({
        status: 'error',
        message: 'Almacenamiento en la nube no disponible. Reintenta más tarde o contacta al administrador.',
      });
    }

    if (!canUseGridFS) {
      console.warn('⚠️  GridFS no disponible en este momento. Usando almacenamiento local.');
    }

    // Procesar archivo único (si existe)
    if (req.file && !req.files) {
      await validateFile(req.file);

      if (canUseGridFS) {
        // Guardar en GridFS (asegurando que el ID usado corresponde al archivo almacenado)
        const fileId = new ObjectId();
        console.log(`📤 Subiendo archivo único a GridFS: ${req.file.originalname} (${req.file.size} bytes) con ID provisional ${fileId}`);

        await new Promise((resolve, reject) => {
          const uploadStream = gridFSBucket.openUploadStreamWithId(fileId, req.file.originalname, {
            metadata: {
              originalname: req.file.originalname,
              mimetype: req.file.mimetype,
              size: req.file.size,
              uploadedAt: new Date(),
            }
          });

          uploadStream.on('error', (err) => {
            console.error('❌ Error en uploadStream:', err.message);
            reject(err);
          });

          uploadStream.on('finish', () => {
            // uploadStream.id === fileId
            console.log(`✅ Archivo guardado en GridFS con ID: ${uploadStream.id}`);
            req.file.fileId = uploadStream.id;
            req.file.url = `${protocol}://${host}/api/files/download/${uploadStream.id}`;
            req.file.public_id = uploadStream.id.toString();
            req.file.size = req.file.size || 0;
            req.file.duration = req.file.duration || null;

            cleanupTempFile(req.file);
            resolve();
          });

          getFileStream(req.file).pipe(uploadStream);
        });

        return next();
      } else {
        // Fallback: almacenamiento local
        console.log(`💾 Usando almacenamiento local para: ${req.file.originalname}`);
        const uploadPath = path.join(__dirname, '../../uploads');
        if (!fs.existsSync(uploadPath)) {
          fs.mkdirSync(uploadPath, { recursive: true });
        }

        const timestamp = Date.now();
        const fileName = `${timestamp}_${req.file.originalname}`;
        const filePath = path.join(uploadPath, fileName);

        if (req.file.path) {
          fs.copyFileSync(req.file.path, filePath);
          cleanupTempFile(req.file);
        } else {
          fs.writeFileSync(filePath, req.file.buffer);
        }

        req.file.filename = fileName;
        req.file.url = `${protocol}://${host}/uploads/${fileName}`;
        req.file.public_id = fileName;

        console.warn(`⚠️  ARCHIVO EN ALMACENAMIENTO LOCAL (EFÍMERO): ${fileName}`);
        return next();
      }
    }

    // Procesar múltiples archivos (array)
    if (req.files && req.files.length > 0) {
      console.log(`📤 Procesando ${req.files.length} archivo(s)...`);
      
      if (canUseGridFS) {
        // Guardar todos en GridFS
        const processedFiles = [];

        for (let index = 0; index < req.files.length; index++) {
          const file = req.files[index];
          await validateFile(file);

          const fileId = new ObjectId();
          console.log(`   [${index + 1}/${req.files.length}] Subiendo: ${file.originalname} (${file.size} bytes) con ID ${fileId}`);

          await new Promise((resolve, reject) => {
            const uploadStream = gridFSBucket.openUploadStreamWithId(fileId, file.originalname, {
              metadata: {
                originalname: file.originalname,
                mimetype: file.mimetype,
                size: file.size,
                uploadedAt: new Date(),
              }
            });

            uploadStream.on('error', (err) => {
              console.error(`❌ Error subiendo archivo ${file.originalname}:`, err.message);
              reject(err);
            });

            uploadStream.on('finish', () => {
              console.log(`   ✅ Guardado en GridFS: ${file.originalname} (ID: ${uploadStream.id})`);
              const processedFile = {
                ...file,
                fileId: uploadStream.id,
                url: `${protocol}://${host}/api/files/download/${uploadStream.id}`,
                public_id: uploadStream.id.toString(),
                size: file.size,
                duration: file.duration || null,
                order: index,
              };
              processedFiles.push(processedFile);
              cleanupTempFile(file);
              resolve();
            });

            getFileStream(file).pipe(uploadStream);
          });
        }

        req.files = processedFiles;
        console.log(`✅ Todos los ${processedFiles.length} archivo(s) procesados exitosamente en GridFS`);
        return next();
      } else {
        // Fallback: almacenamiento local
        console.warn(`💾 Usando almacenamiento local para ${req.files.length} archivo(s)`);
        const uploadPath = path.join(__dirname, '../../uploads');
        if (!fs.existsSync(uploadPath)) {
          fs.mkdirSync(uploadPath, { recursive: true });
        }

        const processedFiles = [];
        for (let index = 0; index < req.files.length; index++) {
          const file = req.files[index];
          await validateFile(file);

          const timestamp = Date.now();
          const fileName = `${timestamp}_${index}_${file.originalname}`;
          const filePath = path.join(uploadPath, fileName);

          if (file.path) {
            fs.copyFileSync(file.path, filePath);
            fs.unlink(file.path, () => {});
          } else {
            fs.writeFileSync(filePath, file.buffer);
          }

          console.warn(`⚠️  ARCHIVO LOCAL EFÍMERO [${index + 1}]: ${fileName}`);

          processedFiles.push({
            ...file,
            filename: fileName,
            url: `${protocol}://${host}/uploads/${fileName}`,
            public_id: fileName,
            size: file.size,
            order: index,
          });
        }

        req.files = processedFiles;
        console.warn(`⚠️  ${req.files.length} archivo(s) almacenados localmente. Se perderán en el próximo redeploy de Render.`);
        return next();
      }
    }

    next();
  } catch (error) {
    console.error('❌ Error en processUploadedFiles:', error.message);
    console.error('   Stack:', error.stack);
    return res.status(400).json({
      status: 'error',
      message: error.message || 'Error al procesar el archivo subido.',
    });
  }
};

module.exports = {
  upload,
  processUploadedFiles,
  initializeGridFS,
  getGridFSBucket: () => gridFSBucket,
};

