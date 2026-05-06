import '../../models/movie_model.dart';

/// Abstract class for movie data sources
/// كده تقدر تغير المصدر من غير ما تكسر التطبيق
abstract class MovieService {
  Future<List<Movie>> getLatestMovies({int page = 1});
  Future<List<Movie>> getLatestTVShows({int page = 1});
  Future<List<Movie>> getLatestEpisodes({int page = 1});
  Future<List<Movie>> searchMovies(String query);
  Future<Movie?> getMovieDetails(String id);
  Future<List<Movie>> getTrending({int page = 1});
  Future<List<Movie>> getPopular({int page = 1});
}
