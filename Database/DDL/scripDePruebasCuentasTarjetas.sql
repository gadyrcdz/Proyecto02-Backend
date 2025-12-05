-- ============================================
-- PRUEBAS DE USUARIOS
-- ============================================
select * from usuario;
select * from tipoCuenta;
select * from moneda;
select * from estadoCuenta;
select * from cuenta;
select * from tipoTarjeta;
select * from tipoIdentificacion;

select * from auditoria;
drop table auditoria; 
select * from tipoMovimientoTarjeta;
select * from tipoMovimiento;
-- 1. Crear usuario
SELECT sp_users_create(
    (SELECT id FROM tipoIdentificacion WHERE nombre = 'Nacional'),
    '7-2345-6789',
    'gadyr',
    'CALDEORN',
    'gadyr.gadyr@email.com',
    '8888-9999',
    'gadyrdcd',
    '$2b$10$Wll.2dloX.hJCafJkWqxBOnRTFByIoT43aTbuOz.nYv2UQpOb.DEy',
    (SELECT id FROM rol WHERE nombre = 'cliente')
) as nuevo_usuario_id;

SELECT * FROM sp_auth_user_get_by_username_or_email('gadyrDiaz');


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
INSERT INTO tipoIdentificacion( nombre, descripcion) VALUES 
('DIMEX',  'Identificacion tipo DIMEX'),
('Pasaporte', 'Identificacion tipo pasaporte')


-- 1. Crear cuenta
SELECT sp_accounts_create(
    (SELECT id FROM usuario WHERE usuario = 'gadyrdcd'),
    'CR22345678901234567121',
    'Mi cuenta principal gadyr buena',
    (SELECT id FROM tipoCuenta WHERE nombre = 'Ahorros'),
    (SELECT id FROM moneda WHERE iso = 'CRC'),
    100000.00,  -- Saldo inicial
    (SELECT id FROM estadoCuenta WHERE nombre = 'Activa')
) as nueva_cuenta_id;

-- 2. Ver todas las cuentas de un usuario
SELECT * FROM sp_accounts_get(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),
    NULL
);

-- 3. Ver una cuenta específica
SELECT * FROM sp_accounts_get(
   'da84a14c-2ed1-4e79-a464-33afefa9d172',
    null
);

-- 4. Cambiar estado de cuenta a bloqueada
SELECT sp_accounts_set_status(
    'UUID-DE-LA-CUENTA-AQUI',
    (SELECT id FROM estadoCuenta WHERE nombre = 'Bloqueada')
);

-- 5. Intentar cerrar cuenta con saldo (debería fallar)
SELECT sp_accounts_set_status(
    'UUID-DE-LA-CUENTA-AQUI',
    (SELECT id FROM estadoCuenta WHERE nombre = 'Cerrada')
);