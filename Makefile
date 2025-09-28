# Makefile para proyectos C++ con Crow
CXX = g++
CXXFLAGS = -std=c++20 -Wall -Wextra -g -O0 -DCROW_MAIN
LDFLAGS = -lpthread

# Directorios
SRCDIR = src
INCDIR = include
BUILDDIR = build
BINDIR = build

# Archivos fuente
SOURCES = $(wildcard $(SRCDIR)/*.cpp)
OBJECTS = $(SOURCES:$(SRCDIR)/%.cpp=$(BUILDDIR)/%.o)
TARGET = $(BINDIR)/main

# Regla principal
all: crow-check $(TARGET)

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
		sudo apt-get install -y build-essential cmake git libboost-all-dev libasio-dev curl wget; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema basado en RedHat/CentOS"; \
		sudo yum groupinstall -y "Development Tools"; \
		sudo yum install -y cmake git boost-devel asio-devel curl wget; \
	elif command -v dnf >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Fedora"; \
		sudo dnf groupinstall -y "Development Tools"; \
		sudo dnf install -y cmake git boost-devel asio-devel curl wget; \
	elif command -v pacman >/dev/null 2>&1; then \
		echo "🔧 Detectado sistema Arch Linux"; \
		sudo pacman -S --noconfirm base-devel cmake git boost asio curl wget; \
	else \
		echo "❌ Sistema no soportado automáticamente. Instala manualmente:"; \
		echo "   - build-essential o equivalent"; \
		echo "   - cmake (>= 3.10)"; \
		echo "   - git"; \
		echo "   - libboost-dev (>= 1.64)"; \
		echo "   - libasio-dev"; \
		echo "   - curl, wget"; \
		exit 1; \
	fi
	@echo "✅ Dependencias instaladas correctamente"

# Instalar Crow simple (header-only) - MÉTODO PRINCIPAL
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

# Instalar Crow compilado (método alternativo si el simple falla)
install-crow:
	@echo "📦 Instalando Crow compilado..."
	@temp_dir=$$(mktemp -d); \
	echo "📁 Directorio temporal: $$temp_dir"; \
	cd "$$temp_dir"; \
	echo "📥 Clonando repositorio de Crow..."; \
	rm -rf Crow; \
	git clone --depth 1 --branch v1.2.0 https://github.com/CrowCpp/Crow.git; \
	cd Crow; \
	echo "🔧 Configurando build con CMake..."; \
	mkdir -p build; \
	cd build; \
	if cmake .. \
		-DCROW_BUILD_EXAMPLES=OFF \
		-DCROW_BUILD_TESTS=OFF \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DCROW_ENABLE_SSL=OFF \
		-DCROW_ENABLE_COMPRESSION=OFF; then \
		echo "✅ Configuración de CMake exitosa"; \
		echo "🔨 Compilando Crow..."; \
		if make -j$$(nproc) 2>/dev/null || make -j1; then \
			echo "✅ Compilación exitosa"; \
			echo "📦 Instalando en el sistema..."; \
			if sudo make install; then \
				sudo ldconfig 2>/dev/null || true; \
				echo "✅ Crow instalado correctamente en el sistema"; \
			else \
				echo "❌ Error en la instalación de Crow"; \
				exit 1; \
			fi; \
		else \
			echo "❌ Error en la compilación de Crow"; \
			echo "🔄 Intentando instalación header-only como alternativa..."; \
			$(MAKE) install-crow-simple; \
		fi; \
	else \
		echo "❌ Error en la configuración de CMake para Crow"; \
		echo "🔄 Intentando instalación header-only como alternativa..."; \
		$(MAKE) install-crow-simple; \
	fi; \
	cd /; \
	rm -rf "$$temp_dir"

# Crear el ejecutable
$(TARGET): $(OBJECTS) | build-dirs
	@echo "🔗 Enlazando ejecutable..."
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)
	@echo "✅ Compilación completada: $(TARGET)"

# Compilar archivos objeto
$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp | build-dirs
	@echo "🔨 Compilando $<..."
	$(CXX) $(CXXFLAGS) -I$(INCDIR) -c $< -o $@

# Crear directorios si no existen - target único
build-dirs:
	@mkdir -p $(BUILDDIR)

# Limpiar archivos generados
clean:
	@echo "🧹 Limpiando archivos generados..."
	rm -rf $(BUILDDIR)
	@echo "✅ Limpieza completada"

# Limpiar completamente (incluyendo Crow instalado)
clean-all: clean
	@echo "🧹 Limpieza completa del sistema..."
	@echo "⚠️  Esto removerá Crow del sistema. ¿Continuar? [y/N]"
	@read -p "" confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		sudo rm -f /usr/local/include/crow.h /usr/local/include/crow/* 2>/dev/null || true; \
		sudo rm -f /usr/local/lib/libcrow* 2>/dev/null || true; \
		sudo rm -f /usr/local/lib/pkgconfig/crow.pc 2>/dev/null || true; \
		sudo ldconfig 2>/dev/null || true; \
		echo "✅ Limpieza completa realizada"; \
	else \
		echo "❌ Limpieza completa cancelada"; \
	fi

# Ejecutar el programa
run: $(TARGET)
	@echo "🚀 Ejecutando servidor..."
	@echo "📡 Disponible en: http://localhost:8080"
	@echo "⏹️  Presiona Ctrl+C para detener"
	./$(TARGET)

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
	@echo "📋 CMake:"
	@cmake --version | head -1 || echo "❌ cmake no encontrado"
	@echo "📋 Boost:"
	@if pkg-config --exists boost 2>/dev/null; then \
		echo "✅ Boost encontrado (pkg-config): $$(pkg-config --modversion boost)"; \
	elif [ -f /usr/include/boost/version.hpp ] || [ -f /usr/local/include/boost/version.hpp ]; then \
		if [ -f /usr/include/boost/version.hpp ]; then \
			boost_version=$$(grep -E '#define BOOST_VERSION [0-9]+' /usr/include/boost/version.hpp | head -1 | awk '{print $$3}' 2>/dev/null || echo "0"); \
		else \
			boost_version=$$(grep -E '#define BOOST_VERSION [0-9]+' /usr/local/include/boost/version.hpp | head -1 | awk '{print $$3}' 2>/dev/null || echo "0"); \
		fi; \
		if [ "$$boost_version" != "0" ] && [ "$$boost_version" -gt 0 ] 2>/dev/null; then \
			major=$$((boost_version / 100000)); \
			minor=$$((boost_version / 100 % 1000)); \
			patch=$$((boost_version % 100)); \
			echo "✅ Boost encontrado (headers): $$major.$$minor.$$patch"; \
			if [ $$boost_version -ge 106400 ]; then \
				echo "✅ Versión de Boost suficiente (>= 1.64)"; \
			else \
				echo "❌ Versión de Boost insuficiente (< 1.64)"; \
			fi; \
		else \
			echo "✅ Boost encontrado (headers disponibles - versión no detectada)"; \
		fi; \
	elif dpkg -l 2>/dev/null | grep -q libboost-dev; then \
		boost_pkg_version=$$(dpkg -l 2>/dev/null | grep libboost-dev | awk '{print $$3}' | head -1); \
		echo "✅ Boost encontrado (dpkg): $$boost_pkg_version"; \
	else \
		echo "❌ Boost no encontrado"; \
		echo "💡 Ejecuta: make install-dependencies"; \
	fi
	@echo "📋 ASIO:"
	@if [ -f /usr/include/asio.hpp ] || [ -f /usr/local/include/asio.hpp ]; then \
		echo "✅ ASIO encontrado (headers disponibles)"; \
	elif dpkg -l | grep -q libasio-dev 2>/dev/null; then \
		echo "✅ ASIO encontrado (dpkg)"; \
	else \
		echo "❌ ASIO no encontrado"; \
		echo "💡 Ejecuta: make install-dependencies"; \
	fi
	@echo "📋 Crow:"
	@if pkg-config --exists crow 2>/dev/null; then \
		echo "✅ Crow encontrado (pkg-config): $$(pkg-config --modversion crow)"; \
	elif [ -f /usr/local/include/crow.h ] || [ -f /usr/include/crow.h ]; then \
		echo "✅ Crow encontrado (headers disponibles)"; \
	else \
		echo "❌ Crow no encontrado"; \
		echo "💡 Ejecuta: make install-crow-simple"; \
	fi

# Reinstalar Crow completamente
reinstall-crow: clean-all install-dependencies install-crow-simple
	@echo "✅ Crow reinstalado completamente"

# Mostrar información del proyecto
info:
	@echo "📋 Información del proyecto:"
	@echo "   Compilador: $(CXX)"
	@echo "   Estándar: C++20"
	@echo "   Flags: $(CXXFLAGS)"
	@echo "   Librerías: $(LDFLAGS)"
	@echo "   Archivos fuente: $(SOURCES)"
	@echo "   Ejecutable: $(TARGET)"

# Mostrar ayuda
help:
	@echo "🔧 Comandos disponibles:"
	@echo ""
	@echo "🏗️  Construcción:"
	@echo "  make                    - Compilar el proyecto"
	@echo "  make install-dependencies - Instalar dependencias del sistema"
	@echo "  make install-crow-simple - Instalar Crow header-only (recomendado)"
	@echo "  make install-crow       - Instalar Crow compilado (alternativo)"
	@echo "  make reinstall-crow     - Reinstalar Crow completamente"
	@echo ""
	@echo "🚀 Ejecución:"
	@echo "  make run               - Compilar y ejecutar servidor"
	@echo "  make run-bg            - Ejecutar servidor en segundo plano"
	@echo "  make stop              - Detener servidor en segundo plano"
	@echo "  make test              - Probar que el servidor funciona"
	@echo ""
	@echo "🔍 Debug y análisis:"
	@echo "  make debug             - Ejecutar con gdb"
	@echo "  make valgrind          - Verificar memoria con valgrind"
	@echo "  make check-system      - Verificar dependencias del sistema"
	@echo ""
	@echo "🧹 Limpieza:"
	@echo "  make clean             - Limpiar archivos generados"
	@echo "  make clean-all         - Limpieza completa (incluye Crow)"
	@echo ""
	@echo "ℹ️  Información:"
	@echo "  make info              - Mostrar información del proyecto"
	@echo "  make help              - Mostrar esta ayuda"

.PHONY: all clean clean-all run run-bg stop test debug valgrind help info crow-check install-dependencies install-crow install-crow-simple reinstall-crow check-system build-dirs