import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/movie_model.dart';
import '../services/api/vid_api_service.dart';
import '../services/api/multi_source_service.dart';
import '../services/cache_service.dart';

/// Content type for browsing
enum BrowseContentType {
  movies,
  tvShows,
  episodes,
}

/// Controller for Browse All screens with infinite scrolling pagination.
/// Accesses ALL content from VidAPI (90K+ movies, 20K+ TV shows, 460K+ episodes).
class BrowseController extends GetxController {
  final VidApiService _vidApiService = Get.find<VidApiService>();
  final CacheService _cacheService = Get.find<CacheService>();

  late BrowseContentType contentType;

  // Observables
  final RxList<Movie> items = <Movie>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMore = true.obs;
  final RxBool hasInternet = true.obs;

  // Filter
  final RxString searchQuery = ''.obs;
  final RxList<Movie> filteredItems = <Movie>[].obs;

  void initController(BrowseContentType type) {
    contentType = type;
    _checkInternet();
    _listenToConnectivity();
    loadInitialData();
  }

  /// Listen to internet connectivity changes
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      hasInternet.value = !results.contains(ConnectivityResult.none);
      if (hasInternet.value && items.isEmpty) {
        loadInitialData();
      }
    });
  }

  /// Check current internet status
  Future<void> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    hasInternet.value = !result.contains(ConnectivityResult.none);
  }

  /// Load initial data
  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      currentPage.value = 1;
      items.clear();
      filteredItems.clear();

      await _fetchPage(1);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'خطأ في تحميل البيانات. حاول تاني!';
      
      // Try cache fallback
      final cacheKey = _getCacheKey(1);
      final cached = await _cacheService.getMoviesList(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        items.assignAll(cached);
        filteredItems.assignAll(cached);
        hasError.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more data (next page) for infinite scrolling
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      await _fetchPage(currentPage.value + 1);
    } catch (e) {
      // Silent fail for pagination - keep existing data
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Fetch a specific page
  Future<void> _fetchPage(int page) async {
    PaginatedResult<Movie> result;

    switch (contentType) {
      case BrowseContentType.movies:
        result = await _vidApiService.getLatestMoviesPaginated(page: page);
        break;
      case BrowseContentType.tvShows:
        result = await _vidApiService.getLatestTVShowsPaginated(page: page);
        break;
      case BrowseContentType.episodes:
        result = await _vidApiService.getLatestEpisodesPaginated(page: page);
        break;
    }

    currentPage.value = result.page;
    totalPages.value = result.totalPages;
    totalItems.value = result.totalItems;
    hasMore.value = result.hasMore;

    if (page == 1) {
      items.assignAll(result.items);
    } else {
      items.addAll(result.items);
    }

    // Apply current filter
    _applyFilter();

    // Cache the page data
    final cacheKey = _getCacheKey(page);
    await _cacheService.saveMoviesList(cacheKey, result.items);
  }

  /// Get cache key for content type and page
  String _getCacheKey(int page) {
    switch (contentType) {
      case BrowseContentType.movies:
        return 'browse_movies_page$page';
      case BrowseContentType.tvShows:
        return 'browse_tv_page$page';
      case BrowseContentType.episodes:
        return 'browse_episodes_page$page';
    }
  }

  /// Search/filter within loaded items
  void filterItems(String query) {
    searchQuery.value = query.trim();
    _applyFilter();
  }

  void _applyFilter() {
    if (searchQuery.value.isEmpty) {
      filteredItems.assignAll(items);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredItems.assignAll(
        items.where((movie) {
          final title = (movie.displayTitle).toLowerCase();
          final genres = movie.genresDisplay.toLowerCase();
          return title.contains(query) || genres.contains(query);
        }).toList(),
      );
    }
  }

  /// Clear filter
  void clearFilter() {
    searchQuery.value = '';
    _applyFilter();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await loadInitialData();
  }

  /// Get display title for content type
  String get title {
    switch (contentType) {
      case BrowseContentType.movies:
        return 'كل الأفلام';
      case BrowseContentType.tvShows:
        return 'كل المسلسلات';
      case BrowseContentType.episodes:
        return 'أحدث الحلقات';
    }
  }

  /// Get total count display
  String get totalDisplay {
    if (totalItems.value == 0) return '';
    final formatter = _formatNumber(totalItems.value);
    return '$formatter ${contentType == BrowseContentType.movies ? 'فيلم' : contentType == BrowseContentType.tvShows ? 'مسلسل' : 'حلقة'}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
