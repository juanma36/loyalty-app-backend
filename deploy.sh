#!/bin/bash

# Script de despliegue para EC2
echo "🚀 Iniciando despliegue de Loyalty App Backend..."

# Actualizar el sistema
echo "📦 Actualizando el sistema..."
sudo yum update -y

# Instalar Docker
echo "🐳 Instalando Docker..."
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Instalar Docker Compose
echo "📋 Instalando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Crear directorio para la aplicación
echo "📁 Creando directorio de la aplicación..."
mkdir -p /home/ec2-user/loyalty-app-backend
cd /home/ec2-user/loyalty-app-backend

# Crear archivo .env con las variables de entorno
echo "🔧 Configurando variables de entorno..."
cat > .env << EOF
# Database Configuration
DB_HOST=loyalty-app-db.czme82402gkh.us-east-2.rds.amazonaws.com
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=Gian!1978
DB_DATABASE=loyalty-app-db

# Application Configuration
NODE_ENV=production
PORT=3000
EOF

echo "✅ Variables de entorno configuradas"

# Construir y ejecutar la aplicación
echo "🔨 Construyendo la aplicación..."
sudo docker-compose -f docker-compose.prod.yml up -d --build

echo "🎉 ¡Despliegue completado!"
echo "📊 La aplicación está ejecutándose en: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "📝 Para ver los logs: sudo docker-compose -f docker-compose.prod.yml logs -f"
echo "🛑 Para detener: sudo docker-compose -f docker-compose.prod.yml down" 