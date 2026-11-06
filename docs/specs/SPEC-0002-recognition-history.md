# SPEC-0002: Consulta de historial de reconocimientos

- **Estado:** verified
- **Módulo:** `song_recognition`
- **Fecha:** 2026-11-05

## 1. Problema

El backend ya persiste canciones e intentos de reconocimiento, pero no ofrece
una forma de consultarlos desde el cliente.

## 2. Objetivo

Exponer un endpoint paginado que devuelva los reconocimientos más recientes,
sin audio crudo ni credenciales.

## 3. Fuera de alcance

- Autenticación y separación por usuario.
- Eliminación de historial.
- Sincronización con el historial local existente.
- Filtros avanzados por proveedor o artista.

## 4. Contrato

```text
GET /api/v1/recognitions/history?limit=20&offset=0
```

`limit` acepta de 1 a 100 y `offset` debe ser mayor o igual a cero.

La respuesta contiene `items`, `limit`, `offset` y `total`.

## 5. Criterios de aceptación

- [x] Devuelve reconocimientos ordenados del más reciente al más antiguo.
- [x] Respeta `limit` y `offset`.
- [x] Incluye canción normalizada cuando existe.
- [x] No incluye audio base64 ni secretos.
- [x] Devuelve lista vacía con `200` cuando no hay registros.
- [x] Valida parámetros inválidos con `422`.

## 6. Diseño técnico

- Añadir puerto de consulta en `domain`.
- Implementar consulta SQLAlchemy en `infrastructure`.
- Añadir schemas y router en `api`.
- Usar el mismo `AsyncSession` inyectado por FastAPI.

## 7. Pruebas

- Repositorio con datos ordenados y paginación.
- Endpoint vacío.
- Validación de parámetros.

Evidencia: `12 tests passed`, `ruff check .` y `git diff --check`.
