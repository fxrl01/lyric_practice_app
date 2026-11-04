import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/wave_visualizer.dart';
import '../../../../core/providers/audio_recording_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../providers/song_recognition_provider.dart';

/// Pantalla principal — Reconocimiento de canciones
///
/// Flujo:
/// 1. Estado idle → botón grande "Escuchar"
/// 2. Grabando → visualizador de ondas + timer
/// 3. Procesando → spinner + buscando
/// 4. Resultado → navega a /result
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onListenTap() {
    HapticService.buttonTap();
    final state = ref.read(songRecognitionProvider);
    final audioState = ref.read(audioRecordingProvider);

    if (state.isListening || audioState.isRecording) {
      // Detener y reconocer
      ref.read(songRecognitionProvider.notifier).stopAndRecognize();
      _pulseController.stop();
      _rippleController.stop();
    } else {
      // Iniciar grabación
      ref.read(songRecognitionProvider.notifier).startRecognition();
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final songState = ref.watch(songRecognitionProvider);
    final audioState = ref.watch(audioRecordingProvider);
    final isRecording = audioState.isRecording;
    final isProcessing = songState.recognitionResult.isLoading;

    // Navegar al resultado cuando hay canción reconocida
    ref.listen<SongRecognitionState>(songRecognitionProvider, (prev, next) {
      if (next.hasSong && prev?.hasSong != true) {
        _pulseController.stop();
        _rippleController.stop();
        context.push('/result');
      }
    });

    // Manejar errores
    ref.listen<SongRecognitionState>(songRecognitionProvider, (prev, next) {
      if (next.recognitionResult.hasError && prev?.recognitionResult.hasError != true) {
        _pulseController.stop();
        _rippleController.stop();
        _showError(next.recognitionResult.error.toString());
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkBg,
              Color(0xFF0F0A1E),
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // ─── Hero section ───
              _buildHero(context).animate().fadeIn(
                    duration: 600.ms,
                    delay: 200.ms,
                  ),

              const SizedBox(height: 32),

              // ─── Visualizador de ondas ───
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isRecording
                    ? WaveVisualizer(
                        key: const ValueKey('wave_active'),
                        amplitude: audioState.amplitude,
                        isActive: true,
                        barCount: 50,
                        maxHeight: 60,
                      )
                    : const SizedBox(
                        key: ValueKey('wave_idle'),
                        height: 60,
                      ),
              ),

              const SizedBox(height: 24),

              // ─── Botón principal ───
              _buildMainButton(
                context,
                isRecording: isRecording,
                isProcessing: isProcessing,
                progress: audioState.progress,
              ),

              const SizedBox(height: 20),

              // ─── Estado + Timer ───
              _buildStatus(
                context,
                isRecording: isRecording,
                isProcessing: isProcessing,
                elapsed: audioState.formattedElapsed,
              ),

              const Spacer(flex: 1),

              // ─── Features ───
              _buildFeatureChips(context).animate().fadeIn(
                    duration: 500.ms,
                    delay: 600.ms,
                  ),

              const SizedBox(height: 16),

              // ─── Historial rápido ───
              _buildHistoryPreview(context, songState),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.primaryGradient,
            ),
            child: const Center(
              child: Text('🎵', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'LyricFlow',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, size: 22),
          tooltip: 'Historial',
          onPressed: () {
            _showHistorySheet(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Powered by AI',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Título principal
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'Descubre la\nMúsica',
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Reconoce, aprende letras y practica\ncon inteligencia artificial',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkTextSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required bool isRecording,
    required bool isProcessing,
    required double progress,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isRecording ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple rings cuando graba
              if (isRecording) ...[
                _buildAnimatedRipple(2.0, 0),
                _buildAnimatedRipple(1.7, 300),
                _buildAnimatedRipple(1.4, 600),
              ],

              // Anillo de progreso
              if (isRecording)
                GradientProgressRing(
                  progress: progress,
                  size: 180,
                  strokeWidth: 3,
                ),

              // Botón central
              GestureDetector(
                onTap: isProcessing ? null : _onListenTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isRecording ? 150 : 160,
                  height: isRecording ? 150 : 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isProcessing
                        ? const LinearGradient(
                            colors: [AppColors.darkElevated, AppColors.darkCard],
                          )
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: isRecording
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: isRecording ? 60 : 30,
                        spreadRadius: isRecording ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isProcessing
                          ? const SizedBox(
                              key: ValueKey('processing'),
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryLight,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              key: ValueKey(isRecording),
                              size: isRecording ? 48 : 56,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRipple(double maxScale, int delayMs) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final t = ((_rippleController.value * 1000 - delayMs) / 1000)
            .clamp(0.0, 1.0);
        final scale = 1.0 + (maxScale - 1.0) * t;
        final opacity = (1.0 - t) * 0.25;

        return Container(
          width: 160 * scale,
          height: 160 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatus(
    BuildContext context, {
    required bool isRecording,
    required bool isProcessing,
    required String elapsed,
  }) {
    String text;
    Color textColor;
    IconData? icon;

    if (isProcessing) {
      text = 'Buscando canción...';
      textColor = AppColors.warning;
      icon = Icons.search_rounded;
    } else if (isRecording) {
      text = 'Escuchando · $elapsed';
      textColor = AppColors.primaryLight;
      icon = Icons.hearing_rounded;
    } else {
      text = 'Toca para reconocer';
      textColor = AppColors.darkTextMuted;
      icon = null;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(text),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips(BuildContext context) {
    final features = [
      ('🎵', 'Reconocer'),
      ('📝', 'Letras'),
      ('🤖', 'Transcribir'),
      ('🎓', 'Practicar'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: features.map((f) {
          return _FeatureChip(emoji: f.$1, label: f.$2);
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryPreview(
    BuildContext context,
    SongRecognitionState state,
  ) {
    final history = state.history.valueOrNull ?? [];
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded,
                    size: 16, color: AppColors.darkTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'Recientes',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showHistorySheet(context),
                  child: Text(
                    'Ver todo',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...history.take(2).map((song) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.subtleGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.music_note_rounded,
                              size: 18, color: AppColors.primaryLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: AppColors.darkTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideY(begin: 0.1);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    final history = ref.read(songRecognitionProvider).history.valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.darkBorder,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Historial de Reconocimiento',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.music_off_rounded,
                            size: 48, color: AppColors.darkTextMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No hay canciones reconocidas aún',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.darkTextMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final song = history[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: AppColors.subtleGradient,
                          ),
                          child: const Center(
                            child: Icon(Icons.music_note_rounded,
                                color: AppColors.primaryLight),
                          ),
                        ),
                        title: Text(song.title,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          song.artist,
                          style: const TextStyle(color: AppColors.darkTextMuted),
                        ),
                        trailing: Text(
                          song.formattedDuration,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.darkTextMuted,
                                  ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Chip de feature compacto
class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _FeatureChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
