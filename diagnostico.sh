#!/bin/bash

echo "========================================"
echo "DIAGNOSTICO COMPLETO - MUSICAPP VALLEDUPAR"
echo "========================================"
echo

# Función para verificar comandos
check_command() {
    if command -v $1 &> /dev/null; then
        echo "    ✅ $2: INSTALADO"
        return 0
    else
        echo "    ❌ $2: NO ENCONTRADO"
        return 1
    fi
}

echo "[1/8] Verificando Flutter..."
check_command flutter "Flutter"

echo
echo "[2/8] Verificando Node.js..."
check_command node "Node.js"

echo
echo "[3/8] Verificando MongoDB..."
if pgrep mongod > /dev/null; then
    echo "    ✅ MongoDB: EJECUTANDOSE"
else
    echo "    ⚠️  MongoDB: NO EJECUTANDOSE (inicia con: sudo systemctl start mongod)"
fi

echo
echo "[4/8] Verificando backend..."
if [ -f "backend/package.json" ]; then
    echo "    ✅ Backend: ARCHIVOS PRESENTES"
else
    echo "    ❌ Backend: ARCHIVOS FALTANTES"
fi

echo
echo "[5/8] Verificando dependencias backend..."
if [ -d "backend/node_modules" ]; then
    echo "    ✅ Backend deps: INSTALADAS"
else
    echo "    ⚠️  Backend deps: NO INSTALADAS"
    echo "       Ejecuta: cd backend && npm install"
fi

echo
echo "[6/8] Verificando Flutter deps..."
if [ -f "pubspec.yaml" ]; then
    flutter pub get > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    ✅ Flutter deps: OK"
    else
        echo "    ❌ Flutter deps: ERROR"
    fi
else
    echo "    ❌ Flutter: pubspec.yaml NO ENCONTRADO"
fi

echo
echo "[7/8] Verificando conectividad backend..."
if curl -s http://localhost:3000/health | grep -q "status.*ok"; then
    echo "    ✅ Backend: FUNCIONANDO"
else
    echo "    ❌ Backend: NO RESPONDE"
    echo "       Ejecuta: cd backend && npm run dev"
fi

echo
echo "[8/8] Verificando configuracion..."
if [ -f ".env" ]; then
    echo "    ✅ Config Flutter: PRESENTE"
else
    echo "    ⚠️  Config Flutter: FALTANTE"
    echo "       Copia .env.example a .env"
fi

if [ -f "backend/.env" ]; then
    echo "    ✅ Config Backend: PRESENTE"
else
    echo "    ⚠️  Config Backend: FALTANTE"
    echo "       Copia backend/.env.example a backend/.env"
fi

echo
echo "========================================"
echo "RESULTADO DEL DIAGNOSTICO"
echo "========================================"
echo
echo "Si hay errores marcados con ❌, SOLUCIONALOS primero."
echo "Si hay advertencias ⚠️, considera resolverlas."
echo
echo "Para iniciar desarrollo completo:"
echo "   1. ./diagnostico.sh"
echo "   2. ./start_dev.sh"
echo
read -p "Presiona Enter para continuar..."