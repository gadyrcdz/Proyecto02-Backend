-- ============================================
-- SP: sp_users_create
-- Descripción: Crea un nuevo usuario validando unicidad
-- ============================================
CREATE OR REPLACE FUNCTION sp_users_create(
    p_tipo_identificacion UUID,
    p_identificacion VARCHAR,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_correo VARCHAR,
    p_telefono VARCHAR,
    p_usuario VARCHAR,
    p_contrasena_hash VARCHAR,
    p_rol UUID
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tipoIdentificacion WHERE id = p_tipo_identificacion) THEN
        RAISE EXCEPTION 'Tipo de identificación inválido';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM rol WHERE id = p_rol) THEN
        RAISE EXCEPTION 'Rol inválido';
    END IF;
    
    IF EXISTS (SELECT 1 FROM usuario WHERE identificacion = p_identificacion) THEN
        RAISE EXCEPTION 'La identificación % ya está registrada', p_identificacion;
    END IF;
    
    IF EXISTS (SELECT 1 FROM usuario WHERE correo = p_correo) THEN
        RAISE EXCEPTION 'El correo % ya está registrado', p_correo;
    END IF;
    
    IF EXISTS (SELECT 1 FROM usuario WHERE usuario = p_usuario) THEN
        RAISE EXCEPTION 'El nombre de usuario % ya existe', p_usuario;
    END IF;
    
    INSERT INTO usuario (
        tipo_identificacion,
        identificacion,
        nombre,
        apellido,
        correo,
        telefono,
        usuario,
        contrasena_hash,
        rol,
        fecha_creacion,
        fecha_actualizacion
    ) VALUES (
        p_tipo_identificacion,
        p_identificacion,
        p_nombre,
        p_apellido,
        p_correo,
        p_telefono,
        p_usuario,
        p_contrasena_hash,
        p_rol,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_user_id;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            v_user_id,
            'CREAR_USUARIO',
            'usuario',
            v_user_id,
            jsonb_build_object(
                'nombre', p_nombre,
                'apellido', p_apellido,
                'correo', p_correo
            )
        );
    END IF;
    
    RETURN v_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al crear usuario: %', SQLERRM;
END;
$$;

-- ============================================
-- SP: sp_users_get_by_identification
-- Descripción: Obtiene usuario por identificación
-- ============================================
CREATE OR REPLACE FUNCTION sp_users_get_by_identification(
    p_identificacion VARCHAR
)
RETURNS TABLE (
    id UUID,
    tipo_identificacion UUID,
    tipo_identificacion_nombre VARCHAR,
    identificacion VARCHAR,
    nombre VARCHAR,
    apellido VARCHAR,
    correo VARCHAR,
    telefono VARCHAR,
    usuario VARCHAR,
    rol UUID,
    rol_nombre VARCHAR,
    fecha_creacion TIMESTAMP,
    fecha_actu TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.tipo_identificacion,
        ti.nombre AS tipo_identificacion_nombre,
        u.identificacion,
        u.nombre,
        u.apellido,
        u.correo,
        u.telefono,
        u.usuario,
        u.rol,
        r.nombre AS rol_nombre,
        u.fecha_creacion,
        u.fecha_actu
    FROM usuario u
    INNER JOIN tipoIdentificacion ti ON u.tipo_identificacion = ti.id
    INNER JOIN rol r ON u.rol = r.id
    WHERE u.identificacion = p_identificacion;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario con identificación % no encontrado', p_identificacion;
    END IF;
END;
$$;


-- ============================================
-- SP: sp_users_update
-- Descripción: Actualiza información de un usuario
-- ============================================
CREATE OR REPLACE FUNCTION sp_users_update(
    p_user_id UUID,
    p_nombre VARCHAR DEFAULT NULL,
    p_apellido VARCHAR DEFAULT NULL,
    p_correo VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL,
    p_usuario VARCHAR DEFAULT NULL,
    p_rol UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated BOOLEAN := FALSE;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_user_id;
    END IF;
    
    IF p_correo IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE correo = p_correo AND id != p_user_id) THEN
            RAISE EXCEPTION 'El correo % ya está registrado por otro usuario', p_correo;
        END IF;
    END IF;
    
    IF p_usuario IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM usuario WHERE usuario = p_usuario AND id != p_user_id) THEN
            RAISE EXCEPTION 'El nombre de usuario % ya existe', p_usuario;
        END IF;
    END IF;
    
    IF p_rol IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM rol WHERE id = p_rol) THEN
            RAISE EXCEPTION 'Rol inválido';
        END IF;
    END IF;
    
    UPDATE usuario
    SET 
        nombre = COALESCE(p_nombre, nombre),
        apellido = COALESCE(p_apellido, apellido),
        correo = COALESCE(p_correo, correo),
        telefono = COALESCE(p_telefono, telefono),
        usuario = COALESCE(p_usuario, usuario),
        rol = COALESCE(p_rol, rol),
        fecha_actu = CURRENT_TIMESTAMP
    WHERE id = p_user_id;
    
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    
    IF v_updated AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            p_user_id,
            'ACTUALIZAR_USUARIO',
            'usuario',
            p_user_id,
            jsonb_build_object(
                'nombre', p_nombre,
                'apellido', p_apellido,
                'correo', p_correo,
                'usuario', p_usuario
            )
        );
    END IF;
    
    RETURN v_updated > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al actualizar usuario: %', SQLERRM;
END;
$$;



-- ============================================
-- SP: sp_users_delete
-- Descripción: Elimina un usuario y sus datos asociados
-- ============================================
CREATE OR REPLACE FUNCTION sp_users_delete(
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted BOOLEAN := FALSE;
    v_usuario_info RECORD;
BEGIN
    SELECT usuario, correo INTO v_usuario_info
    FROM usuario 
    WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario con ID % no existe', p_user_id;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditoria') THEN
        PERFORM registrar_auditoria(
            p_user_id,
            'ELIMINAR_USUARIO',
            'usuario',
            p_user_id,
            jsonb_build_object(
                'usuario', v_usuario_info.usuario,
                'correo', v_usuario_info.correo
            )
        );
    END IF;
    
    DELETE FROM usuario WHERE id = p_user_id;
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    
    RETURN v_deleted > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar usuario: %', SQLERRM;
END;
$$;
