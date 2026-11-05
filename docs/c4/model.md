# C4 - LyricFlow

## Nivel 1: contexto del sistema

```mermaid
flowchart LR
  User[Estudiante musical]
  App[LyricFlow]
  Recognition[Proveedor de reconocimiento]
  Lyrics[Proveedor de letras]
  AI[Proveedor de IA]
  Auth[Proveedor de identidad]

  User -->|Identifica canciones y practica| App
  App -->|Audio/muestra de reconocimiento| Recognition
  App -->|Consulta letras| Lyrics
  App -->|Transcripción/traducción| AI
  App -->|Autenticación| Auth
```

**Estado:** objetivo inmediato. Hoy las llamadas a proveedores salen del
cliente; el objetivo es moverlas detrás del backend.

## Nivel 2: contenedores

```mermaid
flowchart TB
  User[Estudiante] --> Flutter[Flutter app<br/>Android / iOS / Web]
  Flutter -->|HTTPS| API[Backend API<br/>FastAPI]
  Flutter -->|Audio local| Device[Micrófono y reproductor]
  API --> DB[(PostgreSQL)]
  API --> Storage[(Object storage)]
  API --> Queue[(Redis queue)]
  Queue --> Worker[Audio worker<br/>Python]
  API --> Providers[Proveedores externos]
  Worker --> Providers
```

### Responsabilidad de cada contenedor

| Contenedor | Responsabilidad | Estado |
|---|---|---|
| Flutter app | UI, captura, reproducción, estado de pantalla | Actual |
| Backend API | Auth, contratos, secretos, rate limit, orquestación | Objetivo |
| PostgreSQL | Fuente de verdad de usuarios y resultados | Objetivo |
| Object storage | Audio temporal y artefactos grandes | Objetivo |
| Redis queue | Trabajos y reintentos | Objetivo |
| Audio worker | Transcripción, stems y MIDI | Objetivo |
| Proveedores | Reconocimiento, letras y modelos externos | Parcial |

## Nivel 3: componentes de la app Flutter

```mermaid
flowchart LR
  Screens[Presentation<br/>screens/widgets] --> Providers[Riverpod providers]
  Providers --> UseCases[Application<br/>use cases]
  UseCases --> Ports[Domain ports]
  Ports --> Adapters[Data adapters]
  Adapters --> Http[HTTP client]
  Adapters --> Local[Local storage]
  Ports --> Platform[Audio/platform ports]
  Platform --> Device[Device APIs]
```

Componentes de negocio:

- `SongRecognition`: captura y reconocimiento.
- `Lyrics`: letras, sincronización y traducción.
- `Transcription`: trabajos de transcripción.
- `Practice`: sesiones, stems y MIDI.
- `Shared platform`: audio, permisos, cache, logging y configuración.

## Nivel 3: componentes del backend objetivo

```mermaid
flowchart LR
  Router[HTTP routers] --> Auth[Auth boundary]
  Router --> Recognition[Recognition application service]
  Router --> Lyrics[Lyrics application service]
  Router --> Jobs[Processing jobs service]
  Recognition --> Providers[Provider adapters]
  Lyrics --> Providers
  Jobs --> Queue[Queue adapter]
  Jobs --> Storage[Storage adapter]
  Recognition --> Repos[Repositories]
  Lyrics --> Repos
  Jobs --> Repos
  Repos --> DB[(PostgreSQL)]
```

## Nivel dinámico: reconocer una canción

```mermaid
sequenceDiagram
  participant U as Usuario
  participant F as Flutter
  participant A as Backend API
  participant R as Recognition adapter
  participant P as Proveedor
  participant D as PostgreSQL

  U->>F: Inicia reconocimiento
  F->>A: POST /recognitions
  A->>R: Reconocer audio
  R->>P: Solicitud con secreto del servidor
  P-->>R: Metadata normalizada
  R-->>A: Song result
  A->>D: Persistir reconocimiento
  A-->>F: Resultado o error tipado
  F-->>U: Canción y siguientes acciones
```

## Nivel de despliegue objetivo

```text
Dispositivo
  └── Flutter app
          │ HTTPS
          ▼
     API runtime
       ├── PostgreSQL administrado
       ├── Object storage
       └── Redis
              └── Audio worker
```

El despliegue inicial puede ser un único runtime para API y un worker
independiente. El worker se separa porque sus tiempos, memoria y dependencias
de ML no deben bloquear solicitudes HTTP.

