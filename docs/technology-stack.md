# Tecnologías y responsabilidades

## Estado real del repositorio

| Área | Implementado actualmente | Observación |
|---|---|---|
| Frontend | Flutter/Dart, Riverpod, GoRouter, Dio | Cliente multiplataforma |
| UI | Material, Google Fonts, Flutter Animate | No hay frontend web separado |
| Audio | `record`, `just_audio`, `permission_handler` | Captura y reproducción local |
| Configuración | `flutter_dotenv` | No es seguro para secretos de producción |
| Persistencia | `shared_preferences` | Cache e historial local; no es una base de datos |
| Backend | FastAPI scaffold en `backend/` | Aún sin proveedor externo ni base de datos |
| Base de datos | Ninguna remota | No existe Postgres, SQLite ni servidor propio |
| Proveedores | AudD/ACRCloud, letras, OpenAI/Google previstos | Algunos adaptadores todavía son demo |
| Procesamiento pesado | No implementado | Stems y MIDI solo tienen contratos preliminares |
| Testing | `flutter_test`, Mocktail | Predominan pruebas unitarias; faltan contratos e integración |

## Frontend recomendado

Mantener Flutter como único frontend para Android, iOS y Web durante el MVP.
La combinación actual es adecuada:

- **Flutter/Dart:** UI y capacidades de dispositivo.
- **Riverpod:** estado y composición reactiva.
- **GoRouter:** navegación declarativa.
- **Dio:** transporte HTTP detrás de puertos/adaptadores.
- **record/just_audio:** captura y reproducción.
- **SharedPreferences:** preferencias y cache pequeño, no datos de negocio
  críticos.

La mejora no consiste en cambiar de framework, sino en impedir que widgets,
providers de Riverpod o `AppConfig` conozcan APIs externas directamente.

## Backend recomendado por fases

### Fase A: MVP sin backend propio

Se puede conservar el cliente para validar UX, pero solo con datos demo o
proveedores que explícitamente permitan el uso cliente. No debe tratarse como
arquitectura de producción porque las API keys empaquetadas en Flutter pueden
extraerse.

### Fase B: backend modular (iniciada)

Introducir un backend único, no microservicios:

| Responsabilidad | Tecnología propuesta |
|---|---|
| API HTTP y contratos | FastAPI + Python |
| Base de datos | PostgreSQL |
| ORM/migraciones | SQLAlchemy + Alembic |
| Autenticación | Supabase Auth o proveedor OIDC |
| Archivos de audio/resultados | S3-compatible object storage |
| Jobs de audio | Worker Python separado del proceso HTTP |
| Cola | Redis + RQ/Celery, según necesidad de reintentos |
| Observabilidad | Logs estructurados, métricas y trazas |

La primera implementación está en [`backend/`](../backend/). Incluye
configuración tipada, health/readiness, contratos de reconocimiento y un
adaptador AudD detrás de `SongRecognitionPort`. Si la clave no está configurada,
responde `not_configured` y nunca simula resultados.

FastAPI/Python es especialmente conveniente para transcripción, separación de
stems y MIDI por su ecosistema de audio/ML. El worker debe ser un proceso
separado, pero sigue perteneciendo al mismo sistema y repositorio hasta que la
operación justifique dividirlo.

### Fase C: evolución

Extraer únicamente los componentes que tengan una razón medible para hacerlo:

- Worker de audio si requiere escalado independiente.
- Servicio de identidad si cambia el modelo de usuarios.
- Servicio de catálogo si el volumen y la búsqueda lo justifican.

No extraer reconocimiento, letras, traducción y práctica como microservicios
solo por tener carpetas separadas.

## Modelo de datos inicial

PostgreSQL debe ser la fuente de verdad del backend:

```text
users
songs
recognitions
lyrics
lyric_translations
practice_sessions
processing_jobs
audio_assets
```

Reglas:

- `songs` identifica la obra y conserva IDs externos por proveedor.
- `recognitions` registra una solicitud y su resultado, no el audio crudo.
- `lyrics` y `lyric_translations` se versionan por proveedor/idioma.
- `processing_jobs` modela transcripción, stems y MIDI con estados explícitos.
- `audio_assets` guarda metadatos y una referencia a object storage; no audio
  permanente en PostgreSQL.
- El audio debe tener TTL y consentimiento definido.

## Qué no debe hacerse ahora

- No crear un frontend React adicional mientras Flutter cubra las plataformas.
- No usar SharedPreferences como base de datos de usuarios o sesiones.
- No poner API keys de proveedores en una build publicada.
- No crear microservicios antes de tener carga, límites operativos o equipos
  separados.
- No mezclar DTOs JSON de AudD/OpenAI con entidades del dominio.

## Fuentes técnicas

- [Flutter: Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Riverpod](https://riverpod.dev/)
- [C4 model](https://c4model.com/)
- [Supabase documentation](https://supabase.com/docs)
