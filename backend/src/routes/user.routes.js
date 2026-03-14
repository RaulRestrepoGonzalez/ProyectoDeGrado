const { Router } = require('express');
const { obtenerPerfilUsuario, toggleSeguirUsuario, actualizarPerfilUsuario } = require('../controllers/user.controller');
const { authenticate } = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = Router();

router.use(authenticate);

// Endpoint para actualizar mis propios datos (con avatar opcional)
router.put('/me/perfil', upload.single('fotoPerfil'), actualizarPerfilUsuario);

router.get('/:id/perfil', obtenerPerfilUsuario);
router.post('/:id/seguir', toggleSeguirUsuario);

module.exports = router;
