const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../databaseConnection/pool');
const config = require('../config/config');



/**
 * Servicio de autenticación
 */
class AuthService {
    /**
     * Login de usuario
     */
    async login(usernameOrEmail, password) {
        try {
            // Obtener usuario por username o email
            const result = await pool.query(
                'SELECT * FROM sp_auth_user_get_by_username_or_email($1)',
                [usernameOrEmail]
            );
            // console.log(result);
            if (result.rows.length === 0) {
                throw new Error('INVALID_CREDENTIALS');
            }

            const user = result.rows[0];
            // console.log(user);

            // Verificar contraseña
            // console.log(password);
            // console.log(user.contrasenia_hash);
            const isPasswordValid = await bcrypt.compare(password, user.contrasenia_hash);
            // console.log(isPasswordValid);
            if (!isPasswordValid) {
                throw new Error('INVALID_CREDENTIALS');
            }

            // Generar JWT
            const token = jwt.sign(
                {
                    userId: user.user_id,
                    rol: user.rol,
                    rolNombre: user.rol_nombre
                },
                config.jwt.secret,
                { expiresIn: config.jwt.expiresIn }
            );

            return {
                token,
                user: {
                    id: user.user_id,
                    nombre: user.nombrecompleto,
                    rol: user.rol
                }
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Solicitar recuperación de contraseña (genera OTP)
     */
    async forgotPassword(email) {
        try {
            // Verificar que el usuario exista
            const userResult = await pool.query(
                'SELECT * FROM sp_auth_user_get_by_username_or_email($1)',
                [email]
            );

            if (userResult.rows.length === 0) {
                throw new Error('USER_NOT_FOUND');
            }

            const user = userResult.rows[0];

            // Generar código OTP aleatorio (6 dígitos)
            const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

            // Hash del código
            console.log(otpCode);
            const otpHash = await bcrypt.hash(otpCode, 10);
            console.log(otpHash);

            // Crear OTP en la BD (expira en 10 minutos = 600 segundos)
            await pool.query(
                'SELECT sp_otp_create($1, $2, $3, $4)',
                [user.user_id, 'password_reset', 600, otpHash]
            );

           
            return {
                // Solo para desarrollo/testing:
                otpCode: config.nodeEnv === 'production' ? otpCode : undefined
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Verificar código OTP
     */
    async verifyOTP(email, code, purpose = 'password_reset') {
        try {
            // Obtener usuario
            const userResult = await pool.query(
                'SELECT * FROM sp_auth_user_get_by_username_or_email($1)',
                [email]
            );

            if (userResult.rows.length === 0) {
                throw new Error('USER_NOT_FOUND');
            }

            const user = userResult.rows[0];

            // Consumir OTP 
            const otpResult = await pool.query(
                'SELECT * FROM sp_otp_consume($1, $2, $3)',
                [user.user_id, purpose, code] 
            );

            const otpData = otpResult.rows[0];

            if (!otpData || !otpData.consumed) {
                throw new Error('INVALID_OTP');
            }

            const isValid = await bcrypt.compare(code, otpData.stored_hash);

            if (!isValid) {
                throw new Error('INVALID_OTP');
            }

            const tempToken = jwt.sign(
                { userId: user.user_id, purpose: 'reset_password' },
                config.jwt.secret,
                { expiresIn: '15m' }
            );

            return {
                message: 'Código verificado correctamente',
                tempToken
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Resetear contraseña
     */
    async resetPassword(tempToken, newPassword) {
        try {
            // Verificar token temporal
            const decoded = jwt.verify(tempToken, config.jwt.secret);

            if (decoded.purpose !== 'reset_password') {
                throw new Error('INVALID_TOKEN');
            }

            // Hash de la nueva contraseña
            const passwordHash = await bcrypt.hash(newPassword, 10);

            // Actualizar contraseña en la BD
            await pool.query(
                'UPDATE usuario SET contrasenia_hash = $1, fecha_actu = CURRENT_TIMESTAMP WHERE id = $2',
                [passwordHash, decoded.userId]
            );

            return {
                message: 'Contraseña actualizada exitosamente'
            };
        } catch (error) {
            if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
                throw new Error('INVALID_TOKEN');
            }
            throw error;
        }
    }
}

module.exports = new AuthService();