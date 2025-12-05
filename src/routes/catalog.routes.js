// routes/catalog.routes.js - Rutas de catálogos

const express = require('express');
const router = express.Router();
const catalogController = require('../controllers/catalogController');


/**
 * Todas las rutas de catálogo requieren autenticación
 */

router.get('/catalog/all', catalogController.getAllCatalogs);

// Tipos de cuenta
router.get('/catalog/account-types', catalogController.getAccountTypes);

// Monedas
router.get('/catalog/currencies', catalogController.getCurrencies);

// Tipos de tarjeta
router.get('/catalog/card-types', catalogController.getCardTypes);

// Estados de cuenta
router.get('/catalog/account-statuses', catalogController.getAccountStatuses);

// Tipos de movimiento
router.get('/catalog/movement-types', catalogController.getMovementTypes);

// Tipos de identificación
router.get('/catalog/id-types', catalogController.getIdTypes);

module.exports = router;