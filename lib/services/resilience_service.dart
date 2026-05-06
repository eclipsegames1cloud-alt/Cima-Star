import 'package:get/get.dart';
import 'dart:async';
import '../models/movie_model.dart';
import '../utils/constants.dart';
import 'cache_service.dart';
import 'api/vid_api_service.dart';

/// Service for handling API failures with automatic fallback to **cache only**.
/// No fake/hardcoded URLs are ever generated – if the API is down and there is
/// no cached data, the caller receives an empty list.
class ResilienceService extends GetxService {
  final CacheService _cacheService = Get.find<CacheService>();
  
  late VidApiService _primaryApiService;
  final RxBool isPrimaryApiHealthy = true.obs;
  final RxString currentApiSource = 'Primary'.obs;
  final RxInt apiFailureCount = 0.obs;
  
  static const int _healthCheckIntervalSeconds = 300; // 5 minutes
  static const int _failureThreshold = 3;

  Future<ResilienceService> init() async {
    _primaryApiService = VidApiService(_cacheService);
    _startHealthCheck();
    return this;
  }

  /// Start periodic health checks
  void _startHealthCheck() {
    Timer.periodic(Duration(seconds: _healthCheckIntervalSeconds), (_) {
      _checkApiHealth();
    });
  }

  /// Check if primary API is healthy
  Future<void> _checkApiHealth() async {
    try {
      // Try a simple lightweight request
      final movies = await _primaryApiService.getLatestMovies(page: 1);
      
      if (movies.isNotEmpty) {
        isPrimaryApiHealthy.value = true;
        apiFailureCount.value = 0;
        currentApiSource.value = 'Primary (Healthy)';
      } else {
        _recordFailure();
      }
    } catch (e) {
      _recordFailure();
    }
  }

  /// Record API failure
  void _recordFailure() {
    apiFailureCount.value++;
    if (apiFailureCount.value >= _failureThreshold) {
      isPrimaryApiHealthy.value = false;
      currentApiSource.value = 'Cache Fallback (Primary Down)';
    }
  }

  /// Get movies with automatic fallback to cache only
  Future<List<Movie>> getMoviesWithFallback({int page = 1}) async {
    try {
      if (isPrimaryApiHealthy.value) {
        return await _primaryApiService.getLatestMovies(page: page);
      }
    } catch (e) {
      _recordFailure();
    }

    // Fallback: cache only (no fake URLs)
    return await _fallbackToCache('cached_movies_latest$page');
  }

  /// Get TV shows with automatic fallback to cache only
  Future<List<Movie>> getTVShowsWithFallback({int page = 1}) async {
    try {
      if (isPrimaryApiHealthy.value) {
        return await _primaryApiService.getLatestTVShows(page: page);
      }
    } catch (e) {
      _recordFailure();
    }

    return await _fallbackToCache('cached_tvshows_latest$page');
  }

  /// Get episodes with automatic fallback to cache only
  Future<List<Movie>> getEpisodesWithFallback({int page = 1}) async {
    try {
      if (isPrimaryApiHealthy.value) {
        return await _primaryApiService.getLatestEpisodes(page: page);
      }
    } catch (e) {
      _recordFailure();
    }

    return await _fallbackToCache('cached_episodes_latest$page');
  }

  /// Get trending with automatic fallback to cache only
  Future<List<Movie>> getTrendingWithFallback({int page = 1}) async {
    try {
      if (isPrimaryApiHealthy.value) {
        return await _primaryApiService.getTrending(page: page);
      }
    } catch (e) {
      _recordFailure();
    }

    return await _fallbackToCache('cached_trending_latest$page');
  }

  /// Get popular with automatic fallback to cache only
  Future<List<Movie>> getPopularWithFallback({int page = 1}) async {
    try {
      if (isPrimaryApiHealthy.value) {
        return await _primaryApiService.getPopular(page: page);
      }
    } catch (e) {
      _recordFailure();
    }

    return await _fallbackToCache('cached_popular_latest$page');
  }

  /// Centralized cache fallback – returns cached data or empty list.
  /// No fake URLs are ever generated.
  Future<List<Movie>> _fallbackToCache(String cacheKey) async {
    try {
      final cachedMovies = await _cacheService.getMoviesList(cacheKey);
      if (cachedMovies != null && cachedMovies.isNotEmpty) {
        return cachedMovies;
      }
    } catch (e) {
      // Cache read failed – nothing we can do
    }
    return [];
  }

  /// Search with error handling (no cache fallback for search)
  Future<List<Movie>> searchMovies(String query) async {
    try {
      return await _primaryApiService.searchMovies(query);
    } catch (e) {
      return [];
    }
  }

  /// Get movie details with error handling
  Future<Movie?> getMovieDetails(String id) async {
    try {
      return await _primaryApiService.getMovieDetails(id);
    } catch (e) {
      return null;
    }
  }

  /// Reset health check (call after manual retry)
  void resetHealthCheck() {
    isPrimaryApiHealthy.value = true;
    apiFailureCount.value = 0;
    currentApiSource.value = 'Primary (Reset)';
  }

  /// Get health status
  String getHealthStatus() {
    if (isPrimaryApiHealthy.value) {
      return 'API Healthy';
    } else {
      return 'Using Cache Fallback';
    }
  }

  /// Check if we have any offline data
  Future<bool> hasOfflineData() async {
    return await _cacheService.hasMoviesCache();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'currentSource': currentApiSource.value,
      'isHealthy': isPrimaryApiHealthy.value,
      'failureCount': apiFailureCount.value,
      'maxFailureThreshold': _failureThreshold,
    };
  }
}
