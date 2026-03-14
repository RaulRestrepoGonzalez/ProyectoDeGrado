@echo off
title MusicApp Valledupar - Configuración Avanzada
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ===================================================
echo   MusicApp Valledupar - Configuración Avanzada
echo ===================================================
echo.

:menu
echo Seleccione una opción:
echo.
echo 1. Diagnosticar sistema
echo 2. Configurar variables de entorno personalizadas
echo 3. Limpiar caché y reinstalar dependencias
echo 4. Configurar para producción
echo 5. Verificar conexión con MongoDB
echo 6. Exportar configuración actual
echo 7. Importar configuración desde archivo
echo 8. Salir
echo.
set /p "opcion=Ingrese el número de opción: "

if "%opcion%"=="1" goto diagnosticar
if "%opcion%"=="2" goto configurar_env
if "%opcion%"=="3" goto limpiar_cache
if "%opcion%"=="4" goto configurar_produccion
if "%opcion%"=="5" goto verificar_mongodb
if "%opcion%"=="6" goto exportar_config
if "%opcion%"=="7" goto importar_config
if "%opcion%"=="8" goto salir
echo Opción no válida
goto menu

:diagnosticar
echo.
echo ===================================================
echo             DIAGNÓSTICO DEL SISTEMA
echo ===================================================
echo.

echo [1/5] Verificando sistema operativo...
ver
echo.

echo [2/5] Verificando variables de entorno...
echo PATH principal: %PATH%
echo.

echo [3/5] Verificando Node.js y npm...
node --version 2>nul || echo ❌ Node.js no encontrado
npm --version 2>nul || echo ❌ npm no encontrado
echo.

echo [4/5] Verificando Flutter...
flutter --version 2>nul || echo ❌ Flutter no encontrado
flutter doctor
echo.

echo [5/5] Verificando puertos en uso...
echo Puertos comúnmente usados por la aplicación:
netstat -an | findstr ":3000\|:4000\|:8080\|:8081"
echo.

pause
goto menu

:configurar_env
echo.
echo ===================================================
echo        CONFIGURACIÓN DE VARIABLES DE ENTORNO
echo ===================================================
echo.

set /p "backend_port=Puerto para el backend (default: 3000): "
if "%backend_port%"=="" set "backend_port=3000"

set /p "socket_port=Puerto para Socket.IO (default: 4000): "
if "%socket_port%"=="" set "socket_port=4000"

set /p "mongodb_uri=URI de MongoDB (default: mongodb://localhost:27017/musicapp_valledupar): "
if "%mongodb_uri%"=="" set "mongodb_uri=mongodb://localhost:27017/musicapp_valledupar"

set /p "jwt_secret=JWT Secret (dejar en blanco para generar automático): "
if "%jwt_secret%"=="" set "jwt_secret=jwt_secret_%RANDOM%_%TIME%"

echo.
echo Creando archivos .env con la nueva configuración...

set "PROJECT_ROOT=%~dp0"
set "BACKEND_DIR=%PROJECT_ROOT%backend"
set "ENV_FILE=%PROJECT_ROOT%.env"
set "BACKEND_ENV_FILE=%BACKEND_DIR%\.env"

(
    echo # Backend - MusicApp Valledupar
    echo PORT=%backend_port%
    echo MONGODB_URI=%mongodb_uri%
    echo JWT_SECRET=%jwt_secret%
    echo CLIENT_ORIGIN=http://localhost:%backend_port%
    echo.
    echo # Socket.IO
    echo SOCKET_PORT=%socket_port%
    echo SOCKET_PATH=/socket.io
    echo.
    echo # Cloudinary - configura con tus credenciales
    echo CLOUDINARY_CLOUD_NAME=
    echo CLOUDINARY_API_KEY=
    echo CLOUDINARY_API_SECRET=
) > "%BACKEND_ENV_FILE%"

(
    echo # Variables de entorno para la app Flutter
    echo # Configuración personalizada
    echo BASE_URL=http://localhost:%backend_port%/api
    echo SOCKET_URL=http://localhost:%socket_port%
    echo.
    echo # Ejemplo para Firebase ^(opcional^)
    echo # FIREBASE_API_KEY=...
    echo # FIREBASE_APP_ID=...
    echo # FIREBASE_MESSAGING_SENDER_ID=...
    echo # FIREBASE_PROJECT_ID=...
) > "%ENV_FILE%"

echo ✅ Configuración guardada exitosamente
pause
goto menu

:limpiar_cache
echo.
echo ===================================================
echo           LIMPIAR CACHÉ Y DEPENDENCIAS
echo ===================================================
echo.

set /p "confirmar=¿Está seguro de limpiar caché? (S/N): "
if /i not "%confirmar%"=="S" goto menu

echo Limpiando caché de Flutter...
flutter clean
flutter pub cache repair

echo.
echo Limpiando dependencias de Node.js...
cd /d "%~dp0backend"
if exist "node_modules" rmdir /s /q node_modules
if exist "package-lock.json" del package-lock.json

echo.
echo Instalando dependencias nuevamente...
npm install

echo.
echo Obteniendo dependencias de Flutter...
cd /d "%~dp0"
flutter pub get

echo ✅ Limpieza completada
pause
goto menu

:configurar_produccion
echo.
echo ===================================================
echo            CONFIGURACIÓN PARA PRODUCCIÓN
echo ===================================================
echo.

set /p "confirmar_prod=¿Configurar para producción? (S/N): "
if /i not "%confirmar_prod%"=="S" goto menu

set "PROJECT_ROOT=%~dp0"
set "BACKEND_DIR=%PROJECT_ROOT%backend"
set "BACKEND_ENV_FILE=%BACKEND_DIR%\.env"

echo Configurando variables de producción...
set /p "prod_port=Puerto para producción (default: 8080): "
if "%prod_port%"=="" set "prod_port=8080"

set /p "prod_mongodb=URI de MongoDB para producción: "
if "%prod_mongodb%"=="" (
    echo ❌ Se requiere URI de MongoDB para producción
    pause
    goto menu
)

set /p "prod_jwt=JWT Secret para producción: "
if "%prod_jwt%"=="" (
    echo ❌ Se requiere JWT Secret para producción
    pause
    goto menu
)

(
    echo # Backend - MusicApp Valledupar - Producción
    echo PORT=%prod_port%
    echo NODE_ENV=production
    echo MONGODB_URI=%prod_mongodb%
    echo JWT_SECRET=%prod_jwt%
    echo CLIENT_ORIGIN=https://tudominio.com
    echo.
    echo # Socket.IO
    echo SOCKET_PORT=%prod_port%
    echo SOCKET_PATH=/socket.io
    echo.
    echo # Cloudinary - configura con tus credenciales
    echo CLOUDINARY_CLOUD_NAME=
    echo CLOUDINARY_API_KEY=
    echo CLOUDINARY_API_SECRET=
) > "%BACKEND_ENV_FILE%"

echo ✅ Configuración de producción aplicada
pause
goto menu

:verificar_mongodb
echo.
echo ===================================================
echo          VERIFICAR CONEXIÓN MONGODB
echo ===================================================
echo.

cd /d "%~dp0backend"

if not exist ".env" (
    echo ❌ No se encuentra el archivo .env del backend
    pause
    goto menu
)

echo Leyendo configuración de MongoDB...
for /f "tokens=2 delims==" %%i in ('findstr "MONGODB_URI" .env') do set "MONGO_URI=%%i"

echo Probando conexión con: %MONGO_URI%
echo.

node -e "
const mongoose = require('mongoose');
mongoose.connect('%MONGO_URI%', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    serverSelectionTimeoutMS: 5000
}).then(() => {
    console.log('✅ Conexión exitosa a MongoDB');
    process.exit(0);
}).catch((error) => {
    console.log('❌ Error de conexión a MongoDB:', error.message);
    process.exit(1);
});
"

if !errorlevel! equ 0 (
    echo ✅ MongoDB está accesible
) else (
    echo ❌ No se puede conectar a MongoDB
    echo Verifique que MongoDB esté instalado y corriendo
)

pause
goto menu

:exportar_config
echo.
echo ===================================================
echo             EXPORTAR CONFIGURACIÓN
echo ===================================================
echo.

set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"
set "backup_file=config_backup_%timestamp%.txt"

echo Exportando configuración actual a %backup_file%...
(
    echo # Configuración MusicApp Valledupar - %date% %time%
    echo.
    echo ## Backend .env
    type "%~dp0backend\.env" 2>nul || echo Archivo no encontrado
    echo.
    echo ## Flutter .env
    type "%~dp0\.env" 2>nul || echo Archivo no encontrado
    echo.
    echo ## Información del sistema
    ver
    echo Node.js:
    node --version 2>nul || echo No instalado
    echo npm:
    npm --version 2>nul || echo No instalado
    echo Flutter:
    flutter --version 2>nul | findstr "Flutter" || echo No instalado
) > "%backup_file%"

echo ✅ Configuración exportada a %backup_file%
pause
goto menu

:importar_config
echo.
echo ===================================================
echo             IMPORTAR CONFIGURACIÓN
echo ===================================================
echo.

set /p "import_file=Ruta del archivo de configuración a importar: "
if not exist "%import_file%" (
    echo ❌ Archivo no encontrado
    pause
    goto menu
)

echo Importando configuración desde %import_file%...
:: Aquí iría la lógica de importación (simplificada)
echo ⚠️  Función de importación no implementada completamente
pause
goto menu

:salir
echo.
echo ===================================================
echo                HASTA PRONTO
echo ===================================================
pause
exit /b 0
