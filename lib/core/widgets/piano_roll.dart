import 'dart:math';
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Visualización de Piano Roll en tiempo real
///
/// Muestra notas MIDI como bloques horizontales en una cuadrícula
/// estilo DAW (Digital Audio Workstation).
class PianoRoll extends StatefulWidget {
  /// Notas a visualizar
  final List<PianoRollNote> notes;

  /// Posición actual en milisegundos
  final int currentPositionMs;

  /// Ventana de tiempo visible (ms)
  final int visibleRangeMs;

  /// Rango de notas MIDI a mostrar (min-max)
  final int minNote;
  final int maxNote;

  /// ¿Auto-scroll?
  final bool autoScroll;

  /// Altura del widget
  final double height;

  /// Callback al tocar una nota
  final void Function(PianoRollNote note)? onNoteTap;

  const PianoRoll({
    super.key,
    required this.notes,
    this.currentPositionMs = 0,
    this.visibleRangeMs = 8000,
    this.minNote = 36, // C2
    this.maxNote = 84, // C6
    this.autoScroll = true,
    this.height = 250,
    this.onNoteTap,
  });

  @override
  State<PianoRoll> createState() => _PianoRollState();
}

class _PianoRollState extends State<PianoRoll> {
  final ScrollController _horizontalScroll = ScrollController();

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  @override
  void didUpdateWidget(PianoRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll &&
        widget.currentPositionMs != oldWidget.currentPositionMs) {
      _scrollToPosition();
    }
  }

  void _scrollToPosition() {
    if (!_horizontalScroll.hasClients) return;
    const pixelsPerMs = 0.15;
    final targetScroll = widget.currentPositionMs * pixelsPerMs - 100;
    _horizontalScroll.animateTo(
      targetScroll.clamp(0.0, _horizontalScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteRange = widget.maxNote - widget.minNote;
    final noteHeight = widget.height / noteRange;
    final totalWidthMs = widget.notes.isEmpty
        ? widget.visibleRangeMs
        : widget.notes.map((n) => n.endMs).reduce(max) + 2000;
    const pixelsPerMs = 0.15;
    final totalWidth = totalWidthMs * pixelsPerMs;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Piano keys (etiquetas)
            _buildPianoKeys(noteRange, noteHeight),

            // Notas (scrollable)
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalWidth,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _PianoRollPainter(
                      notes: widget.notes,
                      currentPositionMs: widget.currentPositionMs,
                      minNote: widget.minNote,
                      maxNote: widget.maxNote,
                      pixelsPerMs: pixelsPerMs,
                      noteHeight: noteHeight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPianoKeys(int noteRange, double noteHeight) {
    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        border: Border(
          right: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: List.generate(noteRange, (i) {
          final noteIndex = widget.maxNote - i - 1;
          final noteName = _noteNames[noteIndex % 12];
          final octave = noteIndex ~/ 12 - 1;
          final isBlack = noteName.contains('#');

          return Container(
            height: noteHeight,
            alignment: Alignment.center,
            color: isBlack
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.transparent,
            child: noteIndex % 12 == 0
                ? Text(
                    'C$octave',
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.darkTextMuted,
                      fontFamily: 'monospace',
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  final List<PianoRollNote> notes;
  final int currentPositionMs;
  final int minNote;
  final int maxNote;
  final double pixelsPerMs;
  final double noteHeight;

  _PianoRollPainter({
    required this.notes,
    required this.currentPositionMs,
    required this.minNote,
    required this.maxNote,
    required this.pixelsPerMs,
    required this.noteHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final noteRange = maxNote - minNote;

    // Grid lines (horizontales)
    final gridPaint = Paint()
      ..color = AppColors.darkBorder.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i < noteRange; i++) {
      final y = i * noteHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Resaltar líneas de C (octavas)
      if ((maxNote - i - 1) % 12 == 0) {
        final octavePaint = Paint()
          ..color = AppColors.darkBorder.withValues(alpha: 0.4)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), octavePaint);
      }
    }

    // Grid lines (verticales - cada beat ~500ms)
    for (double x = 0; x < size.width; x += 500 * pixelsPerMs) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Notas
    for (final note in notes) {
      final x = note.startMs * pixelsPerMs;
      final w = (note.endMs - note.startMs) * pixelsPerMs;
      final noteIndex = maxNote - note.midiNote - 1;
      final y = noteIndex * noteHeight;

      if (y < 0 || y > size.height) continue;

      final isActive = currentPositionMs >= note.startMs &&
          currentPositionMs <= note.endMs;

      // Nota rect
      final noteRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 1, w.clamp(2, double.infinity), noteHeight - 2),
        const Radius.circular(3),
      );

      // Color basado en velocidad y estado
      final baseColor = _noteColor(note.midiNote);
      final notePaint = Paint()
        ..color = isActive
            ? baseColor
            : baseColor.withValues(alpha: 0.6 + note.velocity * 0.4);

      canvas.drawRRect(noteRect, notePaint);

      // Borde sutil
      if (isActive) {
        final borderPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(noteRect, borderPaint);
      }
    }

    // Playhead (línea vertical roja)
    final playheadX = currentPositionMs * pixelsPerMs;
    final playheadPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);

    // Glow del playhead
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.15)
      ..strokeWidth = 8;
    canvas.drawLine(
        Offset(playheadX, 0), Offset(playheadX, size.height), glowPaint);
  }

  Color _noteColor(int midiNote) {
    // Colores por instrumento/rango
    if (midiNote < 48) return AppColors.accent; // Bajo
    if (midiNote < 60) return AppColors.primary; // Medio
    if (midiNote < 72) return AppColors.success; // Alto
    return AppColors.warning; // Muy alto
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter oldDelegate) {
    return currentPositionMs != oldDelegate.currentPositionMs ||
        notes.length != oldDelegate.notes.length;
  }
}

/// Nota individual en el piano roll
class PianoRollNote {
  final int midiNote; // 0-127
  final int startMs;
  final int endMs;
  final double velocity; // 0.0-1.0
  final String? label;

  const PianoRollNote({
    required this.midiNote,
    required this.startMs,
    required this.endMs,
    this.velocity = 0.8,
    this.label,
  });

  int get durationMs => endMs - startMs;

  String get noteName {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return '${names[midiNote % 12]}${midiNote ~/ 12 - 1}';
  }
}
