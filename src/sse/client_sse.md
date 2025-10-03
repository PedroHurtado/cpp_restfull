# Cliente SSE (Server-Sent Events) en C++

Guía completa para crear clientes SSE en C++ sin necesidad de navegador.

## Tabla de Contenidos
- [Introducción](#introducción)
- [Opción 1: libcurl](#opción-1-libcurl)
- [Opción 2: ASIO](#opción-2-asio)
- [Opción 3: cpp-httplib](#opción-3-cpp-httplib)
- [Opción 4: Boost.Beast](#opción-4-boostbeast)
- [Comparación de Opciones](#comparación-de-opciones)
- [Casos de Uso](#casos-de-uso)

---

## Introducción

Puedes crear un cliente SSE en C++ puro sin necesidad de un navegador. Esto es útil para:
- Procesar eventos en tiempo real sin interfaz gráfica
- Integración en servicios/daemons
- Conectar microservicios
- Monitoreo y logging automatizado
- Aplicaciones embebidas

---

## Opción 1: libcurl

**La más común y portable**

### Instalación
```bash
# Ubuntu/Debian
sudo apt-get install libcurl4-openssl-dev

# macOS
brew install curl

# Fedora/RHEL
sudo dnf install libcurl-devel
```

### Código Completo
```cpp
#include <curl/curl.h>
#include <iostream>
#include <string>

size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    std::string data((char*)contents, size * nmemb);
    std::cout << "Evento recibido: " << data << std::endl;
    return size * nmemb;
}

int main() {
    CURL* curl = curl_easy_init();
    
    if(curl) {
        // Configurar URL del servidor SSE
        curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:18080/events");
        
        // Callback para procesar datos
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        
        // Mantener conexión abierta (HTTP/1.1)
        curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
        
        // Headers necesarios para SSE
        struct curl_slist* headers = NULL;
        headers = curl_slist_append(headers, "Accept: text/event-stream");
        headers = curl_slist_append(headers, "Cache-Control: no-cache");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        
        // Ejecutar (bloqueante hasta que se cierre la conexión)
        CURLcode res = curl_easy_perform(curl);
        
        if(res != CURLE_OK) {
            std::cerr << "Error: " << curl_easy_strerror(res) << std::endl;
        }
        
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
    }
    
    return 0;
}
```

### Compilación
```bash
g++ -std=c++17 sse_client_curl.cpp -lcurl -o sse_client
./sse_client
```

### Ventajas
- ✅ Muy portable y estable
- ✅ Ampliamente usado y documentado
- ✅ Soporta HTTPS/SSL fácilmente

### Desventajas
- ❌ API en C (menos idiomático para C++)
- ❌ Callback bloqueante

---

## Opción 2: ASIO

**Control de bajo nivel sobre sockets**

### Instalación
```bash
# Ubuntu/Debian
sudo apt-get install libasio-dev

# macOS
brew install asio

# O header-only desde: https://think-async.com/Asio/
```

### Código Completo
```cpp
#include <asio.hpp>
#include <iostream>
#include <string>

using asio::ip::tcp;

int main() {
    try {
        asio::io_context io_context;
        
        // Resolver el host
        tcp::resolver resolver(io_context);
        auto endpoints = resolver.resolve("localhost", "18080");
        
        // Conectar al servidor
        tcp::socket socket(io_context);
        asio::connect(socket, endpoints);
        
        // Construir petición HTTP
        std::string request = 
            "GET /events HTTP/1.1\r\n"
            "Host: localhost:18080\r\n"
            "Accept: text/event-stream\r\n"
            "Cache-Control: no-cache\r\n"
            "Connection: keep-alive\r\n"
            "\r\n";
        
        // Enviar petición
        asio::write(socket, asio::buffer(request));
        
        // Leer respuesta continuamente
        asio::streambuf response;
        std::string line;
        
        while(true) {
            asio::read_until(socket, response, "\n");
            std::istream response_stream(&response);
            std::getline(response_stream, line);
            
            if(!line.empty() && line != "\r") {
                std::cout << "Evento: " << line << std::endl;
            }
        }
        
    } catch(std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
    
    return 0;
}
```

### Compilación
```bash
g++ -std=c++17 sse_client_asio.cpp -lpthread -o sse_client
./sse_client
```

### Ventajas
- ✅ Control total sobre la conexión
- ✅ Header-only (opcional)
- ✅ Async I/O nativo

### Desventajas
- ❌ Más código boilerplate
- ❌ Debes manejar HTTP manualmente

---

## Opción 3: cpp-httplib

**La más simple y moderna**

### Instalación
```bash
# Header-only, solo descarga el archivo:
wget https://github.com/yhirose/cpp-httplib/raw/master/httplib.h
```

### Código Completo
```cpp
#include "httplib.h"
#include <iostream>

int main() {
    httplib::Client cli("localhost", 18080);
    
    // Configurar timeout (opcional, 0 = infinito)
    cli.set_read_timeout(0, 0);
    
    // Realizar petición SSE con callback
    auto res = cli.Get("/events", [](const char* data, size_t len) {
        std::string event(data, len);
        std::cout << "Evento recibido: " << event;
        return true; // Continuar recibiendo
    });
    
    if(!res) {
        std::cerr << "Error de conexión" << std::endl;
    }
    
    return 0;
}
```

### Compilación
```bash
g++ -std=c++17 sse_client_httplib.cpp -lpthread -o sse_client
./sse_client
```

### Ventajas
- ✅ Extremadamente simple
- ✅ Header-only
- ✅ API moderna en C++

### Desventajas
- ❌ Menos control fino
- ❌ Menos features que libcurl

---

## Opción 4: Boost.Beast

**HTTP moderno con Boost**

### Instalación
```bash
# Ubuntu/Debian
sudo apt-get install libboost-all-dev

# macOS
brew install boost
```

### Código Completo
```cpp
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <iostream>

namespace beast = boost::beast;
namespace http = beast::http;
namespace net = boost::asio;
using tcp = net::ip::tcp;

int main() {
    try {
        net::io_context ioc;
        tcp::resolver resolver(ioc);
        beast::tcp_stream stream(ioc);
        
        // Conectar
        auto const results = resolver.resolve("localhost", "18080");
        stream.connect(results);
        
        // Construir petición GET
        http::request<http::string_body> req{http::verb::get, "/events", 11};
        req.set(http::field::host, "localhost");
        req.set(http::field::accept, "text/event-stream");
        req.set(http::field::cache_control, "no-cache");
        
        // Enviar petición
        http::write(stream, req);
        
        // Leer respuesta
        beast::flat_buffer buffer;
        http::response<http::string_body> res;
        
        // Leer headers
        http::read_header(stream, buffer, res);
        
        // Leer cuerpo en chunks
        while(true) {
            beast::error_code ec;
            auto bytes = stream.read_some(buffer.prepare(1024), ec);
            
            if(ec == beast::errc::stream_timeout) continue;
            if(ec) break;
            
            buffer.commit(bytes);
            std::string data = beast::buffers_to_string(buffer.data());
            std::cout << "Evento: " << data;
            buffer.consume(bytes);
        }
        
        stream.socket().shutdown(tcp::socket::shutdown_both);
        
    } catch(std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
    }
    
    return 0;
}
```

### Compilación
```bash
g++ -std=c++17 sse_client_beast.cpp -lpthread -o sse_client
./sse_client
```

### Ventajas
- ✅ HTTP/1.1 completo
- ✅ Parte del ecosistema Boost
- ✅ Muy robusto

### Desventajas
- ❌ Dependencia de Boost (pesada)
- ❌ Curva de aprendizaje

---

## Comparación de Opciones

| Librería | Facilidad | Portabilidad | Performance | Dependencias |
|----------|-----------|--------------|-------------|--------------|
| **libcurl** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Ligera |
| **ASIO** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Header-only |
| **cpp-httplib** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | Header-only |
| **Boost.Beast** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Boost (pesada) |

### Recomendaciones

- **Para prototipos rápidos**: cpp-httplib
- **Para producción**: libcurl
- **Para control total**: ASIO
- **Si ya usas Boost**: Boost.Beast

---

## Casos de Uso

### 1. Monitoreo de Logs en Tiempo Real
```cpp
// Cliente que procesa logs del servidor
cli.Get("/logs", [](const char* data, size_t len) {
    parse_log_event(data, len);
    update_dashboard();
    return true;
});
```

### 2. Microservicio Subscriber
```cpp
// Servicio que reacciona a eventos de otro servicio
while(true) {
    auto res = cli.Get("/events", process_event);
    if(!res) reconnect();
}
```

### 3. Sistema IoT
```cpp
// Dispositivo embebido que recibe comandos
cli.Get("/commands", [](const char* data, size_t len) {
    execute_command(parse_command(data));
    return true;
});
```

### 4. Live Analytics
```cpp
// Cliente que agrega métricas en tiempo real
cli.Get("/metrics", [](const char* data, size_t len) {
    update_statistics(parse_metric(data));
    save_to_database();
    return true;
});
```

---

## Parsing de Eventos SSE

Los eventos SSE tienen el formato:
```
event: nombre_evento
data: {"key": "value"}
id: 12345

```

Ejemplo de parser simple:
```cpp
struct SSEEvent {
    std::string event;
    std::string data;
    std::string id;
};

SSEEvent parse_sse(const std::string& raw) {
    SSEEvent evt;
    std::istringstream stream(raw);
    std::string line;
    
    while(std::getline(stream, line)) {
        if(line.find("event:") == 0) {
            evt.event = line.substr(7);
        } else if(line.find("data:") == 0) {
            evt.data = line.substr(6);
        } else if(line.find("id:") == 0) {
            evt.id = line.substr(4);
        }
    }
    
    return evt;
}
```

---

## Conclusión

Sí, **definitivamente puedes crear clientes SSE en C++** sin navegador. La elección de librería depende de:
- Complejidad del proyecto
- Requisitos de portabilidad
- Nivel de control necesario
- Dependencias aceptables

Para la mayoría de casos, **libcurl** o **cpp-httplib** son las mejores opciones por su balance entre simplicidad y funcionalidad.



