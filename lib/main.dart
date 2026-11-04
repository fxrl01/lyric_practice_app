import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/theme.dart';
import 'core/di/dependency_injection.dart';
import 'routes.dart';

/// Entry point de LyricFlow
/// 
/// Inicializa dependencias, carga configuración y lanza la app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (con fallback si no existe)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env file not found, using defaults');
    // Crear un .env vacío en memoria para que dotenv no falle
    dotenv.testLoad(fileInput: '''
APP_ENV=development
APP_DEBUG=true
''');
  }

  // Orientación preferida (no-op en web, ok)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ⚠️ IMPORTANTE: Inicializar AppConfig ANTES del DI
  // porque el DI usa AppConfig.instance para acceder a las API keys
  AppConfig.initialize(
    environment: dotenv.env['APP_ENV'] ?? 'development',
    isDebug: dotenv.env['APP_DEBUG'] == 'true',
  );

  // Inicializar Dependency Injection
  try {
    await configureDependencies();
  } catch (e) {
    debugPrint('⚠️ DI initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: LyricFlowApp(),
    ),
  );
}

/// Widget raíz de la aplicación
class LyricFlowApp extends ConsumerWidget {
  const LyricFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LyricFlow',
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router
      routerConfig: router,

      // Localización
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),

      // Builder para manejar errores globales de UI
      builder: (context, child) {
        // Prevenir escalado de texto del sistema
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
