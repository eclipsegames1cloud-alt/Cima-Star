import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/movie_model.dart';

/// Service for loading offline fallback data
class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();

  factory OfflineDataService() {
    return _instance;
  }

  OfflineDataService._internal();

  List<Movie>? _cachedMockData;

  /// Load mock/fallback data from assets
  Future<List<Movie>> loadFallbackData() async {
    if (_cachedMockData != null) {
      return _cachedMockData!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/json/mock_data.json');
      final jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic> &&
          (jsonData['items'] is List || jsonData['result'] is List)) {
        final movieResponse = MovieResponse.fromJson(jsonData);
        _cachedMockData = movieResponse.result ?? [];
        return _cachedMockData!;
      } else if (jsonData is List) {
        _cachedMockData = (jsonData as List)
            .map((item) {
              try {
                return Movie.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing fallback movie: $e');
                return null;
              }
            })
            .whereType<Movie>()
            .toList();
        return _cachedMockData!;
      }
    } catch (e) {
      print('Error loading fallback data: $e');
    }

    // Return empty list if loading fails
    return [];
  }

  /// Get sample movie for error state
  static Movie getSampleMovie() {
    return Movie(
      title: 'قريباً',
      posterUrl: 'https://via.placeholder.com/300x450?text=Movie',
      imdbId: 'tt0000000',
      tmdbId: '0',
      rating: 0,
      isTV: false,
      embedUrl: '',
    );
  }

  /// Check if fallback data is available
  bool hasCachedData() {
    return _cachedMockData != null && _cachedMockData!.isNotEmpty;
  }

  /// Clear cached fallback data
  void clearCache() {
    _cachedMockData = null;
  }

  /// Get fallback data count
  int getCachedDataCount() {
    return _cachedMockData?.length ?? 0;
  }
}
