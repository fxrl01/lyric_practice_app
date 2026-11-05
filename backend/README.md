# LyricFlow backend

Backend modular inicial para LyricFlow. Esta primera fase define los límites
del sistema sin conectar todavía proveedores externos ni una base de datos.

## Estructura

```text
backend/
  src/lyricflow_backend/
    api/             # FastAPI app, routers y DTOs HTTP
    application/     # Casos de uso y puertos de aplicación
    domain/          # Entidades y contratos de negocio
    infrastructure/  # Adaptadores concretos y configuración
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

- `GET /health`
- `GET /ready`
- `GET /api/v1/recognitions/capabilities`
- `POST /api/v1/recognitions`

## Validar

```bash
pytest
ruff check .
```
