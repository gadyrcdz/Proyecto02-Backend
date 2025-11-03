const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const { validateJWT, isAdmin } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   POST /api/v1/users
 * @desc    Crear usuario
 * @access  Private (Admin only)
 */
router.post('/',usersController.createUser);

/**
 * @route   GET /api/v1/users/:identification
 * @desc    Obtener usuario por identificación
 * @access  Private
 */
router.get('/:identification', usersController.getUserByIdentification);

/**
 * @route   PUT /api/v1/users/:id
 * @desc    Actualizar usuario
 * @access  Private (Admin only)
 */
router.put('/:id', isAdmin, usersController.updateUser);

/**
 * @route   DELETE /api/v1/users/:id
 * @desc    Eliminar usuario
 * @access  Private (Admin only)
 */
router.delete('/:id', isAdmin, usersController.deleteUser);

module.exports = router;