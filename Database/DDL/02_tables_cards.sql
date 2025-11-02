-- ============================================
-- TABLA: tarjeta
-- ============================================
CREATE TABLE IF NOT EXISTS tarjeta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    CONSTRAINT fk_tarjeta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE CASCADE,
    tipo UUID NOT NULL,
    CONSTRAINT fk_tarjeta_tipo FOREIGN KEY (tipo) REFERENCES tipoTarjeta(id),
    
    numero_enmascarado VARCHAR(19) NOT NULL,
    fecha_expiracion VARCHAR(7) NOT NULL,   
    cvv_hash VARCHAR(255) NOT NULL,          
    pin_hash VARCHAR(255) NOT NULL,         
    moneda UUID NOT NULL,
	CONSTRAINT fk_tarjeta_moneda FOREIGN KEY (moneda) REFERENCES moneda(id),
   	limite_credito DECIMAL(18,2) DEFAULT 0.00 CHECK (limite_credito >= 0),
    saldo_actual DECIMAL(18,2) DEFAULT 0.00 CHECK (saldo_actual >= 0),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tarjeta_saldo_limite CHECK (saldo_actual <= limite_credito)
);

-- Indices para mejorar rendimiento
CREATE INDEX idx_tarjeta_usuario_id ON tarjeta(usuario_id);
CREATE INDEX idx_tarjeta_numero_enmascarado ON tarjeta(numero_enmascarado);

CREATE TABLE IF NOT EXISTS movimientoTarjeta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tarjeta_id UUID NOT NULL,
    CONSTRAINT fk_movimiento_tarjeta_tarjeta FOREIGN KEY (tarjeta_id)  REFERENCES tarjeta(id)ON DELETE CASCADE,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tipo UUID NOT NULL,
    CONSTRAINT fk_movimiento_tarjeta_tipo FOREIGN KEY (tipo) REFERENCES tipoMovimientoTarjeta(id),
    descripcion TEXT NOT NULL,
    moneda UUID NOT NULL,
  	CONSTRAINT fk_movimiento_tarjeta_moneda FOREIGN KEY (moneda) REFERENCES moneda(id),
    monto DECIMAL(18,2) NOT NULL CHECK (monto > 0),
    saldo_despues DECIMAL(18,2),
	fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices para mejorar rendimiento en consultas
CREATE INDEX idx_movimiento_tarjeta_tarjeta_id ON movimientoTarjeta(tarjeta_id);
CREATE INDEX idx_movimiento_tarjeta_fecha ON movimientoTarjeta(fecha DESC);
CREATE INDEX idx_movimiento_tarjeta_tipo ON movimientoTarjeta(tipo);


CREATE TABLE IF NOT EXISTS otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    CONSTRAINT fk_otp_usuario  FOREIGN KEY (usuario_id) REFERENCES usuario(id)ON DELETE CASCADE,
    codigo_hash VARCHAR(255) NOT NULL,
    proposito VARCHAR(50) NOT NULL CHECK (
        proposito IN ('password_reset', 'card_details', 'transfer_confirmation')
    ),
    fecha_expiracion TIMESTAMP NOT NULL,
    fecha_consumido TIMESTAMP NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_otp_usado_una_vez CHECK (fecha_consumido IS NULL OR fecha_consumido <= CURRENT_TIMESTAMP)
);

-- indices
CREATE INDEX idx_otp_usuario_id ON otps(usuario_id);
CREATE INDEX idx_otp_proposito ON otps(proposito);
CREATE INDEX idx_otp_fecha_expiracion ON otps(fecha_expiracion);
CREATE INDEX idx_otp_consumido ON otps(fecha_consumido) WHERE fecha_consumido IS NULL;

-- Trigger para limpiar OTPs expirados 
CREATE OR REPLACE FUNCTION limpiar_otps_expirados()
RETURNS void AS $$
BEGIN
    DELETE FROM otps 
    WHERE fecha_expiracion < CURRENT_TIMESTAMP 
      AND fecha_consumido IS NULL;
END;
$$ LANGUAGE plpgsql;


-- ============================================
-- TABLA: apiKey
-- ============================================
CREATE TABLE IF NOT EXISTS apiKey (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave_hash VARCHAR(255) NOT NULL UNIQUE,
    etiqueta VARCHAR(100) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
);

-- Índices
CREATE INDEX idx_apikey_clave_hash ON apiKey(clave_hash);
CREATE INDEX idx_apikey_activa ON apiKey(activa) WHERE activa = TRUE;
CREATE INDEX idx_apikey_creada_por ON apiKey(creada_por);


CREATE TABLE IF NOT EXISTS auditoria (
    id SERIAL PRIMARY KEY, 
    usuario_id UUID NULL, 
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    entidad VARCHAR(50) NULL, 
    entidad_id UUID NULL,    
    detalles JSONB NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    resultado VARCHAR(20) DEFAULT 'exitoso' CHECK (
        resultado IN ('exitoso', 'fallido', 'pendiente')
    ),
    mensaje_error TEXT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- indices para consultas rápidas
CREATE INDEX idx_auditoria_usuario_id ON auditoria(usuario_id);
CREATE INDEX idx_auditoria_accion ON auditoria(accion);
CREATE INDEX idx_auditoria_entidad ON auditoria(entidad, entidad_id);
CREATE INDEX idx_auditoria_fecha ON auditoria(fecha DESC);
CREATE INDEX idx_auditoria_resultado ON auditoria(resultado);

CREATE INDEX idx_auditoria_detalles ON auditoria USING GIN (detalles);
