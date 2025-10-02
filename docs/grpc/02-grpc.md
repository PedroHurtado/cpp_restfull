# Guía Completa: Uso de gRPC en Proyectos C++

## Introducción

gRPC es un framework de comunicación de alto rendimiento desarrollado por Google que utiliza Protocol Buffers como lenguaje de definición de interfaces y HTTP/2 como protocolo de transporte. Esta guía explica en detalle cómo implementar gRPC en proyectos C++.

---

## 1. Comunicación entre Servicios

gRPC permite la comunicación eficiente entre servicios mediante llamadas a procedimientos remotos (RPC). A diferencia de REST, gRPC utiliza HTTP/2 y Protocol Buffers para lograr mejor rendimiento y comunicación tipada.

### Arquitectura de Comunicación

```
Cliente C++  ────RPC Call───>  Servidor C++
     │                              │
     │                              │
  Stub (Proxy)              Service Implementation
     │                              │
     └──── Protocol Buffers ────────┘
     └────── HTTP/2 ────────────────┘
```

### Ventajas de gRPC

- **Tipado fuerte**: Los contratos están definidos en archivos .proto
- **Multiplexado**: HTTP/2 permite múltiples llamadas simultáneas en una conexión
- **Menor latencia**: Serialización binaria más eficiente que JSON
- **Streaming**: Soporte nativo para streaming unidireccional y bidireccional
- **Multiplataforma**: Clientes y servidores pueden estar en diferentes lenguajes

### Ejemplo de Flujo de Comunicación

```cpp
// Cliente realiza llamada RPC
auto stub = MyService::NewStub(channel);
ClientContext context;
Request request;
Response response;

// Llamada síncrona
Status status = stub->MyMethod(&context, request, &response);

if (status.ok()) {
    // Procesar respuesta
    std::cout << "Respuesta: " << response.message() << std::endl;
}
```

---

## 2. Definición de Servicios en .proto

Los archivos `.proto` definen la interfaz del servicio utilizando Protocol Buffers versión 3.

### Estructura Básica de un Archivo .proto

```protobuf
syntax = "proto3";

package myservice;

// Definición de mensajes
message UserRequest {
    string user_id = 1;
    string name = 2;
    int32 age = 3;
}

message UserResponse {
    string user_id = 1;
    string status = 2;
    string message = 3;
}

// Definición del servicio
service UserService {
    // RPC unario simple
    rpc GetUser (UserRequest) returns (UserResponse);
    
    // RPC con streaming del servidor
    rpc ListUsers (UserRequest) returns (stream UserResponse);
    
    // RPC con streaming del cliente
    rpc CreateUsers (stream UserRequest) returns (UserResponse);
    
    // RPC con streaming bidireccional
    rpc ChatWithUsers (stream UserRequest) returns (stream UserResponse);
}
```

### Tipos de Datos en Protocol Buffers

```protobuf
message DataTypes {
    // Tipos numéricos
    int32 edad = 1;
    int64 timestamp = 2;
    uint32 contador = 3;
    float temperatura = 4;
    double precio = 5;
    
    // Tipos booleanos y string
    bool activo = 6;
    string nombre = 7;
    bytes datos_binarios = 8;
    
    // Arrays (repeated)
    repeated string tags = 9;
    repeated int32 numeros = 10;
    
    // Mapas
    map<string, string> metadatos = 11;
    map<int32, UserInfo> usuarios = 12;
    
    // Mensajes anidados
    Address direccion = 13;
    
    // Enumeraciones
    Status estado = 14;
}

enum Status {
    UNKNOWN = 0;
    ACTIVE = 1;
    INACTIVE = 2;
    SUSPENDED = 3;
}

message Address {
    string calle = 1;
    string ciudad = 2;
    string codigo_postal = 3;
}
```

### Ejemplo Completo: Sistema de Pedidos

```protobuf
syntax = "proto3";

package ecommerce;

import "google/protobuf/timestamp.proto";

// Mensaje de producto
message Product {
    string product_id = 1;
    string name = 2;
    double price = 3;
    int32 stock = 4;
}

// Mensaje de pedido
message Order {
    string order_id = 1;
    string customer_id = 2;
    repeated Product products = 3;
    double total_amount = 4;
    google.protobuf.Timestamp created_at = 5;
    OrderStatus status = 6;
}

enum OrderStatus {
    PENDING = 0;
    PROCESSING = 1;
    SHIPPED = 2;
    DELIVERED = 3;
    CANCELLED = 4;
}

// Mensajes de request/response
message CreateOrderRequest {
    string customer_id = 1;
    repeated string product_ids = 2;
}

message CreateOrderResponse {
    Order order = 1;
    bool success = 2;
    string error_message = 3;
}

message GetOrderRequest {
    string order_id = 1;
}

// Servicio de pedidos
service OrderService {
    rpc CreateOrder (CreateOrderRequest) returns (CreateOrderResponse);
    rpc GetOrder (GetOrderRequest) returns (Order);
    rpc StreamOrders (GetOrderRequest) returns (stream Order);
    rpc UpdateOrderStatus (stream Order) returns (CreateOrderResponse);
}
```

---

## 3. Generar Código con protoc

El compilador `protoc` genera código C++ a partir de archivos .proto.

### Instalación de Herramientas

```bash
# Ubuntu/Debian
sudo apt-get install protobuf-compiler libgrpc++-dev

# macOS
brew install protobuf grpc

# O compilar desde fuente
git clone https://github.com/grpc/grpc.git
cd grpc
git submodule update --init
mkdir -p cmake/build
cd cmake/build
cmake ../..
make
sudo make install
```

### Comando Básico de Generación

```bash
protoc --cpp_out=. --grpc_out=. \
    --plugin=protoc-gen-grpc=`which grpc_cpp_plugin` \
    myservice.proto
```

### Archivos Generados

Al ejecutar protoc, se generan dos archivos por cada .proto:

1. **myservice.pb.h / myservice.pb.cc**: Clases de mensajes Protocol Buffers
2. **myservice.grpc.pb.h / myservice.grpc.pb.cc**: Stubs y clases del servicio gRPC

### Script de Generación Automatizada

```bash
#!/bin/bash
# generate_grpc.sh

PROTO_DIR="./proto"
OUT_DIR="./generated"
PLUGIN_PATH=$(which grpc_cpp_plugin)

mkdir -p $OUT_DIR

for proto_file in $PROTO_DIR/*.proto; do
    echo "Generando código para $proto_file"
    protoc -I=$PROTO_DIR \
        --cpp_out=$OUT_DIR \
        --grpc_out=$OUT_DIR \
        --plugin=protoc-gen-grpc=$PLUGIN_PATH \
        $proto_file
done

echo "Código generado en $OUT_DIR"
```

### Integración con CMake

```cmake
# CMakeLists.txt

cmake_minimum_required(VERSION 3.15)
project(GrpcProject)

set(CMAKE_CXX_STANDARD 17)

# Buscar dependencias
find_package(Protobuf REQUIRED)
find_package(gRPC CONFIG REQUIRED)

# Archivos proto
set(PROTO_FILES
    proto/myservice.proto
    proto/user.proto
)

# Generar código desde .proto
add_library(proto-objects OBJECT ${PROTO_FILES})
target_link_libraries(proto-objects PUBLIC
    protobuf::libprotobuf
    gRPC::grpc++
)

target_include_directories(proto-objects PUBLIC 
    ${CMAKE_CURRENT_BINARY_DIR}
)

# Usar protobuf_generate para generar automáticamente
protobuf_generate(
    TARGET proto-objects
    LANGUAGE cpp
)

protobuf_generate(
    TARGET proto-objects
    LANGUAGE grpc
    GENERATE_EXTENSIONS .grpc.pb.h .grpc.pb.cc
    PLUGIN "protoc-gen-grpc=\$<TARGET_FILE:gRPC::grpc_cpp_plugin>"
)

# Servidor
add_executable(server 
    src/server.cpp
    $<TARGET_OBJECTS:proto-objects>
)
target_link_libraries(server
    protobuf::libprotobuf
    gRPC::grpc++
    gRPC::grpc++_reflection
)

# Cliente
add_executable(client 
    src/client.cpp
    $<TARGET_OBJECTS:proto-objects>
)
target_link_libraries(client
    protobuf::libprotobuf
    gRPC::grpc++
)
```

### Makefile Alternativo

```makefile
# Makefile

CXX = g++
CXXFLAGS = -std=c++17 -Wall -pthread
LDFLAGS = -lprotobuf -lgrpc++ -lgrpc++_reflection

PROTO_DIR = proto
GEN_DIR = generated
SRC_DIR = src

PROTOS = $(wildcard $(PROTO_DIR)/*.proto)
PROTO_SRCS = $(patsubst $(PROTO_DIR)/%.proto,$(GEN_DIR)/%.pb.cc,$(PROTOS))
PROTO_HDRS = $(patsubst $(PROTO_DIR)/%.proto,$(GEN_DIR)/%.pb.h,$(PROTOS))
GRPC_SRCS = $(patsubst $(PROTO_DIR)/%.proto,$(GEN_DIR)/%.grpc.pb.cc,$(PROTOS))
GRPC_HDRS = $(patsubst $(PROTO_DIR)/%.proto,$(GEN_DIR)/%.grpc.pb.h,$(PROTOS))

all: server client

$(GEN_DIR)/%.pb.cc $(GEN_DIR)/%.pb.h: $(PROTO_DIR)/%.proto
	@mkdir -p $(GEN_DIR)
	protoc -I=$(PROTO_DIR) --cpp_out=$(GEN_DIR) $<

$(GEN_DIR)/%.grpc.pb.cc $(GEN_DIR)/%.grpc.pb.h: $(PROTO_DIR)/%.proto
	@mkdir -p $(GEN_DIR)
	protoc -I=$(PROTO_DIR) --grpc_out=$(GEN_DIR) \
		--plugin=protoc-gen-grpc=`which grpc_cpp_plugin` $<

server: $(PROTO_SRCS) $(GRPC_SRCS) $(SRC_DIR)/server.cpp
	$(CXX) $(CXXFLAGS) -I$(GEN_DIR) $^ -o $@ $(LDFLAGS)

client: $(PROTO_SRCS) $(GRPC_SRCS) $(SRC_DIR)/client.cpp
	$(CXX) $(CXXFLAGS) -I$(GEN_DIR) $^ -o $@ $(LDFLAGS)

clean:
	rm -rf $(GEN_DIR) server client

.PHONY: all clean
```

---

## 4. Definición de APIs con Contratos Estrictos

gRPC utiliza contratos estrictos definidos en .proto, garantizando compatibilidad y tipado fuerte.

### Principios de Diseño de APIs

#### 1. Versionado de APIs

```protobuf
syntax = "proto3";

package myservice.v1;  // Versión en el package

service UserServiceV1 {
    rpc GetUser (UserRequest) returns (UserResponse);
}

// Nueva versión con cambios
package myservice.v2;

service UserServiceV2 {
    rpc GetUser (UserRequestV2) returns (UserResponseV2);
    rpc GetUserExtended (UserRequestV2) returns (UserResponseV2Extended);
}
```

#### 2. Evolución de Mensajes (Backward Compatibility)

```protobuf
// Versión 1
message User {
    string id = 1;
    string name = 2;
}

// Versión 2 - Añadir campos al final
message User {
    string id = 1;
    string name = 2;
    string email = 3;        // NUEVO campo
    int32 age = 4;           // NUEVO campo
    repeated string roles = 5; // NUEVO campo
}

// NUNCA cambiar el número de campo ni eliminar campos
// En su lugar, marcar como deprecated
message User {
    string id = 1;
    string name = 2;
    string old_field = 3 [deprecated = true];
    string email = 4;
}
```

#### 3. Uso de Enums para Estados

```protobuf
enum UserStatus {
    // Siempre comenzar con valor 0
    USER_STATUS_UNSPECIFIED = 0;
    USER_STATUS_ACTIVE = 1;
    USER_STATUS_INACTIVE = 2;
    USER_STATUS_SUSPENDED = 3;
    USER_STATUS_DELETED = 4;
}

message User {
    string id = 1;
    string name = 2;
    UserStatus status = 3;
}
```

### Implementación del Servidor

```cpp
#include <grpcpp/grpcpp.h>
#include "myservice.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;

class UserServiceImpl final : public myservice::UserService::Service {
public:
    Status GetUser(ServerContext* context, 
                   const myservice::UserRequest* request,
                   myservice::UserResponse* response) override {
        
        // Validación de entrada
        if (request->user_id().empty()) {
            return Status(grpc::StatusCode::INVALID_ARGUMENT, 
                         "user_id no puede estar vacío");
        }
        
        // Lógica de negocio
        response->set_user_id(request->user_id());
        response->set_status("SUCCESS");
        response->set_message("Usuario encontrado");
        
        return Status::OK;
    }
    
    Status CreateUser(ServerContext* context,
                     const myservice::UserRequest* request,
                     myservice::UserResponse* response) override {
        
        // Validaciones estrictas del contrato
        if (request->name().empty() || request->name().length() < 3) {
            return Status(grpc::StatusCode::INVALID_ARGUMENT,
                         "Nombre debe tener al menos 3 caracteres");
        }
        
        if (request->age() < 0 || request->age() > 150) {
            return Status(grpc::StatusCode::INVALID_ARGUMENT,
                         "Edad inválida");
        }
        
        // Crear usuario
        std::string new_id = generateUserId();
        response->set_user_id(new_id);
        response->set_status("CREATED");
        response->set_message("Usuario creado exitosamente");
        
        return Status::OK;
    }
    
private:
    std::string generateUserId() {
        // Generar ID único
        return "user_" + std::to_string(rand());
    }
};

void RunServer() {
    std::string server_address("0.0.0.0:50051");
    UserServiceImpl service;
    
    ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Servidor escuchando en " << server_address << std::endl;
    server->Wait();
}

int main() {
    RunServer();
    return 0;
}
```

### Implementación del Cliente

```cpp
#include <grpcpp/grpcpp.h>
#include "myservice.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;

class UserServiceClient {
public:
    UserServiceClient(std::shared_ptr<Channel> channel)
        : stub_(myservice::UserService::NewStub(channel)) {}
    
    bool GetUser(const std::string& user_id) {
        myservice::UserRequest request;
        request.set_user_id(user_id);
        
        myservice::UserResponse response;
        ClientContext context;
        
        // Timeout de 5 segundos
        std::chrono::system_clock::time_point deadline =
            std::chrono::system_clock::now() + std::chrono::seconds(5);
        context.set_deadline(deadline);
        
        Status status = stub_->GetUser(&context, request, &response);
        
        if (status.ok()) {
            std::cout << "Usuario: " << response.user_id() << std::endl;
            std::cout << "Status: " << response.status() << std::endl;
            std::cout << "Mensaje: " << response.message() << std::endl;
            return true;
        } else {
            std::cerr << "Error RPC: " << status.error_code() 
                     << " - " << status.error_message() << std::endl;
            return false;
        }
    }
    
    bool CreateUser(const std::string& name, int32_t age) {
        myservice::UserRequest request;
        request.set_name(name);
        request.set_age(age);
        
        myservice::UserResponse response;
        ClientContext context;
        
        Status status = stub_->CreateUser(&context, request, &response);
        
        if (status.ok()) {
            std::cout << "Usuario creado con ID: " << response.user_id() << std::endl;
            return true;
        } else {
            std::cerr << "Error: " << status.error_message() << std::endl;
            return false;
        }
    }
    
private:
    std::unique_ptr<myservice::UserService::Stub> stub_;
};

int main() {
    std::string server_address("localhost:50051");
    
    UserServiceClient client(
        grpc::CreateChannel(server_address, 
                           grpc::InsecureChannelCredentials())
    );
    
    client.GetUser("user123");
    client.CreateUser("Juan Pérez", 30);
    
    return 0;
}
```

### Manejo de Errores con Status Codes

```cpp
Status ValidateAndProcess(const Request* request, Response* response) {
    // Validación de argumentos
    if (request->id().empty()) {
        return Status(grpc::StatusCode::INVALID_ARGUMENT,
                     "ID es requerido");
    }
    
    // Recurso no encontrado
    if (!DatabaseExists(request->id())) {
        return Status(grpc::StatusCode::NOT_FOUND,
                     "Recurso no encontrado");
    }
    
    // Sin autenticación
    if (!IsAuthenticated(context)) {
        return Status(grpc::StatusCode::UNAUTHENTICATED,
                     "Autenticación requerida");
    }
    
    // Sin permisos
    if (!HasPermission(context, request->id())) {
        return Status(grpc::StatusCode::PERMISSION_DENIED,
                     "Permisos insuficientes");
    }
    
    // Recurso agotado
    if (RateLimitExceeded(context)) {
        return Status(grpc::StatusCode::RESOURCE_EXHAUSTED,
                     "Límite de peticiones excedido");
    }
    
    // Error interno
    try {
        ProcessRequest(request, response);
    } catch (const std::exception& e) {
        return Status(grpc::StatusCode::INTERNAL,
                     "Error interno del servidor");
    }
    
    return Status::OK;
}
```

---

## 5. Streaming Bidireccional

gRPC soporta cuatro tipos de comunicación: unario, streaming del servidor, streaming del cliente y streaming bidireccional.

### Tipos de Streaming

```protobuf
service StreamingService {
    // 1. Unario (sin streaming)
    rpc GetData (Request) returns (Response);
    
    // 2. Streaming del servidor
    rpc StreamFromServer (Request) returns (stream Response);
    
    // 3. Streaming del cliente
    rpc StreamToServer (stream Request) returns (Response);
    
    // 4. Streaming bidireccional
    rpc StreamBidirectional (stream Request) returns (stream Response);
}
```

### Ejemplo: Chat en Tiempo Real (Bidireccional)

```protobuf
syntax = "proto3";

package chat;

message ChatMessage {
    string user_id = 1;
    string username = 2;
    string message = 3;
    int64 timestamp = 4;
}

service ChatService {
    rpc JoinChat (stream ChatMessage) returns (stream ChatMessage);
}
```

### Implementación del Servidor con Streaming Bidireccional

```cpp
#include <grpcpp/grpcpp.h>
#include "chat.grpc.pb.h"
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::ServerReaderWriter;
using grpc::Status;

class ChatServiceImpl final : public chat::ChatService::Service {
public:
    Status JoinChat(ServerContext* context,
                   ServerReaderWriter<chat::ChatMessage, chat::ChatMessage>* stream) override {
        
        // Cola de mensajes para este cliente
        std::queue<chat::ChatMessage> message_queue;
        std::mutex queue_mutex;
        std::condition_variable cv;
        bool done = false;
        
        // Thread para recibir mensajes del cliente
        std::thread reader([&]() {
            chat::ChatMessage msg;
            while (stream->Read(&msg)) {
                // Añadir timestamp
                msg.set_timestamp(std::chrono::system_clock::now().time_since_epoch().count());
                
                std::cout << "Recibido de " << msg.username() 
                         << ": " << msg.message() << std::endl;
                
                // Broadcast a todos los clientes conectados
                BroadcastMessage(msg);
            }
            done = true;
            cv.notify_one();
        });
        
        // Thread para enviar mensajes al cliente
        std::thread writer([&]() {
            while (!done) {
                std::unique_lock<std::mutex> lock(queue_mutex);
                cv.wait(lock, [&]() { return !message_queue.empty() || done; });
                
                while (!message_queue.empty()) {
                    chat::ChatMessage msg = message_queue.front();
                    message_queue.pop();
                    
                    if (!stream->Write(msg)) {
                        done = true;
                        break;
                    }
                }
            }
        });
        
        // Suscribir este cliente al broadcast
        auto subscriber = [&](const chat::ChatMessage& msg) {
            std::lock_guard<std::mutex> lock(queue_mutex);
            message_queue.push(msg);
            cv.notify_one();
        };
        
        int client_id = SubscribeClient(subscriber);
        
        reader.join();
        done = true;
        cv.notify_one();
        writer.join();
        
        UnsubscribeClient(client_id);
        
        return Status::OK;
    }
    
private:
    std::mutex clients_mutex_;
    std::map<int, std::function<void(const chat::ChatMessage&)>> clients_;
    int next_client_id_ = 0;
    
    int SubscribeClient(std::function<void(const chat::ChatMessage&)> callback) {
        std::lock_guard<std::mutex> lock(clients_mutex_);
        int id = next_client_id_++;
        clients_[id] = callback;
        return id;
    }
    
    void UnsubscribeClient(int client_id) {
        std::lock_guard<std::mutex> lock(clients_mutex_);
        clients_.erase(client_id);
    }
    
    void BroadcastMessage(const chat::ChatMessage& msg) {
        std::lock_guard<std::mutex> lock(clients_mutex_);
        for (const auto& [id, callback] : clients_) {
            callback(msg);
        }
    }
};
```

### Implementación del Cliente con Streaming Bidireccional

```cpp
#include <grpcpp/grpcpp.h>
#include "chat.grpc.pb.h"
#include <thread>
#include <iostream>

using grpc::Channel;
using grpc::ClientContext;
using grpc::ClientReaderWriter;
using grpc::Status;

class ChatClient {
public:
    ChatClient(std::shared_ptr<Channel> channel, 
               const std::string& username)
        : stub_(chat::ChatService::NewStub(channel))
        , username_(username) {}
    
    void StartChat() {
        ClientContext context;
        std::shared_ptr<ClientReaderWriter<chat::ChatMessage, chat::ChatMessage>> 
            stream(stub_->JoinChat(&context));
        
        // Thread para leer mensajes del servidor
        std::thread reader([stream]() {
            chat::ChatMessage msg;
            while (stream->Read(&msg)) {
                std::cout << "[" << msg.username() << "]: " 
                         << msg.message() << std::endl;
            }
        });
        
        // Thread principal para enviar mensajes
        std::string input;
        while (std::getline(std::cin, input)) {
            if (input == "/quit") {
                break;
            }
            
            chat::ChatMessage msg;
            msg.set_username(username_);
            msg.set_message(input);
            
            if (!stream->Write(msg)) {
                std::cerr << "Error al enviar mensaje" << std::endl;
                break;
            }
        }
        
        stream->WritesDone();
        reader.join();
        
        Status status = stream->Finish();
        if (!status.ok()) {
            std::cerr << "Error en chat: " << status.error_message() << std::endl;
        }
    }
    
private:
    std::unique_ptr<chat::ChatService::Stub> stub_;
    std::string username_;
};

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Uso: " << argv[0] << " <username>" << std::endl;
        return 1;
    }
    
    std::string username = argv[1];
    std::string server_address("localhost:50051");
    
    ChatClient client(
        grpc::CreateChannel(server_address, 
                           grpc::InsecureChannelCredentials()),
        username
    );
    
    std::cout << "Conectado al chat como " << username << std::endl;
    std::cout << "Escribe /quit para salir" << std::endl;
    
    client.StartChat();
    
    return 0;
}
```

### Ejemplo: Streaming del Servidor (Datos en Tiempo Real)

```protobuf
service DataStreamService {
    rpc StreamMetrics (MetricsRequest) returns (stream MetricsData);
}

message MetricsRequest {
    string service_name = 1;
    int32 interval_seconds = 2;
}

message MetricsData {
    string service_name = 1;
    double cpu_usage = 2;
    double memory_usage = 3;
    int64 timestamp = 4;
}
```

```cpp
// Implementación del servidor
Status StreamMetrics(ServerContext* context,
                    const MetricsRequest* request,
                    ServerWriter<MetricsData>* writer) override {
    
    int interval = request->interval_seconds();
    
    for (int i = 0; i < 100; ++i) {  // 100 mediciones
        if (context->IsCancelled()) {
            return Status::CANCELLED;
        }
        
        MetricsData data;
        data.set_service_name(request->service_name());
        data.set_cpu_usage(GetCPUUsage());
        data.set_memory_usage(GetMemoryUsage());
        data.set_timestamp(GetCurrentTimestamp());
        
        if (!writer->Write(data)) {
            break;
        }
        
        std::this_thread::sleep_for(std::chrono::seconds(interval));
    }
    
    return Status::OK;
}

// Implementación del cliente
void ReceiveMetrics(const std::string& service_name) {
    MetricsRequest request;
    request.set_service_name(service_name);
    request.set_interval_seconds(1);
    
    ClientContext context;
    MetricsData data;
    
    std::unique_ptr<ClientReader<MetricsData>> reader(
        stub_->StreamMetrics(&context, request)
    );
    
    while (reader->Read(&data)) {
        std::cout << "CPU: " << data.cpu_usage() << "% "
                 << "Memory: " << data.memory_usage() << "%" << std::endl;
    }
    
    Status status = reader->Finish();
}
```

---

## 6. Seguridad y Rendimiento

### Seguridad en gRPC

#### 1. Autenticación con SSL/TLS

```cpp
// Servidor con SSL/TLS
void RunSecureServer() {
    std::string server_address("0.0.0.0:50051");
    
    // Cargar certificados
    std::string server_cert = ReadFile("server.crt");
    std::string server_key = ReadFile("server.key");
    std::string root_cert = ReadFile("ca.crt");
    
    grpc::SslServerCredentialsOptions ssl_opts;
    ssl_opts.pem_root_certs = root_cert;
    
    grpc::SslServerCredentialsOptions::PemKeyCertPair key_cert_pair;
    key_cert_pair.private_key = server_key;
    key_cert_pair.cert_chain = server_cert;
    ssl_opts.pem_key_cert_pairs.push_back(key_cert_pair);
    
    ServerBuilder builder;
    builder.AddListeningPort(server_address, 
                            grpc::SslServerCredentials(ssl_opts));
    builder.RegisterService(&service);
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    server->Wait();
}

// Cliente con SSL/TLS
std::shared_ptr<Channel> CreateSecureChannel() {
    std::string root_cert = ReadFile("ca.crt");
    
    grpc::SslCredentialsOptions ssl_opts;
    ssl_opts.pem_root_certs = root_cert;
    
    return grpc::CreateChannel(
        "localhost:50051",
        grpc::SslCredentials(ssl_opts)
    );
}

std::string ReadFile(const std::string& filename) {
    std::ifstream file(filename);
    return std::string((std::istreambuf_iterator<char>(file)),
                       std::istreambuf_iterator<char>());
}
```

#### 2. Autenticación con Tokens (JWT)

```cpp
// Interceptor de autenticación en el servidor
class AuthInterceptor : public grpc::experimental::Interceptor {
public:
    void Intercept(grpc::experimental::InterceptorBatchMethods* methods) override {
        if (methods->QueryInterceptionHookPoint(
                grpc::experimental::InterceptionHookPoints::PRE_RECV_INITIAL_METADATA)) {
            
            auto metadata = methods->GetRecvInitialMetadata();
            auto auth_header = metadata->find("authorization");
            
            if (auth_header == metadata->end()) {
                methods->FailCall(grpc::Status(
                    grpc::StatusCode::UNAUTHENTICATED,
                    "Token no proporcionado"
                ));
                return;
            }
            
            std::string token = std::string(
                auth_header->second.data(), 
                auth_header->second.length()
            );
            
            if (!ValidateJWT(token)) {
                methods->FailCall(grpc::Status(
                    grpc::StatusCode::UNAUTHENTICATED,
                    "Token inválido o expirado"
                ));
                return;
            }
        }
        
        methods->Proceed();
    }
    
private:
    bool ValidateJWT(const std::string& token) {
        // Implementar validación JWT
        // Verificar firma, expiración, claims, etc.
        return true;
    }
};

// Cliente añadiendo token JWT
class JWTClient {
public:
    void MakeAuthenticatedCall() {
        ClientContext context;
        
        // Añadir token JWT al header
        context.AddMetadata("authorization", "Bearer " + jwt_token_);
        
        Request request;
        Response response;
        
        Status status = stub_->SecureMethod(&context, request, &response);
        
        if (!status.ok()) {
            std::cerr << "Error: " << status.error_message() << std::endl;
        }
    }
    
private:
    std::string jwt_token_;
};
```

#### 3. Autenticación Mutua (mTLS)

```cpp
// Servidor con autenticación mutua
void RunMutualTLSServer() {
    std::string server_address("0.0.0.0:50051");
    
    std::string server_cert = ReadFile("server.crt");
    std::string server_key = ReadFile("server.key");
    std::string root_cert = ReadFile("ca.crt");
    
    grpc::SslServerCredentialsOptions ssl_opts(
        GRPC_SSL_REQUEST_AND_REQUIRE_CLIENT_CERTIFICATE_AND_VERIFY
    );
    ssl_opts.pem_root_certs = root_cert;
    
    grpc::SslServerCredentialsOptions::PemKeyCertPair key_cert_pair;
    key_cert_pair.private_key = server_key;
    key_cert_pair.cert_chain = server_cert;
    ssl_opts.pem_key_cert_pairs.push_back(key_cert_pair);
    
    ServerBuilder builder;
    builder.AddListeningPort(server_address, 
                            grpc::SslServerCredentials(ssl_opts));
    builder.RegisterService(&service);
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    server->Wait();
}

// Cliente con certificado
std::shared_ptr<Channel> CreateMutualTLSChannel() {
    std::string root_cert = ReadFile("ca.crt");
    std::string client_cert = ReadFile("client.crt");
    std::string client_key = ReadFile("client.key");
    
    grpc::SslCredentialsOptions ssl_opts;
    ssl_opts.pem_root_certs = root_cert;
    ssl_opts.pem_cert_chain = client_cert;
    ssl_opts.pem_private_key = client_key;
    
    return grpc::CreateChannel(
        "localhost:50051",
        grpc::SslCredentials(ssl_opts)
    );
}
```

#### 4. Validación de Entrada

```cpp
Status ValidateInput(const UserRequest* request) {
    // Validar longitud de campos
    if (request->name().length() > 100) {
        return Status(grpc::StatusCode::INVALID_ARGUMENT,
                     "Nombre demasiado largo (máximo 100 caracteres)");
    }
    
    // Validar formato de email
    if (!IsValidEmail(request->email())) {
        return Status(grpc::StatusCode::INVALID_ARGUMENT,
                     "Formato de email inválido");
    }
    
    // Prevenir SQL injection
    if (ContainsSQLInjection(request->query())) {
        return Status(grpc::StatusCode::INVALID_ARGUMENT,
                     "Entrada contiene caracteres no permitidos");
    }
    
    // Validar rangos numéricos
    if (request->age() < 0 || request->age() > 150) {
        return Status(grpc::StatusCode::INVALID_ARGUMENT,
                     "Edad fuera de rango válido");
    }
    
    return Status::OK;
}
```

### Optimización de Rendimiento

#### 1. Connection Pooling y Reutilización de Canales

```cpp
class ChannelPool {
public:
    ChannelPool(const std::string& target, int pool_size) {
        for (int i = 0; i < pool_size; ++i) {
            channels_.push_back(
                grpc::CreateChannel(target, 
                                   grpc::InsecureChannelCredentials())
            );
        }
    }
    
    std::shared_ptr<grpc::Channel> GetChannel() {
        std::lock_guard<std::mutex> lock(mutex_);
        auto channel = channels_[current_index_];
        current_index_ = (current_index_ + 1) % channels_.size();
        return channel;
    }
    
private:
    std::vector<std::shared_ptr<grpc::Channel>> channels_;
    int current_index_ = 0;
    std::mutex mutex_;
};

// Uso
ChannelPool pool("localhost:50051", 10);

void MakeParallelCalls() {
    std::vector<std::thread> threads;
    
    for (int i = 0; i < 100; ++i) {
        threads.emplace_back([&pool]() {
            auto channel = pool.GetChannel();
            auto stub = MyService::NewStub(channel);
            
            ClientContext context;
            Request request;
            Response response;
            
            stub->MyMethod(&context, request, &response);
        });
    }
    
    for (auto& thread : threads) {
        thread.join();
    }
}
```

#### 2. Configuración de Keep-Alive

```cpp
// Configurar keep-alive en el canal
grpc::ChannelArguments args;

// Keep-alive ping cada 10 segundos
args.SetInt(GRPC_ARG_KEEPALIVE_TIME_MS, 10000);

// Timeout para keep-alive ping de 5 segundos
args.SetInt(GRPC_ARG_KEEPALIVE_TIMEOUT_MS, 5000);

// Permitir keep-alive sin llamadas activas
args.SetInt(GRPC_ARG_KEEPALIVE_PERMIT_WITHOUT_CALLS, 1);

// Keep-alive ping por HTTP/2 cada 20 segundos
args.SetInt(GRPC_ARG_HTTP2_BDP_PROBE, 1);

auto channel = grpc::CreateCustomChannel(
    "localhost:50051",
    grpc::InsecureChannelCredentials(),
    args
);
```

#### 3. Compresión de Mensajes

```cpp
// Habilitar compresión en el cliente
ClientContext context;
context.set_compression_algorithm(GRPC_COMPRESS_GZIP);

// O configurar compresión por defecto en el canal
grpc::ChannelArguments args;
args.SetCompressionAlgorithm(GRPC_COMPRESS_GZIP);

auto channel = grpc::CreateCustomChannel(
    "localhost:50051",
    grpc::InsecureChannelCredentials(),
    args
);

// Configurar nivel de compresión
context.set_compression_level(GRPC_COMPRESS_LEVEL_HIGH);
```

#### 4. Configuración de Timeouts y Deadlines

```cpp
// Timeout en cliente
ClientContext context;

// Deadline absoluto
auto deadline = std::chrono::system_clock::now() + 
                std::chrono::seconds(30);
context.set_deadline(deadline);

// O con duración relativa
context.set_deadline(
    std::chrono::system_clock::now() + std::chrono::milliseconds(5000)
);

Status status = stub_->MyMethod(&context, request, &response);

if (status.error_code() == grpc::StatusCode::DEADLINE_EXCEEDED) {
    std::cerr << "Timeout alcanzado" << std::endl;
}
```

#### 5. Llamadas Asíncronas para Mayor Throughput

```cpp
class AsyncClient {
public:
    AsyncClient(std::shared_ptr<Channel> channel)
        : stub_(MyService::NewStub(channel)) {}
    
    void AsyncCall(const Request& request) {
        AsyncClientCall* call = new AsyncClientCall;
        call->response_reader = stub_->AsyncMyMethod(
            &call->context, request, &cq_
        );
        
        call->response_reader->Finish(
            &call->response, &call->status, (void*)call
        );
    }
    
    void AsyncCompleteRpc() {
        void* got_tag;
        bool ok = false;
        
        while (cq_.Next(&got_tag, &ok)) {
            AsyncClientCall* call = static_cast<AsyncClientCall*>(got_tag);
            
            if (call->status.ok()) {
                std::cout << "Respuesta recibida" << std::endl;
            } else {
                std::cerr << "Error: " << call->status.error_message() << std::endl;
            }
            
            delete call;
        }
    }
    
private:
    struct AsyncClientCall {
        Response response;
        ClientContext context;
        Status status;
        std::unique_ptr<ClientAsyncResponseReader<Response>> response_reader;
    };
    
    std::unique_ptr<MyService::Stub> stub_;
    CompletionQueue cq_;
};

// Uso
AsyncClient client(channel);

// Enviar múltiples llamadas sin esperar
for (int i = 0; i < 100; ++i) {
    Request req;
    client.AsyncCall(req);
}

// Procesar respuestas
client.AsyncCompleteRpc();
```

#### 6. Pooling de Threads en el Servidor

```cpp
void RunServerWithThreadPool() {
    std::string server_address("0.0.0.0:50051");
    MyServiceImpl service;
    
    ServerBuilder builder;
    
    // Configurar pool de threads
    grpc::ResourceQuota rq;
    rq.SetMaxThreads(20);  // Máximo 20 threads
    builder.SetResourceQuota(rq);
    
    builder.AddListeningPort(server_address, 
                            grpc::InsecureServerCredentials());
    builder.RegisterService(&service);
    
    // Configurar opciones de rendimiento
    builder.SetMaxReceiveMessageSize(4 * 1024 * 1024);  // 4MB
    builder.SetMaxSendMessageSize(4 * 1024 * 1024);     // 4MB
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Servidor con pool de threads iniciado" << std::endl;
    server->Wait();
}
```

#### 7. Batching de Mensajes

```cpp
// Enviar múltiples requests en un solo stream
Status BatchProcess(const std::vector<Request>& requests,
                   std::vector<Response>& responses) {
    ClientContext context;
    
    std::unique_ptr<ClientReaderWriter<Request, Response>> stream(
        stub_->BatchMethod(&context)
    );
    
    // Enviar todas las requests
    for (const auto& req : requests) {
        if (!stream->Write(req)) {
            break;
        }
    }
    stream->WritesDone();
    
    // Recibir todas las responses
    Response resp;
    while (stream->Read(&resp)) {
        responses.push_back(resp);
    }
    
    return stream->Finish();
}
```

#### 8. Métricas y Monitoreo

```cpp
#include <grpcpp/ext/proto_server_reflection_plugin.h>
#include <grpcpp/health_check_service_interface.h>

class MetricsInterceptor : public grpc::experimental::Interceptor {
public:
    void Intercept(grpc::experimental::InterceptorBatchMethods* methods) override {
        auto start = std::chrono::high_resolution_clock::now();
        
        methods->Proceed();
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
            end - start
        ).count();
        
        std::cout << "Llamada completada en " << duration << "ms" << std::endl;
        
        // Enviar métricas a sistema de monitoreo
        RecordMetric("rpc_duration_ms", duration);
    }
    
private:
    void RecordMetric(const std::string& name, int64_t value) {
        // Implementar envío a Prometheus, Grafana, etc.
    }
};

// Health Check Service
void RunServerWithHealthCheck() {
    std::string server_address("0.0.0.0:50051");
    MyServiceImpl service;
    
    grpc::EnableDefaultHealthCheckService(true);
    grpc::reflection::InitProtoReflectionServerBuilderPlugin();
    
    ServerBuilder builder;
    builder.AddListeningPort(server_address, 
                            grpc::InsecureServerCredentials());
    builder.RegisterService(&service);
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    server->Wait();
}
```

#### 9. Rate Limiting

```cpp
class RateLimiter {
public:
    RateLimiter(int max_requests_per_second) 
        : max_requests_(max_requests_per_second) {}
    
    bool AllowRequest(const std::string& client_id) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        auto now = std::chrono::steady_clock::now();
        auto& client_data = clients_[client_id];
        
        // Limpiar requests antiguos (más de 1 segundo)
        while (!client_data.timestamps.empty() &&
               std::chrono::duration_cast<std::chrono::seconds>(
                   now - client_data.timestamps.front()
               ).count() >= 1) {
            client_data.timestamps.pop();
        }
        
        // Verificar límite
        if (client_data.timestamps.size() >= max_requests_) {
            return false;
        }
        
        client_data.timestamps.push(now);
        return true;
    }
    
private:
    struct ClientData {
        std::queue<std::chrono::steady_clock::time_point> timestamps;
    };
    
    std::unordered_map<std::string, ClientData> clients_;
    int max_requests_;
    std::mutex mutex_;
};

// Uso en el servidor
class RateLimitedServiceImpl : public MyService::Service {
public:
    RateLimitedServiceImpl() : rate_limiter_(100) {}  // 100 req/s
    
    Status MyMethod(ServerContext* context,
                   const Request* request,
                   Response* response) override {
        
        std::string client_id = GetClientId(context);
        
        if (!rate_limiter_.AllowRequest(client_id)) {
            return Status(grpc::StatusCode::RESOURCE_EXHAUSTED,
                         "Límite de peticiones excedido");
        }
        
        // Procesar request normal
        return Status::OK;
    }
    
private:
    RateLimiter rate_limiter_;
    
    std::string GetClientId(ServerContext* context) {
        auto metadata = context->client_metadata();
        auto it = metadata.find("client-id");
        if (it != metadata.end()) {
            return std::string(it->second.data(), it->second.length());
        }
        return context->peer();  // Usar IP como fallback
    }
};
```

### Mejores Prácticas de Rendimiento

#### Resumen de Optimizaciones

1. **Reutilizar canales**: No crear un canal nuevo por cada llamada
2. **Pool de conexiones**: Mantener múltiples canales para alta concurrencia
3. **Keep-alive**: Evitar overhead de reconexiones
4. **Compresión**: Usar GZIP para mensajes grandes (>1KB)
5. **Llamadas asíncronas**: Para operaciones de alta latencia
6. **Batching**: Agrupar múltiples requests cuando sea posible
7. **Streaming**: Usar streaming para grandes volúmenes de datos
8. **Timeouts apropiados**: Evitar esperas indefinidas
9. **Tamaño de mensajes**: Limitar tamaño máximo de mensajes
10. **Rate limiting**: Proteger el servidor de sobrecarga

---

## Conclusión

gRPC es una tecnología poderosa para construir sistemas distribuidos eficientes y escalables. Las características clave incluyen:

- **Comunicación eficiente** mediante Protocol Buffers y HTTP/2
- **Contratos estrictos** que garantizan compatibilidad entre servicios
- **Streaming bidireccional** para aplicaciones en tiempo real
- **Seguridad robusta** con SSL/TLS y autenticación
- **Alto rendimiento** con optimizaciones avanzadas

### Recursos Adicionales

- Documentación oficial: https://grpc.io/docs/languages/cpp/
- Protocol Buffers: https://protobuf.dev/
- Ejemplos de gRPC C++: https://github.com/grpc/grpc/tree/master/examples/cpp
- Best practices: https://grpc.io/docs/guides/performance/

### Siguiente Pasos

1. Implementar un servicio básico siguiendo los ejemplos
2. Añadir SSL/TLS para seguridad
3. Implementar streaming para casos de uso específicos
4. Optimizar rendimiento según necesidades
5. Añadir monitoreo y métricas
6. Implementar manejo robusto de errores

