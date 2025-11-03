const express = require('express');
const router = express.Router();
const transfersController = require('../controllers/transfers.controller');
const { validateJWT } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   POST /api/v1/transfers/internal
 * @desc    Realizar transferencia interna
 * @access  Private
 */
router.post('/internal', transfersController.createInternalTransfer);

module.exports = router;