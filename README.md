# LyricFlow

Aplicación Flutter para reconocimiento de canciones, letras y práctica
musical asistida por IA.

## Estado

El proyecto contiene un MVP de reconocimiento, letras, favoritos, historial y
pantallas iniciales para transcripción y práctica. Algunas integraciones de IA,
stems y MIDI todavía están en preparación.

## Arquitectura

La dirección técnica es un monolito modular con Clean Architecture y puertos
de integración hexagonales. La documentación está en [`docs/`](./docs/):

- [`design-analysis.md`](./docs/design-analysis.md)
- [`architecture.md`](./docs/architecture.md)
- [`adr/0001-modular-monolith.md`](./docs/adr/0001-modular-monolith.md)
- [`sdd/README.md`](./docs/sdd/README.md)

## Desarrollo local

1. Instalar Flutter compatible con el SDK indicado en `pubspec.yaml`.
2. Copiar `.env.example` a `.env` y completar las claves solo localmente.
3. Ejecutar:

   ```bash
   flutter pub get
   flutter test
   flutter run
   ```

No publiques `.env`: las credenciales deben mantenerse fuera del repositorio.

## Proceso de desarrollo

Los cambios funcionales se trabajan con Specification-Driven Development
(SDD): primero se define una spec verificable, después se implementa y se
validan sus criterios de aceptación.
