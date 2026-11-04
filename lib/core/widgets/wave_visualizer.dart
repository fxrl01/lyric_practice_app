import 'dart:math';
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Visualizador de ondas de audio animado
///
/// Muestra barras verticales que simulan una onda de audio
/// reactiva a la amplitud del micrófono.
class WaveVisualizer extends StatefulWidget {
  /// Amplitud normalizada (0.0 - 1.0)
  final double amplitude;

  /// ¿Está activo?
  final bool isActive;

  /// Cantidad de barras
  final int barCount;

  /// Color de las barras
  final Color? color;

  /// Altura máxima
  final double maxHeight;

  const WaveVisualizer({
    super.key,
    this.amplitude = 0.5,
    this.isActive = true,
    this.barCount = 40,
    this.color,
    this.maxHeight = 80,
  });

  @override
  State<WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<WaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  List<double> _barHeights = [];

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(widget.barCount, (_) => 0.1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(_updateBars);

    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      // Animate bars to zero
      setState(() {
        _barHeights = List.generate(widget.barCount, (_) => 0.05);
      });
    }
  }

  void _updateBars() {
    if (!widget.isActive) return;

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        // Generar alturas con patrón wave-like
        final baseHeight = widget.amplitude * 0.6;
        final wave = sin((i / widget.barCount) * pi * 2 +
                DateTime.now().millisecondsSinceEpoch / 200) *
            0.3;
        final noise = _random.nextDouble() * 0.2 * widget.amplitude;
        _barHeights[i] = (baseHeight + wave * widget.amplitude + noise)
            .clamp(0.05, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ?? AppColors.primary;

    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final height = _barHeights[index] * widget.maxHeight;
          final centerDistance =
              (index - widget.barCount / 2).abs() / (widget.barCount / 2);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOut,
            width: 3,
            height: height.clamp(2.0, widget.maxHeight),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  barColor.withValues(alpha: 0.5 + centerDistance * 0.3),
                  barColor,
                  AppColors.accent.withValues(alpha: 0.8),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Indicador circular de progreso con gradiente
class GradientProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Widget? child;

  const GradientProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 4,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: AppColors.darkBorder.withValues(alpha: 0.3),
            ),
          ),
          // Progress
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                color: Colors.white,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
