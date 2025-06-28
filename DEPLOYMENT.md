# Guía de Despliegue - Loyalty App Backend

## Prerrequisitos

- Una instancia EC2 en AWS
- Una base de datos RDS PostgreSQL configurada
- El archivo `.pem` de tu par de claves de EC2

## Pasos de Despliegue

### 1. Conectarse a tu instancia EC2

```bash
# Reemplaza con tu IP pública y el nombre de tu archivo .pem
ssh -i "tu-archivo.pem" ec2-user@tu-ip-publica.amazonaws.com
```

### 2. Subir los archivos del proyecto

Desde tu máquina local, en el directorio del proyecto:

```bash
# Crear un archivo tar con el proyecto
tar -czf loyalty-app-backend.tar.gz --exclude=node_modules --exclude=.git .

# Subir el archivo a EC2 (reemplaza con tu IP)
scp -i "tu-archivo.pem" loyalty-app-backend.tar.gz ec2-user@tu-ip-publica.amazonaws.com:~/
```

### 3. En la instancia EC2

```bash
# Extraer el proyecto
tar -xzf loyalty-app-backend.tar.gz
cd loyalty-app-backend

# Dar permisos de ejecución al script
chmod +x deploy.sh

# Ejecutar el script de despliegue
./deploy.sh
```

### 4. Verificar el despliegue

```bash
# Verificar que el contenedor esté ejecutándose
sudo docker ps

# Ver los logs de la aplicación
sudo docker-compose -f docker-compose.prod.yml logs -f

# Verificar que la aplicación responda
curl http://localhost:3000/health
```

## Configuración de Seguridad

### Configurar Security Groups

1. **Para EC2:**
   - Puerto 22 (SSH)
   - Puerto 80 (HTTP)
   - Puerto 443 (HTTPS)
   - Puerto 3000 (tu aplicación)

2. **Para RDS:**
   - Puerto 5432 (PostgreSQL) - solo desde la IP de tu EC2

### Configurar variables de entorno

El script `deploy.sh` ya configura las variables de entorno, pero puedes modificarlas editando el archivo `.env` en EC2:

```bash
sudo nano /home/ec2-user/loyalty-app-backend/.env
```

## Comandos Útiles

```bash
# Ver logs en tiempo real
sudo docker-compose -f docker-compose.prod.yml logs -f

# Detener la aplicación
sudo docker-compose -f docker-compose.prod.yml down

# Reiniciar la aplicación
sudo docker-compose -f docker-compose.prod.yml restart

# Ver el estado de los contenedores
sudo docker ps

# Acceder al contenedor
sudo docker exec -it loyalty-app-backend sh
```

## Monitoreo

### Verificar la salud de la aplicación

```bash
# Verificar endpoint de salud
curl http://localhost:3000/health

# Verificar logs de la aplicación
sudo docker logs loyalty-app-backend
```

### Configurar logs

Los logs se pueden ver con:

```bash
# Logs de Docker Compose
sudo docker-compose -f docker-compose.prod.yml logs

# Logs del contenedor específico
sudo docker logs loyalty-app-backend
```

## Troubleshooting

### Si la aplicación no inicia:

1. Verificar que la base de datos esté accesible:
```bash
telnet loyalty-app-db.czme82402gkh.us-east-2.rds.amazonaws.com 5432
```

2. Verificar las variables de entorno:
```bash
sudo docker exec loyalty-app-backend env | grep DB_
```

3. Verificar los logs:
```bash
sudo docker-compose -f docker-compose.prod.yml logs
```

### Si hay problemas de conectividad:

1. Verificar que el Security Group de RDS permita conexiones desde la IP de EC2
2. Verificar que el Security Group de EC2 permita tráfico saliente al puerto 5432

## Actualizaciones

Para actualizar la aplicación:

```bash
# Detener la aplicación actual
sudo docker-compose -f docker-compose.prod.yml down

# Subir el nuevo código (repetir paso 2)
# Luego ejecutar:
sudo docker-compose -f docker-compose.prod.yml up -d --build
``` 