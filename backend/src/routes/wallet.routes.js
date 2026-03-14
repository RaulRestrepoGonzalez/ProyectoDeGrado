const { Router } = require('express');
const { obtenerCartera, comprarTokens } = require('../controllers/wallet.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();

router.use(authenticate);

router.get('/me', obtenerCartera);
router.post('/comprar', comprarTokens);

module.exports = router;
