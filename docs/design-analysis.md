# Análisis de diseño

## 1. Propósito del producto

LyricFlow ayuda a una persona a identificar una canción, consultar y practicar
sus letras y, posteriormente, transcribir, traducir y analizar audio musical.
El reconocimiento tipo Shazam es una capacidad de entrada; el objetivo
principal es el aprendizaje y la práctica musical.

## 2. Alcance por etapas

### MVP actual

- Capturar una muestra corta desde el micrófono.
- Reconocer una canción mediante un proveedor externo o un modo demo.
- Obtener letras y mostrar un resultado.
- Mantener favoritos e historial local.

### Siguiente etapa

- Letras sincronizadas y experiencia de karaoke.
- Transcripción real con un proveedor intercambiable.
- Traducción explícita y cacheada.
- Manejo consistente de estados de carga, error, reintento y cancelación.

### Etapa posterior

- Separación de stems.
- Extracción de MIDI/piano roll.
- Sesiones de práctica persistentes.
- Backend propio para proteger credenciales, controlar cuotas y ejecutar
  trabajos pesados.

## 3. Actores y casos de uso

| Actor | Caso de uso | Resultado esperado |
|---|---|---|
| Estudiante | Reconocer canción | Canción identificada o error accionable |
| Estudiante | Consultar letras | Letras simples o sincronizadas |
| Estudiante | Traducir letras | Traducción asociada a la letra original |
| Estudiante | Practicar | Sesión con reproducción, stems o guía MIDI |
| Sistema | Cachear resultados | Menos llamadas, respuesta reproducible y TTL |
| Sistema | Reportar fallo | Mensaje útil sin ocultar el error técnico |

## 4. Requisitos no funcionales

- **Mantenibilidad:** cada módulo debe poder evolucionar sin importar
  detalles internos de otro módulo.
- **Testabilidad:** casos de uso y dominio deben probarse sin red, micrófono ni
  widgets.
- **Resiliencia:** timeout, cancelación, cuota agotada y proveedor no
  disponible deben tener estados explícitos.
- **Seguridad:** ninguna API key debe ser necesaria en el cliente publicado;
  las integraciones con secretos deben migrar a backend.
- **Observabilidad:** registrar eventos técnicos sin incluir audio, letras
  privadas, tokens ni credenciales.
- **Portabilidad:** conservar compatibilidad con Android, iOS y Web cuando el
  caso de uso lo permita.
- **Coste controlado:** cachear respuestas y evitar enviar audio innecesario.

## 5. Riesgos actuales

| Riesgo | Impacto | Tratamiento |
|---|---|---|
| API keys en una app cliente | Exposición y abuso de cuota | Adaptadores detrás de backend |
| Transcripción demo presentada como real | Resultado incorrecto | Estado `unavailable`/`demo` explícito |
| Proveedores acoplados al dominio | Migración costosa | Interfaces en `domain`, adaptadores en `data` |
| Audio pesado o persistente | Coste y privacidad | Duración, tamaño y retención limitados |
| Stems/MIDI sin servicio real | UX engañosa | Contratos de jobs y estados verificables |
| Cache inconsistente | Datos obsoletos | TTL, versionado y política por recurso |

## 6. Principios de diseño

1. **El dominio manda:** entidades, reglas y contratos no conocen Flutter ni
   proveedores.
2. **Dependencias hacia adentro:** `presentation -> application/domain`;
   `data -> domain`; nunca al revés.
3. **Puertos antes que proveedores:** AudD, ACRCloud, Whisper, Google y
   lyrics.ovh son adaptadores reemplazables.
4. **Una responsabilidad por caso de uso:** reconocer, obtener letras,
   traducir y transcribir son operaciones separadas.
5. **Estados explícitos:** no usar datos demo como fallback silencioso de un
   error real.
6. **Cambios pequeños y verificables:** cada migración debe incluir pruebas del
   contrato afectado.

## 7. Decisiones de diseño pendientes

- Elegir backend y estrategia de autenticación cuando se requiera proteger
  proveedores.
- Definir almacenamiento persistente para historial, favoritos y sesiones.
- Definir política de derechos y retención de audio/letras.
- Elegir cola de trabajos para transcripción, stems y MIDI.
- Definir telemetría opt-in y datos mínimos de diagnóstico.

