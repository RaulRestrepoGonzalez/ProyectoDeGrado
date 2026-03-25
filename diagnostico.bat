@echo off
echo ========================================
echo DIAGNOSTICO COMPLETO - MUSICAPP VALLEDUPAR
echo ========================================
echo.

echo [1/8] Verificando Flutter...
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Flutter: INSTALADO
) else (
    echo    ❌ Flutter: NO ENCONTRADO
    echo       Instala Flutter desde: https://flutter.dev/docs/get-started/install
)

echo.
echo [2/8] Verificando Node.js...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Node.js: INSTALADO
) else (
    echo    ❌ Node.js: NO ENCONTRADO
    echo       Instala Node.js desde: https://nodejs.org/
)

echo.
echo [3/8] Verificando MongoDB...
mongod --version >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ MongoDB: INSTALADO
) else (
    echo    ⚠️  MongoDB: NO ENCONTRADO (usando local)
    echo       Para instalar: https://www.mongodb.com/try/download/community
)

echo.
echo [4/8] Verificando backend...
if exist "backend\package.json" (
    echo    ✅ Backend: ARCHIVOS PRESENTES
) else (
    echo    ❌ Backend: ARCHIVOS FALTANTES
)

echo.
echo [5/8] Verificando dependencias backend...
if exist "backend\node_modules" (
    echo    ✅ Backend deps: INSTALADAS
) else (
    echo    ⚠️  Backend deps: NO INSTALADAS
    echo       Ejecuta: cd backend && npm install
)

echo.
echo [6/8] Verificando Flutter deps...
if exist "pubspec.yaml" (
    flutter pub get >nul 2>&1
    if %errorlevel% equ 0 (
        echo    ✅ Flutter deps: OK
    ) else (
        echo    ❌ Flutter deps: ERROR
    )
) else (
    echo    ❌ Flutter: pubspec.yaml NO ENCONTRADO
)

echo.
echo [7/8] Verificando conectividad backend...
curl -s http://localhost:3000/health | findstr "status.*ok" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Backend: FUNCIONANDO
) else (
    echo    ❌ Backend: NO RESPONDE
    echo       Ejecuta: cd backend && npm run dev
)

echo.
echo [8/8] Verificando configuracion...
if exist ".env" (
    echo    ✅ Config Flutter: PRESENTE
) else (
    echo    ⚠️  Config Flutter: FALTANTE
    echo       Copia .env.example a .env
)

if exist "backend\.env" (
    echo    ✅ Config Backend: PRESENTE
) else (
    echo    ⚠️  Config Backend: FALTANTE
    echo       Copia backend/.env.example a backend/.env
)

echo.
echo ========================================
echo RESULTADO DEL DIAGNOSTICO
echo ========================================
echo.
echo Si hay errores marcados con ❌, SOLUCIONALOS primero.
echo Si hay advertencias ⚠️, considera resolverlas.
echo.
echo Para iniciar desarrollo completo:
echo   1. .\diagnostico.bat
echo   2. .\start_dev.bat
echo.
pause