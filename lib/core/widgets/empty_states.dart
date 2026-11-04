import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';

/// Estados vacíos reutilizables con ilustraciones y CTAs
///
/// Cada empty state incluye un icono animado, título, descripción
/// y opcionalmente un botón de acción.

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon circle
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Icon(icon, size: 44, color: color),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 24),

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),

            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  // ─── Presets ───

  /// Sin canciones reconocidas
  static Widget noHistory({VoidCallback? onStartListening}) {
    return EmptyStateWidget(
      icon: Icons.music_note_rounded,
      title: 'Sin historial',
      subtitle: 'Las canciones que reconozcas\naparecerán aquí',
      iconColor: AppColors.primaryLight,
      action: onStartListening != null
          ? _PrimaryAction(
              label: 'Reconocer canción',
              icon: Icons.mic_rounded,
              onTap: onStartListening,
            )
          : null,
    );
  }

  /// Sin favoritos
  static Widget noFavorites() {
    return const EmptyStateWidget(
      icon: Icons.favorite_rounded,
      title: 'Sin favoritos',
      subtitle: 'Guarda tus canciones favoritas\npara acceder rápidamente',
      iconColor: AppColors.accent,
    );
  }

  /// Sin letras disponibles
  static Widget noLyrics({VoidCallback? onTranscribe}) {
    return EmptyStateWidget(
      icon: Icons.lyrics_rounded,
      title: 'Sin letras',
      subtitle: 'No encontramos letras para esta canción.\n'
          'Transcríbela con inteligencia artificial.',
      iconColor: AppColors.warning,
      action: onTranscribe != null
          ? _PrimaryAction(
              label: 'Transcribir con IA',
              icon: Icons.auto_awesome_rounded,
              onTap: onTranscribe,
            )
          : null,
    );
  }

  /// Sin conexión
  static Widget offline() {
    return const EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'Sin conexión',
      subtitle: 'Algunas funciones no están disponibles\n'
          'en modo offline. Tus canciones recientes\n'
          'siguen disponibles.',
      iconColor: AppColors.darkTextMuted,
    );
  }

  /// Error genérico
  static Widget error({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Algo salió mal',
      subtitle: message ?? 'Ocurrió un error inesperado.\nIntenta de nuevo.',
      iconColor: AppColors.error,
      action: onRetry != null
          ? _PrimaryAction(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onTap: onRetry,
            )
          : null,
    );
  }

  /// Sin sesiones de práctica
  static Widget noPracticeSessions({VoidCallback? onStartPractice}) {
    return EmptyStateWidget(
      icon: Icons.school_rounded,
      title: 'Empieza a practicar',
      subtitle: 'Reconoce una canción y entra\nal modo práctica para aprender.',
      iconColor: AppColors.success,
      action: onStartPractice != null
          ? _PrimaryAction(
              label: 'Reconocer canción',
              icon: Icons.mic_rounded,
              onTap: onStartPractice,
            )
          : null,
    );
  }
}

/// Botón de acción primaria para empty states
class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
