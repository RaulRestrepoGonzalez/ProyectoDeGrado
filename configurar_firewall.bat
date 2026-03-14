@echo off
title MusicApp Valledupar - Firewall Config
chcp 65001 >nul

echo ===================================================
echo     MusicApp Valledupar - Configuracion Firewall
echo ===================================================
echo.

set BACKEND_PORT=3000

echo Este script creara reglas en el firewall para permitir
echo conexiones entrantes al backend de MusicApp Valledupar
echo.

set /p "confirmar=¿Desea continuar? (S/N): "
if /i not "%confirmar%"=="S" goto end

echo.
echo [1/3] Eliminando reglas anteriores...

netsh advfirewall firewall delete rule name="MusicApp Backend" >nul 2>&1
netsh advfirewall firewall delete rule name="MusicApp Socket" >nul 2>&1

echo [2/3] Creando regla para el backend API...

netsh advfirewall firewall add rule name="MusicApp Backend" dir=in action=allow protocol=TCP localport=%BACKEND_PORT% profile=any

if %errorlevel% equ 0 (
    echo OK: Regla del backend API creada
) else (
    echo ERROR: No se pudo crear la regla del backend API
    echo Ejecuta como administrador
    pause
    goto end
)

echo [3/3] Creando regla para Socket.IO...

set SOCKET_PORT=4000
netsh advfirewall firewall delete rule name="MusicApp Socket" >nul 2>&1
netsh advfirewall firewall add rule name="MusicApp Socket" dir=in action=allow protocol=TCP localport=%SOCKET_PORT% profile=any

if %errorlevel% equ 0 (
    echo OK: Regla de Socket.IO creada
) else (
    echo ERROR: No se pudo crear la regla de Socket.IO
)

echo.
echo ===================================================
echo               CONFIGURACION COMPLETADA
echo ===================================================
echo.
echo Se han creado las siguientes reglas:
echo - MusicApp Backend: Puerto %BACKEND_PORT% (TCP)
echo - MusicApp Socket: Puerto %SOCKET_PORT% (TCP)
echo.
echo Ahora la aplicacion deberia poder conectarse desde
echo cualquier dispositivo en la misma red.
echo.

:end
pause
