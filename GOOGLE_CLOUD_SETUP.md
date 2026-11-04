# 🔧 Configurar Google Cloud API (GRATIS: $300 crédito)

Para usar **Transcripción IA** y **Traducción automática** gratis en LyricFlow, necesitas una API key de Google Cloud.

## 🚀 **Pasos rápidos (10 minutos):**

### **1. Crear cuenta Google Cloud**
- Ve a: **https://console.cloud.google.com/**
- Si no tienes cuenta, crea una (gratis, mismo email de Gmail)
- **IMPORTANTE:** Te dan **$300 USD de crédito** gratis por 90 días

### **2. Crear proyecto nuevo**
1. Click en el selector de proyectos (arriba a la izquierda)
2. **"New Project"**
3. Nombre: `lyricflow-mvp`
4. Click **"Create"**

### **3. Habilitar APIs necesarias**
En la barra de búsqueda superior, busca y habilita:

#### **A. Speech-to-Text API** (transcripción)
- Busca: **"Speech-to-Text API"**
- Click en **"Enable"**
- Esta API da **60 minutos mensuales gratis**

#### **B. Cloud Translation API** (traducción)
- Busca: **"Cloud Translation API"**
- Click en **"Enable"**
- Esta API da **500,000 caracteres mensuales gratis**

### **4. Crear API Key**
1. Ve a **"APIs & Services"** → **"Credentials"**
2. Click en **"Create Credentials"** → **"API Key"**
3. Se generará una key como: `AIzaSyD...`
4. Copia esa key

### **5. Configurar en LyricFlow**
```bash
# Editar archivo .env
nano /home/fernando/Proyectos/lyric_practice_app/.env
```

Agrega tu API key:
```env
GOOGLE_CLOUD_API_KEY=AIzaSyDxxxxxxxxxxxxxxxxxxxxxxx
```

### **6. Restringir API Key (opcional pero recomendado)**
Para seguridad, puedes restringir la key:
1. En Credentials, click en tu API Key
2. **"Application restrictions"** → **"HTTP referrers"**
3. Agrega: `http://localhost:8080/*` y `http://127.0.0.1:8080/*`
4. **"API restrictions"** → Selecciona solo:
   - Cloud Speech-to-Text API
   - Cloud Translation API

## 💰 **Costos y límites GRATIS:**

### **Speech-to-Text API:**
- **Gratis:** 60 minutos/mes (transcripción)
- **Después:** $0.006 por 15 segundos (~$0.024/min)
- **$1 USD =** ~41 minutos extras

### **Translation API:**
- **Gratis:** 500,000 caracteres/mes
- **Después:** $20 por millón de caracteres
- **$1 USD =** 50,000 caracteres extras

### **Ejemplo de uso típico:**
```
1 canción promedio:
- Transcripción: 3-4 minutos de audio
- Traducción: 300-500 palabras (1,500-2,500 chars)

Con límites gratis puedes procesar:
- Transcripción: ~15-20 canciones/mes
- Traducción: ~200-300 canciones/mes
```

## 🎯 **Funcionalidades que habilitas:**

### **1. Transcripción IA automática**
- Convierte audio a texto automáticamente
- Para canciones sin letras disponibles
- Detección automática de idioma
- **Precisión:** ~95% para español/inglés

### **2. Traducción instantánea**
- Letras traducidas a cualquier idioma
- Preserva formato y estructura
- **Idiomas soportados:** 100+ incluyendo:
  - Español, Inglés, Portugués, Francés
  - Alemán, Italiano, Japonés, Coreano, etc.

### **3. Modo Karaoke con traducción**
- Letras original + traducción lado a lado
- Highlight sincronizado
- Ideal para aprender idiomas

## 🔧 **Probar sin API key:**

Si no configuras Google Cloud API Key, la app:
- ✅ Funciona igual para reconocimiento de canciones
- ✅ Obtiene letras de lyrics.ovh (gratis)
- ❌ **NO** tendrá transcripción IA
- ❌ **NO** tendrá traducción automática
- ❌ Transcripción mostrará mensaje "Configura API key"

## 🚨 **Solución de problemas:**

### **"API Key no válida"**
- Verifica que las APIs estén habilitadas
- Revisa que copiaste toda la key (empieza con `AIzaSy`)
- Espera 2-3 minutos después de crear (propagación)

### **"Quota exceeded" (límite excedido)**
- Has usado tus 60 minutos/mes gratis
- Puedes esperar al próximo mes
- O agregar método de pago (no cobran automáticamente)

### **"403 Forbidden"**
- La key está restringida
- Agrega `localhost:8080` a los HTTP referrers
- O quita restricciones temporalmente

## 📊 **Monitorear uso:**
- Ve a: **https://console.cloud.google.com/billing**
- Click en tu proyecto
- **"Reports"** → Ver uso de APIs
- **"Quotas"** → Ver límites restantes

## 🔄 **Alternativas si no quieres Google Cloud:**

### **A. OpenAI Whisper API**
- **Costo:** $0.006 por minuto
- **Calidad:** Excelente, mejor que Google para canciones
- **Config:** `OPENAI_API_KEY=` en .env

### **B. Usar solo letras existentes**
- Lyrics.ovh tiene muchas canciones populares
- 70-80% de canciones tienen letras disponibles
- Gratis, sin límites

---

## ✅ **Resumen:**
1. **Google Cloud:** $300 crédito gratis → varios meses de uso
2. **APIs gratuitas:** 60min transcripción + 500K chars traducción/mes
3. **Configuración:** 10 minutos, solo copiar API key
4. **Beneficio:** Transcripción IA + Traducción automática

**Sin API key la Fase 1 sigue funcionando.** La Fase 2 (IA) será opcional hasta que configures la key.