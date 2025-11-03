const express = require('express');
const router = express.Router();
const auditController = require('../controllers/audit.controller');
const { validateJWT } = require('../middlewares/jwtAuth');

// Todas las rutas requieren JWT
router.use(validateJWT);

/**
 * @route   GET /api/v1/audit/:userId
 * @desc    Listar auditoría de un usuario con filtros y paginación
 * @access  Private (Admin o dueño)
 * @query   fromDate, toDate, accion, entidad, page, pageSize
 */
router.get('/:userId', auditController.getAuditByUser);

/**
 * @route   GET /api/v1/audit/:userId/summary
 * @desc    Obtener resumen de acciones por tipo
 * @access  Private (Admin o dueño)
 * @query   fromDate, toDate
 */
router.get('/:userId/summary', auditController.getActionsSummary);

/**
 * @route   GET /api/v1/audit/:userId/stats
 * @desc    Obtener estadísticas de auditoría
 * @access  Private (Admin o dueño)
 */
router.get('/:userId/stats', auditController.getAuditStats);

module.exports = router;