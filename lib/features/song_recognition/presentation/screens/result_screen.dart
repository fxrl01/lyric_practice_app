import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/services/haptic_service.dart';
import '../../domain/entities/song.dart';
import '../providers/song_recognition_provider.dart';

/// Pantalla de resultado — Muestra la canción reconocida
///
/// Incluye:
/// - Carátula del álbum (o gradiente placeholder)
/// - Título, artista, álbum
/// - Metadata (género, duración, confianza)
/// - Preview de letras (si las hay)
/// - Botones: Ver Letras completas | Modo Práctica
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(songRecognitionProvider);
    final song = state.song;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_off_rounded,
                  size: 64, color: AppColors.darkTextMuted),
              const SizedBox(height: 16),
              Text('No hay resultado',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Regresa e intenta reconocer una canción',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkTextMuted,
                      )),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () {
            ref.read(songRecognitionProvider.notifier).reset();
            context.go('/');
          },
        ),
        actions: [
          // Favorite toggle
          Consumer(
            builder: (context, ref, _) {
              final favState = ref.watch(favoritesProvider);
              final isFav = favState.isFavorite(song.id);
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFav ? AppColors.accent : null,
                  ),
                ),
                onPressed: () {
                  HapticService.lightTap();
                  ref.read(favoritesProvider.notifier).toggleFavorite(song);
                                },
              );
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Icon(Icons.share_rounded, size: 20),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Album Art Hero ───
            _buildAlbumHero(context, song),

            // ─── Song Info ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Título y Artista
                  _buildSongInfo(context, song)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Metadata chips
                  _buildMetadataChips(context, song)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 28),

                  // Botones de acción
                  _buildActionButtons(context, ref, song, state)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 28),

                  // Preview de letras
                  _buildLyricsPreview(context, ref, state)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 600.ms),

                  const SizedBox(height: 28),

                  // Links externos
                  _buildExternalLinks(context, song)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 700.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumHero(BuildContext context, Song song) {
    return SizedBox(
      height: 380,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient (placeholder para cover art)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.6),
                  AppColors.accent.withValues(alpha: 0.4),
                  AppColors.darkBg,
                ],
              ),
            ),
          ),

          // Overlay gradiente inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkBg.withValues(alpha: 0.8),
                    AppColors.darkBg,
                  ],
                ),
              ),
            ),
          ),

          // Album art icon (centro)
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: AppColors.subtleGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.album_rounded,
                    size: 64,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.album ?? 'Single',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.darkTextMuted,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ),

          // Confidence badge
          if (song.confidence != null)
            Positioned(
              top: 100,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      song.confidencePercent,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, Song song) {
    return Column(
      children: [
        Text(
          song.title,
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: context.textTheme.titleMedium?.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (song.album != null) ...[
          const SizedBox(height: 4),
          Text(
            song.album!,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.darkTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataChips(BuildContext context, Song song) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (song.genre != null)
          _MetaChip(
            icon: Icons.library_music_rounded,
            label: song.genre!,
          ),
        if (song.durationMs != null)
          _MetaChip(
            icon: Icons.timer_rounded,
            label: song.formattedDuration,
          ),
        if (song.releaseDate != null)
          _MetaChip(
            icon: Icons.calendar_today_rounded,
            label: '${song.releaseDate!.year}',
          ),
        _MetaChip(
          icon: Icons.cloud_rounded,
          label: song.source.toUpperCase(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Song song,
    SongRecognitionState state,
  ) {
    return Column(
      children: [
        // Botón principal: Ver Letras
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            onPressed: () {
              if (!state.hasLyrics) {
                ref.read(songRecognitionProvider.notifier).fetchLyrics(
                      songTitle: song.title,
                      artist: song.artist,
                      isrc: song.isrc,
                    );
              }
              context.push('/transcription');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lyrics_rounded, size: 20),
                const SizedBox(width: 10),
                Text(
                  song.hasLyrics ? 'Ver Letras' : 'Transcribir con IA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Botón secundario: Modo Práctica
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/practice'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.darkBorder),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_rounded, size: 20),
                SizedBox(width: 10),
                Text(
                  'Modo Práctica',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsPreview(
    BuildContext context,
    WidgetRef ref,
    SongRecognitionState state,
  ) {
    return state.lyricsResult.when(
      loading: () => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando letras...',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Letras no disponibles',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Puedes transcribir esta canción con IA',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) {
          return const SizedBox.shrink();
        }

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    lyrics.isAiGenerated
                        ? Icons.auto_awesome_rounded
                        : Icons.lyrics_rounded,
                    size: 18,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lyrics.isAiGenerated
                        ? 'Transcripción IA'
                        : 'Preview de Letras',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (lyrics.source.name.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        lyrics.source.name,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),

              // AI banner si es transcripción
              if (lyrics.isAiGenerated) ...[
                const SizedBox(height: 12),
                const AiBanner(),
              ],

              const SizedBox(height: 16),

              // Preview de las primeras líneas
              ...lyrics.lines.take(6).map((line) {
                if (line.text.isEmpty) return const SizedBox(height: 8);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    line.text,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.6,
                    ),
                  ),
                );
              }),

              if (lyrics.lineCount > 6) ...[
                const SizedBox(height: 8),
                Text(
                  '... ${lyrics.lineCount - 6} líneas más',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.darkTextMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Copyright/Attribution
              if (lyrics.attribution != null) ...[
                const SizedBox(height: 12),
                Text(
                  lyrics.attribution!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.darkTextMuted.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExternalLinks(BuildContext context, Song song) {
    if (song.externalLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escuchar en',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: song.externalLinks.entries.map((entry) {
            IconData icon;
            Color color;
            switch (entry.key.toLowerCase()) {
              case 'spotify':
                icon = Icons.play_circle_fill_rounded;
                color = const Color(0xFF1DB954);
                break;
              case 'youtube':
                icon = Icons.play_circle_fill_rounded;
                color = const Color(0xFFFF0000);
                break;
              case 'apple_music':
                icon = Icons.play_circle_fill_rounded;
                color = const Color(0xFFFC3C44);
                break;
              default:
                icon = Icons.link_rounded;
                color = AppColors.darkTextSecondary;
            }

            return ActionChip(
              avatar: Icon(icon, size: 18, color: color),
              label: Text(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                style: context.textTheme.labelSmall,
              ),
              onPressed: () {
                // TODO: Abrir URL externamente
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Chip de metadata
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.darkTextMuted),
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
