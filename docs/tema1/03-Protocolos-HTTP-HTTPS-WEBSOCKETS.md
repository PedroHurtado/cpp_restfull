# Protocolos Subyacentes: HTTP, HTTPS y WebSockets

## HTTP (HyperText Transfer Protocol)

### ¿Qué es HTTP?

HTTP es el protocolo de comunicación que permite la transferencia de información en la World Wide Web. Es un protocolo de la capa de aplicación basado en el modelo cliente-servidor que funciona sobre TCP/IP.

### Características Fundamentales de HTTP

#### 1. Stateless (Sin Estado)
Cada petición HTTP es independiente; el servidor no mantiene información sobre peticiones anteriores.

```cpp
// Cada petición incluye toda la información necesaria
GET /api/users/123 HTTP/1.1
Host: api.example.com
Authorization: Bearer token123
Accept: application/json
User-Agent: MyApp/1.0
```

#### 2. Basado en Texto
HTTP es un protocolo legible por humanos, lo que facilita el debugging.

#### 3. Request-Response
Sigue un patrón estricto de petición-respuesta.

### Estructura de Mensajes HTTP

#### Petición HTTP (Request)

```
GET /api/users?page=1&limit=10 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json
Content-Type: application/json
User-Agent: MyApp/1.0
Connection: keep-alive

{
  "filter": {
    "active": true,
    "role": "admin"
  }
}
```

**Componentes:**
1. **Línea de petición**: Método + URL + Versión HTTP
2. **Headers**: Metadatos de la petición
3. **Línea vacía**: Separador
4. **Body**: Datos de la petición (opcional)

#### Respuesta HTTP (Response)

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 1234
Cache-Control: max-age=3600
ETag: "abc123"
Server: nginx/1.18.0
Date: Sun, 28 Sep 2025 10:00:00 GMT

{
  "users": [
    {
      "id": 123,
      "name": "Juan Pérez",
      "email": "juan@example.com",
      "role": "admin"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 50
  }
}
```

### Métodos HTTP

#### GET - Obtener Recursos
```cpp
// Implementación en C++ usando libcurl
#include <curl/curl.h>
#include <string>

class HttpClient {
public:
    std::string get(const std::string& url) {
        CURL* curl = curl_easy_init();
        std::string response;
        
        if (curl) {
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
            
            // Headers
            struct curl_slist* headers = nullptr;
            headers = curl_slist_append(headers, "Accept: application/json");
            headers = curl_slist_append(headers, "Authorization: Bearer token123");
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
            
            CURLcode res = curl_easy_perform(curl);
            
            curl_slist_free_all(headers);
            curl_easy_cleanup(curl);
        }
        
        return response;
    }
    
private:
    static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* s) {
        size_t newLength = size * nmemb;
        s->append((char*)contents, newLength);
        return newLength;
    }
};
```

#### POST - Crear Recursos
```cpp
std::string post(const std::string& url, const std::string& data) {
    CURL* curl = curl_easy_init();
    std::string response;
    
    if (curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
        
        struct curl_slist* headers = nullptr;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        headers = curl_slist_append(headers, "Authorization: Bearer token123");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        
        CURLcode res = curl_easy_perform(curl);
        
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
    }
    
    return response;
}
```

#### Otros Métodos HTTP
```cpp
// PUT - Actualizar recurso completo
curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT");

// PATCH - Actualizar recurso parcialmente  
curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PATCH");

// DELETE - Eliminar recurso
curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE");

// HEAD - Obtener solo headers
curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);

// OPTIONS - Obtener métodos soportados
curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "OPTIONS");
```

### Códigos de Estado HTTP

#### 1xx - Informativos
```cpp
// 100 Continue - El servidor ha recibido los headers
// 101 Switching Protocols - Cambio a WebSockets
response.send(Http::Code::Continue);
```

#### 2xx - Éxito
```cpp
// 200 OK - Petición exitosa
response.send(Http::Code::Ok, data);

// 201 Created - Recurso creado exitosamente
response.headers().add<Http::Header::Location>("/api/users/123");
response.send(Http::Code::Created, newUser);

// 204 No Content - Exitoso pero sin contenido
response.send(Http::Code::No_Content);
```

#### 3xx - Redirección
```cpp
// 301 Moved Permanently - Redirección permanente
response.headers().add<Http::Header::Location>("/api/v2/users");
response.send(Http::Code::Moved_Permanently);

// 304 Not Modified - Recurso no modificado (cache)
if (request.headers().get<Http::Header::IfNoneMatch>() == currentETag) {
    response.send(Http::Code::Not_Modified);
}
```

#### 4xx - Error del Cliente
```cpp
// 400 Bad Request - Petición malformada
if (!isValidJson(request.body())) {
    json error = {{"error", "Invalid JSON format"}};
    response.send(Http::Code::Bad_Request, error.dump());
}

// 401 Unauthorized - No autenticado
if (!isAuthenticated(request)) {
    response.headers().add<Http::Header::WwwAuthenticate>("Bearer");
    response.send(Http::Code::Unauthorized);
}

// 403 Forbidden - Sin permisos
if (!hasPermission(user, "admin")) {
    response.send(Http::Code::Forbidden);
}

// 404 Not Found - Recurso no encontrado
if (!userExists(userId)) {
    json error = {{"error", "User not found"}};
    response.send(Http::Code::Not_Found, error.dump());
}

// 429 Too Many Requests - Rate limiting
if (rateLimiter.isExceeded(clientId)) {
    response.headers().add<Http::Header::RetryAfter>("60");
    response.send(Http::Code::Too_Many_Requests);
}
```

#### 5xx - Error del Servidor
```cpp
// 500 Internal Server Error - Error interno
try {
    auto result = processRequest(request);
    response.send(Http::Code::Ok, result);
} catch (const std::exception& e) {
    logger.error("Internal error: {}", e.what());
    json error = {{"error", "Internal server error"}};
    response.send(Http::Code::Internal_Server_Error, error.dump());
}

// 503 Service Unavailable - Servicio no disponible
if (!database.isConnected()) {
    response.headers().add<Http::Header::RetryAfter>("30");
    response.send(Http::Code::Service_Unavailable);
}
```

### Headers HTTP Importantes

#### Headers de Request
```cpp
class RequestHandler {
public:
    void handleRequest(const Http::Request& request, Http::ResponseWriter response) {
        // Content negotiation
        auto acceptHeader = request.headers().get<Http::Header::Accept>();
        bool wantsJson = acceptHeader && acceptHeader->mime() == MIME(Application, Json);
        
        // Autenticación
        auto authHeader = request.headers().get<Http::Header::Authorization>();
        if (!authHeader || !validateToken(authHeader->value())) {
            response.send(Http::Code::Unauthorized);
            return;
        }
        
        // Cache validation
        auto ifNoneMatch = request.headers().get<Http::Header::IfNoneMatch>();
        if (ifNoneMatch && ifNoneMatch->value() == getCurrentETag()) {
            response.send(Http::Code::Not_Modified);
            return;
        }
        
        // User agent para analytics
        auto userAgent = request.headers().get<Http::Header::UserAgent>();
        analytics.track(userAgent ? userAgent->value() : "unknown");
    }
};
```

#### Headers de Response
```cpp
void sendSuccessResponse(Http::ResponseWriter& response, const json& data) {
    // Content type
    response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
    
    // Cache control
    response.headers().add<Http::Header::CacheControl>("max-age=3600, public");
    response.headers().add<Http::Header::ETag>("\"" + generateETag(data) + "\"");
    
    // Security headers
    response.headers().add<Http::Header::AccessControlAllowOrigin>("https://myapp.com");
    response.headers().addRaw("X-Content-Type-Options", "nosniff");
    response.headers().addRaw("X-Frame-Options", "DENY");
    response.headers().addRaw("X-XSS-Protection", "1; mode=block");
    
    // CORS headers
    response.headers().addRaw("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
    response.headers().addRaw("Access-Control-Allow-Headers", "Content-Type, Authorization");
    
    response.send(Http::Code::Ok, data.dump());
}
```

### Versiones de HTTP

#### HTTP/1.0
- Una conexión por petición
- Sin keep-alive por defecto
- Headers limitados

#### HTTP/1.1
```cpp
// Keep-alive por defecto
Connection: keep-alive

// Chunked transfer encoding
Transfer-Encoding: chunked

// Host header obligatorio
Host: api.example.com
```

#### HTTP/2
```cpp
// Implementación con nghttp2
#include <nghttp2/nghttp2.h>

class Http2Server {
public:
    void setupServer() {
        // Multiplexing - múltiples streams en una conexión
        // Server push - servidor puede enviar recursos proactivamente
        // Compresión de headers HPACK
        // Protocolo binario
    }
};
```

## HTTPS (HTTP Secure)

### ¿Qué es HTTPS?

HTTPS es HTTP sobre una capa de seguridad TLS/SSL. Proporciona:
- **Encriptación**: Los datos se cifran en tránsito
- **Integridad**: Detección de modificaciones
- **Autenticación**: Verificación de identidad del servidor

### Implementación HTTPS en C++

#### Servidor HTTPS con Pistache
```cpp
#include <pistache/http.h>
#include <pistache/ssl.h>

class HttpsServer {
public:
    HttpsServer(Address addr) : endpoint(std::make_shared<Http::Endpoint>(addr)) {
        auto opts = Http::Endpoint::options()
                      .threads(std::thread::hardware_concurrency())
                      .flags(Tcp::Options::InstallSignalHandler);
        
        // Configuración SSL
        Pistache::Ssl::Setup ssl;
        ssl.cert("server.crt")
           .key("server.key")
           .cafile("ca.pem");
        
        endpoint->init(opts);
        endpoint->useSSL(ssl);
    }
    
    void start() {
        endpoint->setHandler(Http::make_handler<HttpsHandler>());
        endpoint->serve();
    }
    
private:
    std::shared_ptr<Http::Endpoint> endpoint;
};
```

#### Cliente HTTPS con libcurl
```cpp
class HttpsClient {
public:
    HttpsClient() {
        curl_global_init(CURL_GLOBAL_DEFAULT);
    }
    
    std::string httpsGet(const std::string& url) {
        CURL* curl = curl_easy_init();
        std::string response;
        
        if (curl) {
            curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
            
            // Configuración SSL
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
            curl_easy_setopt(curl, CURLOPT_CAINFO, "ca-bundle.crt");
            
            // Certificado cliente (opcional)
            curl_easy_setopt(curl, CURLOPT_SSLCERT, "client.crt");
            curl_easy_setopt(curl, CURLOPT_SSLKEY, "client.key");
            
            CURLcode res = curl_easy_perform(curl);
            
            if (res != CURLE_OK) {
                throw std::runtime_error("HTTPS request failed: " + 
                                       std::string(curl_easy_strerror(res)));
            }
            
            curl_easy_cleanup(curl);
        }
        
        return response;
    }
    
    ~HttpsClient() {
        curl_global_cleanup();
    }
};
```

### Configuración SSL/TLS

#### Generación de Certificados
```bash
# Certificado autofirmado para desarrollo
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes

# Configuración para producción con Let's Encrypt
certbot certonly --standalone -d api.example.com
```

#### Configuración de Seguridad
```cpp
class SecurityConfig {
public:
    static void configureTLS(Pistache::Ssl::Setup& ssl) {
        // Versiones TLS permitidas
        ssl.minVersion(Pistache::Ssl::Version::TLSv1_2);
        ssl.maxVersion(Pistache::Ssl::Version::TLSv1_3);
        
        // Cipher suites seguras
        ssl.ciphers("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS");
        
        // HSTS (HTTP Strict Transport Security)
        ssl.honorCipherOrder(true);
    }
};
```

## WebSockets

### ¿Qué son los WebSockets?

WebSockets proporcionan comunicación bidireccional y full-duplex entre cliente y servidor sobre una sola conexión TCP. A diferencia de HTTP, permiten que tanto el cliente como el servidor inicien la comunicación.

### Características de WebSockets

#### 1. Comunicación Bidireccional
```
Cliente ←─────────────────→ Servidor
        ← mensaje push ←
        → mensaje request →
        ← respuesta inmediata ←
```

#### 2. Persistente
Una sola conexión se mantiene abierta durante toda la sesión.

#### 3. Low Latency
Sin overhead de headers HTTP en cada mensaje.

### Handshake WebSocket

#### Upgrade Request
```
GET /websocket HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: https://example.com
Sec-WebSocket-Protocol: chat, superchat
```

#### Upgrade Response
```
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Sec-WebSocket-Protocol: chat
```

### Implementación WebSocket en C++

#### Servidor WebSocket con websocketpp
```cpp
#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/server.hpp>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
typedef websocketpp::server<websocketpp::config::asio> server;

class WebSocketServer {
private:
    server m_server;
    std::set<websocketpp::connection_hdl, std::owner_less<websocketpp::connection_hdl>> m_connections;
    std::thread m_thread;
    
public:
    WebSocketServer() {
        // Configuración
        m_server.set_access_channels(websocketpp::log::alevel::all);
        m_server.clear_access_channels(websocketpp::log::alevel::frame_payload);
        m_server.init_asio();
        m_server.set_reuse_addr(true);
        
        // Handlers
        m_server.set_open_handler([this](websocketpp::connection_hdl hdl) {
            onOpen(hdl);
        });
        
        m_server.set_close_handler([this](websocketpp::connection_hdl hdl) {
            onClose(hdl);
        });
        
        m_server.set_message_handler([this](websocketpp::connection_hdl hdl, server::message_ptr msg) {
            onMessage(hdl, msg);
        });
    }
    
    void start(uint16_t port) {
        m_server.listen(port);
        m_server.start_accept();
        
        m_thread = std::thread([this]() {
            m_server.run();
        });
    }
    
    void stop() {
        m_server.stop();
        if (m_thread.joinable()) {
            m_thread.join();
        }
    }
    
private:
    void onOpen(websocketpp::connection_hdl hdl) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_connections.insert(hdl);
        
        // Enviar mensaje de bienvenida
        json welcome = {
            {"type", "welcome"},
            {"message", "Connected to WebSocket server"},
            {"timestamp", std::time(nullptr)}
        };
        
        sendMessage(hdl, welcome);
    }
    
    void onClose(websocketpp::connection_hdl hdl) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_connections.erase(hdl);
    }
    
    void onMessage(websocketpp::connection_hdl hdl, server::message_ptr msg) {
        try {
            json data = json::parse(msg->get_payload());
            
            // Procesar diferentes tipos de mensajes
            std::string type = data["type"];
            
            if (type == "chat") {
                handleChatMessage(hdl, data);
            } else if (type == "broadcast") {
                handleBroadcast(data);
            } else if (type == "ping") {
                handlePing(hdl);
            }
            
        } catch (const json::parse_error& e) {
            json error = {
                {"type", "error"},
                {"message", "Invalid JSON format"}
            };
            sendMessage(hdl, error);
        }
    }
    
    void handleChatMessage(websocketpp::connection_hdl hdl, const json& data) {
        json message = {
            {"type", "chat"},
            {"user", data["user"]},
            {"message", data["message"]},
            {"timestamp", std::time(nullptr)}
        };
        
        // Broadcast a todos los clientes conectados
        broadcast(message);
    }
    
    void handleBroadcast(const json& data) {
        json broadcastMsg = {
            {"type", "broadcast"},
            {"message", data["message"]},
            {"timestamp", std::time(nullptr)}
        };
        
        broadcast(broadcastMsg);
    }
    
    void handlePing(websocketpp::connection_hdl hdl) {
        json pong = {
            {"type", "pong"},
            {"timestamp", std::time(nullptr)}
        };
        
        sendMessage(hdl, pong);
    }
    
    void sendMessage(websocketpp::connection_hdl hdl, const json& message) {
        try {
            m_server.get_alog().write(websocketpp::log::alevel::app, message.dump());
            m_server.send(hdl, message.dump(), websocketpp::frame::opcode::text);
        } catch (const websocketpp::exception& e) {
            std::cerr << "Send failed: " << e.what() << std::endl;
        }
    }
    
    void broadcast(const json& message) {
        std::lock_guard<std::mutex> lock(m_mutex);
        
        for (auto& connection : m_connections) {
            sendMessage(connection, message);
        }
    }
    
    std::mutex m_mutex;
};
```

#### Cliente WebSocket
```cpp
#include <websocketpp/config/asio_client.hpp>
#include <websocketpp/client.hpp>

typedef websocketpp::client<websocketpp::config::asio_client> client;

class WebSocketClient {
private:
    client m_client;
    websocketpp::connection_hdl m_hdl;
    std::thread m_thread;
    
public:
    WebSocketClient() {
        m_client.clear_access_channels(websocketpp::log::alevel::all);
        m_client.clear_error_channels(websocketpp::log::elevel::all);
        
        m_client.init_asio();
        m_client.start_perpetual();
        
        m_thread = std::thread([this]() {
            m_client.run();
        });
    }
    
    void connect(const std::string& uri) {
        websocketpp::lib::error_code ec;
        client::connection_ptr con = m_client.get_connection(uri, ec);
        
        if (ec) {
            throw std::runtime_error("Connection failed: " + ec.message());
        }
        
        // Handlers
        con->set_open_handler([this](websocketpp::connection_hdl hdl) {
            m_hdl = hdl;
            std::cout << "Connected to server" << std::endl;
        });
        
        con->set_close_handler([](websocketpp::connection_hdl hdl) {
            std::cout << "Disconnected from server" << std::endl;
        });
        
        con->set_message_handler([this](websocketpp::connection_hdl hdl, client::message_ptr msg) {
            onMessage(msg);
        });
        
        m_client.connect(con);
    }
    
    void sendMessage(const json& message) {
        websocketpp::lib::error_code ec;
        m_client.send(m_hdl, message.dump(), websocketpp::frame::opcode::text, ec);
        
        if (ec) {
            std::cerr << "Send failed: " << ec.message() << std::endl;
        }
    }
    
    void disconnect() {
        websocketpp::lib::error_code ec;
        m_client.close(m_hdl, websocketpp::close::status::normal, "Goodbye", ec);
        
        if (ec) {
            std::cerr << "Disconnect failed: " << ec.message() << std::endl;
        }
    }
    
    ~WebSocketClient() {
        m_client.stop_perpetual();
        
        if (m_thread.joinable()) {
            m_thread.join();
        }
    }
    
private:
    void onMessage(client::message_ptr msg) {
        try {
            json data = json::parse(msg->get_payload());
            
            std::string type = data["type"];
            
            if (type == "chat") {
                std::cout << "[" << data["user"] << "]: " << data["message"] << std::endl;
            } else if (type == "broadcast") {
                std::cout << "[BROADCAST]: " << data["message"] << std::endl;
            } else if (type == "pong") {
                std::cout << "Pong received" << std::endl;
            }
            
        } catch (const json::parse_error& e) {
            std::cerr << "Invalid message format" << std::endl;
        }
    }
};
```

### Casos de Uso de WebSockets

#### 1. Chat en Tiempo Real
```cpp
class ChatApplication {
public:
    void setupChatHandlers() {
        server.setMessageHandler([this](auto hdl, auto msg) {
            json data = json::parse(msg->get_payload());
            
            if (data["type"] == "join_room") {
                joinChatRoom(hdl, data["room"]);
            } else if (data["type"] == "chat_message") {
                broadcastToRoom(data["room"], data);
            } else if (data["type"] == "leave_room") {
                leaveChatRoom(hdl, data["room"]);
            }
        });
    }
    
private:
    std::map<std::string, std::set<websocketpp::connection_hdl>> chatRooms;
    
    void joinChatRoom(websocketpp::connection_hdl hdl, const std::string& room) {
        chatRooms[room].insert(hdl);
        
        json notification = {
            {"type", "user_joined"},
            {"room", room},
            {"timestamp", std::time(nullptr)}
        };
        
        broadcastToRoom(room, notification);
    }
    
    void broadcastToRoom(const std::string& room, const json& message) {
        if (chatRooms.find(room) != chatRooms.end()) {
            for (auto& connection : chatRooms[room]) {
                server.sendMessage(connection, message);
            }
        }
    }
};
```

#### 2. Actualizaciones de Estado en Tiempo Real
```cpp
class LiveDashboard {
public:
    void startMetricsUpdater() {
        metricsThread = std::thread([this]() {
            while (running) {
                auto metrics = collectSystemMetrics();
                
                json update = {
                    {"type", "metrics_update"},
                    {"cpu_usage", metrics.cpuUsage},
                    {"memory_usage", metrics.memoryUsage},
                    {"active_connections", metrics.activeConnections},
                    {"requests_per_second", metrics.requestsPerSecond},
                    {"timestamp", std::time(nullptr)}
                };
                
                broadcastToAll(update);
                
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        });
    }
    
private:
    struct SystemMetrics {
        double cpuUsage;
        double memoryUsage;
        int activeConnections;
        double requestsPerSecond;
    };
    
    SystemMetrics collectSystemMetrics() {
        // Recopilar métricas del sistema
        return {
            getCpuUsage(),
            getMemoryUsage(),
            getActiveConnections(),
            getRequestsPerSecond()
        };
    }
};
```

#### 3. Trading y Cotizaciones Financieras
```cpp
class TradingPlatform {
public:
    void setupTradingHandlers() {
        // Suscripción a símbolos
        server.setMessageHandler([this](auto hdl, auto msg) {
            json data = json::parse(msg->get_payload());
            
            if (data["type"] == "subscribe") {
                subscribeToSymbol(hdl, data["symbol"]);
            } else if (data["type"] == "unsubscribe") {
                unsubscribeFromSymbol(hdl, data["symbol"]);
            } else if (data["type"] == "place_order") {
                placeOrder(hdl, data);
            }
        });
        
        // Simulador de precios
        priceUpdater = std::thread([this]() {
            while (running) {
                updatePrices();
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        });
    }
    
private:
    std::map<std::string, std::set<websocketpp::connection_hdl>> symbolSubscriptions;
    std::map<std::string, double> currentPrices;
    
    void updatePrices() {
        for (auto& [symbol, price] : currentPrices) {
            // Simular cambio de precio
            double change = (rand() % 200 - 100) / 10000.0; // -1% a +1%
            price *= (1.0 + change);
            
            json priceUpdate = {
                {"type", "price_update"},
                {"symbol", symbol},
                {"price", price},
                {"change", change},
                {"timestamp", std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch()).count()}
            };
            
            // Enviar a suscriptores
            if (symbolSubscriptions.find(symbol) != symbolSubscriptions.end()) {
                for (auto& connection : symbolSubscriptions[symbol]) {
                    server.sendMessage(connection, priceUpdate);
                }
            }
        }
    }
};
```

### Comparación de Protocolos

#### HTTP vs WebSockets

| Aspecto | HTTP | WebSockets |
|---------|------|------------|
| **Patrón** | Request-Response | Bidireccional |
| **Conexiones** | Una por petición | Persistente |
| **Overhead** | Headers en cada mensaje | Handshake inicial |
| **Latencia** | Mayor (TCP + headers) | Menor (sin headers) |
| **Caché** | Nativo | No aplicable |
| **Simplicidad** | Simple | Más complejo |
| **Debugging** | Fácil (herramientas HTTP) | Requiere herramientas especiales |

#### Cuándo Usar Cada Protocolo

**Usa HTTP/HTTPS cuando:**
- ✅ Necesites operaciones CRUD tradicionales
- ✅ Quieras aprovechar caché HTTP
- ✅ Desarrolles APIs REST estándar
- ✅ La comunicación sea principalmente unidireccional
- ✅ Necesites compatibilidad con proxies/firewalls

**Usa WebSockets cuando:**
- ✅ Requieras comunicación en tiempo real
- ✅ Necesites baja latencia
- ✅ Implementes chat o colaboración
- ✅ Manejes actualizaciones frecuentes de estado
- ✅ Desarrolles juegos multijugador

### Consideraciones de Seguridad

#### Autenticación en WebSockets
```cpp
class SecureWebSocketServer {
public:
    void validateConnection(websocketpp::connection_hdl hdl) {
        auto con = server.get_con_from_hdl(hdl);
        
        // Validar token en el handshake
        auto authHeader = con->get_request_header("Authorization");
        if (authHeader.empty() || !validateJWTToken(authHeader)) {
            con->set_status(websocketpp::http::status_code::unauthorized);
            con->set_body("Unauthorized");
            return;
        }
        
        // Validar origen
        auto origin = con->get_request_header("Origin");
        if (!isAllowedOrigin(origin)) {
            con->set_status(websocketpp::http::status_code::forbidden);
            con->set_body("Origin not allowed");
            return;
        }
    }
    
private:
    bool validateJWTToken(const std::string& token) {
        // Implementar validación JWT
        return jwt::verify(token, secret_key);
    }
    
    bool isAllowedOrigin(const std::string& origin) {
        std::vector<std::string> allowedOrigins = {
            "https://myapp.com",
            "https://app.mycompany.com"
        };
        
        return std::find(allowedOrigins.begin(), allowedOrigins.end(), origin) 
               != allowedOrigins.end();
    }
};
```

#### Rate Limiting
```cpp
class RateLimitedWebSocket {
private:
    std::map<std::string, std::queue<std::time_t>> clientMessageTimes;
    const int maxMessagesPerMinute = 60;
    
public:
    bool isRateLimited(const std::string& clientId) {
        auto now = std::time(nullptr);
        auto& messageQueue = clientMessageTimes[clientId];
        
        // Limpiar mensajes antiguos
        while (!messageQueue.empty() && 
               (now - messageQueue.front()) > 60) {
            messageQueue.pop();
        }
        
        // Verificar límite
        if (messageQueue.size() >= maxMessagesPerMinute) {
            return true; // Rate limited
        }
        
        messageQueue.push(now);
        return false;
    }
};
```

### Monitoreo y Debugging

#### Métricas de WebSocket
```cpp
class WebSocketMetrics {
private:
    std::atomic<int> activeConnections{0};
    std::atomic<long> totalMessages{0};
    std::atomic<long> totalBytes{0};
    
public:
    void onConnection() { activeConnections++; }
    void onDisconnection() { activeConnections--; }
    void onMessage(size_t bytes) { 
        totalMessages++; 
        totalBytes += bytes;
    }
    
    json getMetrics() {
        return {
            {"active_connections", activeConnections.load()},
            {"total_messages", totalMessages.load()},
            {"total_bytes", totalBytes.load()},
            {"messages_per_connection", 
             activeConnections > 0 ? totalMessages.load() / activeConnections.load() : 0}
        };
    }
};
```

#### Logging Estructurado
```cpp
#include <spdlog/spdlog.h>

class WebSocketLogger {
public:
    void logConnection(const std::string& clientId, const std::string& userAgent) {
        spdlog::info("WebSocket connection established",
                    spdlog::arg("client_id", clientId),
                    spdlog::arg("user_agent", userAgent),
                    spdlog::arg("timestamp", std::time(nullptr)));
    }
    
    void logMessage(const std::string& clientId, const std::string& type, size_t size) {
        spdlog::debug("WebSocket message received",
                     spdlog::arg("client_id", clientId),
                     spdlog::arg("message_type", type),
                     spdlog::arg("message_size", size));
    }
    
    void logError(const std::string& clientId, const std::string& error) {
        spdlog::error("WebSocket error",
                     spdlog::arg("client_id", clientId),
                     spdlog::arg("error", error));
    }
};
```

Los protocolos HTTP, HTTPS y WebSockets forman la base de la comunicación en servicios web modernos. HTTP/HTTPS proporcionan la base sólida para APIs REST tradicionales, mientras que WebSockets abren posibilidades para aplicaciones en tiempo real. La elección del protocolo correcto depende de los requisitos específicos de latencia, patrón de comunicación y complejidad de la aplicación.