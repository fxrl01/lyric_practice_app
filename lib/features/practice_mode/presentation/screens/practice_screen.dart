import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/piano_roll.dart';
import '../../../../core/widgets/stem_mixer.dart';
import '../../../../core/widgets/karaoke_view.dart';
import '../widgets/practice_controls.dart';

/// Vista activa en la pantalla de práctica
enum _PracticeTab { mixer, pianoRoll, lyrics }

/// Pantalla completa del Modo Práctica
///
/// Funcionalidades:
/// 1. Stem mixer con mute/solo/volume
/// 2. Piano roll con notas en tiempo real
/// 3. Velocidad ajustable (0.5x - 2x)
/// 4. Metrónomo sincronizado
/// 5. Vista karaoke de letras sincronizadas
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  _PracticeTab _activeTab = _PracticeTab.mixer;

  // Playback state
  bool _isPlaying = false;
  int _positionMs = 0;
  double _playbackSpeed = 1.0;
  int _bpm = 120;
  bool _metronomeActive = false;
  bool _showTools = true;

  // Stem mixer state
  late List<StemChannel> _channels;

  // Demo notes for piano roll
  late List<PianoRollNote> _demoNotes;

  // Demo karaoke lines
  late List<KaraokeLine> _karaokeLines;

  @override
  void initState() {
    super.initState();
    _channels = StemMixer.defaultChannels();
    _demoNotes = _generateDemoNotes();
    _karaokeLines = _generateDemoKaraokeLines();
  }

  List<PianoRollNote> _generateDemoNotes() {
    final random = Random(42);
    final notes = <PianoRollNote>[];
    final scale = [48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67];

    int time = 0;
    for (int i = 0; i < 64; i++) {
      final note = scale[random.nextInt(scale.length)];
      final duration = [250, 500, 750, 1000][random.nextInt(4)];
      notes.add(PianoRollNote(
        midiNote: note,
        startMs: time,
        endMs: time + duration,
        velocity: 0.5 + random.nextDouble() * 0.5,
      ));
      time += duration + random.nextInt(200);
    }
    return notes;
  }

  List<KaraokeLine> _generateDemoKaraokeLines() {
    return [
      const KaraokeLine(text: '♪ Intro instrumental...', startTimeMs: 0, endTimeMs: 4000),
      const KaraokeLine(text: '', startTimeMs: 4000, endTimeMs: 4500),
      const KaraokeLine(text: 'Escucha el ritmo de la música', startTimeMs: 4500, endTimeMs: 7000),
      const KaraokeLine(text: 'Que fluye como el agua cristalina', startTimeMs: 7000, endTimeMs: 10000),
      const KaraokeLine(text: 'Cada nota cuenta una historia', startTimeMs: 10000, endTimeMs: 13000),
      const KaraokeLine(text: 'Que vive dentro de tu alma', startTimeMs: 13000, endTimeMs: 16000),
      const KaraokeLine(text: '', startTimeMs: 16000, endTimeMs: 17000),
      const KaraokeLine(text: '♪ Solo de guitarra...', startTimeMs: 17000, endTimeMs: 24000),
      const KaraokeLine(text: '', startTimeMs: 24000, endTimeMs: 25000),
      const KaraokeLine(text: 'Aprende a sentir cada compás', startTimeMs: 25000, endTimeMs: 28000),
      const KaraokeLine(text: 'Y deja que el sonido te guíe', startTimeMs: 28000, endTimeMs: 31000),
    ];
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      _startPlayback();
    }
  }

  void _startPlayback() {
    Future.doWhile(() async {
      await Future.delayed(Duration(
        milliseconds: (100 / _playbackSpeed).round(),
      ));
      if (!mounted || !_isPlaying) return false;
      setState(() => _positionMs += 100);
      return true;
    });
  }

  void _seekTo(int positionMs) {
    setState(() => _positionMs = positionMs.clamp(0, 60000));
  }

  void _updateStemVolume(String stemId, double volume) {
    setState(() {
      _channels = _channels.map((ch) {
        if (ch.id == stemId) return ch.copyWith(volume: volume);
        return ch;
      }).toList();
    });
  }

  void _toggleMute(String stemId) {
    setState(() {
      _channels = _channels.map((ch) {
        if (ch.id == stemId) return ch.copyWith(isMuted: !ch.isMuted);
        return ch;
      }).toList();
    });
  }

  void _toggleSolo(String stemId) {
    setState(() {
      final wasSolo = _channels.any((ch) => ch.id == stemId && ch.isSolo);
      _channels = _channels.map((ch) {
        if (ch.id == stemId) {
          return ch.copyWith(isSolo: !wasSolo);
        }
        return ch.copyWith(isSolo: false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,

      // ─── AppBar ───
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Modo Práctica',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_playbackSpeed}x · $_bpm BPM',
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Toggle tools panel
          IconButton(
            icon: Icon(
              _showTools
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.tune_rounded,
              color: _showTools ? AppColors.primaryLight : null,
            ),
            onPressed: () => setState(() => _showTools = !_showTools),
          ),
        ],
      ),

      body: Column(
        children: [
          // ─── Tab bar ───
          _buildTabBar(context),

          // ─── Main content area ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(context),
            ),
          ),

          // ─── Tools panel (collapsible) ───
          if (_showTools) _buildToolsPanel(context),

          // ─── Playback controls ───
          _buildPlaybackBar(context),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = [
      (_PracticeTab.mixer, Icons.tune_rounded, 'Mixer'),
      (_PracticeTab.pianoRoll, Icons.piano_rounded, 'Piano Roll'),
      (_PracticeTab.lyrics, Icons.lyrics_rounded, 'Letras'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkElevated,
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.$2,
                      size: 16,
                      color: isActive
                          ? AppColors.primaryLight
                          : AppColors.darkTextMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primaryLight
                            : AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildContent(BuildContext context) {
    switch (_activeTab) {
      case _PracticeTab.mixer:
        return _buildMixerView(context);
      case _PracticeTab.pianoRoll:
        return _buildPianoRollView(context);
      case _PracticeTab.lyrics:
        return _buildLyricsView(context);
    }
  }

  // ═════════════════════════════════════
  // MIXER VIEW
  // ═════════════════════════════════════

  Widget _buildMixerView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('mixer'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stem mixer completo
          StemMixer(
            channels: _channels,
            onVolumeChanged: _updateStemVolume,
            onMuteToggle: _toggleMute,
            onSoloToggle: _toggleSolo,
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Tip card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.info.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.lightbulb_rounded,
                      size: 20, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip de práctica',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Silencia las vocales (M) para practicar cantando '
                        'sobre el instrumental. Usa Solo (S) para aislar '
                        'un instrumento.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.darkTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }

  // ═════════════════════════════════════
  // PIANO ROLL VIEW
  // ═════════════════════════════════════

  Widget _buildPianoRollView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('pianoroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Piano roll
          PianoRoll(
            notes: _demoNotes,
            currentPositionMs: _positionMs,
            height: 300,
            autoScroll: _isPlaying,
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Active note info
          _buildActiveNoteInfo(context),

          const SizedBox(height: 16),

          // Stats
          _buildNoteStats(context),
        ],
      ),
    );
  }

  Widget _buildActiveNoteInfo(BuildContext context) {
    final activeNotes = _demoNotes.where(
      (n) => _positionMs >= n.startMs && _positionMs <= n.endMs,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: activeNotes.isNotEmpty
          ? GlassCard(
              key: ValueKey(activeNotes.first.midiNote),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Note circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        activeNotes.first.noteName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nota actual',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                        Text(
                          activeNotes.first.noteName,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Velocity meter
                  Column(
                    children: [
                      Text(
                        'Velocity',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: activeNotes.first.velocity,
                          strokeWidth: 3,
                          color: AppColors.success,
                          backgroundColor: AppColors.darkBorder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : GlassCard(
              key: const ValueKey('no_note'),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.music_off_rounded,
                      color: AppColors.darkTextMuted, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    _isPlaying ? 'Esperando nota...' : 'Presiona play',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNoteStats(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(context, 'Notas', '${_demoNotes.length}', Icons.music_note_rounded),
        const SizedBox(width: 8),
        _buildStatCard(context, 'Rango', 'C2-C5', Icons.unfold_more_rounded),
        const SizedBox(width: 8),
        _buildStatCard(context, 'Duración', '${(_demoNotes.last.endMs / 1000).toInt()}s', Icons.timer_rounded),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.darkCard,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.darkTextMuted),
            const SizedBox(height: 6),
            Text(
              value,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColors.darkTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════
  // LYRICS VIEW
  // ═════════════════════════════════════

  Widget _buildLyricsView(BuildContext context) {
    return KaraokeView(
      key: const ValueKey('lyrics'),
      lines: _karaokeLines,
      currentPositionMs: _positionMs,
      isPlaying: _isPlaying,
      showTimestamps: true,
      onLineTap: (index, timestampMs) {
        _seekTo(timestampMs);
      },
    );
  }

  // ═════════════════════════════════════
  // TOOLS PANEL
  // ═════════════════════════════════════

  Widget _buildToolsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed control
          SpeedControl(
            speed: _playbackSpeed,
            onSpeedChanged: (speed) {
              setState(() => _playbackSpeed = speed);
            },
          ),

          const SizedBox(height: 8),

          // Compact mixer (when not in mixer tab)
          if (_activeTab != _PracticeTab.mixer)
            StemMixer(
              channels: _channels,
              compact: true,
              onMuteToggle: _toggleMute,
            ),

          const SizedBox(height: 8),

          // Metronome
          MetronomeWidget(
            bpm: _bpm,
            isActive: _metronomeActive,
            onBpmChanged: (bpm) => setState(() => _bpm = bpm),
            onToggle: (active) =>
                setState(() => _metronomeActive = active),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }

  // ═════════════════════════════════════
  // PLAYBACK BAR
  // ═════════════════════════════════════

  Widget _buildPlaybackBar(BuildContext context) {
    const totalDurationMs = 60000;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.darkBorder,
              thumbColor: AppColors.primaryLight,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _positionMs.toDouble().clamp(0, totalDurationMs.toDouble()),
              min: 0,
              max: totalDurationMs.toDouble(),
              onChanged: (v) => _seekTo(v.toInt()),
            ),
          ),

          // Controls
          Row(
            children: [
              // Position
              Text(
                _formatTime(_positionMs),
                style: context.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.darkTextMuted,
                ),
              ),

              const Spacer(),

              // Rewind
              IconButton(
                onPressed: () => _seekTo(_positionMs - 5000),
                icon: const Icon(Icons.replay_5_rounded),
                iconSize: 24,
                color: AppColors.darkTextSecondary,
              ),

              const SizedBox(width: 8),

              // Play/Pause
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Forward
              IconButton(
                onPressed: () => _seekTo(_positionMs + 5000),
                icon: const Icon(Icons.forward_5_rounded),
                iconSize: 24,
                color: AppColors.darkTextSecondary,
              ),

              const Spacer(),

              // Duration
              Text(
                _formatTime(totalDurationMs),
                style: context.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.darkTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
