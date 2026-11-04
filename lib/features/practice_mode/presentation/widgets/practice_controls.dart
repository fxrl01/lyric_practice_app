import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/theme.dart';

/// Widget de metrónomo visual y auditivo sincronizado
class MetronomeWidget extends StatefulWidget {
  /// BPM del metrónomo
  final int bpm;

  /// ¿Está activo?
  final bool isActive;

  /// Compás (beats por compás)
  final int beatsPerMeasure;

  /// Callback cuando cambia BPM
  final void Function(int bpm)? onBpmChanged;

  /// Callback al activar/desactivar
  final void Function(bool active)? onToggle;

  const MetronomeWidget({
    super.key,
    this.bpm = 120,
    this.isActive = false,
    this.beatsPerMeasure = 4,
    this.onBpmChanged,
    this.onToggle,
  });

  @override
  State<MetronomeWidget> createState() => _MetronomeWidgetState();
}

class _MetronomeWidgetState extends State<MetronomeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _beatController;
  int _currentBeat = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    if (widget.isActive) _startMetronome();
  }

  @override
  void didUpdateWidget(MetronomeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      widget.isActive ? _startMetronome() : _stopMetronome();
    }
    if (widget.bpm != oldWidget.bpm && widget.isActive) {
      _stopMetronome();
      _startMetronome();
    }
  }

  void _startMetronome() {
    final interval = Duration(milliseconds: (60000 / widget.bpm).round());
    _timer = Timer.periodic(interval, (_) {
      setState(() {
        _currentBeat = (_currentBeat + 1) % widget.beatsPerMeasure;
      });
      _beatController.forward(from: 0);

      // Haptic feedback en el downbeat
      if (_currentBeat == 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _stopMetronome() {
    _timer?.cancel();
    _timer = null;
    setState(() => _currentBeat = 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _beatController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: widget.isActive && _beatController.value > 0
                          ? AppColors.warning.withValues(
                              alpha: 0.3 * (1 - _beatController.value))
                          : Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Icon(
                      Icons.timer_rounded,
                      size: 18,
                      color: widget.isActive
                          ? AppColors.warning
                          : AppColors.darkTextMuted,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                'Metrónomo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              // On/Off toggle
              GestureDetector(
                onTap: () => widget.onToggle?.call(!widget.isActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: widget.isActive
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: widget.isActive
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    widget.isActive ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.isActive
                          ? AppColors.warning
                          : AppColors.darkTextMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Beat indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.beatsPerMeasure, (i) {
              final isCurrentBeat = i == _currentBeat && widget.isActive;
              final isDownbeat = i == 0;

              return AnimatedBuilder(
                animation: _beatController,
                builder: (context, child) {
                  final scale = isCurrentBeat
                      ? 1.0 + 0.3 * (1 - _beatController.value)
                      : 1.0;

                  return Transform.scale(
                    scale: scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: isDownbeat ? 20 : 14,
                      height: isDownbeat ? 20 : 14,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentBeat
                            ? (isDownbeat
                                ? AppColors.warning
                                : AppColors.primaryLight)
                            : AppColors.darkBorder.withValues(alpha: 0.4),
                        boxShadow: isCurrentBeat
                            ? [
                                BoxShadow(
                                  color: (isDownbeat
                                          ? AppColors.warning
                                          : AppColors.primary)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 16),

          // BPM control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease
              IconButton(
                onPressed: widget.bpm > 40
                    ? () => widget.onBpmChanged?.call(widget.bpm - 5)
                    : null,
                icon: const Icon(Icons.remove_rounded),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.darkElevated,
                  foregroundColor: AppColors.darkTextSecondary,
                ),
              ),

              // BPM display
              GestureDetector(
                onTap: () => _showBpmPicker(context),
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.bpm}',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkTextPrimary,
                                  ),
                        ),
                        const TextSpan(
                          text: ' bpm',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Increase
              IconButton(
                onPressed: widget.bpm < 240
                    ? () => widget.onBpmChanged?.call(widget.bpm + 5)
                    : null,
                icon: const Icon(Icons.add_rounded),
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.darkElevated,
                  foregroundColor: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBpmPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int tempBpm = widget.bpm;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajustar BPM'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$tempBpm',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Slider(
                    value: tempBpm.toDouble(),
                    min: 40,
                    max: 240,
                    divisions: 40,
                    onChanged: (v) {
                      setDialogState(() => tempBpm = v.toInt());
                    },
                  ),
                  // Presets
                  Wrap(
                    spacing: 8,
                    children: [60, 80, 100, 120, 140, 160].map((bpm) {
                      return ActionChip(
                        label: Text('$bpm'),
                        onPressed: () {
                          setDialogState(() => tempBpm = bpm);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onBpmChanged?.call(tempBpm);
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Control de velocidad de reproducción
class SpeedControl extends StatelessWidget {
  final double speed;
  final void Function(double speed)? onSpeedChanged;

  const SpeedControl({
    super.key,
    this.speed = 1.0,
    this.onSpeedChanged,
  });

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded,
                  size: 16, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Velocidad',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${speed}x',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: speed != 1.0
                          ? AppColors.primaryLight
                          : AppColors.darkTextPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _presets.map((preset) {
              final isActive = (speed - preset).abs() < 0.01;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSpeedChanged?.call(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${preset}x',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primaryLight
                            : AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
