const { Router } = require('express');
const { body } = require('express-validator');
const { login, register, me, refresh, logout } = require('../controllers/auth.controller');
const { validateRequest } = require('../middleware/validateRequest');
const { authenticate } = require('../middleware/auth');
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  // Límite configurable; en test aumentamos el límite para evitar falsos positivos.
  max: parseInt(process.env.RATE_LIMIT_MAX || (process.env.NODE_ENV === 'test' ? '1000' : '5'), 10),
  message: { message: 'Demasiados intentos de inicio de sesión, inténtalo de nuevo en 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const router = Router();

router.post(
  '/register',
  [
    body('email').isEmail().withMessage('Email inválido.'),
    body('password')
      .isStrongPassword({
        minLength: 8,
        minLowercase: 1,
        minUppercase: 1,
        minNumbers: 1,
        minSymbols: 1,
      })
      .withMessage('La contraseña debe tener al menos 8 caracteres, incluir números, letras (mayúsculas/minúsculas) y símbolos.'),
    body('nombre').optional().isString().trim().isLength({ min: 2 }),
    body('rol').optional().isIn(['compañia', 'independiente', 'artista']).withMessage('Rol inválido.'),
  ],
  validateRequest,
  register,
);

router.post(
  '/login',
  loginLimiter,
  [
    body('email').isEmail().withMessage('Email inválido.'),
    body('password').notEmpty().withMessage('La contraseña es obligatoria.'),
  ],
  validateRequest,
  login,
);

// Endpoints de sesión / token
router.get('/me', authenticate, me);
router.post('/refresh', refresh);
router.post('/logout', authenticate, logout);

module.exports = router;
