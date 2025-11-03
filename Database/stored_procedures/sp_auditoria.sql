-- ============================================
-- MÓDULO DE AUDITORÍA - PUNTOS EXTRAS
-- ============================================

-- ============================================
-- Función auxiliar: registrar_auditoria
-- Descripción: Registra un evento en la tabla de auditoría
-- ============================================
CREATE OR REPLACE FUNCTION registrar_auditoria(
    p_usuario_id UUID,
    p_accion VARCHAR,
    p_entidad VARCHAR,
    p_entidad_id UUID,
    p_detalles JSONB
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_audit_id UUID;
BEGIN
    INSERT INTO auditoria (
        usuario_id,
        accion,
        entidad,
        entidad_id,
        detalles,
        fecha
    ) VALUES (
        p_usuario_id,
        p_accion,
        p_entidad,
        p_entidad_id,
        p_detalles,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error al registrar auditoría: %', SQLERRM;
        RETURN NULL;
END;
$$;


-- ============================================
-- SP: sp_audit_list_by_user
-- Descripción: Lista eventos de auditoría de un usuario con filtros y paginación
-- ============================================
CREATE OR REPLACE FUNCTION sp_audit_list_by_user(
    p_user_id UUID,
    p_from_date TIMESTAMP DEFAULT NULL,
    p_to_date TIMESTAMP DEFAULT NULL,
    p_accion VARCHAR DEFAULT NULL,
    p_entidad VARCHAR DEFAULT NULL,
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
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_user_id;
    END IF;
    
    IF p_page < 1 THEN
        p_page := 1;
    END IF;
    
    IF p_page_size < 1 OR p_page_size > 100 THEN
        p_page_size := 10;
    END IF;
    
    v_offset := (p_page - 1) * p_page_size;
    
    SELECT COUNT(*) INTO v_total
    FROM auditoria a
    WHERE a.usuario_id = p_user_id
      AND (p_from_date IS NULL OR a.fecha >= p_from_date)
      AND (p_to_date IS NULL OR a.fecha <= p_to_date)
      AND (p_accion IS NULL OR a.accion = p_accion)
      AND (p_entidad IS NULL OR a.entidad = p_entidad);
    
    SELECT jsonb_agg(row_data)
    INTO v_items
    FROM (
        SELECT jsonb_build_object(
            'id', a.id,
            'usuario_id', a.usuario_id,
            'usuario_nombre', CONCAT(u.nombre, ' ', u.apellido),
            'accion', a.accion,
            'entidad', a.entidad,
            'entidad_id', a.entidad_id,
            'detalles', a.detalles,
            'fecha', a.fecha
        ) as row_data
        FROM auditoria a
        INNER JOIN usuario u ON a.usuario_id = u.id
        WHERE a.usuario_id = p_user_id
          AND (p_from_date IS NULL OR a.fecha >= p_from_date)
          AND (p_to_date IS NULL OR a.fecha <= p_to_date)
          AND (p_accion IS NULL OR a.accion = p_accion)
          AND (p_entidad IS NULL OR a.entidad = p_entidad)
        ORDER BY a.fecha DESC
        LIMIT p_page_size
        OFFSET v_offset
    ) subquery;
    
    IF v_items IS NULL THEN
        v_items := '[]'::jsonb;
    END IF;
    
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
-- SP: sp_audit_get_actions_summary
-- Descripción: Obtiene un resumen de acciones por tipo para un usuario
-- (OPCIONAL - útil para dashboards)
-- ============================================
CREATE OR REPLACE FUNCTION sp_audit_get_actions_summary(
    p_user_id UUID,
    p_from_date TIMESTAMP DEFAULT NULL,
    p_to_date TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    accion VARCHAR,
    cantidad BIGINT,
    ultima_fecha TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.accion,
        COUNT(*) as cantidad,
        MAX(a.fecha) as ultima_fecha
    FROM auditoria a
    WHERE a.usuario_id = p_user_id
      AND (p_from_date IS NULL OR a.fecha >= p_from_date)
      AND (p_to_date IS NULL OR a.fecha <= p_to_date)
    GROUP BY a.accion
    ORDER BY cantidad DESC;
END;
$$;


-- ============================================
-- EJEMPLOS DE USO
-- ============================================

-- 1. Listar auditoría de un usuario

-- SELECT * FROM sp_audit_list_by_user(
--     'c935d8bb-4428-4228-849e-a8d9c38b97fe',          -- user_id
--     NULL,                    -- from_date (opcional)
--     NULL,                    -- to_date (opcional)
--     NULL,                    -- accion (opcional)
--     NULL,                    -- entidad (opcional)
--     1,                       -- page
--     10                       -- page_size
-- );


-- 2. Filtrar por acción específica

-- SELECT * FROM sp_audit_list_by_user(
--     'b4b8946b-ed47-479a-82c6-3f9b85d6e2ec',
--     NULL,
--     NULL,
--     'TRANSFERENCIA_INTERNA',  -- solo transferencias
--     NULL,
--     1,
--     10
-- );


-- 3. Filtrar por entidad

-- SELECT * FROM sp_audit_list_by_user(
--     'b4b8946b-ed47-479a-82c6-3f9b85d6e2ec',
--     NULL,
--     NULL,
--     NULL,
--     'cuenta',                 -- solo operaciones en cuentas
--     1,
--     10
-- );


-- 4. Filtrar por rango de fechas

-- SELECT * FROM sp_audit_list_by_user(
--     'b4b8946b-ed47-479a-82c6-3f9b85d6e2ec',
--     '2025-01-01'::TIMESTAMP,
--     '2025-12-31'::TIMESTAMP,
--     NULL,
--     NULL,
--     1,
--     10
-- );


-- 5. Obtener resumen de acciones

-- SELECT * FROM sp_audit_get_actions_summary(
--     'b4b8946b-ed47-479a-82c6-3f9b85d6e2ec',
--     '2025-01-01'::TIMESTAMP,
--     '2025-12-31'::TIMESTAMP
-- );


