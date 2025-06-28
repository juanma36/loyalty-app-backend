# 🚀 Guía de Despliegue Automatizado - Loyalty App Backend

## 📋 Resumen

Este sistema de despliegue automatizado te permite desplegar tu backend desde tu máquina local hasta AWS EC2 con un solo comando.

## 🛠️ Configuración Inicial

### 1. Preparar la Configuración

```bash
# Copiar el archivo de configuración
cp deploy-config.env .env.deploy

# Editar la configuración con tu información
nano .env.deploy
```

### 2. Configurar Variables

Edita el archivo `.env.deploy` con tu información:

```bash
# Tu IP pública de EC2 (desde la consola de AWS)
EC2_IP="3.17.71.235"

# Ruta a tu archivo PEM
PEM_FILE="/Users/juan.gonzalez/Downloads/loyalty-app-key.pem"
```

### 3. Dar Permisos de Ejecución

```bash
chmod +x deploy.sh
chmod +x deploy-to-aws.sh
chmod +x deploy-ec2.sh
```

## 🚀 Despliegue

### Despliegue Completo (Recomendado)

```bash
./deploy.sh
```

### Despliegue Manual

Si prefieres hacerlo paso a paso:

```bash
# 1. Crear archivo de despliegue
tar -czf loyalty-app-backend.tar.gz --exclude=node_modules --exclude=.git .

# 2. Subir a EC2
scp -i "tu-archivo.pem" loyalty-app-backend.tar.gz ec2-user@tu-ip:~/

# 3. Conectarse y desplegar
ssh -i "tu-archivo.pem" ec2-user@tu-ip
tar -xzf loyalty-app-backend.tar.gz
cd loyalty-app-backend
chmod +x deploy-ec2.sh
./deploy-ec2.sh
```

## 📊 Monitoreo

### Ver Logs en Tiempo Real

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml logs -f"
```

### Ver Estado de Contenedores

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker ps"
```

### Probar Endpoint de Salud

```bash
curl http://tu-ip:3000/health
```

### Ver Documentación de la API

```bash
curl http://tu-ip:3000/api-docs
```

## 🔧 Comandos Útiles

### Reiniciar Aplicación

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml restart"
```

### Detener Aplicación

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml down"
```

### Ver Logs de Errores

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml logs --tail=100"
```

### Acceder al Contenedor

```bash
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker exec -it loyalty-app-backend sh"
```

## 🔍 Troubleshooting

### Problema: No se puede conectar a EC2

**Solución:**
- Verifica que la IP pública sea correcta
- Asegúrate de que el Security Group permita SSH (puerto 22)
- Verifica que el archivo PEM tenga permisos 600

### Problema: La aplicación no inicia

**Solución:**
```bash
# Ver logs de error
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml logs"

# Verificar variables de entorno
ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker exec loyalty-app-backend env | grep DB_"
```

### Problema: No se puede conectar a la base de datos

**Solución:**
- Verifica que RDS esté ejecutándose
- Asegúrate de que el Security Group de RDS permita conexiones desde EC2
- Verifica las credenciales de la base de datos

### Problema: Puerto 3000 no está accesible

**Solución:**
- Verifica que el Security Group de EC2 permita tráfico al puerto 3000
- Asegúrate de que la aplicación esté ejecutándose

## 📁 Estructura de Archivos

```
loyalty-app-backend/
├── deploy.sh              # Script principal de despliegue
├── deploy-to-aws.sh       # Script completo de automatización
├── deploy-ec2.sh          # Script de despliegue en EC2
├── deploy-config.env      # Plantilla de configuración
├── .env.deploy           # Tu configuración (crear manualmente)
├── docker-compose.prod.yml # Configuración de Docker para producción
└── DEPLOYMENT-GUIDE.md   # Esta guía
```

## 🔄 Flujo de Trabajo Típico

1. **Desarrollo Local**
   ```bash
   git add .
   git commit -m "Nuevas funcionalidades"
   git push origin main
   ```

2. **Despliegue**
   ```bash
   ./deploy.sh
   ```

3. **Verificación**
   ```bash
   curl http://tu-ip:3000/health
   ```

4. **Monitoreo**
   ```bash
   ssh -i "tu-archivo.pem" ec2-user@tu-ip "sudo docker-compose -f docker-compose.prod.yml logs -f"
   ```

## ⚠️ Consideraciones de Seguridad

- **Archivo PEM**: Mantén tu archivo PEM seguro y con permisos 600
- **Variables de Entorno**: No subas archivos `.env` al repositorio
- **Security Groups**: Configura correctamente los Security Groups en AWS
- **Backups**: El script crea automáticamente backups antes de cada despliegue

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs: `sudo docker-compose -f docker-compose.prod.yml logs`
2. Verifica la conectividad: `telnet tu-ip 3000`
3. Revisa los Security Groups en la consola de AWS
4. Verifica que Docker esté ejecutándose: `sudo systemctl status docker`

---

**¡Tu aplicación está lista para producción! 🎉** 