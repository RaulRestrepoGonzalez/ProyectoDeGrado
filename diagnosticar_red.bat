@echo off
title MusicApp Valledupar - Network Diagnostics
chcp 65001 >nul

echo ===================================================
echo     MusicApp Valledupar - Diagnosticos de Red
echo ===================================================
echo.

:: Obtener IP local
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%j in ("%%i") do set LOCAL_IP=%%j
)

if "%LOCAL_IP%"=="" (
    set LOCAL_IP=localhost
)

echo IP local detectada: %LOCAL_IP%
echo.

echo [1/5] Verificando configuracion actual...

if exist ".env" (
    echo Archivo .env encontrado:
    type .env
    echo.
) else (
    echo ADVERTENCIA: No se encuentra el archivo .env
    echo.
)

echo [2/5] Verificando puertos del backend...

set BACKEND_PORT=3000
netstat -an | findstr ":%BACKEND_PORT%" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: Puerto %BACKEND_PORT% esta en uso
) else (
    echo ADVERTENCIA: Puerto %BACKEND_PORT% no esta en uso
    echo El backend podría no estar corriendo
)

echo.
echo [3/5] Probando conexion con el backend...

:: Probar diferentes URLs
set URLs[0]=http://localhost:%BACKEND_PORT%/api
set URLs[1]=http://%LOCAL_IP%:%BACKEND_PORT%/api
set URLs[2]=http://10.0.2.2:%BACKEND_PORT%/api

for /l %%i in (0,1,2) do (
    echo Probando: !URLs[%%i]!
    powershell -Command "try { $response = Invoke-WebRequest -Uri '!URLs[%%i]!/health' -TimeoutSec 3 -UseBasicParsing; Write-Host 'OK: Respuesta recibida' } catch { Write-Host 'ERROR: Sin conexion' }"
    echo.
)

echo [4/5] Verificando firewall...

echo Verificando si el firewall permite conexiones entrantes...
netsh advfirewall show currentprofile | findstr "State"
echo.

echo [5/5] Recomendaciones...

echo ===================================================
echo               RECOMENDACIONES
echo ===================================================
echo.
echo 1. Si usas un emulador Android:
echo    - La app deberia conectarse automaticamente
echo    - Si falla, verifica que el backend este corriendo
echo.
echo 2. Si usas un dispositivo fisico:
echo    - Asegurate que el dispositivo y PC esten en la misma red
echo    - Configura el firewall para permitir conexiones al puerto %BACKEND_PORT%
echo    - Usa la IP: %LOCAL_IP%:%BACKEND_PORT%
echo.
echo 3. Si el problema persiste:
echo    - Ejecuta: netsh advfirewall firewall add rule name="MusicApp Backend" dir=in action=allow protocol=TCP localport=%BACKEND_PORT%
echo    - Reinicia el backend y la aplicacion
echo.

pause
