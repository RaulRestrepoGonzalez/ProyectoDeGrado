require('dotenv').config();

const http = require('http');
const app = require('./app');
const { connectDB } = require('./config/database');
const { initSocket } = require('./config/socket');
const { validateEnv, getNetworkConfig, detectEnvironment } = require('./config/env');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    console.log('🚀 Iniciando SoundUpar Backend...');
    
    // Detectar y validar entorno automáticamente
    validateEnv();
    
    // Obtener configuración de red
    const network = getNetworkConfig();
    const detected = detectEnvironment();
    
    console.log('✅ Variables de entorno validadas');
    console.log(`🌍 Entorno: ${detected.env}`);
    console.log(`🖥️  Plataforma: ${require('os').platform()} (${require('os').arch()})`);
    console.log(`📡 Escuchando en: ${network.host}:${PORT}`);
    
    if (network.allInterfaces) {
      console.log(`🌐 Disponible en todas las interfaces de red`);
      if (network.ips.length > 0) {
        console.log(`📍 IPs locales: ${network.ips.join(', ')}`);
      }
    }

    // Intentar conectar a la base de datos (no bloquear si falla en desarrollo)
    try {
      await connectDB();
      console.log('✅ Base de datos conectada');
    } catch (dbError) {
      if (detected.isDevelopment) {
        console.warn('⚠️  Base de datos no disponible, continuando en modo desarrollo');
        console.warn('⚠️  Para funcionalidad completa, inicie MongoDB y reinicie el servidor');
      } else {
        throw dbError;
      }
    }

    // Crear servidor HTTP con configuración adaptable
    const server = http.createServer(app);
    
    // Configurar Socket.IO
    initSocket(server);
    console.log('✅ Socket.IO configurado');

    // Iniciar servidor con host dinámico
    server.listen(PORT, network.host, () => {
      console.log('');
      console.log('🎉 Servidor backend iniciado exitosamente');
      console.log('═══════════════════════════════════════════════════════════════');
      
      // Mostrar URLs según el entorno
      if (detected.isDevelopment) {
        console.log(`📡 API Local:      http://localhost:${PORT}/api`);
        console.log(`🔍 Health Check:  http://localhost:${PORT}/health`);
        console.log(`🌐 Socket.IO:     http://localhost:${PORT}`);
        
        if (network.ips.length > 0) {
          console.log('');
          console.log('📱 Para dispositivos en la misma red:');
          network.ips.forEach(ip => {
            console.log(`   • http://${ip}:${PORT}/api`);
          });
        }
        
        console.log('');
        console.log('🔧 Emuladores:');
        console.log(`   • Android: http://10.0.2.2:${PORT}/api`);
        console.log(`   • iOS:     http://localhost:${PORT}/api`);
      } else if (detected.isCloud || detected.isRailway || detected.isRender) {
        console.log(`☁️  API en la nube:  ${process.env.RAILWAY_PUBLIC_DOMAIN || process.env.RENDER_EXTERNAL_URL || `https://your-domain.com`}/api`);
        console.log(`🔍 Health Check:  ${process.env.RAILWAY_PUBLIC_DOMAIN || process.env.RENDER_EXTERNAL_URL || `https://your-domain.com`}/health`);
      } else {
        console.log(`🏢 Producción:     http://${network.primaryIP}:${PORT}/api`);
        console.log(`🔍 Health Check:  http://${network.primaryIP}:${PORT}/health`);
      }
      
      console.log('═══════════════════════════════════════════════════════════════');
      console.log('🎯 El servidor está listo para recibir conexiones');
      
      // Mostrar información específica del entorno
      if (detected.isDocker) {
        console.log('🐳 Ejecutándose en contenedor Docker');
      }
      if (detected.isRailway) {
        console.log('🚂 Desplegado en Railway');
      }
      if (detected.isRender) {
        console.log('🎨 Desplegado en Render');
      }
      if (detected.isCloud) {
        console.log('☁️  Desplegado en plataforma cloud');
      }
      
      console.log('');
    });

    // Manejar errores del servidor con información detallada
    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`❌ Puerto ${PORT} ya está en uso`);
        console.error(`💡 Soluciones:`);
        console.error(`   • Cambia el puerto: set PORT=3001 && npm start`);
        console.error(`   • O libera el puerto: netstat -ano | findstr :${PORT}`);
        console.error(`   • Y cierra el proceso: taskkill /F /PID [PID]`);
      } else if (error.code === 'EACCES') {
        console.error(`❌ Permiso denegado para el puerto ${PORT}`);
        console.error(`💡 Solución: Ejecuta como administrador o usa puerto > 1024`);
      } else if (error.code === 'EADDRNOTAVAIL') {
        console.error(`❌ Dirección ${network.host} no disponible`);
        console.error(`💡 Solución: Verifica la configuración de red`);
      } else {
        console.error('❌ Error del servidor:', error);
      }
      process.exit(1);
    });

    // Manejo elegante del cierre con información del entorno
    const gracefulShutdown = (signal) => {
      console.log(`\n📴 Recibida señal ${signal}, cerrando servidor...`);
      console.log(`⏱️  Tiempo de actividad: ${formatUptime(process.uptime())}`);
      
      server.close(() => {
        console.log('✅ Servidor HTTP cerrado');
        
        // Cerrar conexión a MongoDB si está conectada
        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 0) {
          mongoose.connection.close(() => {
            console.log('✅ Conexión a MongoDB cerrada');
            console.log('👋 Servidor detenido completamente');
            process.exit(0);
          });
        } else {
          console.log('👋 Servidor detenido');
          process.exit(0);
        }
      });

      // Forzar cierre después de 10 segundos
      setTimeout(() => {
        console.error('⏰ Forzando cierre del servidor...');
        process.exit(1);
      }, 10000);
    };

    // Escuchar señales de cierre
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Manejar excepciones no capturadas con contexto
    process.on('uncaughtException', (error) => {
      console.error('❌ Excepción no capturada:', error);
      console.error('🔍 Entorno:', detected.env);
      console.error('🖥️  Plataforma:', require('os').platform());
      
      if (detected.isProduction) {
        gracefulShutdown('uncaughtException');
      } else {
        console.log('🐛 Modo desarrollo: continuando después del error...');
      }
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ Rechazo no manejado en:', promise, 'razón:', reason);
      console.error('🔍 Entorno:', detected.env);
      
      if (detected.isProduction) {
        gracefulShutdown('unhandledRejection');
      } else {
        console.log('🐛 Modo desarrollo: continuando después del rechazo...');
      }
    });

  } catch (error) {
    console.error('❌ Error fatal al iniciar el servidor:', error);
    
    if (error.message.includes('MongoDB')) {
      console.error('');
      console.error('🔧 Soluciones sugeridas:');
      console.error('1. 📦 Instala MongoDB: https://www.mongodb.com/try/download/community');
      console.error('2. 🚀 Inicia el servicio: net start MongoDB (Windows) o brew services start mongodb (macOS)');
      console.error('3. ☁️  O usa MongoDB Atlas (nube): https://www.mongodb.com/cloud/atlas');
      console.error('4. 🐳 En Docker: docker run -d -p 27017:27017 mongo');
      console.error('5. 🚂 En Railway: Agrega variable MONGODB_URI');
      console.error('6. 🎨 En Render: Agrega variable DATABASE_URL');
    }
    
    if (error.message.includes('variables de entorno')) {
      console.error('');
      console.error('🔧 Configuración de entorno:');
      console.error('1. 📝 Crea archivo .env basado en .env.example');
      console.error('2. 🔐 Genera un JWT_SECRET seguro');
      console.error('3. 🗄️  Configura MONGODB_URI si no es local');
      console.error('4. 🌐 Configura CLIENT_ORIGIN si es producción');
    }
    
    process.exit(1);
  }
})();

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
