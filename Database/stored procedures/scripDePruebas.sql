-- ============================================
-- PRUEBAS DE USUARIOS
-- ============================================

-- 1. Crear usuario
SELECT sp_users_create(
    (SELECT id FROM tipoIdentificacion WHERE nombre = 'Nacional'),
    '1-2345-6789',
    'María',
    'González',
    'maria.gonzalez@email.com',
    '8888-9999',
    'mariag',
    '$2b$10$hashejemplo',
    (SELECT id FROM rol WHERE nombre = 'cliente')
) as nuevo_usuario_id;

-- 2. Buscar usuario por identificación
SELECT * FROM sp_users_get_by_identification('1-2345-6789');

-- 3. Actualizar usuario
SELECT sp_users_update(
    (SELECT id FROM usuario WHERE usuario = 'mariag'),
    'María José',  -- nuevo nombre
    NULL,          -- mantener apellido
    'mariajose@email.com',  -- nuevo correo
    NULL,          -- mantener teléfono
    NULL,          -- mantener usuario
    NULL           -- mantener rol
);


SELECT * FROM usuario;
-- 4. Eliminar usuario (cuidado, esto borra todo)
SELECT sp_users_delete((SELECT id FROM usuario WHERE usuario = 'mariag'));


-- ============================================
-- PRUEBAS DE CUENTAS
-- ============================================
INSERT INTO estadoCuenta(nombre, descripcion) VALUES 
('Cerrada',  'Cuenta cerrada moroso ')


select * from cuenta;

-- 1. Crear cuenta
SELECT sp_accounts_create(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),
    'CR12345678901234567890',
    'Mi cuenta principal',
    (SELECT id FROM tipoCuenta WHERE nombre = 'Ahorros'),
    (SELECT id FROM moneda WHERE iso = 'CRC'),
    100000.00,  -- Saldo inicial
    (SELECT id FROM estadoCuenta WHERE nombre = 'Activa')
) as nueva_cuenta_i;

-- 2. Ver todas las cuentas de un usuario
SELECT * FROM sp_accounts_get(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),
    NULL
);

-- 3. Ver una cuenta específica
SELECT * FROM sp_accounts_get(
    NULL,
    '060d4b1d-df5c-42a8-ba3f-5f0ec3c2bfe9'
);

-- 4. Cambiar estado de cuenta a bloqueada
SELECT sp_accounts_set_status(
    '060d4b1d-df5c-42a8-ba3f-5f0ec3c2bfe9',
    (SELECT id FROM estadoCuenta WHERE nombre = 'Bloqueada')
);

-- 5. Intentar cerrar cuenta con saldo- validacion
SELECT sp_accounts_set_status(
    '060d4b1d-df5c-42a8-ba3f-5f0ec3c2bfe9',
    (SELECT id FROM estadoCuenta WHERE nombre = 'Cerrada')
);