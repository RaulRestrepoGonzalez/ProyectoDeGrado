const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Token de acceso faltante.' });
  }

  const token = authHeader.split(' ')[1];
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    return res.status(500).json({ message: 'JWT_SECRET no configurado en el servidor.' });
  }

  try {
    const payload = jwt.verify(token, secret);
    // Asignamos el payload entero a req.user, pero también garantizamos que req.user.id exista
    req.user = payload;
    req.user.id = payload.userId || payload._id; 
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token inválido o expirado.' });
  }
};

module.exports = { authenticate };
