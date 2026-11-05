# ADR-0001: Monolito modular con Clean Architecture y puertos/adaptadores

- **Estado:** Aceptado
- **Fecha:** 2026-11-04
- **Alcance:** Estructura inicial de LyricFlow

## Contexto

La aplicación es un cliente Flutter con capacidades relacionadas pero
distintas: reconocimiento, letras, transcripción y práctica. El código ya
está agrupado por features, aunque algunas integraciones todavía son demo,
algunos datasources mezclan infraestructura con comportamiento temporal y no
existe una política documentada de dependencias.

Microservicios agregarían despliegues, autenticación, observabilidad y coste
antes de que existan límites operativos estables. Una arquitectura totalmente
hexagonal también sería innecesariamente ceremoniosa para una primera versión
si no se aplica con pragmatismo.

## Decisión

Mantener un único despliegue Flutter como **monolito modular**. Cada módulo se
organiza por capacidad de negocio y usa Clean Architecture internamente.
Las integraciones externas se conectan mediante puertos y adaptadores
hexagonales.

La composición de dependencias queda en `core/di`; las features no deben
instanciar clientes HTTP ni leer secretos directamente.

## Consecuencias positivas

- Menos complejidad operativa durante el MVP.
- Pruebas unitarias sin red, micrófono ni widgets.
- Proveedores intercambiables.
- Camino claro para extraer backend o jobs asíncronos.
- Cambios de una feature con menor riesgo de regresión cruzada.

## Consecuencias negativas

- El equipo debe respetar límites internos aunque exista un solo repositorio.
- Se necesita código de mapeo entre modelos externos e internos.
- La modularidad no impedirá por sí sola que se introduzcan dependencias
  indebidas; se requieren revisiones y pruebas.

## Alternativas descartadas por ahora

### Microservicios desde el inicio

Se descartan hasta que haya necesidades reales de escalado independiente,
procesamiento asíncrono o aislamiento de credenciales.

### Arquitectura por capas global

Se descarta como estructura principal porque tiende a agrupar código por tipo
(`screens`, `services`, `repositories`) y hace más difícil localizar y
evolucionar una capacidad completa.

### Hexagonal pura sin convenciones de Clean Architecture

Se descarta como única guía porque no define por sí sola una organización
práctica de presentación, aplicación y dominio para la app Flutter.

## Revisión de la decisión

Revisar este ADR cuando ocurra cualquiera de estas condiciones:

- Se necesite proteger API keys fuera del cliente.
- Stems/transcripción/MIDI requieran trabajos de larga duración.
- Un módulo necesite desplegarse o escalarse de forma independiente.
- El coste, cuota o rendimiento de un proveedor exija backend propio.

