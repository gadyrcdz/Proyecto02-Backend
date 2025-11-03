const usersService = require('../services/users.services');
const { success, error } = require('../utils/responseHandler');

class UsersController {
    /**
     * POST /api/v1/users
     */
    async createUser(req, res) {
        try {
            const userData = req.body;

            // Validaciones básicas
            const requiredFields = [
                'tipoIdentificacion',
                'identificacion',
                'nombre',
                'apellido',
                'correo',
                'usuario',
                'password',
                'rol'
            ];

            for (const field of requiredFields) {
                if (!userData[field]) {
                    return error(res, `El campo ${field} es requerido`, 400);
                }
            }

            const result = await usersService.createUser(userData);

            return success(res, result, 'Usuario creado exitosamente', 201);
        } catch (err) {
            console.error('Error al crear usuario:', err);
            
            if (err.message.includes('ya está registrada') || 
                err.message.includes('ya existe')) {
                return error(res, err.message, 409);
            }

            return error(res, 'Error al crear usuario', 500);
        }
    }

    /**
     * GET /api/v1/users/:identification
     */
    async getUserByIdentification(req, res) {
        try {
            const { identification } = req.params;

            const user = await usersService.getUserByIdentification(identification);

            return success(res, user, 'Usuario encontrado', 200);
        } catch (err) {
            if (err.message === 'USER_NOT_FOUND') {
                return error(res, 'Usuario no encontrado', 404);
            }

            console.error('Error al obtener usuario:', err);
            return error(res, 'Error al obtener usuario', 500);
        }
    }

    /**
     * PUT /api/v1/users/:id
     */
    async updateUser(req, res) {
        try {
            const { id } = req.params;
            const updates = req.body;

            const result = await usersService.updateUser(id, updates);

            return success(res, result, 'Usuario actualizado', 200);
        } catch (err) {
            console.error('Error al actualizar usuario:', err);

            if (err.message.includes('ya está registrado') || 
                err.message.includes('ya existe')) {
                return error(res, err.message, 409);
            }

            if (err.message === 'UPDATE_FAILED') {
                return error(res, 'No se pudo actualizar el usuario', 400);
            }

            return error(res, 'Error al actualizar usuario', 500);
        }
    }

    /**
     * DELETE /api/v1/users/:id
     */
    async deleteUser(req, res) {
        try {
            const { id } = req.params;

            const result = await usersService.deleteUser(id);

            return success(res, result, 'Usuario eliminado', 200);
        } catch (err) {
            console.error('Error al eliminar usuario:', err);

            if (err.message === 'DELETE_FAILED') {
                return error(res, 'No se pudo eliminar el usuario', 400);
            }

            return error(res, 'Error al eliminar usuario', 500);
        }
    }
}

module.exports = new UsersController();