const transfersService = require('../services/transfers.services');
const { success, error } = require('../utils/responseHandler');

class TransfersController {
    /**
     * POST /api/v1/transfers/internal
     */
    async createInternalTransfer(req, res) {
        try {
            const transferData = req.body;
           
            const requiredFields = [
                'fromAccountId',
                'toAccountId',
                'amount',
                'currency',
                'description',
                'userId'
            ];

            for (const field of requiredFields) {
                if (!transferData[field]) {
                    return error(res, `El campo ${field} es requerido`, 400);
                }
            }

            if (transferData.amount <= 0) {
                return error(res, 'El monto debe ser mayor a cero', 400);
            }
            console.log(transferData);
            const result = await transfersService.createInternalTransfer(transferData);
           
            return success(res, result, 'Transferencia realizada exitosamente', 201);
        } catch (err) {
            console.error('Error al realizar transferencia:', err);

            if (err.message.includes('Saldo insuficiente')) {
                return error(res, err.message, 400);
            }

            if (err.message.includes('no pertenece')) {
                return error(res, err.message, 403);
            }

            return error(res, 'Error al realizar transferencia', 500);
        }
    }

    /**
     * POST /api/v1/bank/validate-account
     */
    async validateAccount(req, res) {
        try {
            const { iban } = req.body;

            if (!iban) {
                return error(res, 'El IBAN es requerido', 400);
            }

            const result = await transfersService.validateAccount(iban);

            return success(res, result, 'Cuenta validada', 200);
        } catch (err) {
            console.error('Error al validar cuenta:', err);
            return error(res, 'Error al validar cuenta', 500);
        }
    }
}

module.exports = new TransfersController();