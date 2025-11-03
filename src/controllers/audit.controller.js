const auditService = require('../services/audit.services');
const { success, error } = require('../utils/responseHandler');

class AuditController {
    /**
     * GET /api/v1/audit/:userId
     * Listar auditoría de un usuario
     */
    async getAuditByUser(req, res) {
        try {
            const { userId } = req.params;
            const filters = req.query;

            // Validación de permisos:
            // Solo admin puede ver auditoría de cualquier usuario
            // Cliente solo puede ver su propia auditoría
            if (req.user.rol !== '609bdb9c-3df8-458c-9815-4cb993683ea7' && req.user.id !== userId) {
                return error(res, 'No tienes permiso para ver esta auditoría', 403);
            }

            const result = await auditService.getAuditByUser(userId, filters);

            return success(res, result, 'Auditoría obtenida exitosamente', 200);
        } catch (err) {
            console.error('Error al obtener auditoría:', err);

            if (err.message.includes('no existe')) {
                return error(res, 'Usuario no encontrado', 404);
            }

            return error(res, 'Error al obtener auditoría', 500);
        }
    }

    /**
     * GET /api/v1/audit/:userId/summary
     * Obtener resumen de acciones
     */
    async getActionsSummary(req, res) {
        try {
            const { userId } = req.params;
            const { fromDate, toDate } = req.query;

            // Validación de permisos
            if (req.user.rol !== '609bdb9c-3df8-458c-9815-4cb993683ea7' && req.user.id !== userId) {
                return error(res, 'No tienes permiso para ver esta información', 403);
            }

            const result = await auditService.getActionsSummary(
                userId,
                fromDate || null,
                toDate || null
            );

            return success(res, result, 'Resumen obtenido exitosamente', 200);
        } catch (err) {
            console.error('Error al obtener resumen:', err);
            return error(res, 'Error al obtener resumen', 500);
        }
    }

    /**
     * GET /api/v1/audit/:userId/stats
     * Obtener estadísticas de auditoría
     */
    async getAuditStats(req, res) {
        try {
            const { userId } = req.params;

            // Validación de permisos
            if (req.user.rol !== '609bdb9c-3df8-458c-9815-4cb993683ea7' && req.user.id !== userId) {
                return error(res, 'No tienes permiso para ver esta información', 403);
            }

            const result = await auditService.getAuditStats(userId);

            return success(res, result, 'Estadísticas obtenidas exitosamente', 200);
        } catch (err) {
            console.error('Error al obtener estadísticas:', err);
            return error(res, 'Error al obtener estadísticas', 500);
        }
    }
}

module.exports = new AuditController();