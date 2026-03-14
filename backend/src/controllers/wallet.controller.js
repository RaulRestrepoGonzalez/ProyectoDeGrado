const Usuario = require('../models/Usuario');

const PLANES = {
  basico: { tokens: 5, precio: 1.00, nombre: 'Básico' },
  pro:    { tokens: 15, precio: 3.00, nombre: 'Pro' },
};

// GET /api/wallet/me
exports.obtenerCartera = async (req, res, next) => {
  try {
    const usuario = await Usuario.findById(req.user.id)
      .select('nombre rol tokens publicacionesGratuitas');

    if (!usuario) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    res.status(200).json({
      status: 'success',
      data: {
        tokens: usuario.tokens,
        publicacionesGratuitas: usuario.publicacionesGratuitas,
        rol: usuario.rol,
        publicacionesLibresRestantes: Math.max(0, 3 - usuario.publicacionesGratuitas),
      },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/wallet/comprar
exports.comprarTokens = async (req, res, next) => {
  try {
    const { plan } = req.body; // 'basico' | 'pro'

    const planDetalle = PLANES[plan];
    if (!planDetalle) {
      return res.status(400).json({ message: 'Plan no válido. Use "basico" o "pro".' });
    }

    const usuario = await Usuario.findByIdAndUpdate(
      req.user.id,
      { $inc: { tokens: planDetalle.tokens } },
      { new: true }
    ).select('tokens publicacionesGratuitas rol');

    res.status(200).json({
      status: 'success',
      message: `¡Compraste el Plan ${planDetalle.nombre}! Se añadieron ${planDetalle.tokens} tokens.`,
      data: {
        tokens: usuario.tokens,
        publicacionesGratuitas: usuario.publicacionesGratuitas,
        publicacionesLibresRestantes: Math.max(0, 3 - usuario.publicacionesGratuitas),
      },
    });
  } catch (error) {
    next(error);
  }
};
