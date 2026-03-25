@echo off
echo ========================================
echo TEST DE CONECTIVIDAD BACKEND
echo ========================================
echo.

echo 1. Probando localhost...
curl -s http://localhost:3000/health | findstr "status" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Localhost: OK
) else (
    echo    ❌ Localhost: FALLANDO
)

echo.
echo 2. Probando IP local (192.168.1.9)...
curl -s http://192.168.1.9:3000/health | findstr "status" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ IP Local: OK
) else (
    echo    ❌ IP Local: FALLANDO
)

echo.
echo 3. Verificando si el backend esta corriendo...
netstat -ano | findstr :3000 >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Puerto 3000: ABIERTO
) else (
    echo    ❌ Puerto 3000: CERRADO
)

echo.
echo ========================================
echo INSTRUCCIONES PARA EMULADOR:
echo ========================================
echo.
echo Si el emulador muestra "error de red":
echo.
echo 1. Asegúrate de que el backend esté corriendo:
echo    cd backend && npm run dev
echo.
echo 2. En Android Studio ^> AVD Manager:
echo    - Detén el emulador
echo    - Edita el dispositivo ^> Show Advanced Settings
echo    - Network: Cambia a "Bridged" si es posible
echo.
echo 3. Si sigue fallando, usa la IP local en .env:
echo    BASE_URL=http://192.168.1.9:3000/api
echo.
echo 4. Reinicia la app Flutter en el emulador
echo.
pause