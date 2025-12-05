// controllers/catalogController.js -
const { pool } = require('../databaseConnection/pool');
const { success, error } = require('../utils/responseHandler');

const catalogController = {
    /**
     * Obtener tipos de cuenta
     * GET /catalog/account-types
     */
    async getAccountTypes(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre, descripcion FROM tipoCuenta ORDER BY nombre'
            );

            return success(res, result.rows, 'Tipos de cuenta obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener tipos de cuenta:', err);
            return error(res, 'Error al obtener tipos de cuenta', 500);
        }
    },

    /**
     * Obtener monedas
     * GET /catalog/currencies
     */
    async getCurrencies(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre, iso FROM moneda ORDER BY nombre'
            );

            return success(res, result.rows, 'Monedas obtenidas', 200);
        } catch (err) {
            console.error('Error al obtener monedas:', err);
            return error(res, 'Error al obtener monedas', 500);
        }
    },

    /**
     * Obtener tipos de tarjeta
     * GET /catalog/card-types
     */
    async getCardTypes(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre, descripcion FROM tipoTarjeta ORDER BY nombre'
            );

            return success(res, result.rows, 'Tipos de tarjeta obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener tipos de tarjeta:', err);
            return error(res, 'Error al obtener tipos de tarjeta', 500);
        }
    },

    /**
     * Obtener estados de cuenta
     * GET /catalog/account-statuses
     */
    async getAccountStatuses(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre FROM estadoCuenta ORDER BY nombre'
            );

            return success(res, result.rows, 'Estados obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener estados:', err);
            return error(res, 'Error al obtener estados', 500);
        }
    },

    /**
     * Obtener tipos de movimiento
     * GET /catalog/movement-types
     */
    async getMovementTypesAccount(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre FROM tipoMovimientoCuenta ORDER BY nombre'
            );

            return success(res, result.rows, 'Tipos de movimiento obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener tipos de movimiento:', err);
            return error(res, 'Error al obtener tipos de movimiento', 500);
        }
    },
    async getMovementTypesCard(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre FROM tipoMovimientoTarjeta ORDER BY nombre'
            );

            return success(res, result.rows, 'Tipos de movimiento obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener tipos de movimiento:', err);
            return error(res, 'Error al obtener tipos de movimiento', 500);
        }
    },

    /**
     * Obtener tipos de identificación
     * GET /catalog/id-types
     */
    async getIdTypes(req, res) {
        try {
            const result = await pool.query(
                'SELECT id, nombre FROM tipoIdentificacion ORDER BY nombre'
            );

            return success(res, result.rows, 'Tipos de identificación obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener tipos de identificación:', err);
            return error(res, 'Error al obtener tipos de identificación', 500);
        }
    },

    /**
     * Obtener todos los catálogos a la vez
     * GET /catalog/all
     */
    async getAllCatalogs(req, res) {
        try {
            const [accountTypes, currencies, cardTypes, accountStatuses, movementTypesAcc,movementTypesCar ,idTypes] = await Promise.all([
                pool.query('SELECT id, nombre, descripcion FROM tipoCuenta ORDER BY nombre'),
                pool.query('SELECT id, nombre, iso FROM moneda ORDER BY nombre'),
                pool.query('SELECT id, nombre, descripcion FROM tipoTarjeta ORDER BY nombre'),
                pool.query('SELECT id, nombre FROM estadoCuenta ORDER BY nombre'),
                pool.query('SELECT id, nombre FROM tipoMovimientoCuenta ORDER BY nombre'),
                pool.query('SELECT id, nombre FROM tipoMovimientoTarjeta ORDER BY nombre'),
                pool.query('SELECT id, nombre FROM tipoIdentificacion ORDER BY nombre')
            ]);

            const catalogs = {
                accountTypes: accountTypes.rows,
                currencies: currencies.rows,
                cardTypes: cardTypes.rows,
                accountStatuses: accountStatuses.rows,
                movementTypes: movementTypesAcc.rows,
                movementTypes: movementTypesCar.rows,
                idTypes: idTypes.rows
            };

            return success(res, catalogs, 'Catálogos obtenidos', 200);
        } catch (err) {
            console.error('Error al obtener catálogos:', err);
            return error(res, 'Error al obtener catálogos', 500);
        }
    }
};

module.exports = catalogController;