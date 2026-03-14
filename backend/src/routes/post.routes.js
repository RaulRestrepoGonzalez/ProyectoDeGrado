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

const upload = require('../middleware/upload');

router.post(
  '/',
  upload.array('evidencias', 5), // Hasta 5 archivos adjuntos
  [
    body('contenido')
      .notEmpty()
      .withMessage('El contenido no puede estar vacío.')
      .isLength({ max: 1000 })
      .withMessage('Max 1000 caracteres.'),
    body('tipoPost')
      .optional()
      .isIn(['BUSCANDO_PERSONAL', 'BUSCANDO_OPORTUNIDAD', 'GENERAL']),
    body('vacantes')
      .optional()
      .isNumeric(),
    body('precio')
      .optional()
      .isNumeric(),
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
  [body('texto').notEmpty().withMessage('El comentario no puede estar vacío.')],
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
    body('comentariosOpcionales').optional().isString(),
  ],
  validateRequest,
  postController.denunciarPublicacion
);

module.exports = router;
