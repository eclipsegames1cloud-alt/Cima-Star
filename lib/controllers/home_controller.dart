import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/movie_model.dart';
import '../services/api/multi_source_service.dart';
import '../services/cache_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'dart:convert';

class HomeController extends GetxController {
  final MultiSourceService _apiService = Get.find<MultiSourceService>();
  final CacheService _cacheService = Get.find<CacheService>();
  final StorageService _storageService = Get.find<StorageService>();

  // Observables
  final RxList<Movie> trendingMovies = <Movie>[].obs;
  final RxList<Movie> popularMovies = <Movie>[].obs;
  final RxList<Movie> latestMovies = <Movie>[].obs;
  final RxList<Movie> tvShows = <Movie>[].obs;
  final RxList<Movie> episodes = <Movie>[].obs;
  final RxList<Movie> continueWatching = <Movie>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentTabIndex = 0.obs;
  final RxBool hasInternet = true.obs;
  final RxString activeSource = 'VidAPI'.obs;
  final RxInt currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInternet();
    _listenToConnectivity();
    loadInitialData();
  }

  /// Listen to internet connectivity changes
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      hasInternet.value = !results.contains(ConnectivityResult.none);
      if (hasInternet.value && latestMovies.isEmpty) {
        loadInitialData();
      }
    });
  }

  /// Check current internet status
  Future<void> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    hasInternet.value = !result.contains(ConnectivityResult.none);
  }

  /// Load initial data from all endpoints with caching
  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      activeSource.value = _apiService.activeServiceName.value;

      // Try to load from cache first
      await _loadFromCache();

      // Then fetch fresh data
      await Future.wait([
        _loadTrending(),
        _loadPopular(),
        _loadMovies(),
        _loadTVShows(),
        _loadEpisodes(),
      ]);

      _loadContinueWatching();
    } catch (e) {
      if (latestMovies.isEmpty) {
        errorMessage.value = 'خطأ في تحميل البيانات. حاول تاني!';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load cached data for offline support
  Future<void> _loadFromCache() async {
    final cachedMovies = _cacheService.getCachedData<String>('latest_movies');
    if (cachedMovies != null) {
      try {
        final list = jsonDecode(cachedMovies) as List;
        latestMovies.assignAll(
          list.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList(),
        );
      } catch (_) {}
    }
  }

  /// Save data to cache
  Future<void> _saveToCache(String key, List<Movie> movies) async {
    try {
      final data = jsonEncode(movies.map((m) => m.toJson()).toList());
      await _cacheService.cacheData(key, data);
    } catch (_) {}
  }

  Future<void> _loadTrending() async {
    try {
      final result = await _apiService.getTrending();
      trendingMovies.assignAll(result);
      await _saveToCache('trending', result);
    } catch (e) {
      // Try cache fallback
      final cached = _cacheService.getCachedData<String>('trending');
      if (cached != null) {
        try {
          final list = jsonDecode(cached) as List;
          trendingMovies.assignAll(
            list.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList(),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _loadPopular() async {
    try {
      final result = await _apiService.getPopular();
      popularMovies.assignAll(result);
      await _saveToCache('popular', result);
    } catch (e) {
      final cached = _cacheService.getCachedData<String>('popular');
      if (cached != null) {
        try {
          final list = jsonDecode(cached) as List;
          popularMovies.assignAll(
            list.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList(),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _loadMovies() async {
    try {
      final result = await _apiService.getLatestMovies(page: currentPage.value);
      latestMovies.assignAll(result);
      activeSource.value = _apiService.activeServiceName.value;
      await _saveToCache('latest_movies', result);
    } catch (e) {
      errorMessage.value = 'خطأ في تحميل الأفلام';
    }
  }

  Future<void> _loadTVShows() async {
    try {
      final result = await _apiService.getLatestTVShows();
      tvShows.assignAll(result);
      await _saveToCache('tv_shows', result);
    } catch (e) {
      errorMessage.value = 'خطأ في تحميل المسلسلات';
    }
  }

  Future<void> _loadEpisodes() async {
    try {
      final result = await _apiService.getLatestEpisodes();
      episodes.assignAll(result);
      await _saveToCache('episodes', result);
    } catch (e) {
      errorMessage.value = 'خطأ في تحميل الحلقات';
    }
  }

  /// Load continue watching from storage
  void _loadContinueWatching() {
    final history = _storageService.getAllWatchHistory();
    final movies = history
        .where((h) => h.containsKey('movie'))
        .map((h) {
          try {
            return Movie.fromJson(h['movie'] as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Movie>()
        .toList();
    continueWatching.assignAll(movies);
  }

  /// Load more movies (pagination)
  Future<void> loadMoreMovies() async {
    if (isLoadingMore.value) return;
    isLoadingMore.value = true;
    currentPage.value++;

    try {
      final result = await _apiService.getLatestMovies(page: currentPage.value);
      latestMovies.addAll(result);
    } catch (e) {
      currentPage.value--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    currentPage.value = 1;
    await loadInitialData();
  }

  /// Change tab
  void changeTab(int index) {
    currentTabIndex.value = index;
  }

  /// Get current list based on tab
  List<Movie> get currentList {
    switch (currentTabIndex.value) {
      case 0: return latestMovies;
      case 1: return tvShows;
      case 2: return episodes;
      default: return latestMovies;
    }
  }
}
