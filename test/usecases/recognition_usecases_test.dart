import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lyric_practice_app/core/error/failures.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/entities/song.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/entities/lyrics.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/repositories/i_song_recognition_repository.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/repositories/i_lyrics_repository.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/usecases/recognize_song_usecase.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/usecases/get_lyrics_usecase.dart';

// ─── Mocks ───
class MockSongRecognitionRepository extends Mock
    implements ISongRecognitionRepository {}

class MockLyricsRepository extends Mock implements ILyricsRepository {}

void main() {
  group('RecognizeSongUseCase', () {
    late MockSongRecognitionRepository mockRepo;
    late RecognizeSongUseCase useCase;

    setUp(() {
      mockRepo = MockSongRecognitionRepository();
      useCase = RecognizeSongUseCase(repository: mockRepo);
    });

    test('returns Song on successful recognition', () async {
      final expectedSong = Song.demo();

      when(() => mockRepo.recognizeSong(
            audioBytes: any(named: 'audioBytes'),
            durationMs: any(named: 'durationMs'),
          )).thenAnswer((_) async => Right(expectedSong));

      final result = await useCase(const RecognizeSongParams(
        audioBytes: [1, 2, 3],
        durationMs: 5000,
      ));

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (song) {
          expect(song.title, 'Bohemian Rhapsody');
          expect(song.artist, 'Queen');
        },
      );
    });

    test('returns ValidationFailure when audio bytes are empty', () async {
      final result = await useCase(const RecognizeSongParams(
        audioBytes: [],
        durationMs: 5000,
      ));

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('audio'));
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns ValidationFailure when audio is too short', () async {
      final result = await useCase(const RecognizeSongParams(
        audioBytes: [1, 2, 3],
        durationMs: 500,
      ));

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('corta'));
        },
        (_) => fail('Expected Left'),
      );
    });

    test('uses humming recognition when isHumming is true', () async {
      final expectedSong = Song.demo();

      when(() => mockRepo.recognizeByHumming(
            audioBytes: any(named: 'audioBytes'),
          )).thenAnswer((_) async => Right(expectedSong));

      final result = await useCase(const RecognizeSongParams(
        audioBytes: [1, 2, 3],
        durationMs: 5000,
        isHumming: true,
      ));

      expect(result.isRight(), true);
      verify(() => mockRepo.recognizeByHumming(
            audioBytes: any(named: 'audioBytes'),
          )).called(1);
      verifyNever(() => mockRepo.recognizeSong(
            audioBytes: any(named: 'audioBytes'),
            durationMs: any(named: 'durationMs'),
          ));
    });

    test('returns failure on repository error', () async {
      when(() => mockRepo.recognizeSong(
            audioBytes: any(named: 'audioBytes'),
            durationMs: any(named: 'durationMs'),
          )).thenAnswer((_) async =>
              const Left(ServerFailure(message: 'API timeout')));

      final result = await useCase(const RecognizeSongParams(
        audioBytes: [1, 2, 3],
        durationMs: 5000,
      ));

      expect(result.isLeft(), true);
    });
  });

  group('GetLyricsUseCase', () {
    late MockLyricsRepository mockRepo;
    late GetLyricsUseCase useCase;

    setUp(() {
      mockRepo = MockLyricsRepository();
      useCase = GetLyricsUseCase(repository: mockRepo);
    });

    test('returns synced lyrics when available (synced-first strategy)',
        () async {
      const syncedLyrics = Lyrics(
        songId: '1',
        isSynced: true,
        lines: [
          LyricLine(
            text: 'Hello',
            startTimeMs: 0,
            endTimeMs: 2000,
          ),
        ],
      );

      when(() => mockRepo.getSyncedLyrics(
            songTitle: any(named: 'songTitle'),
            artist: any(named: 'artist'),
            isrc: any(named: 'isrc'),
          )).thenAnswer((_) async => const Right(syncedLyrics));

      final result = await useCase(const GetLyricsParams(
        songTitle: 'Test Song',
        artist: 'Test Artist',
      ));

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (lyrics) {
          expect(lyrics.isSynced, true);
          expect(lyrics.lineCount, 1);
        },
      );
    });

    test('falls back to plain lyrics when synced unavailable', () async {
      const plainLyrics = Lyrics(
        songId: '1',
        isSynced: false,
        lines: [LyricLine(text: 'Plain text')],
      );

      when(() => mockRepo.getSyncedLyrics(
            songTitle: any(named: 'songTitle'),
            artist: any(named: 'artist'),
            isrc: any(named: 'isrc'),
          )).thenAnswer(
              (_) async => const Left(RecognitionFailure(message: 'No synced')));

      when(() => mockRepo.getLyrics(
            songTitle: any(named: 'songTitle'),
            artist: any(named: 'artist'),
            isrc: any(named: 'isrc'),
            duration: any(named: 'duration'),
          )).thenAnswer((_) async => const Right(plainLyrics));

      final result = await useCase(const GetLyricsParams(
        songTitle: 'Test Song',
        artist: 'Test Artist',
      ));

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (lyrics) => expect(lyrics.isSynced, false),
      );
    });

    test('returns ValidationFailure when title is empty', () async {
      final result = await useCase(const GetLyricsParams(
        songTitle: '',
        artist: 'Artist',
      ));

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns ValidationFailure when artist is empty', () async {
      final result = await useCase(const GetLyricsParams(
        songTitle: 'Song',
        artist: '',
      ));

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
