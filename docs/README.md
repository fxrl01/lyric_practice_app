# Documentación de arquitectura y diseño

Esta carpeta contiene las decisiones y modelos que guían la evolución de
LyricFlow. La documentación describe el estado objetivo; no implica que todas
las integraciones estén implementadas todavía.

## Documentos

- [Análisis de diseño](./design-analysis.md): objetivos, restricciones,
  riesgos, casos de uso y criterios de calidad.
- [Arquitectura objetivo](./architecture.md): estructura del monolito modular,
  límites de módulos, dependencias y flujos principales.
- [ADR-0001: monolito modular](./adr/0001-modular-monolith.md): decisión de
  arquitectura y condiciones para una futura extracción de servicios.
- [Tecnologías y responsabilidades](./technology-stack.md): inventario actual,
  backend/frontend recomendado, datos y fases de evolución.
- [Modelo C4](./c4/README.md): contexto, contenedores, componentes y despliegue.
- [Backend](../backend/README.md): ejecución y validación del backend modular.

## Cómo usar estos documentos

1. Antes de agregar una feature, identificar el módulo dueño del caso de uso.
2. Mantener el dominio independiente de Flutter, Dio, APIs externas y
   almacenamiento.
3. Registrar decisiones que cambien límites, dependencias o contratos como un
   nuevo ADR.
4. Actualizar esta documentación cuando la implementación se desvíe
   intencionalmente del diseño.
