-- ============================================
-- PRUEBAS
-- ============================================

-- 1. Listar movimientos de cuenta (página 1, 10 por página)
SELECT * FROM sp_account_movements_list(
    'UUID-DE-CUENT',
    NULL,  -- desde cualquier fecha
    NULL,  -- hasta cualquier fecha
    NULL,  -- cualquier tipo
    NULL,  -- sin búsqueda
    1,     -- página 1
    10     -- 10 por página
);

-- 2. Crear tarjeta
SELECT sp_cards_create(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),
    (SELECT id FROM tipoTarjeta WHERE nombre = 'Crédito'),
    '1234 **** **** 5678',
    '12/2027',
    '$2b$10$HASH_CVV',
    '$2b$10$HASH_PIN',
    (SELECT id FROM moneda WHERE iso = 'CRC'),
    500000.00,  -- límite
    0.00        -- saldo inicial
);

-- 3. Ver tarjetas de un usuario
SELECT * FROM sp_cards_get(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),
    NULL
);

-- 4. Agregar compra a tarjeta
SELECT * FROM sp_card_movement_add(
    'UUID-DE-TARJETA',
    CURRENT_TIMESTAMP,
    (SELECT id FROM tipoMovimientoTarjeta WHERE nombre = 'Compra'),
    'Compra en supermercado',
    (SELECT id FROM moneda WHERE iso = 'CRC'),
    25000.00
);

-- 5. Transferencia interna
SELECT * FROM sp_transfer_create_internal(
    'UUID-CUENTA-ORIGEN',
    'UUID-CUENTA-DESTINO',
    50000.00,
    (SELECT id FROM moneda WHERE iso = 'CRC'),
    'Pago de alquiler',
    'UUID-USUARIO'
);

-- 6. Validar cuenta por IBAN
SELECT * FROM sp_bank_validate_account('CR12345678901234567890');