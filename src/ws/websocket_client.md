# Guía de WebSocket Client en C++ para conectar con Crow

## Introducción

Esta guía explica cómo crear un cliente WebSocket en C++ que se conecte a un servidor Crow (server-to-server). Se presentan tres librerías populares con ejemplos completos.

---

## Opciones de Librerías

### 1. Boost.Beast (Recomendado)

**Ventajas:**
- Parte de Boost, bien mantenida
- Excelente rendimiento
- Documentación completa

**Instalación:**
```bash
# Ubuntu/Debian
sudo apt-get install libboost-all-dev

# macOS
brew install boost
```

**Ejemplo completo:**

```cpp
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>
#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <iostream>
#include <string>

namespace beast = boost::beast;
namespace http = beast::http;
namespace websocket = beast::websocket;
namespace net = boost::asio;
using tcp = boost::asio::ip::tcp;

int main() {
    try {
        // Contexto de I/O
        net::io_context ioc;
        
        // Resolver y conectar
        tcp::resolver resolver{ioc};
        websocket::stream<tcp::socket> ws{ioc};
        
        auto const results = resolver.resolve("localhost", "8080");
        auto ep = net::connect(ws.next_layer(), results);
        
        // Actualizar el host para el handshake
        std::string host = "localhost:8080";
        
        // Realizar el handshake WebSocket
        ws.handshake(host, "/ws");
        
        // Enviar mensaje
        ws.write(net::buffer(std::string("Hola desde C++ client")));
        
        // Leer respuesta
        beast::flat_buffer buffer;
        ws.read(buffer);
        
        std::cout << "Recibido: " << beast::make_printable(buffer.data()) << std::endl;
        
        // Cerrar conexión
        ws.close(websocket::close_code::normal);
        
    } catch(std::exception const& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}
```

**Compilación:**
```bash
g++ -std=c++17 client.cpp -lboost_system -lpthread -o ws_client
./ws_client
```

---

### 2. WebSocket++ (Alternativa simple)

**Ventajas:**
- API simple e intuitiva
- Bien documentada
- Fácil de usar

**Instalación:**
```bash
# Clonar el repositorio
git clone https://github.com/zaphoyd/websocketpp.git
# Es header-only, solo necesitas incluir los headers
```

**Ejemplo completo:**

```cpp
#include <websocketpp/config/asio_no_tls_client.hpp>
#include <websocketpp/client.hpp>
#include <iostream>

typedef websocketpp::client<websocketpp::config::asio_client> client;

using websocketpp::lib::placeholders::_1;
using websocketpp::lib::placeholders::_2;
using websocketpp::lib::bind;

void on_message(client* c, websocketpp::connection_hdl hdl, 
                client::message_ptr msg) {
    std::cout << "Mensaje recibido: " << msg->get_payload() << std::endl;
}

void on_open(client* c, websocketpp::connection_hdl hdl) {
    std::cout << "Conexión abierta" << std::endl;
    c->send(hdl, "Hola desde C++ con WebSocket++", 
            websocketpp::frame::opcode::text);
}

int main() {
    client c;
    
    try {
        c.set_access_channels(websocketpp::log::alevel::all);
        c.clear_access_channels(websocketpp::log::alevel::frame_payload);
        
        c.init_asio();
        
        c.set_message_handler(bind(&on_message, &c, ::_1, ::_2));
        c.set_open_handler(bind(&on_open, &c, ::_1));
        
        websocketpp::lib::error_code ec;
        client::connection_ptr con = c.get_connection("ws://localhost:8080/ws", ec);
        
        if (ec) {
            std::cout << "Error de conexión: " << ec.message() << std::endl;
            return 1;
        }
        
        c.connect(con);
        c.run();
        
    } catch (websocketpp::exception const & e) {
        std::cout << "Excepción: " << e.what() << std::endl;
    }
    
    return 0;
}
```

**Compilación:**
```bash
g++ -std=c++11 client.cpp -I/path/to/websocketpp -lboost_system -lpthread -o ws_client
./ws_client
```

---

### 3. IXWebSocket (Moderna y multiplataforma)

**Ventajas:**
- API moderna y simple
- Multiplataforma (Windows, macOS, Linux, iOS, Android)
- Soporte SSL fácil

**Instalación:**
```bash
git clone https://github.com/machinezone/IXWebSocket.git
cd IXWebSocket
mkdir build && cd build
cmake ..
make
sudo make install
```

**Ejemplo completo:**

```cpp
#include <ixwebsocket/IXWebSocket.h>
#include <iostream>
#include <thread>
#include <chrono>

int main() {
    ix::WebSocket webSocket;
    
    std::string url("ws://localhost:8080/ws");
    webSocket.setUrl(url);
    
    webSocket.setOnMessageCallback([](const ix::WebSocketMessagePtr& msg) {
        if (msg->type == ix::WebSocketMessageType::Message) {
            std::cout << "Recibido: " << msg->str << std::endl;
        }
        else if (msg->type == ix::WebSocketMessageType::Open) {
            std::cout << "Conexión establecida" << std::endl;
        }
        else if (msg->type == ix::WebSocketMessageType::Close) {
            std::cout << "Conexión cerrada" << std::endl;
        }
        else if (msg->type == ix::WebSocketMessageType::Error) {
            std::cout << "Error: " << msg->errorInfo.reason << std::endl;
        }
    });
    
    webSocket.start();
    
    // Esperar a que la conexión se establezca
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    // Enviar mensaje
    webSocket.send("Hola desde C++ con IXWebSocket");
    
    // Mantener la conexión
    std::this_thread::sleep_for(std::chrono::seconds(5));
    
    webSocket.stop();
    
    return 0;
}
```

**Compilación:**
```bash
g++ -std=c++14 client.cpp -lixwebsocket -lpthread -o ws_client
./ws_client
```

---

## Comparación de Librerías

| Característica | Boost.Beast | WebSocket++ | IXWebSocket |
|----------------|-------------|-------------|-------------|
| **Facilidad de uso** | Media | Alta | Muy Alta |
| **Rendimiento** | Excelente | Bueno | Bueno |
| **Dependencias** | Boost | Boost + Asio | Mínimas |
| **SSL/TLS** | Sí | Sí | Sí (muy fácil) |
| **Plataformas** | Múltiples | Múltiples | Múltiples + Mobile |
| **Mantenimiento** | Activo | Activo | Muy Activo |

---

## Consideraciones para Server-to-Server

### 1. Autenticación
Es recomendable implementar autenticación mediante tokens o API keys:

```cpp
// Ejemplo con header personalizado
ws.handshake(host, "/ws", 
    [](beast::http::request<beast::http::empty_body>& req) {
        req.set("Authorization", "Bearer tu_token_aqui");
    });
```

### 2. Reconexión Automática
Implementa lógica de reconexión en caso de fallo:

```cpp
bool reconnect(websocket::stream<tcp::socket>& ws, int max_attempts = 5) {
    for(int i = 0; i < max_attempts; i++) {
        try {
            // Lógica de conexión
            return true;
        } catch(...) {
            std::this_thread::sleep_for(std::chrono::seconds(2 * i));
        }
    }
    return false;
}
```

### 3. Manejo de Errores Robusto
Siempre implementa try-catch y verifica códigos de error:

```cpp
try {
    ws.write(net::buffer(mensaje));
} catch(beast::system_error const& se) {
    if(se.code() != websocket::error::closed) {
        std::cerr << "Error: " << se.code().message() << std::endl;
    }
}
```

### 4. Keep-Alive / Ping-Pong
Implementa mecanismos de keep-alive para mantener la conexión:

```cpp
// Configurar control frames
ws.control_callback(
    [](websocket::frame_type kind, beast::string_view payload) {
        if(kind == websocket::frame_type::ping) {
            std::cout << "Ping recibido" << std::endl;
        }
    });
```

---

## Ejemplo de Servidor Crow para Pruebas

```cpp
#include "crow_all.h"

int main() {
    crow::SimpleApp app;

    CROW_ROUTE(app, "/ws")
        .websocket()
        .onopen([&](crow::websocket::connection& conn){
            CROW_LOG_INFO << "Nueva conexión WebSocket";
        })
        .onmessage([&](crow::websocket::connection& conn, 
                       const std::string& data, bool is_binary){
            CROW_LOG_INFO << "Mensaje recibido: " << data;
            conn.send_text("Echo: " + data);
        })
        .onclose([&](crow::websocket::connection& conn, 
                     const std::string& reason){
            CROW_LOG_INFO << "Conexión cerrada: " << reason;
        });

    app.port(8080).multithreaded().run();
}
```

---

## Recomendaciones Finales

### ¿Cuál librería elegir?

- **Boost.Beast**: Si ya usas Boost en tu proyecto
- **WebSocket++**: Para proyectos simples con API intuitiva
- **IXWebSocket**: Para proyectos multiplataforma o que necesiten facilidad de uso

### Tips Importantes

1. **Manejo de hilos**: Usa hilos separados para operaciones de I/O
2. **Buffer management**: Ten cuidado con el tamaño de los buffers
3. **Timeouts**: Implementa timeouts para evitar bloqueos
4. **Logging**: Añade logs detallados para debugging
5. **Testing**: Prueba escenarios de desconexión y reconexión

---

## Enlaces Útiles

- [Boost.Beast Documentation](https://www.boost.org/doc/libs/release/libs/beast/)
- [WebSocket++ GitHub](https://github.com/zaphoyd/websocketpp)
- [IXWebSocket GitHub](https://github.com/machinezone/IXWebSocket)
- [Crow Framework](https://crowcpp.org/)

---

**Fecha de creación:** Octubre 2025  
**Versión:** 1.0