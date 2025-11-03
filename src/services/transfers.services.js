const { pool } = require('../databaseConnection/pool');

class TransfersService {
    /**
     * Crear transferencia interna
     */
    async createInternalTransfer(transferData) {
        try {
            const {
                fromAccountId,
                toAccountId,
                amount,
                currency,
                description,
                userId
            } = transferData;

            const result = await pool.query(
                'SELECT * FROM sp_transfer_create_internal($1, $2, $3, $4, $5, $6)',
                [fromAccountId, toAccountId, amount, currency, description, userId]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Validar cuenta IBAN
     */
    async validateAccount(iban) {
        try {
            const result = await pool.query(
                'SELECT * FROM sp_bank_validate_account($1)',
                [iban]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new TransfersService();