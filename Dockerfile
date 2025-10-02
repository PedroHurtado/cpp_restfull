# ============================================
# Dockerfile para API REST con Crow (C++)
# ============================================
# Estrategia: Copiar binario pre-compilado
# Imagen final: ~81 MB (debian-slim + binario)
# ============================================

FROM debian:bookworm-slim

# Metadata
LABEL maintainer="tu-email@ejemplo.com"
LABEL description="API REST con Crow C++"
LABEL version="1.0"

# Instalar solo las dependencias runtime mínimas
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Crear usuario no-root para seguridad
RUN groupadd -r apiuser && \
    useradd -r -g apiuser -s /sbin/nologin -c "API User" apiuser

# Crear directorios
WORKDIR /app

# Copiar el binario pre-compilado desde tu devcontainer
COPY --chown=apiuser:apiuser build/api /app/api

# Asegurar permisos de ejecución
RUN chmod +x /app/api

# Cambiar a usuario no-root
USER apiuser

# Exponer puerto
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "pidof api || exit 1"]

# Comando de inicio
CMD ["/app/api"]