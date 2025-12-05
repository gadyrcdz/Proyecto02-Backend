// routes/catalog.routes.js - Rutas de catálogos

const express = require('express');
const router = express.Router();
const catalogController = require('../controllers/catalogController');
const authMiddleware = require('../middleware/authMiddleware');

/**
 * Todas las rutas de catálogo requieren autenticación
 */

// Obtener todos los catálogos a la vez
router.get('/catalog/all', authMiddleware, catalogController.getAllCatalogs);

// Tipos de cuenta
router.get('/catalog/account-types', authMiddleware, catalogController.getAccountTypes);

// Monedas
router.get('/catalog/currencies', authMiddleware, catalogController.getCurrencies);

// Tipos de tarjeta
router.get('/catalog/card-types', authMiddleware, catalogController.getCardTypes);

// Estados de cuenta
router.get('/catalog/account-statuses', authMiddleware, catalogController.getAccountStatuses);

// Tipos de movimiento
router.get('/catalog/movement-types', authMiddleware, catalogController.getMovementTypes);

// Tipos de identificación
router.get('/catalog/id-types', authMiddleware, catalogController.getIdTypes);

module.exports = router;