const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');

const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const app = express();

// Seguridad HTTP headers (ISO 27000 / OWASP) y limpieza de XSS.
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'blob:', 'http:', 'https:'],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        upgradeInsecureRequests: [],
      },
    },
    referrerPolicy: {
      policy: 'strict-origin-when-cross-origin',
    },
  })
);

// CORS flexible para desarrollo y producción
const clientOrigin = process.env.CLIENT_ORIGIN || 'http://localhost:3000';

// En desarrollo, permitir todos los orígenes para facilitar pruebas
const isDevelopment = process.env.NODE_ENV === 'development';

app.use(
  cors({
    origin: isDevelopment ? true : [clientOrigin, 'http://localhost:3000', 'http://127.0.0.1:3000'],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
    optionsSuccessStatus: 200,
  })
);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(mongoSanitize());
app.use(xss());

// Confía en el proxy (para ejecución en nube / contenedores behind proxy)
app.set('trust proxy', 1);

const path = require('path');
// Servir directorio static de uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

app.use('/api', routes);

// Health endpoint mejorado: verifica estado completo de la aplicación
app.get('/health', async (req, res) => {
  const mongoose = require('mongoose');
  const startTime = process.hrtime();
  
  try {
    // Estado de MongoDB
    let mongoStatus = 'disconnected';
    let mongoReadyState = 0;
    let mongoHost = 'N/A';
    let mongoDb = 'N/A';
    
    if (mongoose.connection && mongoose.connection.readyState !== 0) {
      mongoReadyState = mongoose.connection.readyState;
      mongoHost = mongoose.connection.host || 'N/A';
      mongoDb = mongoose.connection.name || 'N/A';
      
      // readyState: 0 = disconnected, 1 = connected, 2 = connecting, 3 = disconnecting
      switch (mongoReadyState) {
        case 1:
          mongoStatus = 'connected';
          break;
        case 2:
          mongoStatus = 'connecting';
          break;
        case 3:
          mongoStatus = 'disconnecting';
          break;
        default:
          mongoStatus = 'disconnected';
      }
    }

    // Calcular uptime del servidor
    const uptimeSeconds = process.uptime();
    const uptimeFormatted = formatUptime(uptimeSeconds);
    
    // Información del servidor
    const serverInfo = {
      status: mongoStatus === 'connected' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: uptimeFormatted,
      uptimeSeconds: Math.floor(uptimeSeconds),
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '1.0.0',
      nodeVersion: process.version,
      platform: process.platform,
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + 'MB',
        external: Math.round(process.memoryUsage().external / 1024 / 1024) + 'MB'
      },
      database: {
        status: mongoStatus,
        readyState: mongoReadyState,
        host: mongoHost,
        database: mongoDb,
        connected: mongoStatus === 'connected'
      },
      api: {
        endpoints: '/api',
        methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
        cors: process.env.NODE_ENV === 'development' ? 'enabled (all origins)' : 'restricted'
      },
      responseTime: Math.round((process.hrtime(startTime)[0] * 1000 + process.hrtime(startTime)[1] / 1000000)) + 'ms'
    };

    // Determinar código de estado HTTP
    const statusCode = mongoStatus === 'connected' ? 200 : 503;
    
    res.status(statusCode).json(serverInfo);
    
  } catch (error) {
    console.error('Error en health check:', error);
    res.status(500).json({
      status: 'error',
      timestamp: new Date().toISOString(),
      error: error.message,
      database: { status: 'error' }
    });
  }
});

// Función auxiliar para formatear uptime
function formatUptime(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);
  
  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m ${secs}s`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m ${secs}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`;
  } else {
    return `${secs}s`;
  }
}

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
