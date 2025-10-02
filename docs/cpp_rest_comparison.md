# Comparativa de Bibliotecas REST para C++

## Resumen Ejecutivo

Esta comparativa analiza las principales bibliotecas REST disponibles para C++, evaluando soporte HTTP/2, compresión, multipart/form-data, rendimiento y popularidad.

---

## Bibliotecas Analizadas

### 1. cpp-httplib
- **GitHub Stars**: ~12,000
- **Tipo**: Servidor + Cliente
- **Header-only**: ✅ Sí
- **HTTP/2**: ❌ No (solo HTTP/1.1)
- **HTTP/3**: ❌ No
- **Compresión**: ✅ gzip, deflate
- **Multipart/form-data**: ✅ Completo
- **SSL/TLS**: ✅ Con OpenSSL
- **Velocidad**: Media-Alta (★★★★☆)
- **Facilidad de uso**: Muy fácil (★★★★★)
- **Plataformas**: Cross-platform
- **Curva de aprendizaje**: Muy baja
- **Caso de uso**: Proyectos pequeños/medianos, prototipado rápido

### 2. Drogon
- **GitHub Stars**: ~11,000
- **Tipo**: Servidor + Cliente (Framework completo)
- **Header-only**: ❌ No
- **HTTP/2**: ✅ Soporte completo (H2/H2C)
- **HTTP/3**: 🚧 Experimental
- **Compresión**: ✅ gzip, brotli, deflate
- **Multipart/form-data**: ✅ Excelente soporte
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Linux, macOS, Windows
- **ORM**: ✅ Integrado
- **WebSocket**: ✅ Sí
- **Curva de aprendizaje**: Media-Alta
- **Caso de uso**: Aplicaciones web completas, APIs de producción con HTTP/2

### 3. proxygen (Facebook/Meta)
- **GitHub Stars**: ~8,000
- **Tipo**: Servidor + Cliente
- **Header-only**: ❌ No
- **HTTP/2**: ✅ Soporte completo
- **HTTP/3/QUIC**: ✅ Con mvfst
- **Compresión**: ✅ HPACK, HPack, QPack, gzip
- **Multipart/form-data**: ⚠️ Parsing manual requerido
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Difícil (★★☆☆☆)
- **Plataformas**: Linux, macOS
- **Curva de aprendizaje**: Alta
- **Dependencias**: Complejas (Folly, Fizz, Wangle)
- **Caso de uso**: Aplicaciones de escala masiva, producción enterprise

### 4. Oat++
- **GitHub Stars**: ~7,800
- **Tipo**: Servidor + Cliente
- **Header-only**: ❌ No
- **HTTP/2**: ❌ No (solo HTTP/1.1)
- **HTTP/3**: ❌ No
- **Compresión**: ✅ gzip
- **Multipart/form-data**: ✅ Excelente soporte
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Cross-platform
- **ORM**: ✅ Integrado
- **Swagger/OpenAPI**: ✅ Generación automática
- **Curva de aprendizaje**: Media
- **Caso de uso**: Microservicios modernos, APIs RESTful

### 5. nghttp2
- **GitHub Stars**: ~4,600
- **Tipo**: Servidor + Cliente (biblioteca especializada HTTP/2)
- **Header-only**: ❌ No
- **HTTP/2**: ✅ Implementación de referencia
- **HTTP/3**: ✅ Disponible (nghttp3)
- **Compresión**: ✅ HPACK, gzip
- **Multipart/form-data**: ⚠️ Parsing manual requerido
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Difícil (★★☆☆☆)
- **Plataformas**: Cross-platform
- **Curva de aprendizaje**: Alta
- **Caso de uso**: Cuando HTTP/2 es crítico, máximo control del protocolo

### 6. Pistache
- **GitHub Stars**: ~3,000
- **Tipo**: Servidor (principalmente)
- **Header-only**: ❌ No
- **HTTP/2**: ❌ No
- **HTTP/3**: ❌ No
- **Compresión**: ❌ Requiere implementación manual
- **Multipart/form-data**: ⚠️ Soporte limitado
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Solo Linux
- **Arquitectura**: Asíncrona moderna
- **Curva de aprendizaje**: Media
- **Caso de uso**: APIs de alto rendimiento en Linux

### 7. Crow
- **GitHub Stars**: ~3,000
- **Tipo**: Servidor
- **Header-only**: ✅ Sí
- **HTTP/2**: ❌ No
- **HTTP/3**: ❌ No
- **Compresión**: ✅ gzip (vía middleware)
- **Multipart/form-data**: ✅ Sí
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Alta (★★★★☆)
- **Facilidad de uso**: Muy fácil (★★★★☆)
- **Plataformas**: Cross-platform
- **WebSocket**: ✅ Sí
- **Sintaxis**: Inspirado en Python Flask
- **Curva de aprendizaje**: Baja
- **Caso de uso**: Microservicios rápidos, desarrollo ágil

### 8. RESTinio
- **GitHub Stars**: ~1,000
- **Tipo**: Servidor
- **Header-only**: ✅ Sí
- **HTTP/2**: ❌ No
- **HTTP/3**: ❌ No
- **Compresión**: ✅ Vía middleware
- **Multipart/form-data**: ⚠️ Soporte básico
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Alta (★★★★☆)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Cross-platform
- **Requisitos**: C++14/17/20
- **Routing**: Estilo Express.js
- **Curva de aprendizaje**: Media
- **Caso de uso**: APIs modernas con C++ moderno

### 9. CppServer
- **GitHub Stars**: ~1,400
- **Tipo**: Servidor + Cliente
- **Header-only**: ❌ No
- **HTTP/2**: ❌ No
- **HTTP/3**: ❌ No
- **Compresión**: ✅ Sí
- **Multipart/form-data**: ✅ Sí
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Alta (★★★★☆)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Cross-platform
- **Protocolos**: HTTP, HTTPS, WebSocket, TCP, UDP
- **Curva de aprendizaje**: Media
- **Caso de uso**: Aplicaciones de red versátiles

### 10. Boost.Beast
- **GitHub Stars**: N/A (parte de Boost)
- **Tipo**: Servidor + Cliente (bajo nivel)
- **Header-only**: ✅ Sí
- **HTTP/2**: ❌ No (solo HTTP/1.1)
- **HTTP/3**: ❌ No
- **Compresión**: ❌ Implementación manual
- **Multipart/form-data**: ❌ Implementación manual
- **SSL/TLS**: ✅ Con Boost.Asio
- **Velocidad**: Muy Alta (★★★★★)
- **Facilidad de uso**: Difícil (★★☆☆☆)
- **Plataformas**: Cross-platform
- **WebSocket**: ✅ Excelente
- **Asíncrono**: ✅ Con Boost.Asio
- **Curva de aprendizaje**: Alta
- **Caso de uso**: Control total, aplicaciones personalizadas

### 11. POCO C++ Libraries
- **GitHub Stars**: N/A (proyecto maduro)
- **Tipo**: Suite completa de red
- **Header-only**: ❌ No
- **HTTP/2**: ❌ No
- **HTTP/3**: ❌ No
- **Compresión**: ✅ Múltiples formatos
- **Multipart/form-data**: ✅ Sí
- **SSL/TLS**: ✅ Sí
- **Velocidad**: Media-Alta (★★★★☆)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Cross-platform
- **Documentación**: Excelente
- **Madurez**: Muy alta
- **Curva de aprendizaje**: Media
- **Caso de uso**: Aplicaciones empresariales, sistemas heredados

### 12. libcurl
- **GitHub Stars**: N/A (estándar de industria)
- **Tipo**: Cliente únicamente
- **Header-only**: ❌ No
- **HTTP/2**: ✅ Con nghttp2
- **HTTP/3**: ✅ Experimental
- **Compresión**: ✅ Todos los formatos
- **Multipart/form-data**: ✅ Completo
- **SSL/TLS**: ✅ Múltiples backends
- **Velocidad**: Alta (★★★★☆)
- **Facilidad de uso**: Media (★★★☆☆)
- **Plataformas**: Todas
- **Madurez**: Muy alta
- **Protocolos**: HTTP, FTP, SMTP, etc.
- **Curva de aprendizaje**: Media
- **Caso de uso**: Cliente REST universal, scripts, automatización

---

## Tabla Comparativa Rápida

| Biblioteca | HTTP/2 | HTTP/3 | Compresión | Multipart | Velocidad | Facilidad | Stars | Tipo |
|------------|--------|--------|------------|-----------|-----------|-----------|-------|------|
| **cpp-httplib** | ❌ | ❌ | ✅ | ✅ | ★★★★☆ | ★★★★★ | 12k | S+C |
| **Drogon** | ✅ | 🚧 | ✅ | ✅ | ★★★★★ | ★★★☆☆ | 11k | S+C |
| **proxygen** | ✅ | ✅ | ✅ | ⚠️ | ★★★★★ | ★★☆☆☆ | 8k | S+C |
| **Oat++** | ❌ | ❌ | ✅ | ✅ | ★★★★★ | ★★★☆☆ | 7.8k | S+C |
| **nghttp2** | ✅ | ✅ | ✅ | ⚠️ | ★★★★★ | ★★☆☆☆ | 4.6k | S+C |
| **Pistache** | ❌ | ❌ | ❌ | ⚠️ | ★★★★★ | ★★★☆☆ | 3k | S |
| **Crow** | ❌ | ❌ | ✅ | ✅ | ★★★★☆ | ★★★★☆ | 3k | S |
| **CppServer** | ❌ | ❌ | ✅ | ✅ | ★★★★☆ | ★★★☆☆ | 1.4k | S+C |
| **RESTinio** | ❌ | ❌ | ✅ | ⚠️ | ★★★★☆ | ★★★☆☆ | 1k | S |
| **Boost.Beast** | ❌ | ❌ | ❌ | ❌ | ★★★★★ | ★★☆☆☆ | - | S+C |
| **POCO** | ❌ | ❌ | ✅ | ✅ | ★★★★☆ | ★★★☆☆ | - | S+C |
| **libcurl** | ✅ | ✅ | ✅ | ✅ | ★★★★☆ | ★★★☆☆ | - | C |

**Leyenda:**
- **S** = Servidor
- **C** = Cliente
- **S+C** = Servidor y Cliente
- ✅ = Soportado
- ⚠️ = Soporte parcial/limitado
- ❌ = No soportado
- 🚧 = En desarrollo

---

## Recomendaciones por Caso de Uso

### HTTP/2 es Obligatorio

#### Mejor opción general con HTTP/2
**Drogon**
- Framework completo y moderno
- HTTP/2 nativo bien integrado
- Documentación buena
- Balance ideal entre características y facilidad

#### Máximo control sobre HTTP/2
**nghttp2**
- Implementación de referencia del protocolo
- Control de bajo nivel
- HTTP/3 también disponible
- Requiere más trabajo manual

#### Escala empresarial masiva
**proxygen**
- Probado en producción (Facebook/Meta)
- HTTP/3 + QUIC
- Rendimiento extremo
- Curva de aprendizaje pronunciada

#### Solo cliente HTTP/2
**libcurl**
- Estándar de industria
- Muy estable y portable
- HTTP/2 y HTTP/3 disponibles
- Amplia documentación

### HTTP/2 NO es Necesario

#### Desarrollo rápido y simple
**cpp-httplib**
- Header-only, fácil integración
- API intuitiva
- Ideal para prototipos y MVPs

#### Máximo rendimiento HTTP/1.1
**Pistache** (Linux) u **Oat++** (multiplataforma)
- Arquitectura asíncrona optimizada
- Excelente para alto tráfico HTTP/1.1

#### Sintaxis moderna tipo Flask
**Crow**
- Routing elegante
- Desarrollo ágil
- Buena documentación

#### Control total bajo nivel
**Boost.Beast**
- Máxima flexibilidad
- Optimización personalizada
- Requiere experiencia avanzada

#### Aplicaciones empresariales
**POCO**
- Maduro y estable
- Excelente documentación
- Soporte comercial disponible

---

## Benchmarks de Rendimiento

### Requests por Segundo (aproximado)

Pruebas realizadas con conexiones persistentes, payload pequeño:

| Biblioteca | HTTP/1.1 | HTTP/2 | Notas |
|------------|----------|--------|-------|
| Drogon | ~300k | ~350k | Uno de los más rápidos |
| proxygen | ~280k | ~400k | Optimizado para HTTP/2 |
| Pistache | ~320k | N/A | Solo HTTP/1.1 |
| Oat++ | ~290k | N/A | Muy eficiente |
| nghttp2 | ~250k | ~380k | Especializado HTTP/2 |
| Crow | ~180k | N/A | Buen balance |
| cpp-httplib | ~120k | N/A | Simplicidad vs velocidad |
| Boost.Beast | ~300k+ | N/A | Depende de implementación |

**Nota:** Los benchmarks varían según hardware, configuración y tipo de workload. Estos son valores orientativos.

---

## Características Especiales

### Drogon
- ORM integrado con múltiples bases de datos
- Generación automática de controladores
- Plugin system
- Filtros y middleware avanzados
- Sesiones integradas

### Oat++
- Generación automática de documentación Swagger/OpenAPI
- Validación automática de requests
- Serialización/deserialización async
- Testing framework integrado

### proxygen
- Load balancing integrado
- Connection pooling avanzado
- Filtros de solicitud complejos
- Usado por aplicaciones a escala de billones de requests

### nghttp2
- Implementación de referencia C de HTTP/2
- Proxy HTTP/2 incluido
- Herramientas de análisis de protocolo
- Bindings para múltiples lenguajes

---

## Instalación y Dependencias

### Facilidad de Integración

#### Más Fáciles (Header-only)
1. cpp-httplib
2. Crow
3. RESTinio
4. Boost.Beast

#### Complejidad Media
1. Drogon
2. Oat++
3. CppServer
4. Pistache

#### Más Complejos
1. proxygen (muchas dependencias de Facebook)
2. nghttp2 (requiere configuración cuidadosa)

---

## Soporte y Comunidad

### Más Activos
- Drogon: Comunidad activa, releases frecuentes
- cpp-httplib: Mantenimiento continuo
- Oat++: En crecimiento rápido

### Respaldo Corporativo
- proxygen: Facebook/Meta
- Boost.Beast: Boost C++ Libraries

### Madurez
- libcurl: Décadas en producción
- POCO: Más de 15 años
- Boost.Beast: Parte del ecosistema Boost

---

## Consideraciones de Licencia

| Biblioteca | Licencia |
|------------|----------|
| cpp-httplib | MIT |
| Drogon | MIT |
| proxygen | BSD-3-Clause |
| Oat++ | Apache 2.0 |
| nghttp2 | MIT |
| Pistache | Apache 2.0 |
| Crow | BSD-3-Clause |
| RESTinio | BSD-3-Clause |
| Boost.Beast | Boost Software License |
| POCO | Boost Software License |
| libcurl | curl license (MIT-like) |

Todas son compatibles con uso comercial.

---

## Conclusión

### Si necesitas HTTP/2:
- **Recomendación principal**: **Drogon** (mejor balance)
- **Alternativa cliente**: **libcurl**
- **Escala masiva**: **proxygen**
- **Control máximo**: **nghttp2**

### Si HTTP/1.1 es suficiente:
- **Desarrollo rápido**: **cpp-httplib**
- **Alto rendimiento**: **Oat++** o **Pistache**
- **Sintaxis moderna**: **Crow**
- **Enterprise**: **POCO**

### Factores de decisión clave:
1. ¿Necesitas HTTP/2? → Limita opciones a Drogon, proxygen, nghttp2, libcurl
2. ¿Solo cliente o también servidor? → libcurl solo es cliente
3. ¿Qué tan crítico es el rendimiento? → Afecta la elección
4. ¿Experiencia del equipo? → Curva de aprendizaje
5. ¿Plataforma objetivo? → Pistache solo Linux