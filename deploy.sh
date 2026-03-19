#!/bin/bash

# SoundUpar - Script de despliegue universal
# Detecta automáticamente el entorno y configura el despliegue

set -e

echo "🚀 SoundUpar - Script de Despliegue Universal"
echo "=================================================="

# Detectar entorno
detect_environment() {
    if [[ -n "$RAILWAY_ENVIRONMENT" ]] || [[ -n "$RAILWAY_SERVICE_NAME" ]]; then
        echo "railway"
    elif [[ -n "$RENDER" ]] || [[ -n "$RENDER_SERVICE_ID" ]]; then
        echo "render"
    elif [[ -n "$AWS_REGION" ]] || [[ -n "$ECS_CONTAINER_METADATA_URI" ]]; then
        echo "aws"
    elif [[ -n "$AZURE_CLIENT_ID" ]]; then
        echo "azure"
    elif [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
        echo "gcp"
    elif [[ -f "/.dockerenv" ]] || [[ -n "$DOCKER_ENV" ]]; then
        echo "docker"
    elif command -v docker &> /dev/null && [[ -f "docker-compose.yml" ]]; then
        echo "docker-compose"
    else
        echo "local"
    fi
}

# Configurar variables de entorno según el entorno
setup_environment() {
    local env=$(detect_environment)
    echo "🔍 Entorno detectado: $env"
    
    case $env in
        "railway")
            echo "🚂 Configurando para Railway..."
            export NODE_ENV=production
            export PORT=${PORT:-3000}
            export CLIENT_ORIGIN=${RAILWAY_PUBLIC_DOMAIN:-"*"}
            echo "✅ Configuración Railway completada"
            ;;
        "render")
            echo "🎨 Configurando para Render..."
            export NODE_ENV=production
            export PORT=${PORT:-3000}
            export CLIENT_ORIGIN=${RENDER_EXTERNAL_URL:-"*"}
            echo "✅ Configuración Render completada"
            ;;
        "aws"|"azure"|"gcp")
            echo "☁️ Configurando para nube..."
            export NODE_ENV=production
            export PORT=${PORT:-3000}
            export CLIENT_ORIGIN="*"
            echo "✅ Configuración nube completada"
            ;;
        "docker")
            echo "🐳 Configurando para Docker..."
            export NODE_ENV=production
            export PORT=${PORT:-3000}
            export CLIENT_ORIGIN="*"
            echo "✅ Configuración Docker completada"
            ;;
        "docker-compose")
            echo "🐳 Configurando para Docker Compose..."
            docker-compose down
            docker-compose build
            docker-compose up -d
            echo "✅ Docker Compose iniciado"
            return 0
            ;;
        "local")
            echo "💻 Configurando para desarrollo local..."
            export NODE_ENV=development
            export PORT=${PORT:-3000}
            export CLIENT_ORIGIN="*"
            echo "✅ Configuración local completada"
            ;;
        *)
            echo "❌ Entorno no reconocido"
            exit 1
            ;;
    esac
}

# Instalar dependencias
install_dependencies() {
    echo "📦 Instalando dependencias..."
    cd backend
    npm ci --production
    echo "✅ Dependencias instaladas"
}

# Verificar base de datos
check_database() {
    echo "🗄️ Verificando conexión a base de datos..."
    
    # Esperar a que MongoDB esté disponible si es Docker
    if [[ "$(detect_environment)" == "docker" ]] || [[ "$(detect_environment)" == "docker-compose" ]]; then
        echo "⏳ Esperando a MongoDB..."
        for i in {1..30}; do
            if nc -z mongodb 27017 &> /dev/null; then
                echo "✅ MongoDB está disponible"
                break
            fi
            if [[ $i -eq 30 ]]; then
                echo "❌ MongoDB no está disponible después de 30 segundos"
                exit 1
            fi
            sleep 1
        done
    fi
    
    echo "✅ Verificación de base de datos completada"
}

# Iniciar aplicación
start_application() {
    echo "🚀 Iniciando aplicación..."
    
    case $(detect_environment) in
        "docker-compose")
            echo "🐳 Aplicación ya iniciada con Docker Compose"
            ;;
        *)
            npm start
            ;;
    esac
}

# Health check
health_check() {
    echo "🔍 Verificando salud de la aplicación..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -f http://localhost:${PORT:-3000}/health &> /dev/null; then
            echo "✅ Aplicación saludable"
            return 0
        fi
        
        echo "⏳ Intento $attempt/$max_attempts - esperando que la aplicación esté lista..."
        sleep 2
        ((attempt++))
    done
    
    echo "❌ La aplicación no está saludable después de $max_attempts intentos"
    exit 1
}

# Función principal
main() {
    echo "📍 Directorio actual: $(pwd)"
    echo "🖥️ Plataforma: $(uname -s)"
    echo "📋 Node.js: $(node --version)"
    echo "📦 npm: $(npm --version)"
    echo ""
    
    setup_environment
    install_dependencies
    check_database
    
    # Iniciar en background para poder hacer health check
    if [[ "$(detect_environment)" != "docker-compose" ]]; then
        start_application &
        APP_PID=$!
        
        sleep 5
        health_check
        
        wait $APP_PID
    fi
    
    echo "🎉 Despliegue completado exitosamente!"
}

# Ejecutar función principal
main "$@"
