# Path de estudio AZ-900 (Azure Fundamentals)

Organizado según los 3 dominios oficiales del examen. Cada tema marca si ya
lo viviste en `azure-microservices-demo` (✅), si se repasó en una sesión de
preguntas y respuestas (🎓), o si es puramente conceptual y aún falta
repasar (📖). El objetivo: saber exactamente qué te falta antes de hacer
exámenes de práctica.

> **Actualización**: se hizo una sesión de repaso interactivo (preguntas de
> práctica) cubriendo CapEx/OpEx, Shared Responsibility Model, economías de
> escala, tipos de nube, alta disponibilidad/escalabilidad/elasticidad/
> tolerancia a fallos, Availability Zones, Region Pairs, redundancia de
> Storage, Management Groups (incluyendo anidación y scope de políticas),
> Cosmos DB, Storage Tiers, Load Balancer/App Gateway/Front Door, Key Vault/
> MFA/Conditional Access/Zero Trust/Defender for Cloud, Azure Advisor/Service
> Health/Blueprints/VM Scale Sets, SLA (incluyendo composite SLA), Planes de
> Soporte, Pricing/TCO Calculator, Compliance/Trust Center, y reconocimiento
> de servicios de IA/IoT/Datos — **17/17 preguntas de práctica correctas**.
> Todos estos temas quedan marcados como repasados (🎓) abajo.

**Formato del examen**: opción múltiple, ~40-60 preguntas, 85% para aprobar,
sin laboratorios ni hands-on. Recurso oficial gratis: [Microsoft Learn - AZ-900](https://learn.microsoft.com/training/courses/az-900t00).

---

## Dominio 1: Describir conceptos de la nube (25-30%)

| Tema | Estado | Notas |
|---|---|---|
| IaaS vs PaaS vs SaaS | ✅ | Viviste IaaS (VM) → PaaS (App Service) en el Proyecto 1 |
| CapEx vs OpEx | 🎓 | CapEx = comprar hardware por adelantado; OpEx = pagar por uso, como la nube. Pura definición. |
| Economías de escala | 🎓 | Azure compra hardware masivamente y reparte el ahorro — concepto de negocio, no técnico |
| Alta disponibilidad / escalabilidad / elasticidad / agilidad / tolerancia a fallos | ✅ parcial | Viviste escalabilidad real con KEDA (Proyecto 3). Alta disponibilidad y tolerancia a fallos: solo conceptuales aquí (no configuramos multi-región ni Availability Zones) |
| Consistencia / confiabilidad | 🎓 | Definiciones — cuánto tiempo funciona un servicio según lo prometido (ver SLA, abajo) |
| Nube pública vs privada vs híbrida | 🎓 | Todo lo que hiciste fue nube **pública**. Híbrida = mezcla on-premises + nube (ej. Azure Arc, VPN Gateway) — nunca lo tocamos |

**Para repasar**: es la sección más "de libro" — casi nada se aprende haciendo. Un repaso de 1-2 horas en Microsoft Learn cubre esto completo.

---

## Dominio 2: Describir arquitectura y servicios de Azure (35-40%)

### 2.1 Componentes arquitectónicos core

| Tema | Estado | Notas |
|---|---|---|
| Regiones | ✅ | Usaste `centralus` todo el proyecto |
| Availability Zones | 🎓 | Centros de datos físicamente separados DENTRO de una región — nunca configuramos zone-redundancy explícita |
| Region Pairs | 🎓 | Cada región de Azure tiene una "pareja" para disaster recovery — puramente conceptual |
| Resource Groups | ✅ | Los usaste constantemente (`rg-microservices`, etc.) |
| Subscriptions | ✅ parcial | Solo usaste UNA suscripción en todo el proyecto |
| **Management Groups** | 🎓 | La jerarquía **por encima** de las suscripciones — para organizar MÚLTIPLES suscripciones (ej. una empresa con 10 suscripciones agrupadas por departamento). Nunca lo necesitaste con una sola suscripción |
| Azure Resource Manager (ARM) | ✅ | Es literalmente lo que usa Bicep por debajo — lo viviste a fondo en el Proyecto 4 |

### 2.2 Cómputo

| Tema | Estado | Notas |
|---|---|---|
| Máquinas Virtuales | ✅ | Proyecto 1 (IaaS original) |
| App Service | ✅ | Proyecto 1 (migración a PaaS) |
| Container Apps / AKS | ✅ | Proyecto 3 — dominas Container Apps a un nivel muy superior al que pide el examen |
| Azure Functions | ✅ | Proyecto 2 (serverless) |
| Virtual Machine Scale Sets | 🎓 | Escalado automático de VMs (el equivalente "viejo" al autoscaling que hiciste con KEDA en contenedores) |

### 2.3 Redes

| Tema | Estado | Notas |
|---|---|---|
| VNets, Subnets | ✅ | Proyecto 3b — dominas esto más de lo que pide el examen |
| NSG | ✅ | Proyecto 3b |
| Private Endpoints | ✅ | Proyecto 3b — tema avanzado, ni siquiera aparece con detalle en AZ-900 |
| Azure DNS | 🎓 | Usaste Private DNS Zones (más avanzado); DNS público de Azure nunca lo tocaste |
| VPN Gateway / ExpressRoute | 🎓 | Conexión de tu red local a Azure — lo mencionamos en teoría (cómo un DBA accede a una DB sin acceso público) pero nunca lo implementamos |
| Load Balancer / Application Gateway / Front Door | 🎓 | Nunca los usamos explícitamente (Container Apps maneja su propio balanceo internamente) |

### 2.4 Almacenamiento

| Tema | Estado | Notas |
|---|---|---|
| Blob Storage | ✅ | Proyecto 2 (`uploads`/`processed`) |
| Tiers de Storage (Hot/Cool/Archive) | 🎓 | Nunca configuramos tiers explícitos |
| Redundancia (LRS, ZRS, GRS, RA-GRS) | 🎓 | Cuántas copias de tus datos guarda Azure y en cuántos lugares — puramente conceptual, no lo configuramos |
| Azure Files, Disk Storage | 🎓 | No los usamos (usamos Blob y SQL) |

### 2.5 Bases de datos

| Tema | Estado | Notas |
|---|---|---|
| Azure SQL Database | ✅ | A fondo — Proyectos 1 y 3, incluyendo Private Endpoint |
| Cosmos DB | 🎓 | Base de datos NoSQL multi-modelo de Azure — nunca la tocamos |
| Modelo serverless de SQL | ✅ | Lo usaste (`auto-pause-delay`) |

### 2.6 Identidad, redes y seguridad generales

| Tema | Estado | Notas |
|---|---|---|
| Azure AD / Entra ID (conceptos básicos) | ✅ parcial | Usaste Managed Identity, AAD-only auth, OIDC — más avanzado que lo que pide el examen, pero repasa los CONCEPTOS básicos (qué es un "tenant", diferencia entre "usuario" y "grupo") |
| Managed Identity | ✅ | A fondo, en cada proyecto |
| RBAC | ✅ | A fondo — asignaste roles constantemente |
| MFA (Multi-Factor Authentication) | 🎓 | Nunca la configuramos — es puramente conceptual para el examen |
| Conditional Access | 🎓 | Reglas de acceso condicional (ej. "requiere MFA si te conectas desde fuera del país") — nunca lo tocamos |
| Zero Trust | 🎓 | Modelo de seguridad conceptual ("nunca confíes, siempre verifica") — pura teoría |
| Defender for Cloud | 🎓 | Herramienta de seguridad/postura de Azure — nunca la abrimos |
| Key Vault | 🎓 | Almacén de secretos — lo MENCIONAMOS (Proyecto 1, arquitectura IaaS) pero nunca lo implementamos a fondo |

### 2.7 Servicios generales / IA / IoT (nivel "saber que existen")

| Tema | Estado | Notas |
|---|---|---|
| Azure AI Services (Cognitive Services, OpenAI, etc.) | 🎓 | Nunca los tocamos — para AZ-900 basta con saber que existen y para qué sirven a grandes rasgos |
| Azure IoT Hub | 🎓 | Ídem — solo reconocimiento de nombre y propósito |
| Azure Synapse / Data Factory / Databricks | 🎓 | Servicios de datos a gran escala — solo reconocimiento |

---

## Dominio 3: Gestión y gobernanza (30-35%)

| Tema | Estado | Notas |
|---|---|---|
| Cost Management + Budgets | ✅ | Proyecto 5 — lo implementaste de verdad, incluyendo el matiz de que un budget NO detiene el gasto solo |
| Calculadora de precios (Pricing Calculator) | 🎓 | Herramienta web, nunca la abrimos — estima costos ANTES de crear algo |
| TCO Calculator | 🎓 | Compara costo de on-premises vs Azure — nunca lo usamos |
| Tags | ✅ | Proyecto 5 |
| Azure Policy | ✅ | Proyecto 5 — con la lección real de `deny` vs `modify` |
| Azure Blueprints | 🎓 | Empaqueta Policy + RBAC + templates ARM en un solo paquete reutilizable — nunca lo usamos (relacionado conceptualmente con lo que Bicep hace, pero es un servicio distinto) |
| Resource Locks | ✅ | Proyecto 5 — probado en vivo con un intento real de borrado bloqueado |
| Azure Advisor | 🎓 | Recomendaciones automáticas de Azure (costo, seguridad, rendimiento) — nunca lo abrimos, es gratis y vale la pena revisarlo aunque sea una vez en el portal |
| Service Health / Resource Health | 🎓 | Dashboard de salud de los servicios de Azure (incidentes, mantenimientos) — nunca lo revisamos |
| Azure Monitor (general) | ✅ parcial | Usaste Log Analytics + Alertas (Proyecto 5) — pero nunca exploramos el dashboard general de Monitor ni Application Insights a fondo |
| Herramientas de gestión: Portal, CLI, PowerShell, Cloud Shell | ✅ parcial | Dominas CLI muchísimo. PowerShell: nunca lo usamos (todo fue `az`, no `Az` de PowerShell). Portal: lo usaste puntualmente (Query Editor, Bastion conceptual) |
| Azure Mobile App | 🎓 | Solo reconocimiento — existe una app para monitorear Azure desde el celular |
| SLA (Service Level Agreement) | 🎓 | **Muy preguntado en el examen** — qué garantiza Microsoft de disponibilidad (ej. 99.9%), y cómo se calcula un "composite SLA" cuando combinas servicios |
| Planes de soporte (Basic, Developer, Standard, Premier) | 🎓 | Qué incluye cada uno, tiempos de respuesta — pura memorización |
| Compliance / Trust Center / Compliance Manager | 🎓 | Documentación de cumplimiento normativo de Microsoft (GDPR, HIPAA, etc.) — 100% teórico |

---

## Repaso de errores reales (Practice Assessment oficial, 80% primer intento)

Conceptos fallados en el primer intento del [Practice Assessment oficial](https://learn.microsoft.com/credentials/certifications/exams/az-900/practice/assessment?assessment-type=practice&assessmentId=23) — quedaron confirmados como entendidos tras el repaso:

1. **ARM vs Azure CLI vs API Management**: ARM es la capa de gestión de fondo (crea/actualiza/borra recursos); CLI/PowerShell/Portal son solo herramientas que le hablan a ARM; API Management es para publicar TUS PROPIAS APIs, nada que ver con desplegar recursos.
2. **SaaS se licencia por suscripción fija**; PaaS/IaaS son pago por consumo.
3. **VNet Peering conecta VNets entre sí**; NSG es solo un firewall, no conecta redes.
4. **Conditional Access evalúa contexto** (dispositivo, ubicación); MFA es solo "pide un factor extra", una posible acción DENTRO de una regla de Conditional Access.
5. **Defense in Depth = múltiples capas de seguridad**; Least Privilege es una práctica específica, una pieza de Defense in Depth, no el nombre de la estrategia completa.
6. **Cost Management administra costos de lo ya desplegado** (budgets, históricos, pronósticos); TCO Calculator compara ANTES de desplegar (on-premises vs Azure).
7. **Azure Arc** extiende la gestión de Azure a recursos fuera de Azure (on-premises, AWS, GCP, Kubernetes) — aparecen en el portal como nativos.
8. **Azure Monitor** es la plataforma completa y puede disparar autoscaling; **Application Insights** es solo la parte de rendimiento de aplicación (APM) dentro de Monitor.

## Segundo intento: 90% (subió de 80%, en la mitad del tiempo)

Errores del segundo intento, ya confirmados como entendidos:

9. **Datos e identidad/acceso de usuarios son SIEMPRE responsabilidad del cliente**, en CUALQUIER modelo (IaaS/PaaS/SaaS) — nunca son del proveedor. De igual forma, la red física/datacenter físico son SIEMPRE del proveedor, incluso en IaaS. Solo las capas de en medio (SO, controles de red, aplicación) cambian según el modelo.
10. **Servicios para correr contenedores**: Azure Container Instances (contenedor suelto, sin orquestación) y AKS (orquestación completa) — Azure Functions es serverless por eventos, no la respuesta típica para "correr contenedores".
11. **VPN Site-to-Site**: el *Local Network Gateway* representa la red on-premises; el *Virtual Network Gateway* representa el lado de Azure. *VNet-to-VNet* es un escenario distinto (conectar 2 VNets de Azure entre sí, no on-premises con Azure).
12. **Remote Desktop (RDP) controla una VM que YA EXISTE** — no sirve para crear una VM nueva. Para crear/administrar desde un celular: Azure Portal o Cloud Shell (PowerShell/CLI), ambos vía navegador.
13. **Service Health tiene 3 pestañas distintas**: *Service issues* (interrupciones activas), *Planned maintenance* (mantenimientos programados), y **Health advisories** (retiros de servicio, breaking changes futuros) — Azure Monitor no cubre esto, solo vigila TUS recursos.

## Plan de repaso sugerido

Dado que ya tienes MUCHO del Dominio 2 y 3 cubierto por experiencia real, el repaso eficiente es:

1. ~~Dominio 1 completo~~ ✅ — cubierto (CapEx/OpEx, Shared Responsibility Model, economías de escala, tipos de nube, HA/escalabilidad/elasticidad/tolerancia a fallos, consistencia)
2. ~~Dominio 2~~ ✅ — cubierto (Availability Zones, Region Pairs, Management Groups, Cosmos DB, Storage Tiers/redundancia/Files, Load Balancer/App Gateway/Front Door, VPN Gateway/ExpressRoute, Azure DNS, IA/IoT/Datos)
3. ~~Dominio 3~~ ✅ — cubierto (SLA, Planes de Soporte, Pricing/TCO Calculator, Compliance, Key Vault/MFA/Conditional Access/Zero Trust/Defender, Advisor/Service Health/Blueprints/VM Scale Sets)
4. **Siguiente paso: exámenes de práctica** — con el temario conceptual ya cubierto (20+ preguntas de práctica correctas en esta sesión), toca hacer 2-3 exámenes de práctica completos (MeasureUp es el oficial de Microsoft, o el simulador gratuito de examtopics/whizlabs) para identificar huecos específicos y acostumbrarte al formato/tiempo real del examen

**Ventaja real que tienes sobre alguien que solo memorizó**: en las preguntas de escenario (“¿qué servicio usarías para X?”), vas a reconocer los patrones porque los **viviste**, no solo los leíste — eso vale mucho más que memorizar definiciones sueltas.
