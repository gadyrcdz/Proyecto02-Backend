const config = require('../config/config');
const { error } = require('../utils/responseHandler');

/**
 * Middleware para validar API Key
 * Se usa en endpoints publicos (login, forgot-password, etc.)
 */
const validateApiKey = (req, res, next) => {
    // Obtener API Key del header
    const apiKey = req.headers['x-api-key'];
    
    // Validar que exista
    if (!apiKey) {
        return error(res, 'API Key requerida', 401);
    }
    
    // Validar que sea correcta
    if (apiKey !== config.apiKey) {
        return error(res, 'API Key inválida', 403);
    }
    
    // Continuar
    next();
};

module.exports = validateApiKey;