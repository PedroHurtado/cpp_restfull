#include "crow.h"
#include <thread>
#include <atomic>
#include <chrono>
#include <sstream>
#include <vector>
#include <mutex>
#include <ctime>

// Manejador de conexiones SSE
class SSEManager {
private:
    std::vector<crow::response*> clients;
    std::mutex clients_mutex;
    std::atomic<bool> running{true};
    std::thread broadcast_thread;

public:
    SSEManager() {
        // Hilo que envía eventos cada segundo
        broadcast_thread = std::thread([this]() {
            int counter = 0;
            while(running) {
                broadcast_event("counter", std::to_string(counter++));
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        });
    }

    ~SSEManager() {
        running = false;
        if(broadcast_thread.joinable()) {
            broadcast_thread.join();
        }
    }

    void add_client(crow::response* res) {
        
        std::lock_guard<std::mutex> lock(clients_mutex);
        clients.push_back(res);
    }

    void remove_client(crow::response* res) {
        std::lock_guard<std::mutex> lock(clients_mutex);
        clients.erase(
            std::remove(clients.begin(), clients.end(), res),
            clients.end()
        );
    }

    void broadcast_event(const std::string& event, const std::string& data) {
        std::lock_guard<std::mutex> lock(clients_mutex);
        
        std::ostringstream oss;
        oss << "event: " << event << "\n"
            << "data: " << data << "\n"
            << "id: " << std::time(nullptr) << "\n\n";
        
        std::string message = oss.str();
        
        // Enviar a todos los clientes conectados
        for(auto* client : clients) {
            try {
                client->write(message);
            } catch(...) {
                // Cliente desconectado
            }
        }
    }
};

int main() {
    crow::SimpleApp app;
    SSEManager sse_manager;

    // Endpoint para servir el HTML
    CROW_ROUTE(app, "/")
    ([]() {
        auto page = crow::response(R"html(
<!DOCTYPE html>
<html>
<head>
    <title>SSE Real-Time Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .event-box {
            background: #e3f2fd;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
            border-left: 4px solid #2196f3;
        }
        .counter {
            font-size: 48px;
            color: #2196f3;
            text-align: center;
            margin: 20px 0;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
        }
        .connected { background: #4caf50; color: white; }
        .disconnected { background: #f44336; color: white; }
        #events {
            max-height: 300px;
            overflow-y: auto;
            margin-top: 20px;
        }
        button {
            background: #2196f3;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 5px;
        }
        button:hover { background: #1976d2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server-Sent Events en Tiempo Real</h1>
        
        <div>
            Estado: <span id="status" class="status disconnected">Desconectado</span>
        </div>
        
        <div class="counter" id="counter">0</div>
        
        <div>
            <button onclick="sendCustomEvent()">Enviar Evento Personalizado</button>
            <button onclick="reconnect()">Reconectar</button>
        </div>
        
        <h3>Log de Eventos:</h3>
        <div id="events"></div>
    </div>

    <script>
        let eventSource;
        const statusEl = document.getElementById('status');
        const counterEl = document.getElementById('counter');
        const eventsEl = document.getElementById('events');

        function connect() {
            eventSource = new EventSource('/events');
            
            eventSource.onopen = function() {
                statusEl.textContent = 'Conectado';
                statusEl.className = 'status connected';
                addLog('Conexion establecida');
            };

            eventSource.onerror = function() {
                statusEl.textContent = 'Desconectado';
                statusEl.className = 'status disconnected';
                addLog('Error de conexion');
            };

            eventSource.addEventListener('counter', function(e) {
                counterEl.textContent = e.data;
                addLog('Counter: ' + e.data);
            });

            eventSource.addEventListener('custom', function(e) {
                addLog('Evento personalizado: ' + e.data);
            });

            eventSource.onmessage = function(e) {
                addLog('Mensaje: ' + e.data);
            };
        }

        function addLog(message) {
            const div = document.createElement('div');
            div.className = 'event-box';
            const time = new Date().toLocaleTimeString();
            div.textContent = '[' + time + '] ' + message;
            eventsEl.insertBefore(div, eventsEl.firstChild);
            
            while(eventsEl.children.length > 10) {
                eventsEl.removeChild(eventsEl.lastChild);
            }
        }

        function sendCustomEvent() {
            fetch('/trigger-event', { method: 'POST' })
                .then(function() { 
                    addLog('Evento personalizado enviado'); 
                });
        }

        function reconnect() {
            if(eventSource) eventSource.close();
            connect();
        }

        connect();
    </script>
</body>
</html>
)html");
        page.set_header("Content-Type", "text/html");
        return page;
    });

    // Endpoint SSE
    CROW_ROUTE(app, "/events")
    ([&sse_manager](const crow::request& req, crow::response& res) {
        res.set_header("Content-Type", "text/event-stream");
        res.set_header("Cache-Control", "no-cache");
        res.set_header("Connection", "keep-alive");
        res.set_header("Access-Control-Allow-Origin", "*");
        
        // Agregar cliente
        sse_manager.add_client(&res);
        
        // Enviar mensaje inicial
        res.write("event: message\ndata: Conectado al servidor SSE\n\n");
        
        // Mantener la conexión abierta
        //res.end();
    });

    // Endpoint para disparar eventos personalizados
    CROW_ROUTE(app, "/trigger-event").methods("POST"_method)
    ([&sse_manager](const crow::request& req) {
        sse_manager.broadcast_event("custom", "Evento disparado por el usuario!");
        return crow::response(200, "OK");
    });

    std::cout << "Servidor SSE iniciado en http://localhost:18080\n";
    std::cout << "Abre tu navegador y visita la URL\n";
    
    app.port(8080).multithreaded().run();
    
    return 0;
}