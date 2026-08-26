const { Router } = require('express');
const { body, oneOf } = require('express-validator');
const {
  login,
  register,
  me,
  refresh,
  logout,
  requestPasswordRecovery,
  resetPassword,
} = require('../controllers/auth.controller');
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

const recoveryLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { message: 'Demasiadas solicitudes. Inténtalo de nuevo más tarde.' },
  standardHeaders: true,
  legacyHeaders: false,
});

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
    body('telefono').matches(/^\+?[0-9]{7,15}$/).withMessage('Debes registrar un WhatsApp válido con código de país.'),
    body('rol').optional().isIn(['compañia', 'independiente', 'artista']).withMessage('Rol inválido.'),
  ],
  validateRequest,
  register,
);

router.post(
  '/recovery/request',
  recoveryLimiter,
  oneOf([
    body('identifier').isString().trim().isLength({ min: 6, max: 120 }),
    body('telefono').matches(/^\+?[0-9]{7,15}$/),
  ], { message: 'Ingresa un correo o WhatsApp válido.' }),
  validateRequest,
  requestPasswordRecovery,
);

router.post(
  '/recovery/reset',
  recoveryLimiter,
  [
    oneOf([
      body('identifier').isString().trim().isLength({ min: 6, max: 120 }),
      body('telefono').matches(/^\+?[0-9]{7,15}$/),
    ], { message: 'Ingresa un correo o WhatsApp válido.' }),
    body('codigo').matches(/^\d{6}$/).withMessage('El código debe tener 6 dígitos.'),
    body('newPassword')
      .isStrongPassword({ minLength: 8, minLowercase: 1, minUppercase: 1, minNumbers: 1, minSymbols: 1 })
      .withMessage('La contraseña debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos.'),
  ],
  validateRequest,
  resetPassword,
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
