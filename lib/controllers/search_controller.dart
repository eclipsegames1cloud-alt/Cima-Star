import 'dart:async';
import 'package:get/get.dart';
import '../models/movie_model.dart';
import '../services/api/multi_source_service.dart';

class SearchController extends GetxController {
  final MultiSourceService _apiService = Get.find<MultiSourceService>();

  RxString searchQuery = ''.obs;
  RxList<Movie> searchResults = <Movie>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasSearched = false.obs;

  // Store all available movies for client-side filtering
  RxList<Movie> allMovies = <Movie>[].obs;

  // Debounce timer
  Timer? _debounce;

  // Genre filters
  final RxList<String> availableGenres = <String>[].obs;
  final RxString selectedGenre = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllMovies();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  /// Load all movies once for faster searching
  Future<void> _loadAllMovies() async {
    try {
      final movies = await _apiService.getLatestMovies();
      final tvShows = await _apiService.getLatestTVShows();
      final episodes = await _apiService.getLatestEpisodes();

      allMovies.addAll([...movies, ...tvShows, ...episodes]);
      _extractGenres();
    } catch (e) {
      // Silent fail - search will use API directly
    }
  }

  /// Extract unique genres from loaded movies
  void _extractGenres() {
    final genres = <String>{};
    for (final movie in allMovies) {
      if (movie.genres != null) {
        genres.addAll(movie.genres!);
      }
    }
    availableGenres.assignAll(genres.toList()..sort());
  }

  /// Live search with debounce
  void onSearchChanged(String query) {
    _debounce?.cancel();
    searchQuery.value = query.trim();

    if (searchQuery.isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      performSearch(searchQuery.value);
    });
  }

  /// Perform search - client-side first, then API
  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    isLoading.value = true;
    hasSearched.value = true;

    try {
      // Client-side search (instant)
      final localResults = allMovies.where((movie) {
        final title = (movie.displayTitle).toLowerCase();
        final description = (movie.description ?? '').toLowerCase();
        final genres = movie.genresDisplay.toLowerCase();
        final queryLower = query.toLowerCase();

        return title.contains(queryLower) || description.contains(queryLower) || genres.contains(queryLower);
      }).toList();

      if (localResults.isNotEmpty) {
        searchResults.assignAll(localResults);
      }

      // API search for more results
      final apiResults = await _apiService.searchMovies(query);
      if (apiResults.isNotEmpty) {
        // Merge without duplicates
        final existingIds = searchResults.map((m) => m.uniqueId).toSet();
        for (final movie in apiResults) {
          if (!existingIds.contains(movie.uniqueId)) {
            searchResults.add(movie);
          }
        }
      } else if (localResults.isEmpty) {
        searchResults.clear();
      }
    } catch (e) {
      // Fallback to client-side only
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter by genre
  void filterByGenre(String genre) {
    if (selectedGenre.value == genre) {
      selectedGenre.value = '';
      // Show all movies if deselecting
      searchResults.assignAll(allMovies);
    } else {
      selectedGenre.value = genre;
      searchResults.assignAll(
        allMovies.where((movie) {
          return movie.genres?.any((g) => g.toLowerCase() == genre.toLowerCase()) ?? false;
        }).toList(),
      );
    }
    hasSearched.value = true;
  }

  /// Clear search
  void clearSearch() {
    _debounce?.cancel();
    searchQuery.value = '';
    selectedGenre.value = '';
    searchResults.clear();
    hasSearched.value = false;
  }

  /// Get recent/trending searches
  List<String> get suggestedSearches => [
    'Action',
    'Drama',
    'Comedy',
    'Thriller',
    'Horror',
    'Sci-Fi',
    'Romance',
    'Animation',
    'Crime',
    'Fantasy',
  ];
}
