# Diferencias entre REST y SOAP

## Introducción

REST (Representational State Transfer) y SOAP (Simple Object Access Protocol) son dos paradigmas diferentes para el diseño de servicios web. Aunque ambos permiten la comunicación entre sistemas distribuidos, tienen enfoques, filosofías y características muy distintas.

## SOAP (Simple Object Access Protocol)

### ¿Qué es SOAP?

SOAP es un **protocolo** de comunicación basado en XML que define un formato estándar para intercambiar información estructurada en entornos distribuidos. Es un estándar del W3C que proporciona un marco completo para servicios web empresariales.

### Características Principales de SOAP

#### 1. Basado en XML
Todo mensaje SOAP es un documento XML con estructura específica:

```xml
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Header>
    <!-- Headers opcionales -->
    <auth:Authentication xmlns:auth="http://example.com/auth">
      <auth:username>user123</auth:username>
      <auth:token>abc123xyz</auth:token>
    </auth:Authentication>
  </soap:Header>
  
  <soap:Body>
    <!-- Contenido del mensaje -->
    <m:GetUser xmlns:m="http://example.com/users">
      <m:UserId>12345</m:UserId>
    </m:GetUser>
  </soap:Body>
</soap:Envelope>
```

#### 2. Neutral al Protocolo de Transporte
SOAP puede funcionar sobre varios protocolos:
- HTTP/HTTPS (más común)
- SMTP
- FTP
- TCP directo
- JMS (Java Message Service)

#### 3. WSDL (Web Services Description Language)
Documento XML que describe completamente el servicio:

```xml
<?xml version="1.0"?>
<definitions xmlns="http://schemas.xmlsoap.org/wsdl/"
             xmlns:tns="http://example.com/users"
             targetNamespace="http://example.com/users">
  
  <types>
    <!-- Definición de tipos de datos -->
    <schema xmlns="http://www.w3.org/2001/XMLSchema">
      <element name="GetUserRequest">
        <complexType>
          <sequence>
            <element name="userId" type="int"/>
          </sequence>
        </complexType>
      </element>
    </schema>
  </types>
  
  <message name="GetUserRequest">
    <part name="parameters" element="tns:GetUserRequest"/>
  </message>
  
  <portType name="UserServicePortType">
    <operation name="GetUser">
      <input message="tns:GetUserRequest"/>
      <output message="tns:GetUserResponse"/>
    </operation>
  </portType>
  
</definitions>
```

### Ventajas de SOAP

#### Robustez y Confiabilidad
- **WS-Security**: Seguridad integrada a nivel de mensaje
- **WS-ReliableMessaging**: Garantía de entrega de mensajes
- **WS-Transaction**: Soporte para transacciones distribuidas

#### Estricta Definición de Contratos
```cpp
// Ejemplo: Cliente C++ generado automáticamente desde WSDL
class UserServiceClient {
public:
    GetUserResponse GetUser(const GetUserRequest& request) {
        // Código generado automáticamente
        SoapMessage msg;
        msg.setBody(request.toXml());
        
        SoapResponse response = transport.send(msg);
        return GetUserResponse::fromXml(response.getBody());
    }
};
```

#### Soporte para Tipos Complejos
SOAP maneja naturalmente estructuras de datos complejas:

```xml
<soap:Body>
  <m:CreateOrder xmlns:m="http://example.com/orders">
    <m:Order>
      <m:CustomerId>12345</m:CustomerId>
      <m:Items>
        <m:Item>
          <m:ProductId>678</m:ProductId>
          <m:Quantity>2</m:Quantity>
          <m:Price>29.99</m:Price>
        </m:Item>
        <m:Item>
          <m:ProductId>679</m:ProductId>
          <m:Quantity>1</m:Quantity>
          <m:Price>45.50</m:Price>
        </m:Item>
      </m:Items>
    </m:Order>
  </m:CreateOrder>
</soap:Body>
```

### Desventajas de SOAP

#### Complejidad y Verbosidad
- Mensajes XML muy largos
- Configuración compleja
- Curva de aprendizaje pronunciada

#### Overhead de Rendimiento
```
Tamaño aproximado de mensajes:
REST JSON: {"id": 123, "name": "Juan"} → ~30 bytes
SOAP XML:  Envelope completo → ~500+ bytes
```

#### Dependencia de Herramientas
Requiere herramientas especializadas para generar código desde WSDL.

## REST (Representational State Transfer)

### ¿Qué es REST?

REST es un **estilo arquitectónico** (no un protocolo) que define principios para diseñar servicios web escalables. Se basa en el uso inteligente de HTTP y sus métodos estándar.

### Principios Fundamentales de REST

#### 1. Arquitectura Cliente-Servidor
Separación clara entre cliente y servidor, permitiendo evolución independiente.

#### 2. Stateless (Sin Estado)
Cada petición contiene toda la información necesaria:

```cpp
// ✅ REST Stateless
GET /api/users/123?include=profile,orders
Authorization: Bearer token123

// ❌ No REST - requiere estado del servidor
GET /api/users/next  // ¿Cuál es el "siguiente"?
```

#### 3. Cacheable
Las respuestas deben indicar si pueden ser cacheadas:

```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600
ETag: "version-123"
Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT

{
  "id": 123,
  "name": "Juan Pérez",
  "email": "juan@example.com"
}
```

#### 4. Sistema de Capas
Permite arquitecturas con múltiples capas (proxies, gateways, caches):

```
Cliente ── Proxy ── Load Balancer ── API Gateway ── Microservicio
```

#### 5. Interfaz Uniforme
Uso consistente de métodos HTTP:

```
GET    /api/users       # Obtener lista de usuarios
GET    /api/users/123   # Obtener usuario específico
POST   /api/users       # Crear nuevo usuario
PUT    /api/users/123   # Actualizar usuario completo
PATCH  /api/users/123   # Actualizar usuario parcialmente
DELETE /api/users/123   # Eliminar usuario
```

#### 6. Código bajo Demanda (Opcional)
El servidor puede enviar código ejecutable al cliente (JavaScript, applets).

### Implementación REST en C++

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
        
        response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
        response.send(Http::Code::Ok, users.dump());
    }
    
    void getUser(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        
        // Buscar usuario por ID...
        if (userExists(id)) {
            json user = {{"id", id}, {"name", "Juan"}, {"email", "juan@example.com"}};
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.send(Http::Code::Ok, user.dump());
        } else {
            json error = {{"error", "User not found"}};
            response.send(Http::Code::Not_Found, error.dump());
        }
    }
    
    void createUser(const Rest::Request& req, Http::ResponseWriter response) {
        try {
            json userData = json::parse(req.body());
            
            // Validar datos...
            if (!userData.contains("name") || !userData.contains("email")) {
                json error = {{"error", "Name and email are required"}};
                response.send(Http::Code::Bad_Request, error.dump());
                return;
            }
            
            // Crear usuario...
            int newId = createNewUser(userData);
            
            json createdUser = userData;
            createdUser["id"] = newId;
            
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.headers().add<Http::Header::Location>("/api/users/" + std::to_string(newId));
            response.send(Http::Code::Created, createdUser.dump());
            
        } catch (const json::parse_error& e) {
            json error = {{"error", "Invalid JSON"}};
            response.send(Http::Code::Bad_Request, error.dump());
        }
    }
};
```

### Ventajas de REST

#### Simplicidad y Ligereza
```cpp
// REST: Simple petición HTTP
GET /api/users/123
Accept: application/json
Authorization: Bearer token123

// Respuesta directa
{
  "id": 123,
  "name": "Juan Pérez",
  "email": "juan@example.com"
}
```

#### Alto Rendimiento
- Mensajes más pequeños (JSON vs XML)
- Aprovecha caché HTTP nativo
- Menor overhead de procesamiento

#### Facilidad de Testing
```bash
# Testing con curl
curl -X GET "https://api.example.com/users/123" \
     -H "Authorization: Bearer token123" \
     -H "Accept: application/json"

curl -X POST "https://api.example.com/users" \
     -H "Content-Type: application/json" \
     -d '{"name": "Juan", "email": "juan@example.com"}'
```

### Desventajas de REST

#### Falta de Estándares Estrictos
- No hay contrato formal como WSDL
- Interpretaciones diferentes de "RESTful"
- Documentación manual necesaria

#### Limitaciones con Datos Complejos
```cpp
// Difícil manejar operaciones complejas en REST
POST /api/users/123/orders/456/items/789/apply-discount
```

## Comparación Detallada

### Tabla Comparativa

| Aspecto | SOAP | REST |
|---------|------|------|
| **Tipo** | Protocolo | Estilo Arquitectónico |
| **Formato** | XML obligatorio | JSON, XML, HTML, texto |
| **Transporte** | HTTP, SMTP, FTP, TCP | Principalmente HTTP |
| **Estado** | Puede ser stateful | Stateless |
| **Caché** | Limitado | Nativo HTTP |
| **Seguridad** | WS-Security integrada | HTTPS + OAuth/JWT |
| **Descubrimiento** | WSDL + UDDI | Documentación manual |
| **Tamaño mensaje** | Grande (XML verbose) | Pequeño (JSON compacto) |
| **Curva aprendizaje** | Alta | Baja |
| **Tooling** | Generación automática | Desarrollo manual |
| **Rendimiento** | Menor | Mayor |

### Casos de Uso Típicos

#### SOAP es Mejor Para:

**Aplicaciones Empresariales Críticas**
```cpp
// Ejemplo: Sistema bancario con transacciones
class BankingService {
public:
    TransferResult transferMoney(
        const AccountNumber& from,
        const AccountNumber& to,
        const Money& amount,
        const SecurityContext& context
    ) {
        // Transacción ACID garantizada
        // Seguridad WS-Security
        // Logging completo
        // Rollback automático en caso de error
    }
};
```

**Sistemas con Requisitos de Seguridad Estrictos**
- Servicios gubernamentales
- Sistemas de salud (HIPAA)
- Servicios financieros
- Sistemas de defensa

**Integración B2B Compleja**
- EDI (Electronic Data Interchange)
- Procesos de negocio complejos
- Workflows con múltiples participantes

#### REST es Mejor Para:

**APIs Públicas y Móviles**
```cpp
// Ejemplo: API para aplicación móvil
class SocialMediaAPI {
public:
    void setupRoutes() {
        // Simple y eficiente para móviles
        GET("/api/posts");           // Feed de posts
        POST("/api/posts");          // Crear post
        GET("/api/users/profile");   // Perfil usuario
        POST("/api/posts/123/like"); // Like a post
    }
};
```

**Microservicios**
- Comunicación interna ligera
- Escalabilidad horizontal
- Despliegue independiente

**Aplicaciones Web Modernas**
- SPAs (Single Page Applications)
- Aplicaciones móviles
- APIs de terceros

## Implementación Híbrida en C++

### SOAP con gSOAP

```cpp
#include "soapH.h"  // Generado desde WSDL

class SOAPUserService {
private:
    struct soap soap;
    
public:
    SOAPUserService() {
        soap_init(&soap);
        soap_set_namespaces(&soap, namespaces);
    }
    
    User getUser(int userId) {
        ns__getUserRequest request;
        ns__getUserResponse response;
        
        request.userId = userId;
        
        // Llamada SOAP
        if (soap_call_ns__getUser(&soap, endpoint, nullptr, 
                                  &request, &response) == SOAP_OK) {
            return response.user;
        } else {
            throw SOAPException(soap_fault_string(&soap));
        }
    }
    
    ~SOAPUserService() {
        soap_cleanup(&soap);
    }
};
```

### REST con Pistache

```cpp
#include <pistache/http.h>
#include <pistache/router.h>

class RESTUserService {
private:
    std::shared_ptr<Http::Endpoint> endpoint;
    Rest::Router router;
    
public:
    RESTUserService(Address addr) 
        : endpoint(std::make_shared<Http::Endpoint>(addr)) {
        
        auto opts = Http::Endpoint::options()
                      .threads(std::thread::hardware_concurrency())
                      .flags(Tcp::Options::InstallSignalHandler);
        endpoint->init(opts);
        
        setupRoutes();
    }
    
    void setupRoutes() {
        Rest::Routes::Get(router, "/api/users/:id",
            [this](const Rest::Request& req, Http::ResponseWriter response) {
                handleGetUser(req, std::move(response));
            });
    }
    
    void handleGetUser(const Rest::Request& req, Http::ResponseWriter response) {
        auto id = req.param(":id").as<int>();
        
        try {
            User user = userRepository.findById(id);
            json result = {
                {"id", user.id},
                {"name", user.name},
                {"email", user.email}
            };
            
            response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
            response.send(Http::Code::Ok, result.dump());
            
        } catch (const UserNotFoundException& e) {
            json error = {{"error", "User not found"}};
            response.send(Http::Code::Not_Found, error.dump());
        }
    }
    
    void start() {
        endpoint->setHandler(router.handler());
        endpoint->serve();
    }
};
```

## Tendencias Actuales y Futuras

### GraphQL como Alternativa
```graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    name
    email
    posts {
      title
      content
      createdAt
    }
  }
}
```

### gRPC para Microservicios
```protobuf
service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
}

message GetUserRequest {
  int32 user_id = 1;
}

message GetUserResponse {
  User user = 1;
}
```

### WebSockets para Tiempo Real
```cpp
#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/server.hpp>

class WebSocketService {
    typedef websocketpp::server<websocketpp::config::asio> server;
    
public:
    void onMessage(websocketpp::connection_hdl hdl, server::message_ptr msg) {
        // Procesamiento en tiempo real
        json data = json::parse(msg->get_payload());
        
        // Broadcast a todos los clientes conectados
        broadcastMessage(data);
    }
};
```

## Recomendaciones de Elección

### Elige SOAP cuando:
- ✅ Necesites transacciones ACID distribuidas
- ✅ Seguridad sea crítica (WS-Security)
- ✅ Requieras contratos estrictos (WSDL)
- ✅ Trabajes en entornos empresariales legacy
- ✅ Necesites garantías de entrega de mensajes

### Elige REST cuando:
- ✅ Desarrolles APIs públicas o móviles
- ✅ El rendimiento sea prioritario
- ✅ Quieras simplicidad y rapidez de desarrollo
- ✅ Construyas microservicios
- ✅ Necesites escalabilidad horizontal

### Considera Alternativas cuando:
- **GraphQL**: Necesites flexibilidad en queries
- **gRPC**: Requieras comunicación de alto rendimiento
- **WebSockets**: Necesites comunicación bidireccional en tiempo real

La elección entre REST y SOAP depende fundamentalmente de tus requisitos específicos: si priorizas simplicidad y rendimiento, REST es ideal; si necesitas robustez empresarial y seguridad estricta, SOAP puede ser la mejor opción.