import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../../models/movie_model.dart';
import '../../utils/constants.dart';
import '../../services/cache_service.dart';
import 'movie_service.dart';
import 'vid_api_service.dart';
import 'backup_api_service.dart';

/// Multi-Source API Service with retry logic and fallback
/// لو واحد وقع، التاني ينقذك
class MultiSourceService extends GetxService implements MovieService {
  late final List<MovieService> _services;
  final RxInt activeServiceIndex = 0.obs;
  final RxString activeServiceName = 'VidAPI'.obs;

  @override
  void onInit() {
    super.onInit();
    _services = [
      VidApiService(Get.find<CacheService>()),
      BackupApiService(baseUrl: AppConstants.apiSources[1]),
      BackupApiService(baseUrl: AppConstants.apiSources[2]),
    ];
  }

  /// Safe request with retry logic and multi-source fallback
  Future<T> _safeRequest<T>(Future<T> Function(MovieService service) request) async {
    int retries = AppConstants.maxRetries;

    // Try current active service first
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final result = await request(_services[activeServiceIndex.value]);
        return result;
      } catch (e) {
        if (attempt == retries - 1) {
          break; // Move to next source
        }
        await Future.delayed(AppConstants.retryDelay);
      }
    }

    // Fallback: try other services
    for (int i = 0; i < _services.length; i++) {
      if (i == activeServiceIndex.value) continue;

      try {
        final result = await request(_services[i]);
        // Switch active service on success
        activeServiceIndex.value = i;
        activeServiceName.value = 'Source ${i + 1}';
        return result;
      } catch (e) {
        continue;
      }
    }

    // All sources failed - try mock data
    throw Exception('All API sources failed. Please check your internet connection.');
  }

  @override
  Future<List<Movie>> getLatestMovies({int page = 1}) async {
    try {
      return await _safeRequest((service) => service.getLatestMovies(page: page));
    } catch (e) {
      return _loadMockData();
    }
  }

  @override
  Future<List<Movie>> getLatestTVShows({int page = 1}) async {
    try {
      return await _safeRequest((service) => service.getLatestTVShows(page: page));
    } catch (e) {
      return _loadMockData();
    }
  }

  @override
  Future<List<Movie>> getLatestEpisodes({int page = 1}) async {
    try {
      return await _safeRequest((service) => service.getLatestEpisodes(page: page));
    } catch (e) {
      return _loadMockData();
    }
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      return await _safeRequest((service) => service.searchMovies(query));
    } catch (e) {
      return _loadMockData();
    }
  }

  @override
  Future<Movie?> getMovieDetails(String id) async {
    try {
      return await _safeRequest((service) => service.getMovieDetails(id));
    } catch (e) {
      final mockMovies = await _loadMockData();
      return mockMovies.isNotEmpty ? mockMovies.first : null;
    }
  }

  @override
  Future<List<Movie>> getTrending({int page = 1}) async {
    try {
      return await _safeRequest((service) => service.getTrending(page: page));
    } catch (e) {
      return _loadMockData();
    }
  }

  @override
  Future<List<Movie>> getPopular({int page = 1}) async {
    try {
      return await _safeRequest((service) => service.getPopular(page: page));
    } catch (e) {
      return _loadMockData();
    }
  }

  /// Load fallback mock data when all sources fail
  Future<List<Movie>> _loadMockData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/json/mock_data.json');
      final jsonData = jsonDecode(jsonString);
      // Supports both "items" (new) and "result" (legacy) keys
      final movieResponse = MovieResponse.fromJson(jsonData as Map<String, dynamic>);
      return movieResponse.result ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Check if a specific source is available
  Future<bool> isSourceAvailable(int index) async {
    if (index < 0 || index >= _services.length) return false;
    try {
      await _services[index].getLatestMovies(page: 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Switch to a specific source manually
  void switchSource(int index) {
    if (index >= 0 && index < _services.length) {
      activeServiceIndex.value = index;
      activeServiceName.value = 'Source ${index + 1}';
    }
  }

  /// Get available sources count
  int get sourceCount => _services.length;
}
