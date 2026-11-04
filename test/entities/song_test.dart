import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/entities/song.dart';

void main() {
  group('Song Entity', () {
    test('creates a Song with required fields', () {
      final song = Song(
        id: '123',
        title: 'Test Song',
        artist: 'Test Artist',
      );

      expect(song.id, '123');
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.source, 'unknown');
      expect(song.hasLyrics, false);
      expect(song.externalLinks, isEmpty);
    });

    test('Song.demo() creates a valid demo song', () {
      final song = Song.demo();

      expect(song.title, 'Bohemian Rhapsody');
      expect(song.artist, 'Queen');
      expect(song.album, 'A Night at the Opera');
      expect(song.source, 'demo');
      expect(song.hasLyrics, true);
      expect(song.confidence, 0.95);
      expect(song.genre, 'Rock');
      expect(song.externalLinks, isNotEmpty);
    });

    test('Song.empty() creates an empty song', () {
      final song = Song.empty();

      expect(song.isEmpty, true);
      expect(song.isNotEmpty, false);
      expect(song.id, '');
      expect(song.title, '');
      expect(song.source, 'none');
    });

    test('formattedDuration returns correct format', () {
      final song = Song(
        id: '1',
        title: 'Test',
        artist: 'Artist',
        durationMs: 210000, // 3:30
      );

      expect(song.formattedDuration, '3:30');
    });

    test('formattedDuration returns --:-- when null', () {
      final song = Song(id: '1', title: 'T', artist: 'A');
      expect(song.formattedDuration, '--:--');
    });

    test('confidencePercent formats correctly', () {
      final song = Song(
        id: '1',
        title: 'T',
        artist: 'A',
        confidence: 0.95,
      );

      expect(song.confidencePercent, '95%');
    });

    test('confidencePercent returns N/A when null', () {
      final song = Song(id: '1', title: 'T', artist: 'A');
      expect(song.confidencePercent, 'N/A');
    });

    test('isHighConfidence works correctly', () {
      expect(
        Song(id: '1', title: 'T', artist: 'A', confidence: 0.85)
            .isHighConfidence,
        true,
      );
      expect(
        Song(id: '1', title: 'T', artist: 'A', confidence: 0.5)
            .isHighConfidence,
        false,
      );
      expect(
        Song(id: '1', title: 'T', artist: 'A').isHighConfidence,
        false,
      );
    });

    test('displayName returns "Artist — Title"', () {
      final song = Song(id: '1', title: 'My Song', artist: 'My Artist');
      expect(song.displayName, 'My Artist — My Song');
    });

    test('copyWith creates modified copy', () {
      final original = Song.demo();
      final copy = original.copyWith(
        title: 'New Title',
        confidence: 0.99,
      );

      expect(copy.title, 'New Title');
      expect(copy.confidence, 0.99);
      expect(copy.artist, original.artist); // unchanged
      expect(copy.album, original.album); // unchanged
      expect(copy.id, original.id); // unchanged
    });

    test('Equatable: same data == same song', () {
      final now = DateTime(2024, 1, 1);
      final song1 = Song(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        recognizedAt: now,
      );
      final song2 = Song(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        recognizedAt: now,
      );

      expect(song1, equals(song2));
    });

    test('Equatable: different id != different song', () {
      final song1 = Song(id: '1', title: 'Song', artist: 'Artist');
      final song2 = Song(id: '2', title: 'Song', artist: 'Artist');

      expect(song1, isNot(equals(song2)));
    });

    test('releaseYear extracts year correctly', () {
      final song = Song(
        id: '1',
        title: 'T',
        artist: 'A',
        releaseDate: DateTime(1975, 10, 31),
      );
      expect(song.releaseYear, 1975);
    });
  });
}
