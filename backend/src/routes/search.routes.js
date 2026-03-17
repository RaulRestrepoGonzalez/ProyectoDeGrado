const { Router } = require('express');
const searchController = require('../controllers/search.controller');
const { authenticate } = require('../middleware/auth');

const router = Router();

// Búsqueda global (requiere estar autenticado)
router.get('/', authenticate, searchController.searchAll);

module.exports = router;
