const { Router } = require('express');

const authRoutes = require('./auth.routes');
const postRoutes = require('./post.routes');
const userRoutes = require('./user.routes');
const walletRoutes = require('./wallet.routes');
const { authenticate } = require('../middleware/auth');

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'MusicApp Valledupar API' });
});

router.get('/protected', authenticate, (req, res) => {
  res.json({ message: 'Acceso autorizado', user: req.user });
});

router.use('/auth', authRoutes);
router.use('/posts', postRoutes);
router.use('/users', userRoutes);
router.use('/wallet', walletRoutes);

module.exports = router;

