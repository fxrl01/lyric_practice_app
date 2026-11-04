import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_practice_app/features/song_recognition/domain/entities/lyrics.dart';

void main() {
  group('Lyrics Entity', () {
    test('creates with required fields', () {
      const lyrics = Lyrics(
        songId: 'song_1',
        lines: [
          LyricLine(text: 'Hello world'),
          LyricLine(text: 'Goodbye world'),
        ],
      );

      expect(lyrics.songId, 'song_1');
      expect(lyrics.lineCount, 2);
      expect(lyrics.language, 'unknown');
      expect(lyrics.isSynced, false);
      expect(lyrics.isAiGenerated, false);
    });

    test('plainText joins all lines', () {
      const lyrics = Lyrics(
        songId: '1',
        lines: [
          LyricLine(text: 'Line one'),
          LyricLine(text: 'Line two'),
          LyricLine(text: 'Line three'),
        ],
      );

      expect(lyrics.plainText, 'Line one\nLine two\nLine three');
    });

    test('wordCount counts all words', () {
      const lyrics = Lyrics(
        songId: '1',
        lines: [
          LyricLine(text: 'Hello beautiful world'),
          LyricLine(text: 'Goodbye cruel world'),
        ],
      );

      expect(lyrics.wordCount, 6);
    });

    test('isEmpty and isNotEmpty work correctly', () {
      const empty = Lyrics(songId: '1', lines: []);
      const nonEmpty = Lyrics(
        songId: '1',
        lines: [LyricLine(text: 'Hey')],
      );

      expect(empty.isEmpty, true);
      expect(empty.isNotEmpty, false);
      expect(nonEmpty.isEmpty, false);
      expect(nonEmpty.isNotEmpty, true);
    });

    test('getActiveLineAt returns correct synced line', () {
      const lyrics = Lyrics(
        songId: '1',
        isSynced: true,
        lines: [
          LyricLine(text: 'First', startTimeMs: 0, endTimeMs: 5000),
          LyricLine(text: 'Second', startTimeMs: 5000, endTimeMs: 10000),
          LyricLine(text: 'Third', startTimeMs: 10000, endTimeMs: 15000),
        ],
      );

      expect(lyrics.getActiveLineAt(3000)?.text, 'First');
      expect(lyrics.getActiveLineAt(7000)?.text, 'Second');
      expect(lyrics.getActiveLineAt(12000)?.text, 'Third');
    });

    test('getActiveLineAt returns null for unsynced', () {
      const lyrics = Lyrics(
        songId: '1',
        lines: [LyricLine(text: 'Test')],
      );

      expect(lyrics.getActiveLineAt(1000), isNull);
    });

    test('getActiveLineIndex returns correct index', () {
      const lyrics = Lyrics(
        songId: '1',
        isSynced: true,
        lines: [
          LyricLine(text: 'A', startTimeMs: 0),
          LyricLine(text: 'B', startTimeMs: 5000),
          LyricLine(text: 'C', startTimeMs: 10000),
        ],
      );

      expect(lyrics.getActiveLineIndex(0), 0);
      expect(lyrics.getActiveLineIndex(6000), 1);
      expect(lyrics.getActiveLineIndex(11000), 2);
    });

    test('uniqueWords returns sorted unique words', () {
      const lyrics = Lyrics(
        songId: '1',
        lines: [
          LyricLine(text: 'Hello world hello'),
          LyricLine(text: 'World goodbye hello'),
        ],
      );

      final words = lyrics.uniqueWords;
      expect(words, contains('hello'));
      expect(words, contains('world'));
      expect(words, contains('goodbye'));
      // Should be unique
      expect(words.where((w) => w == 'hello').length, 1);
    });

    test('copyWith creates modified copy', () {
      const original = Lyrics(
        songId: '1',
        lines: [LyricLine(text: 'A')],
        language: 'en',
      );

      final copy = original.copyWith(language: 'es');

      expect(copy.language, 'es');
      expect(copy.songId, '1');
      expect(copy.lineCount, 1);
    });
  });

  group('LyricLine', () {
    test('formattedStartTime returns correct format', () {
      const line = LyricLine(text: 'Test', startTimeMs: 65000);
      expect(line.formattedStartTime, '1:05');
    });

    test('formattedStartTime returns empty when null', () {
      const line = LyricLine(text: 'Test');
      expect(line.formattedStartTime, '');
    });

    test('durationMs calculates correctly', () {
      const line = LyricLine(
        text: 'Test',
        startTimeMs: 1000,
        endTimeMs: 3500,
      );
      expect(line.durationMs, 2500);
    });

    test('durationMs returns null when timestamps missing', () {
      const line = LyricLine(text: 'Test');
      expect(line.durationMs, isNull);
    });
  });

  group('LyricsSource', () {
    test('attributionText returns correct text', () {
      expect(
        LyricsSource.musixmatch.attributionText,
        'Powered by Musixmatch',
      );
      expect(
        LyricsSource.aiTranscription.attributionText,
        contains('IA'),
      );
      expect(LyricsSource.unknown.attributionText, '');
    });

    test('requiresDisclaimer is true for AI and user sources', () {
      expect(LyricsSource.aiTranscription.requiresDisclaimer, true);
      expect(LyricsSource.userContributed.requiresDisclaimer, true);
      expect(LyricsSource.musixmatch.requiresDisclaimer, false);
    });
  });
}
