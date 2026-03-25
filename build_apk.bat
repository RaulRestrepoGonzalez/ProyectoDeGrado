@echo off
title SoundUpar - Android Build Script
setlocal enabledelayedexpansion

echo ===================================================
echo   SoundUpar - Generador de APK y App Bundle
echo ===================================================
echo.

set "PROJECT_ROOT=%~dp0"
:: Elimina la barra final para evitar problemas con cd en rutas terminadas en '\'
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
cd /d "%PROJECT_ROOT%"

:: Verificaciones iniciales
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter no esta instalado en el PATH.
    pause
    exit /b 1
)

:: Verificar key.properties y keystore
set "KEY_PROPERTIES=%PROJECT_ROOT%\android\key.properties"
if not exist "%KEY_PROPERTIES%" (
    echo ERROR: Falta android\key.properties.
    echo Copia android\key.properties.sample y ajusta las contrasenas y storeFile.
    pause
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("%KEY_PROPERTIES%") do (
    if /I "%%A"=="storeFile" set STORE_FILE=%%B
)

if "%STORE_FILE%"=="" (
    echo ERROR: storeFile no configurado en android\key.properties.
    pause
    exit /b 1
)

:: Normalizar ruta si son barras invertidas sin drive completo
set STORE_FILE=%STORE_FILE:\=/%
if exist "%STORE_FILE%" (
    set KEYSTORE_PATH=%STORE_FILE%
) else (
    if exist "%PROJECT_ROOT%%STORE_FILE%" (
        set KEYSTORE_PATH=%PROJECT_ROOT%%STORE_FILE%
    ) else (
        echo ERROR: Keystore no encontrado: %STORE_FILE%
        echo Verifica la ruta en android\key.properties.
        pause
        exit /b 1
    )
)

:: Comprobar modo desarrollador en Windows
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" >nul 2>&1
if %errorlevel% neq 0 (
    echo ADVERTENCIA: No se encontro la clave de modo desarrollador.
    echo Puedes habilitarla en Configuracion > Para desarrolladores (Recomendado).
    echo Continuando de todos modos (puede fallar si no hay symlink support).
) else (
    echo Modo desarrollador detectado.
)

echo [1/6] Limpiando proyecto...
call flutter clean

echo [2/6] Descargando dependencias...
call flutter pub get

echo [3/6] Compilando APK (para instalacion manual)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Fallo la compilacion del APK.
    pause
    exit /b 1
)

echo [4/5] Compilando App Bundle (para Play Store)...
call flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ERROR: Fallo la compilacion del App Bundle.
    pause
    exit /b 1
)

echo [5/5] Abriendo carpeta de salida...
set APK_PATH=build\app\outputs\flutter-apk
set AAB_PATH=build\app\outputs\bundle\release

echo.
echo ===================================================
echo   RESULTADOS DE COMPILACION
echo ===================================================
echo APK (Sideload): %PROJECT_ROOT%%APK_PATH%\app-release.apk
echo AAB (Play Store): %PROJECT_ROOT%%AAB_PATH%\app-release.aab
echo ===================================================
echo.
echo NOTA: Si planeas subir a Play Store, asegurate de 
echo seguir los pasos en SIGNING_GUIDE.md para firmar
echo la aplicacion oficialmente.
echo.

start "" "%PROJECT_ROOT%%APK_PATH%"
start "" "%PROJECT_ROOT%%AAB_PATH%"

pause
