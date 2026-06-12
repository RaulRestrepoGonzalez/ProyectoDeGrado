const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();

// Middleware para obtener GridFS
const getGridFS = () => {
  const uploadMiddleware = require('./upload');
  return uploadMiddleware.gridFSBucket();
};

// Descargar archivo desde GridFS
router.get('/download/:fileId', async (req, res) => {
  try {
    const { fileId } = req.params;

    if (!ObjectId.isValid(fileId)) {
      return res.status(400).json({ error: 'ID de archivo inválido' });
    }

    const gridFSBucket = getGridFS();
    if (!gridFSBucket) {
      return res.status(500).json({ error: 'GridFS no disponible' });
    }

    // Buscar archivo en GridFS
    const stream = gridFSBucket.openDownloadStream(new ObjectId(fileId));

    stream.on('error', (err) => {
      if (err.name === 'MongoServerError' && err.code === 2) {
        return res.status(404).json({ error: 'Archivo no encontrado' });
      }
      res.status(500).json({ error: 'Error al descargar el archivo' });
    });

    // Enviar archivo al cliente
    res.set('Content-Type', 'application/octet-stream');
    stream.pipe(res);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
