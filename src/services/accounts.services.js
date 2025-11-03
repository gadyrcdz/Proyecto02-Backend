const { pool } = require('../databaseConnection/pool');

class AccountsService {
    /**
     * Crear cuenta
     */
    async createAccount(accountData) {
        try {
            const {
                usuarioId,
                iban,
                aliass,
                tipoCuenta,
                moneda,
                saldoInicial,
                estado
            } = accountData;

            const result = await pool.query(
                `SELECT sp_accounts_create($1, $2, $3, $4, $5, $6, $7) as account_id`,
                [usuarioId, iban, aliass, tipoCuenta, moneda, saldoInicial, estado]
            );

            return {
                accountId: result.rows[0].account_id
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Obtener cuentas
     */
    async getAccounts(ownerId, accountId) {
        try {
            const result = await pool.query(
                'SELECT * FROM sp_accounts_get($1, $2)',
                [ownerId, accountId]
            );

            return result.rows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Cambiar estado de cuenta
     */
    async setAccountStatus(accountId, nuevoEstado) {
        try {
            const result = await pool.query(
                'SELECT sp_accounts_set_status($1, $2) as updated',
                [accountId, nuevoEstado]
            );

            if (!result.rows[0].updated) {
                throw new Error('STATUS_UPDATE_FAILED');
            }

            return { message: 'Estado de cuenta actualizado' };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Listar movimientos de cuenta
     */
    async getAccountMovements(accountId, filters = {}) {
        try {
            const {
                fromDate = null,
                toDate = null,
                type = null,
                q = null,
                page = 1,
                pageSize = 10
            } = filters;

            const result = await pool.query(
                'SELECT * FROM sp_account_movements_list($1, $2, $3, $4, $5, $6, $7)',
                [accountId, fromDate, toDate, type, q, page, pageSize]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new AccountsService();