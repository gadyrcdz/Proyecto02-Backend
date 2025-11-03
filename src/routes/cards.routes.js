const express = require('express');
const router = express.Router();
const cardsController = require('../controllers/cards.controller');
const { validateJWT, isAdmin } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   POST /api/v1/cards
 * @desc    Crear tarjeta
 * @access  Private (Admin only)
 */
router.post('/', cardsController.createCard);

/**
 * @route   GET /api/v1/cards
 * @desc    Listar tarjetas
 * @access  Private
 */
router.get('/', cardsController.getCards);

/**
 * @route   GET /api/v1/cards/:cardId
 * @desc    Obtener tarjeta específica
 * @access  Private
 */
router.get('/:cardId', cardsController.getCards);

/**
 * @route   GET /api/v1/cards/:cardId/movements
 * @desc    Listar movimientos de tarjeta
 * @access  Private
 */
router.get('/:cardId/movements', cardsController.getCardMovements);

/**
 * @route   POST /api/v1/cards/:cardId/movements
 * @desc    Agregar movimiento a tarjeta
 * @access  Private (Admin only)
 */
router.post('/:cardId/movements', isAdmin, cardsController.addCardMovement);

/**
 * @route   POST /api/v1/cards/:cardId/otp
 * @desc    Generar OTP para ver PIN/CVV
 * @access  Private
 */
router.post('/:cardId/otp', cardsController.generateOTP);

/**
 * @route   POST /api/v1/cards/:cardId/view-details
 * @desc    Ver detalles sensibles (PIN/CVV) con OTP
 * @access  Private
 */
router.post('/:cardId/view-details', cardsController.viewCardDetails);

module.exports = router;