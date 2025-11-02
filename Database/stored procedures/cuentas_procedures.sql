-- ============================================
-- SP: sp_accounts_create
-- Descripción: Crea una nueva cuenta bancaria
-- ============================================
CREATE OR REPLACE FUNCTION sp_accounts_create(
    p_usuario_id UUID,
    p_iban VARCHAR,
    p_alias VARCHAR,
    p_tipo_cuenta UUID,
    p_moneda UUID,
    p_saldo_inicial DECIMAL(18,2),
    p_estado UUID
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id UUID;
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_usuario_id) THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_usuario_id;
    END IF;
    
    
    IF NOT EXISTS (SELECT 1 FROM tipoCuenta WHERE id = p_tipo_cuenta) THEN
        RAISE EXCEPTION 'Tipo de cuenta inválido';
    END IF;
    
   
    IF NOT EXISTS (SELECT 1 FROM moneda WHERE id = p_moneda) THEN
        RAISE EXCEPTION 'Moneda inválida';
    END IF;
    
    
    IF NOT EXISTS (SELECT 1 FROM estadoCuenta WHERE id = p_estado) THEN
        RAISE EXCEPTION 'Estado de cuenta inválido';
    END IF;
    
    
    IF EXISTS (SELECT 1 FROM cuenta WHERE iban = p_iban) THEN
        RAISE EXCEPTION 'El IBAN % ya existe', p_iban;
    END IF;
    
   
    IF p_saldo_inicial < 0 THEN
        RAISE EXCEPTION 'El saldo inicial no puede ser negativo';
    END IF;
    
   
    INSERT INTO cuenta (
        usuario_id,
        iban,
        aliass,
        tipocuenta,
        moneda,
        saldo,
        estado,
        fecha_creacion,
        fecha_actu
    ) VALUES (
        p_usuario_id,
        p_iban,
        p_alias,
        p_tipo_cuenta,
        p_moneda,
        p_saldo_inicial,
        p_estado,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_account_id;
    
   
    IF p_saldo_inicial > 0 THEN
        INSERT INTO movimientoCuenta (
            cuenta_id,
            fecha,
            tipo,
            descripcion,
            moneda,
            monto
        ) VALUES (
            v_account_id,
            CURRENT_TIMESTAMP,
            (SELECT id FROM tipoMovimientoCuenta WHERE nombre = 'Credito'),
            'Deposito inicial',
            p_moneda,
            p_saldo_inicial
        );
    END IF;
    
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            p_usuario_id,
            'CREAR_CUENTA',
            'cuenta',
            v_account_id,
            jsonb_build_object(
                'iban', p_iban,
                'saldo_inicial', p_saldo_inicial
            )
        );
    END IF;
    
    RETURN v_account_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al crear cuenta: %', SQLERRM;
END;
$$;



-- ============================================
-- SP: sp_accounts_get
-- Descripción: Obtiene cuentas por usuario o una cuenta específica
-- ============================================
-- Drop function sp_accounts_get;
CREATE OR REPLACE FUNCTION sp_accounts_get(
    p_owner_id UUID DEFAULT NULL,
    p_account_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    usuario_id UUID,
    usuario_nombre TEXT,
    iban VARCHAR,
    aliass VARCHAR,
    tipoCuenta UUID,
    tipo_cuenta_nombre VARCHAR,
    moneda UUID,
    moneda_nombre VARCHAR,
    moneda_iso VARCHAR,
    saldo DECIMAL(18,2),
    estado UUID,
    estado_nombre VARCHAR,
    fecha_creacion TIMESTAMP,
    fecha_actu TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_owner_id IS NULL AND p_account_id IS NULL THEN
        RAISE EXCEPTION 'Debe proporcionar owner_id o account_id';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.usuario_id,
        CONCAT(u.nombre, ' ', u.apellido) AS usuario_nombre,
        c.iban,
        c.aliass,
        c.tipoCuenta,
        tc.nombre AS tipo_cuenta_nombre,
        c.moneda,
        m.nombre AS moneda_nombre,
        m.iso AS moneda_iso,
        c.saldo,
        c.estado,
        ec.nombre AS estado_nombre,
        c.fecha_creacion,
        c.fecha_actu
    FROM cuenta c
    INNER JOIN usuario u ON c.usuario_id = u.id
    INNER JOIN tipoCuenta tc ON c.tipoCuenta = tc.id
    INNER JOIN moneda m ON c.moneda = m.id
    INNER JOIN estadoCuenta ec ON c.estado = ec.id
    WHERE (p_owner_id IS NULL OR c.usuario_id = p_owner_id)
      AND (p_account_id IS NULL OR c.id = p_account_id)
    ORDER BY c.fecha_creacion DESC;
END;
$$;



-- ============================================
-- SP: sp_accounts_set_status
-- Descripción: Cambia el estado de una cuenta
-- ============================================
CREATE OR REPLACE FUNCTION sp_accounts_set_status(
    p_account_id UUID,
    p_nuevo_estado UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo DECIMAL(18,2);
    v_estado_actual UUID;
    v_nuevo_estado_nombre VARCHAR;
    v_updated INTEGER := 0;
BEGIN
    SELECT saldo, estado INTO v_saldo, v_estado_actual
    FROM cuenta
    WHERE id = p_account_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta con ID % no existe', p_account_id;
    END IF;
    
    SELECT nombre INTO v_nuevo_estado_nombre
    FROM estadoCuenta
    WHERE id = p_nuevo_estado;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estado de cuenta inválido';
    END IF;
    
    IF v_nuevo_estado_nombre = 'Cerrada' AND v_saldo != 0 THEN
        RAISE EXCEPTION 'No se puede cerrar una cuenta con saldo. Saldo actual: %', v_saldo;
    END IF;
    
    IF v_estado_actual IN (SELECT id FROM estadoCuenta WHERE nombre = 'Cerrada') 
       AND v_nuevo_estado_nombre != 'Cerrada' THEN
        RAISE EXCEPTION 'No se puede reactivar una cuenta cerrada';
    END IF;
    
    UPDATE cuenta
    SET 
        estado = p_nuevo_estado,
        fecha_actu = CURRENT_TIMESTAMP
    WHERE id = p_account_id;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    
    IF v_updated > 0 AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            (SELECT usuario_id FROM cuenta WHERE id = p_account_id),
            'CAMBIAR_ESTADO_CUENTA',
            'cuenta',
            p_account_id,
            jsonb_build_object(
                'nuevo_estado', v_nuevo_estado_nombre,
                'saldo', v_saldo
            )
        );
    END IF;
    
    RETURN v_updated > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al cambiar estado de cuenta: %', SQLERRM;
END;
$$;
