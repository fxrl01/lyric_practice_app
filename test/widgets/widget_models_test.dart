import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_practice_app/core/widgets/piano_roll.dart';
import 'package:lyric_practice_app/core/widgets/stem_mixer.dart';
import 'package:lyric_practice_app/core/widgets/karaoke_view.dart';

void main() {
  group('PianoRollNote', () {
    test('creates with required fields', () {
      const note = PianoRollNote(
        midiNote: 60,
        startMs: 0,
        endMs: 500,
      );

      expect(note.midiNote, 60);
      expect(note.startMs, 0);
      expect(note.endMs, 500);
      expect(note.velocity, 0.8);
    });

    test('durationMs calculates correctly', () {
      const note = PianoRollNote(
        midiNote: 60,
        startMs: 1000,
        endMs: 2500,
      );
      expect(note.durationMs, 1500);
    });

    test('noteName returns correct names', () {
      // C4 = MIDI 60
      const c4 = PianoRollNote(midiNote: 60, startMs: 0, endMs: 100);
      expect(c4.noteName, 'C4');

      // A4 = MIDI 69
      const a4 = PianoRollNote(midiNote: 69, startMs: 0, endMs: 100);
      expect(a4.noteName, 'A4');

      // E3 = MIDI 52
      const e3 = PianoRollNote(midiNote: 52, startMs: 0, endMs: 100);
      expect(e3.noteName, 'E3');

      // F#5 = MIDI 78
      const fs5 = PianoRollNote(midiNote: 78, startMs: 0, endMs: 100);
      expect(fs5.noteName, 'F#5');
    });
  });

  group('StemChannel', () {
    test('defaultChannels returns 6 channels', () {
      final channels = StemMixer.defaultChannels();
      expect(channels.length, 6);
    });

    test('defaultChannels contains all instruments', () {
      final channels = StemMixer.defaultChannels();
      final ids = channels.map((c) => c.id).toList();

      expect(ids, contains('vocals'));
      expect(ids, contains('drums'));
      expect(ids, contains('bass'));
      expect(ids, contains('guitar'));
      expect(ids, contains('piano'));
      expect(ids, contains('other'));
    });

    test('copyWith modifies correctly', () {
      final channel = StemMixer.defaultChannels().first;

      final muted = channel.copyWith(isMuted: true);
      expect(muted.isMuted, true);
      expect(muted.isSolo, false);
      expect(muted.volume, channel.volume);

      final solo = channel.copyWith(isSolo: true);
      expect(solo.isSolo, true);
      expect(solo.isMuted, false);

      final vol = channel.copyWith(volume: 0.5);
      expect(vol.volume, 0.5);
    });
  });

  group('KaraokeLine', () {
    test('creates with required text', () {
      const line = KaraokeLine(text: 'Hello world');
      expect(line.text, 'Hello world');
      expect(line.startTimeMs, isNull);
      expect(line.isChorus, false);
    });

    test('creates with all fields', () {
      const line = KaraokeLine(
        text: 'Chorus line',
        startTimeMs: 5000,
        endTimeMs: 8000,
        isChorus: true,
        translation: 'Línea del coro',
      );

      expect(line.startTimeMs, 5000);
      expect(line.endTimeMs, 8000);
      expect(line.isChorus, true);
      expect(line.translation, 'Línea del coro');
    });
  });
}
