-- ============================================
-- SP: sp_account_movements_list
-- Descripción: Lista movimientos de cuenta con filtros y paginación
-- ============================================
CREATE OR REPLACE FUNCTION sp_account_movements_list(
    p_account_id UUID,
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
    -- Validar que la cuenta exista
    IF NOT EXISTS (SELECT 1 FROM cuenta WHERE id = p_account_id) THEN
        RAISE EXCEPTION 'Cuenta con ID % no existe', p_account_id;
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
    
    -- Contar total de registros (antes de paginar)
    SELECT COUNT(*) INTO v_total
    FROM movimientoCuenta mc
    WHERE mc.cuenta_id = p_account_id
      AND (p_from_date IS NULL OR mc.fecha >= p_from_date)
      AND (p_to_date IS NULL OR mc.fecha <= p_to_date)
      AND (p_type IS NULL OR mc.tipo = p_type)
      AND (p_q IS NULL OR mc.descripcion ILIKE '%' || p_q || '%');
    
    -- Obtener items paginados
    SELECT jsonb_agg(row_data)
    INTO v_items
    FROM (
        SELECT jsonb_build_object(
            'id', mc.id,
            'cuenta_id', mc.cuenta_id,
            'fecha', mc.fecha,
            'tipo', jsonb_build_object(
                'id', tmc.id,
                'nombre', tmc.nombre,
                'descripcion', tmc.descripcion
            ),
            'descripcion', mc.descripcion,
            'moneda', jsonb_build_object(
                'id', m.id,
                'nombre', m.nombre,
                'iso', m.iso
            ),
            'monto', mc.monto
        ) as row_data
        FROM movimientoCuenta mc
        INNER JOIN tipoMovimientoCuenta tmc ON mc.tipo = tmc.id
        INNER JOIN moneda m ON mc.moneda = m.id
        WHERE mc.cuenta_id = p_account_id
          AND (p_from_date IS NULL OR mc.fecha >= p_from_date)
          AND (p_to_date IS NULL OR mc.fecha <= p_to_date)
          AND (p_type IS NULL OR mc.tipo = p_type)
          AND (p_q IS NULL OR mc.descripcion ILIKE '%' || p_q || '%')
        ORDER BY mc.fecha DESC 
        LIMIT p_page_size
        OFFSET v_offset
    ) subquery;
    
    -- Si no hay resultados, retornar array vacíoio
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
