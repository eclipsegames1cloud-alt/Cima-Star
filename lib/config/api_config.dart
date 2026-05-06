/// API Configuration - Centralized management of all endpoints
/// This file makes it easy to update API sources without code changes
class ApiConfig {
  // Primary VidAPI Configuration
  static const String primaryApiBaseUrl = 'https://vidapi.ru';
  static const String primaryApiName = 'VidAPI (Primary)';

  // Backup API Sources (automatically used if primary fails)
  static const List<ApiSource> backupSources = [
    ApiSource(
      name: 'VidAPI Backup 1',
      baseUrl: 'https://api2.vidsource.xyz',
    ),
    ApiSource(
      name: 'VidAPI Backup 2',
      baseUrl: 'https://backup.vidstream.zone',
    ),
  ];

  // Primary Video Player Configuration
  static const String primaryPlayerUrl = 'https://vaplayer.ru/embed';
  static const String primaryPlayerName = 'VA Player (Primary)';

  // Backup Video Player Sources (used if primary player fails)
  static const List<PlayerSource> backupPlayers = [
    PlayerSource(
      name: 'VA Player Backup 1',
      baseUrl: 'https://player.vidstream.zone/embed',
    ),
    PlayerSource(
      name: 'VA Player Backup 2',
      baseUrl: 'https://backup-player.ru/embed',
    ),
  ];

  // Player Configuration
  static const String playerLanguage = 'ar'; // Arabic
  static const String playerPrimaryColor = 'E50914'; // Netflix Red
  static const bool enablePlayerJavaScript = true;
  static const bool enablePlayerDomStorage = true;
  static const bool allowPlayerZoom = true;

  // API Endpoints Configuration - ONLY endpoints that actually exist on VidAPI
  static const Map<String, String> apiEndpoints = {
    'movies_latest': '/movies/latest/page-{page}.json',
    'tvshows_latest': '/tvshows/latest/page-{page}.json',
    'episodes_latest': '/episodes/latest/page-{page}.json',
    // Note: trending, popular, search, and movie details endpoints
    // may not exist on the actual VidAPI server. They will gracefully
    // fail and fall back to cache/mock data.
    'movies_trending': '/movies/trending/page-{page}.json',
    'movies_popular': '/movies/popular/page-{page}.json',
    'movie_details': '/movie/{id}.json',
    'search': '/search/{query}.json',
  };

  // Request Timeouts (in seconds)
  static const int connectionTimeoutSeconds = 10;
  static const int receiveTimeoutSeconds = 15;
  static const int totalTimeoutSeconds = 30;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  // Cache Configuration (in hours)
  static const int cacheExpirationHours = 2;
  static const int extendedCacheExpirationDays = 7;

  // Network Configuration
  static const bool enableLogging = false; // Set to true for debugging
  static const bool validateSSLCertificates = true; // Enabled for security
  static const bool followRedirects = true;
  static const int maxRedirects = 5;

  // Ad/Spam Blocking Configuration
  static const List<String> blockedDomainPatterns = [
    'doubleclick.net',
    'googlesyndication.com',
    'adclick',
    'popup',
    'ads.',
    'banner',
    'tracking',
  ];

  /// Get complete URL for an endpoint
  static String getApiUrl(
    String endpoint, {
    int? page,
    String? id,
    String? query,
  }) {
    String url = primaryApiBaseUrl + (apiEndpoints[endpoint] ?? '');

    if (page != null) {
      url = url.replaceAll('{page}', page.toString());
    }
    if (id != null) {
      url = url.replaceAll('{id}', Uri.encodeComponent(id));
    }
    if (query != null) {
      url = url.replaceAll('{query}', Uri.encodeComponent(query));
    }

    return url;
  }

  /// Get player URL for movie
  static String getMoviePlayerUrl(String imdbId, {String? tmdbId}) {
    if (imdbId.isNotEmpty) {
      return '$primaryPlayerUrl/movie/$imdbId';
    } else if (tmdbId != null && tmdbId.isNotEmpty) {
      return '$primaryPlayerUrl/movie/$tmdbId';
    }
    return '';
  }

  /// Get player URL for TV episode
  static String getTvPlayerUrl(
    String id, {
    required int season,
    required int episode,
  }) {
    return '$primaryPlayerUrl/tv/$id/$season/$episode';
  }

  /// Get player URL with language parameter
  static String getPlayerUrlWithLanguage(String baseUrl) {
    final separator = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl${separator}lang=$playerLanguage&primaryColor=%23$playerPrimaryColor';
  }
}

/// Model for backup API source
class ApiSource {
  final String name;
  final String baseUrl;

  const ApiSource({
    required this.name,
    required this.baseUrl,
  });

  /// Get complete endpoint URL
  String getEndpointUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}

/// Model for backup player source
class PlayerSource {
  final String name;
  final String baseUrl;

  const PlayerSource({
    required this.name,
    required this.baseUrl,
  });

  /// Get player URL for movie
  String getMovieUrl(String imdbId) {
    return '$baseUrl/movie/$imdbId';
  }

  /// Get player URL for TV episode
  String getTvUrl(String id, int season, int episode) {
    return '$baseUrl/tv/$id/$season/$episode';
  }
}
