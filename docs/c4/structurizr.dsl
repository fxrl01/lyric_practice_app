workspace "LyricFlow" "Modelo C4 objetivo de la plataforma musical" {
    model {
        student = person "Estudiante musical" "Identifica canciones y practica letras."

        lyricFlow = softwareSystem "LyricFlow" "Reconocimiento musical, letras y práctica."
        recognition = softwareSystem "Proveedor de reconocimiento" "Identifica canciones a partir de audio."
        lyrics = softwareSystem "Proveedor de letras" "Entrega letras y metadatos."
        ai = softwareSystem "Proveedor de IA" "Transcribe y traduce audio o texto."
        identity = softwareSystem "Proveedor de identidad" "Autenticación y sesiones."

        student -> lyricFlow "Usa"
        lyricFlow -> recognition "Reconoce canciones"
        lyricFlow -> lyrics "Consulta letras"
        lyricFlow -> ai "Transcribe y traduce"
        lyricFlow -> identity "Autentica usuarios"

        flutter = container lyricFlow "Flutter app" "Flutter/Dart" "UI, captura de audio, reproducción y estado local."
        api = container lyricFlow "Backend API" "FastAPI/Python" "Contratos HTTP, autenticación, secretos y orquestación."
        database = container lyricFlow "PostgreSQL" "PostgreSQL" "Fuente de verdad de usuarios, canciones y trabajos."
        storage = container lyricFlow "Object storage" "S3-compatible" "Audio temporal y artefactos grandes."
        queue = container lyricFlow "Processing queue" "Redis" "Trabajos y reintentos."
        worker = container lyricFlow "Audio worker" "Python" "Transcripción, separación de stems y extracción MIDI."

        student -> flutter "Interactúa"
        flutter -> api "Consume HTTPS/JSON"
        flutter -> identity "Autentica"
        api -> database "Lee y escribe"
        api -> storage "Gestiona referencias"
        api -> queue "Encola trabajos"
        queue -> worker "Entrega trabajos"
        worker -> storage "Lee/escribe artefactos"
        api -> recognition "Solicita reconocimiento"
        api -> lyrics "Consulta letras"
        worker -> ai "Solicita procesamiento"
    }

    views {
        systemContext lyricFlow "SystemContext" {
            include *
            autolayout lr
        }

        container lyricFlow "Containers" {
            include *
            autolayout lr
        }

        theme default
    }
}
