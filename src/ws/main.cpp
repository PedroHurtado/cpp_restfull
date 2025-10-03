#include "crow.h"
#include <unordered_set>
#include <mutex>

int main() {
    crow::SimpleApp app;
    
    std::unordered_set<crow::websocket::connection*> users;
    std::mutex mtx;

    // Configurar directorio de templates
    crow::mustache::set_base("templates");

    // Servir página HTML estática desde "/"
    CROW_ROUTE(app, "/")
    ([](){
        auto page = crow::mustache::load_text("index.html");
        return page;
    });

    // Endpoint WebSocket
    CROW_ROUTE(app, "/ws")
      .websocket(&app)
      .onopen([&](crow::websocket::connection& conn){
          std::lock_guard<std::mutex> lock(mtx);
          users.insert(&conn);
          CROW_LOG_INFO << "Cliente conectado. Total: " << users.size();
      })
      .onclose([&](crow::websocket::connection& conn, const std::string& reason){
          std::lock_guard<std::mutex> lock(mtx);
          users.erase(&conn);
          CROW_LOG_INFO << "Cliente desconectado. Total: " << users.size();
      })
      .onmessage([&](crow::websocket::connection& conn, const std::string& data, bool is_binary){
          std::lock_guard<std::mutex> lock(mtx);
          // Broadcast: enviar mensaje a todos los clientes conectados
          for(auto u : users) {
              if(is_binary)
                  u->send_binary(data);
              else
                  u->send_text(data);
          }
      });

    app.port(8080).multithreaded().run();
}