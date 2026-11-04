# 🔑 Cómo obtener API Key de AudD.io (GRATIS)

Para que LyricFlow funcione correctamente y reconozca canciones en tiempo real como Shazam, necesitas una API key gratuita de AudD.io.

## 🚀 Pasos para obtener la API key:

### 1. Registrarse en AudD.io
- Ve a: **https://dashboard.audd.io/**
- Haz click en **"Sign Up"** o **"Register"**
- Usa tu email (no requiere verificación compleja)

### 2. Obtener tu API Token
- Después de registrarte, ve al **Dashboard**
- Copia tu **API Token** (empieza con algo como `abc123...`)

### 3. Configurar en LyricFlow
Edita el archivo `.env` del proyecto:

```bash
# Abre el archivo .env
nano /home/fernando/Proyectos/lyric_practice_app/.env
```

Agrega tu API key:

```env
# API Key de AudD.io (GRATIS)
AUDD_API_KEY=tu_api_key_aqui
```

### 4. Reiniciar la app
- Reconstruye la app web:
```bash
cd /home/fernando/Proyectos/lyric_practice_app
flutter build web --release
```

### 5. Probar
- Abre http://localhost:8080
- Ahora debería reconocer canciones reales

---

## ⚠️ ¿Por qué necesito API key?

**Sin API key:**
- Solo funciona en modo demo (canciones predefinidas)
- Límite muy bajo de requests
- No reconoce canciones reales

**Con API key gratuita:**
- ✅ Reconocimiento real de cualquier canción
- ✅ Hasta 50 requests por mes (suficiente para testing)
- ✅ Respuestas rápidas (1-3 segundos)
- ✅ Metadata completa (título, artista, álbum, cover, etc.)

---

## 🔧 Alternativas si AudD no funciona

### 1. ACRCloud (también gratis)
- Registro: https://www.acrcloud.com/
- Más preciso que AudD
- Configura en `.env`:
```env
ACRCLOUD_ACCESS_KEY=tu_access_key
ACRCLOUD_ACCESS_SECRET=tu_secret
ACRCLOUD_HOST=identify-eu-west-1.acrcloud.com
```

### 2. Modo demo mejorado
Si no quieres API key, la app ahora muestra:
- 5 canciones demo diferentes (no solo Bohemian Rhapsody)
- Respuestas aleatorias más realistas
- Pero **NO** reconocerá canciones reales

---

## 🎯 Para reconocimiento tipo Shazam (rápido)

Con API key configurada, LyricFlow ahora:
- Graba solo **3 segundos** de audio (como Shazam)
- Optimiza el audio para envío rápido
- Procesa en tiempo real
- Identifica canciones en 2-5 segundos

---

## ❓ Solución de problemas

### "Permiso de micrófono denegado"
- **Chrome/Edge:** Asegúrate de que http://localhost:8080 tenga permiso de micrófono
- Click en el ícono de candado (🔒) en la barra de URL → "Permitir" micrófono
- O usa https://localhost:8080 (requiere configuración extra)

### "Audio de baja calidad"
- Acerca el micrófono a la fuente de música
- Sube el volumen
- Graba en ambiente silencioso

### "No reconoce mi canción"
- Asegúrate de tener API key configurada
- La canción debe estar en la base de datos de AudD (casi todas lo están)
- Intenta con una canción popular primero