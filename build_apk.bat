@echo off
title SoundUpar - Android Build Script
setlocal enabledelayedexpansion

echo ===================================================
echo   SoundUpar - Generador de APK y App Bundle
echo ===================================================
echo.

set PROJECT_ROOT=%~dp0
cd /d "%PROJECT_ROOT%"

:: Verificaciones iniciales
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter no esta instalado en el PATH.
    pause
    exit /b 1
)

echo [1/51] Limpiando proyecto...
call flutter clean

echo [2/5] Descargando dependencias...
call flutter pub get

echo [3/5] Compilando APK (para instalacion manual)...
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
