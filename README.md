# Proyecto Final - Servicios Telemáticos

**Universidad Autónoma de Occidente**\
**Estudiante:** William Reyes Valencia\
**Código:** 2215337

## Arquitectura

    ┌─────────────┐
    │   Usuario   │
    └──────┬──────┘
           │ HTTPS (443)
           ▼
    ┌─────────────┐
    │   Nginx     │ ◄── Certificado SSL
    └──────┬──────┘
           │ HTTP (5000)
           ▼
    ┌─────────────┐      ┌─────────────┐
    │   Flask     │◄────►│   MySQL     │
    └─────────────┘      └─────────────┘
           │
           │ Métricas
           ▼
    ┌─────────────┐      ┌─────────────┐
    │ Prometheus  │◄────►│Node Exporter│
    └──────┬──────┘      └─────────────┘
           │
           ▼
    ┌─────────────┐
    │   Grafana   │
    └─────────────┘

## Instrucciones de Despliegue

### Instalación

``` bash
# 1. Clonar el repositorio
git clone [URL_DEL_REPO]
cd proyecto-final-telematicos

# 2. Levantar la máquina virtual
vagrant up

# 3. Conectarse a la VM
vagrant ssh

# 4. Generar certificados SSL
cd /vagrant/docker/nginx/ssl
bash generate-ssl.sh

# 5. Levantar los contenedores
cd /vagrant/docker
sudo docker-compose up -d

# 6. Verificar que todo esté corriendo
sudo docker ps
```

## Acceso a los Servicios

  Servicio             URL                      Credenciales
  -------------------- ------------------------ ------------------
  **Aplicación Web**   https://localhost:8443   N/A
  **Grafana**          http://localhost:3000    admin / admin123
  **Prometheus**       http://localhost:9090    N/A

## 📊 Métricas Monitoreadas

### 1. **node_cpu_seconds_total**

-   **Descripción:** Tiempo de CPU por modo (idle, user, system)
-   **Uso:** Detectar alto uso de CPU
-   **Alerta:** CPU \> 80% por 2 minutos

### 2. **node_memory_MemAvailable_bytes**

-   **Descripción:** Memoria RAM disponible
-   **Uso:** Monitorear disponibilidad de memoria
-   **Alerta:** Memoria disponible \< 20%

### 3. **node_filesystem_avail_bytes**

-   **Descripción:** Espacio disponible en disco
-   **Uso:** Prevenir llenado de disco
-   **Alerta:** Espacio libre \< 15%

## Configuración

### Docker Compose

Los servicios están orquestados con `docker-compose.yml`:

-   mysql\
-   webapp\
-   nginx\
-   prometheus\
-   node-exporter\
-   grafana

### Nginx

Configuración en `docker/nginx/nginx.conf`:

-   Redirección HTTP → HTTPS\
-   TLS 1.2 y 1.3\
-   Headers de seguridad\
-   Proxy pass a Flask

### Prometheus

Scrape configs en `prometheus/prometheus.yml`:

-   Intervalo 15 segundos\
-   Targets: Prometheus, Node Exporter, WebApp\
-   Alertas: CPU, Memoria, Disco, Disponibilidad

## Evidencias

Ver carpeta `evidencias/capturas/`

## 📚 Conclusión Técnica

### ¿Qué aprendí al integrar Docker, AWS y Prometheus?

Durante el desarrollo de este proyecto aprendí a:

1. **Containerización con Docker**: Comprendí cómo empaquetar aplicaciones y sus dependencias en contenedores aislados, garantizando portabilidad y consistencia entre entornos. La orquestación con Docker Compose simplificó significativamente el manejo de múltiples servicios interdependientes.

2. **Despliegue en la nube**: Aunque inicialmente implementé la solución en Vagrant para desarrollo local, el proceso de configurar instancias EC2, security groups y gestionar recursos en AWS me permitió entender los conceptos fundamentales de infraestructura como servicio (IaaS) y las consideraciones de seguridad necesarias para exponer servicios públicamente.

3. **Monitoreo con Prometheus**: Aprendí el modelo pull de Prometheus para recolección de métricas, la importancia de los exporters (como Node Exporter) y cómo configurar scrape targets. La integración con Grafana me mostró el valor de visualizar datos de monitoreo en tiempo real para la toma de decisiones operativas.

4. **Integración completa**: El mayor aprendizaje fue entender cómo estos componentes trabajan juntos: Docker proporciona la plataforma de ejecución, Prometheus recolecta las métricas de los contenedores y del sistema operativo, y Grafana las presenta de forma accionable.

---

### ¿Qué fue lo más desafiante y cómo lo resolvería en un entorno real?

#### Desafíos encontrados:

1. **Gestión de certificados SSL**: La generación y configuración de certificados autofirmados para HTTPS fue compleja inicialmente. En producción, esto se resolvería usando:
   - **Let's Encrypt** con renovación automática mediante certbot
   - **AWS Certificate Manager (ACM)** para certificados gestionados
   - **Traefik** como reverse proxy con soporte nativo para Let's Encrypt

2. **Limitaciones de recursos**: En instancias pequeñas (t3.micro con 1GB RAM), levantar múltiples contenedores simultáneamente causaba problemas de recursos. En producción:
   - Usar instancias apropiadas al workload (t3.medium o superior)
   - Implementar límites de recursos en docker-compose (memory, cpu limits)
   - Considerar servicios gestionados (RDS para MySQL, CloudWatch para monitoreo)

3. **Persistencia de datos**: Los volúmenes de Docker funcionan bien localmente, pero en producción:
   - Usar **Amazon EBS** para volúmenes persistentes
   - Implementar backups automáticos con snapshots
   - Considerar **Amazon EFS** para volúmenes compartidos entre instancias

4. **Networking y conectividad**: La configuración de redes entre contenedores y security groups requirió múltiples iteraciones. En producción:
   - Usar **Application Load Balancer (ALB)** con target groups
   - Implementar **Service Mesh** (Istio, Linkerd) para microservicios complejos
   - Segregar servicios en múltiples subredes (pública/privada)

5. **Escalabilidad**: La solución actual es monolítica. En producción:
   - Migrar a **Amazon ECS** o **Kubernetes (EKS)** para orquestación enterprise
   - Implementar **Auto Scaling Groups** para escalamiento horizontal
   - Usar **Amazon RDS Multi-AZ** para alta disponibilidad de base de datos

---

### ¿Qué beneficio aporta la observabilidad en el ciclo DevOps?

La observabilidad es fundamental en DevOps por las siguientes razones:

#### 1. **Detección proactiva de problemas**
- Las alertas configuradas en Prometheus (CPU > 80%, memoria < 20%, disco < 15%) permiten identificar problemas **antes** de que afecten a los usuarios finales.
- En este proyecto, pude detectar que Nginx estaba consumiendo recursos excesivos gracias al monitoreo en tiempo real.

#### 2. **Reducción del MTTR (Mean Time To Recovery)**
- Con dashboards de Grafana, el tiempo para diagnosticar problemas se reduce drásticamente.
- En lugar de conectarse por SSH y ejecutar comandos manualmente, un vistazo al dashboard revela el estado del sistema completo.
- Las métricas históricas permiten análisis post-mortem y correlación de eventos.

#### 3. **Visibilidad en el deployment pipeline**
- En un ciclo CI/CD, el monitoreo continuo permite:
  - Validar que nuevos deployments no degraden el rendimiento
  - Hacer rollbacks automáticos si las métricas caen fuera de umbrales aceptables
  - Implementar estrategias de **canary deployments** con confianza

#### 4. **Optimización de recursos y costos**
- Las métricas de CPU, memoria y disco ayudan a:
  - Rightsizing de instancias (evitar sobreprovisionamiento)
  - Identificar servicios que pueden beneficiarse de caching o optimización
  - Planificar capacidad basándose en tendencias reales de uso

#### 5. **Cultura de mejora continua**
- Los datos objetivos eliminan especulaciones sobre el rendimiento del sistema.
- Facilitan conversaciones basadas en evidencia durante retrospectivas y planificación.
- Permiten establecer SLOs (Service Level Objectives) medibles.

#### 6. **Debugging distribuido**
- En arquitecturas de microservicios, la observabilidad permite:
  - Tracing de requests a través de múltiples servicios
  - Identificar cuellos de botella en la cadena de dependencias
  - Correlacionar errores en diferentes componentes

## Referencias

-   https://docs.docker.com/
-   https://prometheus.io/docs/
-   https://grafana.com/docs/
-   https://flask.palletsprojects.com/
-   https://nginx.org/en/docs/
