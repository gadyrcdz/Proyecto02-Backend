CREATE TABLE IF NOT EXISTS rol (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	nombre varchar(50) NOT NULL UNIQUE,
	descripcion TEXT


);

CREATE TABLE IF NOT EXISTS tipoIdentificacion (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	nombre varchar(50) NOT NULL UNIQUE,
	descripcion TEXT


);

CREATE TABLE IF NOT EXISTS tipoCuenta (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	nombre varchar(50) NOT NULL ,
	descripcion TEXT

);

CREATE TABLE IF NOT EXISTS moneda (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	nombre varchar(50) NOT NULL ,
	iso  varchar(50)

);


CREATE TABLE IF NOT EXISTS estadoCuenta (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	nombre varchar(50) NOT NULL UNIQUE,
	descripcion TEXT


);

drop table movimientoCuenta;
CREATE TABLE IF NOT EXISTS movimientoCuenta(
	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	cuenta_id UUID NOT NULL	,
	CONSTRAINT fk_movimientoCuenta_cuenta FOREIGN KEY (cuenta_id) REFERENCES Cuenta(id),
	fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	tipo UUID NOT NULL,
	CONSTRAINT fk_movimientoCuenta_tipoMovCuenta FOREIGN KEY (tipo) REFERENCES tipoMovimientoCuenta(id),
	descripcion VARCHAR(300),
	moneda UUID NOT NULL,
	CONSTRAINT fk_movimientoCuenta_moneda FOREIGN KEY (moneda) REFERENCES moneda(id),
	monto DECIMAL(18,2) DEFAULT 0.00 CHECK (monto >= 0)

);




CREATE TABLE IF NOT EXISTS tipoTarjeta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tipoMovimientoCuenta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tipoMovimientoTarjeta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS usuario(
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	tipo_identificacion UUID NOT NULL,
	CONSTRAINT fk_usuario_tipo_identificacion FOREIGN KEY (tipo_identificacion) REFERENCES tipoIdentificacion(id),
	identificacion VARCHAR(50),
	nombre VARCHAR(50),
	apellido VARCHAR(50),
	correo VARCHAR(50),
	telefono VARCHAR(50),
	usuario VARCHAR(50),
	contrasenia_hash VARCHAR(300),
	rol UUID NOT NULL,
	CONSTRAINT fk_usuario_rol FOREIGN KEY (rol) REFERENCES rol(id),
	fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	fecha_actu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	
);



CREATE TABLE IF NOT EXISTS cuenta (

	id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
	usuario_id UUID NOT NULL,
	CONSTRAINT fk_cuenta_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id),
	iban VARCHAR(50),
	aliass VARCHAR(50),
	tipoCuenta UUID NOT NULL,
	CONSTRAINT fk_cuenta_tipoCuenta FOREIGN KEY (tipoCuenta) REFERENCES tipoCuenta(id),
	moneda UUID NOT NULL,
	CONSTRAINT fk_cuenta_moneda FOREIGN KEY (moneda) REFERENCES moneda(id),
	saldo NUMERIC(18, 2),
	estado UUID NOT NULL,
	CONSTRAINT fk_cuenta_estadoCuenta FOREIGN KEY (estado) REFERENCES estadoCuenta(id),
	fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	fecha_actu TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	


);




INSERT INTO rol(nombre, descripcion) VALUES 
('Administrador',  'Administrador del banco DYG'),
('Cliente', 'cliente del banco con acceso limitado')
ON CONFLICT(nombre) DO NOTHING;

SELECT * FROM rol;