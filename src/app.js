const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const config = require('./config/config');
const { errorHandler, notFound } = require('./utils/errorHandler');

// Crear aplicacion Express
const app = express();

// ============================================
// MIDDLEWARES GLOBALES
// ============================================

// Seguridad HTTP headers
app.use(helmet());

// CORS
app.use(cors({
    origin: config.corsOrigin,
    credentials: true
}));

// Parsear JSON
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
    windowMs: config.rateLimit.windowMs,
    max: config.rateLimit.max,
    message: {
        success: false,
        message: 'Demasiadas peticiones, intenta de nuevo más tarde'
    }
});
app.use('/api/', limiter);

// Logger simple (en desarrollo)
if (config.nodeEnv === 'development') {
    app.use((req, res, next) => {
        console.log(`${req.method} ${req.path}`);
        next();
    });
}

// ============================================
// RUTAS
// ============================================

// Ruta de health check
app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'API funcionando correctamente',
        timestamp: new Date().toISOString()
    });
});

// Rutas de la API v1
// TODO: Importar y usar rutas aquí
// const authRoutes = require('./routes/auth.routes');
// app.use('/api/v1/auth', authRoutes);

// ============================================
// MANEJO DE ERRORES
// ============================================

// Ruta no encontrada (404)
app.use(notFound);

// Manejador global de errores
app.use(errorHandler);

module.exports = app;