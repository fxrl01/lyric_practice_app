import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transcription.dart';
import '../../domain/usecases/transcribe_audio_usecase.dart';
import '../../../../core/providers/app_providers.dart';

/// ═══════════════════════════════════════════
/// Estado de transcripción IA
/// ═══════════════════════════════════════════

class TranscriptionState {
  /// Resultado de la transcripción
  final AsyncValue<Transcription?> result;

  /// Progreso del procesamiento (0.0 - 1.0)
  final double progress;

  /// Idiomas soportados
  final List<String> supportedLanguages;

  /// ¿El servicio está disponible?
  final bool isServiceAvailable;

  const TranscriptionState({
    this.result = const AsyncValue.data(null),
    this.progress = 0.0,
    this.supportedLanguages = const [],
    this.isServiceAvailable = true,
  });

  bool get isLoading => result.isLoading;
  bool get hasResult => result.valueOrNull != null;
  bool get hasError => result.hasError;
  Transcription? get transcription => result.valueOrNull;

  TranscriptionState copyWith({
    AsyncValue<Transcription?>? result,
    double? progress,
    List<String>? supportedLanguages,
    bool? isServiceAvailable,
  }) {
    return TranscriptionState(
      result: result ?? this.result,
      progress: progress ?? this.progress,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      isServiceAvailable: isServiceAvailable ?? this.isServiceAvailable,
    );
  }
}

/// ═══════════════════════════════════════════
/// Notifier de transcripción IA
/// ═══════════════════════════════════════════

class TranscriptionNotifier extends Notifier<TranscriptionState> {
  @override
  TranscriptionState build() {
    _checkServiceAvailability();
    _loadSupportedLanguages();
    return const TranscriptionState();
  }

  /// Transcribir audio con IA
  Future<void> transcribeAudio({
    required List<int> audioBytes,
    String? songId,
    String? language,
    String model = 'whisper-1',
  }) async {
    state = state.copyWith(
      result: const AsyncValue.loading(),
      progress: 0.0,
    );

    // Simular progreso
    _simulateProgress();

    final useCase = ref.read(transcribeAudioUseCaseProvider);
    final result = await useCase(TranscribeAudioParams(
      audioBytes: audioBytes,
      songId: songId,
      language: language,
      model: model,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          result: AsyncValue.error(failure.message, StackTrace.current),
          progress: 0.0,
        );
      },
      (transcription) {
        state = state.copyWith(
          result: AsyncValue.data(transcription),
          progress: 1.0,
        );
      },
    );
  }

  /// Transcribir desde URL
  Future<void> transcribeFromUrl({
    required String audioUrl,
    String? songId,
    String? language,
  }) async {
    state = state.copyWith(
      result: const AsyncValue.loading(),
      progress: 0.0,
    );

    _simulateProgress();

    final useCase = ref.read(transcribeAudioUseCaseProvider);
    final result = await useCase(TranscribeAudioParams(
      audioUrl: audioUrl,
      songId: songId,
      language: language,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          result: AsyncValue.error(failure.message, StackTrace.current),
          progress: 0.0,
        );
      },
      (transcription) {
        state = state.copyWith(
          result: AsyncValue.data(transcription),
          progress: 1.0,
        );
      },
    );
  }

  /// Verificar disponibilidad del servicio
  Future<void> _checkServiceAvailability() async {
    final repo = ref.read(transcriptionRepositoryProvider);
    final result = await repo.isServiceAvailable();
    final available = result.getOrElse(() => false);
    state = state.copyWith(isServiceAvailable: available);
  }

  /// Cargar idiomas soportados
  Future<void> _loadSupportedLanguages() async {
    final repo = ref.read(transcriptionRepositoryProvider);
    final result = await repo.getSupportedLanguages();
    final langs = result.getOrElse(() => ['en', 'es']);
    state = state.copyWith(supportedLanguages: langs);
  }

  /// Simular progreso (se reemplazará con progreso real de la API)
  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (state.progress >= 0.9 || !state.isLoading) return false;
      state = state.copyWith(progress: state.progress + 0.05);
      return true;
    });
  }

  /// Reset
  void reset() {
    final keepAvailable = state.isServiceAvailable;
    state = TranscriptionState(
      isServiceAvailable: keepAvailable,
    );
  }
}

/// Provider de transcripción
final transcriptionProvider =
    NotifierProvider<TranscriptionNotifier, TranscriptionState>(
  TranscriptionNotifier.new,
);

/// ═══════════════════════════════════════════
/// Providers de conveniencia
/// ═══════════════════════════════════════════

/// Solo la transcripción actual
final currentTranscriptionProvider = Provider<Transcription?>((ref) {
  return ref.watch(transcriptionProvider).transcription;
});

/// ¿El servicio de transcripción está disponible?
final isTranscriptionAvailableProvider = Provider<bool>((ref) {
  return ref.watch(transcriptionProvider).isServiceAvailable;
});
