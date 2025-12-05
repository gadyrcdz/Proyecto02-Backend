const authService = require('../services/auth.services');
const { success, error } = require('../utils/responseHandler');

/**
 * Controlador de autenticación
 */
class AuthController {
    /**
     * POST /api/v1/auth/login
     */
    async login(req, res) {
        try {
            const { usernameOrEmail, password } = req.body;

            // Validaciones
            if (!usernameOrEmail || !password) {
                return error(res, 'Usuario/email y contraseña son requeridos', 400);
            }

            // Autenticar
            const result = await authService.login(usernameOrEmail, password);

            return success(res, result, 'Login exitoso', 200);
        } catch (err) {
            if (err.message === 'INVALID_CREDENTIALS') {
                return error(res, 'Credenciales inválidas', 401);
            }
            console.error('Error en login:', err);
            return error(res, 'Error al iniciar sesión', 500);
        }
    }

    /**
     * POST /api/v1/auth/forgot-password
     */
    async forgotPassword(req, res) {
        try {
            const { email } = req.body;

            if (!email) {
                return error(res, 'Email es requerido', 400);
            }

            const result = await authService.forgotPassword(email);

            return success(res, { otpCode: result.otpCode }, 'Código OTP generado', 200);
            
        } catch (err) {
            if (err.message === 'USER_NOT_FOUND') {
                return error(res, 'Usuario no encontrado', 404);
            }
            console.error('Error en forgot-password:', err);
            return error(res, 'Error al procesar solicitud', 500);
        }
    }


    /**
     * POST /api/v1/auth/verify-otp
     */
    async verifyOTP(req, res) {
        try {
            const { email, code } = req.body;

            // Validaciones
            if (!email || !code) {
                return error(res, 'Email y código son requeridos', 400);
            }

            const result = await authService.verifyOTP(email, code);

            return success(res, result, 'Código verificado', 200);
        } catch (err) {
            if (err.message === 'USER_NOT_FOUND') {
                return error(res, 'Usuario no encontrado', 404);
            }
            if (err.message === 'INVALID_OTP') {
                return error(res, 'Código OTP inválido o expirado', 400);
            }
            console.error('Error en verify-otp:', err);
            return error(res, 'Error al verificar código', 500);
        }
    }

    /**
     * POST /api/v1/auth/reset-password
     */
    async resetPassword(req, res) {
        try {
            const { tempToken, newPassword } = req.body;

            // Validaciones
            if (!tempToken || !newPassword) {
                return error(res, 'Token y nueva contraseña son requeridos', 400);
            }

            if (newPassword.length < 8) {
                return error(res, 'La contraseña debe tener al menos 8 caracteres', 400);
            }

            const result = await authService.resetPassword(tempToken, newPassword);

            return success(res, result, 'Contraseña actualizada', 200);
        } catch (err) {
            if (err.message === 'INVALID_TOKEN') {
                return error(res, 'Token inválido o expirado', 401);
            }
            console.error('Error en reset-password:', err);
            return error(res, 'Error al resetear contraseña', 500);
        }
    }
}

module.exports = new AuthController();