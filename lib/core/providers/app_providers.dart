import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/dependency_injection.dart';
import '../../features/song_recognition/domain/repositories/i_song_recognition_repository.dart';
import '../../features/song_recognition/domain/repositories/i_lyrics_repository.dart';
import '../../features/song_recognition/domain/usecases/recognize_song_usecase.dart';
import '../../features/song_recognition/domain/usecases/get_lyrics_usecase.dart';
import '../../features/song_recognition/domain/usecases/translate_lyrics_usecase.dart';
import '../../features/transcription/domain/repositories/i_transcription_repository.dart';
import '../../features/transcription/domain/usecases/transcribe_audio_usecase.dart';
import '../../features/practice_mode/domain/repositories/i_practice_repository.dart';
import '../../features/practice_mode/domain/usecases/separate_stems_usecase.dart';
import '../../features/practice_mode/domain/usecases/generate_midi_usecase.dart';
import '../../features/practice_mode/domain/usecases/get_practice_resources_usecase.dart';

/// ═══════════════════════════════════════════
/// REPOSITORY PROVIDERS
/// Puente entre GetIt (DI) y Riverpod (state)
/// ═══════════════════════════════════════════

final songRecognitionRepositoryProvider =
    Provider<ISongRecognitionRepository>((ref) {
  return sl<ISongRecognitionRepository>();
});

final lyricsRepositoryProvider = Provider<ILyricsRepository>((ref) {
  return sl<ILyricsRepository>();
});

final transcriptionRepositoryProvider =
    Provider<ITranscriptionRepository>((ref) {
  return sl<ITranscriptionRepository>();
});

final practiceRepositoryProvider = Provider<IPracticeRepository>((ref) {
  return sl<IPracticeRepository>();
});

/// ═══════════════════════════════════════════
/// USE CASE PROVIDERS
/// Cada use case como provider inyectable
/// ═══════════════════════════════════════════

final recognizeSongUseCaseProvider = Provider<RecognizeSongUseCase>((ref) {
  return RecognizeSongUseCase(
    repository: ref.watch(songRecognitionRepositoryProvider),
  );
});

final getLyricsUseCaseProvider = Provider<GetLyricsUseCase>((ref) {
  return GetLyricsUseCase(
    repository: ref.watch(lyricsRepositoryProvider),
  );
});

final translateLyricsUseCaseProvider = Provider<TranslateLyricsUseCase>((ref) {
  return TranslateLyricsUseCase(
    repository: ref.watch(lyricsRepositoryProvider),
  );
});

final transcribeAudioUseCaseProvider = Provider<TranscribeAudioUseCase>((ref) {
  return TranscribeAudioUseCase(
    repository: ref.watch(transcriptionRepositoryProvider),
  );
});

final separateStemsUseCaseProvider = Provider<SeparateStemsUseCase>((ref) {
  return SeparateStemsUseCase(
    repository: ref.watch(practiceRepositoryProvider),
  );
});

final generateMidiUseCaseProvider =
    Provider<GenerateMidiFromAudioUseCase>((ref) {
  return GenerateMidiFromAudioUseCase(
    repository: ref.watch(practiceRepositoryProvider),
  );
});

final getPracticeResourcesUseCaseProvider =
    Provider<GetPracticeResourcesUseCase>((ref) {
  return GetPracticeResourcesUseCase(
    lyricsRepository: ref.watch(lyricsRepositoryProvider),
    transcriptionRepository: ref.watch(transcriptionRepositoryProvider),
    practiceRepository: ref.watch(practiceRepositoryProvider),
  );
});
