import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Manejador de permisos específico para Web
///
/// En Web, los permisos de micrófono funcionan diferente:
/// 1. El navegador muestra un diálogo nativo
/// 2. El usuario debe interactuar con la página primero (gesture)
/// 3. Solo funciona en HTTPS (excepto localhost)
class WebPermissionHandler {
  /// Solicitar permiso de micrófono en Web
  /// 
  /// Retorna true si el permiso fue otorgado o ya está concedido.
  static Future<bool> requestMicrophonePermission() async {
    if (!kIsWeb) return true; // En mobile, el paquete record lo maneja
    
    try {
      // Verificar si el navegador soporta getUserMedia
      if (html.window.navigator.mediaDevices == null) {
        debugPrint('❌ Navegador no soporta getUserMedia API');
        return false;
      }
      
      // En Web, usar la API de MediaDevices nativa
      final stream = await html.window.navigator.mediaDevices!.getUserMedia(
        {'audio': true},
      );
      
      // Detener stream inmediatamente para no consumir micrófono
      stream.getTracks().forEach((track) => track.stop());
      
      debugPrint('✅ Permiso de micrófono otorgado en Web');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error al solicitar permiso de micrófono en Web: $e');
      
      // Información útil para debugging
      final isLocalhost = html.window.location.hostname == 'localhost' || 
                         html.window.location.hostname == '127.0.0.1';
      
      if (!isLocalhost && !html.window.isSecureContext) {
        debugPrint('⚠️ Micrófono requiere HTTPS en producción. Usa localhost para desarrollo.');
      }
      
      return false;
    }
  }

  /// Verificar si el navegador soporta getUserMedia
  static bool supportsMediaDevices() {
    if (!kIsWeb) return true;
    return html.window.navigator.mediaDevices?.getUserMedia != null;
  }

  /// Verificar si estamos en HTTPS (requerido para micrófono en producción)
  static bool isSecureContext() {
    if (!kIsWeb) return true;
    return html.window.isSecureContext;
  }

  /// Obtener información de compatibilidad del navegador
  static Map<String, dynamic> getBrowserCompatibility() {
    if (!kIsWeb) return {'compatible': true};
    
    return {
      'compatible': supportsMediaDevices(),
      'secureContext': isSecureContext(),
      'userAgent': html.window.navigator.userAgent,
    };
  }
}
