import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/practice_session.dart';
import '../entities/stem.dart';
import '../entities/midi_track.dart';
import '../repositories/i_practice_repository.dart';
import '../../../song_recognition/domain/entities/lyrics.dart';
import '../../../song_recognition/domain/repositories/i_lyrics_repository.dart';
import '../../../transcription/domain/entities/transcription.dart';
import '../../../transcription/domain/repositories/i_transcription_repository.dart';

/// Caso de uso: Obtener todos los recursos necesarios para práctica
///
/// Orquesta la carga de todos los datos que necesita el modo práctica:
/// 1. Letras (de API o transcripción IA)
/// 2. Stems separados (si están disponibles)
/// 3. MIDI track (si está disponible)
/// 4. Crea la sesión de práctica
///
/// Este es un use case compuesto que coordina múltiples repositorios.
/// Principio ISP: los consumers solo necesitan llamar a este
/// use case en vez de orquestar múltiples repositorios manualmente.
class GetPracticeResourcesUseCase
    extends UseCase<PracticeResources, GetPracticeResourcesParams> {
  final ILyricsRepository _lyricsRepository;
  final ITranscriptionRepository _transcriptionRepository;
  final IPracticeRepository _practiceRepository;

  GetPracticeResourcesUseCase({
    required ILyricsRepository lyricsRepository,
    required ITranscriptionRepository transcriptionRepository,
    required IPracticeRepository practiceRepository,
  })  : _lyricsRepository = lyricsRepository,
        _transcriptionRepository = transcriptionRepository,
        _practiceRepository = practiceRepository;

  @override
  Future<Either<AppFailure, PracticeResources>> call(
    GetPracticeResourcesParams params,
  ) async {
    // Validación
    if (params.songTitle.isEmpty || params.songArtist.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Se requiere título y artista para iniciar práctica.',
        code: 'MISSING_SONG_INFO',
      ));
    }

    // ─── 1. Obtener letras ───
    Lyrics? lyrics;
    Transcription? transcription;
    bool isAiGenerated = false;

    // Intentar letras de API primero
    final lyricsResult = await _lyricsRepository.getLyrics(
      songTitle: params.songTitle,
      artist: params.songArtist,
      isrc: params.isrc,
    );

    lyricsResult.fold(
      (failure) {
        // No hay letras disponibles — se necesita transcripción IA
        lyrics = null;
      },
      (result) {
        lyrics = result;
      },
    );

    // Si no hay letras, intentar transcripción IA
    if (lyrics == null || lyrics!.isEmpty) {
      final transResult = await _transcriptionRepository.getCachedTranscription(
        songId: params.songId,
      );

      transResult.fold(
        (_) {},
        (cached) {
          if (cached != null && !cached.isExpired) {
            transcription = cached;
            isAiGenerated = true;

            // Convertir transcripción a lyrics para práctica
            lyrics = Lyrics(
              songId: params.songId,
              lines: cached.segments
                  .map((s) => LyricLine(
                        text: s.text,
                        startTimeMs: s.startTimeMs,
                        endTimeMs: s.endTimeMs,
                      ))
                  .toList(),
              language: cached.detectedLanguage,
              source: LyricsSource.aiTranscription,
              isSynced: true,
              isAiGenerated: true,
              aiConfidence: cached.confidence,
            );
          }
        },
      );
    }

    // Si todavía no hay letras, error
    if (lyrics == null || lyrics!.isEmpty) {
      return const Left(RecognitionFailure(
        message: 'No hay letras ni transcripción disponible para esta canción. '
            'Transcribe primero el audio con IA.',
        code: 'NO_LYRICS_AVAILABLE',
      ));
    }

    // ─── 2. Verificar stems (opcional, no bloquea) ───
    StemSeparationResult? stems;
    final stemsResult = await _practiceRepository.getCachedStems(
      songId: params.songId,
    );
    stemsResult.fold((_) {}, (result) => stems = result);

    // ─── 3. Verificar MIDI (opcional, no bloquea) ───
    MidiTrack? midiTrack;
    if (stems?.vocalsStem != null) {
      final midiResult = await _practiceRepository.getCachedMidiTrack(
        songId: params.songId,
        stemId: stems!.vocalsStem!.id,
      );
      midiResult.fold((_) {}, (result) => midiTrack = result);
    }

    // ─── 4. Crear sesión de práctica ───
    final sessionResult = await _practiceRepository.createSession(
      songId: params.songId,
      songTitle: params.songTitle,
      songArtist: params.songArtist,
      mode: params.mode,
      difficulty: params.difficulty,
      language: lyrics!.language,
    );

    return sessionResult.fold(
      Left.new,
      (session) => Right(PracticeResources(
        lyrics: lyrics!,
        session: session,
        transcription: transcription,
        stems: stems,
        midiTrack: midiTrack,
        isAiGenerated: isAiGenerated,
      )),
    );
  }
}

/// Resultado agregado con todos los recursos para práctica
class PracticeResources {
  /// Letras para practicar (de API o IA)
  final Lyrics lyrics;

  /// Sesión de práctica creada
  final PracticeSession session;

  /// Transcripción IA (si se usó en vez de letras de API)
  final Transcription? transcription;

  /// Stems separados (si están disponibles)
  final StemSeparationResult? stems;

  /// MIDI track (si está disponible)
  final MidiTrack? midiTrack;

  /// ¿Las letras fueron generadas por IA?
  final bool isAiGenerated;

  const PracticeResources({
    required this.lyrics,
    required this.session,
    this.transcription,
    this.stems,
    this.midiTrack,
    this.isAiGenerated = false,
  });

  /// ¿Tiene stems disponibles?
  bool get hasStemsAvailable => stems?.isComplete ?? false;

  /// ¿Tiene MIDI disponible?
  bool get hasMidiAvailable => midiTrack?.notes.isNotEmpty ?? false;

  /// ¿Puede tocar solo las vocales?
  bool get canPlayVocalsOnly => stems?.vocalsStem != null;
}

/// Parámetros para GetPracticeResourcesUseCase
class GetPracticeResourcesParams extends Equatable {
  final String songId;
  final String songTitle;
  final String songArtist;
  final String? isrc;
  final PracticeMode mode;
  final PracticeDifficulty difficulty;

  const GetPracticeResourcesParams({
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    this.isrc,
    this.mode = PracticeMode.fillBlanks,
    this.difficulty = PracticeDifficulty.medium,
  });

  @override
  List<Object?> get props => [songId, songTitle, songArtist, mode, difficulty];
}
