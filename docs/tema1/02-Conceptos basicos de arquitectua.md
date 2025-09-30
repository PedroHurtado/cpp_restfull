# Conceptos Básicos de Arquitectura Web y APIs

## ¿Qué es una Arquitectura Web?

La arquitectura web define cómo están organizados y se comunican los diferentes componentes de una aplicación web. Es el blueprint que determina la estructura, el comportamiento y las interacciones entre los elementos del sistema.

## Modelos Arquitectónicos Fundamentales

### Arquitectura Cliente-Servidor

```
┌─────────────┐                    ┌─────────────┐
│   Cliente   │ ◄─── Request ────► │  Servidor   │
│             │                    │             │
│ - UI/UX     │ ◄─── Response ───► │ - Lógica    │
│ - Validación│                    │ - Datos     │
│ - Presenta. │                    │ - Seguridad │
└─────────────┘                    └─────────────┘
```

**Características:**
- **Separación de responsabilidades**: Cliente maneja presentación, servidor maneja datos y lógica
- **Stateless**: Cada petición es independiente
- **Escalable**: Múltiples clientes pueden conectarse al mismo servidor

### Arquitectura de Tres Capas (3-Tier)

```
┌─────────────────┐
│ Capa de         │ ← Presentación (Frontend)
│ Presentación    │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ Capa de         │ ← Lógica de Negocio (Backend)
│ Aplicación      │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ Capa de         │ ← Gestión de Datos (Base de Datos)
│ Datos           │
└─────────────────┘
```

### Arquitectura de Microservicios

```
         ┌─────────────┐
         │   Gateway   │
         │    API      │
         └─────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│Servicio│ │Servicio│ │Servicio│
│Usuarios│ │Pedidos │ │Pagos   │
└────────┘ └────────┘ └────────┘
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│   BD   │ │   BD   │ │   BD   │
│Usuarios│ │Pedidos │ │Pagos   │
└────────┘ └────────┘ └────────┘
```

## ¿Qué es una API?

Una **API (Application Programming Interface)** es un conjunto de definiciones y protocolos que permite que diferentes software se comuniquen entre sí. Es el "contrato" que define cómo los componentes deben interactuar.

### Tipos de APIs

#### APIs Web (Web APIs)
APIs accesibles a través de HTTP/HTTPS desde internet:
- **REST APIs**: Utilizan HTTP y principios REST
- **GraphQL APIs**: Lenguaje de consulta flexible
- **gRPC**: Protocolo de comunicación de alto rendimiento

#### APIs de Biblioteca
Interfaces para usar funcionalidades de bibliotecas:
```cpp
// Ejemplo: API de una biblioteca matemática
#include <math_library.h>

double result = calculate_sqrt(25.0);  // API call
```

#### APIs del Sistema Operativo
Interfaces para acceder a servicios del OS:
```cpp
// Ejemplo: API POSIX para operaciones de archivo
#include <unistd.h>
#include <fcntl.h>

int fd = open("file.txt", O_RDONLY);  // System API call
```

## Principios de Diseño de APIs

### 1. Simplicidad y Usabilidad

**Nombres Intuitivos**
```
✅ Bueno:   GET /api/users
✅ Bueno:   POST /api/users
❌ Malo:    GET /api/getUserData
❌ Malo:    POST /api/createNewUserRecord
```

**Consistencia**
```
✅ Consistente:
GET    /api/users
POST   /api/users  
PUT    /api/users/123
DELETE /api/users/123

❌ Inconsistente:
GET    /api/users
CREATE /api/user
MODIFY /api/user/123
REMOVE /api/users/123
```

### 2. Stateless (Sin Estado)

Cada petición debe contener toda la información necesaria:

```cpp
// ✅ Stateless - toda la info en la petición
GET /api/users?page=2&limit=10&sort=name
Authorization: Bearer token123

// ❌ Stateful - depende de estado del servidor
GET /api/users/next  // ¿Cuál es "next"?
```

### 3. Cacheable

Las respuestas deben indicar si pueden ser cacheadas:

```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600
ETag: "abc123"
Content-Type: application/json

{"users": [...]}
```

### 4. Uniform Interface

Usar métodos HTTP estándar consistentemente:

```
GET    - Obtener recursos (idempotente)
POST   - Crear recursos
PUT    - Actualizar/reemplazar recursos (idempotente)
PATCH  - Actualizar parcialmente recursos
DELETE - Eliminar recursos (idempotente)
```

## Componentes de una Arquitectura Web Moderna

### 1. Load Balancer

```
Cliente ──► Load Balancer ──┬──► Servidor 1
                            ├──► Servidor 2
                            └──► Servidor 3
```

**Beneficios:**
- Distribución de carga
- Alta disponibilidad
- Failover automático

### 2. API Gateway

```
                    ┌─────────────────┐
                    │    Clientes     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  API Gateway    │
                    │  (Kong/Traefik) │
                    └────────┬────────┘
                             │
              ┏━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┓
              ▼                              ▼
    ┌─────────────────┐            ┌─────────────────┐
    │ Service Registry│            │  Load Balancer  │
    │   (Consul/Etcd) │◄───────────┤   (Integrado)   │
    └─────────────────┘            └─────────────────┘
              │                              │
              │ Descubrimiento               │ Balanceo
              │                              │
    ┌─────────┴──────────┐         ┌────────┴─────────┐
    ▼                    ▼         ▼                  ▼
┌───────┐            ┌───────┐  ┌───────┐        ┌───────┐
│ Svc A │            │ Svc A │  │ Svc B │        │ Svc B │
│ Inst1 │            │ Inst2 │  │ Inst1 │        │ Inst2 │
└───────┘            └───────┘  └───────┘        └───────┘
```

**Funcionalidades:**
- Enrutamiento de peticiones
- Autenticación y autorización
- Rate limiting
- Logging y monitoreo
- Transformación de datos

### 3. Cache Layer

```
Cliente ──► Cache ──┬──► Hit: Respuesta rápida
                    └──► Miss: ──► API ──► Base de Datos
```

**Tipos de Cache:**
- **Browser Cache**: En el cliente
- **CDN Cache**: Distribuido geográficamente
- **Application Cache**: Redis, Memcached
- **Database Cache**: Query caching

### 4. Message Queue

```
Productor ──► Queue ──► Consumidor
```

**Casos de Uso:**
- Procesamiento asíncrono
- Desacoplamiento de servicios
- Manejo de picos de carga

## Patrones Arquitectónicos Comunes

### 1. MVC (Model-View-Controller)

```
┌──────────┐    ┌──────────────┐    ┌─────────┐
│   View   │◄──►│ Controller   │◄──►│  Model  │
│(Frontend)│    │ (API Logic)  │    │ (Data)  │
└──────────┘    └──────────────┘    └─────────┘
```

### 2. Repository Pattern

```cpp
// Interfaz del repositorio
class IUserRepository {
public:
    virtual User findById(int id) = 0;
    virtual void save(const User& user) = 0;
    virtual void remove(int id) = 0;
};

// Implementación específica
class DatabaseUserRepository : public IUserRepository {
public:
    User findById(int id) override {
        // Lógica de base de datos
    }
    // ... otras implementaciones
};
```

### 3. Service Layer Pattern

```cpp
class UserService {
private:
    IUserRepository* repository;
    IEmailService* emailService;
    
public:
    void createUser(const UserData& data) {
        // Validación
        if (data.email.empty()) {
            throw ValidationException("Email required");
        }
        
        // Lógica de negocio
        User user = User::create(data);
        repository->save(user);
        emailService->sendWelcomeEmail(user);
    }
};
```

## Implementación Práctica en C++

### Servidor Web Básico con Pistache

```cpp
#include <pistache/http.h>
#include <pistache/router.h>
#include <pistache/endpoint.h>
#include <nlohmann/json.hpp>

using namespace Pistache;
using json = nlohmann::json;

class UserController {
public:
    void setupRoutes(Rest::Router& router) {
        // REST endpoints
        Rest::Routes::Get(router, "/api/users", 
                         Rest::Routes::bind(&UserController::getUsers, this));
        Rest::Routes::Get(router, "/api/users/:id", 
                         Rest::Routes::bind(&UserController::getUser, this));
        Rest::Routes::Post(router, "/api/users", 
                          Rest::Routes::bind(&UserController::createUser, this));
        Rest::Routes::Put(router, "/api/users/:id", 
                         Rest::Routes::bind(&UserController::updateUser, this));
        Rest::Routes::Delete(router, "/api/users/:id", 
                            Rest::Routes::bind(&UserController::deleteUser, this));
    }
    
private:
    void getUsers(const Rest::Request& req, Http::ResponseWriter response) {
        json users = json::array();
        
        // Aplicar filtros de query parameters
        auto limit = req.query().get("limit").value_or("10");
        auto offset = req.query().get("offset").value_or("0");
        
        // Lógica para obtener usuarios...
        for (const auto& user : userService.getUsers(std::stoi(limit), std::stoi(offset))) {
            users.push_back({
                {"id", user.id},
                {"name", user.name},
                {"email", user.email}
            });
        }
        
        response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
        response.send(Http::Code::Ok, users.dump());
    }
    
    void getUser(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        
        try {
            User user = userService.getUserById(id);
            json userJson = {
                {"id", user.id}, 
                {"name", user.name}, 
                {"email", user.email}
            };
            
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.headers().add<Http::Header::ETag>("\"" + std::to_string(user.version) + "\"");
            response.send(Http::Code::Ok, userJson.dump());
            
        } catch (const UserNotFoundException& e) {
            json error = {{"error", "User not found"}};
            response.send(Http::Code::Not_Found, error.dump());
        }
    }
    
    void createUser(const Rest::Request& req, Http::ResponseWriter response) {
        try {
            json userData = json::parse(req.body());
            
            // Validar datos de entrada
            if (!userData.contains("name") || !userData.contains("email")) {
                json error = {{"error", "Name and email are required"}};
                response.send(Http::Code::Bad_Request, error.dump());
                return;
            }
            
            // Crear usuario
            User newUser = userService.createUser(userData["name"], userData["email"]);
            
            json createdUser = {
                {"id", newUser.id},
                {"name", newUser.name},
                {"email", newUser.email}
            };
            
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.headers().add<Http::Header::Location>("/api/users/" + std::to_string(newUser.id));
            response.send(Http::Code::Created, createdUser.dump());
            
        } catch (const json::parse_error& e) {
            json error = {{"error", "Invalid JSON"}};
            response.send(Http::Code::Bad_Request, error.dump());
        } catch (const ValidationException& e) {
            json error = {{"error", e.what()}};
            response.send(Http::Code::Bad_Request, error.dump());
        }
    }
    
    void updateUser(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        
        try {
            json updateData = json::parse(req.body());
            User updatedUser = userService.updateUser(id, updateData);
            
            json result = {
                {"id", updatedUser.id},
                {"name", updatedUser.name},
                {"email", updatedUser.email}
            };
            
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.send(Http::Code::Ok, result.dump());
            
        } catch (const UserNotFoundException& e) {
            json error = {{"error", "User not found"}};
            response.send(Http::Code::Not_Found, error.dump());
        } catch (const json::parse_error& e) {
            json error = {{"error", "Invalid JSON"}};
            response.send(Http::Code::Bad_Request, error.dump());
        }
    }
    
    void deleteUser(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        
        try {
            userService.deleteUser(id);
            response.send(Http::Code::No_Content);
            
        } catch (const UserNotFoundException& e) {
            json error = {{"error", "User not found"}};
            response.send(Http::Code::Not_Found, error.dump());
        }
    }
    
private:
    UserService userService;
};

class WebServer {
public:
    WebServer(Address addr) : endpoint(std::make_shared<Http::Endpoint>(addr)) {
        auto opts = Http::Endpoint::options()
                      .threads(std::thread::hardware_concurrency())
                      .flags(Tcp::Options::InstallSignalHandler);
        endpoint->init(opts);
        
        setupRoutes();
    }
    
    void start() {
        endpoint->setHandler(router.handler());
        endpoint->serve();
    }
    
private:
    void setupRoutes() {
        userController.setupRoutes(router);
        
        // Middleware para CORS
        router.addCustomHandler(Http::Method::Options, "/*", 
            [](const Rest::Request&, Http::ResponseWriter response) {
                response.headers().add<Http::Header::AccessControlAllowOrigin>("*");
                response.headers().add<Http::Header::AccessControlAllowMethods>("GET, POST, PUT, DELETE, OPTIONS");
                response.headers().add<Http::Header::AccessControlAllowHeaders>("Content-Type, Authorization");
                response.send(Http::Code::Ok);
            });
    }
    
    std::shared_ptr<Http::Endpoint> endpoint;
    Rest::Router router;
    UserController userController;
};
```

## Consideraciones de Seguridad

### Autenticación vs Autorización

**Autenticación**: ¿Quién eres?
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Autorización**: ¿Qué puedes hacer?
```cpp
class AuthorizationMiddleware {
public:
    static bool checkPermission(const User& user, const std::string& resource, const std::string& action) {
        // Verificar roles y permisos
        if (user.hasRole("admin")) {
            return true; // Admin puede hacer todo
        }
        
        if (resource == "users" && action == "read") {
            return user.hasPermission("users.read");
        }
        
        if (resource == "users" && action == "write") {
            return user.hasPermission("users.write");
        }
        
        return false;
    }
};
```

### HTTPS Obligatorio

```cpp
// Configuración del servidor para forzar HTTPS
class SecureServer {
public:
    SecureServer() {
        server.set_mount_point("/", "./public");
        server.set_ssl_cert_and_key("cert.pem", "key.pem");
        
        // Redirección HTTP -> HTTPS
        server.Get(".*", [](const httplib::Request& req, httplib::Response& res) {
            std::string https_url = "https://" + req.get_header_value("Host") + req.path;
            res.set_redirect(https_url, 301);
        });
    }
};
```

### Validación de Entrada

```cpp
class InputValidator {
public:
    static bool validateEmail(const std::string& email) {
        std::regex pattern(R"(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b)");
        return std::regex_match(email, pattern);
    }
    
    static bool validateUserInput(const json& userData) {
        // Verificar campos requeridos
        if (!userData.contains("name") || !userData.contains("email")) {
            return false;
        }
        
        // Validar tipos
        if (!userData["name"].is_string() || !userData["email"].is_string()) {
            return false;
        }
        
        // Validar formato de email
        if (!validateEmail(userData["email"])) {
            return false;
        }
        
        // Validar longitud de nombre
        std::string name = userData["name"];
        if (name.length() < 2 || name.length() > 100) {
            return false;
        }
        
        return true;
    }
};
```

## Versionado de APIs

### Estrategias de Versionado

**1. URL Versioning**
```
https://api.example.com/v1/users
https://api.example.com/v2/users
```

**2. Header Versioning**
```http
GET /api/users
API-Version: v2
```

**3. Query Parameter Versioning**
```
https://api.example.com/users?version=2
```

### Implementación de Versionado

```cpp
class VersionedAPI {
public:
    void setupVersionedRoutes(Rest::Router& router) {
        // V1 routes
        Rest::Routes::Get(router, "/api/v1/users/:id", 
                         Rest::Routes::bind(&VersionedAPI::getUserV1, this));
        
        // V2 routes
        Rest::Routes::Get(router, "/api/v2/users/:id", 
                         Rest::Routes::bind(&VersionedAPI::getUserV2, this));
        
        // Header-based versioning
        Rest::Routes::Get(router, "/api/users/:id", 
                         Rest::Routes::bind(&VersionedAPI::getUserVersioned, this));
    }
    
private:
    void getUserV1(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        User user = userService.getUserById(id);
        
        // Formato legacy V1
        json result = {
            {"id", user.id}, 
            {"name", user.name}
        };
        
        response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
        response.send(Http::Code::Ok, result.dump());
    }
    
    void getUserV2(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        User user = userService.getUserById(id);
        
        // Formato nuevo V2 con más campos
        json result = {
            {"id", user.id}, 
            {"name", user.name},
            {"email", user.email},
            {"created_at", user.createdAt},
            {"profile", {
                {"avatar_url", user.avatarUrl},
                {"bio", user.bio}
            }}
        };
        
        response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
        response.send(Http::Code::Ok, result.dump());
    }
    
    void getUserVersioned(const Rest::Request& req, Http::ResponseWriter response) {
        std::string version = req.headers().get<Http::Header::Authorization>().value_or("v1");
        
        if (version == "v1") {
            getUserV1(req, std::move(response));
        } else if (version == "v2") {
            getUserV2(req, std::move(response));
        } else {
            json error = {{"error", "Unsupported API version"}};
            response.send(Http::Code::Bad_Request, error.dump());
        }
    }
    
    UserService userService;
};
```

## Métricas y Monitoreo

### Métricas Clave

**Latencia**
- Tiempo de respuesta promedio
- Percentiles (P95, P99)

**Throughput**
- Peticiones por segundo
- Datos transferidos

**Disponibilidad**
- Uptime porcentual
- Error rate

**Errores**
- 4xx (errores del cliente)
- 5xx (errores del servidor)

### Implementación de Métricas

```cpp
class MetricsCollector {
private:
    std::atomic<long> request_count{0};
    std::atomic<long> error_count{0};
    std::atomic<long> total_response_time{0};
    std::mutex histogram_mutex;
    std::map<int, long> status_code_counts;
    
public:
    void recordRequest(int statusCode, long responseTimeMs) {
        request_count++;
        total_response_time += responseTimeMs;
        
        std::lock_guard<std::mutex> lock(histogram_mutex);
        status_code_counts[statusCode]++;
        
        if (statusCode >= 400) {
            error_count++;
        }
    }
    
    json getMetrics() {
        std::lock_guard<std::mutex> lock(histogram_mutex);
        
        return {
            {"total_requests", request_count.load()},
            {"error_count", error_count.load()},
            {"error_rate", getErrorRate()},
            {"average_response_time", getAverageResponseTime()},
            {"status_codes", status_code_counts}
        };
    }
    
private:
    double getErrorRate() {
        long total = request_count.load();
        return total > 0 ? static_cast<double>(error_count.load()) / total : 0.0;
    }
    
    double getAverageResponseTime() {
        long total = request_count.load();
        return total > 0 ? static_cast<double>(total_response_time.load()) / total : 0.0;
    }
};

// Middleware para métricas
class MetricsMiddleware {
public:
    static void wrapHandler(Rest::Route::Handler originalHandler, MetricsCollector& metrics) {
        return [originalHandler, &metrics](const Rest::Request& req, Http::ResponseWriter response) {
            auto start = std::chrono::high_resolution_clock::now();
            
            // Llamar al handler original
            originalHandler(req, std::move(response));
            
            auto end = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
            
            // Registrar métricas
            metrics.recordRequest(200, duration); // Simplificado
        };
    }
};
```

## Documentación de APIs

### OpenAPI/Swagger

```cpp
class APIDocumentation {
public:
    static json generateOpenAPISpec() {
        return {
            {"openapi", "3.0.0"},
            {"info", {
                {"title", "Users API"},
                {"version", "1.0.0"},
                {"description", "API para gestión de usuarios"}
            }},
            {"paths", {
                {"/users", {
                    {"get", {
                        {"summary", "Obtener todos los usuarios"},
                        {"parameters", {
                            {
                                {"name", "limit"},
                                {"in", "query"},
                                {"schema", {{"type", "integer"}}},
                                {"description", "Número máximo de usuarios a retornar"}
                            }
                        }},
                        {"responses", {
                            {"200", {
                                {"description", "Lista de usuarios"},
                                {"content", {
                                    {"application/json", {
                                        {"schema", {
                                            {"type", "array"},
                                            {"items", {{"$ref", "#/components/schemas/User"}}}
                                        }}
                                    }}
                                }}
                            }}
                        }}
                    }}
                }}
            }},
            {"components", {
                {"schemas", {
                    {"User", {
                        {"type", "object"},
                        {"properties", {
                            {"id", {{"type", "integer"}}},
                            {"name", {{"type", "string"}}},
                            {"email", {{"type", "string"}}}
                        }},
                        {"required", {"id", "name", "email"}}
                    }}
                }}
            }}
        };
    }
};
```

Esta base conceptual de arquitectura web y APIs es fundamental para entender cómo diseñar y implementar servicios web efectivos en C++. Proporciona los fundamentos necesarios para los siguientes temas sobre protocolos específicos y estilos arquitectónicos como REST y SOAP.