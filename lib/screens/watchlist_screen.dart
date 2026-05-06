import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/app_routes.dart';
import '../controllers/watchlist_controller.dart';
import '../models/movie_model.dart';

class WatchlistScreen extends GetView<WatchlistController> {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 10),
            const Text('المفضلة'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.favorites.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: controller.favorites.length,
          itemBuilder: (context, index) {
            final movie = controller.favorites[index];
            return _FavoriteMovieCard(movie: movie);
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'لا توجد أفلام في المفضلة',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف أفلامك المفضلة لتشاهدها لاحقًا',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.home),
            icon: const Icon(Icons.explore),
            label: const Text('استكشف الأفلام'),
          ),
        ],
      ),
    );
  }
}

class _FavoriteMovieCard extends StatelessWidget {
  final Movie movie;
  const _FavoriteMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.movieDetail,
        arguments: {'movie': movie},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: movie.posterUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTheme.shimmerBase),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.shimmerBase,
                        child: const Icon(Icons.movie, color: AppTheme.textTertiary, size: 40),
                      ),
                    ),
                  ),

                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GetBuilder<WatchlistController>(
                      builder: (wc) => GestureDetector(
                        onTap: () => wc.removeFromFavorites(movie.uniqueId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Rating badge
                  if (movie.rating != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              movie.ratingDisplay,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Movie info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.displayTitle,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${movie.yearDisplay} | ${movie.isTV ? 'مسلسل' : 'فيلم'}',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
