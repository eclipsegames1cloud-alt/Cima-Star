import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/constants.dart';
import '../models/movie_model.dart';

/// Cache Service for API responses using GetStorage with offline support
class CacheService extends GetxService {
  late final GetStorage _box;
  late final GetStorage _moviesBox;
  late final GetStorage _watchProgressBox;

  Future<CacheService> init() async {
    await GetStorage.init('cima_star_cache');
    await GetStorage.init('cima_star_movies');
    await GetStorage.init('cima_star_progress');
    
    _box = GetStorage('cima_star_cache');
    _moviesBox = GetStorage('cima_star_movies');
    _watchProgressBox = GetStorage('cima_star_progress');
    return this;
  }

  /// Cache data with timestamp
  Future<void> cacheData(String key, dynamic data) async {
    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _box.write(key, jsonEncode(cacheEntry));
    } catch (e) {
      print('Cache error: $e');
    }
  }

  /// Save movies list to dedicated storage
  Future<void> saveMoviesList(String key, List<Movie> movies) async {
    try {
      final cacheEntry = {
        'data': movies.map((m) => m.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _moviesBox.write(key, jsonEncode(cacheEntry));
    } catch (e) {
      print('Movies cache error: $e');
    }
  }

  /// Get cached movies list
  Future<List<Movie>?> getMoviesList(String key) async {
    try {
      final raw = _moviesBox.read<String>(key);
      if (raw == null) return null;

      final cacheEntry = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int?;
      
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        
        // Use extended cache duration for offline mode
        if (age < AppConstants.extendedCacheDuration.inMilliseconds) {
          final data = cacheEntry['data'] as List?;
          if (data != null) {
            return (data as List)
                .map((m) {
                  try {
                    return Movie.fromJson(m as Map<String, dynamic>);
                  } catch (e) {
                    print('Movie parse error: $e');
                    return null;
                  }
                })
                .whereType<Movie>()
                .toList();
          }
        }
      }
      return null;
    } catch (e) {
      print('Get movies cache error: $e');
      return null;
    }
  }

  /// Cache data with extended duration
  Future<void> cacheDataExtended(String key, dynamic data) async {
    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'extended': true,
      };
      await _box.write(key, jsonEncode(cacheEntry));
    } catch (e) {
      print('Extended cache error: $e');
    }
  }

  /// Get cached data if still valid
  T? getCachedData<T>(String key) {
    try {
      final raw = _box.read<String>(key);
      if (raw == null) return null;

      final cacheEntry = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final isExtended = cacheEntry['extended'] as bool? ?? false;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      final cacheDuration = isExtended 
          ? AppConstants.extendedCacheDuration.inMilliseconds
          : AppConstants.cacheDuration.inMilliseconds;

      if (age < cacheDuration) {
        return cacheEntry['data'] as T;
      }
      return null; // Cache expired
    } catch (e) {
      print('Get cache error: $e');
      return null;
    }
  }

  /// Save watch progress for resume playback
  Future<void> saveWatchProgress(String movieId, int seconds) async {
    try {
      final progress = {
        'movieId': movieId,
        'seconds': seconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _watchProgressBox.write(movieId, jsonEncode(progress));
    } catch (e) {
      print('Watch progress save error: $e');
    }
  }

  /// Get watch progress for a movie
  Future<int?> getWatchProgress(String movieId) async {
    try {
      final raw = _watchProgressBox.read<String>(movieId);
      if (raw == null) return null;

      final progress = jsonDecode(raw) as Map<String, dynamic>;
      return progress['seconds'] as int?;
    } catch (e) {
      print('Get watch progress error: $e');
      return null;
    }
  }

  /// Clear watch progress
  Future<void> clearWatchProgress(String movieId) async {
    try {
      await _watchProgressBox.remove(movieId);
    } catch (e) {
      print('Clear watch progress error: $e');
    }
  }

  /// Check if cache is valid for a given key
  bool isCacheValid(String key) {
    return getCachedData(key) != null;
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      await _box.remove(key);
    } catch (e) {
      print('Clear cache error: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await _box.erase();
      await _moviesBox.erase();
    } catch (e) {
      print('Clear all cache error: $e');
    }
  }

  /// Clear only movies cache (keep watch progress)
  Future<void> clearMoviesCache() async {
    try {
      await _moviesBox.erase();
    } catch (e) {
      print('Clear movies cache error: $e');
    }
  }

  /// Get cache age in minutes
  int? getCacheAgeMinutes(String key) {
    try {
      final raw = _box.read<String>(key);
      if (raw == null) return null;

      final cacheEntry = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return (age / 60000).round();
    } catch (e) {
      return null;
    }
  }

  /// Check if any movies are cached
  Future<bool> hasMoviesCache() async {
    try {
      final keys = _moviesBox.getKeys();
      return keys.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all cached movies count
  Future<int> getCachedMoviesCount() async {
    try {
      final keys = _moviesBox.getKeys();
      return keys.length;
    } catch (e) {
      return 0;
    }
  }
}
