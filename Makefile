# Makefile para proyectos C++ con Crow
CXX = g++

# Flags comunes
COMMON_FLAGS = -std=c++20 -DCROW_MAIN

# Flags para DESARROLLO
CXXFLAGS_DEV = $(COMMON_FLAGS) -Wall -Wextra -Wpedantic -g -O0

# Flags para PRODUCCIÓN (OPTIMIZADO)
CXXFLAGS_PROD = $(COMMON_FLAGS) -O3 -march=native -DNDEBUG \
                -ffunction-sections -fdata-sections \
                -flto -fvisibility=hidden

# Flags de enlace
LDFLAGS = -lpthread

# Flags de enlace para PRODUCCIÓN
LDFLAGS_PROD = -lpthread \
               -Wl,--gc-sections \
               -Wl,--strip-all \
               -flto \
               -static-libgcc \
               -static-libstdc++

# Directorios
SRCDIR = src
INCDIR = include
BUILDDIR = build
BUILDDIR_PROD = build/production
BINDIR = build

# Archivos fuente
SOURCES = $(wildcard $(SRCDIR)/*.cpp)
OBJECTS = $(SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR)/%.o)
OBJECTS_PROD = $(SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR_PROD)/%.o)
TARGET = $(BINDIR)/main
TARGET_PROD = $(BINDIR)/api

# ============================================
# VARIABLES DOCKER (Personalizables)
# ============================================
# Puedes cambiar estos valores aquí o desde la línea de comandos:
# make docker-build DOCKER_IMAGE=mi-api DOCKER_TAG=v1.0

DOCKER_IMAGE ?= crow-api
DOCKER_TAG ?= latest
DOCKER_REGISTRY ?=
DOCKER_CONTAINER_NAME ?= crow-api-dev

# Nombre completo de la imagen
ifeq ($(DOCKER_REGISTRY),)
    DOCKER_FULL_IMAGE = $(DOCKER_IMAGE):$(DOCKER_TAG)
else
    DOCKER_FULL_IMAGE = $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
endif

# Regla principal (desarrollo)
all: crow-check $(TARGET)

# ============================================
# TARGETS DE PRODUCCIÓN
# ============================================

# Compilar para producción (target principal optimizado)
production: crow-check $(TARGET_PROD)
	@echo ""
	@echo "✅ Binario de producción generado!"
	@echo "📊 Información del binario:"
	@ls -lh $(TARGET_PROD)
	@file $(TARGET_PROD)
	@echo ""
	@echo "🔍 Dependencias dinámicas:"
	@ldd $(TARGET_PROD) 2>/dev/null || echo "Binario estático (sin dependencias dinámicas)"
	@echo ""
	@echo "📦 Tamaño de secciones:"
	@size $(TARGET_PROD)
	@echo ""
	@echo "🚀 Listo para desplegar: $(TARGET_PROD)"

# Crear ejecutable de producción (YA con strip automático por -Wl,--strip-all)
$(TARGET_PROD): $(OBJECTS_PROD) | build-dirs-prod
	@echo "🔗 Enlazando ejecutable de producción optimizado..."
	$(CXX) $(CXXFLAGS_PROD) $(OBJECTS_PROD) -o $@ $(LDFLAGS_PROD)
	@echo "✅ Compilación de producción completada (optimizado y stripped)"

# Compilar archivos objeto para producción
$(BUILDDIR_PROD)/%.o: $(SRCDIR)/%.cpp | build-dirs-prod
	@echo "🔨 Compilando para producción: $<..."
	$(CXX) $(CXXFLAGS_PROD) -I$(INCDIR) -c $< -o $@

# Crear directorios de producción
build-dirs-prod:
	@mkdir -p $(BUILDDIR_PROD) $(BINDIR)

# Análisis completo del binario de producción
analyze-production: $(TARGET_PROD)
	@echo "=========================================="
	@echo "📊 ANÁLISIS COMPLETO DEL BINARIO"
	@echo "=========================================="
	@echo ""
	@echo "📁 Tamaño del archivo:"
	@ls -lh $(TARGET_PROD)
	@du -h $(TARGET_PROD)
	@echo ""
	@echo "🔍 Tipo de archivo:"
	@file $(TARGET_PROD)
	@echo ""
	@echo "📚 Dependencias dinámicas:"
	@ldd $(TARGET_PROD) 2>/dev/null || echo "✅ Binario completamente estático"
	@echo ""
	@echo "🔧 Información del binario (ELF):"
	@readelf -h $(TARGET_PROD) 2>/dev/null | grep -E "(Class|Type|Machine)" || true
	@echo ""
	@echo "📦 Secciones del binario:"
	@size $(TARGET_PROD)
	@echo ""
	@echo "🔐 Protecciones de seguridad:"
	@readelf -l $(TARGET_PROD) 2>/dev/null | grep -E "(GNU_STACK|GNU_RELRO)" || true
	@echo ""
	@echo "🎯 Símbolos exportados:"
	@nm -D $(TARGET_PROD) 2>/dev/null | wc -l | xargs echo "   Símbolos dinámicos:"
	@echo ""
	@echo "=========================================="

# Comparar binarios dev vs prod
compare: $(TARGET) $(TARGET_PROD)
	@echo "=========================================="
	@echo "⚖️  COMPARACIÓN DEV vs PROD"
	@echo "=========================================="
	@echo ""
	@echo "📊 DESARROLLO ($(TARGET)):"
	@ls -lh $(TARGET)
	@size $(TARGET) | tail -1
	@echo ""
	@echo "🚀 PRODUCCIÓN ($(TARGET_PROD)):"
	@ls -lh $(TARGET_PROD)
	@size $(TARGET_PROD) | tail -1
	@echo ""
	@dev_size=$$(stat -c%s "$(TARGET)" 2>/dev/null || stat -f%z "$(TARGET)"); \
	prod_size=$$(stat -c%s "$(TARGET_PROD)" 2>/dev/null || stat -f%z "$(TARGET_PROD)"); \
	reduction=$$(echo "scale=1; ($$dev_size - $$prod_size) * 100 / $$dev_size" | bc 2>/dev/null || echo "N/A"); \
	echo "💾 Reducción de tamaño: $$reduction%"
	@echo "=========================================="

# ============================================
# TARGETS DE DOCKER
# ============================================

# Construir imagen Docker
docker-build: production
	@echo "🐳 Construyendo imagen Docker..."
	@echo "📦 Imagen: $(DOCKER_FULL_IMAGE)"
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "❌ Docker no está instalado o no está disponible"; \
		echo "💡 Asegúrate de tener Docker instalado y corriendo"; \
		exit 1; \
	fi
	@if [ ! -f Dockerfile ]; then \
		echo "❌ Dockerfile no encontrado"; \
		exit 1; \
	fi
	docker build -t $(DOCKER_FULL_IMAGE) .
	@echo ""
	@echo "✅ Imagen Docker construida: $(DOCKER_FULL_IMAGE)"
	@docker images $(DOCKER_IMAGE)

# Ejecutar contenedor (foreground)
docker-run: docker-build
	@echo "🚀 Ejecutando contenedor: $(DOCKER_CONTAINER_NAME)"
	@echo "📡 API disponible en: http://localhost:8080"
	@echo "⏹️  Presiona Ctrl+C para detener"
	docker run --rm -p 8080:8080 --name $(DOCKER_CONTAINER_NAME) $(DOCKER_FULL_IMAGE)

# Ejecutar contenedor (background)
docker-run-bg: docker-build
	@echo "🚀 Ejecutando contenedor en background..."
	@if docker ps -a --format '{{.Names}}' | grep -q "^$(DOCKER_CONTAINER_NAME)$$"; then \
		echo "⚠️  El contenedor '$(DOCKER_CONTAINER_NAME)' ya existe. Eliminándolo..."; \
		docker rm -f $(DOCKER_CONTAINER_NAME) 2>/dev/null || true; \
	fi
	docker run -d -p 8080:8080 --name $(DOCKER_CONTAINER_NAME) $(DOCKER_FULL_IMAGE)
	@echo "✅ Contenedor corriendo: $(DOCKER_CONTAINER_NAME)"
	@echo "📡 API disponible en: http://localhost:8080"
	@echo "📋 Ver logs: make docker-logs"
	@echo "🛑 Detener: make docker-stop"

# Ver logs del contenedor
docker-logs:
	@if docker ps --format '{{.Names}}' | grep -q "^$(DOCKER_CONTAINER_NAME)$$"; then \
		echo "📋 Logs de $(DOCKER_CONTAINER_NAME):"; \
		docker logs -f $(DOCKER_CONTAINER_NAME); \
	else \
		echo "❌ El contenedor '$(DOCKER_CONTAINER_NAME)' no está corriendo"; \
		echo "💡 Usa 'make docker-run-bg' para iniciarlo"; \
	fi

# Detener contenedor
docker-stop:
	@echo "🛑 Deteniendo contenedor: $(DOCKER_CONTAINER_NAME)"
	@docker stop $(DOCKER_CONTAINER_NAME) 2>/dev/null || echo "⚠️  Contenedor no encontrado o ya detenido"
	@docker rm $(DOCKER_CONTAINER_NAME) 2>/dev/null || true
	@echo "✅ Contenedor detenido y eliminado"

# Test automático del contenedor
docker-test: docker-run-bg
	@echo "🧪 Esperando que el servidor inicie..."
	@sleep 3
	@echo "🧪 Probando endpoint /api/tareas..."
	@if curl -s -f http://localhost:8080/api/tareas > /dev/null; then \
		echo "✅ API respondió correctamente"; \
		curl -s http://localhost:8080/api/tareas | head -20; \
	else \
		echo "❌ Error al conectar con la API"; \
	fi
	@echo ""
	@$(MAKE) docker-stop

# Inspeccionar imagen
docker-inspect: docker-build
	@echo "=========================================="
	@echo "🔍 INFORMACIÓN DE LA IMAGEN"
	@echo "=========================================="
	@echo ""
	@echo "📦 Imagen: $(DOCKER_FULL_IMAGE)"
	@docker images $(DOCKER_IMAGE) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
	@echo ""
	@echo "📚 Historial de capas (primeras 10):"
	@docker history $(DOCKER_FULL_IMAGE) --no-trunc | head -11
	@echo ""
	@echo "🔧 Detalles de configuración:"
	@docker inspect $(DOCKER_FULL_IMAGE) --format='Usuario: {{.Config.User}}'
	@docker inspect $(DOCKER_FULL_IMAGE) --format='Puerto expuesto: {{.Config.ExposedPorts}}'
	@docker inspect $(DOCKER_FULL_IMAGE) --format='Comando: {{.Config.Cmd}}'
	@echo ""
	@echo "=========================================="

# Entrar al contenedor (debug)
docker-shell:
	@if docker ps --format '{{.Names}}' | grep -q "^$(DOCKER_CONTAINER_NAME)$$"; then \
		echo "🐚 Entrando al contenedor $(DOCKER_CONTAINER_NAME)..."; \
		docker exec -it $(DOCKER_CONTAINER_NAME) /bin/sh; \
	else \
		echo "❌ El contenedor '$(DOCKER_CONTAINER_NAME)' no está corriendo"; \
		echo "💡 Usa 'make docker-run-bg' para iniciarlo primero"; \
	fi

# Subir imagen a registry
docker-push: docker-build
	@if [ -z "$(DOCKER_REGISTRY)" ]; then \
		echo "❌ DOCKER_REGISTRY no está configurado"; \
		echo "💡 Usa: make docker-push DOCKER_REGISTRY=tu-usuario"; \
		exit 1; \
	fi
	@echo "📤 Subiendo imagen a registry..."
	docker push $(DOCKER_FULL_IMAGE)
	@echo "✅ Imagen subida: $(DOCKER_FULL_IMAGE)"

# Limpiar imágenes Docker
docker-clean:
	@echo "🧹 Limpiando imágenes Docker de $(DOCKER_IMAGE)..."
	@if docker images $(DOCKER_IMAGE) -q | grep -q .; then \
		docker rmi -f $$(docker images $(DOCKER_IMAGE) -q) 2>/dev/null || true; \
		echo "✅ Imágenes eliminadas"; \
	else \
		echo "ℹ️  No hay imágenes de $(DOCKER_IMAGE) para limpiar"; \
	fi

# Limpiar contenedor y imagen
docker-clean-all: docker-stop docker-clean
	@echo "✅ Limpieza completa de Docker realizada"

# ============================================
# TARGETS ORIGINALES (DESARROLLO)
# ============================================

# Verificar que Crow esté disponible e instalarlo si es necesario
crow-check:
	@echo "🔍 Verificando instalación de Crow..."
	@if ! pkg-config --exists crow 2>/dev/null && [ ! -f /usr/local/include/crow.h ] && [ ! -f /usr/include/crow.h ]; then \
		echo "❌ Crow no encontrado. Instalando dependencias y Crow..."; \
		$(MAKE) install-dependencies; \
		$(MAKE) install-crow-simple; \
	else \
		echo "✅ Crow ya está disponible en el sistema"; \
	fi

# Instalar dependencias necesarias (incluyendo ASIO)
install-dependencies:
	@echo "📦 Instalando dependencias del sistema..."
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema basado en Debian/Ubuntu"; \
		sudo apt-get update; \
		sudo apt-get install -y build-essential cmake git libboost-all-dev libasio-dev curl wget binutils bc; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema basado en RedHat/CentOS"; \
		sudo yum groupinstall -y "Development Tools"; \
		sudo yum install -y cmake git boost-devel asio-devel curl wget binutils bc; \
	elif command -v dnf >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Fedora"; \
		sudo dnf groupinstall -y "Development Tools"; \
		sudo dnf install -y cmake git boost-devel asio-devel curl wget binutils bc; \
	elif command -v pacman >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Arch Linux"; \
		sudo pacman -S --noconfirm base-devel cmake git boost asio curl wget binutils bc; \
	else \
		echo "❌ Sistema no soportado automáticamente."; \
		exit 1; \
	fi
	@echo "✅ Dependencias instaladas correctamente"

# Instalar Crow simple (header-only)
install-crow-simple:
	@echo "📦 Instalando Crow (versión header-only)..."
	@temp_dir=$$(mktemp -d); \
	echo "📁 Directorio temporal: $$temp_dir"; \
	cd "$$temp_dir"; \
	echo "📥 Descargando Crow header-only..."; \
	if command -v wget >/dev/null 2>&1; then \
		wget -O crow_all.h https://github.com/CrowCpp/Crow/releases/download/v1.2.0/crow_all.h; \
	elif command -v curl >/dev/null 2>&1; then \
		curl -L -o crow_all.h https://github.com/CrowCpp/Crow/releases/download/v1.2.0/crow_all.h; \
	else \
		echo "❌ No se encontró wget ni curl"; \
		exit 1; \
	fi; \
	if [ -f crow_all.h ] && [ -s crow_all.h ]; then \
		echo "📦 Instalando header en el sistema..."; \
		sudo mkdir -p /usr/local/include; \
		sudo cp crow_all.h /usr/local/include/crow.h; \
		echo "✅ Crow (header-only) instalado correctamente"; \
	else \
		echo "❌ Error al descargar Crow header-only"; \
		exit 1; \
	fi; \
	cd /; \
	rm -rf "$$temp_dir"

# Crear el ejecutable de desarrollo
$(TARGET): $(OBJECTS) | build-dirs
	@echo "🔗 Enlazando ejecutable de desarrollo..."
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)
	@echo "✅ Compilación de desarrollo completada: $(TARGET)"

# Compilar archivos objeto de desarrollo
$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp | build-dirs
	@echo "🔨 Compilando para desarrollo: $<..."
	$(CXX) $(CXXFLAGS_DEV) -I$(INCDIR) -c $< -o $@

# Crear directorios si no existen
build-dirs:
	@mkdir -p $(BUILDDIR) $(BINDIR)

# Limpiar archivos generados
clean:
	@echo "🧹 Limpiando archivos generados..."
	rm -rf $(BUILDDIR) $(TARGET)
	@echo "✅ Limpieza completada"

# Limpiar solo producción
clean-production:
	@echo "🧹 Limpiando archivos de producción..."
	rm -rf $(BUILDDIR_PROD) $(TARGET_PROD)
	@echo "✅ Limpieza de producción completada"

# Limpiar todo
clean-all: clean clean-production
	@echo "✅ Limpieza completa realizada"

# Ejecutar el programa de desarrollo
run: $(TARGET)
	@echo "🚀 Ejecutando servidor de desarrollo..."
	@echo "📡 Disponible en: http://localhost:8080"
	@echo "⏹️  Presiona Ctrl+C para detener"
	./$(TARGET)

# Ejecutar el programa de producción localmente
run-production: $(TARGET_PROD)
	@echo "🚀 Ejecutando servidor de producción..."
	@echo "📡 Disponible en: http://localhost:8080"
	@echo "⏹️  Presiona Ctrl+C para detener"
	./$(TARGET_PROD)

# Ejecutar en segundo plano
run-bg: $(TARGET)
	@echo "🚀 Ejecutando servidor en segundo plano..."
	@echo "📡 Disponible en: http://localhost:8080"
	./$(TARGET) &
	@echo "💡 Usa 'make stop' para detener el servidor"

# Detener servidor en segundo plano
stop:
	@echo "⏹️  Deteniendo servidor..."
	-pkill -f "./$(TARGET)" 2>/dev/null || true
	-pkill -f "./$(TARGET_PROD)" 2>/dev/null || true
	@echo "✅ Servidor detenido"

# Test rápido del servidor
test: run-bg
	@echo "🧪 Probando servidor..."
	@sleep 2
	@curl -s http://localhost:8080/api/tareas || echo "❌ Error al conectar"
	@$(MAKE) stop

# Debug con gdb
debug: $(TARGET)
	@echo "🐛 Iniciando debug con gdb..."
	gdb ./$(TARGET)

# Verificar memoria con valgrind
valgrind: $(TARGET)
	@echo "🔍 Verificando memoria con valgrind..."
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./$(TARGET)

# Verificar estado del sistema
check-system:
	@echo "🔍 Verificando estado del sistema..."
	@echo "📋 Compilador:"
	@$(CXX) --version | head -1 || echo "❌ g++ no encontrado"
	@echo "📋 Docker:"
	@docker --version 2>/dev/null || echo "❌ Docker no encontrado"
	@echo "📋 Herramientas de binarios:"
	@strip --version | head -1 2>/dev/null || echo "⚠️  strip no encontrado"
	@size --version | head -1 2>/dev/null || echo "⚠️  size no encontrado"
	@echo "📋 Crow:"
	@if [ -f /usr/local/include/crow.h ] || [ -f /usr/include/crow.h ]; then \
		echo "✅ Crow encontrado"; \
	else \
		echo "❌ Crow no encontrado"; \
	fi

# Mostrar información del proyecto
info:
	@echo "=========================================="
	@echo "📋 INFORMACIÓN DEL PROYECTO"
	@echo "=========================================="
	@echo ""
	@echo "🔧 DESARROLLO:"
	@echo "   Compilador: $(CXX)"
	@echo "   Estándar: C++20"
	@echo "   Flags: $(CXXFLAGS_DEV)"
	@echo "   Ejecutable: $(TARGET)"
	@echo ""
	@echo "🚀 PRODUCCIÓN:"
	@echo "   Compilador: $(CXX)"
	@echo "   Estándar: C++20"
	@echo "   Flags: $(CXXFLAGS_PROD)"
	@echo "   Enlace: $(LDFLAGS_PROD)"
	@echo "   Ejecutable: $(TARGET_PROD)"
	@echo ""
	@echo "🐳 DOCKER:"
	@echo "   Imagen: $(DOCKER_FULL_IMAGE)"
	@echo "   Contenedor: $(DOCKER_CONTAINER_NAME)"
	@echo "   Registry: $(DOCKER_REGISTRY)"
	@echo ""
	@echo "📁 Archivos fuente: $(SOURCES)"
	@echo "=========================================="

# Mostrar ayuda
help:
	@echo "=========================================="
	@echo "🔧 COMANDOS DISPONIBLES"
	@echo "=========================================="
	@echo ""
	@echo "🏗️  Construcción (Desarrollo):"
	@echo "  make                    - Compilar para desarrollo (con debug)"
	@echo "  make run                - Compilar y ejecutar en modo desarrollo"
	@echo "  make debug              - Ejecutar con gdb"
	@echo "  make valgrind           - Verificar memoria"
	@echo ""
	@echo "🚀 Construcción (Producción):"
	@echo "  make production         - Compilar binario optimizado (RECOMENDADO)"
	@echo "  make run-production     - Ejecutar binario de producción localmente"
	@echo "  make analyze-production - Análisis completo del binario"
	@echo "  make compare            - Comparar dev vs prod"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  make docker-build       - Construir imagen Docker"
	@echo "  make docker-run         - Construir y ejecutar (foreground)"
	@echo "  make docker-run-bg      - Construir y ejecutar (background)"
	@echo "  make docker-logs        - Ver logs del contenedor"
	@echo "  make docker-stop        - Detener y eliminar contenedor"
	@echo "  make docker-test        - Test automático del contenedor"
	@echo "  make docker-inspect     - Inspeccionar imagen Docker"
	@echo "  make docker-shell       - Entrar al contenedor (debug)"
	@echo "  make docker-push        - Subir imagen a registry"
	@echo "  make docker-clean       - Limpiar imágenes Docker"
	@echo "  make docker-clean-all   - Limpiar contenedor e imágenes"
	@echo ""
	@echo "📦 Instalación:"
	@echo "  make install-dependencies - Instalar dependencias del sistema"
	@echo "  make install-crow-simple  - Instalar Crow header-only"
	@echo ""
	@echo "🧹 Limpieza:"
	@echo "  make clean              - Limpiar archivos de desarrollo"
	@echo "  make clean-production   - Limpiar archivos de producción"
	@echo "  make clean-all          - Limpiar todo"
	@echo ""
	@echo "🔍 Información:"
	@echo "  make check-system       - Verificar dependencias"
	@echo "  make info               - Mostrar configuración del proyecto"
	@echo "  make help               - Mostrar esta ayuda"
	@echo ""
	@echo "=========================================="
	@echo "💡 PERSONALIZAR NOMBRE DE IMAGEN:"
	@echo "=========================================="
	@echo "make docker-build DOCKER_IMAGE=mi-api DOCKER_TAG=v1.0"
	@echo "make docker-push DOCKER_REGISTRY=tu-usuario"
	@echo ""
	@echo "=========================================="
	@echo "💡 FLUJO RECOMENDADO PARA PRODUCCIÓN:"
	@echo "=========================================="
	@echo "1. make production          # Compilar optimizado"
	@echo "2. make analyze-production  # Verificar el binario"
	@echo "3. make docker-build        # Crear imagen Docker"
	@echo "4. make docker-test         # Probar contenedor"
	@echo "5. make docker-push         # Subir a registry (opcional)"
	@echo "=========================================="

.PHONY: all production analyze-production compare clean clean-production clean-all \
        run run-production run-bg stop test debug valgrind help info crow-check \
        install-dependencies install-crow-simple check-system build-dirs build-dirs-prod \
        docker-build docker-run docker-run-bg docker-logs docker-stop docker-test \
        docker-inspect docker-shell docker-push docker-clean docker-clean-all