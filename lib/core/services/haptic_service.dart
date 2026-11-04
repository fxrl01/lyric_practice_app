import 'package:flutter/services.dart';

/// Servicio centralizado de feedback háptico
///
/// Proporciona métodos tipados para cada tipo de interacción.
/// Funciona en iOS y Android; en web es un no-op silencioso.
class HapticService {
  HapticService._();

  /// Tap en botón principal (reconocer, play)
  static Future<void> buttonTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// Tap ligero (chips, toggles)
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Acción exitosa (canción reconocida, sesión completada)
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
  }

  /// Error o acción denegada
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Selección en lista (scroll snap, cambio de tab)
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Beat del metrónomo (downbeat)
  static Future<void> metronomeBeat() async {
    await HapticFeedback.mediumImpact();
  }

  /// Tick del metrónomo (upbeat)
  static Future<void> metronomeTick() async {
    await HapticFeedback.lightImpact();
  }
}
