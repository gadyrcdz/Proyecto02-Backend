const app = require('./src/app');
const config = require('./src/config/config');
const { testConnection } = require('./src/databaseConnection/pool');

// Función para iniciar el servidor
const startServer = async () => {
    try {
        // Verificar conexión a la base de datos
        console.log('Verificando conexion');
        const dbConnected = await testConnection();
        
        if (!dbConnected) {
            console.error('No se pudo conectar a la base de datos.');
            process.exit(1);
        }
        
        // Iniciar servidor
        app.listen(config.port, () => {
            console.log('');
            console.log('═══════════════════════════════════════════');
            console.log(`Servidor corriendo en modo: ${config.nodeEnv}`);
            console.log(`URL: http://localhost:${config.port}`);
            console.log(`Health check: http://localhost:${config.port}/health`);
            console.log('═══════════════════════════════════════════');
            console.log('');
        });
    } catch (error) {
        console.error('Error al iniciar el servidor:', error);
        process.exit(1);
    }
};

// Iniciar servidor
startServer();

// Manejo de errores no capturados
process.on('unhandledRejection', (err) => {
    console.error('❌ Unhandled Rejection:', err);
    process.exit(1);
});

process.on('uncaughtException', (err) => {
    console.error('❌ Uncaught Exception:', err);
    process.exit(1);
});