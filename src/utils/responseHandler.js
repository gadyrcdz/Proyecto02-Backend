/**
 * Manejador de respuestas exitosas
 */
const success = (res, data = null, message = 'Operacion exitosa', statusCode = 200) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data
    });
};

/**
 * Manejador de respuestas de error
 */
const error = (res, message = 'Error en el servidor', statusCode = 500, errors = null) => {
    const response = {
        success: false,
        message
    };
    
    if (errors) {
        response.errors = errors;
    }
    
    return res.status(statusCode).json(response);
};

/**
 * Manejador de errores de base de datos
 */
const databaseError = (res, err) => {
    console.error('Database error:', err);
    
    return error(res, 'Error al procesar la solicitud', 500);
};

/**
 * Manejador de errores de validación
 */
const validationError = (res, errors) => {
    return error(res, 'Error de validación', 400, errors);
};

module.exports = {
    success,
    error,
    databaseError,
    validationError
};