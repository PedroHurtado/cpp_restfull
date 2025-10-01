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

public:
    static void register_anonymous(const std::string &route)
    {
        instance().anonymous_routes_.insert(route);
    }

    static bool is_anonymous(const std::string &route)
    {
        return instance().anonymous_routes_.find(route) != instance().anonymous_routes_.end();
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
