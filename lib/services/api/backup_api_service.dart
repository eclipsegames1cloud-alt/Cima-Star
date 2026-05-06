import 'package:dio/dio.dart';
import '../../models/movie_model.dart';
import '../../utils/constants.dart';
import 'movie_service.dart';

/// Backup API Service - Secondary source
class BackupApiService implements MovieService {
  late final Dio _dio;
  final String _baseUrl;

  BackupApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiSources[1] {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
  }

  @override
  Future<List<Movie>> getLatestMovies({int page = 1}) async {
    try {
      final response = await _dio.get('/api/movies', queryParameters: {'page': page});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Movie>> getLatestTVShows({int page = 1}) async {
    try {
      final response = await _dio.get('/api/tvshows', queryParameters: {'page': page});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Movie>> getLatestEpisodes({int page = 1}) async {
    try {
      final response = await _dio.get('/api/episodes', queryParameters: {'page': page});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    try {
      final response = await _dio.get('/api/search', queryParameters: {'q': query});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Movie?> getMovieDetails(String id) async {
    try {
      final response = await _dio.get('/api/movie/$id');
      if (response.data is Map<String, dynamic>) {
        return Movie.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Movie>> getTrending({int page = 1}) async {
    try {
      final response = await _dio.get('/api/trending', queryParameters: {'page': page});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Movie>> getPopular({int page = 1}) async {
    try {
      final response = await _dio.get('/api/popular', queryParameters: {'page': page});
      return _parseResponse(response.data);
    } catch (e) {
      return [];
    }
  }

  List<Movie> _parseResponse(dynamic data) {
    // Support both "items" (primary) and "result" (legacy) keys from the API
    if (data is Map<String, dynamic> &&
        (data['items'] is List || data['result'] is List)) {
      final movieResponse = MovieResponse.fromJson(data);
      return movieResponse.result ?? [];
    }
    if (data is List) {
      return data
          .map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
