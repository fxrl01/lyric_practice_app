import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../services/speech_to_text_service.dart';
import '../services/translation_service.dart';

// ─── Song Recognition ───
import '../../features/song_recognition/domain/repositories/i_song_recognition_repository.dart';
import '../../features/song_recognition/domain/repositories/i_lyrics_repository.dart';
import '../../features/song_recognition/data/datasources/song_recognition_remote_datasource.dart';
import '../../features/song_recognition/data/datasources/song_recognition_local_datasource.dart';
import '../../features/song_recognition/data/datasources/lyrics_remote_datasource.dart';
import '../../features/song_recognition/data/repositories/song_recognition_repository_impl.dart';
import '../../features/song_recognition/data/repositories/lyrics_repository_impl.dart';

// ─── Transcription ───
import '../../features/transcription/domain/repositories/i_transcription_repository.dart';
import '../../features/transcription/data/datasources/transcription_datasources.dart';
import '../../features/transcription/data/repositories/transcription_repository_impl.dart';

// ─── Practice Mode ───
import '../../features/practice_mode/domain/repositories/i_practice_repository.dart';
import '../../features/practice_mode/data/datasources/practice_datasources.dart';
import '../../features/practice_mode/data/repositories/practice_repository_impl.dart';

// ─── Servicios Fase 2 ───
import '../services/speech_to_text_service.dart';
import '../services/translation_service.dart';

/// Service Locator global (GetIt)
final sl = GetIt.instance;

/// Configura todas las dependencias de la aplicación
///
/// Orden de registro:
/// 1. External (Logger, SharedPrefs, Dio)
/// 2. Data Sources (Remote + Local)
/// 3. Repositories (implementaciones concretas registradas contra interfaces)
///
/// Principio DIP: los consumers dependen de las interfaces
/// del dominio, nunca de las implementaciones concretas.
Future<void> configureDependencies() async {
  // ═════════════════════════════════════════
  // 1. EXTERNAL DEPENDENCIES
  // ═════════════════════════════════════════

  // Logger
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
      ),
      level: AppConfig.instance.isDebug ? Level.debug : Level.warning,
    ),
  );

  // Servicios Fase 2
  sl.registerLazySingleton<SpeechToTextService>(
    () => SpeechToTextService(
      apiKey: dotenv.env['GOOGLE_CLOUD_API_KEY'] ?? '',
    ),
  );

  sl.registerLazySingleton<SpeechToTextService>(
    () => SpeechToTextService(
      apiKey: dotenv.env['GOOGLE_CLOUD_API_KEY'] ?? '',
    ),
  );

  sl.registerLazySingleton<TranslationService>(
    () => TranslationService(
      apiKey: dotenv.env['GOOGLE_CLOUD_API_KEY'] ?? '',
    ),
  );

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Dio HTTP Client
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (AppConfig.instance.isDebug) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => sl<Logger>().d(obj.toString()),
        ),
      );
    }

    dio.interceptors.add(ErrorInterceptor());
    return dio;
  });

  // ApiClient genérico
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(dio: sl<Dio>(), logger: sl<Logger>()),
  );

  // ═════════════════════════════════════════
  // 2. DATA SOURCES
  // ═════════════════════════════════════════

  _registerSongRecognitionDataSources();
  _registerLyricsDataSources();
  _registerTranscriptionDataSources();
  _registerPracticeDataSources();

  // ═════════════════════════════════════════
  // 3. REPOSITORIES (interface → implementation)
  // ═════════════════════════════════════════

  _registerRepositories();

  sl<Logger>().i('✅ All dependencies configured successfully');
}

// ─── Song Recognition Data Sources ───
void _registerSongRecognitionDataSources() {
  // Remote: elegir provider según config
  sl.registerLazySingleton<SongRecognitionRemoteDataSource>(() {
    final config = AppConfig.instance;

    if (config.acrCloudAccessKey.isNotEmpty) {
      return AcrCloudRemoteDataSource(
        apiClient: sl<ApiClient>(),
        accessKey: config.acrCloudAccessKey,
        accessSecret: config.acrCloudAccessSecret,
        host: config.acrCloudHost,
      );
    }

    // Default: AudD (o modo demo si no hay key)
    return AuddRemoteDataSource(
      apiClient: sl<ApiClient>(),
      apiKey: config.auddApiKey,
    );
  });

  // Local
  sl.registerLazySingleton<SongRecognitionLocalDataSource>(
    () => SongRecognitionLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
}

// ─── Lyrics Data Sources ───
void _registerLyricsDataSources() {
  sl.registerLazySingleton<LyricsRemoteDataSource>(
    () => MusixmatchRemoteDataSource(
      apiClient: sl<ApiClient>(),
      apiKey: AppConfig.instance.musixmatchApiKey,
    ),
  );
}

// ─── Transcription Data Sources ───
void _registerTranscriptionDataSources() {
  sl.registerLazySingleton<TranscriptionRemoteDataSource>(
    () => WhisperRemoteDataSource(
      apiClient: sl<ApiClient>(),
      apiKey: AppConfig.instance.openAiApiKey,
    ),
  );

  sl.registerLazySingleton<TranscriptionLocalDataSource>(
    () => TranscriptionLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
}

// ─── Practice Data Sources ───
void _registerPracticeDataSources() {
  sl.registerLazySingleton<PracticeRemoteDataSource>(
    () => PracticeRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<PracticeLocalDataSource>(
    () => PracticeLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
}

// ─── Repositories ───
void _registerRepositories() {
  // ISongRecognitionRepository → SongRecognitionRepositoryImpl
  sl.registerLazySingleton<ISongRecognitionRepository>(
    () => SongRecognitionRepositoryImpl(
      remoteDataSource: sl<SongRecognitionRemoteDataSource>(),
      localDataSource: sl<SongRecognitionLocalDataSource>(),
      logger: sl<Logger>(),
    ),
  );

  // ILyricsRepository → LyricsRepositoryImpl
  sl.registerLazySingleton<ILyricsRepository>(
    () => LyricsRepositoryImpl(
      remoteDataSource: sl<LyricsRemoteDataSource>(),
      logger: sl<Logger>(),
    ),
  );

  // ITranscriptionRepository → TranscriptionRepositoryImpl
  sl.registerLazySingleton<ITranscriptionRepository>(
    () => TranscriptionRepositoryImpl(
      remoteDataSource: sl<TranscriptionRemoteDataSource>(),
      localDataSource: sl<TranscriptionLocalDataSource>(),
      logger: sl<Logger>(),
    ),
  );

  // IPracticeRepository → PracticeRepositoryImpl
  sl.registerLazySingleton<IPracticeRepository>(
    () => PracticeRepositoryImpl(
      remoteDataSource: sl<PracticeRemoteDataSource>(),
      localDataSource: sl<PracticeLocalDataSource>(),
      logger: sl<Logger>(),
    ),
  );
}

/// Interceptor personalizado para manejo de errores HTTP
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final logger = sl<Logger>();

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        logger.w('⏱️ Connection timeout: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.receiveTimeout:
        logger.w('⏱️ Receive timeout: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.badResponse:
        logger.e('❌ Bad response [${err.response?.statusCode}]: ${err.requestOptions.uri}');
        break;
      case DioExceptionType.cancel:
        logger.w('🚫 Request cancelled: ${err.requestOptions.uri}');
        break;
      default:
        logger.e('🔥 Network error: ${err.message}');
    }

    handler.next(err);
  }
}
