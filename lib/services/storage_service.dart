import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/movie_model.dart';
import '../utils/constants.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ==================== Settings Keys ====================
  static const String _keyVideoQuality = 'setting_video_quality';
  static const String _keySubtitleLang = 'setting_subtitle_lang';
  static const String _keyAutoPlayNext = 'setting_auto_play_next';
  static const String _keyNotifyNewMovies = 'setting_notify_new_movies';
  static const String _keyNotifyNewEpisodes = 'setting_notify_new_episodes';
  static const String _keyApiSourceIndex = 'setting_api_source_index';
  static const String _keyPlayerSourceIndex = 'setting_player_source_index';

  // ==================== Settings Defaults & Accessors ====================

  /// Video quality: 'auto', '1080p', '720p', '480p'
  String get videoQuality => _prefs.getString(_keyVideoQuality) ?? 'auto';
  Future<void> setVideoQuality(String quality) async =>
      await _prefs.setString(_keyVideoQuality, quality);

  /// Subtitle language
  String get subtitleLang => _prefs.getString(_keySubtitleLang) ?? 'ar';
  Future<void> setSubtitleLang(String lang) async =>
      await _prefs.setString(_keySubtitleLang, lang);

  /// Auto-play next episode
  bool get autoPlayNext => _prefs.getBool(_keyAutoPlayNext) ?? true;
  Future<void> setAutoPlayNext(bool value) async =>
      await _prefs.setBool(_keyAutoPlayNext, value);

  /// Notify on new movies
  bool get notifyNewMovies => _prefs.getBool(_keyNotifyNewMovies) ?? true;
  Future<void> setNotifyNewMovies(bool value) async =>
      await _prefs.setBool(_keyNotifyNewMovies, value);

  /// Notify on new episodes
  bool get notifyNewEpisodes => _prefs.getBool(_keyNotifyNewEpisodes) ?? true;
  Future<void> setNotifyNewEpisodes(bool value) async =>
      await _prefs.setBool(_keyNotifyNewEpisodes, value);

  /// Active API source index
  int get apiSourceIndex => _prefs.getInt(_keyApiSourceIndex) ?? 0;
  Future<void> setApiSourceIndex(int index) async =>
      await _prefs.setInt(_keyApiSourceIndex, index);

  /// Active player source index
  int get playerSourceIndex => _prefs.getInt(_keyPlayerSourceIndex) ?? 0;
  Future<void> setPlayerSourceIndex(int index) async =>
      await _prefs.setInt(_keyPlayerSourceIndex, index);

  // ==================== Watch History ====================

  /// Save watch history with position, season, and episode
  Future<void> saveWatchHistory({
    required Movie movie,
    required int position,
    int season = 1,
    int episode = 1,
  }) async {
    final key = 'watch_${movie.imdbId ?? movie.id}';
    final data = {
      'movie': movie.toJson(),
      'position': position,
      'season': season,
      'episode': episode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString(key, jsonEncode(data));
  }

  /// Get watch history for a specific movie
  Map<String, dynamic>? getWatchHistory(String movieId) {
    final key = 'watch_$movieId';
    final data = _prefs.getString(key);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  /// Get all watch history
  List<Map<String, dynamic>> getAllWatchHistory() {
    final keys = _prefs.getKeys().where((k) => k.startsWith('watch_'));
    return keys.map((key) {
      final data = _prefs.getString(key);
      return data != null ? jsonDecode(data) as Map<String, dynamic> : {};
    }).where((item) => item.isNotEmpty).toList()
      ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
  }

  /// Clear watch history
  Future<void> clearWatchHistory(String movieId) async {
    final key = 'watch_$movieId';
    await _prefs.remove(key);
  }

  // ==================== Favorites / Watchlist ====================

  /// Save favorite movie
  Future<void> saveFavorite(Movie movie) async {
    final favorites = getFavorites();
    if (!favorites.any((m) => (m.imdbId ?? m.id) == (movie.imdbId ?? movie.id))) {
      favorites.add(movie);
      await _prefs.setString(
        AppConstants.favoritesKey,
        jsonEncode(favorites.map((m) => m.toJson()).toList()),
      );
    }
  }

  /// Remove favorite movie
  Future<void> removeFavorite(String movieId) async {
    final favorites = getFavorites();
    favorites.removeWhere((m) => (m.imdbId ?? m.id) == movieId);
    await _prefs.setString(
      AppConstants.favoritesKey,
      jsonEncode(favorites.map((m) => m.toJson()).toList()),
    );
  }

  /// Get all favorites
  List<Movie> getFavorites() {
    final data = _prefs.getString(AppConstants.favoritesKey);
    if (data == null) return [];

    try {
      final list = jsonDecode(data) as List;
      return list.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if movie is favorite
  bool isFavorite(String movieId) {
    return getFavorites().any((m) => (m.imdbId ?? m.id) == movieId);
  }

  // ==================== Downloads ====================

  /// Save download info
  Future<void> saveDownload(Movie movie, String localPath) async {
    final downloads = getDownloads();
    downloads.add({'movie': movie.toJson(), 'localPath': localPath});
    await _prefs.setString(
      'downloads',
      jsonEncode(downloads),
    );
  }

  /// Get all downloads
  List<Map<String, dynamic>> getDownloads() {
    final data = _prefs.getString('downloads');
    if (data == null) return [];

    try {
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Remove download
  Future<void> removeDownload(String movieId) async {
    final downloads = getDownloads();
    downloads.removeWhere((d) {
      final movie = Movie.fromJson(d['movie'] as Map<String, dynamic>);
      return (movie.imdbId ?? movie.id) == movieId;
    });
    await _prefs.setString('downloads', jsonEncode(downloads));
  }

  // ==================== Generic Key-Value Storage ====================

  Future<void> setString(String key, String value) async => await _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<void> setInt(String key, int value) async => await _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setBool(String key, bool value) async => await _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  /// Check if onboarding is done
  bool get isOnboardingDone => _prefs.getBool(AppConstants.onboardingKey) ?? false;

  /// Set onboarding done
  Future<void> setOnboardingDone() async {
    await _prefs.setBool(AppConstants.onboardingKey, true);
  }

  /// Clear all data
  Future<void> clearAll() async => await _prefs.clear();
}
