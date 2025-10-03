# Monitoreo de Servicios Web con Herramientas Externas - Crow

## ¿Qué es Crow?
Framework web ligero en C++ para crear APIs REST de alto rendimiento, inspirado en Flask de Python.

## Herramientas de Monitoreo Principales

### 1. Prometheus + Grafana
- **Uso**: Recopilación de métricas en tiempo real
- **Implementación**: Crear endpoint `/metrics` en Crow que exponga métricas en formato Prometheus
- **Métricas clave**: Requests totales, errores, tiempos de respuesta
- **Visualización**: Dashboards personalizados en Grafana

### 2. ELK Stack (Elasticsearch, Logstash, Kibana)
- **Uso**: Centralización y análisis de logs
- **Implementación**: Enviar logs desde Crow usando bibliotecas como spdlog
- **Beneficio**: Búsqueda y análisis avanzado de logs históricos

### 3. New Relic / Datadog
- **Uso**: Monitoreo APM (Application Performance Monitoring) completo
- **Implementación**: SDK/agente integrado en la aplicación
- **Características**: Rastreo de transacciones, análisis de rendimiento automático

### 4. UptimeRobot / Pingdom
- **Uso**: Verificación de disponibilidad externa
- **Implementación**: Endpoint `/health` con verificación de dependencias
- **Alertas**: Notificaciones cuando el servicio no está disponible

### 5. Jaeger / Zipkin
- **Uso**: Rastreo distribuido (distributed tracing)
- **Implementación**: OpenTelemetry para instrumentación
- **Beneficio**: Visualizar flujo de requests en arquitecturas distribuidas

## Métricas Esenciales a Monitorear

### Rendimiento
- Tiempo de respuesta promedio y percentiles (P50, P95, P99)
- Throughput (requests por segundo)
- Tasa de errores (4xx, 5xx)

### Recursos del Sistema
- Uso de CPU y memoria
- Conexiones activas
- Threads en uso

### Negocio
- Usuarios activos concurrentes
- Transacciones completadas
- Métricas específicas de tu aplicación

---

## Ejemplo 1: Endpoint de Métricas para Prometheus

### Implementación Completa en Crow

```cpp
#include "crow.h"
#include <atomic>
#include <chrono>
#include <sstream>

// Clase para recolectar métricas
class MetricsCollector {
private:
    std::atomic<uint64_t> total_requests{0};
    std::atomic<uint64_t> successful_requests{0};
    std::atomic<uint64_t> failed_requests{0};
    std::atomic<uint64_t> requests_4xx{0};
    std::atomic<uint64_t> requests_5xx{0};
    std::atomic<uint64_t> total_response_time_ms{0};
    std::atomic<uint64_t> active_connections{0};
    
public:
    void recordRequest(int status_code, uint64_t response_time_ms) {
        total_requests++;
        total_response_time_ms += response_time_ms;
        
        if (status_code >= 200 && status_code < 300) {
            successful_requests++;
        } else if (status_code >= 400 && status_code < 500) {
            requests_4xx++;
            failed_requests++;
        } else if (status_code >= 500) {
            requests_5xx++;
            failed_requests++;
        }
    }
    
    void incrementActiveConnections() { active_connections++; }
    void decrementActiveConnections() { active_connections--; }
    
    // Genera métricas en formato Prometheus
    std::string getPrometheusMetrics() {
        std::stringstream ss;
        
        // Total de requests
        ss << "# HELP http_requests_total Total number of HTTP requests\n";
        ss << "# TYPE http_requests_total counter\n";
        ss << "http_requests_total " << total_requests << "\n\n";
        
        // Requests exitosos
        ss << "# HELP http_requests_successful Successful HTTP requests (2xx)\n";
        ss << "# TYPE http_requests_successful counter\n";
        ss << "http_requests_successful " << successful_requests << "\n\n";
        
        // Errores 4xx
        ss << "# HELP http_requests_4xx Client error responses (4xx)\n";
        ss << "# TYPE http_requests_4xx counter\n";
        ss << "http_requests_4xx " << requests_4xx << "\n\n";
        
        // Errores 5xx
        ss << "# HELP http_requests_5xx Server error responses (5xx)\n";
        ss << "# TYPE http_requests_5xx counter\n";
        ss << "http_requests_5xx " << requests_5xx << "\n\n";
        
        // Tiempo total de respuesta
        ss << "# HELP http_response_time_milliseconds_total Total response time in milliseconds\n";
        ss << "# TYPE http_response_time_milliseconds_total counter\n";
        ss << "http_response_time_milliseconds_total " << total_response_time_ms << "\n\n";
        
        // Conexiones activas
        ss << "# HELP http_active_connections Current number of active connections\n";
        ss << "# TYPE http_active_connections gauge\n";
        ss << "http_active_connections " << active_connections << "\n\n";
        
        // Tiempo promedio de respuesta
        double avg_response_time = total_requests > 0 ? 
            static_cast<double>(total_response_time_ms) / total_requests : 0;
        ss << "# HELP http_response_time_avg_milliseconds Average response time\n";
        ss << "# TYPE http_response_time_avg_milliseconds gauge\n";
        ss << "http_response_time_avg_milliseconds " << avg_response_time << "\n\n";
        
        return ss.str();
    }
};

// Middleware para tracking automático
struct MetricsMiddleware {
    struct context {
        std::chrono::high_resolution_clock::time_point start_time;
    };
    
    MetricsCollector* collector;
    
    MetricsMiddleware(MetricsCollector* mc) : collector(mc) {}
    
    void before_handle(crow::request& req, crow::response& res, context& ctx) {
        ctx.start_time = std::chrono::high_resolution_clock::now();
        collector->incrementActiveConnections();
    }
    
    void after_handle(crow::request& req, crow::response& res, context& ctx) {
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
            end_time - ctx.start_time
        ).count();
        
        collector->recordRequest(res.code, duration);
        collector->decrementActiveConnections();
    }
};

int main() {
    crow::App<MetricsMiddleware> app;
    MetricsCollector metrics;
    
    // Inyectar el collector en el middleware
    app.get_middleware<MetricsMiddleware>().collector = &metrics;
    
    // Endpoint de métricas para Prometheus
    CROW_ROUTE(app, "/metrics")
    ([&metrics]() {
        auto response = crow::response(metrics.getPrometheusMetrics());
        response.set_header("Content-Type", "text/plain; version=0.0.4");
        return response;
    });
    
    // Ejemplos de otros endpoints
    CROW_ROUTE(app, "/api/users")
    ([]() {
        crow::json::wvalue result;
        result["users"] = crow::json::wvalue::list({});
        return crow::response(result);
    });
    
    CROW_ROUTE(app, "/api/data")
    ([]() {
        return crow::response(200, "Data retrieved successfully");
    });
    
    app.port(8080).multithreaded().run();
    return 0;
}
```

### Configuración de Prometheus

**Archivo `prometheus.yml`:**

```yaml
global:
  scrape_interval: 15s      # Recolectar métricas cada 15 segundos
  evaluation_interval: 15s   # Evaluar reglas cada 15 segundos

# Configuración de scraping
scrape_configs:
  - job_name: 'crow_application'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    
# Reglas de alertas
rule_files:
  - 'alerts.yml'
```

**Archivo `alerts.yml`:**

```yaml
groups:
  - name: crow_alerts
    interval: 30s
    rules:
      # Alerta por alta tasa de errores
      - alert: HighErrorRate
        expr: rate(http_requests_5xx[5m]) > 10
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected in Crow application"
          description: "Error rate is {{ $value }} errors per second"
      
      # Alerta por tiempo de respuesta alto
      - alert: SlowResponseTime
        expr: http_response_time_avg_milliseconds > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Average response time is too high"
          description: "Response time is {{ $value }}ms"
```

---

## Ejemplo 2: Health Check Endpoint Completo

### Implementación con Verificación de Dependencias

```cpp
#include "crow.h"
#include <pqxx/pqxx>  // PostgreSQL
#include <redis++/redis++.h>  // Redis
#include <memory>

// Clase para gestionar verificaciones de salud
class HealthChecker {
private:
    std::string db_connection_string;
    std::string redis_host;
    int redis_port;
    
public:
    HealthChecker(const std::string& db_conn, const std::string& redis_h, int redis_p)
        : db_connection_string(db_conn), redis_host(redis_h), redis_port(redis_p) {}
    
    // Verificar conexión a base de datos
    bool checkDatabase() {
        try {
            pqxx::connection conn(db_connection_string);
            if (conn.is_open()) {
                pqxx::work txn(conn);
                pqxx::result r = txn.exec("SELECT 1");
                txn.commit();
                return r.size() > 0;
            }
        } catch (const std::exception& e) {
            std::cerr << "Database check failed: " << e.what() << std::endl;
            return false;
        }
        return false;
    }
    
    // Verificar conexión a Redis
    bool checkRedis() {
        try {
            sw::redis::ConnectionOptions opts;
            opts.host = redis_host;
            opts.port = redis_port;
            opts.socket_timeout = std::chrono::milliseconds(500);
            
            sw::redis::Redis redis(opts);
            redis.ping();
            return true;
        } catch (const std::exception& e) {
            std::cerr << "Redis check failed: " << e.what() << std::endl;
            return false;
        }
    }
    
    // Verificar espacio en disco
    bool checkDiskSpace() {
        // Implementación simplificada
        // En producción, usar funciones del sistema operativo
        return true; // Placeholder
    }
    
    // Verificar uso de memoria
    bool checkMemory() {
        // Implementación simplificada
        return true; // Placeholder
    }
};

int main() {
    crow::SimpleApp app;
    
    // Configuración de dependencias
    HealthChecker health_checker(
        "postgresql://user:password@localhost/mydb",
        "localhost",
        6379
    );
    
    // Health check básico - Para UptimeRobot/Pingdom
    CROW_ROUTE(app, "/health")
    ([&health_checker]() {
        bool db_ok = health_checker.checkDatabase();
        bool redis_ok = health_checker.checkRedis();
        bool disk_ok = health_checker.checkDiskSpace();
        
        crow::json::wvalue response;
        response["status"] = (db_ok && redis_ok && disk_ok) ? "healthy" : "unhealthy";
        response["timestamp"] = std::time(nullptr);
        
        int status_code = (db_ok && redis_ok && disk_ok) ? 200 : 503;
        return crow::response(status_code, response);
    });
    
    // Health check detallado - Para monitoreo interno
    CROW_ROUTE(app, "/health/detailed")
    ([&health_checker]() {
        bool db_ok = health_checker.checkDatabase();
        bool redis_ok = health_checker.checkRedis();
        bool disk_ok = health_checker.checkDiskSpace();
        bool memory_ok = health_checker.checkMemory();
        
        crow::json::wvalue response;
        
        // Estado general
        response["status"] = (db_ok && redis_ok && disk_ok && memory_ok) 
            ? "healthy" : "unhealthy";
        response["timestamp"] = std::time(nullptr);
        response["version"] = "1.2.3";
        response["uptime_seconds"] = 3600; // Calcular uptime real
        
        // Detalles de cada componente
        crow::json::wvalue checks;
        
        checks["database"]["status"] = db_ok ? "up" : "down";
        checks["database"]["response_time_ms"] = 15; // Medir tiempo real
        checks["database"]["type"] = "postgresql";
        
        checks["cache"]["status"] = redis_ok ? "up" : "down";
        checks["cache"]["response_time_ms"] = 5;
        checks["cache"]["type"] = "redis";
        
        checks["disk"]["status"] = disk_ok ? "up" : "down";
        checks["disk"]["available_gb"] = 50.5;
        checks["disk"]["used_percent"] = 65;
        
        checks["memory"]["status"] = memory_ok ? "up" : "down";
        checks["memory"]["available_mb"] = 2048;
        checks["memory"]["used_percent"] = 45;
        
        response["checks"] = std::move(checks);
        
        // Métricas adicionales
        crow::json::wvalue metrics;
        metrics["active_connections"] = 42;
        metrics["requests_per_second"] = 150;
        metrics["average_response_time_ms"] = 85;
        response["metrics"] = std::move(metrics);
        
        int status_code = (db_ok && redis_ok && disk_ok && memory_ok) ? 200 : 503;
        return crow::response(status_code, response);
    });
    
    // Readiness check - Para Kubernetes
    CROW_ROUTE(app, "/ready")
    ([&health_checker]() {
        // Verifica si la aplicación está lista para recibir tráfico
        bool ready = health_checker.checkDatabase() && 
                     health_checker.checkRedis();
        
        crow::json::wvalue response;
        response["ready"] = ready;
        
        return crow::response(ready ? 200 : 503, response);
    });
    
    // Liveness check - Para Kubernetes
    CROW_ROUTE(app, "/alive")
    ([]() {
        // Verifica si la aplicación está viva (no bloqueada)
        crow::json::wvalue response;
        response["alive"] = true;
        return crow::response(200, response);
    });
    
    app.port(8080).multithreaded().run();
    return 0;
}
```

### Ejemplo de Respuesta del Health Check Detallado

```json
{
  "status": "healthy",
  "timestamp": 1696348800,
  "version": "1.2.3",
  "uptime_seconds": 3600,
  "checks": {
    "database": {
      "status": "up",
      "response_time_ms": 15,
      "type": "postgresql"
    },
    "cache": {
      "status": "up",
      "response_time_ms": 5,
      "type": "redis"
    },
    "disk": {
      "status": "up",
      "available_gb": 50.5,
      "used_percent": 65
    },
    "memory": {
      "status": "up",
      "available_mb": 2048,
      "used_percent": 45
    }
  },
  "metrics": {
    "active_connections": 42,
    "requests_per_second": 150,
    "average_response_time_ms": 85
  }
}
```

---

## Estrategia de Alertas

**Configurar alertas para:**
- Tasa de error > 5% durante 5 minutos
- Tiempo de respuesta > 1000ms durante 2 minutos
- Servicio caído durante 1 minuto
- Uso de CPU > 80% durante 10 minutos
- Memoria disponible < 20%

## Mejores Prácticas

1. **Monitoreo proactivo**: Alertas antes de que afecten usuarios
2. **Health checks completos**: Verificar dependencias, no solo HTTP 200
3. **Logs correlacionados**: Usar IDs de transacción únicos
4. **Dashboards por rol**: Vistas para desarrolladores, operaciones y negocio
5. **Documentación**: Catálogo de métricas y su significado
6. **Pruebas de alertas**: Simular fallos regularmente
7. **Retención de datos**: Definir políticas según necesidades

## Stack Recomendado para Comenzar

**Open Source (Gratis):**
- Prometheus (métricas)
- Grafana (visualización)
- Loki o ELK (logs)
- Jaeger (tracing opcional)
- UptimeRobot (uptime monitoring)

**Comercial (Más completo):**
- Datadog o New Relic (todo en uno)
- PagerDuty (gestión de alertas)
- StatusPage (página de estado público)

## Beneficios del Monitoreo

✓ Detectar problemas antes que los usuarios  
✓ Reducir tiempo de resolución (MTTR)  
✓ Entender patrones de uso  
✓ Optimizar rendimiento basado en datos  
✓ Cumplir SLAs y SLOs  
✓ Tomar decisiones de escalado informadas  
✓ Mejorar la experiencia del usuario