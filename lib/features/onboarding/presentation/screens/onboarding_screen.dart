import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/services/haptic_service.dart';

/// Provider para controlar si ya se vio el onboarding
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

/// Verifica si el usuario ya completó el onboarding
Future<bool> checkOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('lyricflow_onboarding_complete') ?? false;
}

/// Pantalla de onboarding con pages animadas
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.mic_rounded,
      iconColor: Color(0xFF7C3AED),
      bgGradient: [Color(0xFF1E1145), Color(0xFF0A0A14)],
      title: 'Reconoce Canciones',
      subtitle: 'Toca el botón y deja que la IA\n'
          'identifique cualquier canción\n'
          'en segundos.',
      emoji: '🎵',
    ),
    _OnboardingPage(
      icon: Icons.lyrics_rounded,
      iconColor: Color(0xFFEC4899),
      bgGradient: [Color(0xFF3D1131), Color(0xFF0A0A14)],
      title: 'Letras Sincronizadas',
      subtitle: 'Obtén letras en tiempo real\n'
          'con vista karaoke. Si no hay,\n'
          'la IA las transcribe por ti.',
      emoji: '📝',
    ),
    _OnboardingPage(
      icon: Icons.translate_rounded,
      iconColor: Color(0xFF3B82F6),
      bgGradient: [Color(0xFF0F1A3D), Color(0xFF0A0A14)],
      title: 'Traduce y Aprende',
      subtitle: 'Traduce letras a 8 idiomas.\n'
          'Aprende vocabulario nuevo\n'
          'con tu música favorita.',
      emoji: '🌎',
    ),
    _OnboardingPage(
      icon: Icons.piano_rounded,
      iconColor: Color(0xFF22C55E),
      bgGradient: [Color(0xFF0A2E1A), Color(0xFF0A0A14)],
      title: 'Modo Práctica',
      subtitle: 'Separa instrumentos, visualiza\n'
          'notas en piano roll, ajusta\n'
          'velocidad y practica con metrónomo.',
      emoji: '🎹',
    ),
  ];

  void _nextPage() {
    HapticService.lightTap();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    HapticService.success();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyricflow_onboarding_complete', true);
    ref.read(onboardingCompleteProvider.notifier).state = true;

    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              HapticService.selection();
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(context, _pages[index], index);
            },
          ),

          // Skip button (top right)
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Saltar',
                  style: TextStyle(
                    color: AppColors.darkTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                32,
                24,
                32,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? _pages[_currentPage].iconColor
                              : AppColors.darkBorder,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Next/Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            _pages[_currentPage].iconColor,
                            _pages[_currentPage].iconColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _pages[_currentPage]
                                .iconColor
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? '¡Empezar! 🚀'
                                  : 'Siguiente',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPage page, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: page.bgGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Emoji grande
              Text(
                page.emoji,
                style: const TextStyle(fontSize: 64),
              )
                  .animate(
                    delay: 200.ms,
                    key: ValueKey('emoji_$index'),
                  )
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 24),

              // Icono en círculo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.iconColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: page.iconColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  page.icon,
                  size: 36,
                  color: page.iconColor,
                ),
              )
                  .animate(
                    delay: 400.ms,
                    key: ValueKey('icon_$index'),
                  )
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 40),

              // Título
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate(
                    delay: 500.ms,
                    key: ValueKey('title_$index'),
                  )
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15),

              const SizedBox(height: 16),

              // Subtítulo
              Text(
                page.subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.darkTextSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate(
                    delay: 600.ms,
                    key: ValueKey('sub_$index'),
                  )
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class para una página de onboarding
class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final List<Color> bgGradient;
  final String title;
  final String subtitle;
  final String emoji;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });
}
