# Kubernetes Demo - Traefik Gateway

Este proyecto contiene una configuración completa de Kubernetes con Traefik como API Gateway, un frontend Nginx y un backend API.

## Arquitectura

```
Internet
    ↓
Traefik Gateway (LoadBalancer)
    ↓
    ├─→ / → Frontend Service (Nginx) → 2 Pods
    └─→ /api → Backend Service (API) → 2 Pods
```

## Componentes

### 1. Frontend (Nginx)
- **Imagen**: nginx:alpine
- **Réplicas**: 2
- **Puerto**: 80
- **Descripción**: Sirve una aplicación web HTML con interfaz para llamar al backend
- **Ruta**: `/`

### 2. Backend API
- **Imagen**: hashicorp/http-echo
- **Réplicas**: 2
- **Puerto**: 8080 (expuesto como 80 en el Service)
- **Descripción**: API simple que responde con un mensaje
- **Ruta**: `/api`

### 3. Traefik API Gateway
- **Imagen**: traefik:v2.10
- **Tipo**: LoadBalancer
- **Puertos**:
  - 80: Tráfico HTTP
  - 8080: Dashboard de Traefik
- **Descripción**: Ingress Controller que enruta el tráfico a los servicios

## Requisitos Previos

- Kubernetes cluster funcionando (minikube, kind, GKE, EKS, AKS, etc.)
- kubectl configurado y conectado al cluster
- (Opcional) helm si quieres personalizar Traefik

## Instalación

### Opción 1: Despliegue directo

```bash
# Aplicar toda la configuración
kubectl apply -f kubernetes-demo.yaml

# Verificar el despliegue
kubectl get all -n demo-app
```

### Opción 2: Despliegue paso a paso

```bash
# 1. Crear namespace
kubectl create namespace demo-app

# 2. Desplegar servicios
kubectl apply -f kubernetes-demo.yaml

# 3. Esperar a que los pods estén listos
kubectl wait --for=condition=ready pod -l app=frontend -n demo-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=api-backend -n demo-app --timeout=120s
kubectl wait --for=condition=ready pod -l app=traefik -n demo-app --timeout=120s
```

## Verificación

```bash
# Ver todos los recursos
kubectl get all -n demo-app

# Ver logs del frontend
kubectl logs -f deployment/frontend -n demo-app

# Ver logs del backend
kubectl logs -f deployment/api-backend -n demo-app

# Ver logs de Traefik
kubectl logs -f deployment/traefik -n demo-app

# Ver el Ingress
kubectl get ingress -n demo-app
```

## Acceso a los Servicios

### En Cluster Cloud (AWS, GCP, Azure)

```bash
# Obtener la IP externa del LoadBalancer
kubectl get svc traefik -n demo-app

# Acceder a:
# http://<EXTERNAL-IP>        → Frontend
# http://<EXTERNAL-IP>/api    → Backend API
# http://<EXTERNAL-IP>:8080   → Traefik Dashboard
```

### En Minikube

```bash
# Obtener la URL del servicio
minikube service traefik -n demo-app --url

# O usar port-forward
kubectl port-forward -n demo-app svc/traefik 8000:80 8080:8080

# Acceder a:
# http://localhost:8000       → Frontend
# http://localhost:8000/api   → Backend API
# http://localhost:8080       → Traefik Dashboard
```

### En kind (Kubernetes in Docker)

```bash
# Port forward
kubectl port-forward -n demo-app svc/traefik 8000:80 8080:8080

# Acceder a:
# http://localhost:8000       → Frontend
# http://localhost:8000/api   → Backend API
# http://localhost:8080       → Traefik Dashboard
```

## Pruebas

### Probar el Frontend
```bash
# Con curl
curl http://<EXTERNAL-IP>/

# Con navegador
# Abrir http://<EXTERNAL-IP>/ y hacer clic en "Llamar al Backend API"
```

### Probar el Backend directamente
```bash
curl http://<EXTERNAL-IP>/api/
# Respuesta: ¡Hola desde el Backend API! 🚀
```

### Ver el Dashboard de Traefik
```bash
# Abrir en navegador
http://<EXTERNAL-IP>:8080/dashboard/
```

## Escalado

### Escalar servicios
```bash
# Escalar frontend a 5 réplicas
kubectl scale deployment frontend --replicas=5 -n demo-app

# Escalar backend a 3 réplicas
kubectl scale deployment api-backend --replicas=3 -n demo-app

# Verificar
kubectl get pods -n demo-app
```

## Troubleshooting

### Los pods no inician
```bash
# Describe el pod con problemas
kubectl describe pod <pod-name> -n demo-app

# Ver eventos del namespace
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

### El LoadBalancer está en "Pending"
```bash
# En minikube, habilitar el tunnel
minikube tunnel

# En kind, usar port-forward en su lugar
kubectl port-forward -n demo-app svc/traefik 8000:80
```

### No puedo acceder a los servicios
```bash
# Verificar el estado del Ingress
kubectl describe ingress demo-ingress -n demo-app

# Verificar los endpoints
kubectl get endpoints -n demo-app

# Probar conectividad directa al pod
kubectl port-forward -n demo-app pod/<pod-name> 8080:80
```

### Ver logs detallados
```bash
# Logs de todos los pods del frontend
kubectl logs -l app=frontend -n demo-app --tail=100

# Logs en tiempo real
kubectl logs -f deployment/traefik -n demo-app
```

## Limpieza

```bash
# Eliminar todos los recursos
kubectl delete namespace demo-app

# O eliminar solo el deployment
kubectl delete -f kubernetes-demo.yaml
```

## Personalización

### Cambiar el mensaje del Backend
Edita la línea `args` en el deployment `api-backend`:
```yaml
args:
  - "-text=Tu mensaje personalizado aquí"
```

### Modificar el HTML del Frontend
Edita el `ConfigMap` llamado `frontend-html`.

### Añadir HTTPS
Añade un certificado TLS:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: demo-app
type: kubernetes.io/tls
data:
  tls.crt: <base64-cert>
  tls.key: <base64-key>
```

Y actualiza el Ingress:
```yaml
spec:
  tls:
  - hosts:
    - tu-dominio.com
    secretName: tls-secret
```

### Añadir autenticación básica en Traefik
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-secret
  namespace: demo-app
data:
  users: <htpasswd-base64>
---
# En el Ingress annotations:
traefik.ingress.kubernetes.io/router.middlewares: demo-app-auth@kubernetescrd
```

## Monitorización

### Métricas de recursos
```bash
# Usar metrics-server
kubectl top pods -n demo-app
kubectl top nodes
```

### Añadir Prometheus y Grafana
```bash
# Habilitar métricas en Traefik
# Añadir a los args de Traefik:
- --metrics.prometheus=true
```

## Mejoras Sugeridas

1. **Añadir health checks**: Configura `livenessProbe` y `readinessProbe`
2. **Resource limits**: Define `resources.limits` y `resources.requests`
3. **ConfigMaps externos**: Separa la configuración del deployment
4. **Secrets**: Usa Secrets para datos sensibles
5. **Network Policies**: Restringe el tráfico entre pods
6. **HPA**: Implementa Horizontal Pod Autoscaler
7. **PodDisruptionBudget**: Asegura disponibilidad durante actualizaciones

## Estructura de Archivos Sugerida

```
proyecto/
├── kubernetes-demo.yaml         # Configuración completa
├── README.md                    # Este archivo
└── manifests/                   # (Opcional) Separar en archivos
    ├── namespace.yaml
    ├── frontend/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── configmap.yaml
    ├── backend/
    │   ├── deployment.yaml
    │   └── service.yaml
    └── traefik/
        ├── deployment.yaml
        ├── service.yaml
        └── ingress.yaml
```

## Referencias

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Documentación de Traefik](https://doc.traefik.io/traefik/)
- [Nginx en Kubernetes](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)

## Soporte

Para problemas o preguntas:
1. Revisa la sección de Troubleshooting
2. Consulta los logs de los pods
3. Verifica la documentación oficial de Kubernetes y Traefik

## Licencia

Este proyecto es de ejemplo educativo. Úsalo libremente para aprender y experimentar con Kubernetes.