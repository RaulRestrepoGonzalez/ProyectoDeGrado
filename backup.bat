@echo off
echo ========================================
echo BACKUP AUTOMATICO - MUSICAPP VALLEDUPAR
echo ========================================
echo.

set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_DIR=backups\%TIMESTAMP%

echo Creando backup en: %BACKUP_DIR%

if not exist "backups" mkdir backups
mkdir %BACKUP_DIR%

echo.
echo [1/4] Respaldando configuracion...
if exist ".env" copy .env %BACKUP_DIR%\
if exist "backend\.env" copy backend\.env %BACKUP_DIR%\

echo [2/4] Respaldando base de datos...
mongodump --db soundupar_db --out %BACKUP_DIR%\mongodb_backup >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Base de datos respaldada
) else (
    echo    ⚠️  No se pudo respaldar base de datos (MongoDB no ejecutándose)
)

echo [3/4] Respaldando codigo fuente...
xcopy lib %BACKUP_DIR%\lib\ /E /I /H /Y >nul 2>&1
xcopy backend %BACKUP_DIR%\backend\ /E /I /H /Y >nul 2>&1
copy pubspec.yaml %BACKUP_DIR%\ >nul 2>&1
copy README.md %BACKUP_DIR%\ >nul 2>&1

echo [4/4] Creando archivo comprimido...
powershell "Compress-Archive -Path '%BACKUP_DIR%' -DestinationPath '%BACKUP_DIR%.zip' -Force" >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✅ Backup comprimido creado
    rmdir /s /q %BACKUP_DIR%
) else (
    echo    ⚠️  No se pudo comprimir (PowerShell no disponible)
)

echo.
echo ========================================
echo BACKUP COMPLETADO
echo ========================================
echo.
echo Ubicacion: %BACKUP_DIR%.zip
echo Fecha: %TIMESTAMP%
echo.
echo Para restaurar:
echo   1. Extraer el archivo .zip
echo   2. Copiar .env files
echo   3. Restaurar BD: mongorestore %BACKUP_DIR%\mongodb_backup
echo.
pause