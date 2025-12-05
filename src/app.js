const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const config = require('./config/config');
const { errorHandler, notFound } = require('./utils/errorHandler');
const allowedOrigins = config.corsOrigin;


// Crear aplicacion Express
const app = express();

// ============================================
// MIDDLEWARES GLOBALES
// ============================================

// Seguridad HTTP headers
app.use(helmet());

// CORS
// CORS
app.use(cors({
    origin: function (origin, callback) {
        // Permitir solicitudes sin origin (Postman, Render, curl)
        if (!origin) return callback(null, true);

        if (allowedOrigins === '*' || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('CORS no permitido para este origen: ' + origin));
        }
    },
    credentials: true
}));

// IMPORTANTE: Responder OPTIONS (preflight)
app.options('/', cors());



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
const authRoutes = require('./routes/auth.routes');
const usersRoutes = require('./routes/users.routes');          
const accountsRoutes = require('./routes/accounts.routes');     
const transfersRoutes = require('./routes/transfers.routes');   
const bankRoutes = require('./routes/bank.routes');     
const cardsRoutes = require('./routes/cards.routes'); 
const auditRoutes = require('./routes/audit.routes');
const catalogRoutes = require('./routes/catalog.routes');



// Registrar rutas
app.use('/api/v1', catalogRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', usersRoutes);                          
app.use('/api/v1/accounts', accountsRoutes);                   
app.use('/api/v1/transfers', transfersRoutes);                
app.use('/api/v1/bank', bankRoutes);  
app.use('/api/v1/cards', cardsRoutes);  
app.use('/api/v1/audit', auditRoutes);           


// ============================================
// MANEJO DE ERRORES
// ============================================

// Ruta no encontrada (404)
app.use(notFound);

// Manejador global de errores
app.use(errorHandler);

module.exports = app;