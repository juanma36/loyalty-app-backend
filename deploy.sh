#!/bin/bash

# Script simplificado de despliegue que usa archivo de configuración
# Uso: ./deploy.sh

# Cargar configuración
if [ -f ".env.deploy" ]; then
    source .env.deploy
else
    echo "❌ Error: No se encontró el archivo .env.deploy"
    echo "📝 Crea el archivo copiando deploy-config.env como .env.deploy"
    echo "🔧 Luego modifica las variables con tu información"
    exit 1
fi

# Verificar configuración
if [ "$EC2_IP" = "TU_IP_PUBLICA_AQUI" ] || [ -z "$EC2_IP" ]; then
    echo "❌ Error: Debes configurar EC2_IP en .env.deploy"
    exit 1
fi

if [ "$PEM_FILE" = "TU_ARCHIVO_PEM_AQUI" ] || [ -z "$PEM_FILE" ]; then
    echo "❌ Error: Debes configurar PEM_FILE en .env.deploy"
    exit 1
fi

if [ ! -f "$PEM_FILE" ]; then
    echo "❌ Error: El archivo PEM no existe: $PEM_FILE"
    exit 1
fi

# Ejecutar el script completo
./deploy-to-aws.sh 