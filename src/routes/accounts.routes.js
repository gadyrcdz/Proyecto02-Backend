const express = require('express');
const router = express.Router();
const accountsController = require('../controllers/accounts.controller');
const { validateJWT, isAdmin } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   POST /api/v1/accounts
 * @desc    Crear cuenta
 * @access  Public 
 */
router.post('/', accountsController.createAccount);

/**
 * @route   GET /api/v1/accounts
 * @desc    Listar cuentas
 * @access  Private
 */
router.get('/', accountsController.getAccountsByUser);

/**
 * @route   GET /api/v1/accounts/:accountId
 * @desc    Obtener cuenta específica
 * @access  Private
 */
router.get('/:accountId', accountsController.getAccountById);

/**
 * @route   POST /api/v1/accounts/:accountId/status
 * @desc    Cambiar estado de cuenta
 * @access  Private (Admin only)
 */
router.post('/:accountId/:status', isAdmin, accountsController.setAccountStatus);

/**
 * @route   GET /api/v1/accounts/:accountId/movements
 * @desc    Listar movimientos de cuenta
 * @access  Private
 */
router.get('/:accountId/movements', accountsController.getAccountMovements);

module.exports = router;