const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const Usuario = require('../models/Usuario');
const PasswordRecovery = require('../models/PasswordRecovery');
const { buildWhatsAppRecoveryUrl } = require('../services/whatsapp.service');

const RECOVERY_EXPIRATION_MINUTES = 10;
const RECOVERY_MAX_ATTEMPTS = 5;

const normalizePhone = (phone) => String(phone).replace(/[^\d+]/g, '').replace(/^00/, '+');

const generateRecoveryCode = () => crypto.randomInt(100000, 1000000).toString();

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET no está configurado. Define esta variable de entorno para seguridad.');
  }
  return secret;
};

const register = async (req, res, next) => {
  try {
    const { email, password, nombre, rol, telefono } = req.body;
    const normalizedEmail = String(email).trim().toLowerCase();

    const existing = await Usuario.findOne({ email: normalizedEmail }).lean();
    if (existing) {
      return res.status(409).json({ message: 'Usuario ya registrado.' });
    }

    const hashed = await bcrypt.hash(password, 12);
    const user = await Usuario.create({
      email: normalizedEmail,
      password: hashed,
      nombre: nombre || 'Sin nombre',
      rol: rol || 'artista',
      telefono: telefono ? normalizePhone(telefono) : null,
    });

    return res.status(201).json({
      message: 'Usuario registrado correctamente.',
      user: { id: user._id, email: user.email, rol: user.rol },
    });
  } catch (error) {
    next(error);
  }
};

const requestPasswordRecovery = async (req, res, next) => {
  try {
    const identifier = String(req.body.identifier || req.body.telefono || '').trim();
    const isEmail = identifier.includes('@');
    const lookup = isEmail
      ? { email: identifier.toLowerCase() }
      : { telefono: normalizePhone(identifier) };
    const user = await Usuario.findOne(lookup).select('_id telefono').lean();

    if (!user) {
      return res.status(404).json({ message: 'No encontramos una cuenta con ese correo o WhatsApp.' });
    }

    if (!user.telefono) {
      return res.status(409).json({
        message: 'Esta cuenta no tiene un WhatsApp registrado. Inicia sesión y agrégalo en Editar perfil para poder recuperar tu contraseña.',
      });
    }

    const telefono = user.telefono;
    const code = generateRecoveryCode();
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    await PasswordRecovery.findOneAndUpdate(
      { telefono },
      {
        telefono,
        userId: user._id,
        codeHash,
        attempts: 0,
        expiresAt: new Date(Date.now() + RECOVERY_EXPIRATION_MINUTES * 60 * 1000),
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
    return res.json({
      message: 'Se abrió WhatsApp con tu código. Cópialo y regresa a la aplicación.',
      whatsappUrl: buildWhatsAppRecoveryUrl(telefono, code),
    });
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const identifier = String(req.body.identifier || req.body.telefono || '').trim();
    let telefono = identifier;
    if (identifier.includes('@')) {
      const user = await Usuario.findOne({ email: identifier.toLowerCase() }).select('telefono').lean();
      telefono = user?.telefono || '';
    } else {
      telefono = normalizePhone(identifier);
    }
    const codeHash = crypto.createHash('sha256').update(req.body.codigo).digest('hex');
    const recovery = await PasswordRecovery.findOne({ telefono });

    if (!recovery || recovery.expiresAt <= new Date() || recovery.attempts >= RECOVERY_MAX_ATTEMPTS) {
      return res.status(400).json({ message: 'El código es inválido o ha expirado.' });
    }

    if (recovery.codeHash !== codeHash) {
      await PasswordRecovery.findByIdAndUpdate(recovery._id, { $inc: { attempts: 1 } });
      return res.status(400).json({ message: 'El código es inválido o ha expirado.' });
    }

    const consumedRecovery = await PasswordRecovery.findOneAndDelete({
      _id: recovery._id,
      codeHash,
      attempts: { $lt: RECOVERY_MAX_ATTEMPTS },
      expiresAt: { $gt: new Date() },
    });

    if (!consumedRecovery) {
      return res.status(400).json({ message: 'El código es inválido o ha expirado.' });
    }

    const password = await bcrypt.hash(req.body.newPassword, 12);
    await Usuario.findByIdAndUpdate(consumedRecovery.userId, { password, refreshToken: null });

    return res.json({ message: 'Contraseña actualizada correctamente.' });
  } catch (error) {
    next(error);
  }
};

const me = async (req, res) => {
  // El middleware de autenticación ya parseó y validó el token.
  const user = req.user;

  return res.json({
    message: 'Usuario autenticado',
    user,
  });
};

const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(401).json({ message: 'Refresh token requerido.' });
    }

    const user = await Usuario.findOne({ refreshToken });
    if (!user) {
      return res.status(401).json({ message: 'Refresh token inválido.' });
    }

    const newRefreshToken = crypto.randomBytes(40).toString('hex');
    await Usuario.findByIdAndUpdate(user._id, { refreshToken: newRefreshToken });

    const token = jwt.sign(
      { userId: user._id, email: user.email, rol: user.rol },
      getJwtSecret(),
      { expiresIn: '15m' }
    );

    return res.json({ token, refreshToken: newRefreshToken });
  } catch (error) {
    return res.status(500).json({ message: 'Error en la actualización del token.' });
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = String(email).trim().toLowerCase();

    const user = await Usuario.findOne({ email: normalizedEmail }).select('+password').lean();
    if (!user) {
      return res.status(401).json({ message: 'Credenciales inválidas.' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Credenciales inválidas.' });
    }

    const token = jwt.sign({ userId: user._id, email: user.email, rol: user.rol }, getJwtSecret(), {
      expiresIn: '15m',
    });

    const refreshToken = crypto.randomBytes(40).toString('hex');
    await Usuario.findByIdAndUpdate(user._id, { refreshToken });

    return res.json({ token, refreshToken });
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user._id; // De 'authenticate' middleware
    await Usuario.findByIdAndUpdate(userId, { refreshToken: null });
    return res.json({ message: 'Sesión cerrada exitosamente.' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  me,
  refresh,
  logout,
  requestPasswordRecovery,
  resetPassword,
};
