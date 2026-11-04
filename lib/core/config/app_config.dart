import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración global de la aplicación
/// 
/// Singleton que mantiene el estado de configuración
/// accesible desde cualquier parte de la app.
class AppConfig {
  AppConfig._();
  
  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  // ─── Estado ───
  late String _environment;
  late bool _isDebug;
  bool _initialized = false;

  // ─── Getters ───
  String get environment => _environment;
  bool get isDebug => _isDebug;
  bool get isProduction => _environment == 'production';
  bool get isDevelopment => _environment == 'development';
  bool get isStaging => _environment == 'staging';
  bool get initialized => _initialized;

  /// ¿Estamos en modo demo (sin API keys)?
  bool get isDemoMode {
    final hasAcr = acrCloudAccessKey.isNotEmpty;
    final hasAudd = auddApiKey.isNotEmpty;
    return !hasAcr && !hasAudd;
  }

  // ─── API Keys ───
  String get acrCloudAccessKey => dotenv.env['ACRCLOUD_ACCESS_KEY'] ?? '';
  String get acrCloudAccessSecret => dotenv.env['ACRCLOUD_ACCESS_SECRET'] ?? '';
  String get acrCloudHost => dotenv.env['ACRCLOUD_HOST'] ?? 'identify-eu-west-1.acrcloud.com';
  String get auddApiKey => dotenv.env['AUDD_API_KEY'] ?? '';
  String get musixmatchApiKey => dotenv.env['MUSIXMATCH_API_KEY'] ?? '';
  String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  // ─── API Base URLs ───
  String get musixmatchBaseUrl => 'https://api.musixmatch.com/ws/1.1';
  String get auddBaseUrl => 'https://api.audd.io';
  String get openAiBaseUrl => 'https://api.openai.com/v1';

  // ─── Configuración de Audio ───
  static const int recordingDurationMs = 10000; // 10 segundos
  static const int sampleRate = 44100;
  static const int maxHistoryItems = 50;

  // ─── Inicialización ───
  static void initialize({
    required String environment,
    required bool isDebug,
  }) {
    _instance._environment = environment;
    _instance._isDebug = isDebug;
    _instance._initialized = true;

    if (isDebug) {
      _instance._printConfig();
    }
  }

  void _printConfig() {
    debugPrint('╔══════════════════════════════════════╗');
    debugPrint('║       LyricFlow Configuration        ║');
    debugPrint('╠══════════════════════════════════════╣');
    debugPrint('║ Environment: $_environment');
    debugPrint('║ Debug Mode:  $_isDebug');
    debugPrint('║ Demo Mode:   $isDemoMode');
    debugPrint('║ ACRCloud:    ${acrCloudAccessKey.isNotEmpty ? '✓ Configured' : '✗ Not set'}');
    debugPrint('║ AudD:        ${auddApiKey.isNotEmpty ? '✓ Configured' : '✗ Not set'}');
    debugPrint('║ Musixmatch:  ${musixmatchApiKey.isNotEmpty ? '✓ Configured' : '✗ Not set'}');
    debugPrint('║ OpenAI:      ${openAiApiKey.isNotEmpty ? '✓ Configured' : '✗ Not set'}');
    debugPrint('╚══════════════════════════════════════╝');
  }
}
