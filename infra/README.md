# Infraestructura como código (Bicep)

Convierte a Bicep declarativo la misma arquitectura que `scripts/*.sh`
construye de forma imperativa: VNet + Private Endpoint, ACR, Container Apps
Environment, Service Bus (2 topics, 5 suscripciones filtradas), SQL (sin
acceso público), y las 6 Container Apps con sus roles RBAC.

## Estructura

```
infra/
├── main.bicep                       ← orquestador
├── main.parameters.example.json     ← copia a main.parameters.json y llena tus valores
└── modules/
    ├── network.bicep                ← VNet, subnets, NSG
    ├── acr.bicep
    ├── containerAppsEnvironment.bicep
    ├── serviceBus.bicep             ← namespace, topics, subscriptions, SQL filters
    ├── sql.bicep                    ← server, db, Private Endpoint, Private DNS Zone
    └── containerApp.bicep           ← módulo genérico, reusado 6 veces desde main.bicep
```

## Limitaciones conocidas (por diseño de ARM/Bicep, no por descuido)

1. **No crea los usuarios SQL de Azure AD** (`CREATE USER FROM EXTERNAL
   PROVIDER`) — es T-SQL, no un recurso de ARM. Después de desplegar, corre
   manualmente `scripts/sql/01-schema.sql` y
   `scripts/sql/02-grant-managed-identities.sql` (con acceso público
   temporalmente habilitado, igual que en el flujo de `scripts/`).
2. **No construye ni sube las imágenes Docker** — asume que ya existen en ACR
   con el tag indicado en el parámetro `imageTag`. Corre
   `scripts/05-build-and-push-images.sh` antes de desplegar este Bicep.
3. **El frontend necesita la URL de `productsapi` "horneada" en el build**
   (Vite resuelve `import.meta.env.*` en tiempo de compilación, no en
   runtime) — por eso su imagen se construye en `scripts/06`, después de que
   `productsapi` ya tiene FQDN. Si despliegas todo con Bicep de una sola vez,
   la imagen de `frontend` en ACR debe haberse construido previamente con la
   URL correcta ya incluida.

## Cómo desplegar

```bash
cd infra
cp main.parameters.example.json main.parameters.json
# edita main.parameters.json con tus valores (nombres únicos, tu email/objectId de Azure AD)

az deployment group what-if \
  --resource-group rg-microservices \
  --template-file main.bicep \
  --parameters main.parameters.json

az deployment group create \
  --resource-group rg-microservices \
  --template-file main.bicep \
  --parameters main.parameters.json
```

`what-if` no aplica ningún cambio — solo muestra qué haría. Úsalo siempre
antes de un `create` real, sobre todo si ya tienes recursos existentes en el
resource group.
