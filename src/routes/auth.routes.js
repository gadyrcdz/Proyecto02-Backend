const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const validateApiKey = require('../middlewares/apiKeyAuth');

// Todas las rutas de auth requieren API Key
router.use(validateApiKey);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Iniciar sesión
 * @access  Public (requiere API Key)
 */
router.post('/login', authController.login);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Solicitar recuperación de contraseña
 * @access  Public (requiere API Key)
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @route   POST /api/v1/auth/verify-otp
 * @desc    Verificar código OTP
 * @access  Public (requiere API Key)
 */
router.post('/verify-otp', authController.verifyOTP);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Resetear contraseña
 * @access  Public (requiere API Key)
 */
router.post('/reset-password', authController.resetPassword);

module.exports = router;