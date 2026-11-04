# 🎤 TEST de Micrófono en Web

Si ves el error **"No se capturó audio"**, sigue estos pasos:

## 🚨 **PROBLEMA COMÚN: Permisos de micrófono en Web**

En Web, los navegadores son estrictos con el micrófono:
1. **Requiere HTTPS** (excepto `localhost` o `127.0.0.1`)
2. **Requiere interacción del usuario** (click, tap) antes de solicitar permiso
3. **Solo un programa puede usar el micrófono** a la vez

## 🔧 **SOLUCIÓN PASO A PASO:**

### **PASO 1: Verificar URL correcta**
**✅ CORRECTO:**
```
http://localhost:8080
http://127.0.0.1:8080
```

**❌ INCORRECTO:**
```
http://192.168.x.x:8080  (dirección IP)
https://localhost:8080    (HTTPS sin certificado)
```

### **PASO 2: Permitir micrófono en el navegador**
1. En Chrome/Edge, haz click en el **ícono de candado (🔒)** en la barra de URL
2. Click en **"Permisos del sitio"**
3. En **"Micrófono"**, selecciona **"Permitir"**
4. Recarga la página

### **PASO 3: Verificar que no hay otro programa usando el micrófono**
- Cierra Zoom, Teams, Discord, Skype
- Cierra grabadoras de pantalla
- Cierra cualquier app que use micrófono

### **PASO 4: Probar en modo incógnito**
1. Abre Chrome/Edge en **modo incógnito**
2. Ve a `http://localhost:8080`
3. Cuando pida permiso de micrófono → **"Permitir"**

## 🛠️ **DEBUGGING RÁPIDO:**

### **1. Abrir consola del navegador**
- **Chrome/Edge:** `F12` → Console
- Deberías ver mensajes como:
  - `🎤 Solicitando permiso de micrófono en Web...`
  - `✅ Permiso de micrófono otorgado en Web`
  - `🎤 Audio capturado: XXXX bytes`

### **2. Probar API de micrófono directamente**
Abre la consola y ejecuta:
```javascript
// Test simple de micrófono
navigator.mediaDevices.getUserMedia({ audio: true })
  .then(stream => console.log('✅ Micrófono funciona!', stream))
  .catch(error => console.log('❌ Error:', error));
```

### **3. Verificar errores específicos**
Si ves estos errores en consola:

**`NotAllowedError`** → El usuario denegó el permiso
**`NotFoundError`** → No hay micrófono disponible
**`NotReadableError`** → Otro programa está usando el micrófono
**`OverconstrainedError`** → El navegador no soporta las restricciones

## 🎯 **SOLUCIONES ESPECÍFICAS:**

### **Si usas dirección IP (192.168.x.x):**
```bash
# Opción 1: Usar localhost
http://localhost:8080

# Opción 2: Configurar HTTPS local (complejo)
# Mejor usar localhost
```

### **Si el navegador no pide permiso:**
1. Cierra todas las pestañas de `localhost:8080`
2. Limpia cache del navegador
3. Reinicia el navegador
4. Abre `http://localhost:8080` de nuevo
5. **HAZ CLICK** en el botón "Escuchar" (no funciona con teclado)

### **Si usas Firefox:**
1. Ve a `about:config`
2. Busca `media.navigator.permission.disabled`
3. Cambia a `true` (solo para desarrollo)
4. O permite manualmente en `about:permissions`

## 📱 **ALTERNATIVA: Probar en Android/iOS (móvil)**

Si en web no funciona, prueba en dispositivo móvil:

```bash
# Conectar dispositivo Android
flutter run -d <device_id>

# O emulador
flutter emulators --launch <emulator_name>
```

En móvil los permisos funcionan mejor.

## 🐛 **LOGGING MEJORADO:**

La app ahora muestra en consola:
- ✅ `🎤 Solicitando permiso de micrófono en Web...`
- ✅ `✅ Permiso de micrófono otorgado en Web` 
- ✅ `🎤 Audio capturado: XXXX bytes (3000ms)`
- ❌ `❌ Error al solicitar permiso: ...`

## 🚀 **COMANDOS PARA REINICIAR:**

```bash
# 1. Detener servidor actual (Ctrl+C en terminal)

# 2. Limpiar y reconstruir
cd /home/fernando/Proyectos/lyric_practice_app
/home/fernando/flutter/bin/flutter clean
/home/fernando/flutter/bin/flutter pub get

# 3. Ejecutar con logging detallado
/home/fernando/flutter/bin/flutter run -d chrome --web-port 8080 --verbose

# 4. Abrir Chrome en http://localhost:8080
# 5. Abrir consola (F12) y ver logs
```

## 📞 **SI NADA FUNCIONA:**

### **Plan B: Modo demo sin micrófono**
Podemos hacer que la app funcione sin micrófono:
1. Usar audio pregrabado para testing
2. O saltar directamente a reconocimiento con archivo

### **Plan C: Solo letras (sin reconocimiento)**
Si el micrófono es imposible, podemos:
1. Buscar canciones por título/artista
2. Obtener letras sin grabar audio

---

**Prueba ahora:** Abre la consola del navegador (F12) y dime qué errores ves cuando haces click en "Escuchar".