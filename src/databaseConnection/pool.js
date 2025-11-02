const { Pool } = require('pg');
const config = require('../config/config');

// Crear pool de conexiones
const pool = new Pool(config.database);

// Evento: conexión exitosa
pool.on('connect', () => {
    console.log('Conectado a la base de datos PostgreSQL');
});

// Evento: error en la conexión
pool.on('error', (err) => {
    console.error('Error inesperado en el pool de PostgreSQL:', err);
    process.exit(-1);
});

// Funcion helper para ejecutar queries
const query = async (text, params) => {
    const start = Date.now();
    try {
        const res = await pool.query(text, params);
        const duration = Date.now() - start;
        console.log('Query ejecutado:', { text, duration, rows: res.rowCount });
        return res;
    } catch (error) {
        console.error('Error en query:', { text, error: error.message });
        throw error;
    }
};

// Funcion para verificar la conexion
const testConnection = async () => {
    try {
        const result = await pool.query('SELECT NOW()');
        console.log('Conexión a BD verificada:', result.rows[0].now);
        return true;
    } catch (error) {
        console.error('Error al conectar con la BD:', error.message);
        return false;
    }
};

module.exports = {
    pool,
    query,
    testConnection
};