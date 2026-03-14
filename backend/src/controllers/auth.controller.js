const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

const Usuario = require('../models/Usuario');

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET no está configurado. Define esta variable de entorno para seguridad.');
  }
  return secret;
};

const register = async (req, res, next) => {
  try {
    const { email, password, nombre, rol } = req.body;

    const existing = await Usuario.findOne({ email }).lean();
    if (existing) {
      return res.status(409).json({ message: 'Usuario ya registrado.' });
    }

    const hashed = await bcrypt.hash(password, 12);
    const user = await Usuario.create({
      email,
      password: hashed,
      nombre: nombre || 'Sin nombre',
      rol: rol === 'agrupacion' ? 'agrupacion' : 'musico',
    });

    return res.status(201).json({
      message: 'Usuario registrado correctamente.',
      user: { id: user._id, email: user.email, rol: user.rol },
    });
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

    const user = await Usuario.findOne({ email }).select('+password').lean();
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

module.exports = { register, login, me, refresh, logout };
