-- ============================================
-- SP: sp_cards_create
-- Descripción: Crea una nueva tarjeta con datos cifrados
-- ============================================
CREATE OR REPLACE FUNCTION sp_cards_create(
    p_usuario_id UUID,
    p_tipo UUID,
    p_numero_enmascarado VARCHAR,
    p_fecha_expiracion VARCHAR,
    p_cvv_hash VARCHAR,
    p_pin_hash VARCHAR,
    p_moneda UUID,
    p_limite_credito DECIMAL(18,2),
    p_saldo_actual DECIMAL(18,2)
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_card_id UUID;
BEGIN
    -- Validar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_usuario_id) THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_usuario_id;
    END IF;
    
    -- Validar que el tipo de tarjeta exista
    IF NOT EXISTS (SELECT 1 FROM tipoTarjeta WHERE id = p_tipo) THEN
        RAISE EXCEPTION 'Tipo de tarjeta inválido';
    END IF;
    
    -- Validar que la moneda exista
    IF NOT EXISTS (SELECT 1 FROM moneda WHERE id = p_moneda) THEN
        RAISE EXCEPTION 'Moneda inválida';
    END IF;
    
    -- Validar limite de credito
    IF p_limite_credito < 0 THEN
        RAISE EXCEPTION 'El límite de crédito no puede ser negativo';
    END IF;
    
    -- Validar saldo actual
    IF p_saldo_actual < 0 THEN
        RAISE EXCEPTION 'El saldo actual no puede ser negativo';
    END IF;
    
    -- Validar que saldo no supere límite
    IF p_saldo_actual > p_limite_credito THEN
        RAISE EXCEPTION 'El saldo actual (%) no puede superar el límite de crédito (%)', 
                        p_saldo_actual, p_limite_credito;
    END IF;
    
    -- Validar unicidad del numero enmascarado 
    IF EXISTS (SELECT 1 FROM tarjeta WHERE numero_enmascarado = p_numero_enmascarado) THEN
        RAISE EXCEPTION 'El número de tarjeta % ya existe', p_numero_enmascarado;
    END IF;
    
    -- Insertar la tarjeta
    INSERT INTO tarjeta (
        usuario_id,
        tipo,
        numero_enmascarado,
        fecha_expiracion,
        cvv_hash,
        pin_hash,
        moneda,
        limite_credito,
        saldo_actual,
        fecha_creacion,
        fecha_actualizacion
    ) VALUES (
        p_usuario_id,
        p_tipo,
        p_numero_enmascarado,
        p_fecha_expiracion,
        p_cvv_hash,
        p_pin_hash,
        p_moneda,
        p_limite_credito,
        p_saldo_actual,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_card_id;
    
    -- Registrar en auditoria
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            p_usuario_id,
            'CREAR_TARJETA',
            'tarjeta',
            v_card_id,
            jsonb_build_object(
                'numero_enmascarado', p_numero_enmascarado,
                'limite_credito', p_limite_credito
            )
        );
    END IF;
    
    RETURN v_card_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al crear tarjeta: %', SQLERRM;
END;
$$;


-- ============================================
-- SP: sp_cards_get
-- Descripción: Obtiene tarjetas por usuario o una tarjeta específica
-- ============================================
-- DROP FUNCTION sp_cards_get;
CREATE OR REPLACE FUNCTION sp_cards_get(
    p_owner_id UUID DEFAULT NULL,
    p_card_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    usuario_id UUID,
    usuario_nombre TEXT,
    tipo UUID,
    tipo_nombre VARCHAR,
    numero_enmascarado VARCHAR,
    fecha_expiracion VARCHAR,
    moneda UUID,
    moneda_nombre VARCHAR,
    moneda_iso VARCHAR,
    limite_credito DECIMAL(18,2),
    saldo_actual DECIMAL(18,2),
    saldo_disponible DECIMAL(18,2),
    fecha_creacion TIMESTAMP,
    fecha_actualizacion TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que al menos un parametro sea proporcionado
    IF p_owner_id IS NULL AND p_card_id IS NULL THEN
        RAISE EXCEPTION 'Debe proporcionar owner_id o card_id';
    END IF;
    
    RETURN QUERY
    SELECT 
        t.id,
        t.usuario_id,
        CONCAT(u.nombre, ' ', u.apellido) AS usuario_nombre,
        t.tipo,
        tt.nombre AS tipo_nombre,
        t.numero_enmascarado,
        t.fecha_expiracion,
        t.moneda,
        m.nombre AS moneda_nombre,
        m.iso AS moneda_iso,
        t.limite_credito,
        t.saldo_actual,
        (t.limite_credito - t.saldo_actual) AS saldo_disponible,
        t.fecha_creacion,
        t.fecha_actualizacion
    FROM tarjeta t
    INNER JOIN usuario u ON t.usuario_id = u.id
    INNER JOIN tipoTarjeta tt ON t.tipo = tt.id
    INNER JOIN moneda m ON t.moneda = m.id
    WHERE (p_owner_id IS NULL OR t.usuario_id = p_owner_id)
      AND (p_card_id IS NULL OR t.id = p_card_id)
    ORDER BY t.fecha_creacion DESC;
END;
$$;
