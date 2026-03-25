#!/bin/bash

echo "========================================"
echo "INICIANDO DESARROLLO - MUSICAPP VALLEDUPAR"
echo "========================================"
echo

echo "[1/6] Ejecutando diagnostico..."
chmod +x diagnostico.sh
./diagnostico.sh
if [ $? -ne 0 ]; then
    echo "❌ DIAGNOSTICO FALLIDO - Revisa los errores arriba"
    exit 1
fi

echo
echo "[2/6] Instalando dependencias backend..."
cd backend
if [ ! -d "node_modules" ]; then
    echo "    Instalando dependencias de Node.js..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Error instalando dependencias backend"
        cd ..
        exit 1
    fi
else
    echo "    ✅ Dependencias backend ya instaladas"
fi

echo
echo "[3/6] Verificando configuracion backend..."
if [ ! -f ".env" ]; then
    echo "    Creando .env desde .env.example..."
    cp .env.example .env
    echo "    ⚠️  Edita backend/.env con tus configuraciones"
fi

echo
echo "[4/6] Instalando dependencias Flutter..."
cd ..
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias Flutter"
    exit 1
fi

echo
echo "[5/6] Verificando configuracion Flutter..."
if [ ! -f ".env" ]; then
    echo "    Creando .env desde .env.example..."
    cp .env.example .env
    echo "    ⚠️  Edita .env con tu IP local"
fi

echo
echo "[6/6] Iniciando servicios..."
echo
echo "========================================"
echo "SERVICIOS DISPONIBLES"
echo "========================================"
echo
echo "Backend API:    http://localhost:3000"
echo "Health Check:   http://localhost:3000/health"
echo
echo "Para iniciar backend: cd backend && npm run dev"
echo "Para iniciar app:     flutter run"
echo
echo "========================================"
echo "¡DESARROLLO LISTO!"
echo "========================================"
echo
read -p "Presiona Enter para continuar..."