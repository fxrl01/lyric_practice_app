import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/theme.dart';
import '../../../song_recognition/domain/entities/lyrics.dart';
import '../../../song_recognition/domain/usecases/translate_lyrics_usecase.dart';
import '../../../../core/providers/app_providers.dart';

/// Estado de traducción
class TranslationState {
  final bool isLoading;
  final String? targetLanguage;
  final Map<int, String> translations; // lineIndex → translated text
  final String? errorMessage;

  const TranslationState({
    this.isLoading = false,
    this.targetLanguage,
    this.translations = const {},
    this.errorMessage,
  });

  bool get hasTranslations => translations.isNotEmpty;

  TranslationState copyWith({
    bool? isLoading,
    String? targetLanguage,
    Map<int, String>? translations,
    String? errorMessage,
  }) {
    return TranslationState(
      isLoading: isLoading ?? this.isLoading,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translations: translations ?? this.translations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider de traducción local
class TranslationNotifier extends Notifier<TranslationState> {
  @override
  TranslationState build() => const TranslationState();

  /// Traducir letras completas
  Future<void> translateLyrics({
    required Lyrics lyrics,
    required String targetLanguage,
  }) async {
    state = state.copyWith(
      isLoading: true,
      targetLanguage: targetLanguage,
      errorMessage: null,
    );

    final useCase = ref.read(translateLyricsUseCaseProvider);
    final result = await useCase(TranslateLyricsParams(
      lyrics: lyrics,
      targetLanguage: targetLanguage,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (translatedLyrics) {
        final translations = <int, String>{};
        for (int i = 0; i < translatedLyrics.lines.length; i++) {
          translations[i] = translatedLyrics.lines[i].text;
        }
        state = state.copyWith(
          isLoading: false,
          translations: translations,
        );
      },
    );
  }

  /// Limpiar traducciones
  void clear() {
    state = const TranslationState();
  }
}

final translationProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
  TranslationNotifier.new,
);

/// Panel de traducción para la vista de letras
class TranslationPanel extends ConsumerWidget {
  final Lyrics lyrics;
  final String currentLanguage;

  const TranslationPanel({
    super.key,
    required this.lyrics,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider);

    final supportedLanguages = [
      ('es', '🇪🇸', 'Español'),
      ('en', '🇺🇸', 'English'),
      ('pt', '🇧🇷', 'Português'),
      ('fr', '🇫🇷', 'Français'),
      ('de', '🇩🇪', 'Deutsch'),
      ('it', '🇮🇹', 'Italiano'),
      ('ja', '🇯🇵', '日本語'),
      ('ko', '🇰🇷', '한국어'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.translate_rounded,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              Text(
                'Traducir',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (translationState.hasTranslations)
                TextButton.icon(
                  onPressed: () {
                    ref.read(translationProvider.notifier).clear();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkTextMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Idioma original
          Row(
            children: [
              Text(
                'Original: ',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.darkTextMuted,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Text(
                  currentLanguage.toUpperCase(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Selector de idiomas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supportedLanguages
                .where((l) => l.$1 != currentLanguage)
                .map((lang) {
              final isSelected =
                  translationState.targetLanguage == lang.$1;
              final isLoading =
                  translationState.isLoading && isSelected;

              return GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        ref.read(translationProvider.notifier).translateLyrics(
                              lyrics: lyrics,
                              targetLanguage: lang.$1,
                            );
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        lang.$3,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.darkTextSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (isLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Error message
          if (translationState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      translationState.errorMessage!,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
