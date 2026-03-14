@echo off
title MusicApp Valledupar - Loader
chcp 65001 >nul

echo ===================================================
echo   Iniciando MusicApp Valledupar (Backend + Frontend)
echo ===================================================
echo.

set BACKEND_PORT=3000
set SOCKET_PORT=4000
set PROJECT_ROOT=%~dp0
set BACKEND_DIR=%PROJECT_ROOT%backend
set ENV_FILE=%PROJECT_ROOT%.env
set BACKEND_ENV_FILE=%BACKEND_DIR%\.env

echo [Paso 1/6] Verificando dependencias...

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js no esta instalado o no esta en el PATH
    echo Por favor, instala Node.js desde https://nodejs.org/
    pause
    exit /b 1
) else (
    echo OK: Node.js encontrado
)

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter no esta instalado o no esta en el PATH
    echo Por favor, instala Flutter desde https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
) else (
    echo OK: Flutter encontrado
)

echo.
echo [Paso 2/6] Detectando configuracion de red...

:: Obtener la IP local automáticamente
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%j in ("%%i") do set LOCAL_IP=%%j
)

if "%LOCAL_IP%"=="" (
    echo No se pudo detectar la IP local, usando localhost
    set LOCAL_IP=localhost
) else (
    echo IP local detectada: %LOCAL_IP%
)

echo.
echo [Paso 3/6] Configurando archivos de entorno...

:: Crear archivo .env para el backend
if not exist "%BACKEND_ENV_FILE%" (
    echo Creando archivo .env para el backend...
    (
        echo # Backend - MusicApp Valledupar
        echo PORT=%BACKEND_PORT%
        echo MONGODB_URI=mongodb://localhost:27017/musicapp_valledupar
        echo JWT_SECRET=your_jwt_secret_key_change_this_in_production_%RANDOM%
        echo CLIENT_ORIGIN=http://localhost:%BACKEND_PORT%
        echo.
        echo # Socket.IO
        echo SOCKET_PORT=%SOCKET_PORT%
        echo SOCKET_PATH=/socket.io
        echo.
        echo # Cloudinary - configura con tus credenciales
        echo CLOUDINARY_CLOUD_NAME=
        echo CLOUDINARY_API_KEY=
        echo CLOUDINARY_API_SECRET=
    ) > "%BACKEND_ENV_FILE%"
    echo OK: Archivo .env del backend creado
) else (
    echo OK: Archivo .env del backend ya existe
)

:: Crear archivo .env para Flutter con configuración completa
if not exist "%ENV_FILE%" (
    echo Creando archivo .env para Flutter...
    (
        echo # Variables de entorno para la app Flutter
        echo # Generado automaticamente - %date% %time%
        echo.
        echo # URLs del backend - configuradas automaticamente
        echo BASE_URL=http://%LOCAL_IP%:%BACKEND_PORT%/api
        echo SOCKET_URL=http://%LOCAL_IP%:%SOCKET_PORT%
        echo.
        echo # IPs adicionales para dispositivos moviles y emuladores
        echo BASE_HOSTS=%LOCAL_IP%,localhost,10.0.2.2,10.0.3.2
        echo.
        echo # Configuracion de red
        echo NETWORK_TIMEOUT=5000
        echo RETRY_ATTEMPTS=3
        echo.
        echo # Ejemplo para Firebase ^(opcional^)
        echo # FIREBASE_API_KEY=...
        echo # FIREBASE_APP_ID=...
        echo # FIREBASE_MESSAGING_SENDER_ID=...
        echo # FIREBASE_PROJECT_ID=...
    ) > "%ENV_FILE%"
    echo OK: Archivo .env de Flutter creado
) else (
    echo OK: Archivo .env de Flutter ya existe
)

echo.
echo [Paso 4/6] Verificando puertos...

netstat -an | findstr ":%BACKEND_PORT%" >nul 2>&1
if %errorlevel% equ 0 (
    echo ADVERTENCIA: Puerto %BACKEND_PORT% esta en uso
    set BACKEND_PORT=3001
    echo Usando puerto %BACKEND_PORT% para el backend
    :: Actualizar el archivo .env con el nuevo puerto
    powershell -Command "(Get-Content '%ENV_FILE%') -replace ':%BACKEND_PORT%:3000/api', ':%BACKEND_PORT%:%BACKEND_PORT%/api' | Set-Content '%ENV_FILE%'"
) else (
    echo Puerto %BACKEND_PORT% disponible
)

echo Puerto %SOCKET_PORT% disponible

echo.
echo [Paso 5/6] Instalando dependencias del backend...

cd /d "%BACKEND_DIR%"
if not exist "node_modules" (
    echo Instalando dependencias de Node.js...
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Error al instalar dependencias del backend
        pause
        exit /b 1
    )
    echo OK: Dependencias del backend instaladas
) else (
    echo OK: Dependencias del backend ya estan instaladas
)

echo.
echo [Paso 6/6] Iniciando aplicacion...

echo Iniciando servidor backend en puerto %BACKEND_PORT%...
echo El backend estara disponible en: http://%LOCAL_IP%:%BACKEND_PORT%
start "Backend - MusicApp Valledupar" cmd /k "cd /d \"%BACKEND_DIR%\" && echo Servidor backend iniciando... && npm run dev"

echo Esperando que el backend se inicie...
timeout /t 8 /nobreak >nul

:: Verificar que el backend esté corriendo
netstat -an | findstr ":%BACKEND_PORT%" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: Backend corriendo en puerto %BACKEND_PORT%
) else (
    echo ADVERTENCIA: No se puede verificar que el backend este corriendo
    timeout /t 2 /nobreak >nul
)

cd /d "%PROJECT_ROOT%"

echo Obteniendo dependencias de Flutter...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Error al obtener dependencias de Flutter
    pause
    exit /b 1
)

echo Verificando dispositivos disponibles...
call flutter devices

echo.
echo ===================================================
echo   CONFIGURACION DE RED
echo ===================================================
echo.
echo Backend URL: http://%LOCAL_IP%:%BACKEND_PORT%/api
echo Socket URL:  http://%LOCAL_IP%:%SOCKET_PORT%
echo.
echo Para dispositivos moviles en la misma red:
echo - Usa la IP: %LOCAL_IP%:%BACKEND_PORT%
echo - Asegurate de que el firewall permita conexiones
echo.
echo Para emuladores Android: http://10.0.2.2:%BACKEND_PORT%/api
echo Para emuladores iOS: http://localhost:%BACKEND_PORT%/api
echo.
echo ===================================================
echo.

echo Iniciando aplicacion Flutter...
echo Puedes usar 'r' para hot-reload, 'R' para hot-restart
echo Presiona Ctrl+C para detener la aplicacion
echo.

call flutter run

echo.
echo ===================================================
echo   Aplicacion MusicApp Valledupar detenida
echo ===================================================
pause
