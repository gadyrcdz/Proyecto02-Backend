/**
 * Middleware global de manejo de errores
 */
const errorHandler = (err, req, res, next) => {
    console.error('Error global capturado:', {
        message: err.message,
        stack: err.stack,
        url: req.originalUrl,
        method: req.method
    });
    
    // Error de validación
    if (err.name === 'ValidationError') {
        return res.status(400).json({
            success: false,
            message: 'Error de validación',
            errors: err.errors
        });
    }
    
    // Error de JWT
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({
            success: false,
            message: 'Token inválido'
        });
    }
    
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
            success: false,
            message: 'Token expirado'
        });
    }
    
    // Error por defecto
    res.status(err.statusCode || 500).json({
        success: false,
        message: err.message || 'Error interno del servidor'
    });
};

/**
 * Manejador de rutas no encontradas (404)
 */
const notFound = (req, res) => {
    res.status(404).json({
        success: false,
        message: `Ruta no encontrada: ${req.method} ${req.originalUrl}`
    });
};

module.exports = {
    errorHandler,
    notFound
};