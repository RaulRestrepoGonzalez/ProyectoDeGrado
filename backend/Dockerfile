# MusicApp Valledupar - Docker
# Construcción multi-etapa para optimizar tamaño
FROM node:18-alpine AS builder

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production && npm cache clean --force

# Copiar código fuente
COPY . .

# Exponer puerto
EXPOSE 3000

# Crear usuario no root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S musicapp -u 1001

# Cambiar propietario de los archivos
RUN chown -R musicapp:nodejs /app
USER musicapp

# Variables de entorno por defecto para Docker
ENV NODE_ENV=production
ENV PORT=3000
ENV MONGODB_URI=mongodb://mongodb:27017/musicapp_valledupar
ENV CLIENT_ORIGIN=*

# Iniciar aplicación
CMD ["npm", "start"]
