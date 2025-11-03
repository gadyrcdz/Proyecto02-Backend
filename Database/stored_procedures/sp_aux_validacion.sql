-- ============================================
-- SP: sp_bank_validate_account
-- Descripción: Valida si una cuenta IBAN existe en el banco
-- ============================================
-- DROP FUNCTION sp_bank_validate_account;
CREATE OR REPLACE FUNCTION sp_bank_validate_account(
    p_iban VARCHAR
)
RETURNS TABLE (
    cuenta_existe BOOLEAN,  -- ← Cambiado de "exists" a "cuenta_existe"
    owner_name TEXT,
    owner_id UUID
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TRUE as cuenta_existe,  -- ← Usar el nuevo nombre
        CONCAT(u.nombre, ' ', u.apellido) as owner_name,
        u.id as owner_id
    FROM cuenta c
    INNER JOIN usuario u ON c.usuario_id = u.id
    WHERE c.iban = p_iban
    LIMIT 1;
    
    -- Si no se encuentra, retornar FALSE
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT FALSE, NULL::VARCHAR, NULL::UUID;
    END IF;
END;
$$;
