import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/usecases/recognize_song_usecase.dart';
import '../../domain/usecases/get_lyrics_usecase.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/audio_recording_provider.dart';
import '../../../../core/services/audio_processor.dart';

/// ═══════════════════════════════════════════
/// Estado del reconocimiento de canciones
/// ═══════════════════════════════════════════

/// Estado completo del flujo de reconocimiento
class SongRecognitionState {
  /// Estado del reconocimiento
  final AsyncValue<Song?> recognitionResult;

  /// Estado de las letras
  final AsyncValue<Lyrics?> lyricsResult;

  /// Historial de canciones reconocidas
  final AsyncValue<List<Song>> history;

  /// ¿Está en modo escucha?
  final bool isListening;

  const SongRecognitionState({
    this.recognitionResult = const AsyncValue.data(null),
    this.lyricsResult = const AsyncValue.data(null),
    this.history = const AsyncValue.data([]),
    this.isListening = false,
  });

  /// ¿Hay un resultado?
  bool get hasSong => recognitionResult.valueOrNull != null;

  /// ¿Se están cargando letras?
  bool get isLoadingLyrics => lyricsResult.isLoading;

  /// ¿Hay letras disponibles?
  bool get hasLyrics =>
      lyricsResult.valueOrNull != null &&
      lyricsResult.valueOrNull!.isNotEmpty;

  /// Canción reconocida (o null)
  Song? get song => recognitionResult.valueOrNull;

  /// Letras (o null)
  Lyrics? get lyrics => lyricsResult.valueOrNull;

  SongRecognitionState copyWith({
    AsyncValue<Song?>? recognitionResult,
    AsyncValue<Lyrics?>? lyricsResult,
    AsyncValue<List<Song>>? history,
    bool? isListening,
  }) {
    return SongRecognitionState(
      recognitionResult: recognitionResult ?? this.recognitionResult,
      lyricsResult: lyricsResult ?? this.lyricsResult,
      history: history ?? this.history,
      isListening: isListening ?? this.isListening,
    );
  }
}

/// ═══════════════════════════════════════════
/// Notifier principal de Song Recognition
/// ═══════════════════════════════════════════

class SongRecognitionNotifier extends Notifier<SongRecognitionState> {
  @override
  SongRecognitionState build() {
    // Cargar historial al inicializar
    _loadHistory();
    return const SongRecognitionState();
  }

  /// Iniciar flujo completo: grabar → reconocer → obtener letras
  Future<void> startRecognition() async {
    final audioNotifier = ref.read(audioRecordingProvider.notifier);

    // 1. Grabar audio
    state = state.copyWith(
      isListening: true,
      recognitionResult: const AsyncValue.data(null),
      lyricsResult: const AsyncValue.data(null),
    );

    await audioNotifier.startRecording(maxDurationMs: 10000);
  }

  /// Detener grabación y procesar
  Future<void> stopAndRecognize() async {
    final audioNotifier = ref.read(audioRecordingProvider.notifier);
    await audioNotifier.stopRecording();

    final audioState = ref.read(audioRecordingProvider);

    if (!audioState.hasData) {
      state = state.copyWith(
        isListening: false,
        recognitionResult: AsyncValue.error(
          'No se capturó audio',
          StackTrace.current,
        ),
      );
      return;
    }

    // Optimizar audio para reconocimiento rápido tipo Shazam
    final optimizedAudio = AudioProcessor.optimizeForApi(audioState.audioBytes);
    
    // Verificar calidad del audio
    if (!AudioProcessor.isAudioQualityGood(optimizedAudio)) {
      state = state.copyWith(
        isListening: false,
        recognitionResult: AsyncValue.error(
          'Audio de baja calidad. Asegúrate de que haya música clara.',
          StackTrace.current,
        ),
      );
      return;
    }
    
    // Reconocer canción
    await recognizeSong(
      audioBytes: optimizedAudio,
      durationMs: audioState.elapsedMs,
    );
  }

  /// Reconocer canción directamente con bytes de audio
  Future<void> recognizeSong({
    required List<int> audioBytes,
    required int durationMs,
    bool isHumming = false,
  }) async {
    state = state.copyWith(
      isListening: false,
      recognitionResult: const AsyncValue.loading(),
    );

    final useCase = ref.read(recognizeSongUseCaseProvider);
    final result = await useCase(RecognizeSongParams(
      audioBytes: audioBytes,
      durationMs: durationMs,
      isHumming: isHumming,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          recognitionResult: AsyncValue.error(
            failure.message,
            StackTrace.current,
          ),
        );
      },
      (song) {
        state = state.copyWith(
          recognitionResult: AsyncValue.data(song),
        );

        // Auto-cargar letras si hay resultado
        if (song.hasLyrics) {
          fetchLyrics(songTitle: song.title, artist: song.artist, isrc: song.isrc);
        }

        // Refrescar historial
        _loadHistory();
      },
    );
  }

  /// Obtener letras de una canción
  Future<void> fetchLyrics({
    required String songTitle,
    required String artist,
    String? isrc,
    bool preferSynced = true,
  }) async {
    state = state.copyWith(
      lyricsResult: const AsyncValue.loading(),
    );

    final useCase = ref.read(getLyricsUseCaseProvider);
    final result = await useCase(GetLyricsParams(
      songTitle: songTitle,
      artist: artist,
      isrc: isrc,
      preferSynced: preferSynced,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          lyricsResult: AsyncValue.error(
            failure.message,
            StackTrace.current,
          ),
        );
      },
      (lyrics) {
        state = state.copyWith(
          lyricsResult: AsyncValue.data(lyrics),
        );
      },
    );
  }

  /// Cargar historial
  Future<void> _loadHistory() async {
    final repo = ref.read(songRecognitionRepositoryProvider);
    final result = await repo.getRecognitionHistory();

    result.fold(
      (_) {}, // Silenciar errores de historial
      (history) {
        state = state.copyWith(
          history: AsyncValue.data(history),
        );
      },
    );
  }

  /// Limpiar historial
  Future<void> clearHistory() async {
    final repo = ref.read(songRecognitionRepositoryProvider);
    await repo.clearHistory();
    state = state.copyWith(
      history: const AsyncValue.data([]),
    );
  }

  /// Cancelar reconocimiento en curso
  void cancel() {
    ref.read(audioRecordingProvider.notifier).cancelRecording();
    state = state.copyWith(
      isListening: false,
      recognitionResult: const AsyncValue.data(null),
    );
  }

  /// Reset completo
  void reset() {
    ref.read(audioRecordingProvider.notifier).reset();
    state = const SongRecognitionState();
    _loadHistory();
  }
}

/// Provider principal de reconocimiento de canciones
final songRecognitionProvider =
    NotifierProvider<SongRecognitionNotifier, SongRecognitionState>(
  SongRecognitionNotifier.new,
);

/// ═══════════════════════════════════════════
/// Providers de conveniencia (selectors)
/// ═══════════════════════════════════════════

/// Solo la canción reconocida
final currentSongProvider = Provider<Song?>((ref) {
  return ref.watch(songRecognitionProvider).song;
});

/// Solo las letras
final currentLyricsProvider = Provider<Lyrics?>((ref) {
  return ref.watch(songRecognitionProvider).lyrics;
});

/// Solo el historial
final recognitionHistoryProvider = Provider<AsyncValue<List<Song>>>((ref) {
  return ref.watch(songRecognitionProvider).history;
});

/// ¿Está escuchando?
final isListeningProvider = Provider<bool>((ref) {
  return ref.watch(songRecognitionProvider).isListening;
});
