#include "crow.h"
#include <unordered_set>
#include <string>
#include <memory>

// ============================================================================
// Sistema de rutas anónimas
// ============================================================================

class AnonymousRouteRegistry
{
private:
    std::unordered_set<std::string> anonymous_routes_;
    static AnonymousRouteRegistry &instance()
    {
        static AnonymousRouteRegistry registry;
        return registry;
    }
    static bool match_route_pattern(const std::string &pattern, const std::string &path)
    {
        size_t pattern_pos = 0;
        size_t path_pos = 0;

        while (pattern_pos < pattern.length() && path_pos < path.length())
        {
            // Si encontramos un parámetro en el patrón
            if (pattern[pattern_pos] == '<')
            {
                // Buscar el cierre del parámetro
                size_t close_pos = pattern.find('>', pattern_pos);
                if (close_pos == std::string::npos)
                {
                    return false; // Patrón malformado
                }

                // Extraer el tipo de parámetro (int, string, etc.)
                std::string param_type = pattern.substr(pattern_pos + 1, close_pos - pattern_pos - 1);

                // Avanzar en el patrón hasta después del '>'
                pattern_pos = close_pos + 1;

                // Buscar el siguiente '/' en el path o el final
                size_t next_slash = path.find('/', path_pos);
                if (next_slash == std::string::npos)
                {
                    next_slash = path.length();
                }

                // Extraer el valor del parámetro
                std::string param_value = path.substr(path_pos, next_slash - path_pos);

                // Validar que el valor coincida con el tipo esperado
                if (!validate_param_type(param_type, param_value))
                {
                    return false;
                }

                // Avanzar en el path
                path_pos = next_slash;
            }
            else
            {
                // Comparación carácter por carácter
                if (pattern[pattern_pos] != path[path_pos])
                {
                    return false;
                }
                pattern_pos++;
                path_pos++;
            }
        }

        // Ambos deben haber llegado al final
        return pattern_pos == pattern.length() && path_pos == path.length();
    }

    static bool validate_param_type(const std::string &type, const std::string &value)
    {
        if (value.empty())
        {
            return false;
        }

        if (type == "int" || type == "uint")
        {
            // Validar que sea un número entero
            if (type == "uint" && value[0] == '-')
            {
                return false; // uint no puede ser negativo
            }

            size_t start = (value[0] == '-' || value[0] == '+') ? 1 : 0;
            for (size_t i = start; i < value.length(); ++i)
            {
                if (!std::isdigit(value[i]))
                {
                    return false;
                }
            }
            return value.length() > start; // Debe tener al menos un dígito
        }
        else if (type == "double" || type == "float")
        {
            // Validar que sea un número decimal
            try
            {
                std::stod(value);
                return true;
            }
            catch (...)
            {
                return false;
            }
        }
        else if (type == "string")
        {
            // string acepta cualquier cosa que no sea '/'
            return value.find('/') == std::string::npos;
        }
        else if (type == "path")
        {
            // path acepta todo, incluyendo '/'
            return true;
        }

        // Tipo desconocido, aceptar por defecto
        return true;
    }

public:
    static void register_anonymous(const std::string &route)
    {
        instance().anonymous_routes_.insert(route);
    }

    static bool is_anonymous(const std::string &request_path)
    {
        // Primero intenta match exacto (para rutas sin parámetros)
        if (instance().anonymous_routes_.find(request_path) != instance().anonymous_routes_.end())
        {
            return true;
        }

        // Si no hay match exacto, intenta pattern matching
        for (const auto &pattern : instance().anonymous_routes_)
        {
            if (match_route_pattern(pattern, request_path))
            {
                return true;
            }
        }

        return false;
    }

    static void clear()
    {
        instance().anonymous_routes_.clear();
    }

    static std::unordered_set<std::string> get_all()
    {
        return instance().anonymous_routes_;
    }
};

// ============================================================================
// Wrapper para añadir el método .allow_anonymous()
// ============================================================================

template <typename Rule>
class RouteWrapper
{
private:
    Rule &rule_;
    std::string route_path_;
    bool is_anonymous_ = false;

public:
    RouteWrapper(Rule &rule, const std::string &route_path)
        : rule_(rule), route_path_(route_path)
    {
    }

    // Método para marcar la ruta como anónima
    RouteWrapper &allow_anonymous()
    {
        is_anonymous_ = true;
        AnonymousRouteRegistry::register_anonymous(route_path_);
        CROW_LOG_INFO << "Route registered as anonymous: " << route_path_;
        return *this;
    }

    // Forward de otros métodos comunes de Rule
    template <typename... Methods>
    RouteWrapper &methods(Methods &&...methods)
    {
        rule_.methods(std::forward<Methods>(methods)...);
        return *this;
    }

    RouteWrapper &name(std::string name)
    {
        rule_.name(std::move(name));
        return *this;
    }

    // Operador () para capturar el handler
    // Operador () para capturar el handler
    template <typename Func>
    void operator()(Func &&f)
    {
        rule_.template operator()<Func>(std::forward<Func>(f));
    }

    // Sobrecarga con nombre
    template <typename Func>
    void operator()(std::string name, Func &&f)
    {
        rule_.template operator()<std::string, Func>(std::move(name), std::forward<Func>(f));
    }
};

// ============================================================================
// Helper para crear el RouteWrapper
// ============================================================================

template <typename App>
class RouteCreator
{
private:
    App &app_;

public:
    RouteCreator(App &app) : app_(app) {}

    template <uint64_t Tag>
    auto create(const std::string &route_path)
    {
        auto &rule = app_.template route<Tag>(route_path);
        return RouteWrapper<decltype(rule)>(rule, route_path);
    }

    auto create_dynamic(const std::string &route_path)
    {
        auto &rule = app_.route_dynamic(route_path);
        return RouteWrapper<decltype(rule)>(rule, route_path);
    }
};

// ============================================================================
// Macro personalizada APP_ROUTE
// ============================================================================

#define APP_ROUTE(app, url)                        \
    RouteCreator<std::decay_t<decltype(app)>>(app) \
        .create<crow::black_magic::get_parameter_tag(url)>(url)

// Para rutas dinámicas (runtime)
#define APP_ROUTE_DYNAMIC(app, url)                \
    RouteCreator<std::decay_t<decltype(app)>>(app) \
        .create_dynamic(url)

// ============================================================================
// Middleware de autenticación
// ============================================================================

struct AuthenticationMiddleware
{
    struct context
    {
        bool authenticated = false;
        std::string user_id;
    };

    void before_handle(crow::request &req, crow::response &res, context &ctx)
    {
        // Verificar si la ruta es anónima
        if (AnonymousRouteRegistry::is_anonymous(req.url))
        {
            CROW_LOG_DEBUG << "Anonymous route accessed: " << req.url;
            ctx.authenticated = true; // Permitir acceso
            return;
        }

        // Verificar autenticación (ejemplo con Bearer token)
        auto auth_header = req.get_header_value("Authorization");

        if (auth_header.empty())
        {
            CROW_LOG_WARNING << "No Authorization header for protected route: " << req.url;
            res.code = 401;
            res.set_header("Content-Type", "application/json");
            res.write(crow::json::wvalue{
                {"error", "Unauthorized"},
                {"message", "Authorization header is required"}}
                          .dump());
            res.end();
            return;
        }

        // Validar token (ejemplo simplificado)
        if (auth_header.substr(0, 7) != "Bearer ")
        {
            CROW_LOG_WARNING << "Invalid Authorization format";
            res.code = 401;
            res.set_header("Content-Type", "application/json");
            res.write(crow::json::wvalue{
                {"error", "Unauthorized"},
                {"message", "Invalid authorization format. Use: Bearer <token>"}}
                          .dump());
            res.end();
            return;
        }

        std::string token = auth_header.substr(7);

        // Aquí validarías el token real (JWT, base de datos, etc.)
        // Por ahora, ejemplo simple
        if (validate_token(token, ctx))
        {
            ctx.authenticated = true;
            CROW_LOG_DEBUG << "User authenticated: " << ctx.user_id;
        }
        else
        {
            CROW_LOG_WARNING << "Invalid token";
            res.code = 401;
            res.set_header("Content-Type", "application/json");
            res.write(crow::json::wvalue{
                {"error", "Unauthorized"},
                {"message", "Invalid or expired token"}}
                          .dump());
            res.end();
        }
    }

    void after_handle(crow::request &req, crow::response &res, context &ctx)
    {
        (void)req;
        (void)res;
        // Logging posterior si es necesario
        if (ctx.authenticated && !ctx.user_id.empty())
        {
            CROW_LOG_INFO << "Request completed for user: " << ctx.user_id;
        }
    }

private:
    // Ejemplo de validación de token (implementa tu lógica real aquí)
    bool validate_token(const std::string &token, context &ctx)
    {
        // Simulación simple - en producción usarías JWT, Redis, etc.
        if (token == "valid_token_123")
        {
            ctx.user_id = "user_123";
            return true;
        }
        if (token == "admin_token_456")
        {
            ctx.user_id = "admin_456";
            return true;
        }
        return false;
    }
};
