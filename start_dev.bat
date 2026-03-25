@echo off
echo ========================================
echo INICIANDO DESARROLLO - MUSICAPP VALLEDUPAR
echo ========================================
echo.

echo [1/6] Ejecutando diagnostico...
call diagnostico.bat
if %errorlevel% neq 0 (
    echo ❌ DIAGNOSTICO FALLIDO - Revisa los errores arriba
    pause
    exit /b 1
)

echo.
echo [2/6] Instalando dependencias backend...
cd backend
if not exist "node_modules" (
    echo    Instalando dependencias de Node.js...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Error instalando dependencias backend
        cd ..
        pause
        exit /b 1
    )
) else (
    echo    ✅ Dependencias backend ya instaladas
)

echo.
echo [3/6] Verificando configuracion backend...
if not exist ".env" (
    echo    Creando .env desde .env.example...
    copy .env.example .env >nul
    echo    ⚠️  Edita backend/.env con tus configuraciones
)

echo.
echo [4/6] Instalando dependencias Flutter...
cd ..
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Error instalando dependencias Flutter
    pause
    exit /b 1
)

echo.
echo [5/6] Verificando configuracion Flutter...
if not exist ".env" (
    echo    Creando .env desde .env.example...
    copy .env.example .env >nul
    echo    ⚠️  Edita .env con tu IP local
)

echo.
echo [6/6] Iniciando servicios...
echo.
echo ========================================
echo SERVICIOS DISPONIBLES
echo ========================================
echo.
echo Backend API:    http://localhost:3000
echo Health Check:   http://localhost:3000/health
echo.
echo Para iniciar backend: cd backend && npm run dev
echo Para iniciar app:     flutter run
echo.
echo ========================================
echo ¡DESARROLLO LISTO!
echo ========================================
echo.
pause