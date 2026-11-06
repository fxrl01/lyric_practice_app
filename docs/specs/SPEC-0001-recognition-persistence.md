# SPEC-0001: Persistencia del reconocimiento

- **Estado:** verified
- **Módulo:** `song_recognition`
- **Fecha:** 2026-11-05

## 1. Problema

El backend reconoce o intenta reconocer una muestra, pero necesita conservar la
canción normalizada y el resultado del intento para habilitar historial y
diagnóstico.

## 2. Objetivo

Persistir canciones reconocidas y cada intento de reconocimiento mediante un
repositorio de dominio y un adaptador SQLAlchemy, sin exponer audio crudo.

## 3. Fuera de alcance

- Autenticación de usuarios.
- Historial HTTP para el cliente.
- Persistencia de letras.
- Almacenamiento permanente del audio.
- Conexión a un proveedor real durante las pruebas.

## 4. Contrato

Una respuesta normalizada con canción genera una fila en `songs` y una fila en
`recognitions`. Un resultado sin canción solo genera `recognitions`.

## 5. Criterios de aceptación

- [x] Una canción reconocida se persiste en `songs`.
- [x] El intento se persiste en `recognitions`.
- [x] El dominio no importa SQLAlchemy.
- [x] El repositorio funciona con SQLite de prueba.
- [x] No se persiste audio base64.
- [x] Alembic puede aplicar y revertir el esquema inicial.

## 6. Evidencia

- `backend/tests/test_database.py`
- `alembic upgrade head`
- `alembic downgrade base`
- `9 tests passed`
- `ruff check .`

