const os = require('os');
const path = require('path');
const fs = require('fs');

// Variables obligatorias para producción
const productionRequiredEnvVars = [
  'JWT_SECRET',
];

// Variables opcionales con valores por defecto
const optionalEnvVars = {
  'PORT': 3000,
  'NODE_ENV': 'development',
  'CLIENT_ORIGIN': '*',
  'SOCKET_PORT': 4000,
  'SOCKET_PATH': '/socket.io',
  'MONGODB_URI': 'mongodb://localhost:27017/musicapp_valledupar',
  'ENABLE_HTTPS': 'false',
  'FORCE_INSECURE': 'false',
  'LOG_LEVEL': 'info',
  'RATE_LIMIT_WINDOW': '900000', // 15 minutos
  'RATE_LIMIT_MAX': '200',
  'CORS_ENABLED': 'true',
  'HEALTH_CHECK_ENABLED': 'true',
  'METRICS_ENABLED': 'false'
};

function detectEnvironment() {
  // Detectar entorno automáticamente
  const env = process.env.NODE_ENV || 'development';
  
  // Detectar si estamos en contenedor Docker
  const isDocker = process.env.DOCKER_ENV === 'true' || 
                   fs.existsSync('/.dockerenv') ||
                   process.env.container === 'docker';
  
  // Detectar si estamos en nube (AWS, Azure, GCP)
  const isCloud = process.env.AWS_REGION || 
                  process.env.AZURE_CLIENT_ID || 
                  process.env.GOOGLE_CLOUD_PROJECT ||
                  process.env.VERCEL ||
                  process.env.HEROKU;
  
  // Detectar si estamos en Railway
  const isRailway = process.env.RAILWAY_ENVIRONMENT ||
                    process.env.RAILWAY_SERVICE_NAME;
  
  // Detectar si estamos en Render
  const isRender = process.env.RENDER ||
                   process.env.RENDER_SERVICE_ID;
  
  return {
    env,
    isDocker,
    isCloud,
    isRailway,
    isRender,
    isProduction: env === 'production',
    isDevelopment: env === 'development',
    isTest: env === 'test'
  };
}

function getNetworkConfig() {
  const detected = detectEnvironment();
  const networkInterfaces = os.networkInterfaces();
  
  // Obtener IPs disponibles
  const ips = [];
  for (const name of Object.keys(networkInterfaces)) {
    for (const net of networkInterfaces[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        ips.push(net.address);
      }
    }
  }
  
  // Configurar host según el entorno
  let host = '0.0.0.0'; // Por defecto escuchar en todas las interfaces
  
  if (detected.isDocker) {
    host = '0.0.0.0'; // En Docker siempre escuchar en todas las interfaces
  } else if (detected.isProduction && !detected.isCloud) {
    host = ips[0] || '0.0.0.0'; // En producción local, usar la primera IP disponible
  } else if (detected.isDevelopment) {
    host = '0.0.0.0'; // En desarrollo, permitir conexiones de cualquier lugar
  }
  
  return {
    host,
    ips,
    primaryIP: ips[0] || 'localhost',
    allInterfaces: host === '0.0.0.0'
  };
}

function getDatabaseConfig() {
  const detected = detectEnvironment();
  
  // Configuración de MongoDB según entorno
  if (detected.isRailway) {
    return process.env.RAILWAY_MONGODB_URI || process.env.MONGODB_URI;
  } else if (detected.isRender) {
    return process.env.RENDER_MONGODB_URI || process.env.MONGODB_URI;
  } else if (detected.isCloud) {
    // Priorizar variables de nube
    return process.env.MONGODB_URI || 
           process.env.MONGODB_URL || 
           process.env.DATABASE_URL ||
           'mongodb://localhost:27017/musicapp_valledupar';
  } else if (detected.isDocker) {
    // En Docker, usar el nombre del servicio MongoDB
    return process.env.MONGODB_URI || 'mongodb://mongodb:27017/musicapp_valledupar';
  } else {
    // Desarrollo local
    return process.env.MONGODB_URI || 'mongodb://localhost:27017/musicapp_valledupar';
  }
}

function getPortConfig() {
  const detected = detectEnvironment();
  
  // Puerto según entorno
  if (process.env.PORT) {
    return parseInt(process.env.PORT);
  } else if (detected.isRailway) {
    return parseInt(process.env.PORT) || 3000;
  } else if (detected.isRender) {
    return parseInt(process.env.PORT) || 3000;
  } else if (detected.isCloud) {
    return parseInt(process.env.PORT) || 3000;
  } else {
    return 3000;
  }
}

function getCORSConfig() {
  const detected = detectEnvironment();
  const network = getNetworkConfig();
  
  if (detected.isProduction) {
    // En producción, ser más restrictivo
    const allowedOrigins = [
      process.env.CLIENT_ORIGIN,
      `http://localhost:${getPortConfig()}`,
      `http://127.0.0.1:${getPortConfig()}`,
    ];
    
    // Agregar IPs locales si no es nube
    if (!detected.isCloud) {
      network.ips.forEach(ip => {
        allowedOrigins.push(`http://${ip}:${getPortConfig()}`);
      });
    }
    
    return allowedOrigins.filter(Boolean);
  } else {
    // En desarrollo, permitir todo
    return true;
  }
}

function validateEnv() {
  const detected = detectEnvironment();
  const network = getNetworkConfig();
  
  console.log('🔧 Entorno detectado:', {
    environment: detected.env,
    platform: os.platform(),
    architecture: os.arch(),
    totalMemory: Math.round(os.totalmem() / 1024 / 1024) + 'MB',
    freeMemory: Math.round(os.freemem() / 1024 / 1024) + 'MB',
    cpus: os.cpus().length,
    network: {
      host: network.host,
      primaryIP: network.primaryIP,
      allIPs: network.ips
    },
    containers: {
      docker: detected.isDocker,
      cloud: detected.isCloud,
      railway: detected.isRailway,
      render: detected.isRender
    }
  });
  
  // Establecer valores por defecto para variables opcionales
  Object.entries(optionalEnvVars).forEach(([key, defaultValue]) => {
    if (!process.env[key]) {
      process.env[key] = defaultValue;
      console.log(`📝 Variable ${key} establecida por defecto: ${defaultValue}`);
    }
  });
  
  // Configurar base de datos automáticamente
  const dbUri = getDatabaseConfig();
  if (!process.env.MONGODB_URI) {
    process.env.MONGODB_URI = dbUri;
    console.log(`🗄️  MONGODB_URI configurada automáticamente: ${dbUri}`);
  }
  
  // Configurar puerto automáticamente
  const port = getPortConfig();
  process.env.PORT = port.toString();
  console.log(`🚡 Puerto configurado: ${port}`);
  
  // Configurar CORS automáticamente
  const corsConfig = getCORSConfig();
  if (corsConfig === true) {
    process.env.CORS_ENABLED = 'true';
    process.env.CLIENT_ORIGIN = '*';
    console.log(`🌐 CORS habilitado para todos los orígenes (desarrollo)`);
  } else {
    process.env.CORS_ENABLED = 'true';
    process.env.CLIENT_ORIGIN = corsConfig.join(',');
    console.log(`🌐 CORS habilitado para orígenes específicos: ${corsConfig.join(', ')}`);
  }
  
  // Generar JWT secret si no existe
  if (!process.env.JWT_SECRET) {
    process.env.JWT_SECRET = require('crypto').randomBytes(64).toString('hex');
    console.log(`🔐 JWT_SECRET generado automáticamente`);
  }
  
  // Validar variables obligatorias para producción
  if (detected.isProduction) {
    const missing = productionRequiredEnvVars.filter((key) => !process.env[key]);
    if (missing.length > 0) {
      throw new Error(
        `Faltan variables de entorno obligatorias para producción: ${missing.join(', ')}. ` +
        'Configúralas según el entorno de despliegue.'
      );
    }
    
    // Advertencias de seguridad para producción
    if (process.env.JWT_SECRET === 'your_jwt_secret_here' || 
        process.env.JWT_SECRET.includes('change_this')) {
      console.warn('⚠️  ADVERTENCIA: JWT_SECRET parece ser el valor por defecto. Cámbialo por uno seguro.');
    }
    
    if (!process.env.ENABLE_HTTPS && !detected.isCloud) {
      console.warn('⚠️  ADVERTENCIA: En producción se recomienda HTTPS. Configura un proxy inverso (nginx, Apache, etc.)');
    }
  }
  
  // Configuración específica para entornos de nube
  if (detected.isRailway) {
    console.log('🚂 Configuración específica para Railway detectada');
    process.env.RAILWAY_ENVIRONMENT = 'production';
  } else if (detected.isRender) {
    console.log('🎨 Configuración específica para Render detectada');
    process.env.RENDER = 'true';
  }
  
  console.log('✅ Configuración de entorno completada');
}

module.exports = { 
  validateEnv, 
  detectEnvironment,
  getNetworkConfig,
  getDatabaseConfig,
  getPortConfig,
  getCORSConfig
};
