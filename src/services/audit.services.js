const { pool } = require('../databaseConnection/pool');

class AuditService {
    /**
     * Listar auditoría de un usuario con filtros
     */
    async getAuditByUser(userId, filters = {}) {
        try {
            const {
                fromDate = null,
                toDate = null,
                accion = null,
                entidad = null,
                page = 1,
                pageSize = 10
            } = filters;

            const result = await pool.query(
                'SELECT * FROM sp_audit_list_by_user($1, $2, $3, $4, $5, $6, $7)',
                [userId, fromDate, toDate, accion, entidad, page, pageSize]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Obtener resumen de acciones por tipo (opcional - para dashboards)
     */
    async getActionsSummary(userId, fromDate = null, toDate = null) {
        try {
            const result = await pool.query(
                'SELECT * FROM sp_audit_get_actions_summary($1, $2, $3)',
                [userId, fromDate, toDate]
            );

            return result.rows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Obtener estadísticas generales de auditoría para un usuario
     */
    async getAuditStats(userId) {
        try {
            // Total de eventos
            const totalResult = await pool.query(
                'SELECT COUNT(*) as total FROM auditoria WHERE usuario_id = $1',
                [userId]
            );

            // Último evento
            const lastEventResult = await pool.query(
                `SELECT accion, fecha 
                 FROM auditoria 
                 WHERE usuario_id = $1 
                 ORDER BY fecha DESC 
                 LIMIT 1`,
                [userId]
            );

            // Acciones más frecuentes (top 5)
            const topActionsResult = await pool.query(
                `SELECT accion, COUNT(*) as cantidad
                 FROM auditoria
                 WHERE usuario_id = $1
                 GROUP BY accion
                 ORDER BY cantidad DESC
                 LIMIT 5`,
                [userId]
            );

            return {
                totalEventos: parseInt(totalResult.rows[0].total),
                ultimoEvento: lastEventResult.rows[0] || null,
                accionesFrecuentes: topActionsResult.rows
            };
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new AuditService();