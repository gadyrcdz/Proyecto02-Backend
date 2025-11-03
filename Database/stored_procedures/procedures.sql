
CREATE OR REPLACE FUNCTION sp_api_key_is_active(p_api_key_hash varchar)
RETURNS TABLE(
	activa boolean
)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY
	SELECT a.activa as estadoKey
	FROM apiKey a
	where a.clave_hash = p_api_key_hash;
END;
$$;


------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sp_auth_user_get_by_username_or_email(p_username_or_email varchar)
RETURNS TABLE(
	user_id UUID,
	contrasenia_hash varchar,
	rol UUID
)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY 
	SELECT u.id as user_id, u.contrasenia_hash, u.rol
	FROM usuario u
	where u.correo = p_username_or_email OR u.usuario = p_username_or_email
	LIMIT 1;
END;
$$;

-------------------------------------------------------------------------------------------
-- ============================================
-- SP: sp_otp_create
-- Descripción: Crea un OTP cifrado con proposito especifico
-- ============================================

CREATE OR REPLACE FUNCTION sp_otp_create(
    p_user_id UUID,
    p_proposito VARCHAR,
    p_expires_in_seconds INTEGER,
    p_codigo_hash VARCHAR
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_otp_id UUID;
    v_fecha_expiracion TIMESTAMP;
BEGIN
    v_fecha_expiracion := CURRENT_TIMESTAMP + (p_expires_in_seconds || ' seconds')::INTERVAL;
    
    INSERT INTO otps (
        usuario_id,
        codigo_hash,
        proposito,
        fecha_expiracion,
        fecha_consumido,
        fecha_creacion
    ) VALUES (
        p_user_id,
        p_codigo_hash,
        p_proposito,
        v_fecha_expiracion,
        NULL, 
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_otp_id;
    
    RETURN v_otp_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al crear OTP: %', SQLERRM;
END;
$$;
-------------------como usarlo-------------------------------
SELECT sp_otp_create(
    (SELECT id FROM usuario WHERE usuario = 'juanperez'),  -- user_id
    'password_reset',                                       -- proposito
    300,                                                    -- 5 minutos
    '$2b$10$EJEMPLO_HASH_DEL_CODIGO_OTP'                   -- codigo_hash
);
-----------------------------------------------------------------------
-- ============================================
-- SP: sp_otp_consume
-- Descripción: Valida y consume un OTP
-- Retorna: TRUE si el OTP es válido y se consumió, FALSE si no
-- ============================================

CREATE OR REPLACE FUNCTION sp_otp_consume(
    p_user_id UUID,
    p_proposito VARCHAR,
    p_codigo_hash VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_otp_id UUID;
    v_otp_hash VARCHAR;
    v_fecha_expiracion TIMESTAMP;
    v_fecha_consumido TIMESTAMP;
BEGIN
    -- Buscar el OTP más reciente que coincida con los criterios
    SELECT 
        id,
        codigo_hash,
        fecha_expiracion,
        fecha_consumido
    INTO 
        v_otp_id,
        v_otp_hash,
        v_fecha_expiracion,
        v_fecha_consumido
    FROM otps
    WHERE usuario_id = p_user_id
      AND proposito = p_proposito
      AND codigo_hash = p_codigo_hash  -- En PostgreSQL comparamos el hash directamente
    ORDER BY fecha_creacion DESC
    LIMIT 1;
    
    -- Existe el OTP?
    IF v_otp_id IS NULL THEN
        RAISE NOTICE 'OTP no encontrado para usuario % con propósito %', p_user_id, p_proposito;
        RETURN FALSE;
    END IF;
    
    -- Ya fue consumido?
    IF v_fecha_consumido IS NOT NULL THEN
        RAISE NOTICE 'OTP ya fue consumido el %', v_fecha_consumido;
        RETURN FALSE;
    END IF;
    
    -- expirado?
    IF v_fecha_expiracion < CURRENT_TIMESTAMP THEN
        RAISE NOTICE 'OTP expirado. Venció el %', v_fecha_expiracion;
        RETURN FALSE;
    END IF;
    
    -- Marcarlo como consumido
    UPDATE otps
    SET fecha_consumido = CURRENT_TIMESTAMP
    WHERE id = v_otp_id;
    
    RAISE NOTICE 'OTP consumido exitosamente';
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al consumir OTP: %', SQLERRM;
END;
$$;


SELECT * FROM sp_auth_user_get_by_username_or_email('juanperez');
SELECT * FROM sp_api_key_is_active('$2b$10$rKvF3YqMYmCQvL0Vz2QhLuqK.8xdVLxEZlH0pBPJE6QKzW.Xm9bXi');
------------------------------------------------------------------------

