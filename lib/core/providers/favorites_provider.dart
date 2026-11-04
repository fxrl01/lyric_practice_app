import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/song_recognition/domain/entities/song.dart';

/// ═══════════════════════════════════════════
/// Sistema de Favoritos
/// ═══════════════════════════════════════════

class FavoritesState {
  final List<Song> favorites;
  final bool isLoaded;

  const FavoritesState({
    this.favorites = const [],
    this.isLoaded = false,
  });

  bool isFavorite(String songId) =>
      favorites.any((s) => s.id == songId);

  int get count => favorites.length;

  FavoritesState copyWith({
    List<Song>? favorites,
    bool? isLoaded,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  static const _key = 'lyricflow_favorites';

  @override
  FavoritesState build() {
    _loadFavorites();
    return const FavoritesState();
  }

  /// Agregar a favoritos
  Future<void> addFavorite(Song song) async {
    if (state.isFavorite(song.id)) return;

    final updated = [...state.favorites, song];
    state = state.copyWith(favorites: updated);
    await _saveFavorites(updated);
  }

  /// Quitar de favoritos
  Future<void> removeFavorite(String songId) async {
    final updated = state.favorites
        .where((s) => s.id != songId)
        .toList();
    state = state.copyWith(favorites: updated);
    await _saveFavorites(updated);
  }

  /// Toggle favorito
  Future<void> toggleFavorite(Song song) async {
    if (state.isFavorite(song.id)) {
      await removeFavorite(song.id);
    } else {
      await addFavorite(song);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key) ?? [];
      final songs = jsonList
          .map((json) => _songFromJson(jsonDecode(json)))
          .whereType<Song>()
          .toList();
      state = state.copyWith(favorites: songs, isLoaded: true);
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _saveFavorites(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = songs
          .map((s) => jsonEncode(_songToJson(s)))
          .toList();
      await prefs.setStringList(_key, jsonList);
    } catch (_) {}
  }

  Map<String, dynamic> _songToJson(Song song) => {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'durationMs': song.durationMs,
        'genre': song.genre,
        'source': song.source,
      };

  Song? _songFromJson(Map<String, dynamic> json) {
    try {
      return Song(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        artist: json['artist'] ?? '',
        album: json['album'],
        durationMs: json['durationMs'],
        genre: json['genre'],
        source: json['source'] ?? 'cache',
      );
    } catch (_) {
      return null;
    }
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

/// ═══════════════════════════════════════════
/// Caché Offline
/// ═══════════════════════════════════════════

class OfflineCacheState {
  final List<Song> cachedSongs;
  final int cacheSize; // bytes aprox
  final bool isOnline;
  final DateTime? lastSync;

  const OfflineCacheState({
    this.cachedSongs = const [],
    this.cacheSize = 0,
    this.isOnline = true,
    this.lastSync,
  });

  int get cachedCount => cachedSongs.length;

  String get formattedCacheSize {
    if (cacheSize < 1024) return '$cacheSize B';
    if (cacheSize < 1024 * 1024) return '${(cacheSize / 1024).toStringAsFixed(1)} KB';
    return '${(cacheSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  OfflineCacheState copyWith({
    List<Song>? cachedSongs,
    int? cacheSize,
    bool? isOnline,
    DateTime? lastSync,
  }) {
    return OfflineCacheState(
      cachedSongs: cachedSongs ?? this.cachedSongs,
      cacheSize: cacheSize ?? this.cacheSize,
      isOnline: isOnline ?? this.isOnline,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class OfflineCacheNotifier extends Notifier<OfflineCacheState> {
  static const _key = 'lyricflow_offline_cache';
  static const _maxCacheItems = 20;

  @override
  OfflineCacheState build() {
    _loadCache();
    return const OfflineCacheState();
  }

  /// Agregar canción al caché offline
  Future<void> cacheSong(Song song) async {
    if (state.cachedSongs.any((s) => s.id == song.id)) return;

    var updated = [...state.cachedSongs, song];

    // Limitar tamaño del caché
    if (updated.length > _maxCacheItems) {
      updated = updated.sublist(updated.length - _maxCacheItems);
    }

    state = state.copyWith(
      cachedSongs: updated,
      lastSync: DateTime.now(),
      cacheSize: updated.length * 2048, // ~2KB por canción estimado
    );
    await _saveCache(updated);
  }

  /// Limpiar caché
  Future<void> clearCache() async {
    state = state.copyWith(
      cachedSongs: [],
      cacheSize: 0,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Actualizar estado de conectividad
  void setOnlineStatus(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key) ?? [];
      final songs = jsonList
          .map((json) => _songFromJson(jsonDecode(json)))
          .whereType<Song>()
          .toList();
      state = state.copyWith(
        cachedSongs: songs,
        cacheSize: songs.length * 2048,
      );
    } catch (_) {}
  }

  Future<void> _saveCache(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = songs
          .map((s) => jsonEncode({
                'id': s.id,
                'title': s.title,
                'artist': s.artist,
                'album': s.album,
                'durationMs': s.durationMs,
                'genre': s.genre,
                'source': s.source,
              }))
          .toList();
      await prefs.setStringList(_key, jsonList);
    } catch (_) {}
  }

  Song? _songFromJson(Map<String, dynamic> json) {
    try {
      return Song(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        artist: json['artist'] ?? '',
        album: json['album'],
        durationMs: json['durationMs'],
        genre: json['genre'],
        source: json['source'] ?? 'cache',
      );
    } catch (_) {
      return null;
    }
  }
}

final offlineCacheProvider =
    NotifierProvider<OfflineCacheNotifier, OfflineCacheState>(
  OfflineCacheNotifier.new,
);
