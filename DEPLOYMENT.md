# SoundUpar - Guía de Despliegue

## 🌍 Entornos Soportados

El backend de SoundUpar se adapta automáticamente a cualquier entorno de despliegue:

### 🖥️ Desarrollo Local
```bash
# Usar el script iniciar.bat (Windows) o
npm run dev
```

### 🐳 Docker
```bash
# Construir imagen
docker build -t musicapp-backend ./backend

# Ejecutar contenedor
docker run -p 3000:3000 -e MONGODB_URI=mongodb://host.docker.internal:27017/soundupar_db musicapp-backend
```

### 🐳 Docker Compose
```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

### 🚂 Railway
1. Conectar repositorio a Railway
2. Railway detectará automáticamente el entorno
3. Configurar variables:
   - `MONGODB_URI`: URL de MongoDB (Railway MongoDB o MongoDB Atlas)
   - `JWT_SECRET`: Clave secreta segura

### 🎨 Render
1. Conectar repositorio a Render
2. Render detectará automáticamente el entorno
3. Configurar variables en el dashboard:
   - `MONGODB_URI`: URL de MongoDB
   - `JWT_SECRET`: Clave secreta segura

### ☁️ AWS/Azure/GCP
El backend detecta automáticamente estas plataformas y se configura:

```bash
# Script universal de despliegue
./deploy.sh
```

## 🔧 Configuración Automática

El backend detecta automáticamente:

- **Entorno**: Desarrollo, Producción, Test
- **Plataforma**: Docker, Railway, Render, AWS, Azure, GCP
- **Red**: IPs locales, interfaces de red disponibles
- **Base de datos**: MongoDB local, MongoDB Atlas, o servicios cloud
- **Puertos**: Puerto dinámico o configurado
- **CORS**: Configuración según entorno
- **Seguridad**: Generación automática de secrets

## 📋 Variables de Entorno

### Obligatorias (Producción)
- `JWT_SECRET`: Clave secreta para tokens JWT

### Opcionales (con valores por defecto)
- `PORT`: 3000
- `NODE_ENV`: development
- `MONGODB_URI`: mongodb://localhost:27017/soundupar_db
- `CLIENT_ORIGIN`: *
- `SOCKET_PORT`: 4000

### Específicas por plataforma
- **Railway**: `RAILWAY_MONGODB_URI`
- **Render**: `RENDER_MONGODB_URI`
- **Docker**: `MONGODB_URI=mongodb://mongodb:27017/soundupar_db`

## 🏥 Health Check

El endpoint `/health` proporciona información completa:

```json
{
  "status": "ok",
  "timestamp": "2024-03-14T...",
  "uptime": "2m 30s",
  "environment": "production",
  "database": {
    "status": "connected",
    "host": "localhost",
    "database": "musicapp_valledupar"
  },
  "api": {
    "endpoints": "/api",
    "methods": ["GET", "POST", "PUT", "PATCH", "DELETE"]
  }
}
```

## 🚀 Comandos Útiles

```bash
# Desarrollo
npm run dev

# Producción
npm start

# Health check
curl http://localhost:3000/health

# Logs (Docker)
docker-compose logs -f backend

# Construir para producción
npm run build
```

## 🔍 Detección de Entorno

El sistema detecta automáticamente:

1. **Docker**: Presencia de `/.dockerenv` o variable `DOCKER_ENV`
2. **Railway**: Variables `RAILWAY_ENVIRONMENT` o `RAILWAY_SERVICE_NAME`
3. **Render**: Variables `RENDER` o `RENDER_SERVICE_ID`
4. **AWS**: Variable `AWS_REGION` o metadatos ECS
5. **Azure**: Variable `AZURE_CLIENT_ID`
6. **GCP**: Variable `GOOGLE_CLOUD_PROJECT`

## 🛡️ Seguridad

- **JWT Secret**: Generado automáticamente si no existe
- **CORS**: Configurado según entorno (restrictivo en producción)
- **Rate Limiting**: Configurado automáticamente
- **Headers de Seguridad**: Configurados con Helmet

## 📱 Conexión desde Móviles

El backend muestra automáticamente las URLs para dispositivos:

```bash
📱 Para dispositivos en la misma red:
   • http://192.168.1.12:3000/api
   • http://192.168.1.100:3000/api

🔧 Emuladores:
   • Android: http://10.0.2.2:3000/api
   • iOS:     http://localhost:3000/api
```

## 🔄 Actualizaciones

El sistema soporta actualizaciones sin downtime:

- **Docker**: `docker-compose up -d --build`
- **Railway/Render**: Deploy automático con git push
- **Cloud**: Script `deploy.sh` con health checks
