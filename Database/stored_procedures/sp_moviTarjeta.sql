-- ============================================
-- SP: sp_card_movements_list
-- Descripción: Lista movimientos de tarjeta con filtros y paginacion
-- ============================================
CREATE OR REPLACE FUNCTION sp_card_movements_list(
    p_card_id UUID,
    p_from_date TIMESTAMP DEFAULT NULL,
    p_to_date TIMESTAMP DEFAULT NULL,
    p_type UUID DEFAULT NULL,
    p_q VARCHAR DEFAULT NULL,
    p_page INTEGER DEFAULT 1,
    p_page_size INTEGER DEFAULT 10
)
RETURNS TABLE (
    items JSONB,
    total BIGINT,
    page INTEGER,
    page_size INTEGER,
    total_pages INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INTEGER;
    v_total BIGINT;
    v_items JSONB;
BEGIN
    -- Validar que la tarjeta exista
    IF NOT EXISTS (SELECT 1 FROM tarjeta WHERE id = p_card_id) THEN
        RAISE EXCEPTION 'Tarjeta con ID % no existe', p_card_id;
    END IF;
    
    -- Validar page y page_size
    IF p_page < 1 THEN
        p_page := 1;
    END IF;
    
    IF p_page_size < 1 OR p_page_size > 100 THEN
        p_page_size := 10;
    END IF;
    
    -- Calcular offset
    v_offset := (p_page - 1) * p_page_size;
    
    -- Contar total de registros
    SELECT COUNT(*) INTO v_total
    FROM movimientoTarjeta mt
    WHERE mt.tarjeta_id = p_card_id
      AND (p_from_date IS NULL OR mt.fecha >= p_from_date)
      AND (p_to_date IS NULL OR mt.fecha <= p_to_date)
      AND (p_type IS NULL OR mt.tipo = p_type)
      AND (p_q IS NULL OR mt.descripcion ILIKE '%' || p_q || '%');
    
    -- Obtener items paginados (CON SUBCONSULTA)
    SELECT jsonb_agg(row_data)
    INTO v_items
    FROM (
        SELECT jsonb_build_object(
            'id', mt.id,
            'tarjeta_id', mt.tarjeta_id,
            'fecha', mt.fecha,
            'tipo', jsonb_build_object(
                'id', tmt.id,
                'nombre', tmt.nombre,
                'descripcion', tmt.descripcion
            ),
            'descripcion', mt.descripcion,
            'moneda', jsonb_build_object(
                'id', m.id,
                'nombre', m.nombre,
                'iso', m.iso
            ),
            'monto', mt.monto,
            'saldo_despues', mt.saldo_despues
        ) as row_data
        FROM movimientoTarjeta mt
        INNER JOIN tipoMovimientoTarjeta tmt ON mt.tipo = tmt.id
        INNER JOIN moneda m ON mt.moneda = m.id
        WHERE mt.tarjeta_id = p_card_id
          AND (p_from_date IS NULL OR mt.fecha >= p_from_date)
          AND (p_to_date IS NULL OR mt.fecha <= p_to_date)
          AND (p_type IS NULL OR mt.tipo = p_type)
          AND (p_q IS NULL OR mt.descripcion ILIKE '%' || p_q || '%')
        ORDER BY mt.fecha DESC
        LIMIT p_page_size
        OFFSET v_offset
    ) subquery;
    
    -- Si no hay resultados, retornar array vacío
    IF v_items IS NULL THEN
        v_items := '[]'::jsonb;
    END IF;
    
    -- Retornar resultado
    RETURN QUERY
    SELECT 
        v_items,
        v_total,
        p_page,
        p_page_size,
        CEIL(v_total::NUMERIC / p_page_size)::INTEGER as total_pages;
END;
$$;


-- ============================================
-- SP: sp_card_movement_add
-- Descripción: Inserta un movimiento de tarjeta y actualiza saldo
-- ============================================
CREATE OR REPLACE FUNCTION sp_card_movement_add(
    p_card_id UUID,
    p_fecha TIMESTAMP WITH TIME ZONE, 
    p_tipo UUID,
    p_descripcion TEXT,
    p_moneda UUID,
    p_monto DECIMAL(18,2)
)
RETURNS TABLE (
    movement_id UUID,
    nuevo_saldo_tarjeta DECIMAL(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_movement_id UUID;
    v_saldo_actual DECIMAL(18,2);
    v_limite_credito DECIMAL(18,2);
    v_nuevo_saldo DECIMAL(18,2);
    v_tipo_nombre VARCHAR;
    v_moneda_tarjeta UUID;
BEGIN
    -- Validar que la tarjeta exista y obtener datos
    SELECT saldo_actual, limite_credito, moneda 
    INTO v_saldo_actual, v_limite_credito, v_moneda_tarjeta
    FROM tarjeta
    WHERE id = p_card_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tarjeta con ID % no existe', p_card_id;
    END IF;
    
    -- Validar que el tipo de movimiento exista
    SELECT nombre INTO v_tipo_nombre
    FROM tipoMovimientoTarjeta
    WHERE id = p_tipo;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tipo de movimiento inválido';
    END IF;
    
    -- Validar que la moneda exista
    IF NOT EXISTS (SELECT 1 FROM moneda WHERE id = p_moneda) THEN
        RAISE EXCEPTION 'Moneda inválida';
    END IF;
    
    -- Validar que la moneda coincida con la de la tarjeta
    IF p_moneda != v_moneda_tarjeta THEN
        RAISE EXCEPTION 'La moneda del movimiento debe coincidir con la moneda de la tarjeta';
    END IF;
    
    -- Validar monto
    IF p_monto <= 0 THEN
        RAISE EXCEPTION 'El monto debe ser mayor a cero';
    END IF;
    
    -- Calcular nuevo saldo según el tipo
    IF v_tipo_nombre = 'Compra' THEN
        v_nuevo_saldo := v_saldo_actual + p_monto;
        
        -- Validar límite de crédito
        IF v_nuevo_saldo > v_limite_credito THEN
            RAISE EXCEPTION 'Saldo insuficiente. Límite: %, Saldo actual: %, Compra: %', 
                            v_limite_credito, v_saldo_actual, p_monto;
        END IF;
        
    ELSIF v_tipo_nombre = 'Pago' THEN
        v_nuevo_saldo := v_saldo_actual - p_monto;
        
        -- No permitir saldo negativo
        IF v_nuevo_saldo < 0 THEN
            v_nuevo_saldo := 0;
        END IF;
    ELSE
        RAISE EXCEPTION 'Tipo de movimiento no reconocido: %', v_tipo_nombre;
    END IF;
    
    -- Insertar el movimiento
    INSERT INTO movimientoTarjeta (
        tarjeta_id,
        fecha,
        tipo,
        descripcion,
        moneda,
        monto,
        saldo_despues,
        fecha_creacion
    ) VALUES (
        p_card_id,
        p_fecha,
        p_tipo,
        p_descripcion,
        p_moneda,
        p_monto,
        v_nuevo_saldo,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_movement_id;
    
    -- Actualizar saldo de la tarjeta
    UPDATE tarjeta
    SET 
        saldo_actual = v_nuevo_saldo,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id = p_card_id;
    
    -- Registrar en auditoría
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            (SELECT usuario_id FROM tarjeta WHERE id = p_card_id),
            'MOVIMIENTO_TARJETA',
            'movimientoTarjeta',
            v_movement_id,
            jsonb_build_object(
                'tipo', v_tipo_nombre,
                'monto', p_monto,
                'saldo_anterior', v_saldo_actual,
                'saldo_nuevo', v_nuevo_saldo
            )
        );
    END IF;
    
    -- Retornar resultado
    RETURN QUERY
    SELECT v_movement_id, v_nuevo_saldo;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al agregar movimiento de tarjeta: %', SQLERRM;
END;
$$;
