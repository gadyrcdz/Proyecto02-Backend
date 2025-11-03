const bcrypt = require('bcrypt');
const { pool } = require('../databaseConnection/pool');

class UsersService {
    /**
     * Crear usuario
     */
    async createUser(userData) {
        try {
            const {
                tipoIdentificacion,
                identificacion,
                nombre,
                apellido,
                correo,
                telefono,
                usuario,
                password,
                rol
            } = userData;

            // Hash de la contraseña
            const passwordHash = await bcrypt.hash(password, 10);

            // Llamar al SP
            const result = await pool.query(
                `SELECT sp_users_create($1, $2, $3, $4, $5, $6, $7, $8, $9) as user_id`,
                [
                    tipoIdentificacion,
                    identificacion,
                    nombre,
                    apellido,
                    correo,
                    telefono,
                    usuario,
                    passwordHash,
                    rol
                ]
            );

            return {
                userId: result.rows[0].user_id
            };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Obtener usuario por identificación
     */
    async getUserByIdentification(identificacion) {
        try {
            const result = await pool.query(
                'SELECT * FROM sp_users_get_by_identification($1)',
                [identificacion]
            );

            if (result.rows.length === 0) {
                throw new Error('USER_NOT_FOUND');
            }

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    /**
     * Actualizar usuario
     */
    async updateUser(userId, updates) {
        try {
            const { nombre, apellido, correo, telefono, usuario, rol } = updates;

            const result = await pool.query(
                'SELECT sp_users_update($1, $2, $3, $4, $5, $6, $7) as updated',
                [
                    userId,
                    nombre || null,
                    apellido || null,
                    correo || null,
                    telefono || null,
                    usuario || null,
                    rol || null
                ]
            );

            if (!result.rows[0].updated) {
                throw new Error('UPDATE_FAILED');
            }

            return { message: 'Usuario actualizado correctamente' };
        } catch (error) {
            throw error;
        }
    }

    /**
     * Eliminar usuario
     */
    async deleteUser(userId) {
        try {
            const result = await pool.query(
                'SELECT sp_users_delete($1) as deleted',
                [userId]
            );

            if (!result.rows[0].deleted) {
                throw new Error('DELETE_FAILED');
            }

            return { message: 'Usuario eliminado correctamente' };
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new UsersService();