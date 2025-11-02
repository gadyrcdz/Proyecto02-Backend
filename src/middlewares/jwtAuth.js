const jwt = require('jsonwebtoken');
const config = require('../config/config');
const { error } = require('../utils/responseHandler');

/**
 * Middleware para validar JWT
 * Se usa en todos los endpoints protegidos
 */
const validateJWT = (req, res, next) => {
    // Obtener token del header
    const authHeader = req.headers['authorization'];
    
    if (!authHeader) {
        return error(res, 'Token no proporcionado', 401);
    }
    
    // Formato: "Bearer TOKEN"
    const token = authHeader.split(' ')[1];
    
    if (!token) {
        return error(res, 'Formato de token inválido', 401);
    }
    
    try {
        // Verificar token
        const decoded = jwt.verify(token, config.jwt.secret);
        
        // Agregar datos del usuario al request
        req.user = {
            id: decoded.userId,
            rol: decoded.rol,
            rolNombre: decoded.rolNombre
        };
        
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return error(res, 'Token expirado', 401);
        }
        return error(res, 'Token inválido', 403);
    }
};

/**
 * Middleware para validar rol de administrador
 */
const isAdmin = (req, res, next) => {
    if (req.user.rolNombre !== 'admin') {
        return error(res, 'Acceso denegado. Se requiere rol de administrador', 403);
    }
    next();
};

/**
 * Middleware para validar que el recurso pertenece al usuario
 */
const isOwnerOrAdmin = (paramName = 'userId') => {
    return (req, res, next) => {
        const resourceUserId = req.params[paramName] || req.body[paramName];
        
        // Admin puede acceder a todo
        if (req.user.rolNombre === 'admin') {
            return next();
        }
        
        // Cliente solo puede acceder a sus propios recursos
        if (req.user.id !== resourceUserId) {
            return error(res, 'No tienes permiso para acceder a este recurso', 403);
        }
        
        next();
    };
};

module.exports = {
    validateJWT,
    isAdmin,
    isOwnerOrAdmin
};