const cardsService = require('../services/cards.services');
const { success, error } = require('../utils/responseHandler');

class CardsController {
    /**
     * POST /api/v1/cards
     */
    async createCard(req, res) {
        try {
            const cardData = req.body;

            const requiredFields = [
                'usuarioId', 'tipo', 'numeroEnmascarado', 'fechaExpiracion',
                'cvv', 'pin', 'moneda', 'limiteCredito', 'saldoActual'
            ];

            for (const field of requiredFields) {
                if (cardData[field] === undefined) {
                    return error(res, `El campo ${field} es requerido`, 400);
                }
            }

            // Validaciones
            if (cardData.cvv.length !== 3) {
                return error(res, 'El CVV debe tener 3 dígitos', 400);
            }

            if (cardData.pin.length !== 4) {
                return error(res, 'El PIN debe tener 4 dígitos', 400);
            }

            const result = await cardsService.createCard(cardData);

            return success(res, result, 'Tarjeta creada exitosamente', 201);
        } catch (err) {
            console.error('Error al crear tarjeta:', err);

            if (err.message.includes('ya existe')) {
                return error(res, err.message, 409);
            }

            return error(res, 'Error al crear tarjeta', 500);
        }
    }

    /**
     * GET /api/v1/cards
     * GET /api/v1/cards/:cardId
     */
    async getCards(req, res) {
        try {
            const { cardId } = req.params;
            const { userId } = req.query;

            // Validar permisos
            if (req.user.rol !== '609bdb9c-3df8-458c-9815-4cb993683ea7' && userId && userId !== req.user.id) {
                return error(res, 'No tienes permiso para ver estas tarjetas', 403);
            }

            const ownerId = req.user.rol === '609bdb9c-3df8-458c-9815-4cb993683ea7' ? userId : req.user.id;

            const cards = await cardsService.getCards(ownerId || null, cardId || null);

            if (cards.length === 0) {
                return error(res, 'No se encontraron tarjetas', 404);
            }

            return success(res, cardId ? cards[0] : cards, 'Tarjetas obtenidas', 200);
        } catch (err) {
            console.error('Error al obtener tarjetas:', err);
            return error(res, 'Error al obtener tarjetas', 500);
        }
    }

    /**
     * GET /api/v1/cards/:cardId/movements
     */
    async getCardMovements(req, res) {
        try {
            const { cardId } = req.params;
            const filters = req.query;

            const result = await cardsService.getCardMovements(cardId, filters);

            return success(res, result, 'Movimientos obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener movimientos:', err);
            return error(res, 'Error al obtener movimientos', 500);
        }
    }

    /**
     * POST /api/v1/cards/:cardId/movements
     */
    async addCardMovement(req, res) {
        try {
            const { cardId } = req.params;
            const movementData = {
                cardId,
                ...req.body,
                fecha: req.body.fecha || new Date()
            };

            const requiredFields = ['tipo', 'descripcion', 'moneda', 'monto'];

            for (const field of requiredFields) {
                if (!movementData[field]) {
                    return error(res, `El campo ${field} es requerido`, 400);
                }
            }

            if (movementData.monto <= 0) {
                return error(res, 'El monto debe ser mayor a cero', 400);
            }

            const result = await cardsService.addCardMovement(movementData);

            return success(res, result, 'Movimiento agregado exitosamente', 201);
        } catch (err) {
            console.error('Error al agregar movimiento:', err);

            if (err.message.includes('Saldo insuficiente') || 
                err.message.includes('límite')) {
                return error(res, err.message, 400);
            }

            return error(res, 'Error al agregar movimiento', 500);
        }
    }

    /**
     * POST /api/v1/cards/:cardId/otp
     */
    async generateOTP(req, res) {
        try {
            const { cardId } = req.params;
           
            const result = await cardsService.generateOTPForCardDetails(cardId);

            return success(res, result, 'OTP generado', 200);
        } catch (err) {
            console.error('Error al generar OTP:', err);

            if (err.message === 'CARD_NOT_FOUND') {
                return error(res, 'Tarjeta no encontrada', 404);
            }

            if (err.message === 'FORBIDDEN') {
                return error(res, 'No tienes permiso para acceder a esta tarjeta', 403);
            }

            return error(res, 'Error al generar OTP', 500);
        }
    }

    /**
     * POST /api/v1/cards/:cardId/view-details
     */
    async viewCardDetails(req, res) {
        try {
            const { cardId } = req.params;
            const { otpCode } = req.body;

            if (!otpCode) {
                return error(res, 'Código OTP es requerido', 400);
            }

            const result = await cardsService.viewCardDetails(cardId, otpCode);

            return success(res, result, 'Acceso autorizado', 200);
        } catch (err) {
            console.error('Error al ver detalles:', err);

            if (err.message === 'CARD_NOT_FOUND') {
                return error(res, 'Tarjeta no encontrada', 404);
            }

            if (err.message === 'FORBIDDEN') {
                return error(res, 'No tienes permiso para acceder a esta tarjeta', 403);
            }

            if (err.message === 'INVALID_OTP') {
                return error(res, 'Código OTP inválido o expirado', 400);
            }

            return error(res, 'Error al ver detalles de tarjeta', 500);
        }
    }
}

module.exports = new CardsController();