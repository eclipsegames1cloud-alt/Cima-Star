import 'package:get/get.dart';
import '../models/movie_model.dart';
import '../services/storage_service.dart';

class WatchlistController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<Movie> favorites = <Movie>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  /// Load favorites from storage
  void loadFavorites() {
    favorites.assignAll(_storageService.getFavorites());
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Movie movie) async {
    final movieId = movie.uniqueId;
    if (isFavorite(movieId)) {
      await _storageService.removeFavorite(movieId);
      favorites.removeWhere((m) => m.uniqueId == movieId);
    } else {
      await _storageService.saveFavorite(movie);
      favorites.add(movie);
    }
  }

  /// Check if movie is favorite
  bool isFavorite(String movieId) {
    return favorites.any((m) => m.uniqueId == movieId);
  }

  /// Add to favorites
  Future<void> addToFavorites(Movie movie) async {
    if (!isFavorite(movie.uniqueId)) {
      await _storageService.saveFavorite(movie);
      favorites.add(movie);
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String movieId) async {
    await _storageService.removeFavorite(movieId);
    favorites.removeWhere((m) => m.uniqueId == movieId);
  }

  /// Get favorites count
  int get favoritesCount => favorites.length;
}
