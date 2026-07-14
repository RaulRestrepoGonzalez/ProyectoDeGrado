const express = require('express');
const { ObjectId } = require('mongodb');
const router = express.Router();

// Middleware para obtener GridFS
const getGridFS = () => {
  const uploadMiddleware = require('../middleware/upload');
  return uploadMiddleware.getGridFSBucket();
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

    // Buscar metadata del archivo en GridFS
    const filesColl = gridFSBucket.s.db.collection('fs.files');
    const fileDoc = await filesColl.findOne({ _id: new ObjectId(fileId) });

    if (!fileDoc) {
      return res.status(404).json({ error: 'Archivo no encontrado' });
    }

    const fileSize = fileDoc.length;
    const contentType = (fileDoc.metadata && fileDoc.metadata.mimetype) ? fileDoc.metadata.mimetype : 'application/octet-stream';

    // Soportar solicitudes con Range para reproductores como ExoPlayer
    const range = req.headers.range;
    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10) || 0;
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;

      if (start >= fileSize || end >= fileSize) {
        res.status(416).set('Content-Range', `bytes */${fileSize}`);
        return res.end();
      }

      const chunkSize = (end - start) + 1;
      res.status(206);
      res.set({
        'Content-Range': `bytes ${start}-${end}/${fileSize}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunkSize,
        'Content-Type': contentType,
      });

      const downloadStream = gridFSBucket.openDownloadStream(new ObjectId(fileId), { start, end });
      downloadStream.on('error', (err) => {
        console.error('Error en descarga parcial GridFS:', err);
        res.status(500).end();
      });
      return downloadStream.pipe(res);
    }

    // Respuesta completa
    res.set({
      'Content-Type': contentType,
      'Content-Length': fileSize,
      'Accept-Ranges': 'bytes',
    });

    const stream = gridFSBucket.openDownloadStream(new ObjectId(fileId));
    stream.on('error', (err) => {
      console.error('Error en descarga GridFS:', err);
      return res.status(500).json({ error: 'Error al descargar el archivo' });
    });
    stream.pipe(res);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
