-- ============================================
-- SP: sp_transfer_create_internal
-- Descripción: Transferencia entre cuentas del mismo banco
-- ============================================
CREATE OR REPLACE FUNCTION sp_transfer_create_internal(
    p_from_account_id UUID,
    p_to_account_id UUID,
    p_amount DECIMAL(18,2),
    p_currency UUID,
    p_description TEXT,
    p_user_id UUID
)
RETURNS TABLE (
    transfer_id UUID,
    receipt_number VARCHAR,
    status VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_transfer_id UUID;
    v_receipt_number VARCHAR;
    v_from_saldo DECIMAL(18,2);
    v_from_moneda UUID;
    v_from_estado UUID;
    v_from_estado_nombre VARCHAR;
    v_to_moneda UUID;
    v_to_estado UUID;
    v_to_estado_nombre VARCHAR;
    v_tipo_credito UUID;
    v_tipo_debito UUID;
BEGIN
    -- Validar que las cuentas sean diferentes
    IF p_from_account_id = p_to_account_id THEN
        RAISE EXCEPTION 'No se puede transferir a la misma cuenta';
    END IF;
    
    -- Validar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_user_id;
    END IF;
    
    -- Validar monto
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'El monto debe ser mayor a cero';
    END IF;
    
    -- Obtener datos de cuenta origen
    SELECT saldo, moneda, estado INTO v_from_saldo, v_from_moneda, v_from_estado
    FROM cuenta
    WHERE id = p_from_account_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta origen no existe';
    END IF;
    
    -- Validar que la cuenta origen pertenezca al usuario
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE id = p_from_account_id AND usuario_id = p_user_id) THEN
        RAISE EXCEPTION 'La cuenta origen no pertenece al usuario';
    END IF;
    
    -- Obtener estado de cuenta origen
    SELECT nombre INTO v_from_estado_nombre
    FROM estadoCuenta
    WHERE id = v_from_estado;
    
    -- Validar que la cuenta origen este activa
    IF v_from_estado_nombre != 'Activa' THEN
        RAISE EXCEPTION 'La cuenta origen no está activa. Estado: %', v_from_estado_nombre;
    END IF;
    
    -- Validar saldo suficiente
    IF v_from_saldo < p_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente. Saldo: %, Monto: %', v_from_saldo, p_amount;
    END IF;
    
    -- Obtener datos de cuenta destino
    SELECT moneda, estado INTO v_to_moneda, v_to_estado
    FROM cuenta
    WHERE id = p_to_account_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta destino no existe';
    END IF;
    
    -- Obtener estado de cuenta destino
    SELECT nombre INTO v_to_estado_nombre
    FROM estadoCuenta
    WHERE id = v_to_estado;
    
    -- Validar que la cuenta destino pueda recibir dinero
    IF v_to_estado_nombre = 'Cerrada' THEN
        RAISE EXCEPTION 'No se puede transferir a una cuenta cerrada';
    END IF;
    
    -- Validar que las monedas coincidan
    IF v_from_moneda != p_currency OR v_to_moneda != p_currency THEN
        RAISE EXCEPTION 'Las monedas no coinciden';
    END IF;
    
    -- Obtener IDs de tipos de movimiento
    SELECT id INTO v_tipo_debito FROM tipoMovimientoCuenta WHERE nombre = 'Debito';
    SELECT id INTO v_tipo_credito FROM tipoMovimientoCuenta WHERE nombre = 'Credito';
    
    -- Generar número de recibo único
    v_receipt_number := 'TRF-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD-HH24MISS') || '-' || SUBSTRING(p_from_account_id::TEXT, 1, 8);
    v_transfer_id := gen_random_uuid();
    
    -- Actualizar saldo de cuenta origen (debito)
    UPDATE cuenta
    SET 
        saldo = saldo - p_amount,
        fecha_actu = CURRENT_TIMESTAMP
    WHERE id = p_from_account_id;
    
    -- Insertar movimiento en cuenta origen
    INSERT INTO movimientoCuenta (
        cuenta_id,
        fecha,
        tipo,
        descripcion,
        moneda,
        monto
    ) VALUES (
        p_from_account_id,
        CURRENT_TIMESTAMP,
        v_tipo_debito,
        'Transferencia enviada: ' || p_description || ' - Ref: ' || v_receipt_number,
        p_currency,
        p_amount
    );
    
    -- Actualizar saldo de cuenta destino 
    UPDATE cuenta
    SET 
        saldo = saldo + p_amount,
        fecha_actu = CURRENT_TIMESTAMP
    WHERE id = p_to_account_id;
    
    -- Insertar movimiento en cuenta destino
    INSERT INTO movimientoCuenta (
        cuenta_id,
        fecha,
        tipo,
        descripcion,
        moneda,
        monto
    ) VALUES (
        p_to_account_id,
        CURRENT_TIMESTAMP,
        v_tipo_credito,
        'Transferencia recibida: ' || p_description || ' - Ref: ' || v_receipt_number,
        p_currency,
        p_amount
    );
    
    -- Registrar en auditoria
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            p_user_id,
            'TRANSFERENCIA_INTERNA',
            'cuenta',
            p_from_account_id,
            jsonb_build_object(
                'from_account', p_from_account_id,
                'to_account', p_to_account_id,
                'amount', p_amount,
                'receipt', v_receipt_number
            )
        );
    END IF;
    
    -- Retornar resultado
    RETURN QUERY
    SELECT v_transfer_id, v_receipt_number, 'exitoso'::VARCHAR;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al realizar transferencia: %', SQLERRM;
END;
$$;
