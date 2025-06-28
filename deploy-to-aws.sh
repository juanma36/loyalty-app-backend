#!/bin/bash

# Script de despliegue automatizado a AWS para Loyalty App Backend
# Autor: Sistema de Despliegue Automatizado
# Versión: 1.0

set -e  # Salir si hay algún error

# =============================================================================
# CONFIGURACIÓN - MODIFICA ESTAS VARIABLES SEGÚN TU SETUP
# =============================================================================

# Información de tu instancia EC2
EC2_IP="TU_IP_PUBLICA_AQUI"  # Ejemplo: 18.188.123.45
PEM_FILE="TU_ARCHIVO_PEM_AQUI"  # Ejemplo: loyalty-app-key.pem
PROJECT_NAME="loyalty-app-backend"

# Configuración opcional
SSH_USER="ec2-user"
SSH_PORT="22"
APP_PORT="3000"

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para validar configuración
validate_config() {
    print_header "Validando Configuración"
    
    if [ "$EC2_IP" = "TU_IP_PUBLICA_AQUI" ] || [ -z "$EC2_IP" ]; then
        print_error "❌ Debes configurar EC2_IP en el script"
        exit 1
    fi
    
    if [ "$PEM_FILE" = "TU_ARCHIVO_PEM_AQUI" ] || [ -z "$PEM_FILE" ]; then
        print_error "❌ Debes configurar PEM_FILE en el script"
        exit 1
    fi
    
    if [ ! -f "$PEM_FILE" ]; then
        print_error "❌ El archivo PEM no existe: $PEM_FILE"
        exit 1
    fi
    
    # Verificar que el archivo PEM tenga los permisos correctos
    if [ "$(stat -c %a "$PEM_FILE" 2>/dev/null || stat -f %Lp "$PEM_FILE" 2>/dev/null)" != "600" ]; then
        print_warning "⚠️  Configurando permisos del archivo PEM..."
        chmod 600 "$PEM_FILE"
    fi
    
    print_success "✅ Configuración validada correctamente"
}

# Función para verificar conectividad
check_connectivity() {
    print_header "Verificando Conectividad"
    
    print_status "🔍 Probando conexión SSH a $EC2_IP..."
    if ssh -i "$PEM_FILE" -o ConnectTimeout=10 -o BatchMode=yes "$SSH_USER@$EC2_IP" exit 2>/dev/null; then
        print_success "✅ Conexión SSH exitosa"
    else
        print_error "❌ No se puede conectar a la instancia EC2"
        print_error "   Verifica:"
        print_error "   - La IP pública es correcta"
        print_error "   - El archivo PEM es válido"
        print_error "   - El Security Group permite SSH (puerto 22)"
        exit 1
    fi
}

# Función para crear backup
create_backup() {
    print_header "Creando Backup"
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="${PROJECT_NAME}_backup_${TIMESTAMP}.tar.gz"
    
    print_status "📦 Creando backup del código actual..."
    tar -czf "$BACKUP_FILE" --exclude=node_modules --exclude=.git --exclude=*.tar.gz .
    
    if [ $? -eq 0 ]; then
        print_success "✅ Backup creado: $BACKUP_FILE"
    else
        print_error "❌ Error creando backup"
        exit 1
    fi
}

# Función para preparar archivo de despliegue
prepare_deployment() {
    print_header "Preparando Archivo de Despliegue"
    
    print_status "📦 Creando archivo tar para despliegue..."
    tar -czf "${PROJECT_NAME}.tar.gz" --exclude=node_modules --exclude=.git --exclude=*.tar.gz .
    
    if [ $? -eq 0 ]; then
        print_success "✅ Archivo de despliegue creado: ${PROJECT_NAME}.tar.gz"
        
        # Mostrar tamaño del archivo
        FILE_SIZE=$(du -h "${PROJECT_NAME}.tar.gz" | cut -f1)
        print_status "📊 Tamaño del archivo: $FILE_SIZE"
    else
        print_error "❌ Error creando archivo de despliegue"
        exit 1
    fi
}

# Función para subir archivo a EC2
upload_to_ec2() {
    print_header "Subiendo Archivo a EC2"
    
    print_status "📤 Subiendo ${PROJECT_NAME}.tar.gz a $EC2_IP..."
    scp -i "$PEM_FILE" -o ConnectTimeout=30 "${PROJECT_NAME}.tar.gz" "$SSH_USER@$EC2_IP:~/"
    
    if [ $? -eq 0 ]; then
        print_success "✅ Archivo subido exitosamente"
    else
        print_error "❌ Error subiendo archivo a EC2"
        exit 1
    fi
}

# Función para ejecutar despliegue en EC2
deploy_on_ec2() {
    print_header "Ejecutando Despliegue en EC2"
    
    print_status "🔧 Ejecutando script de despliegue en la instancia..."
    
    ssh -i "$PEM_FILE" "$SSH_USER@$EC2_IP" << 'EOF'
        set -e
        
        echo "📁 Extrayendo archivo..."
        tar -xzf loyalty-app-backend.tar.gz
        
        echo "📂 Navegando al directorio..."
        cd loyalty-app-backend
        
        echo "🔧 Configurando permisos..."
        chmod +x deploy-ec2.sh
        
        echo "🚀 Ejecutando script de despliegue..."
        ./deploy-ec2.sh
        
        echo "✅ Despliegue completado en EC2"
        
        # Verificar que la aplicación esté ejecutándose
        echo "🔍 Verificando estado de la aplicación..."
        sleep 10
        
        if sudo docker ps | grep -q loyalty-app-backend; then
            echo "✅ Contenedor ejecutándose correctamente"
        else
            echo "❌ El contenedor no está ejecutándose"
            exit 1
        fi
EOF
    
    if [ $? -eq 0 ]; then
        print_success "✅ Despliegue en EC2 completado exitosamente"
    else
        print_error "❌ Error durante el despliegue en EC2"
        exit 1
    fi
}

# Función para verificar despliegue
verify_deployment() {
    print_header "Verificando Despliegue"
    
    print_status "🔍 Verificando que la aplicación esté ejecutándose..."
    
    # Verificar contenedor
    if ssh -i "$PEM_FILE" "$SSH_USER@$EC2_IP" "sudo docker ps | grep -q loyalty-app-backend"; then
        print_success "✅ Contenedor ejecutándose"
    else
        print_error "❌ El contenedor no está ejecutándose"
        return 1
    fi
    
    # Verificar endpoint de salud
    print_status "🏥 Probando endpoint de salud..."
    sleep 5
    
    if curl -s -f "http://$EC2_IP:$APP_PORT/health" > /dev/null; then
        print_success "✅ Endpoint de salud respondiendo"
    else
        print_warning "⚠️  Endpoint de salud no responde (puede tardar en iniciar)"
    fi
    
    # Mostrar información de la aplicación
    print_status "📊 Información de la aplicación:"
    echo -e "${CYAN}   🌐 URL: http://$EC2_IP:$APP_PORT${NC}"
    echo -e "${CYAN}   📚 API Docs: http://$EC2_IP:$APP_PORT/api-docs${NC}"
    echo -e "${CYAN}   🏥 Health: http://$EC2_IP:$APP_PORT/health${NC}"
}

# Función para limpiar archivos temporales
cleanup() {
    print_header "Limpieza"
    
    print_status "🧹 Eliminando archivos temporales..."
    rm -f "${PROJECT_NAME}.tar.gz"
    print_success "✅ Archivos temporales eliminados"
}

# Función para mostrar comandos útiles
show_useful_commands() {
    print_header "Comandos Útiles"
    
    echo -e "${CYAN}📝 Ver logs en tiempo real:${NC}"
    echo "   ssh -i \"$PEM_FILE\" $SSH_USER@$EC2_IP \"sudo docker-compose -f docker-compose.prod.yml logs -f\""
    echo ""
    
    echo -e "${CYAN}🔍 Ver estado de contenedores:${NC}"
    echo "   ssh -i \"$PEM_FILE\" $SSH_USER@$EC2_IP \"sudo docker ps\""
    echo ""
    
    echo -e "${CYAN}🔄 Reiniciar aplicación:${NC}"
    echo "   ssh -i \"$PEM_FILE\" $SSH_USER@$EC2_IP \"sudo docker-compose -f docker-compose.prod.yml restart\""
    echo ""
    
    echo -e "${CYAN}🛑 Detener aplicación:${NC}"
    echo "   ssh -i \"$PEM_FILE\" $SSH_USER@$EC2_IP \"sudo docker-compose -f docker-compose.prod.yml down\""
    echo ""
    
    echo -e "${CYAN}🏥 Probar endpoint de salud:${NC}"
    echo "   curl http://$EC2_IP:$APP_PORT/health"
    echo ""
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    print_header "🚀 DESPLIEGUE AUTOMATIZADO - LOYALTY APP BACKEND"
    
    # Verificar que estemos en el directorio correcto
    if [ ! -f "package.json" ] || [ ! -f "deploy.sh" ]; then
        print_error "❌ Este script debe ejecutarse desde el directorio raíz del proyecto"
        exit 1
    fi
    
    # Verificar dependencias
    if ! command_exists tar; then
        print_error "❌ El comando 'tar' no está disponible"
        exit 1
    fi
    
    if ! command_exists scp; then
        print_error "❌ El comando 'scp' no está disponible"
        exit 1
    fi
    
    if ! command_exists ssh; then
        print_error "❌ El comando 'ssh' no está disponible"
        exit 1
    fi
    
    # Ejecutar pasos del despliegue
    validate_config
    check_connectivity
    create_backup
    prepare_deployment
    upload_to_ec2
    deploy_on_ec2
    verify_deployment
    cleanup
    
    print_header "🎉 ¡DESPLIEGUE COMPLETADO EXITOSAMENTE!"
    print_success "Tu aplicación está ahora ejecutándose en AWS"
    
    show_useful_commands
    
    print_header "📊 RESUMEN"
    echo -e "${GREEN}✅ Backup creado${NC}"
    echo -e "${GREEN}✅ Archivo subido a EC2${NC}"
    echo -e "${GREEN}✅ Aplicación desplegada${NC}"
    echo -e "${GREEN}✅ Verificación completada${NC}"
    echo ""
    echo -e "${YELLOW}🌐 Tu aplicación está disponible en: http://$EC2_IP:$APP_PORT${NC}"
}

# =============================================================================
# EJECUCIÓN
# =============================================================================

# Capturar interrupciones para limpiar archivos temporales
trap 'print_error "❌ Despliegue interrumpido"; rm -f "${PROJECT_NAME}.tar.gz"; exit 1' INT TERM

# Ejecutar función principal
main "$@" 