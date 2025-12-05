const accountsService = require('../services/accounts.services');
const { success, error } = require('../utils/responseHandler');

class AccountsController {
    /**
     * POST /api/v1/accounts
     */
    async createAccount(req, res) {
        try {
            const accountData = req.body;

            const requiredFields = [
                'usuarioId',
                'iban',
                'tipoCuenta',
                'moneda',
                'saldoInicial',
                'estado'
            ];

            for (const field of requiredFields) {
                if (accountData[field] === undefined) {
                    return error(res, `El campo ${field} es requerido`, 400);
                }
            }

            const result = await accountsService.createAccount(accountData);

            return success(res, result, 'Cuenta creada exitosamente', 201);
        } catch (err) {
            console.error('Error al crear cuenta:', err);

            if (err.message.includes('ya existe')) {
                return error(res, err.message, 409);
            }

            return error(res, 'Error al crear cuenta', 500);
        }
    }

    /**
     * GET /api/v1/accounts
     * GET /api/v1/accounts/:accountId
     */
    async getAccountsByUser(req, res) {
        try {
            const { userId } = req.query;

            // Validar permisos: solo admin puede ver cuentas de otros usuarios
            const isAdmin = req.user.rol === '609bdb9c-3df8-458c-9815-4cb993683ea7';
            
            if (!isAdmin && userId && userId !== req.user.id) {
                return error(res, 'No tienes permiso para ver estas cuentas', 403);
            }

            // Determinar de quién obtener las cuentas
            const ownerId = (isAdmin && userId) ? userId : req.user.id;

            // Llamar al servicio con ownerId y accountId = null
            const accounts = await accountsService.getAccounts(ownerId, null);

            if (accounts.length === 0) {
                return error(res, 'No se encontraron cuentas', 404);
            }

            return success(res, accounts, 'Cuentas obtenidas exitosamente', 200);
        } catch (err) {
            console.error('Error al obtener cuentas del usuario:', err);
            return error(res, 'Error al obtener cuentas', 500);
        }
    }

     async getAccountById(req, res) {
        try {
            const { accountId } = req.params;

            // Validar que accountId sea un UUID válido
            const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
            if (!uuidRegex.test(accountId)) {
                return error(res, 'ID de cuenta inválido', 400);
            }

            // Llamar al servicio con ownerId = null y accountId
            const accounts = await accountsService.getAccounts(null, accountId);

            if (accounts.length === 0) {
                return error(res, 'Cuenta no encontrada', 404);
            }

            const account = accounts[0];

            // Validar permisos: solo el dueño o admin pueden ver la cuenta
            const isAdmin = req.user.rol === '609bdb9c-3df8-458c-9815-4cb993683ea7';
            const isOwner = account.usuario_id === req.user.id;

            if (!isAdmin && !isOwner) {
                return error(res, 'No tienes permiso para ver esta cuenta', 403);
            }

            return success(res, account, 'Cuenta obtenida exitosamente', 200);
        } catch (err) {
            console.error('Error al obtener cuenta por ID:', err);
            return error(res, 'Error al obtener cuenta', 500);
        }
    }

    /**
     * POST /api/v1/accounts/:accountId/status
     */
    async setAccountStatus(req, res) {
        try {
            const { accountId } = req.params;
            const { status } = req.params;
            
            console.log(req.params);
            if (!status) {
                return error(res, 'El nuevo estado es requerido', 400);
            }

            const result = await accountsService.setAccountStatus(accountId, status);

            return success(res, result, 'Estado actualizado', 200);
        } catch (err) {
            console.error('Error al cambiar estado:', err);

            if (err.message.includes('saldo') || err.message.includes('cerrar')) {
                return error(res, err.message, 400);
            }

            return error(res, 'Error al cambiar estado de cuenta', 500);
        }
    }

    /**
     * GET /api/v1/accounts/:accountId/movements
     */
    async getAccountMovements(req, res) {
        try {
            const { accountId } = req.params;
            const filters = req.query;

            const result = await accountsService.getAccountMovements(accountId, filters);

            return success(res, result, 'Movimientos obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener movimientos:', err);
            return error(res, 'Error al obtener movimientos', 500);
        }
    }
}

module.exports = new AccountsController();