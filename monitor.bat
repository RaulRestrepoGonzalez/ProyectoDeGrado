@echo off
echo ========================================
echo MONITOR DE SERVICIOS - MUSICAPP VALLEDUPAR
echo ========================================
echo.

:loop
echo [%date% %time%] Verificando servicios...

REM Verificar backend
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Backend NO responde - Reiniciando...
    taskkill /f /im node.exe >nul 2>&1
    cd backend
    start /b npm run dev
    cd ..
    echo ✅ Backend reiniciado
) else (
    echo ✅ Backend OK
)

REM Verificar MongoDB
mongod --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  MongoDB no encontrado - Usando configuración local
) else (
    echo ✅ MongoDB disponible
)

echo.
timeout /t 30 /nobreak >nul
goto loop