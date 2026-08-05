# Infraestructura como código (Bicep)

Pendiente — próximo paso del proyecto. Los `scripts/*.sh` en la raíz del repo
son la fuente de verdad actual (imperativa) del despliegue; este directorio
convertirá esa misma infraestructura a Bicep declarativo.

Limitación conocida a documentar cuando se implemente: Bicep puede crear
todos los recursos de Azure, pero **no puede ejecutar el `CREATE USER FROM
EXTERNAL PROVIDER` en SQL** (es T-SQL, no un recurso de ARM) — para
automatizar eso por completo se necesitaría un recurso
`Microsoft.Resources/deploymentScripts`, o dejarlo como paso manual
documentado (como está hoy en `scripts/sql/`).
