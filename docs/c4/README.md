# Modelo C4 de LyricFlow

El modelo C4 se aplica de forma incremental:

1. **Contexto:** quién usa LyricFlow y con qué sistemas externos se relaciona.
2. **Contenedores:** app Flutter, API, worker, PostgreSQL, object storage y
   proveedores.
3. **Componentes:** módulos internos de la app y del backend.
4. **Código:** se documenta solo para decisiones o flujos difíciles; no se
   pretende diagramar cada clase.

En C4, “contenedor” significa una unidad desplegable o ejecutable, no
necesariamente Docker. Por eso las carpetas `lib/features` son componentes o
código, mientras que la app Flutter y el backend son contenedores.

## Documentos

- [Modelo C4 completo](./model.md)
- [DSL de Structurizr](./structurizr.dsl)

## Convención de actualización

Cada diagrama debe declarar si representa:

- **Actual:** lo que existe hoy en el repositorio.
- **Objetivo:** una capacidad planificada.
- **Transición:** un cambio que se implementará en una fase concreta.

No mezclar infraestructura futura con el diagrama actual sin marcarla como
objetivo.

