import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Vista estilo karaoke con highlight de la línea activa
///
/// Muestra las letras sincronizadas con el audio,
/// resaltando la línea que se está reproduciendo.
class KaraokeView extends StatefulWidget {
  /// Líneas de texto a mostrar
  final List<KaraokeLine> lines;

  /// Posición actual del audio en milisegundos
  final int currentPositionMs;

  /// ¿Está reproduciendo?
  final bool isPlaying;

  /// Callback cuando se toca una línea
  final void Function(int index, int timestampMs)? onLineTap;

  /// ¿Mostrar timestamps?
  final bool showTimestamps;

  /// ¿Auto-scroll al seguir la línea activa?
  final bool autoScroll;

  /// Altura del contenedor
  final double? height;

  const KaraokeView({
    super.key,
    required this.lines,
    this.currentPositionMs = 0,
    this.isPlaying = false,
    this.onLineTap,
    this.showTimestamps = true,
    this.autoScroll = true,
    this.height,
  });

  @override
  State<KaraokeView> createState() => _KaraokeViewState();
}

class _KaraokeViewState extends State<KaraokeView> {
  final ScrollController _scrollController = ScrollController();
  int _activeLineIndex = -1;

  @override
  void didUpdateWidget(KaraokeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPositionMs != oldWidget.currentPositionMs) {
      _updateActiveLine();
    }
  }

  void _updateActiveLine() {
    final newIndex = _findActiveLine(widget.currentPositionMs);
    if (newIndex != _activeLineIndex) {
      setState(() => _activeLineIndex = newIndex);
      if (widget.autoScroll && newIndex >= 0) {
        _scrollToLine(newIndex);
      }
    }
  }

  int _findActiveLine(int positionMs) {
    for (int i = widget.lines.length - 1; i >= 0; i--) {
      final line = widget.lines[i];
      if (line.startTimeMs != null && line.startTimeMs! <= positionMs) {
        return i;
      }
    }
    return -1;
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    final targetOffset = (index * 56.0) - 120; // Centrar la línea activa
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        itemCount: widget.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lines[index];
          final isActive = index == _activeLineIndex;
          final isPast = _activeLineIndex >= 0 && index < _activeLineIndex;
          final isFuture = _activeLineIndex >= 0 && index > _activeLineIndex;

          if (line.text.isEmpty) {
            return const SizedBox(height: 24);
          }

          return GestureDetector(
            onTap: () {
              if (widget.onLineTap != null && line.startTimeMs != null) {
                widget.onLineTap!(index, line.startTimeMs!);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                vertical: isActive ? 12 : 8,
                horizontal: isActive ? 16 : 8,
              ),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timestamp
                  if (widget.showTimestamps && line.startTimeMs != null)
                    SizedBox(
                      width: 48,
                      child: Text(
                        _formatTimestamp(line.startTimeMs!),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isActive
                              ? AppColors.primaryLight
                              : AppColors.darkTextMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                  // Indicador de línea activa
                  if (isActive)
                    Container(
                      width: 3,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: AppColors.primaryGradient,
                      ),
                    ),

                  // Texto
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: isActive ? 18 : 16,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive
                            ? Colors.white
                            : isPast
                                ? AppColors.darkTextMuted
                                : isFuture
                                    ? AppColors.darkTextSecondary
                                    : AppColors.darkTextPrimary,
                        height: 1.5,
                      ),
                      child: Text(line.text),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Línea de karaoke con metadata
class KaraokeLine {
  final String text;
  final int? startTimeMs;
  final int? endTimeMs;
  final bool isChorus;
  final String? translation;

  const KaraokeLine({
    required this.text,
    this.startTimeMs,
    this.endTimeMs,
    this.isChorus = false,
    this.translation,
  });
}
