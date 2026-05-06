import 'package:dio/dio.dart';
import 'dart:convert';
import '../../models/movie_model.dart';
import '../../utils/constants.dart';
import '../cache_service.dart';
import 'movie_service.dart';

/// Primary API Service - VidAPI source with complete resilience
class VidApiService implements MovieService {
  late final Dio _dio;
  final CacheService _cacheService;
  static const String _moviesCacheKey = 'cached_movies_latest';
  static const String _tvShowsCacheKey = 'cached_tvshows_latest';
  static const String _episodesCacheKey = 'cached_episodes_latest';
  static const String _trendingCacheKey = 'cached_trending_latest';
  static const String _popularCacheKey = 'cached_popular_latest';

  VidApiService(this._cacheService) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.vidApiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
    ));
  }

  /// Safely parse JSON with defensive programming
  dynamic _safeJsonParse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('JSON Parse Error: $e');
      return null;
    }
  }

  /// Get latest movies with fallback
  @override
  Future<List<Movie>> getLatestMovies({int page = 1}) async {
    try {
      final response = await _dio.get('/movies/latest/page-$page.json');
      final result = _parseMovieResponse(response.data);
      
      // Cache successful response
      if (result.isNotEmpty) {
        await _cacheService.saveMoviesList('$_moviesCacheKey$page', result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching latest movies: $e');
      // Try to load from cache
      final cached = await _cacheService.getMoviesList('$_moviesCacheKey$page');
      return cached ?? [];
    }
  }

  /// Get latest movies with pagination info
  Future<PaginatedResult<Movie>> getLatestMoviesPaginated({int page = 1}) async {
    try {
      final response = await _dio.get('/movies/latest/page-$page.json');
      return _parsePaginatedResponse(response.data);
    } catch (e) {
      print('Error fetching paginated movies: $e');
      final cached = await _cacheService.getMoviesList('$_moviesCacheKey$page');
      return PaginatedResult(items: cached ?? [], page: page, totalPages: 0, totalItems: 0);
    }
  }

  /// Get latest TV shows with fallback
  @override
  Future<List<Movie>> getLatestTVShows({int page = 1}) async {
    try {
      final response = await _dio.get('/tvshows/latest/page-$page.json');
      final result = _parseMovieResponse(response.data);
      
      // Cache successful response
      if (result.isNotEmpty) {
        await _cacheService.saveMoviesList('$_tvShowsCacheKey$page', result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching latest TV shows: $e');
      final cached = await _cacheService.getMoviesList('$_tvShowsCacheKey$page');
      return cached ?? [];
    }
  }

  /// Get latest TV shows with pagination info
  Future<PaginatedResult<Movie>> getLatestTVShowsPaginated({int page = 1}) async {
    try {
      final response = await _dio.get('/tvshows/latest/page-$page.json');
      return _parsePaginatedResponse(response.data);
    } catch (e) {
      print('Error fetching paginated TV shows: $e');
      final cached = await _cacheService.getMoviesList('$_tvShowsCacheKey$page');
      return PaginatedResult(items: cached ?? [], page: page, totalPages: 0, totalItems: 0);
    }
  }

  /// Get latest episodes with fallback
  @override
  Future<List<Movie>> getLatestEpisodes({int page = 1}) async {
    try {
      final response = await _dio.get('/episodes/latest/page-$page.json');
      final result = _parseMovieResponse(response.data);
      
      // Cache successful response
      if (result.isNotEmpty) {
        await _cacheService.saveMoviesList('$_episodesCacheKey$page', result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching latest episodes: $e');
      final cached = await _cacheService.getMoviesList('$_episodesCacheKey$page');
      return cached ?? [];
    }
  }

  /// Get latest episodes with pagination info
  Future<PaginatedResult<Movie>> getLatestEpisodesPaginated({int page = 1}) async {
    try {
      final response = await _dio.get('/episodes/latest/page-$page.json');
      return _parsePaginatedResponse(response.data);
    } catch (e) {
      print('Error fetching paginated episodes: $e');
      final cached = await _cacheService.getMoviesList('$_episodesCacheKey$page');
      return PaginatedResult(items: cached ?? [], page: page, totalPages: 0, totalItems: 0);
    }
  }

  /// Search movies with fallback
  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _dio.get('/search/${Uri.encodeComponent(query)}.json');
      return _parseMovieResponse(response.data);
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }

  /// Get movie details with resilience
  @override
  Future<Movie?> getMovieDetails(String id) async {
    try {
      final response = await _dio.get('/movie/${Uri.encodeComponent(id)}.json');
      if (response.data is Map<String, dynamic>) {
        return Movie.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching movie details: $e');
      return null;
    }
  }

  /// Get trending with fallback
  @override
  Future<List<Movie>> getTrending({int page = 1}) async {
    try {
      final response = await _dio.get('/movies/trending/page-$page.json');
      final result = _parseMovieResponse(response.data);
      
      // Cache successful response
      if (result.isNotEmpty) {
        await _cacheService.saveMoviesList('$_trendingCacheKey$page', result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching trending: $e');
      // Try to load from cache
      final cached = await _cacheService.getMoviesList('$_trendingCacheKey$page');
      return cached ?? [];
    }
  }

  /// Get popular with fallback
  @override
  Future<List<Movie>> getPopular({int page = 1}) async {
    try {
      final response = await _dio.get('/movies/popular/page-$page.json');
      final result = _parseMovieResponse(response.data);
      
      // Cache successful response
      if (result.isNotEmpty) {
        await _cacheService.saveMoviesList('$_popularCacheKey$page', result);
      }
      
      return result;
    } catch (e) {
      print('Error fetching popular: $e');
      // Try to load from cache
      final cached = await _cacheService.getMoviesList('$_popularCacheKey$page');
      return cached ?? [];
    }
  }

  /// Parse API response with defensive programming
  /// Supports both "items" (VidAPI) and "result" (legacy) keys from the API.
  List<Movie> _parseMovieResponse(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        // Priority: "items" key first (VidAPI), then "result" key (legacy API)
        if (data['items'] is List || data['result'] is List) {
          final movieResponse = MovieResponse.fromJson(data);
          return movieResponse.result ?? [];
        }
      } else if (data is List) {
        // Direct list in response
        return data
            .map((item) {
              try {
                return Movie.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing individual movie: $e');
                return null;
              }
            })
            .whereType<Movie>()
            .toList();
      }
    } catch (e) {
      print('Error parsing movie response: $e');
    }
    return [];
  }

  /// Parse paginated response from VidAPI
  PaginatedResult<Movie> _parsePaginatedResponse(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final movieResponse = MovieResponse.fromJson(data);
        final items = movieResponse.result ?? [];
        final pagination = movieResponse.pagination;
        
        return PaginatedResult(
          items: items,
          page: pagination?.currentPage ?? 1,
          totalPages: pagination?.totalPages ?? 0,
          totalItems: pagination?.totalResults ?? 0,
        );
      }
    } catch (e) {
      print('Error parsing paginated response: $e');
    }
    return PaginatedResult(items: [], page: 1, totalPages: 0, totalItems: 0);
  }

  /// Rebuild embed URL if API embed_url is missing
  static String buildEmbedUrl({
    required String? imdbId,
    required String? tmdbId,
    String? season,
    String? episode,
  }) {
    if (imdbId != null && imdbId.isNotEmpty) {
      if (season != null && episode != null) {
        return '${AppConstants.vaPlayerBaseUrl}/tv/$imdbId/$season/$episode';
      }
      return '${AppConstants.vaPlayerBaseUrl}/movie/$imdbId';
    }
    
    if (tmdbId != null && tmdbId.isNotEmpty) {
      if (season != null && episode != null) {
        return '${AppConstants.vaPlayerBaseUrl}/tv/$tmdbId/$season/$episode';
      }
      return '${AppConstants.vaPlayerBaseUrl}/movie/$tmdbId';
    }
    
    return '';
  }
}

/// Generic paginated result container
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalItems;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });

  bool get hasMore => page < totalPages;
}
