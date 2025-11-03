const express = require('express');
const router = express.Router();
const transfersController = require('../controllers/transfers.controller');
const { validateJWT } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   POST /api/v1/bank/validate-account
 * @desc    Validar cuenta IBAN
 * @access  Private
 */
router.post('/validate-account', transfersController.validateAccount);

module.exports = router;