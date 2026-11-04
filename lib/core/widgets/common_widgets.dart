import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Tarjeta con efecto glassmorphism
/// 
/// Widget reutilizable para crear superficies elevadas
/// con blur de fondo y bordes sutiles.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Shimmer loading placeholder
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            AppColors.darkElevated,
            AppColors.darkElevated.withValues(alpha: 0.5),
            AppColors.darkElevated,
          ],
        ),
      ),
    );
  }
}

/// Botón con gradiente premium
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Gradient? gradient;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: onPressed != null
            ? (gradient ?? AppColors.primaryGradient)
            : null,
        color: onPressed == null ? AppColors.darkElevated : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

/// Indicador de estado vacío
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkTextMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner de advertencia para contenido generado por IA
class AiBanner extends StatelessWidget {
  final String message;

  const AiBanner({
    super.key,
    this.message = 'Transcripción generada por IA — puede contener errores',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.warning.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
