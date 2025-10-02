# Makefile para proyectos C++ con Crow
CXX = g++

# Flags para DESARROLLO
CXXFLAGS_DEV = -std=c++20 -Wall -Wextra -g -O0 -DCROW_MAIN
# Flags para PRODUCCIÓN
CXXFLAGS_PROD = -std=c++20 -O3 -march=native -DNDEBUG -DCROW_MAIN
# Flags de enlace
LDFLAGS = -lpthread
# Flags de enlace estático para producción
LDFLAGS_STATIC = -lpthread -static-libgcc -static-libstdc++

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

# Regla principal (desarrollo)
all: crow-check $(TARGET)

# ============================================
# TARGETS DE PRODUCCIÓN
# ============================================

# Compilar para producción (target principal)
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
	@echo "🚀 Listo para desplegar: $(TARGET_PROD)"

# Compilar y hacer strip del binario
production-strip: production
	@echo "✂️  Eliminando símbolos de debug..."
	strip $(TARGET_PROD)
	@echo "✅ Strip completado!"
	@echo "📊 Tamaño final:"
	@ls -lh $(TARGET_PROD)

# Crear ejecutable de producción
$(TARGET_PROD): $(OBJECTS_PROD) | build-dirs-prod
	@echo "🔗 Enlazando ejecutable de producción..."
	$(CXX) $(OBJECTS_PROD) -o $@ $(LDFLAGS_STATIC)
	@echo "✅ Compilación de producción completada"

# Compilar archivos objeto para producción
$(BUILDDIR_PROD)/%.o: $(SRCDIR)/%.cpp | build-dirs-prod
	@echo "🔨 Compilando para producción: $<..."
	$(CXX) $(CXXFLAGS_PROD) -I$(INCDIR) -c $< -o $@

# Crear directorios de producción
build-dirs-prod:
	@mkdir -p $(BUILDDIR_PROD)

# Análisis del binario de producción
analyze-production: $(TARGET_PROD)
	@echo "📊 Análisis del binario de producción:"
	@echo ""
	@echo "📁 Tamaño del archivo:"
	@ls -lh $(TARGET_PROD)
	@du -h $(TARGET_PROD)
	@echo ""
	@echo "🔍 Tipo de archivo:"
	@file $(TARGET_PROD)
	@echo ""
	@echo "📚 Dependencias dinámicas:"
	@ldd $(TARGET_PROD) 2>/dev/null || echo "Binario estático"
	@echo ""
	@echo "🔧 Información del binario:"
	@readelf -h $(TARGET_PROD) 2>/dev/null | grep -E "(Class|Machine|Type)" || true
	@echo ""
	@echo "📦 Secciones del binario:"
	@size $(TARGET_PROD)

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
		sudo apt-get install -y build-essential cmake git libboost-all-dev libasio-dev curl wget binutils; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema basado en RedHat/CentOS"; \
		sudo yum groupinstall -y "Development Tools"; \
		sudo yum install -y cmake git boost-devel asio-devel curl wget binutils; \
	elif command -v dnf >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Fedora"; \
		sudo dnf groupinstall -y "Development Tools"; \
		sudo dnf install -y cmake git boost-devel asio-devel curl wget binutils; \
	elif command -v pacman >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Arch Linux"; \
		sudo pacman -S --noconfirm base-devel cmake git boost asio curl wget binutils; \
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
	@mkdir -p $(BUILDDIR)

# Limpiar archivos generados
clean:
	@echo "🧹 Limpiando archivos generados..."
	rm -rf $(BUILDDIR)
	@echo "✅ Limpieza completada"

# Limpiar solo producción
clean-production:
	@echo "🧹 Limpiando archivos de producción..."
	rm -rf $(BUILDDIR_PROD) $(TARGET_PROD)
	@echo "✅ Limpieza de producción completada"

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
	@curl -s http://localhost:8080/ || echo "❌ Error al conectar"
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
	@echo "📋 Herramientas de binarios:"
	@strip --version | head -1 2>/dev/null || echo "⚠️  strip no encontrado"
	@echo "📋 Crow:"
	@if [ -f /usr/local/include/crow.h ] || [ -f /usr/include/crow.h ]; then \
		echo "✅ Crow encontrado"; \
	else \
		echo "❌ Crow no encontrado"; \
	fi

# Mostrar información del proyecto
info:
	@echo "📋 Información del proyecto:"
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
	@echo "   Enlace: $(LDFLAGS_STATIC)"
	@echo "   Ejecutable: $(TARGET_PROD)"
	@echo ""
	@echo "📁 Archivos fuente: $(SOURCES)"

# Mostrar ayuda
help:
	@echo "🔧 Comandos disponibles:"
	@echo ""
	@echo "🏗️  Construcción (Desarrollo):"
	@echo "  make                    - Compilar para desarrollo (con debug)"
	@echo "  make run                - Compilar y ejecutar en modo desarrollo"
	@echo "  make debug              - Ejecutar con gdb"
	@echo "  make valgrind           - Verificar memoria"
	@echo ""
	@echo "🚀 Construcción (Producción):"
	@echo "  make production         - Compilar binario optimizado para producción"
	@echo "  make production-strip   - Compilar y hacer strip del binario"
	@echo "  make run-production     - Ejecutar binario de producción localmente"
	@echo "  make analyze-production - Analizar el binario de producción"
	@echo ""
	@echo "📦 Instalación:"
	@echo "  make install-dependencies - Instalar dependencias del sistema"
	@echo "  make install-crow-simple  - Instalar Crow header-only"
	@echo ""
	@echo "🧹 Limpieza:"
	@echo "  make clean              - Limpiar archivos de desarrollo"
	@echo "  make clean-production   - Limpiar archivos de producción"
	@echo ""
	@echo "🔍 Información:"
	@echo "  make check-system       - Verificar dependencias"
	@echo "  make info               - Mostrar configuración del proyecto"
	@echo "  make help               - Mostrar esta ayuda"
	@echo ""
	@echo "💡 Flujo recomendado para producción:"
	@echo "   1. make production-strip    # Compilar y optimizar"
	@echo "   2. make analyze-production  # Verificar el binario"
	@echo "   3. Copiar build/api al contenedor Docker"

.PHONY: all production production-strip analyze-production clean clean-production \
        run run-production run-bg stop test debug valgrind help info crow-check \
        install-dependencies install-crow-simple check-system build-dirs build-dirs-prod