import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../services/web_permission_handler.dart';

/// Estado del grabador de audio
enum AudioRecordingStatus {
  idle,
  requestingPermission,
  permissionDenied,
  recording,
  processing,
  completed,
  error,
}

/// Estado completo del audio recorder
class AudioRecordingState {
  final AudioRecordingStatus status;
  final List<int> audioBytes;
  final int elapsedMs;
  final int maxDurationMs;
  final String? errorMessage;
  final double amplitude; // 0.0 - 1.0 para visualización

  const AudioRecordingState({
    this.status = AudioRecordingStatus.idle,
    this.audioBytes = const [],
    this.elapsedMs = 0,
    this.maxDurationMs = 10000,
    this.errorMessage,
    this.amplitude = 0.0,
  });

  bool get isIdle => status == AudioRecordingStatus.idle;
  bool get isRecording => status == AudioRecordingStatus.recording;
  bool get isProcessing => status == AudioRecordingStatus.processing;
  bool get isCompleted => status == AudioRecordingStatus.completed;
  bool get hasError => status == AudioRecordingStatus.error;
  bool get hasData => audioBytes.isNotEmpty;

  double get progress {
    if (maxDurationMs == 0) return 0;
    return (elapsedMs / maxDurationMs).clamp(0.0, 1.0);
  }

  String get formattedElapsed {
    final seconds = elapsedMs ~/ 1000;
    final ms = (elapsedMs % 1000) ~/ 100;
    return '$seconds.${ms}s';
  }

  AudioRecordingState copyWith({
    AudioRecordingStatus? status,
    List<int>? audioBytes,
    int? elapsedMs,
    int? maxDurationMs,
    String? errorMessage,
    double? amplitude,
  }) {
    return AudioRecordingState(
      status: status ?? this.status,
      audioBytes: audioBytes ?? this.audioBytes,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      maxDurationMs: maxDurationMs ?? this.maxDurationMs,
      errorMessage: errorMessage ?? this.errorMessage,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

/// Provider global de grabación de audio REAL
///
/// Usa el paquete `record` para capturar audio del micrófono
/// en Web, Android e iOS. Graba como WAV para máxima compatibilidad
/// con APIs de reconocimiento.
class AudioRecordingNotifier extends Notifier<AudioRecordingState> {
  Timer? _timer;
  Timer? _amplitudeTimer;
  AudioRecorder? _recorder;

  // Para grabación en stream (web)
  StreamSubscription<Uint8List>? _streamSubscription;
  final List<int> _audioBuffer = [];

  @override
  AudioRecordingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _amplitudeTimer?.cancel();
      _streamSubscription?.cancel();
      _recorder?.dispose();
    });
    return const AudioRecordingState();
  }

  /// Iniciar grabación real del micrófono
  Future<void> startRecording({int maxDurationMs = 3000}) async {
    state = state.copyWith(
      status: AudioRecordingStatus.requestingPermission,
      maxDurationMs: maxDurationMs,
    );

    try {
      // En Web, manejar permisos de forma específica
      if (kIsWeb) {
        debugPrint('🎤 Solicitando permiso de micrófono en Web...');
        final hasPermission = await WebPermissionHandler.requestMicrophonePermission();
        
        if (!hasPermission) {
          // Verificar si es problema de HTTPS/localhost
          final compatibility = WebPermissionHandler.getBrowserCompatibility();
          final isLocalhost = html.window.location.hostname == 'localhost' || 
                             html.window.location.hostname == '127.0.0.1';
          
          String errorMsg;
          if (!compatibility['secureContext'] && !isLocalhost) {
            errorMsg = 'El micrófono requiere HTTPS en producción. '
                'Para desarrollo, usa http://localhost:8080 (no dirección IP)'; 
          } else if (!compatibility['compatible']) {
            errorMsg = 'Tu navegador no soporta grabación de audio. '
                'Usa Chrome, Edge o Firefox actualizado.';
          } else {
            errorMsg = 'Permiso de micrófono denegado. '
                'Asegúrate de hacer click en "Permitir" cuando el navegador lo pida. '
                'También verifica que no haya otro programa usando el micrófono.';
          }
          
          debugPrint('❌ Error de permisos: $errorMsg');
          state = state.copyWith(
            status: AudioRecordingStatus.permissionDenied,
            errorMessage: errorMsg,
          );
          return;
        }
        
        debugPrint('✅ Permiso de micrófono otorgado en Web');
      }

      // Crear recorder
      _recorder = AudioRecorder();

      // Verificar permiso de micrófono (también para mobile)
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          status: AudioRecordingStatus.permissionDenied,
          errorMessage: 'Permiso de micrófono denegado. '
              'Habilítalo en la configuración del dispositivo.',
        );
        return;
      }

      // Limpiar buffer anterior
      _audioBuffer.clear();

      // En web usamos stream, en mobile usamos archivo
      if (kIsWeb) {
        await _startStreamRecording(maxDurationMs);
      } else {
        await _startFileRecording(maxDurationMs);
      }
    } catch (e) {
      debugPrint('❌ Error al iniciar grabación: $e');
      state = state.copyWith(
        status: AudioRecordingStatus.error,
        errorMessage: 'Error al acceder al micrófono: $e',
      );
    }
  }

  /// Grabación vía stream (Web)
  Future<void> _startStreamRecording(int maxDurationMs) async {
    try {
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      debugPrint('🎤 Stream de audio iniciado en Web');
      
      state = state.copyWith(
        status: AudioRecordingStatus.recording,
        audioBytes: [],
        elapsedMs: 0,
        errorMessage: null,
      );

      // Colectar chunks de audio
      _streamSubscription = stream.listen(
        (chunk) {
          debugPrint('🎤 Chunk de audio recibido: ${chunk.length} bytes');
          _audioBuffer.addAll(chunk);
        },
        onError: (e) {
          debugPrint('❌ Error en stream de audio: $e');
          state = state.copyWith(
            status: AudioRecordingStatus.error,
            errorMessage: 'Error durante la grabación: $e',
          );
        },
        onDone: () {
          debugPrint('✅ Stream de audio completado');
        },
      );

      _startTimers(maxDurationMs);
      
    } catch (e) {
      debugPrint('❌ Error al iniciar stream de audio: $e');
      state = state.copyWith(
        status: AudioRecordingStatus.error,
        errorMessage: 'Error al iniciar grabación: $e',
      );
      rethrow;
    }
  }

  /// Grabación vía archivo (Mobile)
  Future<void> _startFileRecording(int maxDurationMs) async {
    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: '', // El paquete usa temp dir automáticamente
    );

    state = state.copyWith(
      status: AudioRecordingStatus.recording,
      audioBytes: [],
      elapsedMs: 0,
      errorMessage: null,
    );

    _startTimers(maxDurationMs);
  }

  void _startTimers(int maxDurationMs) {
    // Timer de progreso
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final newElapsed = state.elapsedMs + 100;
      if (newElapsed >= maxDurationMs) {
        stopRecording();
        return;
      }
      state = state.copyWith(elapsedMs: newElapsed);
    });

    // Timer de amplitud real
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final amp = await _recorder?.getAmplitude();
        if (amp != null) {
          // amp.current es en dB (negativo). Normalizar a 0.0-1.0
          // -60dB = silencio, 0dB = max
          final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          state = state.copyWith(amplitude: normalized);
        }
      } catch (_) {
        // Amplitud no disponible en este platform
        final fakeAmplitude = 0.3 + (DateTime.now().millisecond % 500) / 700;
        state = state.copyWith(amplitude: fakeAmplitude.clamp(0.0, 1.0));
      }
    });
  }

  /// Detener grabación y obtener bytes
  Future<void> stopRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();

    state = state.copyWith(
      status: AudioRecordingStatus.processing,
      amplitude: 0.0,
    );

    try {
      List<int> audioBytes;

      if (kIsWeb) {
        // En web, detener stream y usar buffer acumulado
        await _streamSubscription?.cancel();
        await _recorder?.stop();
        audioBytes = List<int>.from(_audioBuffer);
        
        // Verificar que tenemos audio real (más de solo encabezado WAV)
        if (audioBytes.length < 2000) {
          debugPrint('⚠️ Audio demasiado corto: ${audioBytes.length} bytes');
          throw Exception('Audio demasiado corto para procesar');
        }
      } else {
        // En mobile, leer el archivo grabado
        final path = await _recorder?.stop();
        if (path != null && path.isNotEmpty) {
          // TODO: Read file bytes - for now use buffer
          audioBytes = List<int>.from(_audioBuffer);
        } else {
          audioBytes = [];
        }
      }

      debugPrint('🎤 Buffer de audio: ${_audioBuffer.length} bytes');
      debugPrint('🎤 Audio final: ${audioBytes.length} bytes');
      debugPrint('🎤 Duración: ${state.elapsedMs}ms');

      if (audioBytes.isEmpty) {
        debugPrint('⚠️ Buffer vacío, no se capturó audio');
        state = state.copyWith(
          status: AudioRecordingStatus.error,
          errorMessage: 'No se capturó audio. Asegúrate de que el micrófono esté funcionando y haya sonido.',
        );
        return;
      }
      
      // Verificar que sea audio real (no solo encabezado WAV)
      // Un WAV válido tiene al menos 44 bytes de encabezado + algo de data
      if (audioBytes.length < 100) {
        debugPrint('⚠️ Audio demasiado corto: ${audioBytes.length} bytes');
        state = state.copyWith(
          status: AudioRecordingStatus.error,
          errorMessage: 'Audio demasiado corto. Graba al menos 1 segundo.',
        );
        return;
      }
      
      state = state.copyWith(
        status: AudioRecordingStatus.completed,
        audioBytes: audioBytes,
      );
    } catch (e) {
      debugPrint('❌ Error al detener grabación: $e');
      state = state.copyWith(
        status: AudioRecordingStatus.error,
        errorMessage: 'Error al procesar audio: $e',
      );
    }
  }

  /// Cancelar grabación
  void cancelRecording() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _streamSubscription?.cancel();
    _recorder?.stop();
    _audioBuffer.clear();
    state = const AudioRecordingState();
  }

  /// Reset al estado idle
  void reset() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _streamSubscription?.cancel();
    _audioBuffer.clear();
    state = const AudioRecordingState();
  }
}

/// Provider global de grabación de audio
final audioRecordingProvider =
    NotifierProvider<AudioRecordingNotifier, AudioRecordingState>(
  AudioRecordingNotifier.new,
);
