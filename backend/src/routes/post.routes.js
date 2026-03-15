const { Router } = require('express');
const { body } = require('express-validator');
const postController = require('../controllers/post.controller');
const { authenticate } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validateRequest');

const router = Router();

// Todas las rutas de posts requieren autenticación
router.use(authenticate);

// =======================
//   FEED / PUBLICACIONES
// =======================
router.get('/feed', postController.obtenerFeed);

const { upload, processUploadedFiles } = require('../middleware/upload');

router.post(
  '/',
  upload.array('evidencias', 5), // Hasta 5 archivos adjuntos
  processUploadedFiles, // Procesar metadatos de archivos
  [
    body('contenido')
      .notEmpty()
      .withMessage('El contenido no puede estar vacío.')
      .isLength({ max: 1000 })
      .withMessage('Max 1000 caracteres.')
      .trim(),
    body('tipoPost')
      .optional()
      .isIn(['BUSCANDO_PERSONAL', 'BUSCANDO_OPORTUNIDAD', 'GENERAL'])
      .withMessage('Tipo de publicación inválido.'),
    body('vacantes')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Las vacantes deben ser un número entero positivo.'),
    body('precio')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('El precio debe ser un número positivo.'),
    // Validación mejorada para audios
    body('evidencias')
      .optional()
      .custom((value) => {
        if (Array.isArray(value) && value.length > 5) {
          throw new Error('Máximo 5 archivos permitidos');
        }
        return true;
      }),
  ],
  validateRequest,
  postController.crearPublicacion
);

router.get('/:id', postController.obtenerDetallePublicacion);

// =======================
//     INTERACCIONES
// =======================
router.post('/:id/like', postController.toggleLike);
router.post('/:id/favorito', postController.toggleFavorito);

router.post(
  '/:id/comentarios',
  [body('texto').notEmpty().withMessage('El comentario no puede estar vacío.').trim()],
  validateRequest,
  postController.comentar
);

// =======================
//      MODERACIÓN
// =======================
router.post('/:id/bloquear', postController.bloquearPublicacion);

router.post(
  '/:id/denunciar',
  [
    body('motivo').isIn(['SPAM', 'OFENSIVO', 'ACOSO', 'FRAUDE', 'OTRO']).withMessage('Motivo inválido.'),
    body('comentariosOpcionales').optional().isString().trim(),
  ],
  validateRequest,
  postController.denunciarPublicacion
);

// =======================
//   BÚSQUEDA AVANZADA
// =======================
router.get('/buscar/tipo/:tipo', postController.buscarPorTipo);
router.get('/buscar/multimedia', postController.buscarConMultimedia);

module.exports = router;
