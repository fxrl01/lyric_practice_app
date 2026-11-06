# LyricFlow backend

Backend modular inicial para LyricFlow. Ya incluye la base de persistencia
preparada para PostgreSQL y un fallback SQLite para desarrollo local.

## Estructura

```text
backend/
  src/lyricflow_backend/
    api/             # FastAPI app, routers y DTOs HTTP
    application/     # Casos de uso y puertos de aplicación
    domain/          # Entidades y contratos de negocio
    infrastructure/  # Adaptadores, configuración y persistencia
```

La dependencia debe fluir hacia el dominio:

```text
api -> application -> domain
infrastructure -> domain
```

La API actual responde salud y readiness. El reconocimiento usa AudD cuando
`RECOGNITION_PROVIDER=audd` y `AUDD_API_KEY` están configurados; de lo contrario
devuelve `not_configured`. No usa datos demo ni expone credenciales.

## Ejecutar localmente

Desde `backend/`:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -e '.[dev]'
cp .env.example .env
uvicorn lyricflow_backend.main:app --reload
```

Endpoints:

- `GET /`
- `GET /health`
- `GET /ready`
- `GET /api/v1/recognitions/capabilities`
- `POST /api/v1/recognitions`
- `GET /api/v1/recognitions/history?limit=20&offset=0`
- `GET /api/v1/lyrics?title=...&artist=...`

Lyrics are requested through the backend from `lyrics.ovh` and are returned
as pass-through content with attribution. They are not persisted.

## Persistencia

Configura `DATABASE_URL` con PostgreSQL en un entorno real:

```env
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/lyricflow
```

El valor por defecto usa SQLite para desarrollo. Las tablas iniciales son
`songs` y `recognitions`. El caso de uso de reconocimiento ya persiste el
resultado normalizado cuando recibe una respuesta del proveedor.

Aplica el esquema con Alembic antes de iniciar la API:

```bash
alembic upgrade head
```

Para revertir la última migración:

```bash
alembic downgrade -1
```

La API ya no crea tablas automáticamente al arrancar; las migraciones son la
fuente de verdad del esquema.

## Validar

```bash
pytest
ruff check .
```
