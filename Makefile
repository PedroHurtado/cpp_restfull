# Makefile para proyectos C++
CXX = g++
CXXFLAGS = -std=c++20 -Wall -Wextra -g -O0
LDFLAGS = 

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
all: $(TARGET)

# Crear el ejecutable
$(TARGET): $(OBJECTS) | $(BINDIR)
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)

# Compilar archivos objeto
$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp | $(BUILDDIR)
	$(CXX) $(CXXFLAGS) -I$(INCDIR) -c $< -o $@

# Crear directorios si no existen
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BINDIR):
	mkdir -p $(BINDIR)

# Limpiar archivos generados
clean:
	rm -rf $(BUILDDIR)

# Ejecutar el programa
run: $(TARGET)
	./$(TARGET)

# Debug con gdb
debug: $(TARGET)
	gdb ./$(TARGET)

# Verificar memoria con valgrind
valgrind: $(TARGET)
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./$(TARGET)

# Mostrar ayuda
help:
	@echo "Comandos disponibles:"
	@echo "  make        - Compilar el proyecto"
	@echo "  make run    - Compilar y ejecutar"
	@echo "  make debug  - Ejecutar con gdb"
	@echo "  make valgrind - Verificar memoria con valgrind"
	@echo "  make clean  - Limpiar archivos generados"

.PHONY: all clean run debug valgrind help