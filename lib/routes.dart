import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/song_recognition/presentation/screens/home_screen.dart';
import 'features/song_recognition/presentation/screens/result_screen.dart';
import 'features/transcription/presentation/screens/transcription_screen.dart';
import 'features/practice_mode/presentation/screens/practice_screen.dart';

// ══════════════════════════════════════════════
// GoRouter — Navegación declarativa
// ══════════════════════════════════════════════

/// Provider del router para acceso global via Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // ─── Onboarding ───
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ─── Home / Reconocimiento ───
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ─── Resultado de canción ───
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) => const ResultScreen(),
      ),

      // ─── Transcripción / Letras IA ───
      GoRoute(
        path: '/transcription',
        name: 'transcription',
        builder: (context, state) => const TranscriptionScreen(),
      ),

      // ─── Modo Práctica ───
      GoRoute(
        path: '/practice',
        name: 'practice',
        builder: (context, state) => const PracticeScreen(),
      ),
    ],

    // ─── Error handler ───
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
