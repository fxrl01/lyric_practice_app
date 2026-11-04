import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme.dart';
import '../../../song_recognition/domain/entities/lyrics.dart';

/// Editor inline de letras para corrección manual
///
/// Permite al usuario corregir errores en transcripciones de IA
/// y letras de APIs. Los cambios se mantienen solo en sesión.
class LyricsEditor extends ConsumerStatefulWidget {
  /// Letras originales
  final Lyrics lyrics;

  /// Callback cuando se guardan cambios
  final void Function(Lyrics updatedLyrics) onSave;

  /// Callback al cancelar
  final VoidCallback onCancel;

  const LyricsEditor({
    super.key,
    required this.lyrics,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<LyricsEditor> createState() => _LyricsEditorState();
}

class _LyricsEditorState extends ConsumerState<LyricsEditor> {
  late List<TextEditingController> _controllers;
  bool _hasChanges = false;
  int _editedCount = 0;

  @override
  void initState() {
    super.initState();
    _controllers = widget.lyrics.lines
        .map((line) => TextEditingController(text: line.text))
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      final originalText = widget.lyrics.lines[i].text;
      _controllers[i].addListener(() {
        final changed = _controllers[i].text != originalText;
        setState(() {
          _hasChanges = _controllers.any(
            (c) => c.text !=
                widget.lyrics.lines[_controllers.indexOf(c)].text,
          );
          _editedCount = _controllers
              .where((c) => c.text !=
                  widget.lyrics.lines[_controllers.indexOf(c)].text)
              .length;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updatedLines = <LyricLine>[];
    for (int i = 0; i < _controllers.length; i++) {
      updatedLines.add(widget.lyrics.lines[i].copyWith(
        text: _controllers[i].text,
      ));
    }

    widget.onSave(widget.lyrics.copyWith(lines: updatedLines));
  }

  void _revertLine(int index) {
    _controllers[index].text = widget.lyrics.lines[index].text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Toolbar ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            border: Border(
              bottom: BorderSide(
                color: AppColors.darkBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              // Icono edit
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.warning.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),

              // Título + contador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Edición',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_hasChanges)
                      Text(
                        '$_editedCount línea${_editedCount != 1 ? 's' : ''} modificada${_editedCount != 1 ? 's' : ''}',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),

              // Cancelar
              TextButton(
                onPressed: widget.onCancel,
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),

              // Guardar
              FilledButton.icon(
                onPressed: _hasChanges ? _save : null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.darkCard,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        ),

        // ─── Editor de líneas ───
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _controllers.length,
            itemBuilder: (context, index) {
              final line = widget.lyrics.lines[index];
              final isModified =
                  _controllers[index].text != line.text;

              if (line.text.isEmpty) {
                return const SizedBox(height: 16);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número de línea
                    SizedBox(
                      width: 32,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isModified
                                ? AppColors.warning
                                : AppColors.darkTextMuted.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Campo de texto editable
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isModified
                                ? AppColors.warning.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                          color: isModified
                              ? AppColors.warning.withValues(alpha: 0.05)
                              : null,
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          style: context.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            fontWeight:
                                isModified ? FontWeight.w500 : null,
                          ),
                          maxLines: null,
                          decoration: InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            hintText: 'Línea vacía...',
                            hintStyle: TextStyle(
                              color: AppColors.darkTextMuted.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botón revertir (solo si modificado)
                    if (isModified)
                      IconButton(
                        onPressed: () => _revertLine(index),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        tooltip: 'Revertir',
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.darkTextMuted,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // ─── Footer info ───
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkElevated.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(
                color: AppColors.darkBorder.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.darkTextMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Los cambios solo se aplican en esta sesión y no se guardan en el servidor.',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
