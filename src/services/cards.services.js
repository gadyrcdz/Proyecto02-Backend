const bcrypt = require('bcrypt');
const { pool } = require('../databaseConnection/pool');

class CardsService {
    /**
     * Crear tarjeta
     */
    async createCard(cardData) {
        try {
            const {
                usuarioId,
                tipo,
                numeroEnmascarado,
                fechaExpiracion,
                cvv,
                pin,
                moneda,
                limiteCredito,
                saldoActual
            } = cardData;

            // Hash de CVV y PIN
            const cvvHash = await bcrypt.hash(cvv, 10);
            const pinHash = await bcrypt.hash(pin, 10);

            const result = await pool.query(
                `SELECT sp_cards_create($1, $2, $3, $4, $5, $6, $7, $8, $9) as card_id`,
                [
                    usuarioId,
                    tipo,
                    numeroEnmascarado,
                    fechaExpiracion,
                    cvvHash,
                    pinHash,
                    moneda,
                    limiteCredito,
                    saldoActual
                ]
            );

            return {
                cardId: result.rows[0].card_id
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Obtener tarjetas
     */
    async getCards(ownerId = null, cardId = null) {
        try {
            const result = await pool.query(
                'SELECT * FROM sp_cards_get($1, $2)',
                [ownerId, cardId]
            );

            return result.rows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Listar movimientos de tarjeta
     */
    async getCardMovements(cardId, filters = {}) {
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
                'SELECT * FROM sp_card_movements_list($1, $2, $3, $4, $5, $6, $7)',
                [cardId, fromDate, toDate, type, q, page, pageSize]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Agregar movimiento a tarjeta
     */
    async addCardMovement(movementData) {
        try {
            const { cardId, fecha, tipo, descripcion, moneda, monto } = movementData;

            const result = await pool.query(
                'SELECT * FROM sp_card_movement_add($1, $2, $3, $4, $5, $6)',
                [cardId, fecha, tipo, descripcion, moneda, monto]
            );

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Generar OTP para ver PIN/CVV
     */
    async generateOTPForCardDetails(cardId, purpose = 'card_details') {
        try {
            const cardCheck = await pool.query(
                'SELECT usuario_id FROM tarjeta WHERE id = $1',
                [cardId]
            );

            if (cardCheck.rows.length === 0) {
                throw new Error('CARD_NOT_FOUND');
            }

            const userId = cardCheck.rows[0].usuario_id;

            const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
            const otpHash = await bcrypt.hash(otpCode, 10);

            // Crear OTP (expira en 2 minutos = 120 segundos)
            await pool.query(
                'SELECT sp_otp_create($1, $2, $3, $4)',
                [userId, purpose, 120, otpHash]
            );

            return {
                message: 'Código OTP generado (válido por 2 minutos)',
                otpCode: process.env.NODE_ENV === 'production' ? otpCode : undefined
            };

        } catch (error) {
            throw error;
        }
    }


    /**
     * Ver detalles de tarjeta (PIN/CVV) con OTP
     */
    async viewCardDetails(cardId, otpCode) {
        try {
            // Verificar que la tarjeta pertenezca al usuario
            const cardResult = await pool.query(
                'SELECT pin_hash, cvv_hash, usuario_id FROM tarjeta WHERE id = $1',
                [cardId]
            );

            if (cardResult.rows.length === 0) {
                throw new Error('CARD_NOT_FOUND');
            }

            const userId = cardResult.rows[0].usuario_id;

            // Verificar OTP
            const otpResult = await pool.query(
                'SELECT * FROM sp_otp_consume($1, $2, $3)',
                [userId, 'card_details', otpCode]
            );

            if (!otpResult.rows[0] || !otpResult.rows[0].consumed) {
                throw new Error('INVALID_OTP');
            }

            // OTP válido - NO retornamos PIN/CVV reales por seguridad
            // En producción, solo se mostrarían en el frontend de forma temporal
            return {
                message: 'Autorización concedida',
                cardId: cardId,
                // En una app real, el frontend mostraría el PIN/CVV temporalmente
                // y no se enviaría por la API
                note: 'PIN y CVV disponibles para visualización temporal'
            };
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new CardsService();