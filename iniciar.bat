@echo off
title MusicApp Valledupar Loader

echo ===================================================
echo   Iniciando MusicApp Valledupar (Backend + Frontend)
echo ===================================================
echo.

set BACKEND_PORT=3000
set PROJECT_ROOT=%~dp0
set BACKEND_DIR=%PROJECT_ROOT%backend
set ENV_FILE=%PROJECT_ROOT%.env
set BACKEND_ENV_FILE=%BACKEND_DIR%\.env
set MONGO_PATH=C:\Program Files\MongoDB\Server\8.2\bin

echo [Paso 1/6] Verificando dependencias...

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js no esta instalado
    pause
    exit /b 1
) else (
    echo OK: Node.js encontrado
)

where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter no esta instalado
    pause
    exit /b 1
) else (
    echo OK: Flutter encontrado
)

echo.
echo [Paso 2/6] Iniciando MongoDB...

if exist "%MONGO_PATH%\mongod.exe" (
    echo OK: MongoDB encontrado
) else (
    echo ERROR: MongoDB no encontrado
    pause
    exit /b 1
)

echo Verificando si MongoDB ya esta corriendo...
netstat -an | findstr ":27017" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: MongoDB ya esta corriendo
) else (
    echo MongoDB no esta corriendo, iniciando manualmente...
    
    echo Intentando iniciar servicio MongoDB...
    sc query MongoDB >nul 2>&1
    if %errorlevel% equ 0 (
        net start MongoDB >nul 2>&1
        if %errorlevel% equ 0 (
            echo OK: MongoDB iniciado como servicio
        ) else (
            echo Iniciando MongoDB manualmente...
            if not exist "C:\data\db" mkdir "C:\data\db" 2>nul
            start "MongoDB Server" cmd /k "title MongoDB Server && echo MongoDB iniciado manualmente && \"%MONGO_PATH%\mongod.exe\" --dbpath \"C:\data\db\""
            timeout /t 8
        )
    ) else (
        echo Servicio no encontrado, iniciando manualmente...
        if not exist "C:\data\db" mkdir "C:\data\db" 2>nul
        start "MongoDB Server" cmd /k "title MongoDB Server && echo MongoDB iniciado manualmente && \"%MONGO_PATH%\mongod.exe\" --dbpath \"C:\data\db\""
        timeout /t 8
    )
)

echo Esperando a que MongoDB este completamente listo...
timeout /t 10

echo Verificando que MongoDB este escuchando...
netstat -an | findstr ":27017" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: MongoDB esta escuchando en puerto 27017
) else (
    echo ADVERTENCIA: MongoDB podria no estar listo, pero continuando...
)

echo.
echo [Paso 3/6] Detectando IP local...

set LOCAL_IP=localhost
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4"') do (
    for /f "tokens=1" %%j in ("%%i") do set LOCAL_IP=%%j
)

echo IP local: %LOCAL_IP%

echo.
echo [Paso 4/6] Configurando archivos .env...

if exist "%BACKEND_ENV_FILE%" del "%BACKEND_ENV_FILE%"
(
    echo PORT=%BACKEND_PORT%
    echo NODE_ENV=development
    echo MONGODB_URI=mongodb://localhost:27017/musicapp_valledupar
    echo JWT_SECRET=musicapp_secret_%RANDOM%_%TIME:~0,8%
    echo CLIENT_ORIGIN=*
    echo SOCKET_PORT=4000
    echo SOCKET_PATH=/socket.io
) > "%BACKEND_ENV_FILE%"

if exist "%ENV_FILE%" del "%ENV_FILE%"
(
    echo BASE_URL=http://%LOCAL_IP%:%BACKEND_PORT%/api
    echo SOCKET_URL=http://%LOCAL_IP%:4000
    echo BASE_HOSTS=%LOCAL_IP%,localhost,10.0.2.2,10.0.3.2,127.0.0.1
    echo NETWORK_TIMEOUT=15000
    echo RETRY_ATTEMPTS=8
) > "%ENV_FILE%"

echo OK: Archivos .env configurados

echo.
echo [Paso 5/6] Iniciando backend...

cd /d "%BACKEND_DIR%"

if not exist "node_modules" (
    echo Instalando dependencias del backend...
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Error al instalar dependencias
        pause
        exit /b 1
    )
)

echo Verificando puerto %BACKEND_PORT%...
netstat -an | findstr ":%BACKEND_PORT%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Puerto %BACKEND_PORT% esta en uso, liberando...
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr ":%BACKEND_PORT%"') do (
        taskkill /F /PID %%i >nul 2>&1
    )
    timeout /t 3
)

echo Iniciando servidor backend...
start "Backend - MusicApp" cmd /k "title Backend - MusicApp && echo ======================================== && echo BACKEND - MUSICAPP VALLEDUPAR && echo ======================================== && npm run dev"

echo Esperando que el backend inicie completamente...
timeout /t 15

echo Verificando que el backend este corriendo...
netstat -an | findstr ":%BACKEND_PORT%" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: Backend corriendo en puerto %BACKEND_PORT%
    
    echo Probando conexion con backend...
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:%BACKEND_PORT%/health' -TimeoutSec 10 -UseBasicParsing; Write-Host 'OK: Backend responde correctamente' } catch { Write-Host 'ADVERTENCIA: Backend no responde, esperando mas...' }"
    timeout /t 5
    
    echo Verificando nuevamente...
    powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:%BACKEND_PORT%/health' -TimeoutSec 5 -UseBasicParsing; Write-Host 'OK: Backend funcionando correctamente' } catch { Write-Host 'INFO: Backend iniciado pero health check no disponible - continuando' }"
) else (
    echo ADVERTENCIA: Backend no se pudo verificar
    echo Esto puede deberse a:
    echo - MongoDB no esta completamente listo
    echo - Errores en el codigo del backend
    echo - Problemas de red
    echo.
    echo Verifica la ventana del backend para ver errores especificos
    echo Continuando con Flutter de todos modos...
)

echo.
echo [Paso 6/6] Preparando e iniciando Flutter...

cd /d "%PROJECT_ROOT%"

echo Limpiando e instalando dependencias de Flutter...
call flutter clean
call flutter pub get

echo Verificando dispositivos...
call flutter devices

echo.
echo ===================================================
echo   CONFIGURACION COMPLETADA - MUSICA APP LISTA
echo ===================================================
echo.
echo Backend API:     http://%LOCAL_IP%:%BACKEND_PORT%/api
echo Health Check:    http://%LOCAL_IP%:%BACKEND_PORT%/health
echo Socket.IO:       http://%LOCAL_IP%:4000
echo MongoDB:         mongodb://localhost:27017/musicapp_valledupar
echo.
echo Para dispositivos moviles en esta red:
echo - Usa: http://%LOCAL_IP%:%BACKEND_PORT%/api
echo.
echo Para emuladores:
echo - Android: http://10.0.2.2:%BACKEND_PORT%/api
echo - iOS: http://localhost:%BACKEND_PORT%/api
echo.
echo Servicios corriendo en ventanas separadas:
echo - MongoDB Server
echo - Backend - MusicApp
echo.
echo ===================================================
echo.

echo Iniciando aplicacion Flutter...
echo.
echo COMANDOS UTILES EN FLUTTER:
echo   'r' - Hot reload
echo   'R' - Hot restart  
echo   'p' - Debug paint
echo   'o' - Platform switch
echo   'q' - Quit
echo.
echo Presiona Ctrl+C para detener la aplicacion Flutter
echo Los servicios backend y MongoDB seguiran corriendo
echo.

call flutter run

echo.
echo ===================================================
echo   Aplicacion MusicApp Valledupar detenida
echo ===================================================
echo.
echo La aplicacion Flutter se ha detenido
echo Deteniendo servicios backend y MongoDB...
echo.

echo Cerrando procesos Node.js (Backend)...
taskkill /F /IM node.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: Backend detenido
) else (
    echo INFO: No se encontraron procesos Node.js activos
)

echo.
echo Cerrando procesos MongoDB...
taskkill /F /IM mongod.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: MongoDB detenido
) else (
    echo INFO: No se encontraron procesos MongoDB activos
)

echo.
echo ===================================================
echo   Todos los servicios han sido detenidos
echo ===================================================
echo.
echo La aplicacion y todos sus servicios se han cerrado correctamente
echo Presiona cualquier tecla para salir...

pause >nul
