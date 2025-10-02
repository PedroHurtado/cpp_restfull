# Guía Completa de gRPC para C++

## 1. Instalación de gRPC

### Opción A: Instalación desde código fuente (Recomendada)

```bash
# Instalar dependencias
sudo apt-get install build-essential autoconf libtool pkg-config cmake git

# Clonar el repositorio
git clone --recurse-submodules -b v1.60.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc
cd grpc

# Crear directorio de build
mkdir -p cmake/build
cd cmake/build

# Configurar con CMake
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      ../..

# Compilar e instalar (esto puede tardar)
make -j$(nproc)
sudo make install
```

### Opción B: Instalación con vcpkg (Windows/Linux/macOS)

```bash
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh
./vcpkg install grpc
```

### Opción C: Instalación con package manager (Ubuntu/Debian)

```bash
sudo apt-get install -y protobuf-compiler-grpc libgrpc++-dev
```

## 2. Estructura de Carpetas Recomendada

```
mi_proyecto/
├── Makefile
├── CMakeLists.txt
├── proto/
│   └── mi_servicio.proto
├── src/
│   ├── client.cpp
│   └── server.cpp
├── include/
│   └── (headers generados automáticamente)
├── build/
│   └── (archivos compilados)
└── bin/
    └── (ejecutables)
```

## 3. Archivo Proto de Ejemplo

**proto/mi_servicio.proto:**
```protobuf
syntax = "proto3";

package miservicio;

service MiServicio {
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  rpc SayGoodbye (GoodbyeRequest) returns (GoodbyeReply) {}
}

message HelloRequest {
  string name = 1;
}

message HelloReply {
  string message = 1;
}

message GoodbyeRequest {
  string name = 1;
}

message GoodbyeReply {
  string message = 1;
}
```

## 4. Makefile Completo

**Makefile:**
```makefile
# Compilador y flags
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
LDFLAGS = $(shell pkg-config --libs protobuf grpc++ grpc)
CPPFLAGS = $(shell pkg-config --cflags protobuf grpc++)

# Directorios
PROTO_DIR = proto
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin
PROTO_BUILD_DIR = $(BUILD_DIR)/proto

# Herramientas
PROTOC = protoc
GRPC_CPP_PLUGIN = grpc_cpp_plugin
GRPC_CPP_PLUGIN_PATH = $(shell which $(GRPC_CPP_PLUGIN))

# Archivos proto
PROTO_FILES = $(wildcard $(PROTO_DIR)/*.proto)
PROTO_NAMES = $(basename $(notdir $(PROTO_FILES)))

# Archivos generados
PROTO_SRCS = $(patsubst %,$(PROTO_BUILD_DIR)/%.pb.cc,$(PROTO_NAMES))
PROTO_HDRS = $(patsubst %,$(PROTO_BUILD_DIR)/%.pb.h,$(PROTO_NAMES))
GRPC_SRCS = $(patsubst %,$(PROTO_BUILD_DIR)/%.grpc.pb.cc,$(PROTO_NAMES))
GRPC_HDRS = $(patsubst %,$(PROTO_BUILD_DIR)/%.grpc.pb.h,$(PROTO_NAMES))

# Archivos objeto
PROTO_OBJS = $(patsubst %.cc,%.o,$(PROTO_SRCS))
GRPC_OBJS = $(patsubst %.cc,%.o,$(GRPC_SRCS))

# Ejecutables
SERVER_EXEC = $(BIN_DIR)/server
CLIENT_EXEC = $(BIN_DIR)/client

# Targets
.PHONY: all clean proto server client run-server run-client dirs

all: dirs proto server client

# Crear directorios necesarios
dirs:
	@mkdir -p $(BUILD_DIR) $(BIN_DIR) $(PROTO_BUILD_DIR)

# Generar código desde proto
proto: dirs $(PROTO_SRCS) $(GRPC_SRCS)

$(PROTO_BUILD_DIR)/%.pb.cc $(PROTO_BUILD_DIR)/%.pb.h: $(PROTO_DIR)/%.proto
	$(PROTOC) --cpp_out=$(PROTO_BUILD_DIR) \
	          --grpc_out=$(PROTO_BUILD_DIR) \
	          --plugin=protoc-gen-grpc=$(GRPC_CPP_PLUGIN_PATH) \
	          -I $(PROTO_DIR) $<

# Compilar archivos objeto proto
$(PROTO_BUILD_DIR)/%.pb.o: $(PROTO_BUILD_DIR)/%.pb.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -I$(PROTO_BUILD_DIR) -c $< -o $@

$(PROTO_BUILD_DIR)/%.grpc.pb.o: $(PROTO_BUILD_DIR)/%.grpc.pb.cc
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -I$(PROTO_BUILD_DIR) -c $< -o $@

# Compilar servidor
server: proto $(PROTO_OBJS) $(GRPC_OBJS)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -I$(PROTO_BUILD_DIR) \
	       $(SRC_DIR)/server.cpp $(PROTO_OBJS) $(GRPC_OBJS) \
	       $(LDFLAGS) -o $(SERVER_EXEC)

# Compilar cliente
client: proto $(PROTO_OBJS) $(GRPC_OBJS)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -I$(PROTO_BUILD_DIR) \
	       $(SRC_DIR)/client.cpp $(PROTO_OBJS) $(GRPC_OBJS) \
	       $(LDFLAGS) -o $(CLIENT_EXEC)

# Ejecutar servidor
run-server: server
	@echo "Iniciando servidor..."
	$(SERVER_EXEC)

# Ejecutar cliente
run-client: client
	@echo "Ejecutando cliente..."
	$(CLIENT_EXEC)

# Limpiar archivos generados
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

# Limpiar solo proto generado
clean-proto:
	rm -rf $(PROTO_BUILD_DIR)

# Ayuda
help:
	@echo "Targets disponibles:"
	@echo "  all         - Compilar todo (default)"
	@echo "  proto       - Generar código desde archivos .proto"
	@echo "  server      - Compilar servidor"
	@echo "  client      - Compilar cliente"
	@echo "  run-server  - Compilar y ejecutar servidor"
	@echo "  run-client  - Compilar y ejecutar cliente"
	@echo "  clean       - Limpiar todos los archivos generados"
	@echo "  clean-proto - Limpiar solo archivos proto generados"
	@echo "  help        - Mostrar esta ayuda"
```

## 5. CMakeLists.txt (Alternativa)

**CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.15)
project(MiProyectoGRPC)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Encontrar paquetes necesarios
find_package(Threads REQUIRED)
find_package(Protobuf REQUIRED)
find_package(gRPC CONFIG REQUIRED)

# Directorio de archivos proto
set(PROTO_PATH "${CMAKE_CURRENT_SOURCE_DIR}/proto")
set(PROTO_FILE "${PROTO_PATH}/mi_servicio.proto")

# Archivos generados
set(PROTO_SRCS "${CMAKE_CURRENT_BINARY_DIR}/mi_servicio.pb.cc")
set(PROTO_HDRS "${CMAKE_CURRENT_BINARY_DIR}/mi_servicio.pb.h")
set(GRPC_SRCS "${CMAKE_CURRENT_BINARY_DIR}/mi_servicio.grpc.pb.cc")
set(GRPC_HDRS "${CMAKE_CURRENT_BINARY_DIR}/mi_servicio.grpc.pb.h")

# Generar código desde proto
add_custom_command(
    OUTPUT "${PROTO_SRCS}" "${PROTO_HDRS}" "${GRPC_SRCS}" "${GRPC_HDRS}"
    COMMAND protobuf::protoc
    ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
         --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
         -I "${PROTO_PATH}"
         --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
         "${PROTO_FILE}"
    DEPENDS "${PROTO_FILE}"
)

# Crear biblioteca con código generado
add_library(proto_lib ${PROTO_SRCS} ${GRPC_SRCS})
target_link_libraries(proto_lib
    gRPC::grpc++
    protobuf::libprotobuf
)
target_include_directories(proto_lib PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

# Ejecutables
add_executable(server src/server.cpp)
target_link_libraries(server proto_lib gRPC::grpc++ protobuf::libprotobuf)

add_executable(client src/client.cpp)
target_link_libraries(client proto_lib gRPC::grpc++ protobuf::libprotobuf)
```

## 6. Código Fuente C++

### src/server.cpp

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <grpcpp/grpcpp.h>
#include "mi_servicio.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using miservicio::MiServicio;
using miservicio::HelloRequest;
using miservicio::HelloReply;
using miservicio::GoodbyeRequest;
using miservicio::GoodbyeReply;

class MiServicioImpl final : public MiServicio::Service {
    Status SayHello(ServerContext* context, 
                    const HelloRequest* request,
                    HelloReply* reply) override {
        std::string prefix("Hola, ");
        reply->set_message(prefix + request->name());
        std::cout << "Solicitud recibida: " << request->name() << std::endl;
        return Status::OK;
    }

    Status SayGoodbye(ServerContext* context,
                      const GoodbyeRequest* request,
                      GoodbyeReply* reply) override {
        std::string prefix("Adiós, ");
        reply->set_message(prefix + request->name());
        std::cout << "Despedida recibida: " << request->name() << std::endl;
        return Status::OK;
    }
};

void RunServer() {
    std::string server_address("0.0.0.0:50051");
    MiServicioImpl service;

    ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);
    
    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Servidor escuchando en " << server_address << std::endl;
    server->Wait();
}

int main(int argc, char** argv) {
    RunServer();
    return 0;
}
```

### src/client.cpp

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <grpcpp/grpcpp.h>
#include "mi_servicio.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using miservicio::MiServicio;
using miservicio::HelloRequest;
using miservicio::HelloReply;
using miservicio::GoodbyeRequest;
using miservicio::GoodbyeReply;

class MiServicioClient {
public:
    MiServicioClient(std::shared_ptr<Channel> channel)
        : stub_(MiServicio::NewStub(channel)) {}

    std::string SayHello(const std::string& name) {
        HelloRequest request;
        request.set_name(name);

        HelloReply reply;
        ClientContext context;

        Status status = stub_->SayHello(&context, request, &reply);

        if (status.ok()) {
            return reply.message();
        } else {
            std::cout << "Error: " << status.error_code() << ": " 
                      << status.error_message() << std::endl;
            return "RPC failed";
        }
    }

    std::string SayGoodbye(const std::string& name) {
        GoodbyeRequest request;
        request.set_name(name);

        GoodbyeReply reply;
        ClientContext context;

        Status status = stub_->SayGoodbye(&context, request, &reply);

        if (status.ok()) {
            return reply.message();
        } else {
            std::cout << "Error: " << status.error_code() << ": " 
                      << status.error_message() << std::endl;
            return "RPC failed";
        }
    }

private:
    std::unique_ptr<MiServicio::Stub> stub_;
};

int main(int argc, char** argv) {
    std::string target_str = "localhost:50051";
    MiServicioClient client(
        grpc::CreateChannel(target_str, grpc::InsecureChannelCredentials())
    );

    std::string user("Mundo");
    std::string reply = client.SayHello(user);
    std::cout << "Cliente recibió: " << reply << std::endl;

    reply = client.SayGoodbye(user);
    std::cout << "Cliente recibió: " << reply << std::endl;

    return 0;
}
```

## 7. Comandos de Compilación

### Usando Makefile:

```bash
# Compilar todo
make

# Compilar solo servidor
make server

# Compilar solo cliente
make client

# Ejecutar servidor (en una terminal)
make run-server

# Ejecutar cliente (en otra terminal)
make run-client

# Limpiar archivos compilados
make clean

# Ver ayuda
make help
```

### Usando CMake:

```bash
# Crear directorio de build
mkdir build
cd build

# Configurar proyecto
cmake ..

# Compilar
make -j$(nproc)

# Ejecutar
./server    # En una terminal
./client    # En otra terminal
```

### Compilación Manual:

```bash
# Crear directorios
mkdir -p build/proto bin

# Generar código proto
protoc --cpp_out=build/proto --grpc_out=build/proto \
       --plugin=protoc-gen-grpc=$(which grpc_cpp_plugin) \
       -I proto proto/mi_servicio.proto

# Compilar servidor
g++ -std=c++17 src/server.cpp \
    build/proto/mi_servicio.pb.cc \
    build/proto/mi_servicio.grpc.pb.cc \
    -o bin/server \
    -Ibuild/proto \
    $(pkg-config --cflags --libs protobuf grpc++ grpc)

# Compilar cliente
g++ -std=c++17 src/client.cpp \
    build/proto/mi_servicio.pb.cc \
    build/proto/mi_servicio.grpc.pb.cc \
    -o bin/client \
    -Ibuild/proto \
    $(pkg-config --cflags --libs protobuf grpc++ grpc)
```

## 8. Verificar Instalación

```bash
# Verificar protoc
protoc --version

# Verificar grpc_cpp_plugin
which grpc_cpp_plugin

# Verificar librerías instaladas
pkg-config --libs grpc++
pkg-config --cflags grpc++

# Verificar versión de gRPC
pkg-config --modversion grpc++
```

## 9. Solución de Problemas Comunes

### Error: protoc no encontrado
```bash
# Instalar protobuf compiler
sudo apt-get install protobuf-compiler
```

### Error: grpc_cpp_plugin no encontrado
```bash
# Verificar instalación
sudo apt-get install protobuf-compiler-grpc

# O encontrar la ubicación
find /usr -name grpc_cpp_plugin 2>/dev/null
```

### Error: pkg-config no encuentra grpc++
```bash
# Agregar al PKG_CONFIG_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# O reinstalar gRPC con cmake install
```

### Error de linking
```bash
# Verificar que las bibliotecas estén instaladas
ldconfig -p | grep grpc
ldconfig -p | grep protobuf
```

## 10. Recursos Adicionales

- [Documentación oficial de gRPC](https://grpc.io/docs/languages/cpp/)
- [Tutoriales de gRPC C++](https://grpc.io/docs/languages/cpp/quickstart/)
- [Protocol Buffers Guide](https://protobuf.dev/programming-guides/proto3/)
- [Ejemplos de gRPC](https://github.com/grpc/grpc/tree/master/examples/cpp)

## 11. Tips y Mejores Prácticas

1. **Usar compilación incremental**: El Makefile ya está configurado para solo recompilar lo necesario
2. **Separar proto en bibliotecas**: Para proyectos grandes, crear librerías compartidas
3. **Usar namespace**: Siempre definir package en archivos .proto
4. **Gestión de errores**: Implementar manejo robusto de Status codes
5. **Autenticación**: Usar SSL/TLS en producción en lugar de InsecureCredentials
6. **Logging**: Integrar sistema de logs para debugging
7. **Testing**: Crear pruebas unitarias para servicios gRPC