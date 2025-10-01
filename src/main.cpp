#include "crow.h"
#include <string>
#include <vector>
#include <mutex>
#include "custom_route.hpp"

// Estructura para representar una Tarea
struct Tarea {
    int id;
    std::string titulo;
    std::string descripcion;
    bool completada;

    crow::json::wvalue toJson() const {
        crow::json::wvalue json;
        json["id"] = id;
        json["titulo"] = titulo;
        json["descripcion"] = descripcion;
        json["completada"] = completada;
        return json;
    }
};

// Base de datos en memoria
class TareasDB {
private:
    std::vector<Tarea> tareas;
    int siguiente_id;
    std::mutex mtx;

public:
    TareasDB() : siguiente_id(1) {
        // Datos de ejemplo
        tareas.push_back({siguiente_id++, "Aprender Crow", "Crear una API REST con C++", false});
        tareas.push_back({siguiente_id++, "Hacer ejercicio", "Correr 5km", true});
    }

    Tarea crear(const std::string& titulo, const std::string& descripcion) {
        std::lock_guard<std::mutex> lock(mtx);
        Tarea nueva = {siguiente_id++, titulo, descripcion, false};
        tareas.push_back(nueva);
        return nueva;
    }

    std::vector<Tarea> obtenerTodas() {
        std::lock_guard<std::mutex> lock(mtx);
        return tareas;
    }

    std::pair<bool, Tarea> obtenerPorId(int id) {
        std::lock_guard<std::mutex> lock(mtx);
        for (const auto& tarea : tareas) {
            if (tarea.id == id) {
                return {true, tarea};
            }
        }
        return {false, {}};
    }

    bool actualizar(int id, const std::string& titulo, const std::string& descripcion, bool completada) {
        std::lock_guard<std::mutex> lock(mtx);
        for (auto& tarea : tareas) {
            if (tarea.id == id) {
                tarea.titulo = titulo;
                tarea.descripcion = descripcion;
                tarea.completada = completada;
                return true;
            }
        }
        return false;
    }

    bool eliminar(int id) {
        std::lock_guard<std::mutex> lock(mtx);
        for (auto it = tareas.begin(); it != tareas.end(); ++it) {
            if (it->id == id) {
                tareas.erase(it);
                return true;
            }
        }
        return false;
    }
};

int main() {
    crow::App<AuthenticationMiddleware> app;;    
    TareasDB db;

     // Esta es TODA la solución que necesitas
    app.exception_handler([](crow::response& res) {
        try {
            throw;  // Re-lanza la excepción actual
        }
        catch (const std::exception& e) {
            CROW_LOG_ERROR << "Exception: " << e.what();
            res.code = 500;
            res.set_header("Content-Type", "application/json");
            res.write(crow::json::wvalue{
                {"error", "Internal Server Error"},
                {"message", e.what()}
            }.dump());
            res.end();
        }
        catch (...) {
            CROW_LOG_ERROR << "Unknown exception";
            res.code = 500;
            res.set_header("Content-Type", "application/json");
            res.write(crow::json::wvalue{
                {"error", "Internal Server Error"},
                {"message", "Unknown error occurred"}
            }.dump());
            res.end();
        }
    });

    APP_ROUTE(app, "/test")
    //.allow_anonymous()
    ([]() {
        throw std::runtime_error("Boom!");
        return "Never reached";
    });


    // GET /api/tareas - Obtener todas las tareas
    CROW_ROUTE(app, "/api/tareas")
    .methods("GET"_method)
    ([&db]() {
        auto tareas = db.obtenerTodas();
        crow::json::wvalue respuesta;
        respuesta["total"] = tareas.size();
        
        std::vector<crow::json::wvalue> json_tareas;
        for (const auto& tarea : tareas) {
            json_tareas.push_back(tarea.toJson());
        }
        respuesta["tareas"] = std::move(json_tareas);
        
        return crow::response(200, respuesta);
    });

    // GET /api/tareas/:id - Obtener una tarea por ID
    CROW_ROUTE(app, "/api/tareas/<int>")
    .methods("GET"_method)
    ([&db](int id) {
        auto [encontrada, tarea] = db.obtenerPorId(id);
        
        if (!encontrada) {
            crow::json::wvalue error;
            error["error"] = "Tarea no encontrada";
            return crow::response(404, error);
        }
        
        return crow::response(200, tarea.toJson());
    });

    // POST /api/tareas - Crear una nueva tarea
    CROW_ROUTE(app, "/api/tareas")
    .methods("POST"_method)
    ([&db](const crow::request& req) {
        auto json = crow::json::load(req.body);
        
        if (!json) {
            crow::json::wvalue error;
            error["error"] = "JSON inválido";
            return crow::response(400, error);
        }
        
        if (!json.has("titulo")) {
            crow::json::wvalue error;
            error["error"] = "El campo 'titulo' es requerido";
            return crow::response(400, error);
        }
        
        std::string titulo = json["titulo"].s();
        std::string descripcion = json.has("descripcion") ? std::string(json["descripcion"].s()) : std::string("");
        
        Tarea nueva = db.crear(titulo, descripcion);
        
        crow::json::wvalue respuesta;
        respuesta["mensaje"] = "Tarea creada exitosamente";
        respuesta["tarea"] = nueva.toJson();
        
        return crow::response(201, respuesta);
    });

    // PUT /api/tareas/:id - Actualizar una tarea
    CROW_ROUTE(app, "/api/tareas/<int>")
    .methods("PUT"_method)
    ([&db](const crow::request& req, int id) {
        auto json = crow::json::load(req.body);
        
        if (!json) {
            crow::json::wvalue error;
            error["error"] = "JSON inválido";
            return crow::response(400, error);
        }
        
        if (!json.has("titulo") || !json.has("descripcion") || !json.has("completada")) {
            crow::json::wvalue error;
            error["error"] = "Faltan campos requeridos: titulo, descripcion, completada";
            return crow::response(400, error);
        }
        
        std::string titulo = json["titulo"].s();
        std::string descripcion = json["descripcion"].s();
        bool completada = json["completada"].b();
        
        bool actualizada = db.actualizar(id, titulo, descripcion, completada);
        
        if (!actualizada) {
            crow::json::wvalue error;
            error["error"] = "Tarea no encontrada";
            return crow::response(404, error);
        }
        
        return crow::response(204);
    });

    // DELETE /api/tareas/:id - Eliminar una tarea
    CROW_ROUTE(app, "/api/tareas/<int>")
    .methods("DELETE"_method)
    
    ([&db](int id) {
        bool eliminada = db.eliminar(id);
        
        if (!eliminada) {
            crow::json::wvalue error;
            error["error"] = "Tarea no encontrada";
            return crow::response(404, error);
        }
        
        return crow::response(204);
    });

    std::cout << "API REST corriendo en http://localhost:8080\n";
    
    app.port(8080).multithreaded().run();
    
    return 0;
}