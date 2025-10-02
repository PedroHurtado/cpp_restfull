# 🔌 Conectar DevContainer con Servicios en Host - Guía Completa

## 📋 Índice
1. [Escenario](#escenario)
2. [Solución 1: host.docker.internal](#solución-1-hostdockerinternal)
3. [Solución 2: Network Compartida](#solución-2-network-compartida-recomendada)
4. [Solución 3: Variables de Entorno](#solución-3-variables-de-entorno)
5. [Solución Híbrida (Recomendada)](#solución-híbrida-recomendada)
6. [Comparación de Soluciones](#comparación-de-soluciones)
7. [Troubleshooting](#troubleshooting)

---

## Escenario

Estás desarrollando un microservicio dentro de un **DevContainer** y necesitas conectarte a servicios (base de datos, redis, etc.) que corren en el **HOST** mediante `docker-compose`.

```
HOST (docker-compose):
  ├── PostgreSQL:5432
  ├── Redis:6379
  └── RabbitMQ:5672

DEVCONTAINER (desarrollo):
  └── crow-api (localhost:8080)
      └── Necesita conectar a PostgreSQL, Redis, etc.
```

**Pregunta clave:** ¿Cómo conectar desde el DevContainer a los servicios del host?

---

## Solución 1: host.docker.internal

### 📝 Descripción
Usar el hostname especial `host.docker.internal` que apunta al host desde dentro de un contenedor Docker.

### ✅ Ventajas
- Simple y directo
- No requiere configuración adicional de redes
- Funciona en Docker Desktop (Windows/Mac) out-of-the-box

### ❌ Desventajas
- Código menos portable (hardcodeado)
- No funciona igual en todos los entornos (Linux requiere flag extra)
- Diferente configuración entre dev y producción

---

### 📦 Implementación

#### **1. docker-compose.yml en el HOST**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: dev-postgres
    ports:
      - "5432:5432"  # ← IMPORTANTE: Exponer puerto al host
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: crow_db
      POSTGRES_USER: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    ports:
      - "6379:6379"  # ← IMPORTANTE: Exponer puerto al host
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

#### **2. .devcontainer/devcontainer.json**

```json
{
  "name": "Crow API DevContainer",
  "dockerFile": "Dockerfile",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "runArgs": [
    "--add-host=host.docker.internal:host-gateway"
  ],
  "forwardPorts": [8080],
  "postCreateCommand": "make setup"
}
```

**Nota para Linux:** El flag `--add-host=host.docker.internal:host-gateway` es necesario en Linux.

#### **3. Código C++ (src/main.cpp)**

```cpp
#include <crow.h>
#include <string>

// Configuración de conexión
const std::string DB_HOST = "host.docker.internal";  // ← Apunta al host
const int DB_PORT = 5432;
const std::string DB_NAME = "crow_db";
const std::string DB_USER = "postgres";
const std::string DB_PASSWORD = "dev_password";

int main() {
    crow::SimpleApp app;

    // Ejemplo de conexión a PostgreSQL
    std::string connection_string = 
        "host=" + DB_HOST + 
        " port=" + std::to_string(DB_PORT) +
        " dbname=" + DB_NAME +
        " user=" + DB_USER +
        " password=" + DB_PASSWORD;

    CROW_ROUTE(app, "/health")
    ([]() {
        return crow::response(200, "OK");
    });

    app.port(8080).multithreaded().run();
}
```

#### **4. Comandos para probar**

```bash
# En el HOST: Levantar servicios
cd monorepo/
docker-compose up -d

# Verificar que están corriendo
docker ps

# Abrir DevContainer en VS Code
code services/crow-api/

# Dentro del DevContainer: Compilar y ejecutar
make dev
./build/api

# Probar desde otro terminal
curl http://localhost:8080/health
```

---

## Solución 2: Network Compartida (RECOMENDADA)

### 📝 Descripción
Crear una red Docker compartida y conectar tanto el `docker-compose` como el DevContainer a la misma red.

### ✅ Ventajas
- **Misma configuración en dev y producción**
- Usa nombres de servicio en lugar de IPs
- Más profesional y escalable
- Aislamiento de red apropiado

### ❌ Desventajas
- Requiere crear la red explícitamente
- Configuración inicial ligeramente más compleja

---

### 📦 Implementación

#### **1. docker-compose.yml en el HOST**

```yaml
version: '3.8'

networks:
  microservices:
    name: microservices-network
    driver: bridge

services:
  postgres:
    image: postgres:16-alpine
    container_name: dev-postgres
    networks:
      - microservices  # ← Conectado a la red
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: crow_db
      POSTGRES_USER: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    networks:
      - microservices  # ← Conectado a la red
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: dev-rabbitmq
    networks:
      - microservices
    ports:
      - "5672:5672"
      - "15672:15672"  # Management UI
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin

volumes:
  postgres_data:
```

#### **2. .devcontainer/devcontainer.json**

```json
{
  "name": "Crow API DevContainer",
  "dockerFile": "Dockerfile",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "runArgs": [
    "--network=microservices-network"  // ← Conectar a la red del compose
  ],
  "forwardPorts": [8080],
  "postCreateCommand": "make setup"
}
```

#### **3. Código C++ (src/main.cpp)**

```cpp
#include <crow.h>
#include <string>

// Configuración usando NOMBRES DE SERVICIO
const std::string DB_HOST = "postgres";  // ← Nombre del servicio en docker-compose
const int DB_PORT = 5432;
const std::string DB_NAME = "crow_db";
const std::string DB_USER = "postgres";
const std::string DB_PASSWORD = "dev_password";

const std::string REDIS_HOST = "redis";  // ← Nombre del servicio
const int REDIS_PORT = 6379;

int main() {
    crow::SimpleApp app;

    std::string connection_string = 
        "host=" + DB_HOST + 
        " port=" + std::to_string(DB_PORT) +
        " dbname=" + DB_NAME +
        " user=" + DB_USER +
        " password=" + DB_PASSWORD;

    CROW_ROUTE(app, "/health")
    ([]() {
        return crow::response(200, "OK");
    });

    app.port(8080).multithreaded().run();
}
```

#### **4. Comandos para probar**

```bash
# En el HOST: Crear la red (si no existe)
docker network create microservices-network

# Levantar servicios
docker-compose up -d

# Verificar la red
docker network inspect microservices-network

# Abrir DevContainer (automáticamente se conecta a la red)
code services/crow-api/

# Dentro del DevContainer: Probar conexión
ping postgres
ping redis

# Compilar y ejecutar
make dev
./build/api
```

---

## Solución 3: Variables de Entorno

### 📝 Descripción
Usar variables de entorno para configurar las conexiones, permitiendo cambiar fácilmente entre desarrollo y producción.

### ✅ Ventajas
- **Máxima flexibilidad**
- Fácil cambiar configuración sin recompilar
- Siguiendo las [12-Factor App](https://12factor.net/) principles
- Preparado para múltiples entornos

### ❌ Desventajas
- Requiere gestión de configuración
- Más código para cargar variables

---

### 📦 Implementación

#### **1. Archivo config.env**

```bash
# config.env - Variables de entorno para desarrollo

# Database
DB_HOST=postgres
DB_PORT=5432
DB_NAME=crow_db
DB_USER=postgres
DB_PASSWORD=dev_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=admin

# API Configuration
API_PORT=8080
API_ENV=development
LOG_LEVEL=debug
```

#### **2. Clase Config en C++ (include/config.hpp)**

```cpp
#ifndef CONFIG_HPP
#define CONFIG_HPP

#include <string>
#include <cstdlib>
#include <stdexcept>
#include <fstream>
#include <sstream>
#include <map>

class Config {
private:
    static std::map<std::string, std::string> env_vars;
    static bool loaded;

    static void loadEnvFile(const std::string& filename = "config.env") {
        std::ifstream file(filename);
        if (!file.is_open()) {
            // Si no existe el archivo, usar variables de entorno del sistema
            return;
        }

        std::string line;
        while (std::getline(file, line)) {
            // Ignorar comentarios y líneas vacías
            if (line.empty() || line[0] == '#') continue;

            auto pos = line.find('=');
            if (pos != std::string::npos) {
                std::string key = line.substr(0, pos);
                std::string value = line.substr(pos + 1);
                env_vars[key] = value;
            }
        }
        loaded = true;
    }

public:
    static void load(const std::string& filename = "config.env") {
        if (!loaded) {
            loadEnvFile(filename);
        }
    }

    static std::string get(const std::string& key, const std::string& defaultValue = "") {
        if (!loaded) load();

        // Primero intentar del archivo cargado
        auto it = env_vars.find(key);
        if (it != env_vars.end()) {
            return it->second;
        }

        // Luego intentar de variables de entorno del sistema
        const char* val = std::getenv(key.c_str());
        if (val) {
            return std::string(val);
        }

        // Finalmente retornar el valor por defecto
        return defaultValue;
    }

    static int getInt(const std::string& key, int defaultValue = 0) {
        std::string val = get(key);
        if (val.empty()) return defaultValue;
        return std::stoi(val);
    }

    static bool getBool(const std::string& key, bool defaultValue = false) {
        std::string val = get(key);
        if (val.empty()) return defaultValue;
        return (val == "true" || val == "1" || val == "yes");
    }

    // Métodos de acceso específicos
    static std::string dbHost() { return get("DB_HOST", "localhost"); }
    static int dbPort() { return getInt("DB_PORT", 5432); }
    static std::string dbName() { return get("DB_NAME", "crow_db"); }
    static std::string dbUser() { return get("DB_USER", "postgres"); }
    static std::string dbPassword() { return get("DB_PASSWORD", ""); }

    static std::string redisHost() { return get("REDIS_HOST", "localhost"); }
    static int redisPort() { return getInt("REDIS_PORT", 6379); }

    static int apiPort() { return getInt("API_PORT", 8080); }
    static std::string apiEnv() { return get("API_ENV", "development"); }
    static std::string logLevel() { return get("LOG_LEVEL", "info"); }
};

// Inicialización de miembros estáticos
std::map<std::string, std::string> Config::env_vars;
bool Config::loaded = false;

#endif // CONFIG_HPP
```

#### **3. Código C++ usando Config (src/main.cpp)**

```cpp
#include <crow.h>
#include "config.hpp"
#include <iostream>

int main() {
    // Cargar configuración
    Config::load();

    crow::SimpleApp app;

    // Usar configuración desde variables de entorno
    std::string connection_string = 
        "host=" + Config::dbHost() + 
        " port=" + std::to_string(Config::dbPort()) +
        " dbname=" + Config::dbName() +
        " user=" + Config::dbUser() +
        " password=" + Config::dbPassword();

    std::cout << "Conectando a base de datos: " << Config::dbHost() 
              << ":" << Config::dbPort() << std::endl;

    CROW_ROUTE(app, "/health")
    ([]() {
        return crow::response(200, "OK");
    });

    CROW_ROUTE(app, "/config")
    ([]() {
        crow::json::wvalue response;
        response["environment"] = Config::apiEnv();
        response["database"]["host"] = Config::dbHost();
        response["database"]["port"] = Config::dbPort();
        response["redis"]["host"] = Config::redisHost();
        return response;
    });

    int port = Config::apiPort();
    std::cout << "Iniciando servidor en puerto " << port << std::endl;
    app.port(port).multithreaded().run();
}
```

#### **4. .devcontainer/devcontainer.json**

```json
{
  "name": "Crow API DevContainer",
  "dockerFile": "Dockerfile",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "runArgs": [
    "--network=microservices-network"
  ],
  "containerEnv": {
    "DB_HOST": "postgres",
    "DB_PORT": "5432",
    "DB_NAME": "crow_db",
    "DB_USER": "postgres",
    "DB_PASSWORD": "dev_password",
    "REDIS_HOST": "redis",
    "REDIS_PORT": "6379",
    "API_PORT": "8080",
    "API_ENV": "development",
    "LOG_LEVEL": "debug"
  },
  "forwardPorts": [8080],
  "postCreateCommand": "make setup"
}
```

#### **5. Makefile actualizado**

```makefile
# Variables
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -I./include
LDFLAGS = -lpthread -lssl -lcrypto

# Targets
.PHONY: dev run clean

dev:
	$(CXX) $(CXXFLAGS) src/main.cpp -o build/api $(LDFLAGS)

run: dev
	cp config.env build/ 2>/dev/null || true
	cd build && ./api

clean:
	rm -rf build/*
```

---

## Solución Híbrida (RECOMENDADA)

### 📝 Descripción
Combina **Network Compartida** + **Variables de Entorno** para obtener lo mejor de ambos mundos.

### ✅ Por qué es la mejor opción
- Red compartida para comunicación directa
- Variables de entorno para flexibilidad
- Fácil de cambiar entre entornos
- Preparada para producción

---

### 📦 Implementación Completa

#### **1. docker-compose.yml (HOST)**

```yaml
version: '3.8'

networks:
  microservices:
    name: microservices-network
    driver: bridge

services:
  postgres:
    image: postgres:16-alpine
    container_name: dev-postgres
    networks:
      - microservices
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: crow_db
      POSTGRES_USER: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    networks:
      - microservices
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: dev-rabbitmq
    networks:
      - microservices
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
```

#### **2. .devcontainer/devcontainer.json**

```json
{
  "name": "Crow API DevContainer",
  "dockerFile": "Dockerfile",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "runArgs": [
    "--network=microservices-network"
  ],
  "containerEnv": {
    "DB_HOST": "postgres",
    "DB_PORT": "5432",
    "DB_NAME": "crow_db",
    "DB_USER": "postgres",
    "DB_PASSWORD": "dev_password",
    "REDIS_HOST": "redis",
    "REDIS_PORT": "6379",
    "RABBITMQ_HOST": "rabbitmq",
    "RABBITMQ_PORT": "5672",
    "API_PORT": "8080",
    "API_ENV": "development",
    "LOG_LEVEL": "debug"
  },
  "forwardPorts": [8080],
  "postCreateCommand": "make setup",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools"
      ]
    }
  }
}
```

#### **3. Makefile con comandos de servicios**

```makefile
# Variables
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -I./include
LDFLAGS = -lpthread -lssl -lcrypto -lpq

# Directorios
BUILD_DIR = build
SRC_DIR = src
INCLUDE_DIR = include

# Archivos
SOURCES = $(wildcard $(SRC_DIR)/*.cpp)
TARGET = $(BUILD_DIR)/api

# Colors
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
NC = \033[0m # No Color

.PHONY: all dev production clean test \
        services-up services-down services-status services-logs \
        db-connect redis-connect setup help

all: dev

# ============================================
# COMPILACIÓN
# ============================================

dev:
	@echo "$(GREEN)Compilando en modo desarrollo...$(NC)"
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -g -O0 $(SOURCES) -o $(TARGET) $(LDFLAGS)
	@echo "$(GREEN)✓ Compilación completada$(NC)"

production:
	@echo "$(GREEN)Compilando en modo producción...$(NC)"
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -O3 -DNDEBUG $(SOURCES) -o $(TARGET) $(LDFLAGS)
	@strip $(TARGET)
	@echo "$(GREEN)✓ Compilación optimizada completada$(NC)"

# ============================================
# EJECUCIÓN
# ============================================

run: dev
	@echo "$(YELLOW)Iniciando servidor...$(NC)"
	@$(TARGET)

run-bg: dev
	@echo "$(YELLOW)Iniciando servidor en background...$(NC)"
	@$(TARGET) &

# ============================================
# GESTIÓN DE SERVICIOS (desde DevContainer)
# ============================================

services-up:
	@echo "$(GREEN)Levantando servicios en el host...$(NC)"
	@docker-compose -f ../../docker-compose.yml up -d
	@echo "$(GREEN)✓ Servicios iniciados$(NC)"
	@make services-status

services-down:
	@echo "$(YELLOW)Deteniendo servicios...$(NC)"
	@docker-compose -f ../../docker-compose.yml down
	@echo "$(GREEN)✓ Servicios detenidos$(NC)"

services-status:
	@echo "$(YELLOW)Estado de los servicios:$(NC)"
	@docker ps --filter "network=microservices-network" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

services-logs:
	@docker-compose -f ../../docker-compose.yml logs -f

# ============================================
# CONEXIÓN A SERVICIOS
# ============================================

db-connect:
	@echo "$(GREEN)Conectando a PostgreSQL...$(NC)"
	@docker exec -it dev-postgres psql -U postgres -d crow_db

redis-connect:
	@echo "$(GREEN)Conectando a Redis...$(NC)"
	@docker exec -it dev-redis redis-cli

# ============================================
# TESTING
# ============================================

test: dev
	@echo "$(YELLOW)Ejecutando tests...$(NC)"
	@./scripts/test.sh

test-connections:
	@echo "$(YELLOW)Probando conexiones a servicios...$(NC)"
	@ping -c 1 postgres > /dev/null 2>&1 && echo "$(GREEN)✓ PostgreSQL accesible$(NC)" || echo "$(RED)✗ PostgreSQL no accesible$(NC)"
	@ping -c 1 redis > /dev/null 2>&1 && echo "$(GREEN)✓ Redis accesible$(NC)" || echo "$(RED)✗ Redis no accesible$(NC)"
	@ping -c 1 rabbitmq > /dev/null 2>&1 && echo "$(GREEN)✓ RabbitMQ accesible$(NC)" || echo "$(RED)✗ RabbitMQ no accesible$(NC)"

# ============================================
# SETUP Y LIMPIEZA
# ============================================

setup:
	@echo "$(GREEN)Configurando entorno...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@make test-connections

clean:
	@echo "$(YELLOW)Limpiando archivos de compilación...$(NC)"
	@rm -rf $(BUILD_DIR)/*
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

# ============================================
# AYUDA
# ============================================

help:
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@echo ""
	@echo "  $(YELLOW)Compilación:$(NC)"
	@echo "    make dev              - Compilar en modo desarrollo"
	@echo "    make production       - Compilar optimizado"
	@echo "    make run              - Compilar y ejecutar"
	@echo ""
	@echo "  $(YELLOW)Servicios:$(NC)"
	@echo "    make services-up      - Levantar todos los servicios"
	@echo "    make services-down    - Detener todos los servicios"
	@echo "    make services-status  - Ver estado de servicios"
	@echo "    make services-logs    - Ver logs de servicios"
	@echo ""
	@echo "  $(YELLOW)Conexiones:$(NC)"
	@echo "    make db-connect       - Conectar a PostgreSQL"
	@echo "    make redis-connect    - Conectar a Redis"
	@echo "    make test-connections - Probar conexiones"
	@echo ""
	@echo "  $(YELLOW)Utilidades:$(NC)"
	@echo "    make test             - Ejecutar tests"
	@echo "    make clean            - Limpiar archivos"
	@echo "    make setup            - Configurar entorno"
```

#### **4. Flujo de trabajo completo**

```bash
# ========================================
# PASO 1: En el HOST - Levantar servicios
# ========================================
cd monorepo/
docker-compose up -d

# Verificar que están corriendo
docker ps

# ========================================
# PASO 2: Abrir DevContainer
# ========================================
code services/crow-api/

# ========================================
# PASO 3: Dentro del DevContainer
# ========================================

# Verificar conexiones
make test-connections

# Compilar y ejecutar
make run

# O ejecutar en background
make run-bg

# Ver logs de servicios del host
make services-logs

# Conectar a PostgreSQL para debug
make db-connect

# ========================================
# PASO 4: Desarrollo
# ========================================

# Hacer cambios en el código...
# Recompilar
make dev

# Ejecutar tests
make test

# ========================================
# PASO 5: Cleanup
# ========================================

# Detener servicios del host
make services-down

# O desde el host
docker-compose down
```

---

## Comparación de Soluciones

| Característica | host.docker.internal | Network Compartida | Variables de Entorno | Híbrida |
|----------------|---------------------|--------------------|--------------------|---------|
| **Simplicidad** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Portabilidad** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Flexibilidad** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Prod-Ready** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Rendimiento** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Config Mgmt** | ⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### Recomendación por Caso de Uso

- **Prototipo rápido**: Solución 1 (host.docker.internal)
- **Desarrollo en equipo**: Solución 2 (Network Compartida)
- **Producción**: Solución 3 (Variables de Entorno)
- **Mejor práctica**: **Solución Híbrida** ✅

---

## Troubleshooting

### Problema 1: No puedo conectarme a los servicios

```bash
# Verificar que los servicios están corriendo
docker ps

# Verificar la red
docker network inspect microservices-network

# Probar conectividad desde el devcontainer
ping postgres
ping redis

# Ver logs del servicio
docker logs dev-postgres
```

### Problema 2: host.docker.internal no funciona en Linux

```bash
# Agregar al devcontainer.json:
"runArgs": [
  "--add-host=host.docker.internal:host-gateway"
]
```

### Problema 3: DevContainer no se conecta a la red

```bash
# Crear la red manualmente primero
docker network create microservices-network

# Levantar servicios
docker-compose up -d

# Reconstruir devcontainer
# En VS Code: Cmd/Ctrl + Shift + P > "Rebuild Container"
```

### Problema 4: Puertos ya en uso

```bash
# Ver qué está usando el puerto
lsof -i :5432

# Detener el servicio que lo está usando
docker stop dev-postgres

# O cambiar el puerto en docker-compose.yml
ports:
  - "5433:5432"  # Puerto host:puerto contenedor
```

### Problema 5: Variables de entorno no se cargan

```bash
# Verificar que el archivo config.env existe
ls -la config.env

# Ver variables cargadas en el devcontainer
printenv | grep DB_

# Cargar manualmente desde el código
Config::load("config.env");
```

### Problema 6: Errores de DNS

```bash
# Verificar resolución DNS
nslookup postgres
dig postgres

# Reiniciar Docker Desktop
# O reiniciar el daemon de Docker en Linux
sudo systemctl restart docker
```

### Problema 7: Healthcheck falla

```bash
# Ver estado de healthcheck
docker inspect dev-postgres | grep -A 10 Health

# Ver logs completos
docker logs dev-postgres

# Ejecutar healthcheck manualmente
docker exec dev-postgres pg_isready -U postgres
```

---

## Scripts Útiles

### Script 1: wait-for-services.sh

```bash
#!/bin/bash
# scripts/wait-for-services.sh
# Espera a que todos los servicios estén listos

set -e

echo "Esperando a que los servicios estén listos..."

# Función para esperar por un servicio
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    
    echo -n "Esperando $service_name ($host:$port)... "
    
    timeout=60
    counter=0
    
    until nc -z $host $port 2>/dev/null; do
        sleep 1
        counter=$((counter + 1))
        
        if [ $counter -ge $timeout ]; then
            echo "❌ Timeout"
            return 1
        fi
    done
    
    echo "✅ Listo"
    return 0
}

# Esperar por PostgreSQL
wait_for_service postgres 5432 "PostgreSQL"

# Esperar por Redis
wait_for_service redis 6379 "Redis"

# Esperar por RabbitMQ
wait_for_service rabbitmq 5672 "RabbitMQ"

echo ""
echo "✅ Todos los servicios están listos!"
```

### Script 2: test-connections.sh

```bash
#!/bin/bash
# scripts/test-connections.sh
# Prueba las conexiones a todos los servicios

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Probando conexiones a servicios..."
echo ""

# Test PostgreSQL
echo -n "PostgreSQL: "
if docker exec dev-postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC}"
else
    echo -e "${RED}✗ No disponible${NC}"
fi

# Test Redis
echo -n "Redis: "
if docker exec dev-redis redis-cli ping | grep -q PONG; then
    echo -e "${GREEN}✓ Conectado${NC}"
else
    echo -e "${RED}✗ No disponible${NC}"
fi

# Test RabbitMQ
echo -n "RabbitMQ: "
if docker exec dev-rabbitmq rabbitmq-diagnostics ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC}"
else
    echo -e "${RED}✗ No disponible${NC}"
fi

echo ""
echo "Test de conectividad desde DevContainer:"

# Test desde dentro del container
echo -n "Ping a postgres: "
if ping -c 1 postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

echo -n "Ping a redis: "
if ping -c 1 redis > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

echo -n "Ping a rabbitmq: "
if ping -c 1 rabbitmq > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi
```

### Script 3: init-db.sql

```sql
-- scripts/init-db.sql
-- Script de inicialización de la base de datos

-- Crear extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Crear esquema
CREATE SCHEMA IF NOT EXISTS api;

-- Crear tabla de usuarios (ejemplo)
CREATE TABLE IF NOT EXISTS api.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_users_email ON api.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON api.users(username);

-- Insertar datos de prueba
INSERT INTO api.users (username, email, password_hash)
VALUES 
    ('admin', 'admin@example.com', crypt('admin123', gen_salt('bf'))),
    ('testuser', 'test@example.com', crypt('test123', gen_salt('bf')))
ON CONFLICT (username) DO NOTHING;

-- Grant permisos
GRANT USAGE ON SCHEMA api TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA api TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA api TO postgres;

-- Mensaje de confirmación
DO $
BEGIN
    RAISE NOTICE 'Base de datos inicializada correctamente';
END $;
```

---

## Ejemplos de Uso Avanzado

### Ejemplo 1: Conexión a PostgreSQL con libpq

```cpp
// src/database.hpp
#ifndef DATABASE_HPP
#define DATABASE_HPP

#include <libpq-fe.h>
#include <string>
#include <stdexcept>
#include <memory>
#include "config.hpp"

class Database {
private:
    PGconn* conn;
    
public:
    Database() : conn(nullptr) {
        connect();
    }
    
    ~Database() {
        if (conn) {
            PQfinish(conn);
        }
    }
    
    void connect() {
        std::string conninfo = 
            "host=" + Config::dbHost() + 
            " port=" + std::to_string(Config::dbPort()) +
            " dbname=" + Config::dbName() +
            " user=" + Config::dbUser() +
            " password=" + Config::dbPassword();
        
        conn = PQconnectdb(conninfo.c_str());
        
        if (PQstatus(conn) != CONNECTION_OK) {
            std::string error = PQerrorMessage(conn);
            PQfinish(conn);
            throw std::runtime_error("Error conectando a PostgreSQL: " + error);
        }
    }
    
    bool isConnected() {
        return conn && PQstatus(conn) == CONNECTION_OK;
    }
    
    PGresult* query(const std::string& sql) {
        PGresult* res = PQexec(conn, sql.c_str());
        
        if (PQresultStatus(res) != PGRES_TUPLES_OK && 
            PQresultStatus(res) != PGRES_COMMAND_OK) {
            std::string error = PQerrorMessage(conn);
            PQclear(res);
            throw std::runtime_error("Error en query: " + error);
        }
        
        return res;
    }
};

#endif // DATABASE_HPP
```

### Ejemplo 2: Conexión a Redis con hiredis

```cpp
// src/cache.hpp
#ifndef CACHE_HPP
#define CACHE_HPP

#include <hiredis/hiredis.h>
#include <string>
#include <stdexcept>
#include "config.hpp"

class Cache {
private:
    redisContext* context;
    
public:
    Cache() : context(nullptr) {
        connect();
    }
    
    ~Cache() {
        if (context) {
            redisFree(context);
        }
    }
    
    void connect() {
        struct timeval timeout = { 1, 500000 }; // 1.5 seconds
        
        context = redisConnectWithTimeout(
            Config::redisHost().c_str(), 
            Config::redisPort(), 
            timeout
        );
        
        if (context == NULL || context->err) {
            if (context) {
                std::string error = context->errstr;
                redisFree(context);
                throw std::runtime_error("Error conectando a Redis: " + error);
            } else {
                throw std::runtime_error("Error: No se pudo asignar contexto de Redis");
            }
        }
    }
    
    bool isConnected() {
        if (!context) return false;
        
        redisReply* reply = (redisReply*)redisCommand(context, "PING");
        if (!reply) return false;
        
        bool connected = (reply->type == REDIS_REPLY_STATUS && 
                         std::string(reply->str) == "PONG");
        freeReplyObject(reply);
        
        return connected;
    }
    
    void set(const std::string& key, const std::string& value) {
        redisReply* reply = (redisReply*)redisCommand(
            context, 
            "SET %s %s", 
            key.c_str(), 
            value.c_str()
        );
        
        if (!reply) {
            throw std::runtime_error("Error en SET: " + std::string(context->errstr));
        }
        
        freeReplyObject(reply);
    }
    
    std::string get(const std::string& key) {
        redisReply* reply = (redisReply*)redisCommand(
            context, 
            "GET %s", 
            key.c_str()
        );
        
        if (!reply) {
            throw std::runtime_error("Error en GET: " + std::string(context->errstr));
        }
        
        std::string value;
        if (reply->type == REDIS_REPLY_STRING) {
            value = reply->str;
        }
        
        freeReplyObject(reply);
        return value;
    }
};

#endif // CACHE_HPP
```

### Ejemplo 3: API con Crow usando ambos servicios

```cpp
// src/main.cpp
#include <crow.h>
#include "config.hpp"
#include "database.hpp"
#include "cache.hpp"
#include <iostream>
#include <memory>

int main() {
    // Cargar configuración
    Config::load();
    
    std::cout << "Iniciando Crow API..." << std::endl;
    std::cout << "Entorno: " << Config::apiEnv() << std::endl;
    
    // Inicializar servicios
    std::unique_ptr<Database> db;
    std::unique_ptr<Cache> cache;
    
    try {
        db = std::make_unique<Database>();
        std::cout << "✓ Conectado a PostgreSQL (" 
                  << Config::dbHost() << ":" << Config::dbPort() << ")" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "✗ Error conectando a PostgreSQL: " << e.what() << std::endl;
        return 1;
    }
    
    try {
        cache = std::make_unique<Cache>();
        std::cout << "✓ Conectado a Redis (" 
                  << Config::redisHost() << ":" << Config::redisPort() << ")" << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "✗ Error conectando a Redis: " << e.what() << std::endl;
        return 1;
    }
    
    crow::SimpleApp app;
    
    // Health check
    CROW_ROUTE(app, "/health")
    ([&db, &cache]() {
        crow::json::wvalue response;
        response["status"] = "ok";
        response["database"] = db->isConnected() ? "connected" : "disconnected";
        response["cache"] = cache->isConnected() ? "connected" : "disconnected";
        return response;
    });
    
    // Get user from cache or database
    CROW_ROUTE(app, "/users/<string>")
    ([&db, &cache](const std::string& username) {
        try {
            // Intentar obtener de cache primero
            std::string cached = cache->get("user:" + username);
            if (!cached.empty()) {
                crow::json::wvalue response;
                response["source"] = "cache";
                response["username"] = username;
                response["data"] = cached;
                return crow::response(200, response);
            }
            
            // Si no está en cache, consultar base de datos
            std::string query = "SELECT * FROM api.users WHERE username = '" + username + "'";
            PGresult* res = db->query(query);
            
            if (PQntuples(res) == 0) {
                PQclear(res);
                return crow::response(404, "User not found");
            }
            
            // Guardar en cache
            std::string userData = PQgetvalue(res, 0, 1); // email
            cache->set("user:" + username, userData);
            
            crow::json::wvalue response;
            response["source"] = "database";
            response["username"] = username;
            response["email"] = userData;
            
            PQclear(res);
            return crow::response(200, response);
            
        } catch (const std::exception& e) {
            crow::json::wvalue error;
            error["error"] = e.what();
            return crow::response(500, error);
        }
    });
    
    // Config endpoint
    CROW_ROUTE(app, "/config")
    ([]() {
        crow::json::wvalue response;
        response["environment"] = Config::apiEnv();
        response["database"]["host"] = Config::dbHost();
        response["database"]["port"] = Config::dbPort();
        response["database"]["name"] = Config::dbName();
        response["redis"]["host"] = Config::redisHost();
        response["redis"]["port"] = Config::redisPort();
        return response;
    });
    
    int port = Config::apiPort();
    std::cout << "\n✓ Servidor iniciado en puerto " << port << std::endl;
    std::cout << "Endpoints disponibles:" << std::endl;
    std::cout << "  - http://localhost:" << port << "/health" << std::endl;
    std::cout << "  - http://localhost:" << port << "/config" << std::endl;
    std::cout << "  - http://localhost:" << port << "/users/<username>" << std::endl;
    
    app.port(port).multithreaded().run();
}
```

---

## Checklist de Implementación

### ✅ Setup Inicial

- [ ] Crear `docker-compose.yml` con todos los servicios
- [ ] Crear red Docker `microservices-network`
- [ ] Configurar `.devcontainer/devcontainer.json` con red compartida
- [ ] Crear archivo `config.env` con variables de entorno
- [ ] Implementar clase `Config` en C++

### ✅ Servicios

- [ ] PostgreSQL configurado y funcionando
- [ ] Redis configurado y funcionando
- [ ] RabbitMQ configurado (si se usa)
- [ ] Script `init-db.sql` creado
- [ ] Healthchecks configurados en todos los servicios

### ✅ DevContainer

- [ ] Docker-in-Docker habilitado
- [ ] Red compartida configurada
- [ ] Variables de entorno definidas
- [ ] Scripts de setup ejecutándose correctamente

### ✅ Código

- [ ] Clase `Config` implementada y probada
- [ ] Conexión a PostgreSQL funcionando
- [ ] Conexión a Redis funcionando
- [ ] Endpoints de health check implementados
- [ ] Manejo de errores apropiado

### ✅ Scripts

- [ ] `wait-for-services.sh` creado y funcionando
- [ ] `test-connections.sh` creado y funcionando
- [ ] Makefile con comandos de servicios
- [ ] Scripts de cleanup

### ✅ Testing

- [ ] Tests de conexión a servicios
- [ ] Tests de endpoints
- [ ] Tests de healthcheck
- [ ] Verificación de variables de entorno

---

## Recursos Adicionales

### Documentación Oficial

- [Docker Networks](https://docs.docker.com/network/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Dev Containers](https://containers.dev/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)

### Bibliotecas C++

- [libpq](https://www.postgresql.org/docs/current/libpq.html) - Cliente PostgreSQL
- [hiredis](https://github.com/redis/hiredis) - Cliente Redis
- [Crow](https://crowcpp.org/) - Framework web

### Tutoriales

- [12-Factor App](https://12factor.net/) - Mejores prácticas
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)

---

## Conclusión

La **Solución Híbrida** (Network Compartida + Variables de Entorno) es la más recomendada porque:

1. ✅ **Separa completamente** el desarrollo (devcontainer) de la infraestructura (servicios)
2. ✅ **Permite probar** en un entorno similar a producción
3. ✅ **Facilita el trabajo en equipo** con configuración estandarizada
4. ✅ **Es escalable** para añadir más servicios
5. ✅ **Sigue las mejores prácticas** de la industria

### Flujo de Trabajo Recomendado

```
1. HOST: docker-compose up -d
   └─→ Levanta: PostgreSQL, Redis, RabbitMQ

2. DevContainer: code services/crow-api/
   └─→ Se conecta automáticamente a la red

3. DevContainer: make dev && make run
   └─→ Desarrolla y prueba conectándose a los servicios

4. DevContainer: make production && make docker-build
   └─→ Construye imagen optimizada

5. DevContainer: make docker-save
   └─→ Exporta imagen para producción

6. HOST: docker load && docker-compose up
   └─→ Despliega en entorno integrado
```

Este enfoque te permite **desarrollar rápido** sin comprometer la **calidad** ni la **escalabilidad** del proyecto.

---

