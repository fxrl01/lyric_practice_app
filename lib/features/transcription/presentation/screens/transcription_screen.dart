import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/karaoke_view.dart';
import '../../../../core/services/speech_to_text_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/providers/audio_recording_provider.dart';
import '../../../song_recognition/domain/entities/lyrics.dart';
import '../../../song_recognition/presentation/providers/song_recognition_provider.dart';
import '../providers/transcription_provider.dart';
import '../widgets/translation_panel.dart';
import '../widgets/lyrics_editor.dart';

/// Vista de la pantalla de transcripción/letras
enum _ViewMode { normal, karaoke, editor }

/// Pantalla completa de Transcripción / Letras
///
/// Funcionalidades:
/// 1. Muestra letras obtenidas de API
/// 2. Transcripción automática con IA (Whisper)
/// 3. Vista karaoke-style con highlight
/// 4. Traducción a múltiples idiomas
/// 5. Corrección manual por el usuario
class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({super.key});

  @override
  ConsumerState<TranscriptionScreen> createState() =>
      _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen>
    with SingleTickerProviderStateMixin {
  _ViewMode _viewMode = _ViewMode.normal;
  bool _showTranslation = false;
  int _simulatedPositionMs = 0;
  bool _isSimulatingPlayback = false;

  // Letras editadas por el usuario (solo sesión)
  Lyrics? _editedLyrics;

  /// Letras efectivas (editadas o originales)
  Lyrics? _getEffectiveLyrics() {
    if (_editedLyrics != null) return _editedLyrics;
    return ref.read(songRecognitionProvider).lyrics;
  }

  void _startSimulatedPlayback() {
    if (_isSimulatingPlayback) return;
    setState(() => _isSimulatingPlayback = true);

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || !_isSimulatingPlayback) return false;
      setState(() => _simulatedPositionMs += 100);
      return true;
    });
  }

  void _stopSimulatedPlayback() {
    setState(() => _isSimulatingPlayback = false);
  }

  void _seekTo(int positionMs) {
    setState(() => _simulatedPositionMs = positionMs);
  }

  @override
  Widget build(BuildContext context) {
    final songState = ref.watch(songRecognitionProvider);
    final transState = ref.watch(transcriptionProvider);
    final translationState = ref.watch(translationProvider);
    final song = songState.song;
    final lyrics = _editedLyrics ?? songState.lyrics;

    return Scaffold(
      // ─── AppBar ───
      appBar: AppBar(
        backgroundColor: AppColors.darkBg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              song?.title ?? 'Letras',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (song?.artist != null)
              Text(
                song!.artist,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.darkTextMuted,
                ),
              ),
          ],
        ),
        actions: [
          // Toggle karaoke mode
          if (lyrics != null && lyrics.isSynced)
            IconButton(
              icon: Icon(
                _viewMode == _ViewMode.karaoke
                    ? Icons.view_list_rounded
                    : Icons.music_note_rounded,
                color: _viewMode == _ViewMode.karaoke
                    ? AppColors.primaryLight
                    : null,
              ),
              tooltip: _viewMode == _ViewMode.karaoke
                  ? 'Vista normal'
                  : 'Vista karaoke',
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == _ViewMode.karaoke
                      ? _ViewMode.normal
                      : _ViewMode.karaoke;
                });
              },
            ),

          // Edit mode
          if (lyrics != null)
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: _viewMode == _ViewMode.editor
                    ? AppColors.warning
                    : null,
                size: 20,
              ),
              tooltip: 'Editar letras',
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == _ViewMode.editor
                      ? _ViewMode.normal
                      : _ViewMode.editor;
                });
              },
            ),

          // Translation toggle
          if (lyrics != null)
            IconButton(
              icon: Icon(
                Icons.translate_rounded,
                color: _showTranslation ? AppColors.primaryLight : null,
                size: 20,
              ),
              tooltip: 'Traducir',
              onPressed: () {
                setState(() => _showTranslation = !_showTranslation);
              },
            ),

          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'transcribe':
                  _startAITranscription();
                  break;
                case 'copy':
                  _copyLyrics(lyrics);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'transcribe',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('Transcribir con IA'),
                  ],
                ),
              ),
              if (lyrics != null)
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Copiar letras'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),

      // ─── Body ───
      body: Column(
        children: [
          // AI Banner
          if (lyrics?.isAiGenerated == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warning.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transcripción generada por IA — puede contener errores',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  if (lyrics?.aiConfidence != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.warning.withValues(alpha: 0.15),
                      ),
                      child: Text(
                        '${(lyrics!.aiConfidence! * 100).toInt()}%',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Edited indicator
          if (_editedLyrics != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.success.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Letras editadas por ti',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _editedLyrics = null),
                    child: Text(
                      'Restaurar original',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Translation panel
          if (_showTranslation && lyrics != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TranslationPanel(
                lyrics: lyrics,
                currentLanguage: lyrics.language,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),

          // Loading state (transcription)
          if (transState.isLoading)
            _buildTranscriptionProgress(context, transState),

          // ─── Content ───
          Expanded(
            child: lyrics != null && lyrics.isNotEmpty
                ? _buildLyricsContent(context, lyrics, translationState)
                : _buildEmptyState(context, transState),
          ),

          // ─── Playback controls (karaoke mode) ───
          if (_viewMode == _ViewMode.karaoke && lyrics != null)
            _buildPlaybackControls(context, lyrics),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(
    BuildContext context,
    Lyrics lyrics,
    TranslationState translationState,
  ) {
    // Editor mode
    if (_viewMode == _ViewMode.editor) {
      return LyricsEditor(
        lyrics: lyrics,
        onSave: (updatedLyrics) {
          setState(() {
            _editedLyrics = updatedLyrics;
            _viewMode = _ViewMode.normal;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Letras actualizadas'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        },
        onCancel: () {
          setState(() => _viewMode = _ViewMode.normal);
        },
      ).animate().fadeIn(duration: 200.ms);
    }

    // Karaoke mode
    if (_viewMode == _ViewMode.karaoke && lyrics.isSynced) {
      return KaraokeView(
        lines: lyrics.lines
            .map((l) => KaraokeLine(
                  text: l.text,
                  startTimeMs: l.startTimeMs,
                  endTimeMs: l.endTimeMs,
                  isChorus: l.isChorus,
                  translation: translationState.translations[
                      lyrics.lines.indexOf(l)],
                ))
            .toList(),
        currentPositionMs: _simulatedPositionMs,
        isPlaying: _isSimulatingPlayback,
        showTimestamps: true,
        onLineTap: (index, timestampMs) {
          _seekTo(timestampMs);
        },
      );
    }

    // Normal mode
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: lyrics.lineCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildLyricsHeader(context, lyrics);
        }

        final lineIndex = index - 1;
        final line = lyrics.lines[lineIndex];
        final translation = translationState.translations[lineIndex];

        if (line.text.isEmpty) {
          return const SizedBox(height: 20);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp
                  if (lyrics.isSynced && line.startTimeMs != null)
                    SizedBox(
                      width: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          line.formattedStartTime,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.darkTextMuted.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),

                  // Texto
                  Expanded(
                    child: Text(
                      line.text,
                      style: context.textTheme.bodyLarge?.copyWith(
                        height: 1.7,
                        fontWeight:
                            line.isChorus ? FontWeight.w600 : FontWeight.w400,
                        color: line.isChorus
                            ? AppColors.primaryLight
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              // Traducción inline
              if (translation != null && _showTranslation)
                Padding(
                  padding: EdgeInsets.only(
                    left: lyrics.isSynced ? 44 : 0,
                    top: 2,
                    bottom: 4,
                  ),
                  child: Text(
                    translation,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryLight.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricsHeader(BuildContext context, Lyrics lyrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metadata
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              icon: lyrics.isSynced
                  ? Icons.timer_rounded
                  : Icons.text_fields_rounded,
              label: lyrics.isSynced ? 'Sincronizada' : 'Sin sincronizar',
              color: lyrics.isSynced ? AppColors.success : AppColors.darkTextMuted,
            ),
            _buildInfoChip(
              icon: Icons.text_snippet_rounded,
              label: '${lyrics.lineCount} líneas',
            ),
            _buildInfoChip(
              icon: Icons.abc_rounded,
              label: '${lyrics.wordCount} palabras',
            ),
            if (lyrics.language != 'unknown')
              _buildInfoChip(
                icon: Icons.language_rounded,
                label: lyrics.language.toUpperCase(),
              ),
          ],
        ),

        // Source attribution
        if (lyrics.attribution != null) ...[
          const SizedBox(height: 12),
          Text(
            lyrics.attribution!,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.darkTextMuted.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],

        const Divider(height: 32),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: (color ?? AppColors.darkTextMuted).withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? AppColors.darkTextMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? AppColors.darkTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionProgress(
    BuildContext context,
    TranscriptionState transState,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkElevated,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transcribiendo con Whisper IA...',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(transState.progress * 100).toInt()}% completado',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: transState.progress,
              minHeight: 4,
              backgroundColor: AppColors.darkBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(BuildContext context, TranscriptionState transState) {
    if (transState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            SizedBox(height: 16),
            Text('Procesando...'),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.lyrics_rounded,
                size: 56,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin letras disponibles',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No encontramos letras para esta canción.\n'
              'Puedes transcribirla automáticamente con IA.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Transcribe button
            GradientButton(
              onPressed: transState.isServiceAvailable
                  ? _startAITranscription
                  : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Transcribir con IA',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            if (!transState.isServiceAvailable) ...[
              const SizedBox(height: 12),
              Text(
                'Configura tu API key de OpenAI para usar esta función',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Error message
            if (transState.hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.error.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      transState.result.error.toString(),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, Lyrics lyrics) {
    final totalDurationMs = lyrics.lines.lastOrNull?.endTimeMs ?? 
        (lyrics.lines.lastOrNull?.startTimeMs ?? 0) + 5000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
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
              value: _simulatedPositionMs
                  .toDouble()
                  .clamp(0, totalDurationMs.toDouble()),
              min: 0,
              max: totalDurationMs.toDouble(),
              onChanged: (value) => _seekTo(value.toInt()),
            ),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Time
              Text(
                _formatTime(_simulatedPositionMs),
                style: context.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.darkTextMuted,
                ),
              ),

              const Spacer(),

              // Rewind 5s
              IconButton(
                onPressed: () =>
                    _seekTo((_simulatedPositionMs - 5000).clamp(0, totalDurationMs)),
                icon: const Icon(Icons.replay_5_rounded),
                iconSize: 28,
              ),

              // Play/Pause
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: IconButton(
                  onPressed: _isSimulatingPlayback
                      ? _stopSimulatedPlayback
                      : _startSimulatedPlayback,
                  icon: Icon(
                    _isSimulatingPlayback
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),
              ),

              // Forward 5s
              IconButton(
                onPressed: () =>
                    _seekTo((_simulatedPositionMs + 5000).clamp(0, totalDurationMs)),
                icon: const Icon(Icons.forward_5_rounded),
                iconSize: 28,
              ),

              const Spacer(),

              // Total time
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

  void _startAITranscription() async {
    final audioState = ref.read(audioRecordingProvider);
    final audioBytes = audioState.audioBytes;
    
    if (audioBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay audio grabado para transcribir'),
        ),
      );
      return;
    }
    
    // Usar SpeechToTextService (Google Speech-to-Text gratis)
    final speechService = ref.read(speechToTextServiceProvider);
    
    try {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 12),
              Text('Transcribiendo con Google IA...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Transcribir
      final transcription = await speechService.transcribeAudio(
        audioBytes: audioBytes,
        languageCode: 'es-ES',
      );
      
      // Crear lyrics a partir de transcripción
      if (transcription.isNotEmpty) {
        final lines = transcription.split('\n').map((line) => LyricLine(text: line)).toList();
        final newLyrics = Lyrics(
          songId: ref.read(songRecognitionProvider).song?.id ?? 'transcribed',
          lines: lines,
          language: 'es',
          source: LyricsSource.aiGenerated,
          isSynced: false,
          isAiGenerated: true,
          aiConfidence: 0.85,
          attribution: 'Transcrito con Google Speech-to-Text',
        );
        
        // Guardar en state
        ref.read(songRecognitionProvider.notifier).state = 
            ref.read(songRecognitionProvider).copyWith(
              lyricsResult: AsyncValue.data(newLyrics),
            );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transcripción completada: ${lines.length} líneas'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en transcripción: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyLyrics(Lyrics? lyrics) {
    if (lyrics == null) return;
    // TODO: Clipboard.setData(ClipboardData(text: lyrics.plainText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Letras copiadas al portapapeles'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
