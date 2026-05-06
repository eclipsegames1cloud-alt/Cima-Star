/// App-wide constants for Cima Star
class AppConstants {
  // App Info
  static const String appName = 'Cima Star';
  static const String appVersion = '3.0.0';

  // Multi-Source API Endpoints
  static const List<String> apiSources = [
    'https://vidapi.ru',
    'https://api2.vidsource.xyz',
    'https://backup.vidstream.zone',
  ];

  // Primary API Base URL (first source)
  static String get vidApiBaseUrl => apiSources[0];

  // API Endpoints
  static String get moviesLatestUrl => '$vidApiBaseUrl/movies/latest/page-1.json';
  static String get tvShowsLatestUrl => '$vidApiBaseUrl/tvshows/latest/page-1.json';
  static String get episodesLatestUrl => '$vidApiBaseUrl/episodes/latest/page-1.json';
  static String get trendingMoviesUrl => '$vidApiBaseUrl/movies/trending/page-1.json';
  static String get popularMoviesUrl => '$vidApiBaseUrl/movies/popular/page-1.json';

  // Player URLs - VA Player with fallback
  static const String vaPlayerBaseUrl = 'https://vaplayer.ru/embed';
  static const String vaPlayerLang = 'ar';
  static const String vaPlayerPrimaryColor = '%23E50914';

  // Backward-compatible aliases (do not remove – referenced by player_controller)
  static const String playerBaseUrl = vaPlayerBaseUrl;
  static const String playerLang = vaPlayerLang;
  static const String playerPrimaryColor = vaPlayerPrimaryColor;
  
  // Alternative player URLs for fallback
  static const List<String> playerSources = [
    'https://vaplayer.ru/embed',
    'https://player.vidstream.zone/embed',
    'https://backup-player.ru/embed',
  ];

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 2);
  static const Duration extendedCacheDuration = Duration(days: 7);

  // Pagination
  static const int defaultPageSize = 20;

  // Download
  static const String downloadFolder = 'CimaStar';

  // Shared Preferences Keys
  static const String favoritesKey = 'favorites';
  static const String watchHistoryKey = 'watch_history';
  static const String watchProgressKey = 'watch_progress';
  static const String cacheKey = 'api_cache';
  static const String settingsKey = 'settings';
  static const String onboardingKey = 'onboarding_done';
  static const String moviesListCacheKey = 'movies_list_cache';
  static const String tvShowsListCacheKey = 'tvshows_list_cache';

  // Notification Channels
  static const String notificationChannelId = 'cima_star_notifications';
  static const String notificationChannelName = 'Cima Star';
  static const String notificationChannelDesc = 'New movies & episodes notifications';

  // Blocked WebView Domains
  static const List<String> blockedDomains = [
    'spam',
    'ads',
    'popup',
    'malware',
    'tracking',
    'doubleclick',
    'googlesyndication',
    'pagead',
    'adclick',
    'banner',
  ];
  
  // WebView configurations
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool allowZoom = true;
  static const bool enableMediaPlayback = true;
  static const int userAgentVersion = 1;
}
